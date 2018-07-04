unit gdax.api.orders;

{$i gdax.inc}

interface
uses
  Classes, gdax.api, gdax.api.consts, gdax.api.types;
type

  { TGDAXOrderImpl }

  TGDAXOrderImpl = class(TGDAXRestApi,IGDAXOrder)
  public
    const
      PROP_ID = 'id';
      PROP_PRICE = 'price';
      PROP_SIZE = 'size';
      PROP_FUNDS = 'funds';
      PROP_PROD = 'product_id';
      PROP_SIDE = 'side';
      PROP_TYPE = 'type';
      PROP_POST = 'post_only';
      PROP_CREATE = 'created_at';
      PROP_FEE = 'fill_fees';
      PROP_FILL = 'filled_size';
      PROP_EXEC = 'executed_value';
      PROP_STATUS = 'status';
      PROP_SETTLED = 'settled';
      PROP_REJECT = 'reject_reason';
      PROP_STOP = 'stop';
      PROP_STOP_PRICE = 'stop_price';
      PROP_STOP_ENTRY = 'entry';
      PROP_STOP_LOSS = 'loss';
  private
    FProduct: IGDAXProduct;
    FPostOnly: Boolean;
    FSize: Extended;
    FType: TOrderType;
    FID: String;
    FFillFees: Extended;
    FFilledSize: Extended;
    FExecutedValue: Extended;
    FStatus: TOrderStatus;
    FSettled: Boolean;
    FSide: TOrderSide;
    FPrice: Extended;
    FRejectReason: String;
    FCreatedAt: TDateTime;
    FStop: Boolean;
    function GetCreatedAt: TDateTime;
    function GetProduct: IGDAXProduct;
    function GetStopOrder: Boolean;
    procedure SetCreatedAt(const AValue: TDateTime);
    procedure SetProduct(const Value: IGDAXProduct);
    function GetPostOnly: Boolean;
    procedure SetPostOnly(const Value: Boolean);
    function GetSize: Extended;
    procedure SetSize(const Value: Extended);
    function GetOrderType: TOrderType;
    procedure SetOrderType(const Value: TOrderType);
    function GetID: String;
    procedure SetID(const Value: String);
    function GetFillFees: Extended;
    procedure SetFillFees(const Value: Extended);
    function GetFilledSized: Extended;
    procedure SetFilledSized(const Value: Extended);
    function GetExecutedValue: Extended;
    procedure SetExecutedValue(const Value: Extended);
    function GetOrderStatus: TOrderStatus;
    procedure SetOrderStatus(const Value: TOrderStatus);
    function GetSettled: Boolean;
    procedure SetSettled(const Value: Boolean);
    function GetSide: TOrderSide;
    procedure SetSide(const Value: TOrderSide);
    function GetPrice: Extended;
    procedure SetPrice(const Value: Extended);
    function GetRejectReason: String;
    procedure SetRejectReason(const Value: String);
    procedure SetStopOrder(const AValue: Boolean);
  protected
    function DoGetPostBody: string; override;
    function DoGet(const AEndpoint: string; const AHeaders: TStrings;
      out Content: string; out Error: string): Boolean; override;
    function DoPost(const AEndPoint: string; const AHeaders: TStrings;
      const ABody: string; out Content: string; out Error: string): Boolean;override;
    function GetEndpoint(const AOperation: TRestOperation): string; override;
    function DoLoadFromJSON(const AJSON: string; out Error: string): Boolean;override;
    function DoGetSupportedOperations: TRestOperations; override;
    function DoDelete(const AEndpoint: string; const AHeaders: TStrings;
      out Content: string; out Error: string): Boolean; override;
  public
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
    constructor Create; override;
    destructor Destroy; override;
  end;

  { TGDAXOrdersImpl }

  TGDAXOrdersImpl = class(TGDAXPagedApi,IGDAXOrders)
  private
    FOrders: TGDAXOrderList;
    FStatuses: TOrderStatuses;
    FProduct: IGDAXProduct;
    function GetOrders: TGDAXOrderList;
    function GetPaged: IGDAXPaged;
    function GetStatuses: TOrderStatuses;
    procedure SetStatuses(const Value: TOrderStatuses);
    function BuildQueryStringForStatus:String;
    function GetProduct: IGDAXProduct;
    procedure SetProduct(const Value: IGDAXProduct);
  protected
    function DoGetSupportedOperations: TRestOperations; override;
    function DoLoadFromJSON(const AJSON: string;
      out Error: string): Boolean;override;
    function GetEndpoint(const AOperation: TRestOperation): string; override;
    function DoMove(const ADirection: TGDAXPageDirection; out Error: String;
      const ALastBeforeID, ALastAfterID: Integer;
      const ALimit: TPageLimit=0): Boolean; override;
  public
    property Orders: TGDAXOrderList read GetOrders;
    property Statuses: TOrderStatuses read GetStatuses write SetStatuses;
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property Paged: IGDAXPaged read GetPaged;
    constructor Create; override;
    destructor Destroy; override;
  end;
