unit ECSRequestForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, AdvUtil, Vcl.StdCtrls, Vcl.Grids, AdvObj, BaseGrid, AdvGrid,
  CommPLC_ECS,DefCommon, Vcl.ExtCtrls, RzCmboBx, ALed;

type
  TECSTestForm = class(TForm)
    pnlGlassData: TPanel;
    Label4: TLabel;
    grdGlassData: TAdvStringGrid;
    Label1: TLabel;
    cboLostDataCH: TRzComboBox;
    Label2: TLabel;
    Label3: TLabel;
    edLostDataPanelID: TEdit;
    cboRequestOption: TRzComboBox;
    Label5: TLabel;
    btnLostData: TButton;
    edPanelCode: TEdit;
    Label6: TLabel;
    cboTakeOutCH: TRzComboBox;
    Label7: TLabel;
    edTakeOutPanelID: TEdit;
    btnTakeOut: TButton;
    memoLog: TMemo;
    tmrRefresh: TTimer;
    pnlStateLost: TPanel;
    pnlStateTakeOut: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure Edit2KeyPress(Sender: TObject; var Key: Char);
    procedure btnLostDataClick(Sender: TObject);
    procedure btnTakeOutClick(Sender: TObject);
    procedure cboTakeOutCHChange(Sender: TObject);
    procedure tmrRefreshTimer(Sender: TObject);
  private
    { Private declarations }
    procedure AddLog(sLog: String);
  public
    { Public declarations }
  end;

var
  ECSTestForm: TECSTestForm;

implementation

{$R *.dfm}

procedure TECSTestForm.btnLostDataClick(Sender: TObject);
var
  nGlassCode, nRequestOption: Integer;
  nRes: Integer;
  sGlassID : string;
  nCh : Integer;
begin
  sGlassID := edLostDataPanelID.Text;
  nGlassCode:= StrToInt(edPanelCode.Text);
  nRequestOption:= cboRequestOption.ItemIndex;
  nCh := cboLostDataCH.ItemIndex;
  case nRequestOption of
    0 : begin
      sGlassID := '';
      if nGlassCode < 1 then begin
         ShowMessage('Check out the Panel Code');
         Exit;
      end;
    end;
    1 : begin
      nGlassCode := 0;
      if Length(sGlassID) = 0 then begin
         ShowMessage('Check out the Panel ID');
         Exit;
      end;
    end;
  end;
  pnlStateLost.Font.Color := clYellow;
  pnlStateLost.Caption := 'Running...';

  TThread.CreateAnonymousThread(
  procedure begin

    AddLog(format('ECS_Lost_Glass_Request: sGlassID=%s, nGlassCode=%d, nRequestOption=%d CH=%d', [sGlassID, nGlassCode, nRequestOption, nCh]));
    nRes:= g_CommPLC.ECS_Lost_Glass_Request(sGlassID, nGlassCode, nRequestOption+1, nCh);
    if nRes <> 0 then begin
      AddLog('ECS_Lost_Glass_Request NG ' + IntToStr(nRes));
      pnlStateLost.Font.Color := clRed;
      pnlStateLost.Caption := 'NG';
    end
    else begin
      AddLog('ECS_Lost_Glass_Request OK');
      pnlStateLost.Font.Color := clLime;
      pnlStateLost.Caption := 'OK';
    end;
  end
  ).Start;

end;


procedure TECSTestForm.btnTakeOutClick(Sender: TObject);
var
sPanelID : string;
nRes : Integer;
begin
  sPanelID:= edTakeOutPanelID.Text;
  if length(sPanelID) = 0 then begin
    ShowMessage('Check out the Panel ID');
    Exit;
  end;
  pnlStateTakeOut.Font.Color := clYellow;
  pnlStateTakeOut.Caption := 'Running...';

  AddLog('Take Out Report: ' + sPanelID);
  TThread.CreateAnonymousThread(
    procedure begin

      nRes:= g_CommPLC.ECS_TakeOutReport(0,sPanelID);
      if nRes <> 0 then begin
        AddLog('Take Out Report NG ' + IntToStr(nRes));
        pnlStateTakeOut.Font.Color := clRed;
        pnlStateTakeOut.Caption := 'NG';
      end
      else begin
        AddLog('Take Out Report OK');
        pnlStateTakeOut.Font.Color := clLime;
        pnlStateTakeOut.Caption := 'OK';
      end;
    end
  ).Start;

