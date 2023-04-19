unit VirtualBcrForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DefScript,GMesCom,CommonClass,DefCommon;

type
  TVirtualBcr = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edtVirtualBcr1: TEdit;
    edtVirtualBcr2: TEdit;
    edtVirtualBcr3: TEdit;
    edtVirtualBcr4: TEdit;
    btnVirtualBcr: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Button13: TButton;
    Button14: TButton;
    Button15: TButton;
    Button16: TButton;
    procedure btnVirtualBcrClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);
    procedure Button15Click(Sender: TObject);
    procedure Button16Click(Sender: TObject);
  private
    { Private declarations }

    procedure SendMainGuiDisplay(Channel,nGuiMode : Integer; nP1: Integer = 0; nP2: Integer = 0; nP3 : Integer = 0);
    procedure SendTestGuiDisplay(Channel,nGuiMode : Integer; sMsg: string = ''; sMsg2: string = ''; nParam: Integer = 0; nParam2 : Integer = 0);
  public
      m_MainHandle : HWND ;
    m_TestHandle : HWND ;

    { Public declarations }
  end;

var
  VirtualBcr: TVirtualBcr;

implementation

uses
Test4ChOC,pasScriptClass, DefGmes;

{$R *.dfm}

//constructor TVirtualBcr.Create( hMain, hTest: HWND );
//begin
//m_MainHandle := hMain;
// m_TestHandle := hTest;
//
//end;

//destructor TVirtualBcr.Destroy;
//begin
//
//  inherited;
//end;

procedure TVirtualBcr.btnVirtualBcrClick(Sender: TObject);
var
i : Integer;
begin
  if Length(edtVirtualBcr1.Text) > 0 then frmTest4ChOC[0].getBcrData(edtVirtualBcr1.Text);
  if Length(edtVirtualBcr2.Text) > 0 then frmTest4ChOC[0].getBcrData(edtVirtualBcr2.Text);
  if Length(edtVirtualBcr3.Text) > 0 then frmTest4ChOC[0].getBcrData(edtVirtualBcr3.Text);
  if Length(edtVirtualBcr4.Text) > 0 then frmTest4ChOC[0].getBcrData(edtVirtualBcr4.Text);
//  Close;
end;



procedure TVirtualBcr.Button10Click(Sender: TObject);
begin
  PasScr[2].m_nNgCode := StrToIntDef(Edit3.Text,0);
    PasScr[2].TestInfo.SerialNo := edtVirtualBcr3.Text;
//    PasScr[2].RunSeq(DefScript.SEQ_Finish);
//  PasScr[2].m_bIsProbeBackSig := False;
    DongaGmes.MesData[2].Rwk := Common.GmesInfo[PasScr[0].m_nNgCode ].MES_Code;
//  PasScr[0].RunSeq(DefScript.SEQ_Finish);
//  PasScr[0].m_bIsProbeBackSig := False;
   PasScr[2].CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(2,DefGmes.MES_EICR,1);
            SendTestGuiDisplay(2,DefGmes.MES_EICR, '','', 0);
  end,5000,1);
end;

procedure TVirtualBcr.Button11Click(Sender: TObject);
begin
  PasScr[3].m_nNgCode := 0;
  PasScr[3].TestInfo.SerialNo := edtVirtualBcr4.Text;
//  PasScr[3].RunSeq(DefScript.SEQ_Finish);
//  PasScr[3].m_bIsProbeBackSig := False;
    DongaGmes.MesData[3].Rwk := Common.GmesInfo[PasScr[0].m_nNgCode ].MES_Code;
//  PasScr[0].RunSeq(DefScript.SEQ_Finish);
//  PasScr[0].m_bIsProbeBackSig := False;
   PasScr[3].CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(3,DefGmes.MES_EICR,1);
            SendTestGuiDisplay(3,DefGmes.MES_EICR, '','', 0);
  end,5000,1);
