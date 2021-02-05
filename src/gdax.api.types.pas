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

unit gdax.api.types;

{$i gdax.inc}

interface

uses
  Classes,SysUtils,gdax.api.consts,
  {$IFDEF FPC}
  fgl
  {$ELSE}
  System.Collections.Generics
  {$ENDIF};
type

  //forward
  IGDAXTime = interface;

  { IGDAXAuthenticator }

  IGDAXAuthenticator = interface
    ['{0AEA765A-8393-4B9B-9749-B180939ACA72}']
    //property methods
    function GetKey: String;
    function GetMode: TGDAXApi;
    function GetPassphrase: String;
    function GetSecret: String;
    function GetTime: IGDAXTime;
    function GetUseLocalTime: Boolean;
    procedure SetKey(Const AValue: String);
    procedure SetMode(Const AValue: TGDAXApi);
    procedure SetPassphrase(Const AValue: String);
    procedure SetSecret(Const AValue: String);
    procedure SetUseLocalTime(Const AValue: Boolean);
    //properties
    property Key: String read GetKey write SetKey;
    property Secret: String read GetSecret write SetSecret;
    property Passphrase: String read GetPassphrase write SetPassphrase;
    property UseLocalTime: Boolean read GetUseLocalTime write SetUseLocalTime;
    property Mode: TGDAXApi read GetMode write SetMode;
    //methods
    procedure BuildHeaders(Const AOutput:TStrings;Const ASignature:String;
      Const AEpoch:Integer);
    function GenerateAccessSignature(Const AOperation:TRestOperation;
      Const ARequestPath:String;Out Epoch:Integer;Const ARequestBody:String=''):String;
  end;

  TGDAXPageDirection = (pdBefore,pdAfter);

  TPageLimit = 0..100;

  { IGDAXPaged }

  IGDAXPaged = interface
    ['{6A335FAA-FF81-4DD4-8444-8B0A121651B8}']
    //property methods
    function GetLastAfterID: Integer;
    function GetLastBeforeID: Integer;
    //properties
    property LastBeforeID:Integer read GetLastBeforeID;
    property LastAfterID:Integer read GetLastAfterID;
    //methods
    function Move(Const ADirection:TGDAXPageDirection;Out Error:String;
      Const ALastBeforeID,ALastAfterID:Integer;
      Const ALimit:TPageLimit=0):Boolean;overload;
    function Move(Const ADirection:TGDAXPageDirection;Out Error:String;
      Const ALimit:TPageLimit=0):Boolean;overload;
    function Move(Const ADirection:TGDAXPageDirection;
      Const ALimit:TPageLimit=0):Boolean;overload;
  end;

  { IGDAXRestAPI }

  IGDAXRestAPI = interface
    ['{08E2B6BA-3FF0-4FC8-91E2-D180C57997A6}']
    //property methods
    function GetAuthenticator: IGDAXAuthenticator;
    function GetPostBody: String;
    function GetSupportedOperations: TRestOperations;
    procedure SetAuthenticator(Const AValue: IGDAXAuthenticator);
    //properties
    property SupportedOperations: TRestOperations read GetSupportedOperations;
    property Authenticator: IGDAXAuthenticator read GetAuthenticator write SetAuthenticator;
    property PostBody : String read GetPostBody;
    //methods
    function Post(Out Content:String;Out Error:String):Boolean;
    function Get(Out Content:String;Out Error:String):Boolean;
    function Delete(Out Content:String;Out Error:String):Boolean;
    function LoadFromJSON(Const AJSON:String;Out Error:String):Boolean;
  end;

  { IGDAXTime }

  IGDAXTime = interface(IGDAXRestAPI)
    ['{5464CEE5-520D-44FF-B3A5-F119D160FB29}']
    //property methods
    function GetEpoch: Extended;
    function GetISO: String;
    procedure SetEpoch(Const AValue: Extended);
    procedure SetISO(Const AValue: String);
    //properties
    property ISO: String read GetISO write SetISO;
    property Epoch: Extended read GetEpoch write SetEpoch;
  end;

  { TLedgerEntry }

  TLedgerEntry = packed record
  public
    const
      PROP_ID = 'id';
      PROP_CREATE = 'created_at';
      PROP_AMOUNT = 'amount';
      PROP_BALANCE = 'balance';
      PROP_TYPE = 'type';
      PROP_DETAILS = 'details';
    type

      { TDetails }

      TDetails = packed record
      private
        FOrderID: String;
        FProductID: String;
        FTradeID: String;
      public
        const
          PROP_ORDER_ID = 'order_id';
          PROP_TRADE_ID = 'trade_id';
          PROP_PROD_ID = 'product_id';
      public
        property OrderID : String read FOrderID write FOrderID;
        property TradeID : String read FTradeID write FTradeID;
        property ProductID : String read FProductID write FProductID;
        constructor Create(Const AJSON:String);
      end;
  private
    FAmount: Extended;
    FBalance: Extended;
    FCreated: TDateTime;
    FCreatedAt: TDateTime;
    FDetails: TDetails;
    FID: String;
    FLedgerType: TLedgerType;
  public
    property ID : String read FID write FID;
    property CreatedAt : TDateTime read FCreatedAt write FCreated;
    property Amount : Extended read FAmount write FAmount;
    property Balance : Extended read FBalance write FBalance;
    property LedgerType : TLedgerType read FLedgerType write FLedgerType;
    property Details : TDetails read FDetails write FDetails;
    constructor Create(Const AJSON:String);
  end;

  TLedgerEntryArray = array of TLedgerEntry;

  { IGDAXAccountLedger }

  IGDAXAccountLedger = interface(IGDAXRestAPI)
    ['{FA730CEB-6508-4613-BD65-C633217E677F}']
    //property methods
    function GetAcctID: String;
    function GetCount: Cardinal;
    function GetEntries: TLedgerEntryArray;
    function GetPaged: IGDAXPaged;
    procedure SetAcctID(Const AValue: String);
    //properties
    property AcctID: String read GetAcctID write SetAcctID;
    property Paged: IGDAXPaged read GetPaged;
    property Entries: TLedgerEntryArray read GetEntries;
    property Count: Cardinal read GetCount;
    //methods
    procedure ClearEntries;
  end;

  { IGDAXAccount }

  IGDAXAccount = interface(IGDAXRestAPI)
    ['{01D88E69-F15F-4603-914F-4C87270B2165}']
    //property methods
    function GetAcctID: String;
    function GetAvailable: Extended;
    function GetBalance: Extended;
    function GetCurrency: String;
    function GetHolds: Extended;
    procedure SetAcctID(Const AValue: String);
    procedure SetAvailable(Const AValue: Extended);
    procedure SetBalance(Const AValue: Extended);
    procedure SetCurrency(Const AValue: String);
    procedure SetHolds(Const AValue: Extended);
    //properties
    property AcctID: String read GetAcctID write SetAcctID;
    property Currency: String read GetCurrency write SetCurrency;
    property Balance: Extended read GetBalance write SetBalance;
    property Holds: Extended read GetHolds write SetHolds;
    property Available: Extended read GetAvailable write SetAvailable;
  end;

  { TGDAXAccountList }

  TGDAXAccountList =
    {$IFDEF FPC}
    TFPGInterfacedObjectList<IGDAXAccount>
    {$ELSE}
    TInterfaceList<IGDAXAccount>
    {$ENDIF};

  { IGDAXAccounts }

  IGDAXAccounts = interface(IGDAXRestAPI)
    ['{C5C55A92-9541-4E0A-8593-3F4B8E8A85FF}']
    //property methods
    function GetAccounts: TGDAXAccountList;
    //properties
    property Accounts : TGDAXAccountList read GetAccounts;
  end;

  { TBookEntry }

  TBookEntry = class(TObject)
  private
    FPrice: Extended;
    FSize: Extended;
    FSide: TOrderSide;
    function GetPrice: Extended;
    function GetSize: Extended;
    procedure SetPrice(Const Value: Extended);
    procedure SetSize(Const Value: Extended);
    function GetSide: TOrderSide;
    procedure SetSide(Const Value: TOrderSide);
  protected
  public
    property Price: Extended read GetPrice write SetPrice;
    property Size: Extended read GetSize write SetSize;
    property Side: TOrderSide read GetSide write SetSide;
    constructor Create(Const APrice:Single;Const ASize:Extended);overload;
  end;

  { TAggregatedEntry }

  TAggregatedEntry = class(TBookEntry)
  private
    FNumberOrders: Cardinal;
    function GetNumberOrders: Integer;
    procedure SetNumberOrders(Const Value: Integer);
  public
    property NumberOrders: Integer read GetNumberOrders write SetNumberOrders;
    constructor Create(Const APrice:Extended;Const ASize:Extended;
      Const ANumberOrders:Cardinal);overload;
  end;

  { TFullEntry }

  TFullEntry = class(TBookEntry)
  private
    FOrderID: String;
    function GetOrderID: String;
    procedure SetOrderID(Const Value: String);
  public
    property OrderID: String read GetOrderID write SetOrderID;
    constructor Create(Const APrice:Single;Const ASize:Extended;Const AOrderID:String);overload;
  end;

  { IGDAXProduct }

  IGDAXProduct = interface(IGDAXRestAPI)
    ['{3750A665-E21B-4254-8B24-9615356A487F}']
    //property methods
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
    //properties
    property ID : String read GetID write SetID;
    property BaseCurrency : String read GetBaseCurrency write SetBaseCurrency;
    property QuoteCurrency : String read GetQuoteCurrency write SetQuoteCurrency;
    property BaseMinSize : Extended read GetBaseMinSize write SetBaseMinSize;
    property BaseMaxSize : Extended read GetBaseMaxSize write SetBaseMaxSize;
    property QuoteIncrement : Extended read GetQuoteIncrement
      write SetQuoteIncrement;
    property MinMarketFunds : Extended read GetMinMarket write SetMinMarket;
    property MaxMarketFunds : Extended read GetMaxMarket write SetMaxMarket;
  end;

  { TGDAXProductList }

  TGDAXProductList =
    {$IFDEF FPC}
    TFPGInterfacedObjectList<IGDAXProduct>
    {$ELSE}
    TInterfacedList<IGDAXProduct>
    {$ENDIF};

  { IGDAXProducts }

  IGDAXProducts = interface(IGDAXRestAPI)
    ['{B64F0413-DD15-4488-AB8E-0DE8E4BEC936}']
    //property methods
    function GetProducts: TGDAXProductList;
    function GetQuoteCurrency: String;
    procedure SetQuoteCurrency(Const AValue: String);
    //properties
    property QuoteCurrency : String read GetQuoteCurrency write SetQuoteCurrency;
    property Products : TGDAXProductList read GetProducts;
  end;

  TGDAXBookEntryList =
    {$IFDEF FPC}
    TFPGObjectList<TBookEntry>
    {$ELSE}
    TObjectList<TBookEntry>
    {$ENDIF};

  { IGDAXBook }

  IGDAXBook = interface(IGDAXRestAPI)
    ['{CDC9A578-AF7B-4D94-B8AC-0D876059ACCF}']
    //property methods
    function GetAskList: TGDAXBookEntryList;
    function GetAskSize: Single;
    function GetBidList: TGDAXBookEntryList;
    function GetBidSize: Single;
    function GetLevel: TGDAXBookLevel;
    function GetMarketType: TMarketType;
    function GetProduct: IGDAXProduct;
    procedure SetLevel(Const AValue: TGDAXBookLevel);
    procedure SetProduct(Const AValue: IGDAXProduct);
    //properties
    property Level: TGDAXBookLevel read GetLevel write SetLevel;
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property AskList: TGDAXBookEntryList read GetAskList;
    property BidList: TGDAXBookEntryList read GetBidList;
    property MarketType: TMarketType read GetMarketType;
    property AskSize: Single read GetAskSize;
    property BidSize: Single read GetBidSize;
  end;

  { TCandleBucket }

  TCandleBucket = record
  private
    FTime: Extended;
    FLow: Extended;
    FHigh: Extended;
    FOpen: Extended;
    FClose: Extended;
    FVolume: Extended;
    function GetTime: Extended;
    procedure SetTime(Const Value: Extended);
    function GetLow: Extended;
    procedure SetLow(Const Value: Extended);
    function GetHigh: Extended;
    procedure SetHigh(Const Value: Extended);
    function GetOpen: Extended;
    procedure SetOpen(Const Value: Extended);
    function GetClose: Extended;
    procedure SetClose(Const Value: Extended);
    function GetVolume: Extended;
    procedure SetVolume(Const Value: Extended);
  public
    property Time: Extended read GetTime write SetTime;
    property Low: Extended read GetLow write SetLow;
    property High: Extended read GetHigh write SetHigh;
    property Open: Extended read GetOpen write SetOpen;
    property Close: Extended read GetClose write SetClose;
    property Volume: Extended read GetVolume write SetVolume;
    constructor create(Const ATime:Extended;ALow,AHigh,AOpen,AClose:Extended;
      AVolume:Extended);
    class operator Equal(Const A,B:TCandleBucket):Boolean;
  end;

  TGDAXCandleBucketList =
    {$IFDEF FPC}
    TFPGList<TCandleBucket>
    {$ELSE}
    TList<TCandleBucket>
    {$ENDIF};

  { IGDAXCandles }

  IGDAXCandles = interface(IGDAXRestAPI)
    ['{7CEBB745-B371-4C0F-A598-B22B5F8AA97D}']
    //property methods
    function GetEndTime: TDatetime;
    function GetGranularity: Cardinal;
    function GetList: TGDAXCandleBucketList;
    function GetProduct: IGDAXProduct;
    function GetStartTime: TDatetime;
    procedure SetEndTime(Const AValue: TDatetime);
    procedure SetGranularity(Const AValue: Cardinal);
    procedure SetProduct(Const AValue: IGDAXProduct);
    procedure SetStartTime(Const AValue: TDatetime);
    //properties
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property StartTime: TDatetime read GetStartTime write SetStartTime;
    property Granularity: Cardinal read GetGranularity write SetGranularity;
    property EndTime: TDatetime read GetEndTime write SetEndTime;
    property List: TGDAXCandleBucketList read GetList;
  end;

  { TFillEntry }

  TFillEntry = packed record
  private
    FCreatedAt: TDateTime;
    FFee: Extended;
    FLiquidity: Char;
    FOrderID: String;
    FPrice: Extended;
    FProductID: String;
    FSettled: Boolean;
    FSide: TOrderSide;
    FSize: Extended;
    FTradeID: Cardinal;
  public
    const
      PROP_ID = 'trade_id';
      PROP_PROD = 'product_id';
      PROP_PRICE = 'price';
      PROP_SIZE = 'size';
      PROP_ORDER = 'order_id';
      PROP_CREATE = 'created_at';
      PROP_LIQUID = 'liquidity';
      PROP_FEE = 'fee';
      PROP_SETTLED = 'settled';
      PROP_SIDE = 'side';
  public
    property TradeID: Cardinal read FTradeID write FTradeID;
    property ProductID: String read FProductID write FProductID;
    property Price: Extended read FPrice write FPrice;
    property Size: Extended read FSize write FSize;
    property OrderID: String read FOrderID write FOrderID;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property Liquidity: Char read FLiquidity write FLiquidity;
    property Fee: Extended read FFee write FFee;
    property Settled: Boolean read FSettled write FSettled;
    property Side: TOrderSide read FSide write FSide;
    constructor Create(Const AJSON:String);
  end;

  TFillEntryArray = array of TFillEntry;

  { IGDAXFills }

  IGDAXFills = interface(IGDAXRestAPI)
    ['{2B6DDB92-9716-4ACB-932C-4D614614739D}']
    //property methods
    function GetCount: Cardinal;
    function GetPaged: IGDAXPaged;
    function GetProductID: String;
    function GetOrderID: String;
    function GetEntries: TFillEntryArray;
    function GetTotalFees(Const ASides: TOrderSides): Extended;
    function GetTotalPrice(Const ASides: TOrderSides): Extended;
    function GetTotalSize(Const ASides: TOrderSides): Extended;
    procedure SetOrderID(Const AValue: String);
    procedure SetProductID(Const AValue: String);
    //properties
    property Paged: IGDAXPaged read GetPaged;
    property Entries: TFillEntryArray read GetEntries;
    property Count: Cardinal read GetCount;
    property OrderID: String read GetOrderID write SetOrderID;
    property ProductID: String read GetProductID write SetProductID;
    property TotalSize[Const ASides:TOrderSides]: Extended read GetTotalSize;
    property TotalPrice[Const ASides:TOrderSides]: Extended read GetTotalPrice;
    property TotalFees[Const ASides:TOrderSides]: Extended read GetTotalFees;
    //methods
    procedure ClearEntries;
  end;

  { IGDAXTicker }

  IGDAXTicker = interface(IGDAXRestAPI)
    ['{945801E3-05EC-423E-8036-0013F5D1AA02}']
    //property methods
    function GetAsk: Extended;
    function GetBid: Extended;
    function GetPrice: Extended;
    function GetProduct: IGDAXProduct;
    function GetSize: Extended;
    function GetTime: TDateTime;
    function GetVolume: Extended;
    procedure SetAsk(Const AValue: Extended);
    procedure SetBid(Const AValue: Extended);
    procedure SetPrice(Const AValue: Extended);
    procedure SetProduct(Const AValue: IGDAXProduct);
    procedure SetSize(Const AValue: Extended);
    procedure SetTime(Const AValue: TDateTime);
    procedure SetVolume(Const AValue: Extended);
    //properties
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property Price: Extended read GetPrice write SetPrice;
    property Size: Extended read GetSize write SetSize;
    property Bid: Extended read GetBid write SetBid;
    property Ask: Extended read GetAsk write SetAsk;
    property Volume: Extended read GetVolume write SetVolume;
    property Time: TDateTime read GetTime write SetTime;
  end;

  { IGDAXOrder }

  IGDAXOrder = interface(IGDAXRestAPI)
    ['{41D2CFC9-DD1B-4B4C-A187-73BC96EDB2B2}']
    //property methods
    function GetCreatedAt: TDateTime;
    function GetExecutedValue: Extended;
    function GetFilledSized: Extended;
    function GetFillFees: Extended;
    function GetID: String;
    function GetOrderStatus: TOrderStatus;
    function GetOrderType: TOrderType;
    function GetPostOnly: Boolean;
    function GetPrice: Extended;
    function GetProduct: IGDAXProduct;
    function GetRejectReason: String;
    function GetSettled: Boolean;
    function GetSide: TOrderSide;
    function GetSize: Extended;
    function GetStopOrder: Boolean;
    procedure SetCreatedAt(Const AValue: TDateTime);
    procedure SetExecutedValue(Const AValue: Extended);
    procedure SetFilledSized(Const AValue: Extended);
    procedure SetFillFees(Const AValue: Extended);
    procedure SetID(Const AValue: String);
    procedure SetOrderStatus(Const AValue: TOrderStatus);
    procedure SetOrderType(Const AValue: TOrderType);
    procedure SetPostOnly(Const AValue: Boolean);
    procedure SetPrice(Const AValue: Extended);
    procedure SetProduct(Const AValue: IGDAXProduct);
    procedure SetRejectReason(Const AValue: String);
    procedure SetSettled(Const AValue: Boolean);
    procedure SetSide(Const AValue: TOrderSide);
    procedure SetSize(Const AValue: Extended);
    procedure SetStopOrder(Const AValue: Boolean);
    //properties
    property ID: String read GetID write SetID;
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property OrderType: TOrderType read GetOrderType write SetOrderType;
    property OrderStatus: TOrderStatus read GetOrderStatus write SetOrderStatus;
    property Side: TOrderSide read GetSide write SetSide;
    property PostOnly: Boolean read GetPostOnly write SetPostOnly;
    property StopOrder: Boolean read GetStopOrder write SetStopOrder;
    property Settled: Boolean read GetSettled write SetSettled;
    property Size: Extended read GetSize write SetSize;
    property Price: Extended read GetPrice write SetPrice;
    property FillFees: Extended read GetFillFees write SetFillFees;
    property FilledSized: Extended read GetFilledSized write SetFilledSized;
    property ExecutedValue: Extended read GetExecutedValue write SetExecutedValue;
    property RejectReason: String read GetRejectReason write SetRejectReason;
    property CreatedAt: TDateTime read GetCreatedAt write SetCreatedAt;
  end;

  TGDAXOrderList =
    {$IFDEF FPC}
      TFPGInterfacedObjectList<IGDAXOrder>
    {$ELSE}
      TInterfaceList<IGDAXOrder>
    {$ENDIF};

  { IGDAXOrders }

  IGDAXOrders = interface(IGDAXRestAPI)
    ['{02EB5136-81FA-46EE-AC3A-0665EA009C6B}']
    //property methods
    function GetPaged: IGDAXPaged;
    function GetProduct: IGDAXProduct;
    function GetStatuses: TOrderStatuses;
    procedure SetProduct(Const AValue: IGDAXProduct);
    procedure SetStatuses(Const AValue: TOrderStatuses);
    function GetOrders: TGDAXOrderList;
    //properties
    property Orders: TGDAXOrderList read GetOrders;
    property Statuses: TOrderStatuses read GetStatuses write SetStatuses;
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property Paged: IGDAXPaged read GetPaged;
  end;

  { TCurrency }

  TCurrency = packed record
  public
    const
      PROP_ID = 'id';
      PROP_NAME = 'name';
      PROP_MIN_SIZE = 'min_size';
      PROP_STATUS = 'status';
      PROP_MESSAGE = 'message';
  strict private
    FID: String;
    FMinSize: Extended;
    FName: String;
    FStatus: String;
    FMessage: String;
  public
    property ID : String read FID write FID;
    property Name : String read FName write FName;
    property MinSize : Extended read FMinSize write FMinSize;
    property Status : String read FStatus write FStatus;
    property Message : String read FMessage write FMessage;
    constructor Create(Const AJSON:String);
  end;

  TCurrencyArray = array of TCurrency;

  { IGDAXCurrencies }

  IGDAXCurrencies = interface(IGDAXRestAPI)
    ['{9C3A7952-31F7-4064-AE64-AD1AB079CBE6}']
    //property methods
    function GetCount: Cardinal;
    function GetCurrencies: TCurrencyArray;
    //properties
    property Currencies : TCurrencyArray read GetCurrencies;
    property Count : Cardinal read GetCount;
  end;

