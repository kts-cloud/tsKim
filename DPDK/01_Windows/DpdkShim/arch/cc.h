#ifndef CC_H
#define CC_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

/* --- Type definitions for lwIP --- */
typedef uint8_t   u8_t;
typedef int8_t    s8_t;
typedef uint16_t  u16_t;
typedef int16_t   s16_t;
typedef uint32_t  u32_t;
typedef int32_t   s32_t;
typedef uintptr_t mem_ptr_t;

/* --- ssize_t: match DPDK definition (long long), prevent lwIP redefining as int --- */
#include <limits.h>
#ifndef _SSIZE_T_DEFINED
#define _SSIZE_T_DEFINED
typedef long long ssize_t;
#endif
#ifndef SSIZE_MAX
#define SSIZE_MAX LLONG_MAX
#endif
#define LWIP_NO_UNISTD_H 1

/* --- Byte order --- */
#ifndef BYTE_ORDER
#define BYTE_ORDER  LITTLE_ENDIAN
#endif

/* --- Diagnostics --- */
#define LWIP_PLATFORM_DIAG(x)   do { printf x; fflush(stdout); } while(0)
#define LWIP_PLATFORM_ASSERT(x) do { printf("lwIP ASSERT: %s\n", (x)); fflush(stdout); } while(0)

/* --- Struct packing (clang) --- */
#define PACK_STRUCT_BEGIN
#define PACK_STRUCT_STRUCT  __attribute__((packed))
#define PACK_STRUCT_END
#define PACK_STRUCT_FIELD(x)  x

/* --- Random number (used by initial TCP sequence) --- */
#define LWIP_RAND()  ((u32_t)rand())

#endif /* CC_H */
