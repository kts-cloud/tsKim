object DBModule_Sqlite: TDBModule_Sqlite
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 159
  Width = 325
  object SQLConnection: TSQLConnection
    DriverName = 'Sqlite'
    LoginPrompt = False
    Params.Strings = (
      'DriverName=Sqlite'
      'DriverUnit=Data.DbxSqlite'
      
        'DriverPackageLoader=TDBXSqliteDriverLoader,DBXSqliteDriver250.bp' +
        'l'
      
        'MetaDataPackageLoader=TDBXSqliteMetaDataCommandFactory,DbxSqlite' +
        'Driver250.bpl'
      'FailIfMissing=False'
      
        'Database=C:\Users\sam81\Documents\Embarcadero\Studio\Projects\DB' +
        'Test\bin\ISPD.db'
      'HostName=LocalDB'
      'User_Name=Local')
    Left = 34
    Top = 66
  end
  object SQLQuery: TSQLQuery
    MaxBlobSize = -1
    Params = <>
    SQLConnection = SQLConnection
    Left = 128
    Top = 68
  end
end
