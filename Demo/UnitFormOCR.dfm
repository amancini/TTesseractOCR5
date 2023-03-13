object FormOCR: TFormOCR
  Left = 0
  Top = 0
  Caption = 'OCR Utility'
  ClientHeight = 751
  ClientWidth = 1284
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pbLayout: TPaintBox
    Left = 225
    Top = 41
    Width = 527
    Height = 694
    Cursor = crCross
    Align = alClient
    OnMouseDown = pbLayoutMouseDown
    OnMouseMove = pbLayoutMouseMove
    OnPaint = pbLayoutPaint
    ExplicitLeft = 10
    ExplicitTop = 6
    ExplicitWidth = 469
    ExplicitHeight = 328
  end
  object cxSplitter1: TSplitter
    Left = 217
    Top = 41
    Width = 8
    Height = 694
    ExplicitLeft = 744
    ExplicitTop = 0
    ExplicitHeight = 735
  end
  object pbRecognizeProgress: TProgressBar
    Left = 0
    Top = 735
    Width = 1284
    Height = 16
    Align = alBottom
    Smooth = True
    TabOrder = 0
  end
  object memText: TMemo
    Left = 752
    Top = 41
    Width = 532
    Height = 694
    Align = alRight
    TabOrder = 1
  end
  object panLayoutLeft: TPanel
    Left = 0
    Top = 41
    Width = 217
    Height = 694
    Align = alLeft
    TabOrder = 2
    object gbPage: TPanel
      Left = 1
      Top = 1
      Width = 215
      Height = 78
      Align = alTop
      Caption = 'Page'
      TabOrder = 0
      object labMeanWordConf: TLabel
        Left = 10
        Top = 52
        Width = 112
        Height = 13
        Caption = 'Mean word confidence:'
      end
      object labOrientation: TLabel
        Left = 10
        Top = 16
        Width = 58
        Height = 13
        Caption = 'Orientation:'
      end
      object labWritingDirect: TLabel
        Left = 10
        Top = 34
        Width = 82
        Height = 13
        Caption = 'Writing direction:'
      end
    end
    object tvLayoutItems: TTreeList
      Left = 1
      Top = 95
      Width = 215
      Height = 598
      Align = alClient
      HideSelection = False
      Indent = 19
      ReadOnly = True
      RowSelect = True
      TabOrder = 1
      Visible = True
      OnChange = tvLayoutItemsChange
      Columns = <>
      Separator = ';'
      ItemHeight = 16
      HeaderSettings.Color = clBtnFace
      HeaderSettings.Font.Charset = DEFAULT_CHARSET
      HeaderSettings.Font.Color = clWindowText
      HeaderSettings.Font.Height = -11
      HeaderSettings.Font.Name = 'Tahoma'
      HeaderSettings.Font.Style = []
      HeaderSettings.Height = 18
      Version = '1.2.0.1'
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1284
    Height = 41
    Align = alTop
    TabOrder = 3
    object Button1: TButton
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 75
      Height = 33
      Align = alLeft
      Caption = 'Load image'
      TabOrder = 0
      OnClick = Button1Click
    end
  end
  object OpenPictureDialog1: TOpenPictureDialog
    Left = 448
    Top = 296
  end
end
