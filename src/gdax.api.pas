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

unit gdax.api;

{$i gdax.inc}

interface
uses
  Classes, SysUtils, gdax.api.consts, gdax.api.types,
  {$IFDEF FPC}
  internetaccess
  {$ELSE}
  //could probably use internetaccess, but need to check. if so,
  //fpc class could just be used for delphi and should just "work"
  System.Net.HttpClientComponent
  {$ENDIF};
type

  { TBaseGDAXRestApiImpl }

  TBaseGDAXRestApiImpl = class(TInterfacedObject,IGDAXRestAPI)
  strict private
    FAuthenticator:IGDAXAuthenticator;
  protected
    function GetAuthenticator: IGDAXAuthenticator;
    function GetPostBody: String;
    function GetSupportedOperations: TRestOperations;
    procedure SetAuthenticator(Const AValue: IGDAXAuthenticator);
    function GetEndpoint(Const AOperation:TRestOperation) : String;virtual;abstract;
    function GetHeadersForOperation(Const AOperation:TRestOperation;
      Const AHeaders:TStrings;Out Error:String):Boolean;virtual;
    function DoDelete(Const AEndpoint:String;Const AHeaders:TStrings;
      Out Content:String;Out Error:String):Boolean;virtual;abstract;
    function DoGet(Const AEndpoint:String;Const AHeaders:TStrings;
      Out Content:String;Out Error:String):Boolean;virtual;abstract;
    function DoPost(Const AEndPoint:String;Const AHeaders:TStrings;Const ABody:String;
      Out Content:String;Out Error:String):Boolean;virtual;abstract;
    function DoGetSupportedOperations:TRestOperations;virtual;abstract;
    function DoGetPostBody:String;virtual;
    function DoGetSuccess(Const AHTTPStatusCode:Integer;Out Error:String):Boolean;virtual;
    function DoLoadFromJSON(Const AJSON:String;Out Error:String):Boolean;virtual;
  public
    property SupportedOperations: TRestOperations read GetSupportedOperations;
    property Authenticator: IGDAXAuthenticator read GetAuthenticator write SetAuthenticator;
    property PostBody : String read GetPostBody;
    function Post(Out Content:String;Out Error:String):Boolean;
    function Get(Out Content:String;Out Error:String):Boolean;
    function Delete(Out Content:String;Out Error:String):Boolean;
    function LoadFromJSON(Const JSON:String;Out Error:String):Boolean;
    constructor Create;virtual;
    destructor Destroy; override;
  end;
  (*
    meta class for gdax base
  *)
  TBaseGDAXRestApiImplClass = class of TBaseGDAXRestApiImpl;

  {$IFDEF FPC}
  (*
    free pascal implementation of a base gdax api
  *)

  { TFPCRestAPI }

  TFPCRestAPI = class(TBaseGDAXRestApiImpl)
  strict private
    procedure TransferReaction(sender: TInternetAccess;
      var method: string; var url: TDecodedUrl;
      var data: TInternetAccessDataBlock;
      var reaction: TInternetAccessReaction);
  strict protected
    function DoDelete(Const AEndpoint: string; Const AHeaders: TStrings;
      Out Content:String;out Error: string): Boolean; override;
    function DoPost(Const AEndPoint: string; Const AHeaders: TStrings;
      Const ABody: string; Out Content:String;out Error: string): Boolean; override;
    function DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
      Out Content:String;out Error: string): Boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;
  {$ELSE}
  (*
    delphi rest api will most likely need some overhauling to even compile,
    have not tested...
  *)
  TDelphiRestAPI = class(TBaseGDAXRestApiImpl)
  strict private
    FClient: TNetHTTPClient;
  strict protected
    function DoDelete(Const AEndpoint: string; Const AHeaders: TStrings;
      Out Content:String;out Error: string): Boolean; override;
    function DoPost(Const AEndPoint: string; Const AHeaders: TStrings;
      Const ABody: string; Out Content:String;out Error: string): Boolean; override;
    function DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
      Out Content:String;out Error: string): Boolean; override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;
  {$ENDIF}
  (*
    actual base class depending on compiler for api endpoints
  *)
  TGDAXRestApi =
    {$IFDEF FPC}
    TFPCRestAPI
    {$ELSE}
    TDelphiRestAPI
    {$ENDIF};

  { TGDAXPagedApi }
  (*
    for endpoints that are paged, inherit from this base class
  *)
  TGDAXPagedApi = class(TGDAXRestApi,IGDAXPaged)
  strict private
    FLastAfterID:Integer;
    FLastBeforeID:Integer;
    FMoving:Boolean;
    FMovingParams:String;
    procedure ExtractPageIDs(Const AHeaders:TStrings);
  protected
    function GetLastAfterID: Integer;
    function GetLastBeforeID: Integer;
  strict protected
    function DoMove(Const ADirection:TGDAXPageDirection;Out Error:String;
      Const ALastBeforeID,ALastAfterID:Integer;
      Const ALimit:TPageLimit=0):Boolean;virtual;
    function DoGet(Const AEndpoint: string; Const AHeaders: TStrings; out
      Content: String; out Error: string): Boolean; override;
    function GetMovingParameters:String;
  public
    property LastBeforeID:Integer read GetLastBeforeID;
    property LastAfterID:Integer read GetLastAfterID;
    function Move(Const ADirection:TGDAXPageDirection;Out Error:String;
      Const ALastBeforeID,ALastAfterID:Integer;
      Const ALimit:TPageLimit=0):Boolean;overload;
    function Move(Const ADirection:TGDAXPageDirection;
      Const ALimit:TPageLimit=0):Boolean;overload;
    function Move(Const ADirection:TGDAXPageDirection;Out Error:String;
      Const ALimit:TPageLimit=0):Boolean;overload;
  end;

