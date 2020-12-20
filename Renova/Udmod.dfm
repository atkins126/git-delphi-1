object dmod: Tdmod
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 150
  Width = 215
  object FDCCompareBDM: TFDConnection
    Params.Strings = (
      'User_Name=RenovaUser'
      'Password=!RenovaUser5'
      'OSAuthent=No'
      'Database=OBF'
      'DriverID=MSSQL')
    LoginPrompt = False
    Left = 104
  end
  object FDComRenova: TFDCommand
    Connection = FDCCompareBDM
    Left = 96
    Top = 56
  end
  object FDQuery1: TFDQuery
    Connection = FDCCompareBDM
    Left = 24
    Top = 8
  end
end
