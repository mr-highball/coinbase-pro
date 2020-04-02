unit gdax.api.currencies;

{$i gdax.inc}

interface

uses
  Classes, SysUtils, gdax.api.consts, gdax.api, gdax.api.types;
type

  { TGDAXCurrenciesImpl }

  TGDAXCurrenciesImpl = class(TGDAXRestApi,IGDAXCurrencies)
  strict private
    FCurrencies: TCurrencyArray;
  protected
    function GetCount: Cardinal;
    function GetCurrencies: TCurrencyArray;
  strict protected
    function GetEndpoint(Const AOperation: TRestOperation): String; override;
    function DoGetSupportedOperations: TRestOperations; override;
    function DoLoadFromJSON(Const AJSON: String;
      out Error: String): Boolean;override;
  public
    property Currencies : TCurrencyArray read GetCurrencies;
    property Count : Cardinal read GetCount;
  end;

implementation
uses
  fpjson,
  jsonparser;

{ TGDAXCurrenciesImpl }

function TGDAXCurrenciesImpl.GetCount: Cardinal;
begin
  Result := Length(FCurrencies);
end;

function TGDAXCurrenciesImpl.GetCurrencies: TCurrencyArray;
begin
  Result := FCurrencies;
end;

function TGDAXCurrenciesImpl.GetEndpoint(Const AOperation: TRestOperation): String;
begin
  Result:='';
  if AOperation=roGet then
    Result := GDAX_END_API_CURRENCIES;
end;

function TGDAXCurrenciesImpl.DoGetSupportedOperations: TRestOperations;
begin
  Result:=[roGet];
end;

function TGDAXCurrenciesImpl.DoLoadFromJSON(Const AJSON: String; out
  Error: String): Boolean;
var
  I : Integer;
  LJSON : TJSONArray;
  LCurrency : TCurrency;
begin
  Result := False;
  try
    //clear old entries
    SetLength(FCurrencies,0);
    LJSON := TJSONArray(GetJSON(AJSON));

    if not Assigned(LJSON) then
      raise Exception.Create(E_BADJSON);

    try
      //iterate and load currencies by json
      for I:=0 to Pred(LJSON.Count) do
      begin
        LCurrency := TCurrency.Create(LJSON.Items[I].AsJSON);
        SetLength(FCurrencies, Succ(Length(FCurrencies)));
        FCurrencies[High(FCurrencies)]:=LCurrency;
      end;

      Result := True;
    finally
      LJSON.Free;
    end;
  except on E:Exception do
    Error := E.Message;
  end;
end;

end.