implementation
uses
  fpjson,
  jsonparser,
  fpIndexer;

{ TCurrency }

constructor TCurrency.Create(Const AJSON: String);
var
  LJSON : TJSONObject;
begin
  LJSON := TJSONObject(GetJSON(AJSON));

  if not Assigned(LJSON) then
    raise Exception.Create(E_BADJSON);

  try
    FID := LJSON.Get(PROP_ID);
    FMinSize := LJSON.Get(PROP_MIN_SIZE);
    FName := LJSON.Get(PROP_NAME);
    FStatus := LJSON.Get(PROP_STATUS);
    FMessage := '';

    if Assigned(LJSON.Find(PROP_MESSAGE)) then
      FMessage := LJSON.Get(PROP_MESSAGE);
  finally
    LJSON.Free;
  end;
end;

{ TFillEntry }

constructor TFillEntry.Create(Const AJSON: String);
var
  LJSON : TJSONObject;
begin
  LJSON := TJSONObject(GetJSON(AJSON));

  if not Assigned(LJSON) then
    raise Exception.Create(E_BADJSON);

  try
    FTradeID := LJSON.Get(PROP_ID);
    FProductID := LJSON.Get(PROP_PROD);
    FPrice := LJSON.Get(PROP_PRICE);
    FSize := LJSON.Get(PROP_SIZE);
    FOrderID := LJSON.Get(PROP_ORDER);
    FCreatedAt := fpIndexer.ISO8601ToDate(LJSON.Get(PROP_CREATE));
    FLiquidity := LJSON.Get(PROP_LIQUID);
    FFee := LJSON.Get(PROP_FEE);
    FSettled := LJSON.Get(PROP_SETTLED);
    FSide := StringToOrderSide(LJSON.Get(PROP_SIDE));
  finally
    LJSON.Free;
  end;
