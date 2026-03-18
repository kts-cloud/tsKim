/*
 * dpdk_ftp_client.c -- FTP client state machine on lwIP raw TCP API (NO_SYS=1)
 *
 * Control connection (port 21) + data connection (PASV mode).
 * All lwIP calls must run from the same thread context.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define WIN32_LEAN_AND_MEAN
#define _WINSOCKAPI_
#include <windows.h>

#include "lwip/tcp.h"
#include "lwip/ip_addr.h"
#include "lwip/pbuf.h"

/* ================================================================
 * FTP state machine states
 * ================================================================ */
enum {
    FTP_STATE_IDLE = 0,
    FTP_STATE_CONNECTING,
    FTP_STATE_WAIT_WELCOME,       /* waiting for 220 */
    FTP_STATE_SENDING_USER,
    FTP_STATE_WAIT_USER,          /* waiting for 331 */
    FTP_STATE_SENDING_PASS,
    FTP_STATE_WAIT_PASS,          /* waiting for 230 */
    FTP_STATE_READY,
    FTP_STATE_SENDING_PASV,
    FTP_STATE_WAIT_PASV,          /* waiting for 227 */
    FTP_STATE_DATA_CONNECTING,
    FTP_STATE_SENDING_CMD,
    FTP_STATE_TRANSFERRING,
    FTP_STATE_WAIT_DONE,          /* waiting for 226 */
    FTP_STATE_ERROR
};

/* ================================================================
 * FTP client context
 * ================================================================ */
typedef struct {
    struct tcp_pcb *ctrl_pcb;       /* control channel  */
    struct tcp_pcb *data_pcb;       /* data channel     */
    int state;
    int response_code;
    char response_buf[4096];
    int response_len;

    /* Transfer buffers */
    uint8_t *recv_buf;              /* download buffer            */
    uint32_t recv_len;
    uint32_t recv_capacity;
    const uint8_t *send_data;       /* upload data (not owned)    */
    uint32_t send_len;
    uint32_t send_offset;

    /* PASV parsed address */
    uint32_t pasv_ip;
    uint16_t pasv_port;

    /* Pending command to send after data channel connects */
    char pending_cmd[256];

    /* Completion flag */
    volatile int op_done;
    int op_result;                  /* 0=success, -1=error, 1=timeout */

    /* Upload: flag indicating STOR mode */
    int is_upload;
} ftp_client_t;

/* ================================================================
 * Forward declarations of callbacks
 * ================================================================ */
static err_t ftp_ctrl_connected_cb(void *arg, struct tcp_pcb *tpcb, err_t err);
static err_t ftp_ctrl_recv_cb(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err);
static void  ftp_ctrl_err_cb(void *arg, err_t err);
static err_t ftp_data_connected_cb(void *arg, struct tcp_pcb *tpcb, err_t err);
static err_t ftp_data_recv_cb(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err);
static err_t ftp_data_sent_cb(void *arg, struct tcp_pcb *tpcb, u16_t len);
static void  ftp_data_err_cb(void *arg, err_t err);

/* ================================================================
 * Debug logging (to stderr, same style as shim)
 * ================================================================ */
static void ftp_dbg(const char *fmt, ...)
{
    char buf[512];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(buf, sizeof(buf), fmt, ap);
    va_end(ap);
    fprintf(stderr, "%s", buf);
    fflush(stderr);
    /* Also write to debug log file */
    HANDLE h = CreateFileA("D:\\DPDK\\01_Windows\\eal_debug.txt",
        FILE_APPEND_DATA, FILE_SHARE_READ|FILE_SHARE_WRITE,
        NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h != INVALID_HANDLE_VALUE) {
        DWORD w;
        WriteFile(h, buf, (DWORD)strlen(buf), &w, NULL);
        CloseHandle(h);
    }
}

/* ================================================================
 * Helper: send a string on the control channel
 * ================================================================ */
static err_t ftp_ctrl_send(ftp_client_t *ftp, const char *str)
{
    if (!ftp->ctrl_pcb) return ERR_CONN;
    u16_t slen = (u16_t)strlen(str);
    err_t err = tcp_write(ftp->ctrl_pcb, str, slen, TCP_WRITE_FLAG_COPY);
    if (err == ERR_OK)
        tcp_output(ftp->ctrl_pcb);
    else
        ftp_dbg("[FTP] ctrl_send failed: %d\n", (int)err);
    return err;
}