end;

procedure TVirtualBcr.Button12Click(Sender: TObject);
begin
  PasScr[3].m_nNgCode := StrToIntDef(Edit4.Text,0);
    PasScr[3].TestInfo.SerialNo := edtVirtualBcr4.Text;
//    PasScr[3].RunSeq(DefScript.SEQ_Finish);
//  PasScr[3].m_bIsProbeBackSig := False;
    DongaGmes.MesData[3].Rwk := Common.GmesInfo[PasScr[0].m_nNgCode ].MES_Code;
//  PasScr[0].RunSeq(DefScript.SEQ_Finish);
//  PasScr[0].m_bIsProbeBackSig := False;
   PasScr[3].CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(3,DefGmes.MES_EICR,1);
            SendTestGuiDisplay(3,DefGmes.MES_EICR, '','', 0);
  end,5000,1);
end;

procedure TVirtualBcr.Button13Click(Sender: TObject);
begin

//    if not PasScr[i].m_bUse then Continue;
    SendTestGuiDisplay(0,DefCommon.MSG_MODE_BARCODE_READY,'','',1);

end;

procedure TVirtualBcr.Button14Click(Sender: TObject);
begin
    SendTestGuiDisplay(1,DefCommon.MSG_MODE_BARCODE_READY,'','',1);
end;

procedure TVirtualBcr.Button15Click(Sender: TObject);
begin
    SendTestGuiDisplay(2,DefCommon.MSG_MODE_BARCODE_READY,'','',1);
end;

procedure TVirtualBcr.Button16Click(Sender: TObject);
begin
    SendTestGuiDisplay(3,DefCommon.MSG_MODE_BARCODE_READY,'','',1);
end;

procedure TVirtualBcr.Button1Click(Sender: TObject);
begin
  edtVirtualBcr1.Text := Format('%s%.4d',['TEST', Random(10000)]);
end;

procedure TVirtualBcr.Button2Click(Sender: TObject);
begin
  edtVirtualBcr2.Text := Format('%s%.4d',['TEST', Random(10000)]);
end;

procedure TVirtualBcr.Button3Click(Sender: TObject);
begin
  edtVirtualBcr3.Text := Format('%s%.4d',['TEST', Random(10000)]);
end;

procedure TVirtualBcr.Button4Click(Sender: TObject);
begin
  edtVirtualBcr4.Text := Format('%s%.4d',['TEST', Random(10000)]);
end;


procedure TVirtualBcr.SendMainGuiDisplay(Channel,nGuiMode, nP1, nP2, nP3: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData     : RGuiScript;
begin
  GuiData.MsgType := DefCommon.MSG_TYPE_SCRIPT;
  GuiData.Channel := Channel;
  GuiData.Mode    := nGuiMode;
  GuiData.nParam  := nP1;
  GuiData.nParam2 := nP2;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_MainHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TVirtualBcr.SendTestGuiDisplay(Channel,nGuiMode: Integer; sMsg, sMsg2: string; nParam, nParam2: Integer);
var
  ccd         : TCopyDataStruct;
  GuiData    : RGuiScript;
begin
  GuiData.MsgType := defCommon.MSG_TYPE_SCRIPT;
  GuiData.Channel := Channel;
  GuiData.Mode    := nGuiMode;
  GuiData.Msg     := sMsg;
  GuiData.Msg2    := sMsg2;
  GuiData.nParam  := nParam;
  GuiData.nParam2 := nParam2;
  ccd.dwData      := 0;
  ccd.cbData      := SizeOf(GuiData);
  ccd.lpData      := @GuiData;
  SendMessage(m_TestHandle,WM_COPYDATA,0, LongInt(@ccd));
end;

procedure TVirtualBcr.Button5Click(Sender: TObject);
begin
  PasScr[0].m_nNgCode := 0;
    PasScr[0].TestInfo.SerialNo := edtVirtualBcr1.Text;
    DongaGmes.MesData[0].Rwk := Common.GmesInfo[PasScr[0].m_nNgCode ].MES_Code;
//  PasScr[0].RunSeq(DefScript.SEQ_Finish);
//  PasScr[0].m_bIsProbeBackSig := False;
   PasScr[0].CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(0,DefGmes.MES_EICR,1);
            SendTestGuiDisplay(0,DefGmes.MES_EICR, '','', 0);
  end,5000,1);