implementation
uses
  SysUtils, SynCrossPlatformJSON, fpindexer, gdax.api.products;

{ TGDAXOrderImpl }

constructor TGDAXOrderImpl.Create;
begin
  inherited;
  FStatus:=stUnknown;
  FProduct:=TGDAXProductImpl.Create;
  FPostOnly:=True;
  FType:=otLimit;
  FSize:=0;
end;

destructor TGDAXOrderImpl.Destroy;
begin
  FProduct:=nil;
  inherited;
end;

function TGDAXOrderImpl.DoDelete(const AEndpoint: string; const AHeaders: TStrings; out
  Content: string; out Error: string): Boolean;
begin
  Result:=False;
  try
    if Trim(FID)='' then
    begin
      Error:=Format(E_INVALID,['id','a long ass string']);
      Exit;
    end;
    Result:=inherited;
    if not Result then
      Exit;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TGDAXOrderImpl.DoGet(const AEndpoint: string; const AHeaders: TStrings; out
  Content: string; out Error: string): Boolean;
begin
  Result:=False;
  if Trim(FID)='' then
  begin
    Error:=Format(E_INVALID,['id','a long ass string']);
    Exit;
  end;
  Result:=inherited;
end;

function TGDAXOrderImpl.DoGetPostBody: string;
var
  LJSON:TJSONVariantData;
begin
  Result:='';
  LJSON.FromJSON('{}');
  LJSON.AddNameValue(PROP_SIZE,FloatToStrF(FSize,TFloatFormat.ffFixed,15,8));
  LJSON.AddNameValue(PROP_PRICE,FloatToStrF(FPrice,TFloatFormat.ffFixed,15,8));
  LJSON.AddNameValue(PROP_SIDE,OrderSideToString(FSide));
  LJSON.AddNameValue(PROP_PROD,FProduct.ID);
  if (FType=otLimit) and FPostOnly then
    LJSON.AddNameValue(PROP_POST,FPostOnly);
  LJSON.AddNameValue(PROP_TYPE,OrderTypeToString(FType));
  if FStop then
  begin
    //stop orders seem to actually require funds to be specified when market, even
    //though docs say otherwise
    if FType=otMarket then
      LJSON.AddNameValue(PROP_FUNDS,FloatToStrF(FSize * FPrice,TFloatFormat.ffFixed,15,8));
    case FSide of
      osBuy: LJSON.AddNameValue(PROP_STOP,PROP_STOP_ENTRY);
      osSell: LJSON.AddNameValue(PROP_STOP,PROP_STOP_LOSS);
    end;
    LJSON.AddNameValue(PROP_STOP_PRICE,FloatToStrF(FPrice,TFloatFormat.ffFixed,15,8))
  end;
  Result:=LJSON.ToJSON;
end;

function TGDAXOrderImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet,roPost,roDelete];
end;

