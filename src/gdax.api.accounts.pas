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

unit gdax.api.accounts;

{$i gdax.inc}

interface
uses
  Classes, gdax.api.consts, gdax.api, gdax.api.types;
type

  { TGDAXAccountLedgerImpl }

  TGDAXAccountLedgerImpl = class(TGDAXPagedApi,IGDAXAccountLedger)
  strict private
    FID: String;
    FEntries: TLedgerEntryArray;
    function GetAcctID: String;
    function GetCount: Cardinal;
    function GetEntries: TLedgerEntryArray;
    function GetPaged: IGDAXPaged;
    procedure SetAcctID(Const Value: String);
  strict protected
    function DoGet(Const AEndpoint: string; Const AHeaders: TStrings; out
      Content: String; out Error: string): Boolean; override;
    function DoLoadFromJSON(Const AJSON: string; out Error: string): Boolean;override;
    function DoMove(Const ADirection: TGDAXPageDirection; out Error: String;
      Const ALastBeforeID, ALastAfterID: Integer;
      Const ALimit: TPageLimit=0): Boolean; override;
    function GetEndpoint(Const AOperation: TRestOperation): string; override;
    function DoGetSupportedOperations: TRestOperations; override;
  public
    property AcctID: String read GetAcctID write SetAcctID;
    property Paged: IGDAXPaged read GetPaged;
    property Entries: TLedgerEntryArray read GetEntries;
    property Count: Cardinal read GetCount;
    procedure ClearEntries;
  end;

  TGDAXAccountImpl = class(TGDAXRestApi,IGDAXAccount)
  strict private
    FID: String;
    FCurrency: String;
    FBalance: Extended;
    FHolds: Extended;
    FAvailable: Extended;
    function GetAcctID: String;
    procedure SetAcctID(Const AValue: String);
    function GetCurrency: String;
    procedure SetCurrency(Const AValue: String);
    function GetBalance: Extended;
    procedure SetBalance(Const AValue: Extended);
    function GetHolds: Extended;
    procedure SetHolds(Const AValue: Extended);
    function GetAvailable: Extended;
    procedure SetAvailable(Const AValue: Extended);
  strict protected
    function DoGetSupportedOperations: TRestOperations; override;
    function GetEndpoint(Const AOperation: TRestOperation): string; override;
    function DoLoadFromJSON(Const AJSON: string; out Error: string): Boolean;
      override;
  public
    property AcctID: String read GetAcctID write SetAcctID;
    property Currency: String read GetCurrency write SetCurrency;
    /// <summary>
    ///   total funds in the account
    /// </summary>
    property Balance: Extended read GetBalance write SetBalance;
    /// <summary>
    ///   funds on hold (not available for use)
    /// </summary>
    property Holds: Extended read GetHolds write SetHolds;
    /// <summary>
    ///   funds available to withdraw* or trade
    /// </summary>
    property Available: Extended read GetAvailable write SetAvailable;
  end;

  { TGDAXAccountsImpl }

  TGDAXAccountsImpl = class(TGDAXRestApi,IGDAXAccounts)
  strict private
    FAccounts: TGDAXAccountList;
    function GetAccounts: TGDAXAccountList;
  strict protected
    function DoGetSupportedOperations: TRestOperations; override;
    function GetEndpoint(Const AOperation: TRestOperation): string; override;
    function DoLoadFromJSON(Const AJSON: string;
      out Error: string): Boolean;override;
  public
    property Accounts : TGDAXAccountList read GetAccounts;
    constructor Create; override;
    destructor Destroy; override;
  end;
implementation
uses
  SysUtils,
  fpjson,
  jsonparser;

{ TGDAXAccountImpl }

function TGDAXAccountImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXAccountImpl.DoLoadFromJSON(Const AJSON: string;
  out Error: string): Boolean;
var
  LJSON:TJSONObject;