implementation
uses
  {$IFDEF FPC}
    {$IFDEF MSWINDOWS}
    w32internetaccess
    {$ELSE}
      {$IFDEF ANDROID}
      androidinternetaccess
      {$ELSE}
      synapseinternetaccess
      {$ENDIF}
    {$ENDIF}
  {$ELSE}
  System.Generics.Collections, System.Net.UrlClient, System.Net.HttpClient
  {$ENDIF};

{ TGDAXPagedApi }

function TGDAXPagedApi.GetLastAfterID: Integer;
begin
  Result:=FLastAfterID;
end;

function TGDAXPagedApi.GetLastBeforeID: Integer;
begin
  Result:=FLastBeforeID
end;

procedure TGDAXPagedApi.ExtractPageIDs(Const AHeaders: TStrings);
var
  I:Integer;
begin
  //find if we have before cursor
  I:=AHeaders.IndexOfName(CB_BEFORE);
  if I>=0 then
    FLastBeforeID:=StrToIntDef(AHeaders.ValueFromIndex[I],0)
  //if no before cursor, we won't have an after
  else
    Exit;
  //now look for after cursor
  I:=AHeaders.IndexOfName(CB_AFTER);
  if I>=0 then
    FLastAfterID:=StrToIntDef(AHeaders.ValueFromIndex[I],0);
end;

function TGDAXPagedApi.DoMove(Const ADirection: TGDAXPageDirection;out Error: String;
  Const ALastBeforeID,ALastAfterID:Integer;
  Const ALimit: TPageLimit): Boolean;
var
  LContent:String;
begin
  Result:=False;
  try
    FMoving:=True;
    FMovingParams:='';
    //direction first
    case ADirection of
      pdAfter: FMovingParams:=URL_PAGE_AFTER + '=' + IntToStr(ALastAfterID);
      pdBefore: FMovingParams:=URL_PAGE_BEFORE + '=' + IntToStr(ALastBeforeID);
    end;
    //next if we have a limit
    if ALimit>0 then
      FMovingParams:=FMovingParams + '&' + URL_PAGE_LIMIT + IntToStr(ALimit);
    //the child class needs to use GetMovingParameters method for now,
    //perhaps later will change
    Result:=Get(LContent,Error);
  except on E:Exception do
    Error:=E.Message;
  end;
end;

function TGDAXPagedApi.DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
  out Content: String; out Error: string): Boolean;
begin
  Result:=inherited DoGet(AEndpoint, AHeaders, Content, Error);
  ExtractPageIDs(AHeaders);
  //if a call to Move was made, then reset until next call
  if FMoving then
    FMoving:=False;
end;

function TGDAXPagedApi.GetMovingParameters: String;
begin
  if not FMoving then
    Result:=''
  else
    Result:=FMovingParams;
end;

function TGDAXPagedApi.Move(Const ADirection: TGDAXPageDirection;Out Error:String;
  Const ALastBeforeID, ALastAfterID: Integer;
  Const ALimit: TPageLimit): Boolean;
