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

unit gdax.api.consts;

{$i gdax.inc}

interface
uses
  Classes, SysUtils;
type
  TGDAXApi = (gdSand,gdProd);
  TGDAXApis = set of TGDAXApi;
  TGDAXBookLevel = (blOne=1,blTwo=2,blThree=3);
  TGDAXBookLevels = set of TGDAXBookLevel;
  TRestOperation = (roGet,roPost,roDelete);
  TRestOperations = set of TRestOperation;
  (*
    1:1 relation to corresponding string arrays
  *)
  TOrderType = (otMarket,otLimit,otUnknown);
  TOrderTypes = set of TOrderType;
  TOrderSide = (osBuy,osSell,osUnknown);
  TOrderSides = set of TOrderSide;
  TOrderStatus = (stPending,stOpen,stActive,stSettled,stDone,stRejected,stCancelled,stUnknown);
  TOrderStatuses = set of TOrderStatus;
  TMarketType = (mtBuyers,mtSellers,mtUnknown);
  TMarketTypes = set of TMarketType;
  TLedgerType = (ltTransfer,ltMatch,ltFee,ltRebate);
  TledgerTypes = set of TLedgerType;

(*
  helper methods
*)
function BuildFullEndpoint(Const AResource:String; Const AMode:TGDAXApi):String;
function OrderTypeToString(Const AType:TOrderType):String;
function StringToOrderType(Const AType:String):TOrderType;
function OrderSideToString(Const ASide:TOrderSide):String;
function StringToOrderSide(Const ASide:String):TOrderSide;
function OrderStatusToString(Const AStatus:TOrderStatus):String;
function StringToOrderStatus(Const AStatus:String):TOrderStatus;
function LedgerTypeToString(Const AType:TLedgerType):String;
function StringToLedgerType(Const AType:String):TLedgerType;

const
  //maximum requests per second to the public REST API endpoints
  GDAX_PUBLIC_REQUESTS_PSEC = 3;

  //maximum requests per second to the public REST API endpoints
  GDAX_PRIVATE_REQUESTS_PSEC = 5;

  //https://docs.gdax.com/?python#api
  GDAX_END_API_BASE = 'https://api.pro.coinbase.com';//'https://api.gdax.com';

  //https://docs.gdax.com/?python#sandbox
  GDAX_END_API_BASE_SAND = 'https://api-public.sandbox.pro.coinbase.com';//'https://api-public.sandbox.gdax.com';

  //https://docs.gdax.com/?python#list-accounts
  GDAX_END_API_ACCTS = '/accounts';

  //https://docs.gdax.com/?python#get-an-account
  GDAX_END_API_ACCT = GDAX_END_API_ACCTS+'/%s';

  //https://docs.gdax.com/?python#get-account-history
  GDAX_END_API_ACCT_HIST = GDAX_END_API_ACCT+'/ledger';

  //https://docs.gdax.com/?python#get-holds
  GDAX_END_API_ACCT_HOLD = GDAX_END_API_ACCT+'/holds';

  //https://docs.gdax.com/?python#orders (post)
  GDAX_END_API_ORDERS = '/orders';
  GDAX_END_API_ORDER = GDAX_END_API_ORDERS+'/%s';

  //https://docs.gdax.com/?python#fills
  GDAX_END_API_FILLS = '/fills';

  //https://docs.gdax.com/#selecting-a-timestamp
  GDAX_END_API_TIME = '/time';

  //https://docs.gdax.com/#get-product-order-book
  GDAX_END_API_PRODUCT = '/products';
  GDAX_END_API_PRODUCTS = GDAX_END_API_PRODUCT+'/%s';
  GDAX_END_API_BOOK = GDAX_END_API_PRODUCTS+'/book?level=%d';
  GDAX_END_API_TICKER = GDAX_END_API_PRODUCTS+'/ticker';
  GDAX_END_API_CANDLES = GDAX_END_API_PRODUCTS+'/candles';

  //header names for gdax authentication
  CB_ACCESS_KEY = 'CB-ACCESS-KEY';
  CB_ACCESS_SIGN = 'CB-ACCESS-SIGN';
  CB_ACCESS_TIME = 'CB-ACCESS-TIMESTAMP';
  CB_ACCESS_PASS = 'CB-ACCESS-PASSPHRASE';

  //header names and url consts for pagination
  CB_BEFORE = 'CB-BEFORE';
  CB_AFTER = 'CB-AFTER';
  URL_PAGE_BEFORE = 'before';
  URL_PAGE_AFTER = 'after';
  URL_PAGE_LIMIT = 'limit';

  //Order types that can be made
  ORDER_TYPES : array [0..1] of string = (
    'market',
    'limit'
  );

  //which side, buy or sell, this order falls on (or is posted on)
  ORDER_SIDES : array[0..1] of string = (
    'buy',
    'sell'
  );
  ORDER_STATUS : array[0..6] of string = (
    'pending',
    'open',
    'active',
    'settled',
    'done',
    'rejected',
    'cancelled'
  );

  //types of entries for the account history endpoint (ledger)
  LEDGER_TYPES : array[0..3] of string = (
    'transfer',
    'match',
    'fee',
    'rebate'
  );

  //rest operations expanded text
  OP_POST = 'POST';
  OP_GET = 'GET';
  OP_DELETE = 'DELETE';

  USER_AGENT_MOZILLA = 'Mozilla/5.0 (Windows NT 10.0; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0';
  E_UNSUPPORTED = '%s operation unsupported in class %s';
  E_BADJSON = 'bad json format';
  E_BADJSON_PROP = 'property %s cannot be found';
  E_UNKNOWN = '%s is unknown in %s';
  E_INVALID = '%s is invalid, must be %s';
  E_NOT_IMPL = '%s is not implemented in %s';