begin
  Result := False;

  //try and parse
  LJSON := TJSONObject(GetJSON(AJSON));
  try
    if not Assigned(LJSON) then
    begin
      Error := E_BADJSON;
      Exit;
    end;

    //extract id from json
    if LJSON.Find('id') <> nil then
    begin
      Error := Format(E_BADJSON_PROP, ['id']);
      Exit;
    end
    else
      FID := LJSON.Get('id');

    //extract balance from json
    if LJSON.Find('balance') <> nil then
    begin
      Error := Format(E_BADJSON_PROP,['balance']);
      Exit;
    end
    else
      FBalance := StrToFloatDef(LJSON.Get('balance'),0);

    //extract holds from json
    if LJSON.Find('hold') <> nil then
    begin
      Error := Format(E_BADJSON_PROP,['hold']);
      Exit;
    end
    else
      FHolds := StrToFloatDef(LJSON.Get('hold'),0);

    //extract available from json
    if LJSON.Find('available') <> nil then
    begin
      Error := Format(E_BADJSON_PROP,['available']);
      Exit;
    end
    else
      FAvailable := StrToFloatDef(LJSON.Get('available'),0);

    //extract currency from json
    if LJSON.Find('currency') <> nil then
    begin
      Error := Format(E_BADJSON_PROP,['currency']);
      Exit;
    end
    else
      FCurrency := LJSON.Get('currency');

    Result := True;
  finally
    LJSON.Free;
  end;
end;

function TGDAXAccountImpl.GetAcctID: String;
begin
  Result := FID;
end;

function TGDAXAccountImpl.GetAvailable: Extended;
begin
  Result := FAvailable;
end;

function TGDAXAccountImpl.GetBalance: Extended;
begin
  Result := FBalance;
end;

function TGDAXAccountImpl.GetCurrency: String;
begin
  Result := FCurrency;
end;

function TGDAXAccountImpl.GetEndpoint(Const AOperation: TRestOperation): string;
begin
  Result:='';
  if AOperation = roGet then
    Result := Format(GDAX_END_API_ACCT,[FID]);
end;

function TGDAXAccountImpl.GetHolds: Extended;
begin
  Result := FHolds;
end;

procedure TGDAXAccountImpl.SetAcctID(Const AValue: String);
begin
  FID := AValue;
end;

procedure TGDAXAccountImpl.SetAvailable(Const AValue: Extended);
begin
  FAvailable := AValue;
end;

procedure TGDAXAccountImpl.SetBalance(Const AValue: Extended);
begin
  FBalance := AValue;
end;

procedure TGDAXAccountImpl.SetCurrency(Const AValue: String);
begin
  FCurrency := AValue;
end;

procedure TGDAXAccountImpl.SetHolds(Const AValue: Extended);
begin
  FHolds := AValue;
end;

{ TGDAXAccountsImpl }

constructor TGDAXAccountsImpl.Create;
begin
  inherited;
  FAccounts := TGDAXAccountList.Create;
end;

destructor TGDAXAccountsImpl.Destroy;
begin
  FAccounts.Free;
  inherited;
end;

function TGDAXAccountsImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXAccountsImpl.DoLoadFromJSON(Const AJSON: string;
  out Error: string): Boolean;
var
  LJSON: TJSONArray;
  I: Integer;
  LAcct: IGDAXAccount;
begin
  Result := False;
  try
    FAccounts.Clear;

    LJSON := TJSONArray(GetJSON(AJSON));

    if not Assigned(LJSON) then
      raise Exception.Create(E_BADJSON);

    try
      //iterate items
      for I := 0 to Pred(LJSON.Count) do
      begin
        LAcct := TGDAXAccountImpl.Create;
        //if we can't load this via json, then terminate
        if not LAcct.LoadFromJSON(
            LJSON.Items[I].AsJSON,
            Error
          )
        then
        begin
          Error := Format(E_BADJSON_PROP,['account index:'+IntToStr(I)]);
          Exit;
        end;
        //otherwise we can add this to our list
        FAccounts.Add(LAcct);
      end;
      Result := True;

    finally
      LJSON.Free;
    end;
  except on E: Exception do
    Error := E.Message;
  end;
end;

function TGDAXAccountsImpl.GetAccounts: TGDAXAccountList;
begin
  Result := FAccounts;
end;

function TGDAXAccountsImpl.GetEndpoint(Const AOperation: TRestOperation): string;
begin
  Result := GDAX_END_API_ACCTS;
end;

{ TGDAXAccountLedgerImpl }

