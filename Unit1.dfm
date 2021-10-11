object Form1: TForm1
  Left = 237
  Top = 121
  Width = 508
  Height = 574
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'Tanks'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar1: TStatusBar
    Left = 0
    Top = 501
    Width = 500
    Height = 19
    Panels = <
      item
        Text = #1054#1089#1090#1072#1083#1086#1089#1100' '#1090#1072#1085#1082#1086#1074': 0'
        Width = 150
      end
      item
        Text = #1054#1095#1082#1080': 0'
        Width = 50
      end>
  end
  object XPManifest1: TXPManifest
    Left = 72
    Top = 8
  end
  object MainMenu1: TMainMenu
    Left = 40
    Top = 8
    object N1: TMenuItem
      Caption = #1048#1075#1088#1072
      object N2: TMenuItem
        Caption = #1047#1072#1075#1088#1091#1079#1080#1090#1100' '#1082#1072#1088#1090#1091
      end
      object N7: TMenuItem
        Caption = '-'
      end
      object N3: TMenuItem
        Caption = #1042#1099#1093#1086#1076
        OnClick = N3Click
      end
    end
    object N4: TMenuItem
      Caption = #1055#1086#1084#1086#1097#1100
      object N5: TMenuItem
        Caption = #1057#1087#1088#1072#1074#1082#1072
      end
      object N6: TMenuItem
        Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077'...'
      end
    end
  end
  object Bonus: TTimer
    Enabled = False
    Interval = 10000
    OnTimer = BonusTimer
    Left = 8
    Top = 8
  end
end
