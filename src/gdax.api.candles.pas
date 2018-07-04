unit gdax.api.candles;

{$i gdax.inc}

interface
uses
  Classes, gdax.api, gdax.api.consts, gdax.api.types;
type

  TCandles = class(TGDAXRestApi)
  private const
    MAX_CANDLES = 200;
    ACCEPTED_GRANULARITY : array of Integer = [60,300,900,3600,21600,86400];
  private
    FProduct: IGDAXProduct;
    FList: TList<TCandleBucket>;
    FStartTime: TDatetime;
    FEndTime: TDatetime;
    FGranularity: Cardinal;
    function GetProduct: IGDAXProduct;
    procedure SetProduct(const Value: IGDAXProduct);
    function GetStartTime: TDatetime;
    procedure SetStartTime(const Value: TDatetime);
    function GetEndTime: TDatetime;
    procedure SetEndTime(const Value: TDatetime);
    function GetGranularity: Cardinal;
    procedure SetGranularity(const Value: Cardinal);
    function BuildQueryParams:String;
    function GetList: TList<TCandleBucket>;
  protected
    function DoGetSupportedOperations: TRestOperations; override;
    function DoGet(const AEndpoint: string; const AHeaders: TStrings;
      out Content: string; out Error: string): Boolean; override;
    function DoLoadFromJSON(const AJSON: string; out Error: string): Boolean;
      override;
    function GetEndpoint(const AOperation: TRestOperation): string; override;
  public
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property StartTime: TDatetime read GetStartTime write SetStartTime;
    property Granularity: Cardinal read GetGranularity write SetGranularity;
    property EndTime: TDatetime read GetEndTime write SetEndTime;
    property List: TList<TCandleBucket> read GetList;
    constructor Create; override;
    destructor Destroy; override;
  end;
implementation

uses
  SysUtils,SynCrossPlatformJSON,Dateutils;

{ TCandles }

function TCandles.BuildQueryParams: String;
var
  LGran:Integer;
begin
  Result:='';
  if FGranularity<1 then
  begin
    FGranularity:=SecondsBetween(FStartTime,FEndTime);
    //if still less than 1, then just set it to 1
    if FGranularity<1 then
      FGranularity:=1;
  end;
  //find if we aren't above the maximum candles
  if Round(SecondsBetween(FStartTime,FEndTime) / FGranularity)>MAX_CANDLES then
    LGran:=Round(SecondsBetween(FStartTime,FEndTime) / FGranularity)
  else
    LGran:=FGranularity;
  //finally return the query params
  Result:=Format(
    '?start=%s&end=%s&granularity=%d',
    [
      DateTimeToIso8601(FStartTime),
      DateTimeToIso8601(FEndTime),
      LGran
    ]
  );
end;

constructor TCandles.Create;
begin
  inherited;
  FList:=TList<TCandleBucket>.Create;
end;

destructor TCandles.Destroy;
begin
  FList.Free;
  inherited;
end;

function TCandles.DoGet(const AEndpoint: string; const AHeaders: TStrings;
  out Content, Error: string): Boolean;
begin
  Result:=False;
  if FProduct=opUnknown then
  begin
    Error:=Format(E_UNKNOWN,['candles product','TCandles DoGet']);
    Exit;
  end;
  Result:=inherited;
end;

function TCandles.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TCandles.DoLoadFromJSON(const AJSON: string;
  out Error: string): Boolean;
var
  LJSON:TJSONVariantData;
  I: Integer;
const
  T_IX = 0;
  L_IX = 1;
  H_IX = 2;
  O_IX = 3;
  C_IX = 4;
  V_IX = 5;
begin
  Result:=False;
  try
    FList.Clear;
    //valid json?
    if not LJSON.FromJSON(AJSON) then
    begin
      Error:=E_BADJSON;
      Exit;
    end;
    //this object returns an array of arrays (buckets)
    if not (LJSON.Kind=jvArray) then
    begin
      Error:=Format(E_BADJSON_PROP,['main array']);
      Exit;
    end;
    for I := 0 to Pred(LJSON.Count) do
    begin
      FList.Add(
        TCandleBucket.create(
          TJSONVariantData(LJSON.Item[I]).Item[T_IX],
          TJSONVariantData(LJSON.Item[I]).Item[L_IX],
          TJSONVariantData(LJSON.Item[I]).Item[H_IX],
          TJSONVariantData(LJSON.Item[I]).Item[O_IX],
          TJSONVariantData(LJSON.Item[I]).Item[C_IX],
          TJSONVariantData(LJSON.Item[I]).Item[V_IX]
        )
      );
    end;
    Result:=True;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TCandles.GetEndpoint(const AOperation: TRestOperation): string;
begin
  Result:=Format(GDAX_END_API_CANDLES,[OrderProductToString(FProduct)])+BuildQueryParams;
end;

function TCandles.GetEndTime: TDatetime;
begin
  Result:=FEndTime;
end;

function TCandles.GetGranularity: Cardinal;
begin
  Result:=FGranularity;
end;

function TCandles.GetList: TList<TCandleBucket>;
begin
  Result:=FList;
end;

function TCandles.GetProduct: IGDAXProduct;
begin
  Result:=FProduct;
end;

function TCandles.GetStartTime: TDatetime;
begin
  Result:=FStartTime;
end;

procedure TCandles.SetEndTime(const Value: TDatetime);
begin
  FEndTime:=Value;
end;

procedure TCandles.SetGranularity(const Value: Cardinal);
var
  I:Integer;
begin
  FGranularity:=Value;
  //we have to check for valid granularities otherwise
  //the request will get ignored
  for I:=0 to High(ACCEPTED_GRANULARITY) do
    if FGranularity>ACCEPTED_GRANULARITY[I] then
      Continue
    else
    begin
      FGranularity:=ACCEPTED_GRANULARITY[I];
      Exit;
    end;
  //if we couldn't find a match, set to the highest accepted granularity
  FGranularity:=ACCEPTED_GRANULARITY[High(ACCEPTED_GRANULARITY)];
end;

procedure TCandles.SetProduct(const Value: IGDAXProduct);
begin
  FProduct:=Value;
end;

procedure TCandles.SetStartTime(const Value: TDatetime);
begin
  FStartTime:=Value;
end;

end.