function TGDAXOrderImpl.DoLoadFromJSON(const AJSON: string; out Error: string): Boolean;
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
    //id is required in all situations
    if LJSON.NameIndex(PROP_ID)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_ID]);
      Exit;
    end
    else
      FID:=LJSON.Value[PROP_ID];
    //Price per bitcoin (not required)
    if LJSON.NameIndex(PROP_PRICE)<0 then
      FPrice:=0
    else
      FPrice:=StrToFloat(LJSON.Value[PROP_PRICE]);
    //Amount of BTC to buy or sell
    if LJSON.NameIndex(PROP_SIZE)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_SIZE]);
      Exit;
    end
    else
      FSize:=StrToFloat(LJSON.Value[PROP_SIZE]);
    //product id is the type of currency
    if LJSON.NameIndex(PROP_PROD)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_PROD]);
      Exit;
    end
    else
      FProduct.ID:=LJSON.Value[PROP_PROD];
    //side is buying or selling
    if LJSON.NameIndex(PROP_SIDE)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_SIDE]);
      Exit;
    end
    else
      FSide:=StringToOrderSide(LJSON.Value[PROP_SIDE]);
    //type of the order (limit/market)
    if LJSON.NameIndex(PROP_TYPE)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_TYPE]);
      Exit;
    end
    else
      FType:=StringToOrderType(LJSON.Value[PROP_TYPE]);
    //status of the order
    if LJSON.NameIndex(PROP_STATUS)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_STATUS]);
      Exit;
    end
    else
      FStatus:=StringToOrderStatus(LJSON.Value[PROP_STATUS]);
    //post only is for limit orders, but should still come back in response
    if LJSON.NameIndex(PROP_POST)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_POST]);
      Exit;
    end
    else
      FPostOnly:=LJSON.Value[PROP_POST];
    //settled
    if LJSON.NameIndex(PROP_SETTLED)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_SETTLED]);
      Exit;
    end
    else
      FSettled:=LJSON.Value[PROP_SETTLED];
    //fill fees
    if LJSON.NameIndex(PROP_FEE)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_FEE]);
      Exit;
    end
    else
      FFillFees:=StrToFloat(LJSON.Value[PROP_FEE]);
    //filled size is how much of size is actually filled
    if LJSON.NameIndex(PROP_FILL)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_FILL]);
      Exit;
    end
    else
      FFilledSize:=StrToFloat(LJSON.Value[PROP_FILL]);
    //executed value
    if LJSON.NameIndex(PROP_EXEC)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_EXEC]);
      Exit;
    end
    else
      FExecutedValue:=StrToFloat(LJSON.Value[PROP_EXEC]);
    //rejected reason may or may not be here
    if LJSON.NameIndex(PROP_REJECT)<0 then
      FRejectReason:=''
    else
      FRejectReason:=LJSON.Value[PROP_REJECT];
    //create time in utc of the order
    if LJSON.NameIndex(PROP_CREATE)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[PROP_CREATE]);
      Exit;
    end
    else
      FCreatedAt:=fpindexer.ISO8601ToDate(LJSON.Value[PROP_CREATE]);
    Result:=True;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TGDAXOrderImpl.DoPost(const AEndPoint: string; const AHeaders: TStrings;
  const ABody: string; out Content: string; out Error: string): Boolean;
begin
  Result:=False;
  if FType=otUnknown then
  begin
    Error:=Format(E_UNKNOWN,['order type',Self.ClassName]);
    Exit;
  end;
  if FSide=TOrderSide.osUnknown then
  begin
    Error:=Format(E_UNKNOWN,['order side',Self.ClassName]);
    Exit;
  end;
  if FSize<=0 then
  begin
    Error:=Format(E_INVALID,['size '+FloatToStr(FSize),'0.01 and 10000.0']);
    Exit;
  end;
  if FProduct.ID.IsEmpty then
  begin
    Error:=Format(E_UNKNOWN,['product',Self.ClassName]);
    Exit;
  end;
  Result:=inherited;
end;

function TGDAXOrderImpl.GetEndpoint(const AOperation: TRestOperation): string;
begin
  Result:='';
  if (AOperation=roGet) or (AOperation=roDelete) then
    Result:=Format(GDAX_END_API_ORDER,[FID])
  else if AOperation=roPost then
    Result:=GDAX_END_API_ORDERS
  else if AOperation=roDelete then
    Result:=Format(GDAX_END_API_ORDER,[FID]);
end;

function TGDAXOrderImpl.GetExecutedValue: Extended;
begin
  Result:=FExecutedValue;
