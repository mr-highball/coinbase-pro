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

unit gdax.api.book;

{$i gdax.inc}

interface
uses
  Classes, SysUtils, gdax.api, gdax.api.consts, gdax.api.types;
type
  TGDAXBook = class(TGDAXRestApi,IGDAXBook)
  private
    FAskList:TObjectList<TBookEntry>;
    FBidList:TObjectList<TBookEntry>;
    FLevel: TGDAXBookLevel;
    FProduct: IGDAXProduct;
    FMarketType: TMarketType;
    FAskSize: Single;
    FBidSize: Single;
    function GetLevel: TGDAXBookLevel;
    procedure SetLevel(Const Value: TGDAXBookLevel);
    function GetProduct: IGDAXProduct;
    procedure SetProduct(Const AValue: IGDAXProduct);
    function GetAskList: TObjectList<TBookEntry>;
    function GetBidList: TObjectList<TBookEntry>;
    procedure ClearMetaData;
    function GetMarketType: TMarketType;
    function GetAskSize: Single;
    function GetBidSize: Single;
  protected
    function DoLoadFromJSON(Const AJSON: string; out Error: string): Boolean;
      override;
    function GetEndpoint(Const AOperation: TRestOperation): string; override;
    function DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
      out Content: string; out Error: string): Boolean; override;
    function DoGetSupportedOperations: TRestOperations; override;
  public
    property Level: TGDAXBookLevel read GetLevel write SetLevel;
    property Product: IGDAXProduct read GetProduct write SetProduct;
    property AskList: TObjectList<TBookEntry> read GetAskList;
    property BidList: TObjectList<TBookEntry> read GetBidList;
    property MarketType: TMarketType read GetMarketType;
    property AskSize: Single read GetAskSize;
    property BidSize: Single read GetBidSize;
    constructor Create; override;
    destructor Destroy; override;
  end;
implementation
uses
  SynCrossPlatformJSON, Math;

{ TGDAXBook }

procedure TGDAXBook.ClearMetaData;
begin
  FAskList.Clear;
  FBidList.Clear;
  FMarketType:=mtUnknown;
  FBidSize:=0;
  FAskSize:=0;
end;

constructor TGDAXBook.Create;
begin
  inherited;
  FAskList:=TObjectList<TBookEntry>.Create;
  FBidList:=TObjectList<TBookEntry>.Create;
  FLevel:=blOne;
  FProduct:=opUnknown;
end;

destructor TGDAXBook.Destroy;
begin
  FAskList.Free;
  FBidList.Free;
  inherited;
end;

function TGDAXBook.DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
  out Content, Error: string): Boolean;
begin
  Result:=False;
  if FProduct=opUnknown then
  begin
    Error:=Format(E_UNKNOWN,['OrderProduct',Self.ClassName]);
    Exit;
  end;
  Result:=inherited;
end;

function TGDAXBook.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXBook.DoLoadFromJSON(Const AJSON: string;
  out Error: string): Boolean;
var
  LJSON,LAsks,LBids:LJSONVariantData;
  LEntry:TBookEntry;
  I: Integer;
const
  ENTRY_ASK='asks';
  ENTRY_BID='bids';
  PRICE_DECIMAL=-2;
  PR_IX = 0;
  SZ_IX = 1;
  OTHER_IX = 2;