/* ================================================================
 * Helper: parse FTP response code (first 3 digits)
 * Returns -1 if response is incomplete (multi-line continuation).
 * Returns the 3-digit code when a final line "NNN " is found.
 * ================================================================ */
static int ftp_parse_response(const char *buf, int len)
{
    if (len < 4) return -1;

    /* Scan backwards to find the last complete line ending with \r\n */
    /* A final response line starts with 3 digits followed by a space */
    const char *p = buf;
    const char *end = buf + len;
    int last_code = -1;

    while (p < end) {
        /* Find end of this line */
        const char *eol = (const char *)memchr(p, '\n', (size_t)(end - p));
        if (!eol) break; /* incomplete line, wait for more data */

        /* Check if this line has format "NNN " (final) or "NNN-" (continuation) */
        int line_len = (int)(eol - p);
        if (line_len >= 4 && isdigit((unsigned char)p[0]) &&
            isdigit((unsigned char)p[1]) && isdigit((unsigned char)p[2])) {
            if (p[3] == ' ') {
                /* Final response line */
                last_code = (p[0] - '0') * 100 + (p[1] - '0') * 10 + (p[2] - '0');
            }
            /* p[3] == '-' means continuation, keep scanning */
        }

        p = eol + 1;
    }

    return last_code;
}

/* ================================================================
 * Helper: parse PASV response 227 (h1,h2,h3,h4,p1,p2)
 * ================================================================ */
static int ftp_parse_pasv(const char *buf, uint32_t *out_ip, uint16_t *out_port)
{
    const char *open = strchr(buf, '(');
    if (!open) return -1;

    unsigned int h1, h2, h3, h4, p1, p2;
    if (sscanf(open + 1, "%u,%u,%u,%u,%u,%u", &h1, &h2, &h3, &h4, &p1, &p2) != 6)
        return -1;

    /* IP in network byte order (lwIP ip4_addr is in network order) */
    *out_ip = (uint32_t)((h1) | (h2 << 8) | (h3 << 16) | (h4 << 24));
    *out_port = (uint16_t)(p1 * 256 + p2);
    return 0;
}

/* ================================================================
 * Helper: upload data on data channel (chunked to TCP_SND_BUF)
 * ================================================================ */
static void ftp_data_push_upload(ftp_client_t *ftp)
{
    if (!ftp->data_pcb || !ftp->send_data) return;

    while (ftp->send_offset < ftp->send_len) {
        u16_t sndbuf = tcp_sndbuf(ftp->data_pcb);
        if (sndbuf == 0) break;

        uint32_t remaining = ftp->send_len - ftp->send_offset;
        u16_t chunk = (remaining > sndbuf) ? sndbuf : (u16_t)remaining;

        err_t err = tcp_write(ftp->data_pcb, ftp->send_data + ftp->send_offset,
                              chunk, TCP_WRITE_FLAG_COPY);
        if (err != ERR_OK) {
            ftp_dbg("[FTP] data upload write err=%d\n", (int)err);
            break;
        }
        ftp->send_offset += chunk;
    }
    tcp_output(ftp->data_pcb);

    /* If all data sent, close the data connection */
    if (ftp->send_offset >= ftp->send_len) {
        tcp_close(ftp->data_pcb);
        ftp->data_pcb = NULL;
        ftp->state = FTP_STATE_WAIT_DONE;
        ftp_dbg("[FTP] upload complete, data channel closed, waiting 226\n");
    }
}

/* ================================================================
 * Control channel callbacks
 * ================================================================ */
static err_t ftp_ctrl_connected_cb(void *arg, struct tcp_pcb *tpcb, err_t err)
{
    ftp_client_t *ftp = (ftp_client_t *)arg;
    (void)tpcb;

    if (err != ERR_OK) {
        ftp_dbg("[FTP] ctrl connect failed: %d\n", (int)err);
        ftp->state = FTP_STATE_ERROR;
        ftp->op_done = 1;
        ftp->op_result = -1;
        return err;
    }

    ftp_dbg("[FTP] ctrl connected, waiting for 220 welcome\n");
    ftp->state = FTP_STATE_WAIT_WELCOME;
    return ERR_OK;
}