function TGDAXAccountLedgerImpl.DoLoadFromJSON(Const AJSON: string;
  out Error: string): Boolean;
var
  I : Integer;
  LJSON : TJSONArray;
  LEntryJSON : String;
  LEntry : TLedgerEntry;
begin
  Result := False;
  try
    //clear entries on load
    SetLength(FEntries,0);
    LJSON := TJSONArray(GetJSON(AJSON));

    if not Assigned(LJSON) then
      raise Exception.Create(E_BADJSON);

    try
      //for all of the records returned, build a new ledger entry from json
      for I := 0 to Pred(LJSON.Count) do
      begin
        SetLength(FEntries, Succ(Length(FEntries)));
        LEntryJSON := LJSON.Items[I].AsJSON;
        LEntry := TLedgerEntry.Create(LEntryJSON);
        FEntries[High(FEntries)]:=LEntry;
      end;

      Result := True;
    finally
      LJSON.Free;
    end;
  except on E: Exception do
    Error := E.Message;
  end;
end;

function TGDAXAccountLedgerImpl.DoMove(Const ADirection: TGDAXPageDirection;
  out Error: String; Const ALastBeforeID, ALastAfterID: Integer;
  Const ALimit: TPageLimit): Boolean;
var
  LEntries:TLedgerEntryArray;
  I,J:Integer;
begin
  //noting here in case someone runs across this (or I forget) but this method
  //doesn't take into account possible duplicates being added to entries.
  //a caller can request to move forward, which sets page identifiers, then
  //request to move backwards from the last recorded spot (which result in
  //re-adding entries), perhaps will change later to account for this, but
  //as of now, not a big deal since caller can also specifically before and
  //after specific id's
  SetLength(LEntries,0);

  if Length(FEntries)>0 then
    LEntries := FEntries;

  Result := inherited DoMove(ADirection, Error, ALastBeforeID, ALastAfterID,ALimit);

  if not Result then
    Exit;

  //only if we have a local array that needs to be appended somewhere do we
  //do this logic
  if (Length(LEntries)>0) then
  begin
    //use length because we want the index "after" the highest entry
    I := Length(LEntries);
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
          LEntries[J] := FEntries[J];
      end;

      //lastly, assign our merged array to private var
      FEntries := LEntries;
    end
    else
    begin
      //move new entries to end and assign to private var
      if Length(FEntries)>0 then
        for J:=0 to High(FEntries) do
          LEntries[I + J]:=FEntries[J];

      FEntries := LEntries;
    end;
  end;
end;

function TGDAXAccountLedgerImpl.GetAcctID: String;
begin
  Result := FID;
end;

function TGDAXAccountLedgerImpl.GetCount: Cardinal;
begin
  Result := Length(FEntries);
end;

function TGDAXAccountLedgerImpl.GetEntries: TLedgerEntryArray;
begin
  Result := FEntries;
end;

function TGDAXAccountLedgerImpl.GetPaged: IGDAXPaged;
begin
  Result := Self as IGDAXPaged;
end;

function TGDAXAccountLedgerImpl.GetEndpoint(
  Const AOperation: TRestOperation): string;
var
  LMoving:String;
begin
  Result:='';
  //since this is a paged endpoint, we need to check for any move requests
  //made by caller
  LMoving := GetMovingParameters;
  if not LMoving.IsEmpty then
    LMoving:='?'+LMoving;
  if AOperation=roGet then
    Result := Format(GDAX_END_API_ACCT_HIST,[FID])+LMoving;
end;

function TGDAXAccountLedgerImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

procedure TGDAXAccountLedgerImpl.ClearEntries;
begin
  SetLength(FEntries,0);
end;

procedure TGDAXAccountLedgerImpl.SetAcctID(Const Value: String);
begin
  FID := Value;
end;

function TGDAXAccountLedgerImpl.DoGet(Const AEndpoint: string;
  Const AHeaders: TStrings; out Content: String; out Error: string): Boolean;
begin
  if FID.IsEmpty then
  begin
    Error := Format(E_INVALID,['account id','a valid identifier']);
    Exit;
  end;
  Result := inherited DoGet(AEndpoint, AHeaders, Content, Error);
end;

end.