begin
  Result:=False;
  try
    LEntry:=nil;
    FAskList.Clear;
    FBidList.Clear;
    ClearMetaData;
    if not LJSON.FromJSON(AJSON) then
    begin
      Error:=E_BADJSON;
      Exit;
    end;
    if LJSON.NameIndex(ENTRY_BID)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[ENTRY_BID]);
      Exit;
    end;
    if LJSON.NameIndex(ENTRY_ASK)<0 then
    begin
      Error:=Format(E_BADJSON_PROP,[ENTRY_ASK]);
      Exit;
    end;
    LBids:=LJSON.Data(ENTRY_BID)^;
    LAsks:=LJSON.Data(ENTRY_ASK)^;
    //fill out book for bids
    for I := 0 to Pred(LBids.Count) do
    begin
      case FLevel of
        blOne,blTwo:
          begin
            LEntry:=TAggregatedEntry.create(
              Single(SimpleRoundTo(StrToFloat(LJSONVariantData(LBids.Item[I]).Item[PR_IX]),PRICE_DECIMAL)),
              StrToFloat(LJSONVariantData(LBids.Item[I]).Item[SZ_IX]),
              LJSONVariantData(LBids.Item[I]).Item[OTHER_IX]
            );
            FBidList.Add(LEntry);
          end;
        blThree:
          begin
            LEntry:=TFullEntry.create(
              Single(SimpleRoundTo(StrToFloat(LJSONVariantData(LBids.Item[I]).Item[PR_IX]),PRICE_DECIMAL)),
              StrToFloat(LJSONVariantData(LBids.Item[I]).Item[SZ_IX]),
              LJSONVariantData(LBids.Item[I]).Item[OTHER_IX]
            );
            FBidList.Add(LEntry);
          end;
      end;
      LEntry.Side:=osBuy;
      FBidSize:=FBidSize+LEntry.Size;
    end;
    //fill out book for asks
    for I := 0 to Pred(LAsks.Count) do
    begin
      case FLevel of
        blOne,blTwo:
          begin
            LEntry:=TAggregatedEntry.create(
              Single(SimpleRoundTo(StrToFloat(LJSONVariantData(LAsks.Item[I]).Item[PR_IX]),PRICE_DECIMAL)),
              StrToFloat(LJSONVariantData(LAsks.Item[I]).Item[SZ_IX]),
              LJSONVariantData(LAsks.Item[I]).Item[OTHER_IX]
            );
            FAskList.Add(LEntry);
          end;
        blThree:
          begin
            LEntry:=TFullEntry.create(
              Single(SimpleRoundTo(StrToFloat(LJSONVariantData(LAsks.Item[I]).Item[PR_IX]),PRICE_DECIMAL)),
              StrToFloat(LJSONVariantData(LAsks.Item[I]).Item[SZ_IX]),
              LJSONVariantData(LAsks.Item[I]).Item[OTHER_IX]
            );
            FAskList.Add(LEntry);
          end;
      end;
      LEntry.Side:=osSell;
      FAskSize:=FAskSize+LEntry.Size;
    end;
    //more buying than selling means its a sellers market
    if FBidSize>FAskSize then
      FMarketType:=mtSellers
    else if FBidSize<FAskSize then
      FMarketType:=mtBuyers
    else
      FMarketType:=mtUnknown;
    Result:=True;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TGDAXBook.GetAskList: TObjectList<TBookEntry>;
begin
  Result:=FAskList;
end;

function TGDAXBook.GetAskSize: Single;
begin
  Result:=FAskSize;
end;

function TGDAXBook.GetBidList: TObjectList<TBookEntry>;
begin
  Result:=FBidList;
end;

function TGDAXBook.GetBidSize: Single;
begin
  Result:=FBidSize;
end;

function TGDAXBook.GetEndpoint(Const AOperation: TRestOperation): string;
begin
  Result:=Format(GDAX_END_API_BOOK,[OrderProductToString(FProduct),Ord(FLevel)]);
end;

function TGDAXBook.GetLevel: TGDAXBookLevel;
begin
  Result:=FLevel;
end;

function TGDAXBook.GetMarketType: TMarketType;
begin
  Result:=FMarketType;
end;

function TGDAXBook.GetProduct: IGDAXProduct;
begin
  Result:=FProduct;
end;

procedure TGDAXBook.SetLevel(Const Value: TGDAXBookLevel);
begin
  ClearMetaData;
  FLevel:=Value;
end;

procedure TGDAXBook.SetProduct(Const AValue: IGDAXProduct);
begin
  ClearMetaData;
  FProduct:=Value;
end;

end.
