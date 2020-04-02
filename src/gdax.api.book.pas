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
  TGDAXBookImpl = class(TGDAXRestApi,IGDAXBook)
  private
    FAskList: TGDAXBookEntryList;
    FBidList: TGDAXBookEntryList;
    FLevel: TGDAXBookLevel;
    FProduct: IGDAXProduct;
    FMarketType: TMarketType;
    FAskSize: Single;
    FBidSize: Single;
  protected
    function GetLevel: TGDAXBookLevel;
    procedure SetLevel(Const Value: TGDAXBookLevel);
    function GetProduct: IGDAXProduct;
    procedure SetProduct(Const Value: IGDAXProduct);
    function GetAskList: TGDAXBookEntryList;
    function GetBidList: TGDAXBookEntryList;
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
    property AskList: TGDAXBookEntryList read GetAskList;
    property BidList: TGDAXBookEntryList read GetBidList;
    property MarketType: TMarketType read GetMarketType;
    property AskSize: Single read GetAskSize;
    property BidSize: Single read GetBidSize;
    constructor Create; override;
    destructor Destroy; override;
  end;
implementation
uses
  fpjson,
  jsonparser;

{ TGDAXBookImpl }

procedure TGDAXBookImpl.ClearMetaData;
begin
  FAskList.Clear;
  FBidList.Clear;
  FMarketType := mtUnknown;
  FBidSize:=0;
  FAskSize:=0;
end;

constructor TGDAXBookImpl.Create;
begin
  inherited;
  FAskList := TGDAXBookEntryList.Create;
  FBidList := TGDAXBookEntryList.Create;
  FLevel := blOne;
end;

destructor TGDAXBookImpl.Destroy;
begin
  FAskList.Free;
  FBidList.Free;
  inherited;
end;

function TGDAXBookImpl.DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
  out Content, Error: string): Boolean;
begin
  Result := False;
  if not Assigned(FProduct) then
  begin
    Error := Format(E_UNKNOWN,['OrderProduct',Self.ClassName]);
    Exit;
  end;
  Result := inherited;
end;

function TGDAXBookImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXBookImpl.DoLoadFromJSON(Const AJSON: string;
  out Error: string): Boolean;
var
  LJSON : TJSONObject;
  LAsks,
  LBids : TJSONArray;
  LEntry:TBookEntry;
  I: Integer;
const
  ENTRY_ASK='asks';
  ENTRY_BID='bids';
  PR_IX = 0;
  SZ_IX = 1;
  OTHER_IX = 2;
begin
  Result := False;
  try
    LEntry := nil;
    FAskList.Clear;
    FBidList.Clear;
    ClearMetaData;
    LJSON := TJSONObject(GetJSON(AJSON));

    if not Assigned(LJSON) then
      raise Exception.Create(E_BADJSON);

    try
      if LJSON.Find(ENTRY_BID) <> nil then
      begin
        Error := Format(E_BADJSON_PROP,[ENTRY_BID]);
        Exit;
      end;

      if LJSON.Find(ENTRY_ASK) <> nil then
      begin
        Error := Format(E_BADJSON_PROP,[ENTRY_ASK]);
        Exit;
      end;

      LBids := LJSON.Arrays[ENTRY_BID];
      LAsks := LJSON.Arrays[ENTRY_ASK];

      //fill out book for bids
      for I:=0 to Pred(LBids.Count) do
      begin
        case FLevel of
          blOne,blTwo:
            begin
              LEntry := TAggregatedEntry.create(
                TJSONArray(LBids.Items[I]).Items[PR_IX].AsFloat,
                TJSONArray(LBids.Items[I]).Items[SZ_IX].AsFloat,
                TJSONArray(LBids.Items[I]).Items[OTHER_IX].AsInt64
              );
              FBidList.Add(LEntry);
            end;
          blThree:
            begin
              LEntry := TFullEntry.create(
                TJSONArray(LBids.Items[I]).Items[PR_IX].AsFloat,
                TJSONArray(LBids.Items[I]).Items[SZ_IX].AsFloat,
                TJSONArray(LBids.Items[I]).Items[OTHER_IX].AsString
              );
              FBidList.Add(LEntry);
            end;
        end;
        LEntry.Side := osBuy;
        FBidSize := FBidSize+LEntry.Size;
      end;

      //fill out book for asks
      for I:=0 to Pred(LAsks.Count) do
      begin
        case FLevel of
          blOne,blTwo:
            begin
              LEntry := TAggregatedEntry.create(
                TJSONArray(LAsks.Items[I]).Items[PR_IX].AsFloat,
                TJSONArray(LAsks.Items[I]).Items[SZ_IX].AsFloat,
                TJSONArray(LAsks.Items[I]).Items[OTHER_IX].AsInt64
              );

              FAskList.Add(LEntry);
            end;
          blThree:
            begin
              LEntry := TFullEntry.create(
                TJSONArray(LAsks.Items[I]).Items[PR_IX].AsFloat,
                TJSONArray(LAsks.Items[I]).Items[SZ_IX].AsFloat,
                TJSONArray(LAsks.Items[I]).Items[OTHER_IX].AsString
              );

              FAskList.Add(LEntry);
            end;
        end;

        LEntry.Side := osSell;
        FAskSize := FAskSize+LEntry.Size;
      end;

      //more buying than selling means its a sellers market
      if FBidSize > FAskSize then
        FMarketType := mtSellers
      else if FBidSize < FAskSize then
        FMarketType := mtBuyers
      else
        FMarketType := mtUnknown;

      Result := True;
    finally
      LJSON.Free;
    end;
  except on E: Exception do
    Error := E.Message;
  end;
end;

function TGDAXBookImpl.GetAskList: TGDAXBookEntryList;
begin
  Result := FAskList;
end;

function TGDAXBookImpl.GetAskSize: Single;
begin
  Result := FAskSize;
end;

function TGDAXBookImpl.GetBidList: TGDAXBookEntryList;
begin
  Result := FBidList;
end;

function TGDAXBookImpl.GetBidSize: Single;
begin
  Result := FBidSize;
end;

function TGDAXBookImpl.GetEndpoint(Const AOperation: TRestOperation): string;
begin
  if AOperation=roGet then
    Result := Format(GDAX_END_API_BOOK,[FProduct.ID,Ord(FLevel)]);
end;

function TGDAXBookImpl.GetLevel: TGDAXBookLevel;
begin
  Result := FLevel;
end;

function TGDAXBookImpl.GetMarketType: TMarketType;
begin
  Result := FMarketType;
end;

function TGDAXBookImpl.GetProduct: IGDAXProduct;
begin
  Result := FProduct;
end;

procedure TGDAXBookImpl.SetLevel(Const Value: TGDAXBookLevel);
begin
  ClearMetaData;
  FLevel := Value;
end;

procedure TGDAXBookImpl.SetProduct(Const Value: IGDAXProduct);
begin
  ClearMetaData;
  FProduct := Value;
end;

end.