static err_t ftp_ctrl_recv_cb(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err)
{
    ftp_client_t *ftp = (ftp_client_t *)arg;

    if (!p || err != ERR_OK) {
        /* Connection closed by server */
        ftp_dbg("[FTP] ctrl connection closed by server\n");
        ftp->state = FTP_STATE_ERROR;
        ftp->op_done = 1;
        ftp->op_result = -1;
        if (p) pbuf_free(p);
        return ERR_OK;
    }

    /* Accumulate response data */
    int space = (int)sizeof(ftp->response_buf) - ftp->response_len - 1;
    int copy_len = (p->tot_len < (u16_t)space) ? p->tot_len : (u16_t)space;
    if (copy_len > 0) {
        pbuf_copy_partial(p, ftp->response_buf + ftp->response_len, (u16_t)copy_len, 0);
        ftp->response_len += copy_len;
        ftp->response_buf[ftp->response_len] = '\0';
    }

    tcp_recved(tpcb, p->tot_len);
    pbuf_free(p);

    /* Try to parse a complete response */
    int code = ftp_parse_response(ftp->response_buf, ftp->response_len);
    if (code < 0)
        return ERR_OK;  /* incomplete, wait for more */

    ftp->response_code = code;
    ftp_dbg("[FTP] response %d in state %d\n", code, ftp->state);

    /* State machine */
    switch (ftp->state) {
    case FTP_STATE_WAIT_WELCOME:
        if (code == 220) {
            ftp->state = FTP_STATE_READY;
            ftp->op_done = 1;
            ftp->op_result = 0;
        } else {
            ftp->state = FTP_STATE_ERROR;
            ftp->op_done = 1;
            ftp->op_result = -1;
        }
        break;

    case FTP_STATE_WAIT_USER:
        if (code == 331) {
            ftp->state = FTP_STATE_READY;
            ftp->op_done = 1;
            ftp->op_result = 0;
        } else if (code == 230) {
            /* No password needed */
            ftp->state = FTP_STATE_READY;
            ftp->op_done = 1;
            ftp->op_result = 0;
        } else {
            ftp->state = FTP_STATE_ERROR;
            ftp->op_done = 1;
            ftp->op_result = -1;
        }
        break;

    case FTP_STATE_WAIT_PASS:
        if (code == 230) {
            ftp->state = FTP_STATE_READY;
            ftp->op_done = 1;
            ftp->op_result = 0;
        } else {
            ftp->state = FTP_STATE_ERROR;
            ftp->op_done = 1;
            ftp->op_result = -1;
        }
        break;

    case FTP_STATE_WAIT_PASV:
        if (code == 227) {
            if (ftp_parse_pasv(ftp->response_buf, &ftp->pasv_ip, &ftp->pasv_port) == 0) {
                ftp_dbg("[FTP] PASV → ip=%u.%u.%u.%u port=%u\n",
                        ftp->pasv_ip & 0xFF, (ftp->pasv_ip >> 8) & 0xFF,
                        (ftp->pasv_ip >> 16) & 0xFF, (ftp->pasv_ip >> 24) & 0xFF,
                        ftp->pasv_port);
                /* Connect data channel */
                ftp->data_pcb = tcp_new();
                if (!ftp->data_pcb) {
                    ftp->state = FTP_STATE_ERROR;
                    ftp->op_done = 1;
                    ftp->op_result = -1;
                    break;
                }
                tcp_arg(ftp->data_pcb, ftp);
                tcp_recv(ftp->data_pcb, ftp_data_recv_cb);
                tcp_sent(ftp->data_pcb, ftp_data_sent_cb);
                tcp_err(ftp->data_pcb, ftp_data_err_cb);

                ip_addr_t data_ip;
                ip_addr_set_ip4_u32(&data_ip, ftp->pasv_ip);

                ftp->state = FTP_STATE_DATA_CONNECTING;
                err_t cerr = tcp_connect(ftp->data_pcb, &data_ip, ftp->pasv_port,
                                         ftp_data_connected_cb);
                if (cerr != ERR_OK) {
                    ftp_dbg("[FTP] data tcp_connect failed: %d\n", (int)cerr);
                    ftp->state = FTP_STATE_ERROR;
                    ftp->op_done = 1;
                    ftp->op_result = -1;
                }
            } else {
                ftp_dbg("[FTP] PASV parse failed\n");
                ftp->state = FTP_STATE_ERROR;
                ftp->op_done = 1;
                ftp->op_result = -1;
            }
        } else {
            ftp->state = FTP_STATE_ERROR;
            ftp->op_done = 1;
            ftp->op_result = -1;
        }
        break;

    case FTP_STATE_SENDING_CMD:
        /* Shouldn't normally get a ctrl response here until data is done */
        /* But handle 1xx informational replies */
        if (code >= 100 && code < 200) {
            /* Informational, ignore */
        } else if (code == 150 || code == 125) {
            /* "Opening data connection" — transfer in progress */
            ftp->state = FTP_STATE_TRANSFERRING;
        } else {
            ftp->state = FTP_STATE_ERROR;
            ftp->op_done = 1;
            ftp->op_result = -1;
        }
        break;

    case FTP_STATE_TRANSFERRING:
        /* Could get 226 while data is still draining, handle it */
        if (code == 226) {
            ftp->state = FTP_STATE_READY;
            ftp->op_done = 1;
            ftp->op_result = 0;
            ftp_dbg("[FTP] 226 received during transfer\n");
        } else if (code == 150 || code == 125) {
            /* late arrival of "opening" message, ignore */
        } else {
            ftp->state = FTP_STATE_ERROR;
            ftp->op_done = 1;
            ftp->op_result = -1;
        }
        break;

    case FTP_STATE_WAIT_DONE:
        if (code == 226) {
            ftp->state = FTP_STATE_READY;
            ftp->op_done = 1;
            ftp->op_result = 0;
            ftp_dbg("[FTP] 226 transfer complete\n");
        } else if (code == 150 || code == 125) {
            /* opening message arrived late, ignore */
        } else {
            ftp->state = FTP_STATE_ERROR;
            ftp->op_done = 1;
            ftp->op_result = -1;
        }
        break;

    default:
        /* For READY state: generic command response (PWD, CWD, etc.) */
        if (ftp->state == FTP_STATE_READY) {
            ftp->op_done = 1;
            ftp->op_result = 0;
        }
        break;
    }

    /* Reset response buffer for next response */
    ftp->response_len = 0;

    return ERR_OK;
}

