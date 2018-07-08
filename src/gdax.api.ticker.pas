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
  Classes, SysUtils, gdax.api, gdax.api.consts, gdax.api.types,
  {$IFDEF FPC}
  fgl
  {$ELSE}
  System.Generics.Collections
  {$ENDIF};
type
  TProductTicker = class(TGDAXRestApi,IGDAXTicker)
  strict private
    FProduct: IGDAXProduct;
    FSize: Extended;
    FAsk: Extended;
    FBid: Extended;
    FTime: String;
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
    procedure SetTime(Const Value: String);
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

function TProductTicker.DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
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

function TProductTicker.DoLoadFromJSON(Const AJSON: string;
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

function TProductTicker.GetAsk: Extended;
begin
  Result:=FAsk;
end;

function TProductTicker.GetBid: Extended;
begin
  Result:=FBid;
end;

function TProductTicker.GetEndpoint(Const AOperation: TRestOperation): string;
begin
  Result:=Format(GDAX_END_API_TICKER,[FProduct.ID]);
end;

function TProductTicker.GetPrice: Extended;
begin
  Result:=FPrice;
end;

function TProductTicker.GetProduct: IGDAXProduct;
begin
  Result:=FProduct;
end;

function TProductTicker.GetSize: Extended;
begin
  Result:=FSize;
end;

function TProductTicker.GetTime: String;
begin
  Result:=FTime;
end;

function TProductTicker.GetVolume: Extended;
begin
  Result:=FVolume;
end;

procedure TProductTicker.SetAsk(Const Value: Extended);
begin
  FAsk:=Value;
end;

procedure TProductTicker.SetBid(Const Value: Extended);
begin
  FBid:=Value;
end;


procedure TProductTicker.SetPrice(Const Value: Extended);
begin
  FPrice:=Value;
end;

procedure TProductTicker.SetProduct(Const Value: IGDAXProduct);
begin
  FProduct:=Value;
end;

procedure TProductTicker.SetSize(Const Value: Extended);
begin
  FSize:=Value;
end;

procedure TProductTicker.SetTime(Const Value: String);
begin
  FTime:=Value;
end;

procedure TProductTicker.SetVolume(Const Value: Extended);
begin
  FVolume:=Volume;
end;

end.