begin
  Result:=False;
  try
    //use id's provided by caller
    Result:=DoMove(ADirection,Error,ALastBeforeID,ALastAfterID,ALimit);
  except on E:Exception do
    Error:=E.Message;
  end;
end;

function TGDAXPagedApi.Move(Const ADirection: TGDAXPageDirection;
  Const ALimit: TPageLimit): Boolean;
var
  LError:String;
begin
  Result:=Move(ADirection,LError,ALimit);
end;

function TGDAXPagedApi.Move(Const ADirection: TGDAXPageDirection;
  out Error: String; Const ALimit: TPageLimit): Boolean;
begin
  Result:=False;
  //make a call to the base move with private id's
  Result:=Move(ADirection,Error,FLastBeforeID,FLastAfterID,ALimit);
end;

{ TGDAXRestApi }

constructor TBaseGDAXRestApiImpl.Create;
begin
end;

function TBaseGDAXRestApiImpl.Delete(out Content: String; out
  Error: String): Boolean;
var
  LHeaders: TStringList;
  LEndpoint: String;
begin
  Result:=False;
  if not (roDelete in SupportedOperations) then
  begin
    Error:=Format(E_UNSUPPORTED,['delete',Self.ClassName]);
    Exit;
  end;
  LHeaders:=TStringList.Create;
  try
    if not GetHeadersForOperation(roDelete,LHeaders,Error) then
      Exit;
    LEndpoint:=BuildFullEndpoint(GetEndpoint(roDelete),Authenticator.Mode);
    Result:=DoDelete(
      LEndpoint,
      LHeaders,
      Content,
      Error
    );
  finally
    LHeaders.Free;
  end;
end;

destructor TBaseGDAXRestApiImpl.Destroy;
begin
  //nil our reference
  FAuthenticator:=nil;
  inherited Destroy;
end;

function TBaseGDAXRestApiImpl.DoGetPostBody: String;
begin
  Result:='';
end;

function TBaseGDAXRestApiImpl.DoGetSuccess(const AHTTPStatusCode: Integer; out
  Error: String): Boolean;
begin
  Result:=False;
  if (AHTTPStatusCode>=200) and (AHTTPStatusCode<=299) then
  begin
    Result:=True;
    Exit;
  end;
  Error:=Format('invalid web status code %d',[AHTTPStatusCode]);
end;

function TBaseGDAXRestApiImpl.DoLoadFromJSON(const AJSON: String; out
  Error: String): Boolean;
begin
  //nothing to load from
  Error:='';
  Result:=True;
end;

function TBaseGDAXRestApiImpl.Get(out Content: String;
  out Error: String): Boolean;
var
  LHeaders: TStringList;
  LEndpoint: String;
begin
  Result:=False;
  if not (roGet in SupportedOperations) then
  begin
    Error:=Format(E_UNSUPPORTED,['get',Self.ClassName]);
    Exit;
  end;
  LHeaders:=TStringList.Create;
  try
    if not GetHeadersForOperation(roGet,LHeaders,Error) then
      Exit;
    LEndpoint:=BuildFullEndpoint(GetEndpoint(roGet),Authenticator.Mode);
    Result:=DoGet(
      LEndpoint,
      LHeaders,
      Content,
      Error
    );
    if Result and (not DoLoadFromJSON(Content,Error)) then
    begin
      Result:=False;
      Exit;
    end;
  finally
    LHeaders.Free;
  end;
end;

function TBaseGDAXRestApiImpl.GetAuthenticator: IGDAXAuthenticator;
begin
  Result:=FAuthenticator;
end;

function TBaseGDAXRestApiImpl.GetPostBody: String;
begin
  Result:=DoGetPostBody;
end;

function TBaseGDAXRestApiImpl.GetSupportedOperations: TRestOperations;
begin
  Result:=DoGetSupportedOperations;
end;

procedure TBaseGDAXRestApiImpl.SetAuthenticator(const AValue: IGDAXAuthenticator);
begin
  FAuthenticator:=AValue;
end;

function TBaseGDAXRestApiImpl.GetHeadersForOperation(
  const AOperation: TRestOperation; const AHeaders: TStrings; out Error: String): Boolean;
var
  LEpoch:Integer;
  LSignature:String;