static void ftp_ctrl_err_cb(void *arg, err_t err)
{
    ftp_client_t *ftp = (ftp_client_t *)arg;
    ftp_dbg("[FTP] ctrl error: %d\n", (int)err);
    ftp->ctrl_pcb = NULL;  /* lwIP frees pcb before calling err callback */
    ftp->state = FTP_STATE_ERROR;
    ftp->op_done = 1;
    ftp->op_result = -1;
}

/* ================================================================
 * Data channel callbacks
 * ================================================================ */
static err_t ftp_data_connected_cb(void *arg, struct tcp_pcb *tpcb, err_t err)
{
    ftp_client_t *ftp = (ftp_client_t *)arg;
    (void)tpcb;

    if (err != ERR_OK) {
        ftp_dbg("[FTP] data connect failed: %d\n", (int)err);
        ftp->state = FTP_STATE_ERROR;
        ftp->op_done = 1;
        ftp->op_result = -1;
        return err;
    }

    ftp_dbg("[FTP] data channel connected\n");

    /* Now send the pending command on the control channel */
    if (ftp->pending_cmd[0] != '\0') {
        ftp->state = FTP_STATE_SENDING_CMD;
        ftp_ctrl_send(ftp, ftp->pending_cmd);
        ftp->pending_cmd[0] = '\0';

        /* If this is an upload (STOR), start pushing data */
        if (ftp->is_upload) {
            ftp_data_push_upload(ftp);
        }
    }

    return ERR_OK;
}