end;

procedure TECSTestForm.AddLog(sLog: String);
begin
  if Tag > 0 then Exit;

  if memoLog.Lines.Count > 100 then begin
     memoLog.Lines.Clear;
  end;
  memoLog.Lines.Add(FormatDateTime('HH:NN:SS.ZZZ => ', Now) +  sLog);
end;

procedure TECSTestForm.Edit2KeyPress(Sender: TObject; var Key: Char);
begin
  // 입력된 키가 숫자가 아니면 무시합니다.
  if not (Key in ['0'..'9', #8]) then
    Key := #0;
end;

procedure TECSTestForm.FormCreate(Sender: TObject);
var
i : Integer;
begin
  if pnlGlassData.Visible then begin
    pnlGlassData.Visible:= False;
    Exit;
  end;

  pnlStateLost.Color := clBlack;
  pnlStateLost.Font.Color := clLime;
  pnlStateLost.Font.Size := 15;
  pnlStateLost.StyleElements := [];
  pnlStateTakeOut.Color := clBlack;
  pnlStateTakeOut.Font.Color := clLime;
  pnlStateTakeOut.Font.Size := 15;
  pnlStateTakeOut.StyleElements := [];

  for i := 0 to 3 do begin
    grdGlassData.Cells[0, i+1]:= IntToStr(i+1);
    grdGlassData.Cells[1, i+1]:= g_CommPLC.GlassData[i].MateriID;
    grdGlassData.Cells[2, i+1]:= IntToStr(g_CommPLC.GlassData[i].GlassCode);
    grdGlassData.Cells[3, i+1]:= g_CommPLC.GlassData[i].GlassID;
    grdGlassData.Cells[4, i+1]:= IntToStr(g_CommPLC.GlassData[i].GlassJudge);
  end;
  grdGlassData.Cells[0, 6]:= 'Lost_Glass Data';
  grdGlassData.Cells[1, 6]:= g_CommPLC.GlassData[5].MateriID;
  grdGlassData.Cells[2, 6]:= IntToStr(g_CommPLC.GlassData[5].GlassCode);
  grdGlassData.Cells[3, 6]:= g_CommPLC.GlassData[5].GlassID;
  grdGlassData.Cells[4, 6]:= IntToStr(g_CommPLC.GlassData[5].GlassJudge);

  pnlGlassData.Visible:= True;
end;

procedure TECSTestForm.tmrRefreshTimer(Sender: TObject);
var
i : integer;
begin
  tmrRefresh.Enabled := False;
  for i := 0 to 3 do begin
    grdGlassData.Cells[0, i+1]:= IntToStr(i+1);
    grdGlassData.Cells[1, i+1]:= g_CommPLC.GlassData[i].MateriID;
    grdGlassData.Cells[2, i+1]:= IntToStr(g_CommPLC.GlassData[i].GlassCode);
    grdGlassData.Cells[3, i+1]:= g_CommPLC.GlassData[i].GlassID;
    grdGlassData.Cells[4, i+1]:= IntToStr(g_CommPLC.GlassData[i].GlassJudge);
  end;

  grdGlassData.Cells[0, 6]:= 'Lost_Glass Data';
  grdGlassData.Cells[1, 6]:= g_CommPLC.GlassData[5].MateriID;
  grdGlassData.Cells[2, 6]:= IntToStr(g_CommPLC.GlassData[5].GlassCode);
  grdGlassData.Cells[3, 6]:= g_CommPLC.GlassData[5].GlassID;
  grdGlassData.Cells[4, 6]:= IntToStr(g_CommPLC.GlassData[5].GlassJudge);

  tmrRefresh.Enabled := true;

end;

procedure TECSTestForm.cboTakeOutCHChange(Sender: TObject);
begin
  if cboTakeOutCH.ItemIndex > DefCommon.MAX_CH then  Exit;
  edTakeOutPanelID.Text := g_CommPLC.GlassData[cboTakeOutCH.ItemIndex].MateriID;
end;

end.
