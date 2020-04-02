{ GDAX/Coinbase-Pro client library

  Copyright (c) 2018 mr-highball

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
}

unit gdax.api.candles;

{$i gdax.inc}

interface
uses
  Classes, gdax.api, gdax.api.consts, gdax.api.types;
type

  TGDAXCandlesImpl = class(TGDAXRestApi,IGDAXCandles)
  public const
    MAX_CANDLES = 300;
    ACCEPTED_GRANULARITY : array[0..5] of Integer = (60,300,900,3600,21600,86400);
  private
    FProduct: IGDAXProduct;
    FList: TGDAXCandleBucketList;
    FStartTime: TDatetime;
    FEndTime: TDatetime;
    FGranularity: Cardinal;
  protected
    function GetProduct: IGDAXProduct;
    procedure SetProduct(Const Value: IGDAXProduct);
    function GetStartTime: TDatetime;
    procedure SetStartTime(Const Value: TDatetime);
    function GetEndTime: TDatetime;
    procedure SetEndTime(Const Value: TDatetime);
    function GetGranularity: Cardinal;
    procedure SetGranularity(Const Value: Cardinal);
    function BuildQueryParams:String;
    function GetList: TGDAXCandleBucketList;
  protected
    function DoGetSupportedOperations: TRestOperations; override;
    function DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
      out Content: string; out Error: string): Boolean; override;
    function DoLoadFromJSON(Const AJSON: string; out Error: string): Boolean;
      override;
    function GetEndpoint(Const AOperation: TRestOperation): string; override;
  public
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property StartTime: TDatetime read GetStartTime write SetStartTime;
    property Granularity: Cardinal read GetGranularity write SetGranularity;
    property EndTime: TDatetime read GetEndTime write SetEndTime;
    property List: TGDAXCandleBucketList read GetList;
    constructor Create; override;
    destructor Destroy; override;
  end;
implementation

uses
  SysUtils,
  fpjson,
  jsonparser,
  Dateutils,
  fpindexer;

{ TGDAXCandlesImpl }

function TGDAXCandlesImpl.BuildQueryParams: String;
var
  LGran:Integer;
begin
  Result:='';

  if FGranularity < ACCEPTED_GRANULARITY[Low(ACCEPTED_GRANULARITY)] then
  begin
    FGranularity := SecondsBetween(FStartTime,FEndTime);

    //if still less than 1, then just set it to the lowest accepted
    if FGranularity < 1 then
      FGranularity := ACCEPTED_GRANULARITY[Low(ACCEPTED_GRANULARITY)];
  end;

  //find if we aren't above the maximum candles
  if Round(SecondsBetween(FStartTime,FEndTime) / FGranularity)>MAX_CANDLES then
    LGran := Round(SecondsBetween(FStartTime, FEndTime) / FGranularity)
  else
    LGran := FGranularity;

  //finally return the query params
  Result := Format(
    '?start=%s&end=%s&granularity=%d',
    [
      DateToISO8601(FStartTime),
      DateToISO8601(FEndTime),
      LGran
    ]
  );
end;

constructor TGDAXCandlesImpl.Create;
begin
  inherited;
  FList := TGDAXCandleBucketList.Create;
  FGranularity := ACCEPTED_GRANULARITY[Low(ACCEPTED_GRANULARITY)];
end;

destructor TGDAXCandlesImpl.Destroy;
begin
  FProduct := nil;
  FList.Free;
  inherited;
end;

function TGDAXCandlesImpl.DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
  out Content, Error: string): Boolean;
begin
  Result := False;

  if not Assigned(FProduct) then
  begin
    Error := Format(E_UNKNOWN,['candles product', 'TGDAXCandlesImpl DoGet']);
    Exit;
  end;

  Result := inherited;
end;

function TGDAXCandlesImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXCandlesImpl.DoLoadFromJSON(Const AJSON: string;
  out Error: string): Boolean;
var
  LJSON : TJSONArray;
  I: Integer;
const
  T_IX = 0;
  L_IX = 1;
  H_IX = 2;
  O_IX = 3;
  C_IX = 4;
  V_IX = 5;
begin
  Result := False;
  try
    FList.Clear;
    LJSON := TJSONArray(GetJSON(AJSON));

    if not Assigned(LJSON) then
      raise Exception.Create(E_BADJSON);

    try
      for I := 0 to Pred(LJSON.Count) do
      begin
        FList.Add(
          TCandleBucket.create(
            TJSONArray(LJSON.Items[I]).Items[T_IX].AsFloat,
            TJSONArray(LJSON.Items[I]).Items[L_IX].AsFloat,
            TJSONArray(LJSON.Items[I]).Items[H_IX].AsFloat,
            TJSONArray(LJSON.Items[I]).Items[O_IX].AsFloat,
            TJSONArray(LJSON.Items[I]).Items[C_IX].AsFloat,
            TJSONArray(LJSON.Items[I]).Items[V_IX].AsFloat
          )
        );
      end;

      Result := True;
    finally
      LJSON.Free;
    end;
  except on E: Exception do
    Error := E.Message;
  end;
end;

function TGDAXCandlesImpl.GetEndpoint(Const AOperation: TRestOperation): string;
begin
  Result:='';
  if not Assigned(FProduct) then
    raise Exception.Create(Format(E_UNKNOWN,['product',Self.ClassName]));
  Result := Format(GDAX_END_API_CANDLES,[FProduct.ID])+BuildQueryParams;
end;

function TGDAXCandlesImpl.GetEndTime: TDatetime;
begin
  Result := FEndTime;
end;

function TGDAXCandlesImpl.GetGranularity: Cardinal;
begin
  Result := FGranularity;
end;

function TGDAXCandlesImpl.GetList: TGDAXCandleBucketList;
begin
  Result := FList;
end;

function TGDAXCandlesImpl.GetProduct: IGDAXProduct;
begin
  Result := FProduct;
end;

function TGDAXCandlesImpl.GetStartTime: TDatetime;
begin
  Result := FStartTime;
end;

procedure TGDAXCandlesImpl.SetEndTime(Const Value: TDatetime);
begin
  FEndTime := Value;
end;

procedure TGDAXCandlesImpl.SetGranularity(Const Value: Cardinal);
var
  I:Integer;
begin
  FGranularity := Value;
  //we have to check for valid granularities otherwise
  //the request will get ignored
  for I:=0 to High(ACCEPTED_GRANULARITY) do
    if FGranularity>ACCEPTED_GRANULARITY[I] then
      Continue
    else
    begin
      FGranularity := ACCEPTED_GRANULARITY[I];
      Exit;
    end;
  //if we couldn't find a match, set to the highest accepted granularity
  FGranularity := ACCEPTED_GRANULARITY[High(ACCEPTED_GRANULARITY)];
end;

procedure TGDAXCandlesImpl.SetProduct(Const Value: IGDAXProduct);
begin
  FProduct := nil;
  FProduct := Value;
end;

procedure TGDAXCandlesImpl.SetStartTime(Const Value: TDatetime);
begin
  FStartTime := Value;
end;

end.
