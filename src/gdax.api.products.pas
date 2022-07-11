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

unit gdax.api.products;

{$i gdax.inc}

interface

uses
  Classes, SysUtils, gdax.api.types, gdax.api.consts, gdax.api;
type

  { TGDAXProductImpl }

  TGDAXProductImpl = class(TGDAXRestApi,IGDAXProduct)
  public
    const
      PROP_ID = 'id';
      PROP_BASE_CUR = 'base_currency';
      PROP_QUOTE_CUR = 'quote_currency';
      PROP_BASE_MIN = 'base_min_size';
      PROP_BASE_MAX = 'base_max_size';
      PROP_QUOTE_INC = 'quote_increment';
      PROP_MIN_MARKET_FUNDS = 'min_market_funds';
      PROP_MAX_MARKET_FUNDS = 'max_market_funds';
  strict private
    FBaseCurrency: String;
    FBaseMaxSize: Extended;
    FBaseMinSize: Extended;
    FMinMarketFunds,
    FMaxMarketFunds : Extended;
    FID: String;
    FQuoteCurrency: String;
    FQuoteIncrement: Extended;
  protected
    function GetBaseCurrency: String;
    function GetBaseMaxSize: Extended;
    function GetBaseMinSize: Extended;
    function GetID: String;
    function GetMaxMarket: Extended;
    function GetMinMarket: Extended;
    function GetQuoteCurrency: String;
    function GetQuoteIncrement: Extended;
    procedure SetBaseCurrency(Const AValue: String);
    procedure SetBaseMaxSize(Const AValue: Extended);
    procedure SetBaseMinSize(Const AValue: Extended);
    procedure SetID(Const AValue: String);
    procedure SetMaxMarket(const AValue: Extended);
    procedure SetMinMarket(const AValue: Extended);
    procedure SetQuoteCurrency(Const AValue: String);
    procedure SetQuoteIncrement(Const AValue: Extended);
  strict protected
    function GetEndpoint(Const AOperation: TRestOperation): String; override;
    function DoLoadFromJSON(Const AJSON: String;
      out Error: String): Boolean;override;
    function DoGetSupportedOperations: TRestOperations; override;
  public
    property ID : String read GetID write SetID;
    property BaseCurrency : String read GetBaseCurrency write SetBaseCurrency;
    property QuoteCurrency : String read GetQuoteCurrency write SetQuoteCurrency;
    property BaseMinSize : Extended read GetBaseMinSize write SetBaseMinSize; deprecated;
    property BaseMaxSize : Extended read GetBaseMaxSize write SetBaseMaxSize; deprecated;
    property QuoteIncrement : Extended read GetQuoteIncrement
      write SetQuoteIncrement;
    property MinMarketFunds : Extended read GetMinMarket write SetMinMarket;
    property MaxMarketFunds : Extended read GetMaxMarket write SetMaxMarket; deprecated;
  end;

  { TGDAXProductsImpl }

  TGDAXProductsImpl = class(TGDAXRestApi,IGDAXProducts)
  strict private
    FQuoteCurrency: String;
    FProducts: TGDAXProductList;
    function GetProducts: TGDAXProductList;
    function GetQuoteCurrency: String;
    procedure SetQuoteCurrency(Const AValue: String);
  strict protected
    function DoGetSupportedOperations: TRestOperations; override;
    function GetEndpoint(Const AOperation: TRestOperation): String; override;
    function DoLoadFromJSON(Const AJSON: String; out Error: String): Boolean;override;
  public
    property QuoteCurrency : String read GetQuoteCurrency write SetQuoteCurrency;
    property Products : TGDAXProductList read GetProducts;
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation
uses
  fpjson,
  jsonparser;

{ TGDAXProductsImpl }

function TGDAXProductsImpl.GetProducts: TGDAXProductList;
begin
  Result := FProducts;
end;

function TGDAXProductsImpl.GetQuoteCurrency: String;
begin
  Result := FQuoteCurrency;
end;

procedure TGDAXProductsImpl.SetQuoteCurrency(Const AValue: String);
begin
  FQuoteCurrency := AValue;
end;

function TGDAXProductsImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXProductsImpl.GetEndpoint(
  Const AOperation: TRestOperation): String;
begin
  Result := GDAX_END_API_PRODUCT;
end;

function TGDAXProductsImpl.DoLoadFromJSON(Const AJSON: String; out
  Error: String): Boolean;
var
  I : Integer;
  LJSON : TJSONArray;
  LProdJSON : TJSONObject;
  LProdCur : String;
  LProduct : IGDAXProduct;
