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

unit gdax.api.fills;

{$i gdax.inc}

interface
uses
  Classes, gdax.api, gdax.api.consts, gdax.api.types;
type

  { TGDAXFillsImpl }

  TGDAXFillsImpl = class(TGDAXPagedApi,IGDAXFills)
  private
    FEntries: TFillEntryArray;
    FOrderID: String;
    FProductID: String;
    function GetCount: Cardinal;
    function GetEntries: TFillEntryArray;
    function GetOrderID: String;
    function GetPaged: IGDAXPaged;
    function GetProductID: String;
    procedure SetOrderID(Const Value: String);
    function BuildQueryParams:String;
    function GetTotalSize(Const ASides: TOrderSides): Extended;
    function GetTotalPrice(Const ASides: TOrderSides): Extended;
    function GetTotalFees(Const ASides: TOrderSides): Extended;
    procedure SetProductID(Const AValue: String);
  protected
    function DoGetSupportedOperations: TRestOperations; override;
    function GetEndpoint(Const AOperation: TRestOperation): string; override;
    function DoLoadFromJSON(Const AJSON: string;
      out Error: string): Boolean;override;
    function DoMove(Const ADirection: TGDAXPageDirection; out Error: String;
      Const ALastBeforeID, ALastAfterID: Integer;
      Const ALimit: TPageLimit=0): Boolean; override;
  public
    property Paged: IGDAXPaged read GetPaged;
    property Entries: TFillEntryArray read GetEntries;
    property Count: Cardinal read GetCount;
    property OrderID: String read GetOrderID write SetOrderID;
    property ProductID: String read GetProductID write SetProductID;
    property TotalSize[Const ASides:TOrderSides]: Extended read GetTotalSize;
    property TotalPrice[Const ASides:TOrderSides]: Extended read GetTotalPrice;
    property TotalFees[Const ASides:TOrderSides]: Extended read GetTotalFees;
    procedure ClearEntries;
    constructor Create; override;
  end;
implementation
uses
  SynCrossPlatformJSON, SysUtils;

{ TGDAXFillsImpl }

function TGDAXFillsImpl.BuildQueryParams: String;
begin
  Result:='';

  //as of 8/23/18 empty call to fills is deprecated, but cb pro will report error
  if (Trim(FOrderID).Length + Trim(FProductID).Length)<1 then
    Exit;

  Result:='?';
  //if requesting a specific order id (prioritize this)
  if Trim(FOrderID).Length>0 then
    Result:=Result + TFillEntry.PROP_ORDER + '=' + FOrderID
  //append product id filter
  else
    Result:=Result + TFillEntry.PROP_PROD +'=' + FProductID;

  //only append moving parameters if we have any
  if not GetMovingParameters.IsEmpty then
  begin
    //we have to check if we are being requested to "move" via paged
    if Result.Length > 1 then
      Result:=Result + '&' + GetMovingParameters
    else
      Result:=Result + GetMovingParameters;
  end;
end;

constructor TGDAXFillsImpl.Create;
begin
  inherited;
  FOrderID:='';
  FProductID:='';
end;

function TGDAXFillsImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXFillsImpl.DoLoadFromJSON(Const AJSON: string; out Error: string): Boolean;
var
  LJSON:TJSONVariantData;
  I: Integer;
begin
  Result:=False;
  try
    //clear fill entries
    SetLength(FEntries,0);
    //determine if we can load the array
    if not LJSON.FromJSON(AJSON) then
    begin
      Error:=E_BADJSON;
      Exit;
    end;
    //determine if we are an array
    if not (LJSON.Kind = jvArray) then
    begin
      Error:=Format(E_BADJSON_PROP,['main fills array']);
      Exit;
    end;
    //deserialize fill entries
    for I := 0 to Pred(LJSON.Count) do
    begin
      SetLength(FEntries,Succ(Length(FEntries)));
      FEntries[High(FEntries)]:=TFillEntry.Create(LJSON.Item[I]);
    end;
    Result:=True;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TGDAXFillsImpl.DoMove(Const ADirection: TGDAXPageDirection; out
  Error: String; Const ALastBeforeID, ALastAfterID: Integer;
  Const ALimit: TPageLimit): Boolean;
var
  LEntries:TFillEntryArray;
  I,J:Integer;
begin
  SetLength(LEntries,0);
  if Length(FEntries)>0 then
    LEntries:=FEntries;
  Result:=inherited DoMove(ADirection, Error, ALastBeforeID, ALastAfterID,ALimit);
  if not Result then
    Exit;
  //only if we have a local array that needs to be appended somewhere do we
  //do this logic
  if (Length(LEntries)>0) then
  begin
    //use length because we want the index "after" the highest entry
    I:=Length(LEntries);
    SetLength(LEntries,Length(LEntries)+Length(FEntries));
    if ADirection=pdBefore then
    begin
      if Length(FEntries)>0 then
      begin
        //slide old entries ahead of new entries
        for J:=0 to High(LEntries) - I do
          LEntries[I + J]:=LEntries[J];
        //now move new entries to start
        for J:=0 to High(FEntries) do
          LEntries[J]:=FEntries[J];
      end;
      //lastly, assign our merged array to private var
      FEntries:=LEntries;
    end
    else
    begin
      //move new entries to end and assign to private var
      if Length(FEntries)>0 then
        for J:=0 to High(FEntries) do
          LEntries[I + J]:=FEntries[J];
      FEntries:=LEntries;
    end;
  end;
end;

procedure TGDAXFillsImpl.ClearEntries;
begin
  SetLength(FEntries,0);
end;

function TGDAXFillsImpl.GetEndpoint(Const AOperation: TRestOperation): string;
begin
  Result:='';
  if AOperation=roGet then
    Result:=GDAX_END_API_FILLS+BuildQueryParams;
end;

function TGDAXFillsImpl.GetOrderID: String;
begin
  Result:=FOrderID;
end;

function TGDAXFillsImpl.GetEntries: TFillEntryArray;
begin
  Result:=FEntries;
end;

function TGDAXFillsImpl.GetCount: Cardinal;
begin
  Result:=Length(FEntries);
end;

function TGDAXFillsImpl.GetPaged: IGDAXPaged;
begin
  Result:=Self as IGDAXPaged;
end;

function TGDAXFillsImpl.GetProductID: String;
begin
  Result:=FProductID;
end;

function TGDAXFillsImpl.GetTotalFees(Const ASides: TOrderSides): Extended;
var
  I: Integer;
begin
  Result:=0;
  for I := 0 to High(FEntries) do
    if FEntries[I].Side in ASides then
      Result:=Result + FEntries[I].Fee;
end;

procedure TGDAXFillsImpl.SetProductID(Const AValue: String);
begin
  FProductID:=AValue;
end;

function TGDAXFillsImpl.GetTotalPrice(Const ASides: TOrderSides): Extended;
var
  I: Integer;
begin
  Result:=0;
  for I := 0 to High(FEntries) do
    if FEntries[I].Side in ASides then
      Result:=Result + FEntries[I].Price;
end;

function TGDAXFillsImpl.GetTotalSize(Const ASides: TOrderSides): Extended;
var
  I: Integer;
begin
  Result:=0;
  for I := 0 to High(FEntries) do
    if FEntries[I].Side in ASides then
      Result:=Result + FEntries[I].Size;
end;

procedure TGDAXFillsImpl.SetOrderID(Const Value: String);
begin
  FOrderID:=Value;
end;

end.
