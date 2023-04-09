unit DefAF9;

interface


uses Windows, Messages, SysUtils, AF9_API;

//##############################################################################
//##############################################################################
//
//##############################################################################
//##############################################################################

//  Data Types
//     C++            Delphi
//	unsigned short   WORD
//	unsigned long    DWORD=LongWord=Cardinal
//  char*            PAnsiChar
//  BYTE*            PByte


	//****************************************************************************
	//  2022-020-25 DLL(V2.02)
	//
	//  1CH                     MULTI(CH1,CH2)  //2022-020-25 DLL(V2.02)
	// ----------------------+-------------------------------
	//  Start_Connection        MULTI_Start_Connection
	//  Stop_Connection         ???
	//  Connection_Status       MULTI_Connection_Status
	//  SW_Revision 						MULTI_SW_Revision
	//  DLL_Revision            ???
	//  DAC_SET                 MULTI_DAC_SET
	//  ExtendIO_Set            MULTI_ExtendIO_Set
	//  AllPowerOnOff           MULTI_AllPowerOnOff
	//  APSPatternRGBSet        MULTI_APSPatternRGBSet
	//  APSBoxPatternSet        MULTI_APSBoxPatternSet
	//  LGDSetReg               MULTI_LGDSetReg
	//  LGDSetRegM              MULTI_LGDSetRegM
	//  LGDGetReg               MULTI_LGDGetReg
	//  LGDRangeGetReg          MULTI_LGDRangeGetReg
	//  APSSetReg               MULTI_APSSetReg
	//  SendHexFileCRC          MULTI_SendHexFileCRC
	//  SendHexFile             MULTI_SendHexFile
	//  WriteBMPFile            MULTI_WriteBMPFile
	//  BMPFileSend             MULTI_BMPFileSend
	//  BMPFileView             MULTI_BMPFileView
	//  FLASHRead               MULTI_FLASHRead
	//  FrrSet                  MULTI_FrrSet
	// ----------------------+-------------------------------
	//  InitAF9API              InitAF9API 
	//  FreeAF9API              FreeAF9API 
	//  IsVaildUSBHandler       //TBD:AF9:API? IsVaildUSBHandler 
	//  SetResolution           //TBD:AF9:API? SetResolution 
	//  SetFreqChange           //TBD:AF9:API? SetFreqChange 
	//  APSFrrSet               //TBD:AF9:API?
	//  APSFrrSet2              //TBD:AF9:API?
	//  APSSFRSet               //TBD:AF9:API?
	//****************************************************************************

	//****************************************************************************
	// 1CH API
	//****************************************************************************

	//-------------------------------------
	// Start the USB connection.
	//
	// @param	None
	// @return	-1 : USB library open fail.
	//			     0 : No USB device found.
	//			     1 : USB device found and connect ok.
	//
	// @note		USB driver must be installed.
	//		Refer to another document for instructions on installing USB drivers.
	//
	//DLLFunction int Start_Connection(void);	
	function AF9API_Start_Connection: Integer; stdcall; 	// AF9API_Start_Connection, AF9API_MULTI_Start_Connection

	//-------------------------------------
	// Stop the USB connection.
	//
	// @param	None
	// @return	0 : USB device stop fail.
	//			    1 : USB device stop and USB device release.
	//
	// @note		USB driver must be installed.
	//		Refer to another document for instructions on installing USB drivers.
	//
	//DLLFunction int Stop_Connection(void);
	function AF9API_Stop_Connection: Integer; stdcall;

	//-------------------------------------
	// Read the connection status of USB.
	//
	// @param	None
	// @return	0 : USB connection is not working.
	//			    1 : USB connected.
	//
	// @note		USB driver must be installed.
	//			Refer to another document for instructions on installing USB drivers.
	//
	//DLLFunction int Connection_Status(void);
	function AF9API_Connection_Status: Integer; stdcall;	// AF9API_Connection_Status, AF9API_MULTI_Connection_Status

	//-------------------------------------
	// Read the FPGA IP version.
	//
	// @param	None
	// @return	FPGA IP Version(xxx).
	//
	// @note		None
	//
	//DLLFunction int SW_Revision(void);
	function AF9API_SW_Revision: Integer; stdcall; // AF9API_SW_Revision, AF9API_MULTI_SW_Revision

	//-------------------------------------
	// Read the DLL version.
	//
	// @param	None
	// @return	DLL IP Version(x.xx).
	//
	// @note		None
	//
	//DLLFunction int DLL_Revision(void);	
	function AF9API_DLL_Revision: Integer; stdcall;

	//------------------------------------- 
	// Set the voltage of the power.
	//
	// @param	Type	  : Set the power type.
	// @param	ch		  : Set the power channel.
	// @param	Voltage	: Set the power voltage(mV, absolute value).
	// @param	Option	: Set the power option(plus voltage : 1, minus voltage : 2)
	// 
	// @return	0 : Failed to set the power.
	//			    1 : Successful set the power.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction BOOL DAC_SET(int Type, int channel, int Voltage, int Option);
	function AF9API_DAC_SET(nType: Integer; channel: Integer; Voltage: Integer; Option: Integer): Boolean; stdcall; //type->nType //DAC_SET, MULTI_DAC_SET

	//------------------------------------- 
	// Turn on/off the power.
	//
	// @param	Address	: Turn on/off the power address.
	// @param	ch		  : Turn on/off the power channel.
	// @param	Enable	: Turn on/off the power.
	// 
	// @return	0 : Failed to turn on/off the power.
	//			    1 : Successful turn on/off the power.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction BOOL ExtendIO_Set(int Address, int Channel, int Enable);
	function AF9API_ExtendIO_Set(Address: Integer; Channel: Integer; Enable: Integer): Boolean; stdcall; //ExtendIO_Set, MULTI_ExtendIO_Set

	//------------------------------------- 
	// Turn on/off all power and initial modlue.
	//
	// @param	OnOff	: Turn on/off all power and initial modlue(ON, OFF).
	//
	// @return	0 : Failed to turn on/off the module.
	//			    1 : Successful turn on/off the module.
	//
	// @note		From the SPI Flash of the module, 
	//			    power settings and other settings are read and processed.
	//
	//DLLFunction int AllPowerOnOff(int OnOff);
	function AF9API_AllPowerOnOff(OnOff: Integer): Integer; stdcall; //AllPowerOnOff, MULTI_AllPowerOnOff

	//------------------------------------- 
	// Display RGB Gray pattern.
	//
	// @param	R	: Red color(0 ~ 255).
	// @param	G	: Green color(0 ~ 255).
	// @param	B	: Blue color(0 ~ 255).
	//
	// @return	0 : Display fail.
	//			    1 : Display success.
	//
	// @note		None
	//
	//DLLFunction int APSPatternRGBSet(int R, int G, int B);
	function AF9API_APSPatternRGBSet(R,G,B: Integer): Integer; stdcall; //APSPatternRGBSet, MULTI_APSPatternRGBSet

	//------------------------------------- 
	// Display BOX RGB Gray pattern.
	//
	// @param	XOffset			: X position Offset(0 ~ 2920).
	// @param	YOffset			: Y position Offset(0 ~ 1900).
	// @param	Width			  : X Width(0 ~ 2920).
	// @param	Height			: Y Height(0 ~ 1900).
	// @param	R				    : Foreground red color(0 ~ 255).
	// @param	G				    : Foreground green color(0 ~ 255).
	// @param	B				    : Foreground blue color(0 ~ 255).
	// @param	Background_R	: Background red color(0 ~ 255).
	// @param	Background_G	: Background green color(0 ~ 255).
	// @param	Background_B	: Background blue color(0 ~ 255).
	// 
	// @return	0 : BOX display fail.
	//			    1 : BOX display success.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction int APSBoxPatternSet(int XOffset, int YOffset, int Width, int Height, int R, int G, int B, int Background_R, int Background_G, int Background_B);
	function AF9API_APSBoxPatternSet(XOffset,YOffset, Width,Height, R,G,B, BR,BG,BB: Integer): Integer; stdcall;  //APSBoxPatternSet, MULTI_APSBoxPatternSet

	//------------------------------------- 
	// Setting the internal register of the LGD.
	//
	// @param	Addr	: Address.
	// @param	data	: Data.
	//
	// @return	0 : Setting fail.
	//			    1 : Setting success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction int LGDSetReg(unsigned long Addr, unsigned char data);
	function AF9API_LGDSetReg(Addr: DWORD; data: Byte): Integer; stdcall; //AF9API_LGDSetReg, AF9API_MULTI_LGDSetReg

	//------------------------------------- 
	// Multiple setting the internal register of the LGD.
	//
	// @param	LCommand	: Command list(Addr : address, Data : data)
	// @param	CommandCnt	: Command count.
	//
	// @return	0 : Setting fail.
	//			    1 : Setting success.
	//
	// @note		typedef struct {
	//				unsigned long Addr;
	//				unsigned char Data;
	//			} LGD_COMMAND;
	// 
	//			Please contact the manufacturer for register information.
	//
	//DLLFunction int LGDSetRegM(LGD_COMMAND* LCommand, int CommandCnt);
	function AF9API_LGDSetRegM(LGDCommand: AF9_PLGDCommand; CommandCnt: Integer): Integer; stdcall; //LGDSetRegM, MULTI_LGDSetRegM

	//------------------------------------- 
	// Read the internal register of the LGD.
	//
	// @param	Addr	: Address
	//
	// @return	The data value of bytes received.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction unsigned char LGDGetReg(unsigned long Addr);
	function AF9API_LGDGetReg(Addr: DWORD): Byte; stdcall; //TBD:AF9_API? //LGDGetReg, MULTI_LGDGetReg

	//-------------------------------------
	// Multiple read the internal register of the LGD.
	//
	// @param	pBuffer		: Read value buffer.
	// @param	StartAddr	: Read start address.
	// @param	EndAddr		: Read end address.
	//
	// @return	0 : Read fail.
	//			    1 : Read success.
	// 
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction unsigned char LGDRangeGetReg(BYTE* pBuffer, unsigned long StartAddr, unsigned long EndAddr);
	function AF9API_LGDRangeGetReg(pBuffer: PByte; StartAddr,EndAddr: DWORD): Byte; stdcall; //LGDRangeGetReg, AF9API_MULTI_LGDRangeGetReg

	//------------------------------------- 
	// Setting the internal register of the APSOLUTION.
	//
	// @param	Addr	: Address.
	// @param	data	: Data.
	//
	// @return	0 : Setting fail.
	//			    1 : Setting success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction int APSSetReg(int Addr, int Data);
	function AF9API_APSSetReg(Addr: Integer; Data: Integer): Integer; stdcall; //APSSetReg, MULTI_APSSetReg

	//------------------------------------- Send the hex file CRC.
	// Send the hex file CRC.
	//
	// @param	CRC	: Checksum data(The sum of all values & 0xFFFF)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make checksum data.
	//			    Please refer to the example file.
	//
	//DLLFunction int SendHexFileCRC(unsigned short CRC);
	function AF9API_SendHexFileCRC(CRC: UInt16): Integer; stdcall; //SendHexFileCRC, MULTI_SendHexFileCRC


  	//-------------------------------------
	// Send the hex file and write in SPI flash.
	//
	// @param	pbyteBuffer	: Hex data buffer.
	// @param	len			    : hex data buffer length.
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		Please refer to the example file.
	//
	//DLLFunction int SendHexFile(BYTE* pbyteBuffer, int len);

	function AF9API_SendHexFileOC(pbyteBuffer: PByte; len: Integer): Integer; stdcall; //SendHexFile, MULTI_SendHexFile

	//-------------------------------------
	// Send the hex file and write in SPI flash.
	//
	// @param	pbyteBuffer	: Hex data buffer.
	// @param	len			    : hex data buffer length.
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		Please refer to the example file.
	//
	//DLLFunction int SendHexFile(BYTE* pbyteBuffer, int len);

	function AF9API_SendHexFile(pbyteBuffer: PByte; len: Integer): Integer; stdcall; //SendHexFile, MULTI_SendHexFile

	//------------------------------------- 
	// Send BMP file and view.
	//
	// @param	pbyteBuffer	: Raw data buffer.
	// @param	len			    : Raw data buffer length.
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make raw data.
	//			    Please refer to the example file.
	//
	//DLLFunction int WriteBMPFile(BYTE* pbyteBuffer, int len);
	function AF9API_WriteBMPFile(pbyteBuffer: PByte; len: Integer): Integer; stdcall; //WriteBMPFile, MULTI_WriteBMPFile

	//------------------------------------- Send BMP files
	// It only sends BMP files.
	//
	// @param	pbyteBuffer	: Raw data buffer.
	// @param	len			    : Raw data buffer length.
	// @param	num			    : Image file number(1 ~ 20).
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make raw data.
	//			    Please refer to the example file.
	//			    When it is rebooting the board, the data disappears. !!!!
	//
	//DLLFunction int BMPFileSend(BYTE* pbyteBuffer, int len, int num);
	function AF9API_BMPFileSend(pbyteBuffer: PByte; len: Integer; num: Integer): Integer; stdcall; //BMPFileSend, MULTI_BMPFileSend 

	//------------------------------------- 
	// Show the BMP file.
	//
	// @param	num	: Image file number(1 ~ 20).
	//
	// @return	0 : Send fail.
	//					1 : Send success.
	//
	// @note		If there is no image transmitted, a wrong screen appears.
	//
	//DLLFunction int BMPFileView(int num);
	function AF9API_BMPFileView(num: Integer): Integer; stdcall; //BMPFileView, MULTI_BMPFileView
	
	//------------------------------------- Read data from SPI flash.
	// Read data from SPI flash.
	//
	// @param	pBuffer		: SPI flash data buffer.
	// @param	StartAddr	: Read SPI flash start address(align 256byte).
	// @param	EndAddr		: Read SPI flash end address(align 256byte).
	//
	// @return	0 : Read fail.
	//					1 : Read success.
	//
	// @note		None
	//
	//DLLFunction unsigned char FLASHRead(BYTE* pBuffer, unsigned long StartAddr, unsigned long EndAddr);
	function AF9API_FLASHRead(pBuffer: PByte; StartAddr,EndAddr: DWORD): Byte; stdcall; //FLASHRead, MULTI_FLASHRead

	//------------------------------------- FRR Function.
	// FRR Function.
	//
	// @param	FrrStart : FRR function start.
	// @param	R		   : Foreground red color(0 ~ 255).
	// @param	G		   : Foreground green color(0 ~ 255).
	// @param	B		   : Foreground blue color(0 ~ 255).
	// @param	BR		 : Background red color(0 ~ 255).
	// @param	BG		 : Background green color(0 ~ 255).
	// @param	BB		 : Background blue color(0 ~ 255).
	// @param	PTN1	 : Pattern1(1 ~ 6).
	// @param	PTN2	 : Pattern2(1 ~ 6).
	// @param	PTN3	 : Pattern3(1 ~ 6).
	// @param	PTN4	 : Pattern4(1 ~ 6).
	// @param	PTN5	 : Pattern5(1 ~ 6).
	// @param	PTN6	 : Pattern6(1 ~ 6).
	// @param	Hz	 	 : Frequency Set.
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		Please contact the manufacturer for more information.
	//
	//DLLFunction int FrrSet(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTN1, BYTE PTN2, BYTE PTN3, BYTE PTN4, BYTE PTN5, BYTE PTN6, int Hz);
	function AF9API_FrrSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTN1,PTN2,PTN3,PTN4,PTN5,PTN6: Byte; Hz: Integer): Integer; stdcall; //FrrSeta, MULTI_FrrSet

	//****************************************************************************
	// Multiple(2CH) API
	//****************************************************************************

	//------------------------------------- Start the multi USB connection.
	// Start the multi USB connection.
	//
	// @param	None
	// @return	-1 : USB library open fail.
	//			     0 : No USB device found.
	//			     1 : USB device found and connect ok.
	//
	// @note		USB driver must be installed.
	//					Refer to another document for instructions on installing USB drivers.
	//           Two USBs must be connected. //TBD:ITOLED???
	// 
	//DLLFunction int MULTI_Start_Connection(void);
	function AF9API_MULTI_Start_Connection: Integer; stdcall; 

	//------------------------------------- Read the connection status of USB.
	// Read the connection status of USB.
	//
	// @param	CH	: Set the USB device channel(CH1, CH2)
	// @return	0 : USB connection is not working.
	//					1 : USB connected.
	//
	// @note		USB driver must be installed.
	//					Refer to another document for instructions on installing USB drivers.
	//
	//DLLFunction int MULTI_Connection_Status(int CH);
	function AF9API_MULTI_Connection_Status(CH: Integer): Integer; stdcall;

	//------------------------------------- Read multiple FPGA IP versions.
	// Read multiple FPGA IP versions.
	//
	// @param	None
	// @return	FPGA IP Version(xxx).
	//
	// @note		None
	//
	//DLLFunction int MULTI_SW_Revision(int CH);
	function AF9API_MULTI_SW_Revision(CH: Integer): Integer; stdcall;


	//------------------------------------- Set the voltage of multiple power.
	// Set the voltage of multiple power.
	//
	// @param	Type	: Set the power type.
	// @param	channel	: Set the power channel.
	// @param	Voltage	: Set the power voltage(mV, absolute value).
	// @param	Option	: Set the power option(plus voltage : 1, minus voltage : 2)
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Failed to set the power.
	//			1 : Successful set the power.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction BOOL MULTI_DAC_SET(int Type, int channel, int Voltage, int Option, int CH);
	function AF9API_MULTI_DAC_SET(nType: Integer; channel: Integer; Voltage: Integer; Option: Integer; CH: Integer): Boolean; stdcall; //type->nType


	//------------------------------------- Turn on/off multiple power.
	// Turn on/off multiple power.
	//
	// @param	Address	: Turn on/off the power address.
	// @param	Channel	: Turn on/off the power channel.
	// @param	Enable	: Turn on/off the power.
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Failed to turn on/off the power.
	//			1 : Successful turn on/off the power.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction BOOL MULTI_ExtendIO_Set(int Address, int Channel, int Enable, int CH);
	function AF9API_MULTI_ExtendIO_Set(Address: Integer; Channel: Integer; Enable: Integer; CH: Integer): Boolean; stdcall;

	//------------------------------------- 
	// multiple turn on/off all power and initial module.
	//
	// @param	OnOff	: Turn on/off all power and initial module(ON, OFF).
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Failed to turn on/off the module.
	//			1 : Successful turn on/off the module.
	//
	// @note		From the SPI Flash of the module,
	//			power settings and other settings are read and processed.
	//
	//DLLFunction int MULTI_AllPowerOnOff(int OnOff, int CH);
	function AF9API_MULTI_AllPowerOnOff(OnOff: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- 
	// Display multiple RGB Gray patterns.
	//
	// @param	R	: Red color(0 ~ 255).
	// @param	G	: Green color(0 ~ 255).
	// @param	B	: Blue color(0 ~ 255).
	// @param	CH	: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Display fail.
	//			1 : Display success.
	//
	// @note		None
	//
	//DLLFunction int MULTI_APSPatternRGBSet(int R, int G, int B, int CH);
	function AF9API_MULTI_APSPatternRGBSet(R,G,B: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- 
	// Display multiple BOX RGB Gray pattern.
	//
	// @param	XOffset			: X position Offset(0 ~ 2920).
	// @param	YOffset			: Y position Offset(0 ~ 1900).
	// @param	Width			: X Width(0 ~ 2920).
	// @param	Height			: Y Height(0 ~ 1900).
	// @param	R				: Foreground red color(0 ~ 255).
	// @param	G				: Foreground green color(0 ~ 255).
	// @param	B				: Foreground blue color(0 ~ 255).
	// @param	Background_R	: Background red color(0 ~ 255).
	// @param	Background_G	: Background green color(0 ~ 255).
	// @param	Background_B	: Background blue color(0 ~ 255).
	// @param	CH				: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : BOX display fail.
	//			1 : BOX display success.
	//
	// @note		For more information, refer to other documents.
	//
	//DLLFunction int MULTI_APSBoxPatternSet(int XOffset, int YOffset, int Width, int Height, int R, int G, int B, int Background_R, int Background_G, int Background_B, int CH);
	function AF9API_MULTI_APSBoxPatternSet(XOffset,YOffset, Width,Height, R,G,B, BR,BG,BB: Integer; CH: Integer): Integer; stdcall; 

	//------------------------------------- 
	// Multiple setting the internal register of the LGD.
	//
	// @param	Addr	: Address.
	// @param	data	: Data.
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Setting fail.
	//			1 : Setting success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction int MULTI_LGDSetReg(unsigned long Addr, unsigned char Data, int CH);
	function AF9API_MULTI_LGDSetReg(Addr: DWORD; data: Byte; CH: Integer): Integer; stdcall; 

	//------------------------------------- 
	// Multiple setting the internal register of the LGD.
	//
	// @param	LCommand	: Command list(Addr : address, Data : data)
	// @param	CommandCnt	: Command count.
	// @param	CH			: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Setting fail.
	//			1 : Setting success.
	//
	// @note		typedef struct {
	//				unsigned long Addr;
	//				unsigned char Data;
	//			} LGD_COMMAND;
	//
	//			Please contact the manufacturer for register information.
	//
	//DLLFunction int MULTI_LGDSetRegM(LGD_COMMAND* LCommand, int CommandCnt, int CH);
	function AF9API_MULTI_LGDSetRegM(LGDCommand: AF9_PLGDCommand; CommandCnt: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- 
	// Multiple read the internal register of the LGD.
	//
	// @param	Addr	: Address
	// @param	CH		: Set the USB device channel(CH1, CH2)
	//
	// @return	The data value of bytes received.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction unsigned char MULTI_LGDGetReg(unsigned long Addr, int CH);
	function AF9API_MULTI_LGDGetReg(Addr: DWORD; CH: Integer): Byte; stdcall; //TBD:AF9_API? 

	//------------------------------------- 
	// Multiple read the internal register of the LGD.
	//
	// @param	pBuffer		: Read value buffer.
	// @param	StartAddr	: Read start address.
	// @param	EndAddr		: Read end address.
	// @param	CH			  : Set the USB device channel(CH1, CH2)
	// 
	// @return	0 : Read fail.
	//			    1 : Read success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction unsigned char MULTI_LGDRangeGetReg(BYTE* pBuffer, unsigned long StartAddr, unsigned long EndAddr, int CH);
	function AF9API_MULTI_LGDRangeGetReg(pBuffer: PByte; StartAddr,EndAddr: DWORD; CH: Integer): Byte; stdcall;

	//------------------------------------- 
	// Multiple setting the internal register of the APSOLUTION.
	//
	// @param	Addr	: Address.
	// @param	data	: Data.
	// @param	CH		: Set the USB device channel(CH1, CH2)
	// 
	// @return	0 : Setting fail.
	//			    1 : Setting success.
	//
	// @note		Please contact the manufacturer for register information.
	//
	//DLLFunction int MULTI_APSSetReg(int Addr, int Data, int CH);
	function AF9API_MULTI_APSSetReg(Addr: Integer; Data: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- 
	// Multiple send the hex file CRC.
	//
	// @param	CRC	: Checksum data(The sum of all values & 0xFFFF)
	// @param	CH	: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make checksum data.
	//			    Please refer to the example file.
	//
	//DLLFunction int MULTI_SendHexFileCRC(unsigned short CRC, int CH);
	function AF9API_MULTI_SendHexFileCRC(CRC: UInt16; CH: Integer): Integer; stdcall;

	//------------------------------------- 
	// Multiple send the hex file and write in SPI flash.
	//
	// @param	pbyteBuffer	: Hex data buffer.
	// @param	len			    : hex data buffer length.
	// @param	CH			    : Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		Please refer to the example file.
	//
	//DLLFunction int MULTI_SendHexFile(BYTE* pbyteBuffer, int len, int CH);
	function AF9API_MULTI_SendHexFile(pbyteBuffer: PByte; len: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- 
	// Multiple send BMP file and view.
	//
	// @param	pbyteBuffer	: raw data buffer.
	// @param	len			    : raw data buffer length.
	// @param	CH			    : Set the USB device channel(CH1, CH2)
	// 
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make raw data.
	//			Please refer to the example file.
	//
	//DLLFunction int MULTI_WriteBMPFile(BYTE* pbyteBuffer, int len, int CH);
	function AF9API_MULTI_WriteBMPFile(pbyteBuffer: PByte; len: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- 
	// It only sends multiple BMP files.
	//
	// @param	pbyteBuffer	: Raw data buffer.
	// @param	len			    : Raw data buffer length.
	// @param	num			    : Image file number(1 ~ 20).
	// @param	CH			    : Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		There is a way to make raw data.
	//			Please refer to the example file.
	//			When it is rebooting the board, the data disappears.
	//			
	//DLLFunction int MULTI_BMPFileSend(BYTE* pbyteBuffer, int len, int num, int CH);
	function AF9API_MULTI_BMPFileSend(pbyteBuffer: PByte; len: Integer; num: Integer; CH: Integer): Integer; stdcall;

	//-------------------------------------
	// Show the multiple BMP file.
	//
	// @param	num	    : Image file number(1 ~ 10).
	// @param	CH			: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		If there is no image transmitted, a wrong screen appears.
	//
	//DLLFunction int MULTI_BMPFileView(int num, int CH);
	function AF9API_MULTI_BMPFileView(num: Integer; CH: Integer): Integer; stdcall;

	//-------------------------------------
	// Multiple read data from SPI flash.
	//
	// @param	pBuffer		: SPI flash data buffer.
	// @param	StartAddr	: Read SPI flash start address(align 256byte).
	// @param	EndAddr		: Read SPI flash end address(align 256byte).
	// @param	CH			: Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Read fail.
	//			    1 : Read success.
	//
	// @note		None
	//
	//DLLFunction unsigned char MULTI_FLASHRead(BYTE* pBuffer, unsigned long StartAddr, unsigned long EndAddr, int CH);
	function AF9API_MULTI_FLASHRead(pBuffer: PByte; StartAddr,EndAddr: DWORD; CH: Integer): Byte; stdcall;

	//------------------------------------- 
	// Multiple FRR Function.
	//
	// @param	FrrStart : FRR function start.
	// @param	R		   : Foreground red color(0 ~ 255).
	// @param	G		   : Foreground green color(0 ~ 255).
	// @param	B    	 : Foreground blue color(0 ~ 255).
	// @param	BR		 : Background red color(0 ~ 255).
	// @param	BG		 : Background green color(0 ~ 255).
	// @param	BB		 : Background blue color(0 ~ 255).
	// @param	PTN1	 : Pattern1(1 ~ 6).
	// @param	PTN2	 : Pattern2(1 ~ 6).
	// @param	PTN3	 : Pattern3(1 ~ 6).
	// @param	PTN4	 : Pattern4(1 ~ 6).
	// @param	PTN5	 : Pattern5(1 ~ 6).
	// @param	PTN6	 : Pattern6(1 ~ 6).
	// @param	Hz	 	 : Frequency Set.
	// @param	CH		 : Set the USB device channel(CH1, CH2)
	//
	// @return	0 : Send fail.
	//			    1 : Send success.
	//
	// @note		Please contact the manufacturer for more information.
	//
	//DLLFunction int MULTI_FrrSet(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTN1, BYTE PTN2, BYTE PTN3, BYTE PTN4, BYTE PTN5, BYTE PTN6, int Hz, int CH);
	function AF9API_MULTI_FrrSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTN1,PTN2,PTN3,PTN4,PTN5,PTN6: Byte; Hz: Integer; CH: Integer): Integer; stdcall;

	//------------------------------------- 
	//
	// LGD function.
	//
	// Please contact the manufacturer for more information.
	// 

	// DLLFunction void InitAF9API(void);
	//TBD:AF9:v2.02? procedure	AF9API_InitAF9API; stdcall; // Init AF9API Written by Steve //TBD:AF9:API?
	// DLLFunction void FreeAF9API(void);
	procedure	AF9API_FreeAF9API; stdcall; // Free AF9API Written by Steve //TBD:AF9:API?
	// DLLFunction BOOL IsVaildUSBHandler(void);
	function AF9API_IsVaildUSBHandler: Boolean; stdcall;	// USB Handler Validation Written by Steve //TBD:AF9:API?
	//DLLFunction int SetResolution(int ResHRes, int ResHBP, int ResHSA, int ResHFP, int ResVRes, int ResVBP, int ResVSA, int ResVFP);
	function AF9API_SetResolution(ResHRes,ResHBP,ResHSA,ResHFP, ResVRes,ResVBP,ResVSA,ResVFP: Integer): Integer; stdcall; //TBD:AF9:API?
	//DLLFunction int SetFreqChange(BYTE* pbyteBuffer, int len, int HzCnt, int Repeat);
	function AF9API_SetFreqChange(pbyteBuffer: PByte; len: Integer; HzCnt: Integer; nRepeat: Integer): Integer; stdcall; //TBD:AF9:API?

	//DLLFunction int APSFrrSet(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTNCnt, DWORD PTN);
	function AF9API_APSFrrSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD): Integer; stdcall; //TBD:AF9:API?
	//DLLFunction int APSFrrSet2(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTNCnt, DWORD PTN, int Hz);
	function AF9API_APSFrrSet2(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD; Hz:Integer): Integer; stdcall; //TBD:AF9:API?
	//DLLFunction int APSSFRSet(int FrrStart, BYTE R, BYTE G, BYTE B, BYTE BR, BYTE BG, BYTE BB, BYTE PTNCnt, DWORD PTN, int Hz);
	function AF9API_APSSFRSet(FrrStart: Integer; R,G,B: Byte; BR,BG,BB: Byte; PTNCnt: Byte; PTN: DWORD; Hz:Integer): Integer; stdcall; //TBD:AF9:API?


//##############################################################################
//##############################################################################
//
//##############################################################################
//##############################################################################

const

	AF9API_DLL = 'AF9_API2.dll';

  function AF9API_Start_Connection; external AF9API_DLL name 'Start_Connection';
  function AF9API_Stop_Connection; external AF9API_DLL name 'Stop_Connection';
  function AF9API_Connection_Status; external AF9API_DLL name 'Connection_Status';
  function AF9API_SW_Revision; external AF9API_DLL name 'SW_Revision';
  function AF9API_DLL_Revision; external AF9API_DLL name 'DLL_Revision';
  function AF9API_DAC_SET; external AF9API_DLL name 'DAC_SET';
  function AF9API_ExtendIO_Set; external AF9API_DLL name 'ExtendIO_Set';
  function AF9API_AllPowerOnOff; external AF9API_DLL name 'AllPowerOnOff';
  function AF9API_APSPatternRGBSet; external AF9API_DLL name 'APSPatternRGBSet';
  function AF9API_APSBoxPatternSet; external AF9API_DLL name 'APSBoxPatternSet';
  function AF9API_LGDSetReg; external AF9API_DLL name 'LGDSetReg';
  function AF9API_LGDSetRegM; external AF9API_DLL name 'LGDSetRegM';
  function AF9API_LGDGetReg; external AF9API_DLL name 'LGDGetReg';
  function AF9API_LGDRangeGetReg; external AF9API_DLL name 'LGDRangeGetReg';
  function AF9API_APSSetReg; external AF9API_DLL name 'APSSetReg';
  function AF9API_SendHexFileCRC; external AF9API_DLL name 'SendHexFileCRC';
  function AF9API_SendHexFile; external AF9API_DLL name 'SendHexFile';
  function AF9API_SendHexFileOC; external AF9API_DLL name 'SendHexFileOC';
  function AF9API_WriteBMPFile; external AF9API_DLL name 'WriteBMPFile';
	function AF9API_BMPFileSend; external AF9API_DLL name 'BMPFileSend';
	function AF9API_BMPFileView;  external AF9API_DLL name 'BMPFileView';
  function AF9API_FLASHRead; external AF9API_DLL name 'FLASHRead';
  function AF9API_FrrSet; external AF9API_DLL name 'FrrSet';

  function AF9API_MULTI_Start_Connection; external AF9API_DLL name 'MULTI_Start_Connection';
//function AF9API_MULTI_Stop_Connection; external AF9API_DLL name 'MULTI_Stop_Connection'; //TBD:AF9:API?
  function AF9API_MULTI_Connection_Status; external AF9API_DLL name 'MULTI_Connection_Status';
  function AF9API_MULTI_SW_Revision; external AF9API_DLL name 'MULTI_SW_Revision';
//function AF9API_MULTI_DLL_Revision; external AF9API_DLL name 'MULTI_DLL_Revision'; //TBD:AF9:API?
  function AF9API_MULTI_DAC_SET; external AF9API_DLL name 'MULTI_DAC_SET';
  function AF9API_MULTI_ExtendIO_Set; external AF9API_DLL name 'MULTI_ExtendIO_Set';
  function AF9API_MULTI_AllPowerOnOff; external AF9API_DLL name 'MULTI_AllPowerOnOff';
  function AF9API_MULTI_APSPatternRGBSet; external AF9API_DLL name 'MULTI_APSPatternRGBSet';
  function AF9API_MULTI_APSBoxPatternSet; external AF9API_DLL name 'MULTI_APSBoxPatternSet';
  function AF9API_MULTI_LGDSetReg; external AF9API_DLL name 'MULTI_LGDSetReg';
  function AF9API_MULTI_LGDSetRegM; external AF9API_DLL name 'MULTI_LGDSetRegM';
  function AF9API_MULTI_LGDGetReg; external AF9API_DLL name 'MULTI_LGDGetReg';
  function AF9API_MULTI_LGDRangeGetReg; external AF9API_DLL name 'MULTI_LGDRangeGetReg';
  function AF9API_MULTI_APSSetReg; external AF9API_DLL name 'MULTI_APSSetReg';
  function AF9API_MULTI_SendHexFileCRC; external AF9API_DLL name 'MULTI_SendHexFileCRC';
  function AF9API_MULTI_SendHexFile; external AF9API_DLL name 'MULTI_SendHexFile';
  function AF9API_MULTI_WriteBMPFile; external AF9API_DLL name 'MULTI_WriteBMPFile';
	function AF9API_MULTI_BMPFileSend; external AF9API_DLL name 'MULTI_BMPFileSend';
	function AF9API_MULTI_BMPFileView;  external AF9API_DLL name 'MULTI_BMPFileView';
  function AF9API_MULTI_FLASHRead; external AF9API_DLL name 'MULTI_FLASHRead';
  function AF9API_MULTI_FrrSet; external AF9API_DLL name 'MULTI_FrrSet';

	//TBD:AF9:v2.02? procedure AF9API_InitAF9API; external AF9API_DLL name 'InitAF9API';
  procedure AF9API_FreeAF9API; external AF9API_DLL name 'FreeAF9API';
  function AF9API_IsVaildUSBHandler; external AF9API_DLL name 'IsVaildUSBHandler';
  function AF9API_SetResolution; external AF9API_DLL name 'SetResolution';
  function AF9API_SetFreqChange; external AF9API_DLL name 'SetFreqChange';

  function AF9API_APSFrrSet; external AF9API_DLL name 'APSFrrSet';
  function AF9API_APSFrrSet2; external AF9API_DLL name 'APSFrrSet2';
  function AF9API_APSSFRSet; external AF9API_DLL name 'APSSFRSet';

//function AF9API_APS_REG_Set; external AF9API_DLL name 'APS_REG_Set';
//function AF9API_PatternRGBSet; external AF9API_DLL name 'PatternRGBSet';
//function AF9API_Set_Power; external AF9API_DLL name 'Set_Power';
//function AF9API_WriteHexFile; external AF9API_DLL name 'WriteHexFile';

//##############################################################################
//###
//### Additional for ITOLED
//###
//##############################################################################

const

  // Additional for ITOLED

  //  - AF9API_Start_Connection
  AF9API_STARTCONN_USB_OPENFAIL = -1;
  AF9API_STARTCONN_USB_NOTFOUND = 0;
  AF9API_STARTCONN_OK           = 1;

  //  - AF9_Connection_Status
  //  - AF9_APSPatternRGBSet
  AF9API_RESULT_OK = 1; //
  AF9API_RESULT_NG = 0;

  //
  CMD_DISPLAY_OFF = 0;
  CMD_DISPLAY_ON  = 1;

  // arbitrary value for AF9-FPGA RGD_REG(T-CON?) and APS_REG
  LGD_REG_DEVICE  = $A0; //arbitrary !!!
  APS_REG_DEVICE  = $B0; //arbitrary !!!

  PG_TYPE_AF9   = 9; //TBD:ITOLED?

  {$IFDEF SIMULATOR_PANEL}
  SIM_TCON_SIZE   = 1024*64;
  SIM_APSREG_SIZE = 1024*64;
  {$ENDIF}

  MAX_FLASHSIZE_BYTE = 4*1024*1024; // 8M //TBD:ITOLED? (PANEL-dependent)

type

  // AF9: AF9ConnStDisconn -> (Call Start_Connection) -> AF9ConnStStart -> (Call Conn_Status:OK) -> (Call SW_Revision) -> AF9ConnStConn
	enumPgConnSt = (pgConnStDisconn=0, pgConnStStart=1, pgConnStConn=2);
//TPgStatus = (pgDisconnect, pgConnect, pgWait, pgDone, pgForceStop);  //TBD:ITOLED?

  //-----------------
  RPwrValAF9 = record
		A : integer; //TBD:AF9?
  end;
  RPwrVal = RPwrValAF9;

implementation

end.