static err_t ftp_data_recv_cb(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err)
{
    ftp_client_t *ftp = (ftp_client_t *)arg;

    if (!p || err != ERR_OK) {
        /* Data connection closed by server — transfer done */
        ftp_dbg("[FTP] data channel closed (recv_len=%u, state=%d)\n",
                ftp->recv_len, ftp->state);
        if (ftp->state == FTP_STATE_TRANSFERRING || ftp->state == FTP_STATE_SENDING_CMD)
            ftp->state = FTP_STATE_WAIT_DONE;
        if (p) pbuf_free(p);
        /* Must call tcp_close to send our FIN, completing the TCP shutdown.
         * Without this, the connection stays in CLOSE_WAIT and the FTP server
         * waits for full close before sending 226. */
        if (tpcb) {
            tcp_arg(tpcb, NULL);
            tcp_recv(tpcb, NULL);
            tcp_sent(tpcb, NULL);
            tcp_err(tpcb, NULL);
            tcp_close(tpcb);
        }
        ftp->data_pcb = NULL;
        return ERR_OK;
    }

    /* Accumulate received data (LIST/RETR) */
    ftp_dbg("[FTP] data_recv: tot_len=%u, recv_buf=%p, recv_len=%u, cap=%u\n",
            p->tot_len, (void*)ftp->recv_buf, ftp->recv_len, ftp->recv_capacity);
    if (ftp->recv_buf && ftp->recv_len < ftp->recv_capacity) {
        uint32_t space = ftp->recv_capacity - ftp->recv_len;
        uint32_t to_copy = (p->tot_len < space) ? p->tot_len : space;
        /* pbuf_copy_partial takes u16_t len, copy in chunks if needed */
        uint32_t copied = 0;
        while (copied < to_copy) {
            u16_t chunk = (u16_t)((to_copy - copied) > 0xFFFF ? 0xFFFF : (to_copy - copied));
            u16_t got = pbuf_copy_partial(p, ftp->recv_buf + ftp->recv_len + copied, chunk, (u16_t)copied);
            copied += got;
            if (got < chunk) break;
        }
        ftp->recv_len += copied;
        ftp_dbg("[FTP] data_recv: accumulated %u bytes (total=%u)\n", copied, ftp->recv_len);
    }

    tcp_recved(tpcb, p->tot_len);
    pbuf_free(p);
    return ERR_OK;
}

static err_t ftp_data_sent_cb(void *arg, struct tcp_pcb *tpcb, u16_t len)
{
    ftp_client_t *ftp = (ftp_client_t *)arg;
    (void)tpcb;
    (void)len;

    /* Continue pushing upload data if more remains */
    if (ftp->is_upload && ftp->send_offset < ftp->send_len) {
        ftp_data_push_upload(ftp);
    }

    return ERR_OK;
}

static void ftp_data_err_cb(void *arg, err_t err)
{
    ftp_client_t *ftp = (ftp_client_t *)arg;
    ftp_dbg("[FTP] data error: %d (state=%d)\n", (int)err, ftp->state);
    ftp->data_pcb = NULL;  /* pcb already freed by lwIP */
    if (ftp->state != FTP_STATE_READY && ftp->state != FTP_STATE_IDLE) {
        ftp->state = FTP_STATE_ERROR;
        ftp->op_done = 1;
        ftp->op_result = -1;
    }
}

/* ================================================================
 * Public API
 * ================================================================ */

void ftp_client_init(ftp_client_t *ftp)
{
    memset(ftp, 0, sizeof(*ftp));
    ftp->state = FTP_STATE_IDLE;
}

int ftp_connect(ftp_client_t *ftp, uint32_t server_ip, uint16_t port)
{
    if (ftp->ctrl_pcb) {
        ftp_dbg("[FTP] already connected\n");
        return -1;
    }

    ftp->ctrl_pcb = tcp_new();
    if (!ftp->ctrl_pcb) {
        ftp_dbg("[FTP] tcp_new failed\n");
        return -1;
    }

    tcp_arg(ftp->ctrl_pcb, ftp);
    tcp_recv(ftp->ctrl_pcb, ftp_ctrl_recv_cb);
    tcp_err(ftp->ctrl_pcb, ftp_ctrl_err_cb);

    ip_addr_t addr;
    ip_addr_set_ip4_u32(&addr, server_ip);

    ftp->state = FTP_STATE_CONNECTING;
    ftp->response_len = 0;
    ftp->response_code = 0;
    ftp->op_done = 0;
    ftp->op_result = 0;

    err_t err = tcp_connect(ftp->ctrl_pcb, &addr, port, ftp_ctrl_connected_cb);
    if (err != ERR_OK) {
        ftp_dbg("[FTP] tcp_connect failed: %d\n", (int)err);
        tcp_abort(ftp->ctrl_pcb);
        ftp->ctrl_pcb = NULL;
        ftp->state = FTP_STATE_ERROR;
        return -1;
    }

    return 0;
}