end;

{ TLedgerEntry.TDetails }

constructor TLedgerEntry.TDetails.Create(Const AJSON: String);
var
  LJSON : TJSONObject;
begin
  LJSON := TJSONObject(GetJSON(AJSON));

  if not Assigned(LJSON) then
    raise Exception.Create(E_BADJSON);

  try
    FOrderID := LJSON.Get(PROP_ORDER_ID);
    FTradeID := LJSON.Get(PROP_TRADE_ID);
    FProductID := LJSON.Get(PROP_PROD_ID);

  finally
    LJSON.Free;
  end;
end;

{ TLedgerEntry }

constructor TLedgerEntry.Create(Const AJSON: String);
var
  LJSON,
  LDetails : TJSONObject;
begin
  LJSON := TJSONObject(GetJSON(AJSON));

  if not Assigned(LJSON) then
    raise Exception.Create(E_BADJSON);

  try
    FID := LJSON.Get(PROP_ID);
    FCreatedAt := fpIndexer.ISO8601ToDate(LJSON.Get(PROP_CREATE));
    FAmount := LJSON.Get(PROP_AMOUNT);
    FBalance := LJSON.Get(PROP_BALANCE);
    FLedgerType := StringToLedgerType(LJSON.Get(PROP_TYPE));

    if not Assigned(LJSON.Find(PROP_DETAILS)) then
      raise Exception.Create(Format(E_INVALID,['details json','json object']));

    LDetails := LJSON.Objects[PROP_DETAILS];

    //deserialize details object
    FDetails := TDetails.Create(LDetails.AsJSON);
  finally
    LJSON.Free;
  end;
