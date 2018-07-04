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

unit gdax.api.authenticator;

{$i gdax.inc}

interface
uses
  Classes, SysUtils, gdax.api.consts, gdax.api.types;

type

  { TGDAXAuthenticatorImpl }

  TGDAXAuthenticatorImpl = class(TInterfacedObject,IGDAXAuthenticator)
  strict private
    FKey: String;
    FPass: String;
    FSecret: String;
    FTime: IGDAXTime;
    FUseLocalTime: Boolean;
    FMode: TGDAXApi;
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
  strict protected
    procedure DoBuildHeaders(Const AOutput:TStrings;Const ASignature:String;
      Const AEpoch:Integer);virtual;
  public
    property Key: String read GetKey write SetKey;
    property Secret: String read GetSecret write SetSecret;
    property Passphrase: String read GetPassphrase write SetPassphrase;
    (*
      when true, this machine's time will be used when HMAC signing to
      save a request to GDAX's time endpoint
    *)
    property UseLocalTime: Boolean read GetUseLocalTime write SetUseLocalTime;
    property Mode: TGDAXApi read GetMode write SetMode;
    procedure BuildHeaders(Const AOutput:TStrings;Const ASignature:String;
      Const AEpoch:Integer);
    function GenerateAccessSignature(Const AOperation:TRestOperation;
      Const ARequestPath:String;Out Epoch:Integer;Const ARequestBody:String=''):String;
    constructor Create;virtual;
    destructor Destroy; override;
  end;
implementation
uses
  DateUtils, SynCommons, SbpBase64, gdax.api.time, HlpIHashInfo, HlpConverters,
  HlpHashFactory;
{ TGDAXAuthenticatorImpl }

procedure TGDAXAuthenticatorImpl.BuildHeaders(const AOutput: TStrings;
  const ASignature: String;const AEpoch:Integer);
begin
  DoBuildHeaders(AOutput,ASignature,AEpoch);
end;

constructor TGDAXAuthenticatorImpl.Create;
begin
  FTime:=TGDAXTimeImpl.Create;
  FTime.Authenticator:=Self;
  FUseLocalTime:=True;
end;

destructor TGDAXAuthenticatorImpl.Destroy;
begin
  FTime:=nil;
  inherited;
end;

function TGDAXAuthenticatorImpl.GetKey: String;
begin
  Result:=FKey;
end;

function TGDAXAuthenticatorImpl.GetMode: TGDAXApi;
begin
  Result:=FMode;
end;

function TGDAXAuthenticatorImpl.GetPassphrase: String;
begin
  Result:=FPass;
end;

function TGDAXAuthenticatorImpl.GetSecret: String;
begin
  Result:=FSecret;
end;

function TGDAXAuthenticatorImpl.GetTime: IGDAXTime;
begin
  Result:=FTime;
end;

function TGDAXAuthenticatorImpl.GetUseLocalTime: Boolean;
begin
  Result:=FUseLocalTime;
end;

procedure TGDAXAuthenticatorImpl.SetKey(AValue: String);
begin
  FKey:=AValue;
end;

procedure TGDAXAuthenticatorImpl.SetMode(AValue: TGDAXApi);
begin
  FMode:=AValue;
end;

procedure TGDAXAuthenticatorImpl.SetPassphrase(AValue: String);
begin
  FPass:=AValue;
end;

procedure TGDAXAuthenticatorImpl.SetSecret(AValue: String);
begin
  FSecret:=AValue;
end;

procedure TGDAXAuthenticatorImpl.SetUseLocalTime(AValue: Boolean);
begin
  FUseLocalTime:=AValue;
end;

procedure TGDAXAuthenticatorImpl.DoBuildHeaders(const AOutput: TStrings;
  const ASignature: String;const AEpoch:Integer);
begin
  AOutput.Clear;
  AOutput.NameValueSeparator:=':';
  AOutput.Add('%s: %s',['Connection','keep-alive']);
  AOutput.Add('%s: %s',['Content-Type','application/json']);
  AOutput.Add('%s: %s',['User-Agent',USER_AGENT_MOZILLA]);
  AOutput.Add('%s: %s',[CB_ACCESS_KEY,FKey]);
  AOutput.Add('%s: %s',[CB_ACCESS_SIGN,ASignature]);
  AOutput.Add('%s: %s',[CB_ACCESS_TIME,IntToStr(AEpoch)]);
  AOutput.Add('%s: %s',[CB_ACCESS_PASS,FPass]);
end;

function TGDAXAuthenticatorImpl.GenerateAccessSignature(
  const AOperation: TRestOperation; const ARequestPath: String;
  Out Epoch:Integer;const ARequestBody: String): String;
var
  LContent:String;
  LError:String;
  LMessage:String;
  LHMAC:IHMAC;
begin
  //https://docs.gdax.com/#creating-a-request
  Result:='';
  LHMAC:=THashFactory.THMAC.CreateHMAC(THashFactory.TCrypto.CreateSHA2_256);
  if not FUseLocalTime then
  begin
    if not FTime.Get(LContent,LError) then
      raise Exception.Create(LError);
    Epoch:=Trunc(FTime.Epoch);
  end
  else
    Epoch := DateTimeToUnix(LocalTimeToUniversal(Now));
  LMessage:=IntToStr(Trunc(Epoch));
  //then append the operation
  case AOperation of
    roGet: LMessage:=LMessage+OP_GET;
    roPost: LMessage:=LMessage+OP_POST;
    roDelete: LMessage:=LMessage+OP_DELETE;
  end;
  //now add the request path
  LMessage:=Trim(LMessage+ARequestPath);
  //now if there is a body, add it
  if AOperation=roPost then
    LMessage:=LMessage+Trim(ARequestBody);
  //decode the base64 encoded secret and record to key
  LHMAC.Key:=TBase64.Default.Decode(
    String(
      TEncoding.UTF8.GetString(
        TConverters.ConvertStringToBytes(FSecret, TEncoding.UTF8)
      )
    )
  );
  //using decoded key and message, sign using HMAC
  Result:=TBase64.Default.Encode(
    LHMAC.ComputeString(LMessage, TEncoding.UTF8).GetBytes()
  );
end;

end.
