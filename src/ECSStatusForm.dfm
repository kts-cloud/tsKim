object frmECSStatus: TfrmECSStatus
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'ECS Status'
  ClientHeight = 861
  ClientWidth = 1594
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object grdStatus: TAdvStringGrid
    Left = 0
    Top = 0
    Width = 1594
    Height = 548
    Cursor = crDefault
    Align = alTop
    ColCount = 16
    DefaultColWidth = 96
    DefaultRowHeight = 32
    DrawingStyle = gdsClassic
    RowCount = 17
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSizing, goColSizing]
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
    HoverRowCells = [hcNormal, hcSelected]
    ActiveCellFont.Charset = DEFAULT_CHARSET
    ActiveCellFont.Color = clWindowText
    ActiveCellFont.Height = -11
    ActiveCellFont.Name = 'Tahoma'
    ActiveCellFont.Style = [fsBold]
    ColumnHeaders.Strings = (
      ''
      'EQP'
      'EQP'
      'EQP'
      'EQP'
      'EQP'
      'EQP'
      'EQP'
      'Robot'
      'Robot'
      'ECS')
    ControlLook.FixedGradientHoverFrom = clGray
    ControlLook.FixedGradientHoverTo = clWhite
    ControlLook.FixedGradientDownFrom = clGray
    ControlLook.FixedGradientDownTo = clSilver
    ControlLook.DropDownHeader.Font.Charset = DEFAULT_CHARSET
    ControlLook.DropDownHeader.Font.Color = clWindowText
    ControlLook.DropDownHeader.Font.Height = -11
    ControlLook.DropDownHeader.Font.Name = 'Tahoma'
    ControlLook.DropDownHeader.Font.Style = []
    ControlLook.DropDownHeader.Visible = True
    ControlLook.DropDownHeader.Buttons = <>
    ControlLook.DropDownFooter.Font.Charset = DEFAULT_CHARSET
    ControlLook.DropDownFooter.Font.Color = clWindowText
    ControlLook.DropDownFooter.Font.Height = -11
    ControlLook.DropDownFooter.Font.Name = 'Tahoma'
    ControlLook.DropDownFooter.Font.Style = []
    ControlLook.DropDownFooter.Visible = True
    ControlLook.DropDownFooter.Buttons = <>
    DefaultAlignment = taCenter
    Filter = <>
    FilterDropDown.Font.Charset = DEFAULT_CHARSET
    FilterDropDown.Font.Color = clWindowText
    FilterDropDown.Font.Height = -11
    FilterDropDown.Font.Name = 'Tahoma'
    FilterDropDown.Font.Style = []
    FilterDropDown.TextChecked = 'Checked'
    FilterDropDown.TextUnChecked = 'Unchecked'
    FilterDropDownClear = '(All)'
    FilterEdit.TypeNames.Strings = (
      'Starts with'
      'Ends with'
      'Contains'
      'Not contains'
      'Equal'
      'Not equal'
      'Larger than'
      'Smaller than'
      'Clear')
    FixedColWidth = 96
    FixedRowHeight = 32
    FixedFont.Charset = DEFAULT_CHARSET
    FixedFont.Color = clWindowText
    FixedFont.Height = -11
    FixedFont.Name = 'Tahoma'
    FixedFont.Style = [fsBold]
    FloatFormat = '%.2f'
    HoverButtons.Buttons = <>
    HoverButtons.Position = hbLeftFromColumnLeft
    HTMLSettings.ImageFolder = 'images'
    HTMLSettings.ImageBaseName = 'img'
    PrintSettings.DateFormat = 'dd/mm/yyyy'
    PrintSettings.Font.Charset = DEFAULT_CHARSET
    PrintSettings.Font.Color = clWindowText
    PrintSettings.Font.Height = -11
    PrintSettings.Font.Name = 'Tahoma'
    PrintSettings.Font.Style = []
    PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
    PrintSettings.FixedFont.Color = clWindowText
    PrintSettings.FixedFont.Height = -11
    PrintSettings.FixedFont.Name = 'Tahoma'
    PrintSettings.FixedFont.Style = []
    PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
    PrintSettings.HeaderFont.Color = clWindowText
    PrintSettings.HeaderFont.Height = -11
    PrintSettings.HeaderFont.Name = 'Tahoma'
    PrintSettings.HeaderFont.Style = []
    PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
    PrintSettings.FooterFont.Color = clWindowText
    PrintSettings.FooterFont.Height = -11
    PrintSettings.FooterFont.Name = 'Tahoma'
    PrintSettings.FooterFont.Style = []
    PrintSettings.PageNumSep = '/'
    SearchFooter.FindNextCaption = 'Find &next'
    SearchFooter.FindPrevCaption = 'Find &previous'
    SearchFooter.Font.Charset = DEFAULT_CHARSET
    SearchFooter.Font.Color = clWindowText
    SearchFooter.Font.Height = -11
    SearchFooter.Font.Name = 'Tahoma'
    SearchFooter.Font.Style = []
    SearchFooter.HighLightCaption = 'Highlight'
    SearchFooter.HintClose = 'Close'
    SearchFooter.HintFindNext = 'Find next occurrence'
    SearchFooter.HintFindPrev = 'Find previous occurrence'
    SearchFooter.HintHighlight = 'Highlight occurrences'
    SearchFooter.MatchCaseCaption = 'Match case'
    SearchFooter.ResultFormat = '(%d of %d)'
    ShowSelection = False
    SortSettings.DefaultFormat = ssAutomatic
    Version = '8.3.2.4'
    ColWidths = (
      96
      96
      96
      96
      96
      96
      96
      96
      96
      96
      96
      96
      96
      96
      96
      96)
    RowHeights = (
      32
      32
      32
      32
      32
      32
      32
      32
      32
      32
      32
      32
      32
      32
      32
      32
      32)
  end
  object pnlTest: TPanel
    Left = 0
    Top = 559
    Width = 1027
    Height = 294
    BevelOuter = bvNone
    TabOrder = 2
    Visible = False
    object GroupBox3: TGroupBox
      Left = 11
      Top = 3
      Width = 495
      Height = 286
      Caption = 'ECS'
      TabOrder = 0
      object Label7: TLabel
        Left = 12
        Top = 25
        Width = 40
        Height = 13
        Caption = 'User ID:'
      end
      object Label8: TLabel
        Left = 12
        Top = 52
        Width = 30
        Height = 13
        Caption = 'Serial:'
      end
      object Label9: TLabel
        Left = 12
        Top = 137
        Width = 34
        Height = 13
        Caption = 'Result:'
      end
      object Label10: TLabel
        Left = 12
        Top = 79
        Width = 32
        Height = 13
        Caption = 'Zig ID:'
      end
      object Label11: TLabel
        Left = 12
        Top = 107
        Width = 28
        Height = 13
        Caption = 'Error:'
      end
      object btnECS_PCHK: TButton
        Left = 170
        Top = 47
        Width = 75
        Height = 25
        Hint = '0x100'
        Caption = 'PCHK'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 6
        OnClick = btnECS_PCHKClick
      end
      object btnECS_EICR: TButton
        Left = 170
        Top = 76
        Width = 75
        Height = 25
        Hint = '0x100'
        Caption = 'EICR'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 7
        OnClick = btnECS_EICRClick
      end
      object btnECS_UCHK: TButton
        Left = 170
        Top = 20
        Width = 75
        Height = 25
        Hint = '0xF4'
        Caption = 'UCHK'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 5
        OnClick = btnECS_UCHKClick
      end
      object btnECS_APDR: TButton
        Left = 170
        Top = 104
        Width = 75
        Height = 25
        Hint = '0x10'
        Caption = 'APDR'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 8
        OnClick = btnECS_APDRClick
      end
      object edtUserID: TEdit
        Left = 56
        Top = 22
        Width = 108
        Height = 21
        TabOrder = 0
        Text = '52428'
      end
      object edtSerial: TEdit
        Left = 56
        Top = 49
        Width = 108
        Height = 21
        TabOrder = 1
        Text = '12345ABCD'
      end
      object edtResult: TEdit
        Left = 56
        Top = 135
        Width = 108
        Height = 21
        TabOrder = 4
        Text = '0'
      end
      object edtZigID: TEdit
        Left = 56
        Top = 76
        Width = 108
        Height = 21
        TabOrder = 2
        Text = 'VH12345'
      end
      object edtErrorCode: TEdit
        Left = 56
        Top = 104
        Width = 108
        Height = 21
        TabOrder = 3
        Text = 'A0C-B0A-----G3X----------------------------'
      end
      object GroupBox5: TGroupBox
        Left = 251
        Top = 99
        Width = 219
        Height = 75
        Caption = 'Alarm'
        TabOrder = 11
        object Label14: TLabel
          Left = 6
          Top = 22
          Width = 28
          Height = 13
          Caption = 'Type:'
        end
        object Label15: TLabel
          Left = 3
          Top = 49
          Width = 30
          Height = 13
          Caption = 'Value:'
        end
        object Label16: TLabel
          Left = 125
          Top = 20
          Width = 29
          Height = 13
          Caption = 'Code:'
        end
        object btnAlarm: TButton
          Left = 127
          Top = 44
          Width = 75
          Height = 25
          Hint = '0x0E, 0F'
          Caption = 'Alarm'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = btnAlarmClick
        end
        object edtAlarmCode: TEdit
          Left = 158
          Top = 17
          Width = 49
          Height = 21
          TabOrder = 0
          Text = '21'
        end
        object cboValue_Alarm: TComboBox
          Left = 39
          Top = 46
          Width = 82
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 2
          Text = '0 : Off'
          Items.Strings = (
            '0 : Off'
            '1 : On')
        end
        object cboAlarmType: TComboBox
          Left = 40
          Top = 19
          Width = 79
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 3
          Text = '0 : Light'
          Items.Strings = (
            '0 : Light'
            '1 : Heavy')
        end
      end
      object GroupBox6: TGroupBox
        Left = 251
        Top = 13
        Width = 219
        Height = 80
        Caption = 'Unit Status'
        TabOrder = 10
        object Label12: TLabel
          Left = 5
          Top = 20
          Width = 30
          Height = 13
          Caption = 'Mode:'
        end
        object Label13: TLabel
          Left = 3
          Top = 46
          Width = 30
          Height = 13
          Caption = 'Value:'
        end
        object btnUnitStatus: TButton
          Left = 127
          Top = 44
          Width = 75
          Height = 25
          Hint = '0x00'
          Caption = 'Unit Status'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = btnUnitStatusClick
        end
        object cboUnitStatus: TComboBox
          Left = 39
          Top = 17
          Width = 168
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 0
          Text = '0 : Online State'
          Items.Strings = (
            '0 : Online State'
            '1 : Dummy Status'
            '2 : -'
            '3 : -'
            '4 : -'
            '5 : -'
            '6 : -'
            '7 :-'
            '8 : Run'
            '9 : Idle'
            '10 : Down'
            '11 :Glass In Processing'
            '12 :Glass Exist In Unit'
            '13 :Previous Transfer Enable')
        end
        object cboValue_Status: TComboBox
          Left = 39
          Top = 44
          Width = 82
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 2
          Text = '0 : Off'
          Items.Strings = (
            '0 : Off'
            '1 : On')
        end
      end
      object btnECS_ZSET: TButton
        Left = 170
        Top = 132
        Width = 75
        Height = 25
        Hint = '0x100'
        Caption = 'ZSET'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 9
        OnClick = btnECS_ZSETClick
      end
      object gbETC: TGroupBox
        Left = 5
        Top = 174
        Width = 486
        Height = 104
        Caption = 'ETC'
        TabOrder = 12
        object Label17: TLabel
          Left = 8
          Top = 21
          Width = 36
          Height = 13
          Caption = 'Param1'
        end
        object Label18: TLabel
          Left = 8
          Top = 49
          Width = 36
          Height = 13
          Caption = 'Param2'
        end
        object Label19: TLabel
          Left = 8
          Top = 78
          Width = 36
          Height = 13
          Caption = 'Param3'
        end
        object edtParam1: TEdit
          Left = 52
          Top = 18
          Width = 108
          Height = 21
          TabOrder = 0
          Text = '0'
        end
        object edtParam2: TEdit
          Left = 52
          Top = 46
          Width = 108
          Height = 21
          TabOrder = 1
          Text = '0'
        end
        object edtParam3: TEdit
          Left = 52
          Top = 75
          Width = 108
          Height = 21
          TabOrder = 2
          Text = '0'
        end
        object btnGlassData: TButton
          Left = 408
          Top = 42
          Width = 75
          Height = 25
          Hint = 'W10'
          Caption = 'Glass Data'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 3
          OnClick = btnGlassDataClick
        end
        object btnModelChange: TButton
          Left = 328
          Top = 73
          Width = 75
          Height = 25
          Hint = 'Model Index=Parma1'
          Caption = 'Model Change'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 4
          OnClick = btnModelChangeClick
        end
        object btnGlassPosition: TButton
          Left = 166
          Top = 73
          Width = 75
          Height = 25
          Hint = 'Ch=P1, Exist=P2, Code=P3'
          Caption = 'Glass Position'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 5
          OnClick = btnGlassPositionClick
        end
        object btnLostGlass: TButton
          Left = 408
          Top = 13
          Width = 75
          Height = 25
          Hint = 'sGlassID=P1,  nGlassCode=P2,  nRequestOption=P3'
          Caption = 'Lost Glass'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 6
          OnClick = btnLostGlassClick
        end
        object btnGlassExist: TButton
          Left = 247
          Top = 73
          Width = 75
          Height = 25
          Hint = 'Exists=P1,  nCount=P2'
          Caption = 'Glass Exist'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 7
          OnClick = btnGlassExistClick
        end
        object btnScrapGlass: TButton
          Left = 328
          Top = 42
          Width = 75
          Height = 25
          Hint = 'sGlassID=P1,  nGlassCode=P2,  nRequestOption=P3'
          Caption = 'Scrap Glass'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 8
          OnClick = btnScrapGlassClick
        end
        object btnStagePosition: TButton
          Left = 166
          Top = 13
          Width = 75
          Height = 25
          Hint = 'A Front P1=0, B Front P1=1'
          Caption = 'Stage Position'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 9
          OnClick = btnStagePositionClick
        end
        object btnAccStatus: TButton
          Left = 166
          Top = 42
          Width = 75
          Height = 25
          Hint = 'A  P1=0, B P1=1, Vluae P2(0=Idle, 1=Run, 2=Down), AlarmCode P3'
          Caption = 'Acc. Status'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 10
          OnClick = btnAccStatusClick
        end
        object btnLinkTest: TButton
          Left = 247
          Top = 13
          Width = 75
          Height = 25
          Hint = 'none'
          Caption = 'Link Test'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 11
          OnClick = btnLinkTestClick
        end
        object btnGlassInProcessing: TButton
          Left = 247
          Top = 42
          Width = 75
          Height = 25
          Hint = 'Processing=P1 0=End, 1=Processing'
          Caption = 'In Processing'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 12
          OnClick = btnGlassInProcessingClick
        end
        object btnTactTime: TButton
          Left = 328
          Top = 13
          Width = 75
          Height = 25
          Hint = 'Ch=P1,  nTactTime=P2'
          Caption = 'TactTime'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 13
          OnClick = btnTactTimeClick
        end
        object btnTakeOutReport: TButton
          Left = 409
          Top = 73
          Width = 75
          Height = 25
          Hint = 'Model Index=Parma1'
          Caption = 'Take Out Report'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 14
          OnClick = btnTakeOutReportClick
        end
      end
    end
    object GroupBox4: TGroupBox
      Left = 512
      Top = 3
      Width = 199
      Height = 126
      Caption = 'Robot'
      TabOrder = 1
      object Label3: TLabel
        Left = 11
        Top = 17
        Width = 30
        Height = 13
        Caption = 'Value:'
      end
      object btnRobot_Unload: TButton
        Left = 75
        Top = 36
        Width = 105
        Height = 25
        Hint = '0xD1'
        Caption = 'Unload Req.'
        TabOrder = 1
        OnClick = btnRobot_UnloadClick
      end
      object btnRobot_Load: TButton
        Left = 75
        Top = 5
        Width = 105
        Height = 25
        Hint = '0xC1'
        Caption = 'Load Req.'
        TabOrder = 0
        OnClick = btnRobot_LoadClick
      end
      object btnRobot_Exchange: TButton
        Left = 75
        Top = 63
        Width = 105
        Height = 25
        Caption = 'Exchange Req.'
        TabOrder = 2
        OnClick = btnRobot_ExchangeClick
      end
      object cboChannel_Robot: TComboBox
        Left = 10
        Top = 36
        Width = 59
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 3
        Text = 'Ch 0'
        Items.Strings = (
          'Ch 0'
          'Ch 1')
      end
      object btnRobot_Clear: TButton
        Left = 75
        Top = 95
        Width = 105
        Height = 25
        Caption = 'Clear Req.'
        TabOrder = 4
        OnClick = btnRobot_ClearClick
      end
    end
    object memoLog: TMemo
      Left = 512
      Top = 135
      Width = 497
      Height = 154
      ScrollBars = ssVertical
      TabOrder = 2
    end
  end
  object btnCloses: TButton
    Left = 752
    Top = 565
    Width = 257
    Height = 56
    Cancel = True
    Caption = 'Close'
    TabOrder = 1
    OnClick = btnClosesClick
  end
  object GroupBox2: TGroupBox
    Left = 1033
    Top = 649
    Width = 247
    Height = 81
    Caption = 'Read/Write'
    TabOrder = 4
    object Label1: TLabel
      Left = 7
      Top = 22
      Width = 36
      Height = 13
      Caption = 'Device:'
    end
    object Label2: TLabel
      Left = 7
      Top = 49
      Width = 60
      Height = 13
      Caption = 'Value(Hex): '
    end
    object edtDevice: TEdit
      Left = 67
      Top = 19
      Width = 92
      Height = 21
      TabOrder = 0
      Text = 'B000'
    end
    object edtValue: TEdit
      Left = 67
      Top = 46
      Width = 92
      Height = 21
      TabOrder = 1
      Text = '0'
    end
    object btnReadDevice: TButton
      Left = 165
      Top = 13
      Width = 75
      Height = 25
      Caption = 'Read Device'
      TabOrder = 2
      OnClick = btnReadDeviceClick
    end
    object btnWriteDevice: TButton
      Left = 165
      Top = 44
      Width = 75
      Height = 25
      Caption = 'Write Device'
      TabOrder = 3
      OnClick = btnWriteDeviceClick
    end
  end
  object btnShowSimulator: TButton
    Left = 1333
    Top = 688
    Width = 109
    Height = 25
    Caption = 'Show Simulator'
    TabOrder = 5
    OnClick = btnShowSimulatorClick
  end
  object GroupBox1: TGroupBox
    Left = 1033
    Top = 562
    Width = 409
    Height = 81
    Caption = 'Start Address'
    TabOrder = 3
    object lblStartAddrEQP: TLabel
      Left = 15
      Top = 19
      Width = 27
      Height = 13
      Caption = 'EQP :'
    end
    object lblStartAddrEQP_W: TLabel
      Left = 15
      Top = 46
      Width = 37
      Height = 13
      Caption = 'EQP W:'
    end
    object lblStartAddrROBOT: TLabel
      Left = 143
      Top = 19
      Width = 42
      Height = 13
      Caption = 'ROBOT :'
    end
    object lblStartAddrROBOT_W: TLabel
      Left = 143
      Top = 46
      Width = 52
      Height = 13
      Caption = 'ROBOT W:'
    end
    object lblStartAddrECS: TLabel
      Left = 288
      Top = 19
      Width = 23
      Height = 13
      Caption = 'ECS:'
    end
    object lblStartAddrECS_W: TLabel
      Left = 288
      Top = 46
      Width = 36
      Height = 13
      Caption = 'ECS W:'
    end
    object edtStartAddrEQP: TEdit
      Left = 58
      Top = 16
      Width = 60
      Height = 21
      Color = clGray
      ReadOnly = True
      TabOrder = 0
      Text = 'FF00'
    end
    object edtStartAddrEQP_W: TEdit
      Left = 58
      Top = 43
      Width = 60
      Height = 21
      Color = clGray
      ReadOnly = True
      TabOrder = 1
      Text = 'FF00'
    end
    object edtStartAddrECS: TEdit
      Left = 330
      Top = 16
      Width = 60
      Height = 21
      Color = clGray
      ReadOnly = True
      TabOrder = 2
      Text = 'FF00'
    end
    object edtStartAddrECS_W: TEdit
      Left = 330
      Top = 43
      Width = 60
      Height = 21
      Color = clGray
      ReadOnly = True
      TabOrder = 3
      Text = 'FF00'
    end
    object edtStartAddrRobot: TEdit
      Left = 201
      Top = 16
      Width = 60
      Height = 21
      Color = clGray
      ReadOnly = True
      TabOrder = 4
      Text = 'FF00'
    end
    object edtStartAddrRobot_W: TEdit
      Left = 201
      Top = 43
      Width = 60
      Height = 21
      Color = clGray
      ReadOnly = True
      TabOrder = 5
      Text = 'FF00'
    end
  end
  object btnShowGlassData: TButton
    Left = 1333
    Top = 657
    Width = 109
    Height = 25
    Caption = 'Show GlassData'
    TabOrder = 6
    OnClick = btnShowGlassDataClick
  end
  object pnlGlassData: TPanel
    Left = 633
    Top = 257
    Width = 807
    Height = 274
    Caption = 'pnlGlassData'
    TabOrder = 7
    Visible = False
    object Label4: TLabel
      Left = 1
      Top = 1
      Width = 805
      Height = 23
      Align = alTop
      Alignment = taCenter
      Caption = 'Glass Data'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ExplicitWidth = 88
    end
    object grdGlassData: TAdvStringGrid
      Left = 5
      Top = 30
      Width = 799
      Height = 204
      Cursor = crDefault
      DrawingStyle = gdsClassic
      RowCount = 9
      ScrollBars = ssBoth
      TabOrder = 0
      HoverRowCells = [hcNormal, hcSelected]
      ActiveCellFont.Charset = DEFAULT_CHARSET
      ActiveCellFont.Color = clWindowText
      ActiveCellFont.Height = -11
      ActiveCellFont.Name = 'Tahoma'
      ActiveCellFont.Style = [fsBold]
      ColumnHeaders.Strings = (
        'Ch'
        'CarrierID'
        'GlassCode'
        'GlassID'
        'JudgeCode')
      ControlLook.FixedGradientHoverFrom = clGray
      ControlLook.FixedGradientHoverTo = clWhite
      ControlLook.FixedGradientDownFrom = clGray
      ControlLook.FixedGradientDownTo = clSilver
      ControlLook.DropDownHeader.Font.Charset = DEFAULT_CHARSET
      ControlLook.DropDownHeader.Font.Color = clWindowText
      ControlLook.DropDownHeader.Font.Height = -11
      ControlLook.DropDownHeader.Font.Name = 'Tahoma'
      ControlLook.DropDownHeader.Font.Style = []
      ControlLook.DropDownHeader.Visible = True
      ControlLook.DropDownHeader.Buttons = <>
      ControlLook.DropDownFooter.Font.Charset = DEFAULT_CHARSET
      ControlLook.DropDownFooter.Font.Color = clWindowText
      ControlLook.DropDownFooter.Font.Height = -11
      ControlLook.DropDownFooter.Font.Name = 'Tahoma'
      ControlLook.DropDownFooter.Font.Style = []
      ControlLook.DropDownFooter.Visible = True
      ControlLook.DropDownFooter.Buttons = <>
      Filter = <>
      FilterDropDown.Font.Charset = DEFAULT_CHARSET
      FilterDropDown.Font.Color = clWindowText
      FilterDropDown.Font.Height = -11
      FilterDropDown.Font.Name = 'Tahoma'
      FilterDropDown.Font.Style = []
      FilterDropDown.TextChecked = 'Checked'
      FilterDropDown.TextUnChecked = 'Unchecked'
      FilterDropDownClear = '(All)'
      FilterEdit.TypeNames.Strings = (
        'Starts with'
        'Ends with'
        'Contains'
        'Not contains'
        'Equal'
        'Not equal'
        'Larger than'
        'Smaller than'
        'Clear')
      FixedRowHeight = 22
      FixedFont.Charset = DEFAULT_CHARSET
      FixedFont.Color = clWindowText
      FixedFont.Height = -11
      FixedFont.Name = 'Tahoma'
      FixedFont.Style = [fsBold]
      FloatFormat = '%.2f'
      HoverButtons.Buttons = <>
      HoverButtons.Position = hbLeftFromColumnLeft
      HTMLSettings.ImageFolder = 'images'
      HTMLSettings.ImageBaseName = 'img'
      PrintSettings.DateFormat = 'dd/mm/yyyy'
      PrintSettings.Font.Charset = DEFAULT_CHARSET
      PrintSettings.Font.Color = clWindowText
      PrintSettings.Font.Height = -11
      PrintSettings.Font.Name = 'Tahoma'
      PrintSettings.Font.Style = []
      PrintSettings.FixedFont.Charset = DEFAULT_CHARSET
      PrintSettings.FixedFont.Color = clWindowText
      PrintSettings.FixedFont.Height = -11
      PrintSettings.FixedFont.Name = 'Tahoma'
      PrintSettings.FixedFont.Style = []
      PrintSettings.HeaderFont.Charset = DEFAULT_CHARSET
      PrintSettings.HeaderFont.Color = clWindowText
      PrintSettings.HeaderFont.Height = -11
      PrintSettings.HeaderFont.Name = 'Tahoma'
      PrintSettings.HeaderFont.Style = []
      PrintSettings.FooterFont.Charset = DEFAULT_CHARSET
      PrintSettings.FooterFont.Color = clWindowText
      PrintSettings.FooterFont.Height = -11
      PrintSettings.FooterFont.Name = 'Tahoma'
      PrintSettings.FooterFont.Style = []
      PrintSettings.PageNumSep = '/'
      SearchFooter.FindNextCaption = 'Find &next'
      SearchFooter.FindPrevCaption = 'Find &previous'
      SearchFooter.Font.Charset = DEFAULT_CHARSET
      SearchFooter.Font.Color = clWindowText
      SearchFooter.Font.Height = -11
      SearchFooter.Font.Name = 'Tahoma'
      SearchFooter.Font.Style = []
      SearchFooter.HighLightCaption = 'Highlight'
      SearchFooter.HintClose = 'Close'
      SearchFooter.HintFindNext = 'Find next occurrence'
      SearchFooter.HintFindPrev = 'Find previous occurrence'
      SearchFooter.HintHighlight = 'Highlight occurrences'
      SearchFooter.MatchCaseCaption = 'Match case'
      SearchFooter.ResultFormat = '(%d of %d)'
      SortSettings.DefaultFormat = ssAutomatic
      Version = '8.3.2.4'
      ColWidths = (
        64
        282
        99
        270
        80)
      RowHeights = (
        22
        22
        22
        22
        22
        22
        22
        22
        22)
    end
    object btnHideGlassData: TButton
      Left = 678
      Top = 240
      Width = 109
      Height = 25
      Caption = 'Hide'
      TabOrder = 1
      OnClick = btnHideGlassDataClick
    end
  end
  object tmrRefresh: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmrRefreshTimer
    Left = 800
    Top = 48
  end
end