end;

{ TBookEntry }

constructor TBookEntry.Create(Const APrice: Single; Const ASize: Extended);
begin
  FPrice := APrice;
  FSize := ASize;
end;

function TBookEntry.GetPrice: Extended;
begin
  Result := FPrice;
end;

function TBookEntry.GetSide: TOrderSide;
begin
  Result := FSide;
end;

function TBookEntry.GetSize: Extended;
begin
  Result := FSize;
end;

procedure TBookEntry.SetPrice(Const Value: Extended);
begin
  FPrice := Value;
end;

procedure TBookEntry.SetSide(Const Value: TOrderSide);
begin
  FSide := Value;
end;

procedure TBookEntry.SetSize(Const Value: Extended);
begin
  FSize := Value;
end;

{ TAggregatedEntry }

constructor TAggregatedEntry.Create(Const APrice: Extended; Const ASize: Extended;
  Const ANumberOrders: Cardinal);
begin
  inherited create(APrice,ASize);
  FNumberOrders := ANumberOrders;
end;

function TAggregatedEntry.GetNumberOrders: Integer;
begin
  Result := FNumberOrders;
end;

procedure TAggregatedEntry.SetNumberOrders(Const Value: Integer);
begin
  FNumberOrders := Value;
end;

{ TFullEntry }