end;

procedure TVirtualBcr.Button6Click(Sender: TObject);
begin
  PasScr[0].m_nNgCode := StrToIntDef(Edit1.Text,0);
  PasScr[0].TestInfo.SerialNo := edtVirtualBcr1.Text;
//  PasScr[0].RunSeq(DefScript.SEQ_Finish);
//  PasScr[0].m_bIsProbeBackSig := False;
    DongaGmes.MesData[0].Rwk := Common.GmesInfo[PasScr[0].m_nNgCode ].MES_Code;
//  PasScr[0].RunSeq(DefScript.SEQ_Finish);
//  PasScr[0].m_bIsProbeBackSig := False;
   PasScr[0].CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(0,DefGmes.MES_EICR,1);
            SendTestGuiDisplay(0,DefGmes.MES_EICR, '','', 0);
  end,5000,1);

end;

procedure TVirtualBcr.Button7Click(Sender: TObject);
begin
  PasScr[1].m_nNgCode := 0;
    PasScr[1].TestInfo.SerialNo := edtVirtualBcr2.Text;
        DongaGmes.MesData[1].Rwk := Common.GmesInfo[PasScr[0].m_nNgCode ].MES_Code;
//  PasScr[0].RunSeq(DefScript.SEQ_Finish);
//  PasScr[0].m_bIsProbeBackSig := False;
   PasScr[1].CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(1,DefGmes.MES_EICR,1);
            SendTestGuiDisplay(1,DefGmes.MES_EICR, '','', 0);
  end,5000,1);
//  PasScr[1].RunSeq(DefScript.SEQ_Finish);
//  PasScr[1].m_bIsProbeBackSig := False;
end;

procedure TVirtualBcr.Button8Click(Sender: TObject);
begin
  PasScr[1].m_nNgCode := StrToIntDef(Edit2.Text,0);
    PasScr[1].TestInfo.SerialNo := edtVirtualBcr2.Text;
        DongaGmes.MesData[1].Rwk := Common.GmesInfo[PasScr[0].m_nNgCode ].MES_Code;
//  PasScr[0].RunSeq(DefScript.SEQ_Finish);
//  PasScr[0].m_bIsProbeBackSig := False;
   PasScr[1].CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(1,DefGmes.MES_EICR,1);
            SendTestGuiDisplay(1,DefGmes.MES_EICR, '','', 0);
  end,5000,1);
//  PasScr[1].RunSeq(DefScript.SEQ_Finish);
//  PasScr[1].m_bIsProbeBackSig := False;
end;

procedure TVirtualBcr.Button9Click(Sender: TObject);
begin
  PasScr[2].m_nNgCode := 0;
  PasScr[2].TestInfo.SerialNo := edtVirtualBcr3.Text;
      DongaGmes.MesData[2].Rwk := Common.GmesInfo[PasScr[0].m_nNgCode ].MES_Code;
//  PasScr[0].RunSeq(DefScript.SEQ_Finish);
//  PasScr[0].m_bIsProbeBackSig := False;
   PasScr[2].CheckSyncCmdAck(procedure begin
            SendMainGuiDisplay(2,DefGmes.MES_EICR,1);
            SendTestGuiDisplay(2,DefGmes.MES_EICR, '','', 0);
  end,5000,1);
//  PasScr[2].RunSeq(DefScript.SEQ_Finish);
//  PasScr[2].m_bIsProbeBackSig := False;
end;

end.
