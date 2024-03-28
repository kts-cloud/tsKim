object frmDioSignal: TfrmDioSignal
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Dio Status'
  ClientHeight = 675
  ClientWidth = 832
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object grpDioSig: TRzGroupBox
    Left = 0
    Top = 0
    Width = 832
    Height = 675
    Align = alClient
    Caption = ' DIO Signal'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    GroupStyle = gsUnderline
    ParentFont = False
    TabOrder = 0
    ExplicitWidth = 854
    ExplicitHeight = 657
  end
end
