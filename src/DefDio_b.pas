unit DefDio;

interface
{$I Common.inc}
	const

  // DAE DIO ªÁøÎ.
    MAX_IO_CNT          = 64;
    MAX_IN_CNT          = 64;
    MAX_OUT_CNT         = 64;




    DAE_IO_DEVICE_IP    = '192.168.0.99';
    DAE_IO_DEVICE_PORT  = 6989;
    DAE_IO_DEVICE_INTERVAL = 200;
    DAE_IO_DEVICE_COUNT = 8;

    TYPE_NORMAL = 0;
    TYPE_GIB    = 1;
//    MAX_IN_CNT          = 64;
//    MAX_OUT_CNT          = 64;

// for 64 channel Items.
    // IN SIGNAL.
    IN_FAN1_IN                = 0;
    IN_FAN2_OUT               = 1;
    IN_FAN3_IN                = 2;
    IN_FAN4_OUT               = 3;

//
    IN_START_SW               = 6;
    IN_FRONT_EMS              = 7;
    IN_SIDE_EMS               = 8;
    IN_RIGHT_INNER_EMS        = 9;
    IN_LEFT_INNER_EMS         = 10;
    IN_REAR_EMS               = 11;

    IN_MOVING_AIR_REGULATOR   = 14;
    IN_Z_XIS_MOTOR_OUT1       = 15;

    IN_TEMPERTURE_ALARM       = 16;
    IN_POWER_HIGH_ALARM       = 17;
    IN_LIGHT_CURTAIN          = 18;
    IN_AUTO_MODE_SEL_KEY      = 19;
    IN_TEACH_MODE_SEL_KEY     = 20;
    IN_UPPER_LEFT_DOOR        = 21;
    IN_UPPER_RIGHT_DOOR       = 22;
    IN_LOWER_LEFT_DOOR        = 23;
    IN_LOWER_RIGHT_DOOR       = 24;
    IN_MC_MONITORING          = 25;
    IN_B_STAGE_IN_CAM         = 26;
    IN_A_STAGE_IN_CAM         = 27;
    IN_MORTOR_STOP_SENSOR     = 28;
    IN_SHUTTER_UP_SENSOR      = 29;
    IN_SHUTTER_DN_SNENSOR     = 30;

    IN_CLAMP_UP_SENSOR_1CH_1  = 32;
    IN_CLAMP_UP_SENSOR_1CH_2  = 33;
    IN_POGO_DN_SENSOR_1CH     = 34;
    IN_DETECTION_SENSOR_1CH   = 35;

