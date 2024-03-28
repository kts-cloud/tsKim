object frmPlcSimulate: TfrmPlcSimulate
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'PLC Simulator'
  ClientHeight = 661
  ClientWidth = 754
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
  object pnPLC: TPanel
    Left = 0
    Top = 0
    Width = 754
    Height = 481
    Align = alTop
    Caption = 'pnPLC'
    TabOrder = 0
    object lblSelectedAddr: TLabel
      Left = 6
      Top = 85
      Width = 102
      Height = 18
      AutoSize = False
      Caption = 'B0'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object grdPLCMemory: TAdvStringGrid
      Left = 3
      Top = 103
      Width = 584
      Height = 378
      Cursor = crDefault
      ColCount = 20
      DefaultColWidth = 18
      DrawingStyle = gdsClassic
      RowCount = 17
      ScrollBars = ssBoth
      TabOrder = 1
      HoverRowCells = [hcNormal, hcSelected]
      OnGetCellColor = grdPLCMemoryGetCellColor
      OnDblClickCell = grdPLCMemoryDblClickCell
      ActiveCellFont.Charset = DEFAULT_CHARSET
      ActiveCellFont.Color = clWindowText
      ActiveCellFont.Height = -11
      ActiveCellFont.Name = 'Tahoma'
      ActiveCellFont.Style = [fsBold]
      ColumnHeaders.Strings = (
        'Addr'
        '0'
        '1'
        '2'
        '3'
        '4'
        '5'
        '6'
        '7'
        '8'
        '9'
        'A'
        'B'
        'C'
        'D'
        'E'
        'F'
        'Low'
        'High'
        'Word')
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
      FixedColWidth = 40
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
      ShowSelection = False
      SortSettings.DefaultFormat = ssAutomatic
      Version = '8.3.2.4'
      ColWidths = (
        40
        18
        18
        18
        18
        18
        18
        18
        18
        18
        18
        18
        18
        18
        18
        18
        20
        63
        73
        114)
      RowHeights = (
        22
        22
        22
        22
        22
        22
        22
        22
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
    object GroupBox1: TGroupBox
      Left = 3
      Top = 5
      Width = 670
      Height = 76
      Caption = 'PLC'
      TabOrder = 0
      object Label1: TLabel
        Left = 8
        Top = 18
        Width = 39
        Height = 13
        Caption = 'Device: '
      end
      object Label28: TLabel
        Left = 263
        Top = 18
        Width = 54
        Height = 13
        Caption = 'Command :'
      end
      object Label4: TLabel
        Left = 8
        Top = 45
        Width = 57
        Height = 13
        Caption = 'Addr(Hex): '
      end
      object cboAddr: TComboBox
        Left = 65
        Top = 15
        Width = 65
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 0
        Text = 'B'
        Items.Strings = (
          'B'
          'W')
      end
      object btnGotoAddr: TButton
        Left = 136
        Top = 40
        Width = 73
        Height = 25
        Caption = #51452#49548' '#51060#46041'(&A)'
        TabOrder = 2
        OnClick = btnGotoAddrClick
      end
      object cboPLC_CommandList: TComboBox
        Left = 323
        Top = 15
        Width = 316
        Height = 21
        Style = csDropDownList
        TabOrder = 5
        Items.Strings = (
          'Detect (1, 2, 3, 4)'
          'Detect (5, 6, 7, 8)'
          'Clamp Down(1, 2, 3, 4)'
          'Clamp Down(5, 6, 7, 8)')
      end
      object chkPLCExec_On: TCheckBox
        Left = 408
        Top = 47
        Width = 41
        Height = 17
        Caption = 'On'
        TabOrder = 6
        Visible = False
      end
      object btnPLCExec_Command: TButton
        Left = 514
        Top = 42
        Width = 125
        Height = 25
        Caption = 'Exec'
        TabOrder = 7
        OnClick = btnPLCExec_CommandClick
      end
      object edtAddr: TEdit
        Left = 65
        Top = 42
        Width = 65
        Height = 21
        TabOrder = 1
        Text = '0'
        OnKeyPress = edtAddrKeyPress
      end
      object btnGotoPrev: TButton
        Left = 213
        Top = 40
        Width = 30
        Height = 25
        Caption = '&<P'
        TabOrder = 3
        OnClick = btnGotoPrevClick
      end
      object btnGotoNext: TButton
        Left = 242
        Top = 40
        Width = 30
        Height = 25
        Caption = 'N&>'
        TabOrder = 4
        OnClick = btnGotoNextClick
      end
    end
    object GroupBox2: TGroupBox
      Left = 593
      Top = 101
      Width = 152
      Height = 246
      Caption = 'Write'
      TabOrder = 2
      object Label2: TLabel
        Left = 23
        Top = 111
        Width = 23
        Height = 13
        Caption = 'Addr'
      end
      object Label3: TLabel
        Left = 23
        Top = 159
        Width = 26
        Height = 13
        Caption = 'Value'
      end
      object rgDataType: TRadioGroup
        Left = 16
        Top = 24
        Width = 121
        Height = 81
        Caption = #45936#51060#53552' '#54805#49885
        ItemIndex = 0
        Items.Strings = (
          'Hex'
          #49707#51088
          'ASCII')
        TabOrder = 0
      end
      object edtWriteAddr: TEdit
        Left = 20
        Top = 128
        Width = 121
        Height = 21
        TabOrder = 1
        Text = '0'
      end
      object btnWriteAddr: TButton
        Left = 20
        Top = 203
        Width = 121
        Height = 25
        Caption = '&Write'
        TabOrder = 3
        OnClick = btnWriteAddrClick
      end
      object edtWriteValue: TEdit
        Left = 20
        Top = 176
        Width = 121
        Height = 21
        TabOrder = 2
        Text = 'FF00'
      end
    end
    object chkAutoStart: TCheckBox
      Left = 600
      Top = 360
      Width = 134
      Height = 17
      Caption = 'Auto Inspection Start'
      TabOrder = 3
    end
    object chkPauseProcess: TCheckBox
      Left = 600
      Top = 383
      Width = 134
      Height = 17
      Caption = 'Pause Process'
      TabOrder = 4
    end
  end
  object pnLog: TPanel
    Left = 0
    Top = 481
    Width = 754
    Height = 180
    Align = alClient
    Caption = 'Panel1'
    TabOrder = 1
    object mmoLog: TMemo
      Left = 1
      Top = 37
      Width = 752
      Height = 142
      Align = alClient
      Lines.Strings = (
        'mmoLog')
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 752
      Height = 36
      Align = alTop
      TabOrder = 1
      object btnClearLog_PG: TButton
        Left = 2
        Top = 5
        Width = 92
        Height = 25
        Caption = 'Clear Log'
        TabOrder = 0
        OnClick = btnClearLog_PGClick
      end
    end
  end
  object tmrCycle: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tmrCycleTimer
    Left = 363
    Top = 45
  end
end