end;

function TGDAXOrderImpl.GetFilledSized: Extended;
begin
  Result:=FFilledSize;
end;

function TGDAXOrderImpl.GetFillFees: Extended;
begin
  Result:=FFillFees;
end;

function TGDAXOrderImpl.GetID: String;
begin
  Result:=FID;
end;

function TGDAXOrderImpl.GetOrderStatus: TOrderStatus;
begin
  Result:=FStatus;
end;

function TGDAXOrderImpl.GetOrderType: TOrderType;
begin
  Result:=FType;
end;

function TGDAXOrderImpl.GetPostOnly: Boolean;
begin
  Result:=FPostOnly;
end;

function TGDAXOrderImpl.GetPrice: Extended;
begin
  Result:=FPrice;
end;

function TGDAXOrderImpl.GetProduct: IGDAXProduct;
begin
  Result:=FProduct;
end;

function TGDAXOrderImpl.GetStopOrder: Boolean;
begin
  Result:=FStop;
end;

function TGDAXOrderImpl.GetCreatedAt: TDateTime;
begin
  Result:=FCreatedAt;
end;

procedure TGDAXOrderImpl.SetCreatedAt(const AValue: TDateTime);
begin
  FCreatedAt:=AValue;
end;

function TGDAXOrderImpl.GetRejectReason: String;
begin
  Result:=FRejectReason;
end;

function TGDAXOrderImpl.GetSettled: Boolean;
begin
  Result:=FSettled;
end;

function TGDAXOrderImpl.GetSide: TOrderSide;
begin
  Result:=FSide;
end;

function TGDAXOrderImpl.GetSize: Extended;
begin
  Result:=FSize;
end;

procedure TGDAXOrderImpl.SetExecutedValue(const Value: Extended);
begin
  FExecutedValue:=Value;
end;

procedure TGDAXOrderImpl.SetFilledSized(const Value: Extended);
begin
  FFilledSize:=Value;
end;

procedure TGDAXOrderImpl.SetFillFees(const Value: Extended);
begin
  FFillFees:=Value;
end;

procedure TGDAXOrderImpl.SetID(const Value: String);
begin
  FID:=Value;
end;

procedure TGDAXOrderImpl.SetOrderStatus(const Value: TOrderStatus);
begin
  FStatus:=Value;
end;

procedure TGDAXOrderImpl.SetOrderType(const Value: TOrderType);
begin
  FType:=Value;
end;

procedure TGDAXOrderImpl.SetPostOnly(const Value: Boolean);
begin
  FPostOnly:=Value;
end;

procedure TGDAXOrderImpl.SetPrice(const Value: Extended);
begin
  FPrice:=Value;
end;

procedure TGDAXOrderImpl.SetProduct(const Value: IGDAXProduct);
begin
  //free reference first
  FProduct:=nil;
  FProduct:=Value;
end;

procedure TGDAXOrderImpl.SetRejectReason(const Value: String);
begin
  FRejectReason:=Value;
end;

procedure TGDAXOrderImpl.SetStopOrder(const AValue: Boolean);
begin
  FStop:=AValue;
end;

procedure TGDAXOrderImpl.SetSettled(const Value: Boolean);
begin
  FSettled:=Value;
end;

procedure TGDAXOrderImpl.SetSide(const Value: TOrderSide);
begin
  FSide:=Value;
end;

procedure TGDAXOrderImpl.SetSize(const Value: Extended);
begin
  FSize:=Value;
end;

{ TGDAXOrdersImpl }

function TGDAXOrdersImpl.BuildQueryStringForStatus: String;
Const
  QUERY = '?status=%s';
  QUERY_ADD = '&status=%s';