//    DIO_IN_CLAMP_UP_SENSOR_2CH_1  = 36;
//    DIO_IN_CLAMP_UP_SENSOR_2CH_2  = 37;
//    DIO_IN_POGO_DN_SENSOR_2CH     = 38;
//    DIO_IN_DETECTION_SENSOR_2CH   = 39;
//
//    DIO_IN_CLAMP_UP_SENSOR_3CH_1  = 40;
//    DIO_IN_CLAMP_UP_SENSOR_3CH_2  = 41;
//    DIO_IN_POGO_DN_SENSOR_3CH     = 42;
//    DIO_IN_DETECTION_SENSOR_3CH   = 43;
//
//    DIO_IN_CLAMP_UP_SENSOR_4CH_1  = 44;
//    DIO_IN_CLAMP_UP_SENSOR_4CH_2  = 45;
//    DIO_IN_POGO_DN_SENSOR_4CH     = 46;
//    DIO_IN_DETECTION_SENSOR_4CH   = 47;
//
//    DIO_IN_CLAMP_UP_SENSOR_5CH_1  = 48;
//    DIO_IN_CLAMP_UP_SENSOR_5CH_2  = 49;
//    DIO_IN_POGO_DN_SENSOR_5CH     = 50;
//    DIO_IN_DETECTION_SENSOR_5CH   = 51;
//
//    DIO_IN_CLAMP_UP_SENSOR_6CH_1  = 52;
//    DIO_IN_CLAMP_UP_SENSOR_6CH_2  = 53;
//    DIO_IN_POGO_DN_SENSOR_6CH     = 54;
//    DIO_IN_DETECTION_SENSOR_6CH   = 55;
//
//    DIO_IN_CLAMP_UP_SENSOR_7CH_1  = 56;
//    DIO_IN_CLAMP_UP_SENSOR_7CH_2  = 57;
//    DIO_IN_POGO_DN_SENSOR_7CH     = 58;
//    DIO_IN_DETECTION_SENSOR_7CH   = 59;
//
//    DIO_IN_CLAMP_UP_SENSOR_8CH_1  = 60;
//    DIO_IN_CLAMP_UP_SENSOR_8CH_2  = 61;
//    DIO_IN_POGO_DN_SENSOR_8CH     = 62;
    IN_DETECTION_SENSOR_8CH   = 63;

    IN_MAX = IN_DETECTION_SENSOR_8CH;

    // For GIB
    IN_AIR_ISOLATOR_SENSOR1    = 64;
    IN_AIR_ISOLATOR_SENSOR2    = 65;
    IN_AIR_ISOLATOR_SENSOR3    = 66;
    IN_AIR_ISOLATOR_SENSOR4    = 67;
    IN_AIR_ISOLATOR_LEFT_DOOR  = 68;
    IN_AIR_ISOLATOR_RIGHT_DOOR = 69;

    // OUT SIGNAL.
    OUT_START_SW_LED          = 0;
    OUT_RESET_SW_LED          = 1;
    OUT_WORKER_LAMP           = 2;
    OUT_RED_LAMP              = 3;
    OUT_YELLOW_LAMP           = 4;
    OUT_GREEN_LAMP            = 5;
    OUT_MELODY_1              = 6;
    OUT_MELODY_2              = 7;
    OUT_MELODY_3              = 8;
    OUT_MELODY_4              = 9;
    OUT_Z_XIS_MOTOR_IN1       = 10;
    OUT_SIDE_SEL_KEY_UNLOCK     = 11;
    OUT_UPPER_LEFT_DOOR_UNLOCK  = 12;
    OUT_UPPER_RIGHT_DOOR_UNLOCK = 13;

    OUT_ION_BAR_SOL           = 14;
    OUT_AIR_KNIFE_SOL         = 15;
    OUT_A_STAGE_FRONT         = 16;
    OUT_B_STAGE_FRONT         = 17;
    OUT_SHUTTER_UP_SOL        = 18;
    OUT_SHUTTER_DN_SOL        = 19;

    OUT_CLAMP_UP_SOL_12CH     = 32;
    OUT_CLAMP_DN_SOL_12CH     = 33;
    OUT_POGO_UP_SOL_12CH      = 34;
    OUT_POGO_DN_SOL_12CH      = 35;

    OUT_CLAMP_UP_SOL_34CH     = 40;
    OUT_CLAMP_DN_SOL_34CH     = 41;
    OUT_POGO_UP_SOL_34CH      = 42;
    OUT_POGO_DN_SOL_34CH      = 43;

    OUT_CLAMP_UP_SOL_56CH     = 48;
    OUT_CLAMP_DN_SOL_56CH     = 49;
    OUT_POGO_UP_SOL_56CH      = 50;
    OUT_POGO_DN_SOL_56CH      = 51;

    OUT_CLAMP_UP_SOL_78CH     = 56;
    OUT_CLAMP_DN_SOL_78CH     = 57;
    OUT_POGO_UP_SOL_78CH      = 58;
    OUT_POGO_DN_SOL_78CH      = 59;

    OUT_MAX = OUT_POGO_DN_SOL_78CH;

    LAMP_STATE_NONE     = 0;
    LAMP_STATE_MANUAL   = LAMP_STATE_NONE + 1;
    LAMP_STATE_PAUSE    = LAMP_STATE_NONE + 2;
    LAMP_STATE_AUTO     = LAMP_STATE_NONE + 3;
    LAMP_STATE_REQUEST  = LAMP_STATE_NONE + 4;
    LAMP_STATE_ERROR    = LAMP_STATE_NONE + 5;
    LAMP_STATE_EMEGENCY = LAMP_STATE_NONE + 6;
    // Error list.

