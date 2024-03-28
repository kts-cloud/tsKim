object ECSTestForm: TECSTestForm
  Left = 0
  Top = 0
  Caption = 'ECSTestForm'
  ClientHeight = 643
  ClientWidth = 941
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 257
    Width = 215
    Height = 23
    Alignment = taCenter
    Caption = ' Lost Panel Data Request '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 104
    Top = 313
    Width = 71
    Height = 23
    Alignment = taCenter
    Caption = 'Panel ID'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label3: TLabel
    Left = 104
    Top = 286
    Width = 93
    Height = 23
    Alignment = taCenter
    Caption = 'Panel Code'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label5: TLabel
    Left = 440
    Top = 257
    Width = 129
    Height = 23
    Alignment = taCenter
    Caption = 'Request Option'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label6: TLabel
    Left = 24
    Top = 410
    Width = 144
    Height = 23
    Alignment = taCenter
    Caption = 'Take Out Report '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label7: TLabel
    Left = 104
    Top = 447
    Width = 71
    Height = 23
    Alignment = taCenter
    Caption = 'Panel ID'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object pnlGlassData: TPanel
    Left = 0
    Top = 0
    Width = 941
    Height = 241
    Align = alTop
    Caption = 'pnlGlassData'
    TabOrder = 0
    Visible = False
    object Label4: TLabel
      Left = 1
      Top = 1
      Width = 939
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
      Left = 66
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
  end
  object cboLostDataCH: TRzComboBox
    Left = 24
    Top = 288
    Width = 63
    Height = 21
    Style = csDropDownList
    DropDownCount = 10
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Verdana'
    Font.Style = [fsBold]
    FocusColor = 14283263
    ImeName = 'Microsoft IME 2010'
    ParentFont = False
    TabOrder = 1
    Text = 'Ch 1'
    Items.Strings = (
      'Ch 1'
      'Ch 2'
      'Ch 3'
      'Ch 4')
    ItemIndex = 0
    Values.Strings = (
      'CH 1'
      'CH 2'
      'CH 3'
      'CH 4')
  end
  object edLostDataPanelID: TEdit
    Left = 224
    Top = 315
    Width = 193
    Height = 21
    TabOrder = 2
  end
  object edPanelCode: TEdit
    Left = 224
    Top = 288
    Width = 193
    Height = 21
    TabOrder = 3
    Text = '0'
    OnKeyPress = Edit2KeyPress
  end
  object cboRequestOption: TRzComboBox
    Left = 448
    Top = 288
    Width = 121
    Height = 21
    Style = csDropDownList
    DropDownCount = 10
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Verdana'
    Font.Style = [fsBold]
    FocusColor = 14283263
    ImeName = 'Microsoft IME 2010'
    ParentFont = False
    TabOrder = 4
    Text = '1.Panel CODE'
    Items.Strings = (
      '1.Panel CODE'
      '2.Panel ID')
    ItemIndex = 0
    Values.Strings = (
      'CH 1'
      'CH 2'
      'CH 3'
      'CH 4')
  end
  object btnLostData: TButton
    Left = 575
    Top = 286
    Width = 129
    Height = 50
    Caption = 'Lost Panel Data Request '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    WordWrap = True
    OnClick = btnLostDataClick
  end
  object cboTakeOutCH: TRzComboBox
    Left = 24
    Top = 449
    Width = 63
    Height = 21
    Style = csDropDownList
    DropDownCount = 10
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Verdana'
    Font.Style = [fsBold]
    FocusColor = 14283263
    ImeName = 'Microsoft IME 2010'
    ParentFont = False
    TabOrder = 6
    Text = 'Ch 1'
    OnChange = cboTakeOutCHChange
    Items.Strings = (
      'Ch 1'
      'Ch 2'
      'Ch 3'
      'Ch 4')
    ItemIndex = 0
    Values.Strings = (
      'CH 1'
      'CH 2'
      'CH 3'
      'CH 4')
  end
  object edTakeOutPanelID: TEdit
    Left = 224
    Top = 449
    Width = 193
    Height = 21
    TabOrder = 7
  end
  object btnTakeOut: TButton
    Left = 575
    Top = 433
    Width = 129
    Height = 50
    Caption = 'Take Out Report'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 8
    WordWrap = True
    OnClick = btnTakeOutClick
  end
  object memoLog: TMemo
    Left = 0
    Top = 489
    Width = 941
    Height = 154
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 9
  end
  object pnlStateLost: TPanel
    Left = 748
    Top = 286
    Width = 141
    Height = 50
    Caption = '...........'
    Color = -1
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 10
  end
  object pnlStateTakeOut: TPanel
    Left = 748
    Top = 433
    Width = 141
    Height = 50
    Caption = '...........'
    Color = -1
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 11
  end
  object tmrRefresh: TTimer
    Interval = 500
    OnTimer = tmrRefreshTimer
    Left = 872
    Top = 32
  end
end
