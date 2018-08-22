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

unit gdax.api.ticker;

{$i gdax.inc}

interface
uses
  Classes, SysUtils, gdax.api, gdax.api.consts, gdax.api.types;

type

  { TGDAXTickerImpl }

  TGDAXTickerImpl = class(TGDAXRestApi,IGDAXTicker)
  strict private
    FProduct: IGDAXProduct;
    FSize: Extended;
    FAsk: Extended;
    FBid: Extended;
    FTime: TDateTime;
    FVolume: Extended;
    FPrice: Extended;
    function GetProduct: IGDAXProduct;
    procedure SetProduct(Const Value: IGDAXProduct);
    function GetSize: Extended;
    procedure SetSize(Const Value: Extended);
    function GetAsk: Extended;
    function GetBid: Extended;
    function GetTime: TDateTime;
    function GetVolume: Extended;
    procedure SetAsk(Const Value: Extended);
    procedure SetBid(Const Value: Extended);
    procedure SetTime(Const Value: TDateTime);
    procedure SetVolume(Const Value: Extended);
    function GetPrice: Extended;
    procedure SetPrice(Const Value: Extended);
  strict protected
    function GetEndpoint(Const AOperation: TRestOperation): string; override;
    function DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
      out Content: string; out Error: string): Boolean; override;
    function DoGetSupportedOperations: TRestOperations; override;
    function DoLoadFromJSON(Const AJSON: string; out Error: string): Boolean;
      override;
  public
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property Price: Extended read GetPrice write SetPrice;
    property Size: Extended read GetSize write SetSize;
    property Bid: Extended read GetBid write SetBid;
    property Ask: Extended read GetAsk write SetAsk;
    property Volume: Extended read GetVolume write SetVolume;
    property Time: TDateTime read GetTime write SetTime;
    constructor Create; override;
    destructor Destroy; override;
  end;
implementation
uses
  SynCrossPlatformJSON, fpindexer;

{ TProductTicket }

constructor TGDAXTickerImpl.Create;
begin
  inherited Create;
  FProduct:=nil;
  FSize:=0;
  FAsk:=0;
  FBid:=0;
  FTime:=Now;
  FVolume:=0;
  FPrice:=0;
end;

destructor TGDAXTickerImpl.Destroy;
begin
  FProduct:=nil;
  inherited Destroy;
end;

function TGDAXTickerImpl.DoGet(Const AEndpoint: string;
  Const AHeaders: TStrings; out Content: string; out Error: string): Boolean;
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

function TGDAXTickerImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXTickerImpl.DoLoadFromJSON(Const AJSON: string;
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
    FPrice:=LJSON.Value['price'];
    FSize:=LJSON.Value['size'];
    FAsk:=LJSON.Value['ask'];
    FBid:=LJSON.Value['bid'];
    FVolume:=LJSON.Value['volume'];
    FTime:=ISO8601ToDate(LJSON.Value['time']);
    Result:=True;
  except on E: Exception do
    Error:=E.ClassName+': '+E.Message;
  end;
end;

function TGDAXTickerImpl.GetAsk: Extended;
begin
  Result:=FAsk;
end;

function TGDAXTickerImpl.GetBid: Extended;
begin
  Result:=FBid;
end;

function TGDAXTickerImpl.GetEndpoint(Const AOperation: TRestOperation): string;
begin
  Result:='';
  if not Assigned(FProduct) then
    raise Exception.Create(Format(E_UNKNOWN,['product',Self.ClassName]));
  if AOperation=roGet then
    Result:=Format(GDAX_END_API_TICKER,[FProduct.ID]);
end;

function TGDAXTickerImpl.GetPrice: Extended;
begin
  Result:=FPrice;
end;

function TGDAXTickerImpl.GetProduct: IGDAXProduct;
begin
  Result:=FProduct;
end;

function TGDAXTickerImpl.GetSize: Extended;
begin
  Result:=FSize;
end;

function TGDAXTickerImpl.GetTime: TDateTime;
begin
  Result:=FTime;
end;

function TGDAXTickerImpl.GetVolume: Extended;
begin
  Result:=FVolume;
end;

procedure TGDAXTickerImpl.SetAsk(Const Value: Extended);
begin
  FAsk:=Value;
end;

procedure TGDAXTickerImpl.SetBid(Const Value: Extended);
begin
  FBid:=Value;
end;


procedure TGDAXTickerImpl.SetPrice(Const Value: Extended);
begin
  FPrice:=Value;
end;

procedure TGDAXTickerImpl.SetProduct(Const Value: IGDAXProduct);
begin
  FProduct:=nil;
  FProduct:=Value;
end;

procedure TGDAXTickerImpl.SetSize(Const Value: Extended);
begin
  FSize:=Value;
end;

procedure TGDAXTickerImpl.SetTime(Const Value: TDateTime);
begin
  FTime:=Value;
end;

procedure TGDAXTickerImpl.SetVolume(Const Value: Extended);
begin
  FVolume:=Value;
end;

end.