//1	FRONT EMS (DI01)
//2	SIDE EMS (DI02)
//3	RIGHT INNER EMS (DI03)
//4	LEFT INNER EMS (DI04)
//5	REAR EMS (DI05)
//6	LIGHT CURTAIN (DI18)
//7	UPPER LEFT DOOR (DI21)
//8	UPPER RIGHT DOOR (DI22)
    ERR_LIST_START = -1;
    ERR_LIST_FRONT_EMS          = ERR_LIST_START + 1;
    ERR_LIST_SIDE_EMS           = ERR_LIST_START + 2;
    ERR_LIST_R_INNER_EMS        = ERR_LIST_START + 3;
    ERR_LIST_L_INNER_EMS        = ERR_LIST_START + 4;
    ERR_LIST_REAR_EMS           = ERR_LIST_START + 5;
    ERR_LIST_LIGHT_CUTAIN       = ERR_LIST_START + 6;
    ERR_LIST_U_L_DOOR           = ERR_LIST_START + 7;
    ERR_LIST_U_R_DOOR           = ERR_LIST_START + 8;

//9	LOWER LEFT DOOR (DI23)
//10	LOWER RIGHT DOOR (DI24)
//11	FAN#1 »Ì±‚ (DI06)
//12	FAN#2 »Ì±‚ (DI07)
//13	FAN#3 πË±‚ ((DI08)
//14	FAN#4 πË±‚ (DI09)
//15	FAN#5 »Ì±‚ (DI10)

    ERR_LIST_L_L_DOOR           = ERR_LIST_START + 9;
    ERR_LIST_L_R_DOOR           = ERR_LIST_START + 10;
    ERR_LIST_FAN_1_OUT          = ERR_LIST_START + 11;

//16	FAN#6 »Ì±‚ (DI11)
//17	FAN#7 πË±‚ (DI12)
//18	FAN#8 πË±‚ (DI13)
//19	Main AIR PRESSURE NG ((DI14)
//20	TEMPERATURE ALARM (DI16)
//21	POWER HIGH ALARM (DI17)
//22	Need to press Reset button(DI25)

    ERR_LIST_MAIN_AIR_PRESURE   = ERR_LIST_START + 19;
    ERR_LIST_TEMPRERATURE       = ERR_LIST_START + 20;
    ERR_LIST_POWER_HIGH         = ERR_LIST_START + 21;
    ERR_LIST_MC_MONITOR         = ERR_LIST_START + 22;




//23	A Stage Position NG(DI26)
//24	B Stage Position NG(DI27)
//25	Shutter up sensor NG(DI28)
//26	Shutter Down sensor NG(DI29)
//27	Clamp up sensor-1 1Ch NG(DI32)
//28	Clamp up sensor-1 2Ch NG(DI36)
//29	Clamp up sensor-1 3Ch NG(DI40)
//30	Clamp up sensor-1 4Ch NG(DI44)
//31	Clamp up sensor-1 5Ch NG(DI48)
    ERR_LIST_A_STAGE_SENSOR     = ERR_LIST_START + 25;
    ERR_LIST_B_STAGE_SENSOR     = ERR_LIST_START + 26;
    ERR_LIST_SHUTTER_UP_SENSOR  = ERR_LIST_START + 27;
    ERR_LIST_SHUTTER_DN_SENSOR  = ERR_LIST_START + 28;
    ERR_LIST_CAMP_UP_SENSOR_1   = ERR_LIST_START + 29;
//32	Clamp up sensor-1 6Ch NG(DI52)
//33	Clamp up sensor-1 7Ch NG(DI56)
//34	Clamp up sensor-1 8Ch NG(DI60)
//35	Clamp up sensor-2 1Ch NG(DI33)
//36	Clamp up sensor-2 2Ch NG(DI37)
//37	Clamp up sensor-2 3Ch NG(DI41)
//38	Clamp up sensor-2 4Ch NG(DI45)
//39	Clamp up sensor-2 5Ch NG(DI49)
    ERR_LIST_CAMP_UP_SENSOR_2   = ERR_LIST_START + 37;
//40	Clamp up sensor-2 6Ch NG(DI53)
//41	Clamp up sensor-2 7Ch NG(DI57)
//42	Clamp up sensor-2 8Ch NG(DI61)
//43	Clamp down sensor-1 1Ch NG(DI32)
//44	Clamp down sensor-1 2Ch NG(DI36)
//45	Clamp down sensor-1 3Ch NG(DI40)
//46	Clamp down sensor-1 4Ch NG(DI44)
//47	Clamp down sensor-1 5Ch NG(DI48)
    ERR_LIST_CAMP_DN_SENSOR_1   = ERR_LIST_START + 45;