begin
  Result := False;
  try
    LJSON := TJSONArray(GetJSON(AJSON));

    if not Assigned(LJSON) then
      raise Exception.Create(E_BADJSON);

    try
      //iterate returned array of products
      for I := 0 to Pred(LJSON.Count) do
      begin
        LProdJSON := TJSONObject(LJSON.Items[I]);

        //check to make sure we can parse this object
        if not Assigned(LProdJSON) then
        begin
          Error := Format(E_BADJSON_PROP,['product index:'+IntToStr(I)]);
          Exit;
        end;

        //we can filter for a particular quote currency, so check this here
        if not FQuoteCurrency.IsEmpty then
        begin
          LProdCur := LProdJSON.Get(TGDAXProductImpl.PROP_QUOTE_CUR);
          LProdCur := LProdCur.Trim.ToLower;

          //have a matching quote currency means this index is valid
          if LProdCur = FQuoteCurrency.Trim.ToLower then
          begin
            LProduct := TGDAXProductImpl.Create;

            if LProduct.LoadFromJSON(LProdJSON.AsJSON, Error) then
              FProducts.Add(LProduct);
          end;
        end
        //all products
        else
        begin
          LProduct := TGDAXProductImpl.Create;

          if LProduct.LoadFromJSON(LProdJSON.AsJson, Error) then
            FProducts.Add(LProduct);
        end;
      end;

    Result := True;
    finally
      LJSON.Free;
    end;
  except on E:Exception do
    Error := E.Message;
  end;
end;

constructor TGDAXProductsImpl.Create;
begin
  inherited Create;
  FProducts := TGDAXProductList.Create;
end;

destructor TGDAXProductsImpl.Destroy;
begin
  FProducts.Free;
  inherited Destroy;
end;

{ TGDAXProductImpl }

function TGDAXProductImpl.GetBaseCurrency: String;
begin
  Result := FBaseCurrency;
end;

function TGDAXProductImpl.GetBaseMaxSize: Extended;
begin
  Result := FBaseMaxSize;
end;

function TGDAXProductImpl.GetBaseMinSize: Extended;
begin
  Result := FBaseMinSize;
end;

function TGDAXProductImpl.GetID: String;
begin
  Result := FID;
end;

function TGDAXProductImpl.GetMaxMarket: Extended;
begin
  Result := FMaxMarketFunds;
end;

function TGDAXProductImpl.GetMinMarket: Extended;
begin
  Result := FMinMarketFunds;
end;

function TGDAXProductImpl.GetQuoteCurrency: String;
begin
  Result := FQuoteCurrency;
end;

function TGDAXProductImpl.GetQuoteIncrement: Extended;
begin
  Result := FQuoteIncrement;
end;

procedure TGDAXProductImpl.SetBaseCurrency(const AValue: String);
begin
  FBaseCurrency := AValue;
end;

procedure TGDAXProductImpl.SetBaseMaxSize(const AValue: Extended);
begin
  FBaseMaxSize := AValue;
end;

procedure TGDAXProductImpl.SetBaseMinSize(const AValue: Extended);
begin
  FBaseMinSize := AValue;
end;

procedure TGDAXProductImpl.SetID(const AValue: String);
begin
  FID := AValue;
end;

procedure TGDAXProductImpl.SetMaxMarket(const AValue: Extended);
begin
  FMaxMarketFunds := AValue;
end;

procedure TGDAXProductImpl.SetMinMarket(const AValue: Extended);
begin
  FMinMarketFunds := AValue;
end;

procedure TGDAXProductImpl.SetQuoteCurrency(const AValue: String);
begin
  FQuoteCurrency := AValue;
end;

procedure TGDAXProductImpl.SetQuoteIncrement(const AValue: Extended);
begin
  FQuoteIncrement := AValue;
end;

function TGDAXProductImpl.DoLoadFromJSON(const AJSON: String; out Error: String
  ): Boolean;
var
  LJSON : TJSONObject;
begin
  Result := False;
  try
    LJSON := TJSONObject(GetJSON(AJSON));

    if not Assigned(LJSON) then
      raise Exception.Create(E_BADJSON);

    try
      FID := LJSON.Get(PROP_ID);
      FBaseCurrency := LJSON.Get(PROP_BASE_CUR);

      if Assigned(LJSON.Find(PROP_BASE_MIN)) then
        FBaseMinSize := 0.00000001
      else
        FBaseMinSize := LJSON.Get(PROP_BASE_MIN);

      if Assigned(LJSON.Find(PROP_BASE_MAX)) then
        FBaseMaxSize := 99999999
      else
        FBaseMaxSize := LJSON.Get(PROP_BASE_MAX);

      FQuoteCurrency := LJSON.Get(PROP_QUOTE_CUR);
      FQuoteIncrement := LJSON.Get(PROP_QUOTE_INC);

      if Assigned(LJSON.Find(PROP_MIN_MARKET_FUNDS)) then
        FMinMarketFunds := LJSON.Get(PROP_MIN_MARKET_FUNDS);

      if Assigned(LJSON.Find(PROP_MAX_MARKET_FUNDS)) then
        FMaxMarketFunds := LJSON.Get(PROP_MAX_MARKET_FUNDS);

      Result := True;
    finally
      LJSON.Free;
    end;
  except on E:Exception do
    Error := E.Message;
  end;
end;

function TGDAXProductImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXProductImpl.GetEndpoint(const AOperation: TRestOperation): String;
begin
  Result := Format(GDAX_END_API_PRODUCTS,[FID]);
end;

end.

