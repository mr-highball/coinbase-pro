unit gdax.api.ticker;

{$i gdax.inc}

interface
uses
  Classes, SysUtils, gdax.api, gdax.api.consts, gdax.api.types,
  {$IFDEF FPC}
  fgl
  {$ELSE}
  System.Generics.Collections
  {$ENDIF};
type
  TProductTicker = class(TGDAXRestApi)
  strict private
    FProduct: IGDAXProduct;
    FSize: Single;
    FAsk: Single;
    FBid: Single;
    FTime: String;
    FVolume: Single;
    FPrice: Single;
    function GetProduct: IGDAXProduct;
    procedure SetProduct(const Value: IGDAXProduct);
    function GetSize: Single;
    procedure SetSize(const Value: Single);
    function GetAsk: Single;
    function GetBid: Single;
    function GetTime: String;
    function GetVolume: Single;
    procedure SetAsk(const Value: Single);
    procedure SetBid(const Value: Single);
    procedure SetTime(const Value: String);
    procedure SetVolume(const Value: Single);
    function GetPrice: Single;
    procedure SetPrice(const Value: Single);
  strict protected
    function GetEndpoint(const AOperation: TRestOperation): string; override;
    function DoGet(const AEndpoint: string; const AHeaders: TStrings;
      out Content: string; out Error: string): Boolean; override;
    function DoGetSupportedOperations: TRestOperations; override;
    function DoLoadFromJSON(const AJSON: string; out Error: string): Boolean;
      override;
  public
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property Price: Single read GetPrice write SetPrice;
    property Size: Single read GetSize write SetSize;
    property Bid: Single read GetBid write SetBid;
    property Ask: Single read GetAsk write SetAsk;
    property Volume: Single read GetVolume write SetVolume;
    property Time: String read GetTime write SetTime;
    constructor Create; override;
  end;
implementation
uses
  SynCrossPlatformJSON,Math;
{ TProductTicket }

constructor TProductTicker.Create;
begin
  inherited;
  FProduct:=opUnknown;
end;

function TProductTicker.DoGet(const AEndpoint: string; const AHeaders: TStrings;
  out Content, Error: string): Boolean;
begin
  Result:=False;
  try
    if not Assigned(FProduct) then
    begin
      Error:=Format(E_UNKNOWN,['product',Self.ClassName]);
      Exit;
    end;
    Result:=inherited;
  except on E: Exception do
    Error:=E.ClassName+': '+E.Message;
  end;
end;

function TProductTicker.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TProductTicker.DoLoadFromJSON(const AJSON: string;
  out Error: string): Boolean;
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
    FPrice:=SimpleRoundTo(StrToFloat(LJSON.Value['price']),-2);
    FSize:=SimpleRoundTo(StrToFloat(LJSON.Value['size']),-3);
    FAsk:=SimpleRoundTo(StrToFloat(LJSON.Value['ask']),-2);
    FBid:=SimpleRoundTo(StrToFloat(LJSON.Value['bid']),-2);
    FVolume:=SimpleRoundTo(StrToFloat(LJSON.Value['volume']),-8);
    FTime:=LJSON.Value['time'];
    Result:=True;
  except on E: Exception do
    Error:=E.ClassName+': '+E.Message;
  end;
end;

function TProductTicker.GetAsk: Single;
begin
  Result:=FAsk;
end;

function TProductTicker.GetBid: Single;
begin
  Result:=FBid;
end;

function TProductTicker.GetEndpoint(const AOperation: TRestOperation): string;
begin
  Result:=Format(GDAX_END_API_TICKER,[FProduct.ID]);
end;

function TProductTicker.GetPrice: Single;
begin
  Result:=FPrice;
end;

function TProductTicker.GetProduct: IGDAXProduct;
begin
  Result:=FProduct;
end;

function TProductTicker.GetSize: Single;
begin
  Result:=FSize;
end;

function TProductTicker.GetTime: String;
begin
  Result:=FTime;
end;

function TProductTicker.GetVolume: Single;
begin
  Result:=FVolume;
end;

procedure TProductTicker.SetAsk(const Value: Single);
begin
  FAsk:=Value;
end;

procedure TProductTicker.SetBid(const Value: Single);
begin
  FBid:=Value;
end;


procedure TProductTicker.SetPrice(const Value: Single);
begin
  FPrice:=Value;
end;

procedure TProductTicker.SetProduct(const Value: IGDAXProduct);
begin
  FProduct:=Value;
end;

procedure TProductTicker.SetSize(const Value: Single);
begin
  FSize:=Value;
end;

procedure TProductTicker.SetTime(const Value: String);
begin
  FTime:=Value;
end;

procedure TProductTicker.SetVolume(const Value: Single);
begin
  FVolume:=Volume;
end;

end.
