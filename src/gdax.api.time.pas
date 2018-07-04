unit gdax.api.time;

interface
uses
  Classes,gdax.api.types,gdax.api,gdax.api.consts;
type

  { TGDAXTimeImpl }

  TGDAXTimeImpl = class(TGDAXRestApi,IGDAXTime)
  public
    const
      PROP_ISO = 'iso';
      PROP_EPOCH = 'epoch';
  strict private
    FISO: String;
    FEpoch: Extended;
    function GetEpoch: Extended;
    function GetISO: String;
    procedure SetEpoch(AValue: Extended);
    procedure SetISO(AValue: String);
  strict protected
    function DoGetSupportedOperations: TRestOperations; override;
    function GetHeadersForOperation(const AOperation: TRestOperation;
      const AHeaders: TStrings; out Error: String): Boolean; override;
    function GetEndpoint(const AOperation: TRestOperation): String; override;
    function DoLoadFromJSON(const AJSON: String;
      out Error: String): Boolean;override;
  public
    property ISO: String read GetISO write SetISO;
    property Epoch: Extended read GetEpoch write SetEpoch;
  end;
implementation
uses
  DateUtils, SysUtils, SynCrossPlatformJSON;

{ TGDAXTimeImpl }

function TGDAXTimeImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXTimeImpl.GetHeadersForOperation(const AOperation: TRestOperation;
  const AHeaders: TStrings; out Error: String): Boolean;
begin
  Result:=False;
  try
    //to avoid circular dependency between authenticator and time,
    //we put the minimal headers here
    AHeaders.Add('%s=%s',['Content-Type','application/json']);
    AHeaders.Add('%s=%s',['User-Agent',USER_AGENT_MOZILLA]);
    Result:=True;
  except on E:Exception do
    Error:=E.Message;
  end;
end;

function TGDAXTimeImpl.DoLoadFromJSON(const AJSON: String;
  out Error: String): Boolean;
var
  LJSON:TJSONVariantData;
begin
  Result:=False;
  try
    if not LJSON.FromJSON(AJSON) then
    begin
      Error:=E_BADJSON;
      Exit;
    end;
    if LJSON.NameIndex(PROP_ISO)<0 then
    begin
      Error:=E_BADJSON;
      Exit;
    end;
    FISO:=LJSON.Value[PROP_ISO];
    if LJSON.NameIndex(PROP_EPOCH)<0 then
    begin
      Error:=E_BADJSON;
      Exit;
    end;
    FEpoch:=LJSON.Value[PROP_EPOCH];
    Result:=True;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TGDAXTimeImpl.GetEndpoint(const AOperation: TRestOperation): String;
begin
  Result:=GDAX_END_API_TIME;
end;

function TGDAXTimeImpl.GetEpoch: Extended;
begin
  Result:=FEpoch;
end;

function TGDAXTimeImpl.GetISO: String;
begin
  Result:=FISO;
end;

procedure TGDAXTimeImpl.SetEpoch(AValue: Extended);
begin
  FEpoch:=AValue;
end;

procedure TGDAXTimeImpl.SetISO(AValue: String);
begin
  FISO:=AValue;
end;

end.