int ftp_send_cmd(ftp_client_t *ftp, const char *cmd)
{
    ftp->response_len = 0;
    ftp->response_code = 0;
    ftp->op_done = 0;
    ftp->op_result = 0;

    return (ftp_ctrl_send(ftp, cmd) == ERR_OK) ? 0 : -1;
}

int ftp_start_pasv(ftp_client_t *ftp)
{
    ftp->response_len = 0;
    ftp->response_code = 0;
    ftp->op_done = 0;
    ftp->op_result = 0;
    ftp->state = FTP_STATE_WAIT_PASV;  /* set before send so callback sees correct state */

    ftp_dbg("[FTP] sending PASV command...\n");
    err_t err = ftp_ctrl_send(ftp, "PASV\r\n");
    if (err != ERR_OK)
        ftp_dbg("[FTP] PASV send failed: %d\n", (int)err);
    return (err == ERR_OK) ? 0 : -1;
}

int ftp_start_list(ftp_client_t *ftp, uint8_t *buf, uint32_t buf_size)
{
    ftp->recv_buf = buf;
    ftp->recv_len = 0;
    ftp->recv_capacity = buf_size;
    ftp->is_upload = 0;
    ftp->send_data = NULL;
    ftp->send_len = 0;
    ftp->send_offset = 0;
    snprintf(ftp->pending_cmd, sizeof(ftp->pending_cmd), "LIST\r\n");

    return ftp_start_pasv(ftp);
}

int ftp_start_retr(ftp_client_t *ftp, const char *path, uint8_t *buf, uint32_t buf_size)
{
    ftp->recv_buf = buf;
    ftp->recv_len = 0;
    ftp->recv_capacity = buf_size;
    ftp->is_upload = 0;
    ftp->send_data = NULL;
    ftp->send_len = 0;
    ftp->send_offset = 0;
    snprintf(ftp->pending_cmd, sizeof(ftp->pending_cmd), "RETR %s\r\n", path);

    return ftp_start_pasv(ftp);
}

int ftp_start_stor(ftp_client_t *ftp, const char *path, const uint8_t *data, uint32_t len)
{
    ftp->recv_buf = NULL;
    ftp->recv_len = 0;
    ftp->recv_capacity = 0;
    ftp->is_upload = 1;
    ftp->send_data = data;
    ftp->send_len = len;
    ftp->send_offset = 0;
    snprintf(ftp->pending_cmd, sizeof(ftp->pending_cmd), "STOR %s\r\n", path);

    return ftp_start_pasv(ftp);
}

void ftp_cleanup_data(ftp_client_t *ftp)
{
    if (ftp->data_pcb) {
        tcp_arg(ftp->data_pcb, NULL);
        tcp_recv(ftp->data_pcb, NULL);
        tcp_sent(ftp->data_pcb, NULL);
        tcp_err(ftp->data_pcb, NULL);
        tcp_abort(ftp->data_pcb);
        ftp->data_pcb = NULL;
    }
    ftp->recv_buf = NULL;
    ftp->recv_len = 0;
    ftp->send_data = NULL;
    ftp->send_len = 0;
    ftp->send_offset = 0;
    ftp->state = FTP_STATE_READY;
    ftp_dbg("[FTP] data channel cleaned up, state reset to READY\n");
}

void ftp_disconnect(ftp_client_t *ftp)
{
    if (ftp->data_pcb) {
        tcp_arg(ftp->data_pcb, NULL);
        tcp_recv(ftp->data_pcb, NULL);
        tcp_sent(ftp->data_pcb, NULL);
        tcp_err(ftp->data_pcb, NULL);
        tcp_abort(ftp->data_pcb);
        ftp->data_pcb = NULL;
    }
    if (ftp->ctrl_pcb) {
        tcp_arg(ftp->ctrl_pcb, NULL);
        tcp_recv(ftp->ctrl_pcb, NULL);
        tcp_err(ftp->ctrl_pcb, NULL);
        tcp_close(ftp->ctrl_pcb);
        ftp->ctrl_pcb = NULL;
    }
    ftp->state = FTP_STATE_IDLE;
    ftp->op_done = 0;
}

int ftp_get_state(ftp_client_t *ftp)
{
    return ftp->state;
}