constructor TFullEntry.Create(Const APrice: Single; Const ASize: Extended;
  Const AOrderID: String);
begin
  inherited create(APrice,ASize);
  FOrderID := AOrderID;
end;

function TFullEntry.GetOrderID: String;
begin
  Result := FOrderID;
end;

procedure TFullEntry.SetOrderID(Const Value: String);
begin
  FOrderID := Value;
end;

{ TCandleBucket }

constructor TCandleBucket.create(Const ATime: Extended; ALow, AHigh, AOpen,
 AClose: Extended; AVolume: Extended);
begin
 Self.FTime := ATime;
 Self.FLow := ALow;
 Self.FHigh := AHigh;
 Self.FOpen := AOpen;
 Self.FClose := AClose;
 Self.FVolume := AVolume;
end;

class operator TCandleBucket.Equal(Const A, B: TCandleBucket): Boolean;
begin
  Result := A.Time=B.Time;
end;

function TCandleBucket.GetClose: Extended;
begin
 Result := FClose;
end;

function TCandleBucket.GetHigh: Extended;
begin
 Result := FHigh;
end;

function TCandleBucket.GetLow: Extended;
begin
 Result := FLow;
end;

function TCandleBucket.GetOpen: Extended;
begin
 Result := FOpen;
end;

function TCandleBucket.GetTime: Extended;
begin
 Result := FTime;
end;

function TCandleBucket.GetVolume: Extended;
begin
 Result := FVolume;
end;

procedure TCandleBucket.SetClose(Const Value: Extended);
begin
 FClose := Value;
end;

procedure TCandleBucket.SetHigh(Const Value: Extended);
begin
 FHigh := Value;
end;

procedure TCandleBucket.SetLow(Const Value: Extended);
begin
 FLow := Value;
end;

procedure TCandleBucket.SetOpen(Const Value: Extended);
begin
  FOpen := Value;
end;

procedure TCandleBucket.SetTime(Const Value: Extended);
begin
 FTime := Value;
end;

procedure TCandleBucket.SetVolume(Const Value: Extended);
begin
 FVolume := Value;
end;
end.