begin
  Result:=False;
  try
    if not Assigned(Authenticator) then
    begin
      Error:='authenticator is invalid';
      Exit;
    end;
	  //generate the signature
    LSignature:=Authenticator.GenerateAccessSignature(
      AOperation,
      GetEndpoint(AOperation),
      LEpoch,
      DoGetPostBody
    );
    //using signature and time, build the headers for the request
    Authenticator.BuildHeaders(
      AHeaders,
      LSignature,
      LEpoch
    );
    Result:=True;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TBaseGDAXRestApiImpl.LoadFromJSON(const JSON: String; out Error: String
  ): Boolean;
begin
  Result:=DoLoadFromJSON(JSON,Error);
end;

function TBaseGDAXRestApiImpl.Post(out Content: String; out Error: String): Boolean;
var
  LHeaders: TStringList;
  LBody: string;
  LEndpoint: String;
begin
  Result:=False;
  if not (roPost in SupportedOperations) then
  begin
    Error:=Format(E_UNSUPPORTED,['post',Self.ClassName]);
    Exit;
  end;
  LHeaders:=TStringList.Create;
  try
    if not GetHeadersForOperation(roPost,LHeaders,Error) then
      Exit;
    LEndpoint:=BuildFullEndpoint(GetEndpoint(roPost),Authenticator.Mode);
    LBody:=DoGetPostBody;
    Result:=DoPost(
      LEndpoint,
      LHeaders,
      LBody,
      Content,
      Error
    );
    if Result and (not DoLoadFromJSON(Content,Error)) then
    begin
      Result:=False;
      Exit;
    end;
  finally
    LHeaders.Free;
  end;
end;

{$IFNDEF FPC}
{ TDelphiRestAPI }

constructor TDelphiRestAPI.Create;
begin
  inherited;
  FClient:=TNetHTTPClient.Create(nil);
  FClient.ContentType:='application/json; charset=utf-8';
  FClient.UserAgent:=USER_AGENT_MOZILLA;
end;

destructor TDelphiRestAPI.Destroy;
begin
  FClient.Free;
  inherited;
end;

function TDelphiRestAPI.DoDelete(Const AEndpoint: string; Const AHeaders: TStrings;
  Out Content:String;out Error: string): Boolean;
var
  LHeaders:TArray<TNameValuePair>;
  I: Integer;
  LResp: IHTTPResponse;
begin
  Result:=False;
  try
    SetLength(LHeaders,AHeaders.Count);
    for I := 0 to Pred(AHeaders.Count) do
      LHeaders[I]:=TNameValuePair.Create(AHeaders.Names[I],AHeaders.ValueFromIndex[I]);
    LResp:=FClient.Delete(
      AEndpoint,
      nil,
      LHeaders
    );
    Content:=LResp.ContentAsString();
    Result:=DoGetSuccess(LResp.StatusCode,Error);
    //this will provide a more specific error
    if (not Result) and (LResp.StatusText<>'') then
      Error:=LResp.StatusText;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TDelphiRestAPI.DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
  Out Content:String;out Error: string): Boolean;
var
  LHeaders:TArray<TNameValuePair>;
  I: Integer;
  LResp: IHTTPResponse;
  LJSON:TJSONVariantData;
begin
  Result:=False;
  try
    SetLength(LHeaders,AHeaders.Count);
    for I := 0 to Pred(AHeaders.Count) do
      LHeaders[I]:=TNameValuePair.Create(AHeaders.Names[I],AHeaders.ValueFromIndex[I]);
    LResp:=FClient.Get(
      AEndpoint,
      nil,
      LHeaders
    );
    Content:=LResp.ContentAsString();
    Result:=DoGetSuccess(LResp.StatusCode,Error);
    //this will provide a more specific error
    if (not Result) then
    begin
      if LJSON.FromJSON(Content) and (LJSON.NameIndex('message')>-1) then
        Error:=LJSON.Value['message']
      else if Error='' then
        Error:=LResp.StatusText;
    end;
  except on E: Exception do
    Error:=E.Message;
  end;
end;

function TDelphiRestAPI.DoPost(Const AEndPoint: string; Const AHeaders: TStrings;
  Const ABody: string; Out Content:String;out Error: string): Boolean;
var
  LHeaders:TArray<TNameValuePair>;
  I: Integer;
  LResp: IHTTPResponse;
  LBody:TStringStream;
