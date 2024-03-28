unit PdhExample;

interface

uses
  Windows, SysUtils;

type
  PDH_STATUS = Longint;
  PDH_FMT_COUNTERVALUE = record
    CStatus: PDH_STATUS;
    doubleValue: Double;
  end;
  PPDH_FMT_COUNTERVALUE = ^PDH_FMT_COUNTERVALUE;

const
  PDH_INVALID_DATA = -1;
  PDH_FMT_DOUBLE = $00000200;

function PdhOpenQuery(szDataSource: PChar; dwUserData: Longint; var phQuery: THandle): PDH_STATUS; stdcall; external 'pdh.dll';
function PdhAddCounter(hQuery: THandle; szFullCounterPath: PChar; dwUserData: Longint; var phCounter: THandle): PDH_STATUS; stdcall; external 'pdh.dll';
function PdhCollectQueryData(hQuery: THandle): PDH_STATUS; stdcall; external 'pdh.dll';
function PdhGetFormattedCounterValue(hCounter: THandle; dwFormat: Longint; lpdwType: LPDWORD; var pValue: PDH_FMT_COUNTERVALUE): PDH_STATUS; stdcall; external 'pdh.dll';
function PdhCloseQuery(hQuery: THandle): PDH_STATUS; stdcall; external 'pdh.dll';
function PdhRemoveCounter(hCounter: THandle): PDH_STATUS; stdcall; external 'pdh.dll';

function GetCpuUsage: Double;


implementation


function PdhCheck(PdhResult: PDH_STATUS): Boolean;
begin
  Result := (PdhResult = ERROR_SUCCESS) or (PdhResult = PDH_INVALID_DATA);
end;

function GetCpuUsage: Double;
const
  QUERY_INTERVAL = 1000; // 1초마다 CPU 사용량을 업데이트
var
  Query: THandle;
  Counter: THandle;
  Status: PDH_STATUS;
  CounterValue: PDH_FMT_COUNTERVALUE; // 이름을 CounterValue로 변경
begin
  Query := 0;
  Counter := 0;

  try
    // PdhOpenQuery 함수를 사용하여 쿼리 핸들을 생성
    Status := PdhOpenQuery(nil, 0, Query);
    if not PdhCheck(Status) then
      RaiseLastOSError(Status);

    // PdhAddCounter 함수를 사용하여 성능 카운터를 추가
    Status := PdhAddCounter(Query, '\\.\Processor(_Total)\% Processor Time', 0, Counter);
    if not PdhCheck(Status) then
      RaiseLastOSError(Status);

    // PdhCollectQueryData 함수를 사용하여 쿼리 데이터 수집 시작
    Status := PdhCollectQueryData(Query);
    if not PdhCheck(Status) then
      RaiseLastOSError(Status);

    // 쿼리 간격만큼 기다림
    Sleep(QUERY_INTERVAL);

    // PdhCollectQueryData 함수를 사용하여 쿼리 데이터 수집 종료
    Status := PdhCollectQueryData(Query);
    if not PdhCheck(Status) then
      RaiseLastOSError(Status);

    // PdhGetFormattedCounterValue 함수를 사용하여 성능 카운터 값 가져오기
    Status := PdhGetFormattedCounterValue(Counter, PDH_FMT_DOUBLE, nil, CounterValue);
    if not PdhCheck(Status) then
      RaiseLastOSError(Status);

    Result := CounterValue.doubleValue;
  finally
    // PdhCloseQuery 함수를 사용하여 쿼리 핸들 리소스 해제
    if Query <> 0 then
      PdhCloseQuery(Query);

    // PdhRemoveCounter 함수를 사용하여 성능 카운터 리소스 해제
    if Counter <> 0 then
      PdhRemoveCounter(Counter);
  end;
end;
end.

