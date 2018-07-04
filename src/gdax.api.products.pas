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
  strict private
    FBaseCurrency: String;
    FBaseMaxSize: Extended;
    FBaseMinSize: Extended;
    FID: String;
    FQuoteCurrency: String;
    FQuoteIncrement: Extended;
    function GetBaseCurrency: String;
    function GetBaseMaxSize: Extended;
    function GetBaseMinSize: Extended;
    function GetID: String;
    function GetQuoteCurrency: String;
    function GetQuoteIncrement: Extended;
    procedure SetBaseCurrency(AValue: String);
    procedure SetBaseMaxSize(AValue: Extended);
    procedure SetBaseMinSize(AValue: Extended);
    procedure SetID(AValue: String);
    procedure SetQuoteCurrency(AValue: String);
    procedure SetQuoteIncrement(AValue: Extended);
  strict protected
    function GetEndpoint(const AOperation: TRestOperation): String; override;
    function DoLoadFromJSON(const AJSON: String;
      out Error: String): Boolean;override;
    function DoGetSupportedOperations: TRestOperations; override;
  public
    property ID : String read GetID write SetID;
    property BaseCurrency : String read GetBaseCurrency write SetBaseCurrency;
    property QuoteCurrency : String read GetQuoteCurrency write SetQuoteCurrency;
    property BaseMinSize : Extended read GetBaseMinSize write SetBaseMinSize;
    property BaseMaxSize : Extended read GetBaseMaxSize write SetBaseMaxSize;
    property QuoteIncrement : Extended read GetQuoteIncrement
      write SetQuoteIncrement;
  end;

  { TGDAXProductsImpl }

  TGDAXProductsImpl = class(TGDAXRestApi,IGDAXProducts)
  strict private
    FQuoteCurrency: String;
    FProducts: TGDAXProductList;
    function GetProducts: TGDAXProductList;
    function GetQuoteCurrency: String;
    procedure SetQuoteCurrency(AValue: String);
  strict protected
    function DoGetSupportedOperations: TRestOperations; override;
    function GetEndpoint(const AOperation: TRestOperation): String; override;
    function DoLoadFromJSON(const AJSON: String; out Error: String): Boolean;override;
  public
    property QuoteCurrency : String read GetQuoteCurrency write SetQuoteCurrency;
    property Products : TGDAXProductList read GetProducts;
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation
uses
  SynCrossPlatformJSON;

{ TGDAXProductsImpl }

function TGDAXProductsImpl.GetProducts: TGDAXProductList;
begin
  Result:=FProducts;
end;

function TGDAXProductsImpl.GetQuoteCurrency: String;
begin
  Result:=FQuoteCurrency;
end;

procedure TGDAXProductsImpl.SetQuoteCurrency(AValue: String);
begin
  FQuoteCurrency:=AValue;
end;

function TGDAXProductsImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXProductsImpl.GetEndpoint(
  const AOperation: TRestOperation): String;
begin
  Result:=GDAX_END_API_PRODUCT;
end;

function TGDAXProductsImpl.DoLoadFromJSON(const AJSON: String; out
  Error: String): Boolean;
var
  I:Integer;
  LJSON:TJSONVariantData;
  LProdJSON:TJSONVariantData;
  LProdCur:String;
  LProduct:IGDAXProduct;
begin
  Result:=False;
  try
    if not LJSON.FromJSON(AJSON) then
    begin
      Error:=E_BADJSON;
      Exit;
    end;
    //iterate returned array of products
    for I:=0 to Pred(LJSON.Count) do
    begin
      //check to make sure we can parse this object
      if not LProdJSON.FromJSON(LJSON.Item[I]) then
      begin
        Error:=Format(E_BADJSON_PROP,['product index:'+IntToStr(I)]);
        Exit;
      end;
      //we can filter for a particular quote currency, so check this here
      if not FQuoteCurrency.IsEmpty then
      begin
        LProdCur:=LProdJSON.Value[TGDAXProductImpl.PROP_QUOTE_CUR];
        LProdCur:=LProdCur.Trim.ToLower;
        //have a matching quote currency means this index is valid
        if LProdCur = FQuoteCurrency.Trim.ToLower then
        begin
          LProduct:=TGDAXProductImpl.Create;
          if LProduct.LoadFromJSON(LProdJSON.ToJSON,Error) then
            FProducts.Add(LProduct);
        end;
      end
      //all products
      else
      begin
        LProduct:=TGDAXProductImpl.Create;
        if LProduct.LoadFromJSON(LProdJSON.ToJSON,Error) then
          FProducts.Add(LProduct);
      end;
    end;
    Result:=True;
  except on E:Exception do
    Error:=E.Message;
  end;
end;

constructor TGDAXProductsImpl.Create;
begin
  inherited Create;
  FProducts:=TGDAXProductList.Create;
end;

destructor TGDAXProductsImpl.Destroy;
begin
  FProducts.Free;
  inherited Destroy;
end;

{ TGDAXProductImpl }

function TGDAXProductImpl.GetBaseCurrency: String;
begin
  Result:=FBaseCurrency;
end;

function TGDAXProductImpl.GetBaseMaxSize: Extended;
begin
  Result:=FBaseMaxSize;
end;

function TGDAXProductImpl.GetBaseMinSize: Extended;
begin
  Result:=FBaseMinSize;
end;

function TGDAXProductImpl.GetID: String;
begin
  Result:=FID;
end;

function TGDAXProductImpl.GetQuoteCurrency: String;
begin
  Result:=FQuoteCurrency;
end;

function TGDAXProductImpl.GetQuoteIncrement: Extended;
begin
  Result:=FQuoteIncrement;
end;

procedure TGDAXProductImpl.SetBaseCurrency(AValue: String);
begin
  FBaseCurrency:=AValue;
end;

procedure TGDAXProductImpl.SetBaseMaxSize(AValue: Extended);
begin
  FBaseMaxSize:=AValue;
end;

procedure TGDAXProductImpl.SetBaseMinSize(AValue: Extended);
begin
  FBaseMinSize:=AValue;
end;

procedure TGDAXProductImpl.SetID(AValue: String);
begin
  FID:=AValue;
end;

procedure TGDAXProductImpl.SetQuoteCurrency(AValue: String);
begin
  FQuoteCurrency:=AValue;
end;

procedure TGDAXProductImpl.SetQuoteIncrement(AValue: Extended);
begin
  FQuoteIncrement:=AValue;
end;

function TGDAXProductImpl.DoLoadFromJSON(const AJSON: String; out
  Error: String): Boolean;
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
    FID:=LJSON.Value[PROP_ID];
    FBaseCurrency:=LJSON.Value[PROP_BASE_CUR];
    FBaseMinSize:=LJSON.Value[PROP_BASE_MIN];
    FBaseMaxSize:=LJSON.Value[PROP_BASE_MAX];
    FQuoteCurrency:=LJSON.Value[PROP_QUOTE_CUR];
    FQuoteIncrement:=LJSON.Value[PROP_QUOTE_INC];
    Result:=True;
  except on E:Exception do
    Error:=E.Message;
  end;
end;

function TGDAXProductImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXProductImpl.GetEndpoint(const AOperation: TRestOperation): String;
begin
  Result:=Format(GDAX_END_API_PRODUCTS,[FID]);
end;

end.