begin
  if FStatuses=[] then
  begin
    Result:=Format(QUERY,['all']);
    Exit;
  end;
  if stPending in FStatuses then
    Result:=Format(Query,[OrderStatusToString(stPending)]);
  if stOpen in FStatuses then
  begin
    if Result='' then
      Result:=Result+Format(QUERY,[OrderStatusToString(stOpen)])
    else
      Result:=Result+Format(QUERY_ADD,[OrderStatusToString(stOpen)]);
  end;
  if stActive in FStatuses then
  begin
    if Result='' then
      Result:=Result+Format(QUERY,[OrderStatusToString(stActive)])
    else
      Result:=Result+Format(QUERY_ADD,[OrderStatusToString(stActive)]);
  end;
  if stDone in FStatuses then
  begin
    if Result='' then
      Result:=Result+Format(QUERY,[OrderStatusToString(stDone)])
    else
      Result:=Result+Format(QUERY_ADD,[OrderStatusToString(stDone)]);
  end;
  if stRejected in FStatuses then
  begin
    if Result='' then
      Result:=Result+Format(QUERY,[OrderStatusToString(stRejected)])
    else
      Result:=Result+Format(QUERY_ADD,[OrderStatusToString(stRejected)]);
  end;
end;

constructor TGDAXOrdersImpl.Create;
begin
  inherited;
  FProduct:=TGDAXProductImpl.Create;
  FOrders:=TGDAXOrderList.Create;
end;

destructor TGDAXOrdersImpl.Destroy;
begin
  FProduct:=nil;
  FOrders.Free;
  inherited;
end;

function TGDAXOrdersImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXOrdersImpl.DoLoadFromJSON(const AJSON: string;
  out Error: string): Boolean;
var
  LJSON:TJSONVariantData;
  I: Integer;
  LOrder: IGDAXOrder;
begin
  Result:=False;
  try
    FOrders.Clear;
    if not LJSON.FromJSON(AJSON) then
    begin
      Error:=E_BADJSON;
      Exit;
    end;
    if LJSON.Kind<>jvArray then
    begin
      Error:=Format(E_BADJSON_PROP,['main json array']);
      Exit;
    end;
    for I := 0 to Pred(LJSON.Count) do
    begin
      LOrder:=TGDAXOrderImpl.Create;
      //try to deserialzie order
      if not LOrder.LoadFromJSON(TJSONVariantData(LJSON.Item[I]).ToJSON,Error) then
        Exit;
      FOrders.Add(LOrder);
    end;
    Result:=True;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TGDAXOrdersImpl.GetEndpoint(const AOperation: TRestOperation): string;
var
  LMoving:String;
begin
  Result:='';
  //filters for statuses
  Result:=GDAX_END_API_ORDERS+BuildQueryStringForStatus;
  //specific product
  if not FProduct.ID.IsEmpty then
    Result:=Result+'&product_id='+FProduct.ID;
  //paging params
  LMoving:=GetMovingParameters;
  if LMoving.Length>0 then
    Result:=Result+LMoving;
end;

function TGDAXOrdersImpl.DoMove(const ADirection: TGDAXPageDirection; out Error: String;
  const ALastBeforeID, ALastAfterID: Integer;
  const ALimit: TPageLimit): Boolean;
var
  I:Integer;
  LList:TGDAXOrderList;
begin
  LList:=TGDAXOrderList.Create;
  try
    try
      //keep old orders on page move
      LList.Assign(FOrders);
      Result:=inherited DoMove(ADirection, Error, ALastBeforeID,
        ALastAfterID,ALimit
      );
      //add all the previous orders
      for I:=0 to Pred(LList.Count) do
        FOrders.Add(LList[I]);
    except on E:Exception do
      Error:=E.Message;
    end;
  finally
    LList.Free;
  end;
end;

function TGDAXOrdersImpl.GetOrders: TGDAXOrderList;
begin
  Result:=FOrders;
end;

function TGDAXOrdersImpl.GetProduct: IGDAXProduct;
begin
  Result:=FProduct;
end;

function TGDAXOrdersImpl.GetStatuses: TOrderStatuses;
begin
  Result:=FStatuses;
end;

procedure TGDAXOrdersImpl.SetProduct(const Value: IGDAXProduct);
begin
  FProduct:=Value;
end;

procedure TGDAXOrdersImpl.SetStatuses(const Value: TOrderStatuses);
begin
  FStatuses:=Value;
end;

function TGDAXOrdersImpl.GetPaged: IGDAXPaged;
begin
  Result:=Self as IGDAXPaged;
end;

end.