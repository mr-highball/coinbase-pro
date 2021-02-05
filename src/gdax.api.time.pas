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

unit gdax.api.time;

interface
uses
  Classes,gdax.api.types,gdax.api,gdax.api.consts;
type

  { TGDAXTimeImpl }

  TGDAXTimeImpl = class(TGDAXRestApi,IGDAXTime)
  public
    const
      PROP_ISO = 'iso';
      PROP_EPOCH = 'epoch';
  strict private
    FISO: String;
    FEpoch: Extended;
  protected
    function GetEpoch: Extended;
    function GetISO: String;
    procedure SetEpoch(Const AValue: Extended);
    procedure SetISO(Const AValue: String);
  strict protected
    function DoGetSupportedOperations: TRestOperations; override;
    function GetHeadersForOperation(Const AOperation: TRestOperation;
      Const AHeaders: TStrings; out Error: String): Boolean; override;
    function GetEndpoint(Const AOperation: TRestOperation): String; override;
    function DoLoadFromJSON(Const AJSON: String;
      out Error: String): Boolean;override;
  public
    property ISO: String read GetISO write SetISO;
    property Epoch: Extended read GetEpoch write SetEpoch;
  end;
implementation
uses
  DateUtils,
  SysUtils,
  fpjson,
  jsonparser;

{ TGDAXTimeImpl }

function TGDAXTimeImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXTimeImpl.GetHeadersForOperation(Const AOperation: TRestOperation;
  Const AHeaders: TStrings; out Error: String): Boolean;
begin
  Result := False;
  try
    //to avoid circular dependency between authenticator and time,
    //we put the minimal headers here
    AHeaders.Add('%s=%s',['Content-Type','application/json']);
    AHeaders.Add('%s=%s',['User-Agent',USER_AGENT_MOZILLA]);
    Result := True;
  except on E:Exception do
    Error := E.Message;
  end;
end;

function TGDAXTimeImpl.DoLoadFromJSON(Const AJSON: String;
  out Error: String): Boolean;
var
  LJSON : TJSONObject;
begin
  Result := False;

  try
    LJSON := TJSONObject(GetJSON(AJSON));

    if not Assigned(LJSON) then
      raise Exception.Create(E_BADJSON);

    try
      if not Assigned(LJSON) then
      begin
        Error := E_BADJSON;
        Exit;
      end;

      if LJSON.Find(PROP_ISO) = nil then
      begin
        Error := E_BADJSON;
        Exit;
      end;
      FISO := LJSON.Get(PROP_ISO);
      if LJSON.Find(PROP_EPOCH) = nil then
      begin
        Error := E_BADJSON;
        Exit;
      end;
      FEpoch := LJSON.Get(PROP_EPOCH);
      Result := True;

    finally
      LJSON.Free;
    end;
  except on E: Exception do
    Error := E.Message;
  end;
end;

function TGDAXTimeImpl.GetEndpoint(Const AOperation: TRestOperation): String;
begin
  Result := GDAX_END_API_TIME;
end;

function TGDAXTimeImpl.GetEpoch: Extended;
begin
  Result := FEpoch;
end;

function TGDAXTimeImpl.GetISO: String;
begin
  Result := FISO;
end;

procedure TGDAXTimeImpl.SetEpoch(Const AValue: Extended);
begin
  FEpoch := AValue;
end;

procedure TGDAXTimeImpl.SetISO(Const AValue: String);
begin
  FISO := AValue;
end;

end.
