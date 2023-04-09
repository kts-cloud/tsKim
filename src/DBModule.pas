unit DBModule;

interface

uses
  System.SysUtils, System.Classes, Data.DbxSqlite, Data.FMTBcd, Data.DB, Data.SqlExpr, Vcl.Forms, CommonClass;

const
  DEF_DEFAULT_TLB = 'TLB_ISPD';

type
  TDBModule_Sqlite = class(TDataModule)
    SQLConnection: TSQLConnection;
    SQLQuery: TSQLQuery;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
    bConnected    : Boolean;
    TactIndex     : Integer;
  public
    { Public declarations }
    ChannelCount: Integer;
    function DBConnect : Boolean;
    function CheckAndCreateTable(nMaxCh : Integer; sTableName : string = DEF_DEFAULT_TLB) : Boolean;
    function CheckAndCreateTimeTable(sTableName : string) : Boolean;
    procedure UpdateNGTypeCount(nCh, nNGType : Integer);
    procedure InsertTactTime(sTactTime : String);
    procedure CheckNGTypeFieldCount;
    function DropTable(sTableName : string = DEF_DEFAULT_TLB) : Boolean;
    function SendQueryOpen(sQuery : String) : Boolean;
    function SendQueryExec(sQuery : String) : Boolean;

  end;

var
  modDB: TDBModule_Sqlite;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function TDBModule_Sqlite.CheckAndCreateTable(nMaxCh : Integer; sTableName: string): Boolean;
var
  sL : TStringList;
  i  : Integer;
  bCheck : Boolean;
  sQuery, sQueryCh : String;
  nQueryRlt : Integer;
begin
  if not SQLConnection.Connected then DBConnect;

  ChannelCount:= nMaxCh;
  if bConnected then begin
    bCheck := False;
    sL := TStringList.Create;
    SQLConnection.GetTableNames(sL);
    // Check Table
    for i := 0 to sL.Count -1 do begin
      if sL[i] = sTableName then begin
        bCheck := True;
        Break;
      end;
    end;
    //Create Table
    if not bCheck then begin
      SQLQuery.SQL.Clear;
//      sQuery := Format('CREATE TABLE %s(INSP_DATE DATE NOT NULL, NG_TYPE NUMBER(3), CH1 NUMBER(10), CH2 NUMBER(10), CH3 NUMBER(10), CH4 NUMBER(10), PRIMARY KEY(''INSP_DATE'',''NG_TYPE''));',[sTableName]);
      sQueryCh := '';
      for i := 1 to ChannelCount do begin
        sQueryCh := sQueryCh + Format('CH%d INTEGER DEFAULT 0,',[i]);
      end;
      sQuery := Format('CREATE TABLE %s(INSP_DATE DATE NOT NULL, NG_TYPE NUMBER(3), %s PRIMARY KEY(''INSP_DATE'',''NG_TYPE''));',[sTableName, sQueryCh]);
      SQLQuery.SQL.Text := sQuery;
      nQueryRlt := SQLQuery.ExecSQL;
      if nQueryRlt = 0 then bCheck := True;
    end;
    sL.Free;
    Result := bCheck;
  end
  else begin
    Result := False;
  end;

end;

function TDBModule_Sqlite.CheckAndCreateTimeTable(sTableName: string): Boolean;
var
  sL : TStringList;
  i  : Integer;
  bCheck : Boolean;
  sQuery : String;
  nQueryRlt : Integer;
begin
  if not SQLConnection.Connected then DBConnect;

  if bConnected then begin
    bCheck := False;
    sL := TStringList.Create;
    SQLConnection.GetTableNames(sL);
    // Check Table
    for i := 0 to sL.Count -1 do begin
      if sL[i] = sTableName then begin
        bCheck := True;
        Break;
      end;
    end;
    //Create Table
    if not bCheck then begin
      SQLQuery.SQL.Clear;
      sQuery := Format('CREATE TABLE %s(No NUMBER(2), TACTTIME DOUBLE);',[sTableName]);
      SQLQuery.SQL.Text := sQuery;
      nQueryRlt := SQLQuery.ExecSQL;
      if nQueryRlt = 0 then bCheck := True;
    end;
    sL.Free;
    Result := bCheck;
  end
  else begin
    Result := False;
  end;
end;

procedure TDBModule_Sqlite.CheckNGTypeFieldCount;
var
  sQuery, sDate : string;
  i , nFDCount : Integer;
begin
  if not SQLConnection.Connected then DBConnect;

  sDate := FormatDateTime('YYYYMMDD',now);
  sQuery := Format('SELECT COUNT(NG_TYPE) FROM TLB_ISPD WHERE INSP_DATE = ''%s''',[sDate]);
  SendQueryOpen(sQuery);

  nFDCount := Length(Common.GmesInfo);
  if SQLQuery.Fields[0].AsInteger = 0 then begin // Date가 없는 경우 Check
    for i := 0 to nFDCount do begin
      sQuery := Format('INSERT INTO TLB_ISPD(INSP_DATE, NG_TYPE) VALUES(''%s'',%d)',[sDate,i]);
      SendQueryExec(sQuery);
    end;
  end
  else begin
    if nFDCount <> SQLQuery.Fields[0].AsInteger then begin
