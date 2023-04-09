object frmNGRatio: TfrmNGRatio
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'NG Ratio'
  ClientHeight = 707
  ClientWidth = 1274
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel_Header: TRzPanel
    Left = 0
    Top = 0
    Width = 1274
    Height = 33
    Align = alTop
    Alignment = taLeftJustify
    BorderOuter = fsFlat
    BorderSides = [sdBottom]
    Caption = 'NG Ratio'
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
    TabOrder = 1
    VisualStyle = vsGradient
    WordWrap = False
    object Btn_Close: TRzBitBtn
      Left = 1120
      Top = 0
      Width = 154
      Height = 32
      FrameColor = clGradientActiveCaption
      Align = alRight
      Caption = 'Close'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      HotTrack = True
      ParentFont = False
      TabOrder = 0
      TextStyle = tsRecessed
      ThemeAware = False
      OnClick = Btn_CloseClick
    end
    object btnTest: TRzBitBtn
      Left = 1000
      Top = 0
      Width = 120
      Height = 32
      FrameColor = clGradientActiveCaption
      Align = alRight
      Caption = 'Test'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      HotTrack = True
      ParentFont = False
      TabOrder = 1
      TextStyle = tsRecessed
      ThemeAware = False
      Visible = False
      OnClick = btnTestClick
    end
  end
  object RzPanel1: TRzPanel
    Left = 0
    Top = 33
    Width = 1274
    Height = 674
    Align = alClient
    BorderOuter = fsFlat
    TabOrder = 0
    object grdList: TAdvStringGrid
      Left = 1
      Top = 45
      Width = 1272
      Height = 628
      Cursor = crDefault
      Align = alClient
      DrawingStyle = gdsClassic
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      ScrollBars = ssBoth
      TabOrder = 1
      HoverRowCells = [hcNormal, hcSelected]
      ActiveCellFont.Charset = DEFAULT_CHARSET
      ActiveCellFont.Color = clWindowText
      ActiveCellFont.Height = -11
      ActiveCellFont.Name = 'Tahoma'
      ActiveCellFont.Style = [fsBold]
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
      ShowSelection = False
      SortSettings.DefaultFormat = ssAutomatic
      Version = '8.3.2.4'
      ColWidths = (
        64
        64
        64
        64
        64)
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
        22)
    end
    object RzPanel2: TRzPanel
      Left = 1
      Top = 1
      Width = 1272
      Height = 44
      Align = alTop
      TabOrder = 0
      object dtpStart: TDateTimePicker
        Left = 2
        Top = 2
        Width = 186
        Height = 40
        Align = alLeft
        Date = 44207.579806423610000000
        Time = 44207.579806423610000000
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        ExplicitHeight = 37
      end
      object pnl1: TPanel
        Left = 188
        Top = 2
        Width = 16
        Height = 40
        Align = alLeft
        Caption = '~'
        TabOrder = 2
      end
      object dtpEnd: TDateTimePicker
        Left = 204
        Top = 2
        Width = 186
        Height = 40
        Align = alLeft
        Date = 44207.579863113410000000
        Time = 44207.579863113410000000
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        ExplicitHeight = 37
      end
      object cboChannel: TRzComboBox
        Left = 945
        Top = 2
        Width = 85
        Height = 40
        Align = alRight
        Font.Charset = ANSI_CHARSET
        Font.Color = 9856100
        Font.Height = -27
        Font.Name = 'Verdana'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
        Text = 'ALL'
        Items.Strings = (
          'ALL'
          'CH1'
          'CH2')
        ItemIndex = 0
      end
      object Btn_Export: TRzBitBtn
        Left = 1150
        Top = 2
        Width = 120
        Height = 40
        FrameColor = clGradientActiveCaption
        Align = alRight
        Caption = 'Export'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        HotTrack = True
        ParentFont = False
        TabOrder = 4
        TextStyle = tsRecessed
        ThemeAware = False
        OnClick = Btn_ExportClick
      end
      object Btn_View: TRzBitBtn
        Left = 390
        Top = 2
        Width = 100
        Height = 40
        FrameColor = clGradientActiveCaption
        Align = alLeft
        Caption = 'Query'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        HotTrack = True
        ParentFont = False
        TabOrder = 5
        TextStyle = tsRecessed
        ThemeAware = False
        OnClick = Btn_ViewClick
      end
      object Btn_Delete: TRzBitBtn
        Left = 1030
        Top = 2
        Width = 120
        Height = 40
        FrameColor = clGradientActiveCaption
        Align = alRight
        Caption = 'Clear'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        HotTrack = True
        ParentFont = False
        TabOrder = 6
        TextStyle = tsRecessed
        ThemeAware = False
        OnClick = Btn_DeleteClick
      end
      object Btn_Today: TRzBitBtn
        Left = 590
        Top = 2
        Width = 100
        Height = 40
        FrameColor = clGradientActiveCaption
        Align = alLeft
        Caption = 'Today'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        HotTrack = True
        ParentFont = False
        TabOrder = 7
        TextStyle = tsRecessed
        ThemeAware = False
        OnClick = Btn_TodayClick
      end
      object btnNext: TRzBitBtn
        Left = 690
        Top = 2
        Width = 100
        Height = 40
        FrameColor = clGradientActiveCaption
        Align = alLeft
        Caption = '>>'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        HotTrack = True
        ParentFont = False
        TabOrder = 8
        TextStyle = tsRecessed
        ThemeAware = False
        OnClick = btnNextClick
      end
      object btnPrev: TRzBitBtn
        Left = 490
        Top = 2
        Width = 100
        Height = 40
        FrameColor = clGradientActiveCaption
        Align = alLeft
        Caption = '<<'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clMaroon
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        HotTrack = True
        ParentFont = False
        TabOrder = 9
        TextStyle = tsRecessed
        ThemeAware = False
        OnClick = btnPrevClick
      end
    end
  end
end
