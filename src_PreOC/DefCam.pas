unit DefCam;

interface

  const
    BASE_TCP_SERVER_IP  = '192.168.0.11'; //'127.0.0.1'; //'192.168.0.11';//
    BASE_TCP_CLINT_IP   = '192.168.0.'; //'127.0.0.'; //'192.168.0.';//
    BASE_TCP_CLINT_INDEX = 31; //1; //31;
    BASE_SERVER_PORT    = 2291;    // G Server.
    BASE_CLINT_PORT     = 1961;    // D Server.

    CAM_CH1             = 0;
    MAX_CAM_CH          = 3;

    MAX_TCP_CH          = 4;

    TCP_BUFF_SIZE       = 700000;

    //m_nRevEvnt µA ”Ðe Return ˆt.
    RET_NONE = 1;
    RET_ACK  = 2;
    RET_NAK  = 3;

    CAM_CONNECT_FIRST_OK = 0;
    CAM_CONNECT_OK       = 1;
    CAM_CONNECT_NG       = 2;
implementation

end.