//      Application.MessageBox('Different Count','Confirm',MB_OK + MB_ICONINFORMATION );
      for i := 0 to nFDCount do begin
        sQuery := Format('SELECT NG_TYPE FROM TLB_ISPD WHERE INSP_DATE = ''%s'' AND NG_TYPE=%d',[sDate,i]);
        SendQueryOpen(sQuery);
        if SQLQuery.IsEmpty then begin
          sQuery := Format('INSERT INTO TLB_ISPD(INSP_DATE, NG_TYPE) VALUES(''%s'',%d)',[sDate,i]);
          SendQueryExec(sQuery);
        end;
      end;
    end;
  end;
end;

procedure TDBModule_Sqlite.DataModuleCreate(Sender: TObject);
begin
  Self.TactIndex := 0;
  SQLConnection.Params.Values['Database'] := ExtractFilePath(Application.ExeName) + 'ISPD.db';
end;

function TDBModule_Sqlite.DBConnect: Boolean;
begin
  SQLConnection.Open;
  bConnected := SQLConnection.Connected;
  Result := bConnected;
end;

function TDBModule_Sqlite.DropTable(sTableName: string): Boolean;
var
  sQuery : String;
  nQueryRlt : Integer;
begin
  if not SQLConnection.Connected then DBConnect;

  SQLQuery.SQL.Clear;
  sQuery := Format('DROP TABLE %s;',[sTableName]);
  SQLQuery.SQL.Text := sQuery;
  nQueryRlt := SQLQuery.ExecSQL;
  if nQueryRlt = 0 then Result := True
  else Result := False;
end;

procedure TDBModule_Sqlite.InsertTactTime(sTactTime: string);
var
  sQuery : String;
begin
  if not SQLConnection.Connected then DBConnect;

  if TactIndex > 9 then TactIndex := 0;
  // 조회 후 있으면 삭제 -> Insert
  sQuery := Format('SELECT * FROM TLB_ISPD_TIME WHERE No = %d;',[TactIndex]);
  SendQueryOpen(sQuery);
  if SQLQuery.RecordCount > 0 then begin
    // 삭제
    sQuery := Format('DELETE FROM TLB_ISPD_TIME WHERE No = %d;',[TactIndex]);
    SendQueryExec(sQuery);
  end;

  sQuery := Format('INSERT INTO TLB_ISPD_TIME VALUES (%d,%s);',[TactIndex,sTactTime]);
  SendQueryExec(sQuery);
  inc(TactIndex);
end;

function TDBModule_Sqlite.SendQueryExec(sQuery: String): Boolean;
var
  nQueryRlt : Integer;
begin
  if not SQLConnection.Connected then DBConnect;

  SQLQuery.SQL.Clear;
  SQLQuery.SQL.Text := sQuery;
  nQueryRlt := SQLQuery.ExecSQL;
  if nQueryRlt = 0 then Result := True
  else Result := False;
end;

function TDBModule_Sqlite.SendQueryOpen(sQuery: String): Boolean;
begin
  if not SQLConnection.Connected then DBConnect;

  SQLQuery.SQL.Clear;
  SQLQuery.SQL.Text := sQuery;

  try
    SQLQuery.Open;
    Result := True;
  except
    Result := False;
  end;
end;

procedure TDBModule_Sqlite.UpdateNGTypeCount(nCh, nNGType: Integer);
var
  sQuery ,sDate : String;
  i : Integer;
begin
  if not SQLConnection.Connected then DBConnect;

  sDate := FormatDateTime('YYYYMMDD',now);

  sQuery := Format('SELECT COUNT(NG_TYPE) FROM TLB_ISPD WHERE INSP_DATE = ''%s''',[sDate]);
  SendQueryOpen(sQuery);
  if (SQLQuery.Fields[0].AsInteger = 0) then begin // Date가 없는 경우 Check , 필드 카운드가 0인경우
    for i := 0 to Length(Common.GmesInfo) do begin
      sQuery := Format('INSERT INTO TLB_ISPD(INSP_DATE, NG_TYPE) VALUES(''%s'',%d)',[sDate,i]);
      SendQueryExec(sQuery);
    end;
  end;

  sQuery := Format('UPDATE TLB_ISPD SET CH%d = CH%d + 1 WHERE (INSP_DATE = ''%s'') AND (NG_TYPE = %d)',[nCh,nCh,sDate,nNGType]);
  SendQueryExec(sQuery);
end;

end.