begin
  Result:=False;
  try
    SetLength(LHeaders,AHeaders.Count);
    for I := 0 to Pred(AHeaders.Count) do
      LHeaders[I]:=TNameValuePair.Create(AHeaders.Names[I],AHeaders.ValueFromIndex[I]);
    LBody:=TStringStream.Create(ABody);
    try
      LResp:=FClient.Post(
        AEndpoint,
        LBody,
        nil,
        LHeaders
      );
      Content:=LResp.ContentAsString();
      Result:=DoGetSuccess(LResp.StatusCode,Error);
      //this will provide a more specific error
      if (not Result) and (LResp.StatusText<>'') then
        Error:=LResp.StatusText;
    finally
      LBody.Free;
    end;
  except on E: Exception do
    Error:=E.Message;
  end;
end;
{$ELSE}
{ TFPCRestAPI }

procedure TFPCRestAPI.TransferReaction(sender: TInternetAccess;
  var method: string; var url: TDecodedUrl; var data: TInternetAccessDataBlock;
  var reaction: TInternetAccessReaction);
begin
  reaction:=TInternetAccessReaction.iarAccept;
end;

function TFPCRestAPI.DoDelete(Const AEndpoint: string;
  Const AHeaders: TStrings; out Content: String; out Error: string): Boolean;
var
  LClient:TInternetAccess;
begin
  Result:=False;
  LClient:=defaultInternetAccessClass.create();
  try
    try
      //take control of determining success
      LClient.OnTransferReact:=TransferReaction;
      //add all headers to client
      LClient.additionalHeaders.AddStrings(AHeaders,True);
      //delete and capture response (will throw exception of failure)
      Content:=LClient.request(OP_DELETE,AEndPoint,'');
      //check response status code, otherwise error details will be in the body
      if not DoGetSuccess(LClient.lastHTTPResultCode,Error) then
      begin
        Error:=Error + sLineBreak + Content;
        Exit;
      end;
      AHeaders.Clear;
      AHeaders.AddStrings(LClient.lastHTTPHeaders);
      Result:=True;
    except on E:Exception do
      Error:=E.Message;
    end;
  finally
    LClient.Free;
  end;
end;

function TFPCRestAPI.DoPost(Const AEndPoint: string; Const AHeaders: TStrings;
  Const ABody: string; out Content: String; out Error: string): Boolean;
var
  LClient:TInternetAccess;
begin
  Result:=False;
  LClient:=defaultInternetAccessClass.create();
  try
    try
      //take control of determining success
      LClient.OnTransferReact:=TransferReaction;
      //add all headers to client
      LClient.additionalHeaders.AddStrings(AHeaders,True);
      //post and capture response (will throw exception of failure)
      Content:=LClient.post(AEndPoint,ABody);
      //check response status code, otherwise error details will be in the body
      if not DoGetSuccess(LClient.lastHTTPResultCode,Error) then
      begin
        Error:=Error + sLineBreak + Content;
        Exit;
      end;
      AHeaders.Clear;
      AHeaders.AddStrings(LClient.lastHTTPHeaders);
      Result:=True;
    except on E:Exception do
      Error:=E.Message;
    end;
  finally
    LClient.Free;
  end;
end;

function TFPCRestAPI.DoGet(Const AEndpoint: string; Const AHeaders: TStrings;
  out Content: String; out Error: string): Boolean;
var
  LClient:TInternetAccess;
begin
  Result:=False;
  LClient:=defaultInternetAccessClass.create();
  try
    try
      //take control of determining success
      LClient.OnTransferReact:=TransferReaction;
      //add all headers to client
      LClient.additionalHeaders.AddStrings(AHeaders,True);
      //get and capture response (will throw exception if failure)
      Content:=LClient.get(AEndPoint);
      //check response status code, otherwise error details will be in the body
      if not DoGetSuccess(LClient.lastHTTPResultCode,Error) then
      begin
        Error:=Error + sLineBreak + Content;
        Exit;
      end;
      AHeaders.Clear;
      AHeaders.AddStrings(LClient.lastHTTPHeaders);
      Result:=True;
    except on E:Exception do
      Error:=E.Message;
    end;
  finally
    LClient.Free;
  end;
end;

constructor TFPCRestAPI.Create;
begin
  inherited Create;
end;

destructor TFPCRestAPI.Destroy;
begin
  inherited Destroy;
end;
{$ENDIF}
initialization
{$IFDEF FPC}
  {$IFDEF MSWINDOWS}
  defaultInternetAccessClass:=TW32InternetAccess;
  {$ELSE}
    {$IFDEF ANDROID}
    defaultInternetAccessClass:=TAndroidInternetAccessClass;
    {$ELSE}
    defaultInternetAccessClass:=TSynapseInternetAccess;
    {$ENDIF}
  {$ENDIF}
{$ENDIF}
end.
