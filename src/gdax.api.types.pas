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
    procedure SetKey(AValue: String);
    procedure SetMode(AValue: TGDAXApi);
    procedure SetPassphrase(AValue: String);
    procedure SetSecret(AValue: String);
    procedure SetUseLocalTime(AValue: Boolean);
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
    function GetSupportedOperations: TRestOperations;
    procedure SetAuthenticator(AValue: IGDAXAuthenticator);
    //properties
    property SupportedOperations: TRestOperations read GetSupportedOperations;
    property Authenticator: IGDAXAuthenticator read GetAuthenticator write SetAuthenticator;
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
    procedure SetEpoch(AValue: Extended);
    procedure SetISO(AValue: String);
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
    procedure SetAcctID(AValue: String);
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
    procedure SetAcctID(const AValue: String);
    procedure SetAvailable(const AValue: Extended);
    procedure SetBalance(const AValue: Extended);
    procedure SetCurrency(const AValue: String);
    procedure SetHolds(const AValue: Extended);
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
    FPrice: Single;
    FSize: Extended;
    FSide: TOrderSide;
    function GetPrice: Single;
    function GetSize: Extended;
    procedure SetPrice(const Value: Single);
    procedure SetSize(const Value: Extended);
    function GetSide: TOrderSide;
    procedure SetSide(const Value: TOrderSide);
  protected
  public
    property Price: Single read GetPrice write SetPrice;
    property Size: Extended read GetSize write SetSize;
    property Side: TOrderSide read GetSide write SetSide;
    constructor Create(Const APrice:Single;Const ASize:Extended);overload;
  end;

  { TAggregatedEntry }

  TAggregatedEntry = class(TBookEntry)
  private
    FNumberOrders: Cardinal;
    function GetNumberOrders: Integer;
    procedure SetNumberOrders(const Value: Integer);
  public
    property NumberOrders: Integer read GetNumberOrders write SetNumberOrders;
    constructor Create(Const APrice:Single;Const ASize:Extended;
      Const ANumberOrders:Cardinal);overload;
  end;

  { TFullEntry }

  TFullEntry = class(TBookEntry)
  private
    FOrderID: String;
    function GetOrderID: String;
    procedure SetOrderID(const Value: String);
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
    function GetQuoteCurrency: String;
    function GetQuoteIncrement: Extended;
    procedure SetBaseCurrency(AValue: String);
    procedure SetBaseMaxSize(AValue: Extended);
    procedure SetBaseMinSize(AValue: Extended);
    procedure SetID(AValue: String);
    procedure SetQuoteCurrency(AValue: String);
    procedure SetQuoteIncrement(AValue: Extended);
    //properties
    property ID : String read GetID write SetID;
    property BaseCurrency : String read GetBaseCurrency write SetBaseCurrency;
    property QuoteCurrency : String read GetQuoteCurrency write SetQuoteCurrency;
    property BaseMinSize : Extended read GetBaseMinSize write SetBaseMinSize;
    property BaseMaxSize : Extended read GetBaseMaxSize write SetBaseMaxSize;
    property QuoteIncrement : Extended read GetQuoteIncrement
      write SetQuoteIncrement;
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
    procedure SetQuoteCurrency(AValue: String);
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
    procedure SetLevel(AValue: TGDAXBookLevel);
    procedure SetProduct(AValue: IGDAXProduct);
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
    FLow: Single;
    FHigh: Single;
    FOpen: Single;
    FClose: Single;
    FVolume: Extended;
    function GetTime: Extended;
    procedure SetTime(const Value: Extended);
    function GetLow: Single;
    procedure SetLow(const Value: Single);
    function GetHigh: Single;
    procedure SetHigh(const Value: Single);
    function GetOpen: Single;
    procedure SetOpen(const Value: Single);
    function GetClose: Single;
    procedure SetClose(const Value: Single);
    function GetVolume: Extended;
    procedure SetVolume(const Value: Extended);
  public
    property Time: Extended read GetTime write SetTime;
    property Low: Single read GetLow write SetLow;
    property High: Single read GetHigh write SetHigh;
    property Open: Single read GetOpen write SetOpen;
    property Close: Single read GetClose write SetClose;
    property Volume: Extended read GetVolume write SetVolume;
    constructor create(Const ATime:Extended;ALow,AHigh,AOpen,AClose:Single;
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
    procedure SetEndTime(AValue: TDatetime);
    procedure SetGranularity(AValue: Cardinal);
    procedure SetProduct(AValue: IGDAXProduct);
    procedure SetStartTime(AValue: TDatetime);
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
    procedure SetOrderID(AValue: String);
    procedure SetProductID(AValue: String);
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
    function GetAsk: Single;
    function GetBid: Single;
    function GetPrice: Single;
    function GetProduct: IGDAXProduct;
    function GetSize: Single;
    function GetTime: String;
    function GetVolume: Single;
    procedure SetAsk(AValue: Single);
    procedure SetBid(AValue: Single);
    procedure SetPrice(AValue: Single);
    procedure SetProduct(AValue: IGDAXProduct);
    procedure SetSize(AValue: Single);
    procedure SetTime(AValue: String);
    procedure SetVolume(AValue: Single);
    //properties
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property Price: Single read GetPrice write SetPrice;
    property Size: Single read GetSize write SetSize;
    property Bid: Single read GetBid write SetBid;
    property Ask: Single read GetAsk write SetAsk;
    property Volume: Single read GetVolume write SetVolume;
    property Time: String read GetTime write SetTime;
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
    procedure SetCreatedAt(const AValue: TDateTime);
    procedure SetExecutedValue(const AValue: Extended);
    procedure SetFilledSized(const AValue: Extended);
    procedure SetFillFees(const AValue: Extended);
    procedure SetID(const AValue: String);
    procedure SetOrderStatus(const AValue: TOrderStatus);
    procedure SetOrderType(const AValue: TOrderType);
    procedure SetPostOnly(const AValue: Boolean);
    procedure SetPrice(const AValue: Extended);
    procedure SetProduct(const AValue: IGDAXProduct);
    procedure SetRejectReason(const AValue: String);
    procedure SetSettled(const AValue: Boolean);
    procedure SetSide(const AValue: TOrderSide);
    procedure SetSize(const AValue: Extended);
    procedure SetStopOrder(const AValue: Boolean);
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
    procedure SetProduct(const AValue: IGDAXProduct);
    procedure SetStatuses(const AValue: TOrderStatuses);
    function GetOrders: TGDAXOrderList;
    //properties
    property Orders: TGDAXOrderList read GetOrders;
    property Statuses: TOrderStatuses read GetStatuses write SetStatuses;
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property Paged: IGDAXPaged read GetPaged;
  end;

implementation
uses
  SynCrossPlatformJSON, fpIndexer;

{ TFillEntry }

constructor TFillEntry.Create(const AJSON: String);
var
  LJSON:TJSONVariantData;
begin
  if not LJSON.FromJSON(AJSON) then
    raise Exception.Create(E_BADJSON);
  if LJSON.Kind<>jvObject then
    raise Exception.Create(E_BADJSON);
  FTradeID:=LJSON.Value[PROP_ID];
  FProductID:=LJSON.Value[PROP_PROD];
  FPrice:=LJSON.Value[PROP_PRICE];
  FSize:=LJSON.Value[PROP_SIZE];
  FOrderID:=LJSON.Value[PROP_ORDER];
  FCreatedAt:=fpIndexer.ISO8601ToDate(LJSON.Value[PROP_CREATE]);
  FLiquidity:=LJSON.Value[PROP_LIQUID];
  FFee:=LJSON.Value[PROP_FEE];
  FSettled:=LJSON.Value[PROP_SETTLED];
  FSide:=StringToOrderSide(LJSON.Value[PROP_SIDE]);
end;

{ TLedgerEntry.TDetails }

constructor TLedgerEntry.TDetails.Create(const AJSON: String);
var
  LJSON:TJSONVariantData;
begin
  if not LJSON.FromJSON(AJSON) then
    raise Exception.Create(E_BADJSON);
  if LJSON.Kind<>jvObject then
    raise Exception.Create(E_BADJSON);
  FOrderID:=LJSON.Value[PROP_ORDER_ID];
  FTradeID:=LJSON.Value[PROP_TRADE_ID];
  FProductID:=LJSON.Value[PROP_PROD_ID];
end;

{ TLedgerEntry }

constructor TLedgerEntry.Create(const AJSON: String);
var
  I:Integer;
  LJSON:TJSONVariantData;
  LDetails:TJSONVariantData;
begin
  if not LJSON.FromJSON(AJSON) then
    raise Exception.Create(E_BADJSON);
  if LJSON.Kind<>jvObject then
    raise Exception.Create(E_BADJSON);
  FID:=LJSON.Value[PROP_ID];
  FCreatedAt:=fpIndexer.ISO8601ToDate(LJSON.Value[PROP_CREATE]);
  FAmount:=LJSON.Value[PROP_AMOUNT];
  FBalance:=LJSON.Value[PROP_BALANCE];
  FLedgerType:=StringToLedgerType(LJSON.Value[PROP_TYPE]);
  if LJSON.NameIndex(PROP_DETAILS)>=0 then
    if not LDetails.FromJSON(LJSON.Data(PROP_DETAILS)^.ToJSON) then
      raise Exception.Create(Format(E_INVALID,['details json','json object']));
  //deserialize details object
  FDetails:=TDetails.Create(LDetails.ToJSON);
end;

{ TBookEntry }

constructor TBookEntry.Create(const APrice: Single; const ASize: Extended);
begin
  FPrice:=APrice;
  FSize:=ASize;
end;

function TBookEntry.GetPrice: Single;
begin
  Result:=FPrice;
end;

function TBookEntry.GetSide: TOrderSide;
begin
  Result:=FSide;
end;

function TBookEntry.GetSize: Extended;
begin
  Result:=FSize;
end;

procedure TBookEntry.SetPrice(const Value: Single);
begin
  FPrice:=Value;
end;

procedure TBookEntry.SetSide(const Value: TOrderSide);
begin
  FSide:=Value;
end;

procedure TBookEntry.SetSize(const Value: Extended);
begin
  FSize:=Value;
end;

{ TAggregatedEntry }

constructor TAggregatedEntry.Create(const APrice: Single; const ASize: Extended;
  const ANumberOrders: Cardinal);
begin
  inherited create(APrice,ASize);
  FNumberOrders:=ANumberOrders;
end;

function TAggregatedEntry.GetNumberOrders: Integer;
begin
  Result:=FNumberOrders;
end;

procedure TAggregatedEntry.SetNumberOrders(const Value: Integer);
begin
  FNumberOrders:=Value;
end;

{ TFullEntry }

constructor TFullEntry.Create(const APrice: Single; const ASize: Extended;
  const AOrderID: String);
begin
  inherited create(APrice,ASize);
  FOrderID:=AOrderID;
end;

function TFullEntry.GetOrderID: String;
begin
  Result:=FOrderID;
end;

procedure TFullEntry.SetOrderID(const Value: String);
begin
  FOrderID:=Value;
end;

{ TCandleBucket }

constructor TCandleBucket.create(const ATime: Extended; ALow, AHigh, AOpen,
 AClose: Single; AVolume: Extended);
begin
 Self.FTime:=ATime;
 Self.FLow:=ALow;
 Self.FHigh:=AHigh;
 Self.FOpen:=AOpen;
 Self.FClose:=AClose;
 Self.FVolume:=AVolume;
end;

class operator TCandleBucket.Equal(const A, B: TCandleBucket): Boolean;
begin
  Result:=A.Time=B.Time;
end;

function TCandleBucket.GetClose: Single;
begin
 Result:=FClose;
end;

function TCandleBucket.GetHigh: Single;
begin
 Result:=FHigh;
end;

function TCandleBucket.GetLow: Single;
begin
 Result:=FLow;
end;

function TCandleBucket.GetOpen: Single;
begin
 Result:=FOpen;
end;

function TCandleBucket.GetTime: Extended;
begin
 Result:=FTime;
end;

function TCandleBucket.GetVolume: Extended;
begin
 Result:=FVolume;
end;

procedure TCandleBucket.SetClose(const Value: Single);
begin
 FClose:=Value;
end;

procedure TCandleBucket.SetHigh(const Value: Single);
begin
 FHigh:=Value;
end;

procedure TCandleBucket.SetLow(const Value: Single);
begin
 FLow:=Value;
end;

procedure TCandleBucket.SetOpen(const Value: Single);
begin

end;

procedure TCandleBucket.SetTime(const Value: Extended);
begin
 FTime:=Value;
end;

procedure TCandleBucket.SetVolume(const Value: Extended);
begin
 FVolume:=Value;
end;
end.