//48	Clamp down sensor-1 6Ch NG(DI52)
//49	Clamp down sensor-1 7Ch NG(DI56)
//50	Clamp down sensor-1 8Ch NG(DI60)
//51	Clamp down sensor-2 1Ch NG(DI33)
//52	Clamp down sensor-2 2Ch NG(DI37)
//53	Clamp down sensor-2 3Ch NG(DI41)
//54	Clamp down sensor-2 4Ch NG(DI45)
//55	Clamp down sensor-2 5Ch NG(DI49)
    ERR_LIST_CAMP_DN_SENSOR_2   = ERR_LIST_START + 53;
//56	Clamp down sensor-2 6Ch NG(DI53)
//57	Clamp down sensor-2 7Ch NG(DI57)
//58	Clamp down sensor-2 8Ch NG(DI61)
//59	pogo up sensor 1Ch NG(DI34)
//60	pogo up sensor 2Ch NG(DI38)
//61	pogo up sensor 3Ch NG(DI42)
//62	pogo up sensor 4Ch NG(DI46)
//63	pogo up sensor 5Ch NG(DI50)
    ERR_LIST_POGO_UP_SENSOR   = ERR_LIST_START + 61;
//64	pogo up sensor 6Ch NG(DI54)
//65	pogo up sensor 7Ch NG(DI58)
//66	pogo up sensor 8Ch NG(DI62)
//67	pogo down sensor 1Ch NG(DI34)
//68	pogo down sensor 2Ch NG(DI38)
//69	pogo down sensor 3Ch NG(DI42)
//70	pogo down sensor 4Ch NG(DI46)
//71	pogo down sensor 5Ch NG(DI50)
    ERR_LIST_POGO_DN_SENSOR   = ERR_LIST_START + 69;
//72	pogo down sensor 6Ch NG(DI54)
//73	pogo down sensor 7Ch NG(DI58)
//74	pogo down sensor 8Ch NG(DI62)
//75	Carrier detect sensor 1Ch NG(DI35)
//76	Carrier detect sensor 2Ch NG(DI39)
//77	Carrier detect sensor 3Ch NG(DI43)
//78	Carrier detect sensor 4Ch NG(DI47)
//79	Carrier detect sensor 5Ch NG(DI51)
    ERR_LIST_CARRIER_DETECT_SENSOR   = ERR_LIST_START + 77;
//80	Carrier detect sensor 6Ch NG(DI55)
//81	Carrier detect sensor 7Ch NG(DI59)
//82	Carrier detect sensor 8Ch NG(DI63)
    ERR_LIST_MORTOR_STOP_SENSOR       = ERR_LIST_START + 86;
    ERR_LIST_DIO_CARD_DISCONNECTED    = ERR_LIST_START + 89;

    ERR_LIST_STEP_MOTOR_DISCONNECTED  = ERR_LIST_START + 90;
    ERR_LIST_STEP_MOTOR_POSITION_NG   = ERR_LIST_STEP_MOTOR_DISCONNECTED + 1;
    ERR_LIST_STEP_MOTOR_CANNOT_WORK   = ERR_LIST_STEP_MOTOR_DISCONNECTED + 2;

    ERR_LIST_IONIZER_STATUS_NG        = ERR_LIST_START + 100;
    ERR_LIST_CAMMERA_1_CONNECTION_NG  = ERR_LIST_START + 101;
    ERR_LIST_CAMMERA_2_CONNECTION_NG  = ERR_LIST_CAMMERA_1_CONNECTION_NG + 1;
    ERR_LIST_CAMMERA_3_CONNECTION_NG  = ERR_LIST_CAMMERA_1_CONNECTION_NG + 2;
    ERR_LIST_CAMMERA_4_CONNECTION_NG  = ERR_LIST_CAMMERA_1_CONNECTION_NG + 3;
    ERR_LIST_CAM_LAMP_CONNECT_NG      = ERR_LIST_START + 105;
    ERR_LIST_ROBOT_NG                 = ERR_LIST_START + 106;
    ERR_LIST_ECS_NG                   = ERR_LIST_START + 107;
    ERR_LIST_MAX                      = ERR_LIST_ECS_NG + 8;




//    MAX_ALARM_DATA_SIZE = 10;
    MAX_ALARM_DATA_SIZE =  ERR_LIST_MAX div 8;
implementation

end.
