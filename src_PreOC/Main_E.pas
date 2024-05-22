unit Main_E;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RzPanel, RzButton,
  RzStatus, ALed, System.ImageList, Vcl.ImgList;

type
  TfrmEEPROM = class(TForm)
    ilFlag: TImageList;
    ilIMGMain: TImageList;
    pnlSysInfo: TRzPanel;
    RzGroupBox3: TRzGroupBox;
    RzPanel11: TRzPanel;
    pnlResolution: TRzPanel;
    pnlScriptVer: TRzPanel;
    RzPanel18: TRzPanel;
    RzPanel12: TRzPanel;
    pnlPatternGroup: TRzPanel;
    RzPanel2: TRzPanel;
    pnlCheckSum: TRzPanel;
    RzGroupBox4: TRzGroupBox;
    ledGmes: ThhALed;
    ledBcr1: ThhALed;
    ledSwJigA: ThhALed;
    RzPanel6: TRzPanel;
    pnlHost: TRzPanel;
    pnlBcr1: TRzPanel;
    pnlBcrStatus1: TRzPanel;
    pnlSwitch: TRzPanel;
    pnlSwA: TRzPanel;
    grpDioSig: TRzGroupBox;
    ledDioConnected: ThhALed;
    RzPanel17: TRzPanel;
    pnlDioStatus: TRzPanel;
    RzGroupBox1: TRzGroupBox;
    RzPanel1: TRzPanel;
    pnlUserId: TRzPanel;
    RzPanel4: TRzPanel;
    pnlStationNo: TRzPanel;
    RzPanel9: TRzPanel;
    pnlUserName: TRzPanel;
    btnMaintMsg: TRzBitBtn;
    RzStatusBar1: TRzStatusBar;
    RzResourceStatus1: TRzResourceStatus;
    RzClockStatus1: TRzClockStatus;
    RzStatusPane1: TRzStatusPane;
    RzStatusPane2: TRzStatusPane;
    RzKeyStatus1: TRzKeyStatus;
    tmrAlarmMsg: TTimer;
    tmrDisplayTestForm: TTimer;
    tolGroupMain: TRzToolbar;
    btnModel: TRzToolButton;
    rzspcr8: TRzSpacer;
    btnExit: TRzToolButton;
    btnLogIn: TRzToolButton;
    rzspcr1: TRzSpacer;
    btnModelChange: TRzToolButton;
    rzspcr2: TRzSpacer;
    btnInit: TRzToolButton;
    RzSpacer1: TRzSpacer;
    RzSpacer2: TRzSpacer;
    RzSpacer3: TRzSpacer;
    RzSpacer4: TRzSpacer;
    btnStation: TRzToolButton;
    btnMaint: TRzToolButton;
    pnlModelNameInfo: TPanel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmEEPROM: TfrmEEPROM;

implementation

{$R *.dfm}

end.
