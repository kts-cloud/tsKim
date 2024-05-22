object frmSelectModel: TfrmSelectModel
  Left = 1482
  Top = 207
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Model Select'
  ClientHeight = 711
  ClientWidth = 680
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Icon.Data = {
    0000010001002020040001000400E80200001600000028000000200000004000
    0000010004000000000000020000000000000000000000000000000000000000
    000000008000008000000080800080000000800080008080000080808000C0C0
    C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
    00000000000000000000000000000FEFEFEFEFEE00000000DD8DFDFDFDF00EFE
    FEFEFEEE00044000DDD8DFDFDFD00FEFEFEFEEE8044444407DDD8DFDFDF00EFE
    FEFEEE8E044F4440D7DDD8DFDFD00FEFEFEEE8E604FF44405D7DDD8DFDF00EFE
    FEEE8E600FF84440D5D7DDD8DFD00FEFEEE8E600FF88FFF05D5D7DDD8DF00EFE
    EE8E600FF8888880D5D5D7DDD8D00FEEE8E6E600F88888805D505D7DDD800EEE
    8E6E6E600F880000550005D7DDD00EE8E6E6E66600F80440500F005D7DD00000
    00000000040F044000FFF00000000004444F8804444004440F88FF4440000004
    444F880444444440F8888FF440000044444F88000044440F888888FF44000044
    FF888888F04444000088F444440000044FF8888F044444444088F44440000004
    44FF88F0444004444088F44440000000000FFF000440F0000000000000000AA8
    A200F00204408F40333B3B3B8BB00AAA8A200022000088F003B3B3B8BBB00FAA
    A8A202A20888888F003B3B8BBBF00AFAAA8A2A2A0888888FF003B8BBBFB00FAF
    AAA8A2A20FFF88FF003B8BBBFBF00AFAFAAA8A2A04448FF003B8BBBFBFB00FAF
    AFAAA8A20444FF403B8BBBFBFBF00AFAFAFAAA8A0444F440B8BBBFBFBFB00FAF
    AFAFAAA8044444408BBBFBFBFBF00AFAFAFAFAAA00044000BBBFBFBFBFB00FAF
    AFAFAFAA00000000BBFBFBFBFBF0000000000000000000000000000000000007
    E0000007E0000006600000000000000000000000000000000000000000000000
    000000000000000000000000000000000000E0000007E0000007C0000003C000
    0003E0000007E000000700000000000000000000000000000000000000000000
    000000000000000000000000000000000000000660000007E0000007E000}
  OldCreateOrder = False
  Position = poMainFormCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel_Header: TRzPanel
    Left = 0
    Top = 0
    Width = 680
    Height = 49
    Align = alTop
    Alignment = taLeftJustify
    BorderOuter = fsFlat
    BorderSides = [sdBottom]
    Caption = 'Model Selection'
    FlatColor = 10524310
    Font.Charset = ANSI_CHARSET
    Font.Color = 9856100
    Font.Height = -21
    Font.Name = 'Verdana'
    Font.Style = [fsBold]
    GradientColorStart = 11855600
    GradientColorStop = 9229030
    TextMargin = 4
    ParentFont = False
    TabOrder = 0
    VisualStyle = vsGradient
    WordWrap = False
    object cbbModelType: TComboBox
      Left = 365
      Top = 10
      Width = 300
      Height = 33
      Style = csDropDownList
      DropDownCount = 20
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = cbbModelTypeClick
    end
  end
  object RzPanel1: TRzPanel
    Left = 0
    Top = 49
    Width = 680
    Height = 662
    Align = alClient
    Alignment = taLeftJustify
    BorderOuter = fsFlat
    BorderSides = [sdBottom]
    FlatColor = 10524310
    Font.Charset = ANSI_CHARSET
    Font.Color = 9856100
    Font.Height = -11
    Font.Name = 'Verdana'
    Font.Style = []
    GradientColorStart = 11855600
    GradientColorStop = 9229030
    TextMargin = 4
    ParentFont = False
    TabOrder = 1
    VisualStyle = vsGradient
    WordWrap = False
    object btnCancel: TRzBitBtn
      Left = 478
      Top = 612
      Width = 145
      Height = 43
      FrameColor = clGradientActiveCaption
      Caption = 'Cancel'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      HotTrack = True
      ParentFont = False
      TabOrder = 2
      TextStyle = tsRecessed
      OnClick = btnCancelClick
    end
    object btnOk: TRzBitBtn
      Left = 26
      Top = 612
      Width = 145
      Height = 43
      FrameColor = clGradientActiveCaption
      Caption = 'OK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      HotTrack = True
      ParentFont = False
      TabOrder = 1
      TextStyle = tsRecessed
      OnClick = btnOkClick
    end
    object RzGroupBox5: TRzGroupBox
      Left = 10
      Top = 11
      Width = 655
      Height = 586
      Caption = 'Model List'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 7879740
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      GradientColorStop = 16763080
      GroupStyle = gsBanner
      ParentColor = True
      ParentFont = False
      TabOrder = 0
      object lstModel: TRzListBox
        Left = 0
        Top = 31
        Width = 655
        Height = 555
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Tahoma'
        Font.Style = []
        ImeName = 'Microsoft Office IME 2007'
        ItemHeight = 23
        ParentFont = False
        TabOrder = 0
        OnDblClick = lstModelDblClick
      end
    end
  end
end