implementation

function BuildFullEndpoint(Const AResource:String; Const AMode:TGDAXApi):String;
begin
  if AMode=gdSand then
    Result:=GDAX_END_API_BASE_SAND+AResource
  else
    Result:=GDAX_END_API_BASE+AResource;
end;

function StringToOrderStatus(Const AStatus:String):TOrderStatus;
var
  I: Integer;
begin
  Result:=stUnknown;
  for I := Low(ORDER_STATUS) to High(ORDER_STATUS) do
    if LowerCase(ORDER_STATUS[I])=LowerCase(AStatus) then
    begin
      Result:=TOrderStatus(I);
      Exit;
    end;
end;

function LedgerTypeToString(Const AType: TLedgerType): String;
begin
  Result:='';
  if Ord(AType)<=High(LEDGER_TYPES) then
    Result:=LEDGER_TYPES[Ord(AType)];
end;

function StringToLedgerType(Const AType: String): TLedgerType;
var
  I: Integer;
begin
  Result:=ltTransfer;
  for I := Low(LEDGER_TYPES) to High(LEDGER_TYPES) do
    if LowerCase(LEDGER_TYPES[I])=LowerCase(AType) then
    begin
      Result:=TLedgerType(I);
      Exit;
    end;
end;

function StringToOrderSide(Const ASide:String):TOrderSide;
var
  I: Integer;
begin
  Result:=osUnknown;
  for I := Low(ORDER_SIDES) to High(ORDER_SIDES) do
    if LowerCase(ORDER_SIDES[I])=LowerCase(ASide) then
    begin
      Result:=TOrderSide(I);
      Exit;
    end;
end;

function StringToOrderType(Const AType:String):TOrderType;
var
  I: Integer;
begin
  Result:=otUnknown;
  for I := Low(ORDER_TYPES) to High(ORDER_TYPES) do
    if LowerCase(ORDER_TYPES[I])=LowerCase(AType) then
    begin
      Result:=TOrderType(I);
      Exit;
    end;
end;

function OrderStatusToString(Const AStatus:TOrderStatus):String;
begin
  Result:='';
  if AStatus=stUnknown then
    Exit;
  Result:=ORDER_STATUS[Ord(AStatus)];
end;

function OrderSideToString(Const ASide:TOrderSide):String;
begin
  Result:='';
  if ASide=osUnknown then
    Exit;
  Result:=ORDER_SIDES[Ord(ASide)];
end;

function OrderTypeToString(Const AType:TOrderType):String;
begin
  Result:='';
  if AType=otUnknown then
    Exit;
  Result:=ORDER_TYPES[Ord(AType)];
end;
end.

