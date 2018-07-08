{ GDAX/Coinbase-Pro client library tester

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

unit test;

{$MODE DELPHI}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, Grids, gdax.api.types, gdax.api.authenticator,
  gdax.api.accounts, gdax.api.orders, gdax.api.consts, gdax.api.ticker,
  gdax.api.book;

type

  { TGDAXTester }

  TGDAXTester = class(TForm)
    arrow_fills_back: TShape;
    arrow_fills_forward: TShape;
    btn_auth_test: TButton;
    btn_base_web_test: TButton;
    btn_product_test: TButton;
    btn_accounts_test: TButton;
    btn_test_fills: TButton;
    btn_test_order: TButton;
    btn_test_ledger: TButton;
    chk_order_stop: TCheckBox;
    chk_auth_time: TCheckBox;
    chk_order_post: TCheckBox;
    chk_sandbox: TCheckBox;
    combo_ledger_accounts: TComboBox;
    combo_fills_products: TComboBox;
    combo_order_type: TComboBox;
    combo_order_ids: TComboBox;
    combo_order_side: TComboBox;
    edit_order_price: TEdit;
    edit_order_size: TEdit;
    edit_auth_key: TLabeledEdit;
    edit_auth_secret: TLabeledEdit;
    edit_auth_pass: TLabeledEdit;
    edit_product_quote: TLabeledEdit;
    lbl_fills_total: TLabel;
    lbl_fills_total_size: TLabel;
    lbl_fills_total_price: TLabel;
    lbl_fills_total_fees: TLabel;
    lbl_ledger_count: TLabel;
    lbl_ledger_ids: TLabel;
    lbl_fills_prods: TLabel;
    list_ledger: TListBox;
    list_fills: TListBox;
    list_products: TListBox;
    memo_order_output: TMemo;
    memo_base_web: TMemo;
    memo_auth_result: TMemo;
    pctrl_main: TPageControl;
    grid_accounts: TStringGrid;
    arrow_ledger_forward: TShape;
    arrow_ledger_back: TShape;
    ts_fills: TTabSheet;
    ts_ledger: TTabSheet;
    ts_order: TTabSheet;
    ts_accounts: TTabSheet;
    ts_products: TTabSheet;
    ts_fpc_web: TTabSheet;
    ts_auth: TTabSheet;
    procedure btn_accounts_testClick(Sender: TObject);
    procedure btn_auth_testClick(Sender: TObject);
    procedure btn_base_web_testClick(Sender: TObject);
    procedure btn_product_testClick(Sender: TObject);
    procedure btn_test_fillsClick(Sender: TObject);
    procedure btn_test_ledgerClick(Sender: TObject);
    procedure btn_test_orderClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pctrl_mainChange(Sender: TObject);
    procedure ts_fillsShow(Sender: TObject);
  private
    FAuthenticator:IGDAXAuthenticator;
    FAccountsLoaded:Boolean;
    FFillsLoaded:Boolean;
    FLedger:IGDAXAccountLedger;
    FFills:IGDAXFills;
    procedure LedgerMoveForward(Sender:TObject);
    procedure LedgerMoveBack(Sender:TObject);
    procedure FillsMoveForward(Sender:TObject);
    procedure FillsMoveBack(Sender:TObject);
    procedure InitAuthenticator;
    procedure InitOrderTab;
    procedure InitLedgerTab;
    procedure InitFillsTab;
    function TestTimeEndpoint:String;
    function TestProducts(Const AQuoteCurrencyFilter:String):IGDAXProducts;
    function TestAccounts:IGDAXAccounts;
    function TestOrder(Const AProductID:String;Const ASide:TOrderSide;
      Const AType:TOrderType;Const APostOnly,AStop:Boolean;Const APrice,ASize:Extended;
      Out Success:Boolean;Out Content:String):IGDAXOrder;
    function TestLedger(Const AAcctID:String; Out Content,Error:String;
      Out Success:Boolean):IGDAXAccountLedger;
    function TestFills(Const AProductID:String; Out Content,Error:String;
      Out Success:Boolean):IGDAXFills;
  public

  end;

var
  GDAXTester: TGDAXTester;

implementation
uses
  SynCrossPlatformJSON, gdax.api.time, gdax.api.products, gdax.api.fills;
{$R *.lfm}

{ TGDAXTester }

procedure TGDAXTester.FormCreate(Sender: TObject);
begin
  FAccountsLoaded:=False;;
  FAuthenticator:=TGDAXAuthenticatorImpl.Create;
  pctrl_main.ActivePage:=ts_auth;
  InitOrderTab;
  InitLedgerTab;
  InitFillsTab;
end;

procedure TGDAXTester.btn_auth_testClick(Sender: TObject);
var
  LSig:String;
  LEpoch:Integer;
begin
  InitAuthenticator;
  memo_auth_result.Lines.Clear;
  LSig:=FAuthenticator.GenerateAccessSignature(
    roGET,
    BuildFullEndpoint(GDAX_END_API_ACCTS,gdSand),
    LEpoch
  );
  FAuthenticator.BuildHeaders(memo_auth_result.Lines,LSig,LEpoch);
end;

procedure TGDAXTester.btn_accounts_testClick(Sender: TObject);
var
  LCol:TGridColumn;
  LAccts:IGDAXAccounts;
  I:Integer;
begin
  grid_accounts.Clear;
  grid_accounts.ColCount:=5;
  LCol:=grid_accounts.Columns.Add;
  LCol.Title.Caption:='Account ID';
  LCol:=grid_accounts.Columns.Add;
  LCol.Title.Caption:='Available';
  LCol:=grid_accounts.Columns.Add;
  LCol.Title.Caption:='Balance';
  LCol:=grid_accounts.Columns.Add;
  LCol.Title.Caption:='Currency';
  LCol:=grid_accounts.Columns.Add;
  LCol.Title.Caption:='Holds';
  LAccts:=TestAccounts;
  grid_accounts.RowCount:=LAccts.Accounts.Count;
  for I:=1 to Pred(LAccts.Accounts.Count) do
  begin
    grid_accounts.Cells[1,I]:=LAccts.Accounts[I].AcctID;
    grid_accounts.Cells[2,I]:=FloatToStr(LAccts.Accounts[I].Available);
    grid_accounts.Cells[3,I]:=FloatToStr(LAccts.Accounts[I].Balance);
    grid_accounts.Cells[4,I]:=LAccts.Accounts[I].Currency;
    grid_accounts.Cells[5,I]:=FloatToStr(LAccts.Accounts[I].Holds);
  end;
end;

procedure TGDAXTester.btn_base_web_testClick(Sender: TObject);
begin
  memo_base_web.Lines.Clear;
  memo_base_web.Lines.Add(TestTimeEndpoint);
end;

procedure TGDAXTester.btn_product_testClick(Sender: TObject);
var
  I:Integer;
  LProducts:IGDAXProducts;
begin
  list_products.Clear;
  LProducts:=TestProducts(edit_product_quote.Text);
  for I:=0 to Pred(LProducts.Products.Count) do
    list_products.Items.Add(LProducts.Products[I].ID);
end;

procedure TGDAXTester.btn_test_fillsClick(Sender: TObject);
var
  I:Integer;
  LContent,LError:String;
  LSuccess:Boolean;
  LEntries:TFillEntryArray;
begin
  list_fills.Clear;
  if not ((Sender=arrow_fills_back) or (Sender=arrow_fills_forward)) then
  begin
    FFills:=nil;
    FFills:=TestFills(
      combo_fills_products.Items.ValueFromIndex[combo_fills_products.ItemIndex],
      LContent,
      LError,
      LSuccess
    );
  end;
  LEntries:=FFills.Entries;
  for I:=0 to High(LEntries) do
  begin
    list_fills.Items.Add(
      Format(
        'Product:%s Side:%s Price:%f',
        [
          LEntries[I].ProductID,
          OrderSideToString(LEntries[I].Side),
          LEntries[I].Price
        ]
      )
    );
  end;
  lbl_fills_total.Caption:='Total:'+IntToStr(Length(LEntries));
  lbl_fills_total_size.Caption:='TotalSize:'+FloatToStr(FFills.TotalSize[[osBuy,osSell]]);
  lbl_fills_total_fees.Caption:='TotalFees:'+FloatToStr(FFills.TotalFees[[osBuy,osSell]]);
  lbl_fills_total_price.Caption:='TotalPrice:'+FloatToStr(FFills.TotalPrice[[osBuy,osSell]]);
end;

procedure TGDAXTester.btn_test_ledgerClick(Sender: TObject);
var
  I:Integer;
  LContent,LError:String;
  LSuccess:Boolean;
  LJSON:TJSONVariantData;
begin
  list_ledger.Clear;
  if not ((Sender=arrow_ledger_back) or (Sender=arrow_ledger_forward)) then
  begin
    FLedger:=nil;
    FLedger:=TestLedger(
      combo_ledger_accounts.Items.ValueFromIndex[combo_ledger_accounts.ItemIndex],
      LContent,
      LError,
      LSuccess
    );
  end;
  for I:=0 to High(FLedger.Entries) do
  begin
    list_ledger.Items.Add(
      Format(
        'Type:%s Amount:%f',
        [
          LedgerTypeToString(FLedger.Entries[I].LedgerType),
          FLedger.Entries[I].Amount
        ]
      )
    );
  end;
  lbl_ledger_count.Caption:=IntToStr(Length(FLedger.Entries));
end;

procedure TGDAXTester.btn_test_orderClick(Sender: TObject);
var
  LOrder:IGDAXOrder;
  LContent:String;
  LType:TOrderType;
  LSide:TOrderSide;
  LSuccess:Boolean;
  LError:string;
begin
  LType:=StringToOrderType(combo_order_type.Text);
  LSide:=StringToOrderSide(combo_order_side.Text);
  LOrder:=TestOrder(
    combo_order_ids.Items[combo_order_ids.ItemIndex],
    LSide,
    LType,
    chk_order_post.Checked,
    chk_order_stop.Checked,
    StrToFloatDef(edit_order_price.Text,1),
    StrToFloatDef(edit_order_size.Text,1),
    LSuccess,
    LContent
  );
  memo_order_output.Clear;
  if not LSuccess then
  begin
    memo_order_output.Lines.Add('order not successful');
    memo_order_output.Text:=LContent;
    Exit;
  end;
  memo_order_output.Text:=LContent;
  while not (
    LOrder.OrderStatus in [stActive,stOpen,stDone,stCancelled,stRejected]
  ) do
  begin
    Application.ProcessMessages;
    Sleep(1000 div GDAX_PRIVATE_REQUESTS_PSEC);
    memo_order_output.Lines.Add('polling for status');
    if not LOrder.Get(LContent,LError) then
    begin
      memo_order_output.Lines.Add('error occurred during polling: ' + LError);
      Exit;
    end;
    memo_order_output.Lines.Add(LContent);
  end;
end;

procedure TGDAXTester.FormDestroy(Sender: TObject);
begin
  FAuthenticator:=nil;
end;

procedure TGDAXTester.pctrl_mainChange(Sender: TObject);
var
  I:Integer;
  LAccounts:IGDAXAccounts;
begin
  if not FAccountsLoaded then
  begin
    combo_ledger_accounts.Clear;
    LAccounts:=TestAccounts;
    for I:=0 to Pred(LAccounts.Accounts.Count) do
      combo_ledger_accounts.Items.Add(
        LAccounts.Accounts[I].Currency + '=' +
        LAccounts.Accounts[I].AcctID
      );
    FAccountsLoaded:=True;
  end;
end;

procedure TGDAXTester.ts_fillsShow(Sender: TObject);
var
  I:Integer;
  LProducts:IGDAXProducts;
begin
  if not FFillsLoaded then
  begin
    combo_fills_products.Clear;
    LProducts:=TestProducts('');
    for I:=0 to Pred(LProducts.Products.Count) do
      combo_fills_products.Items.Add(LProducts.Products[I].ID);
    FFillsLoaded:=True;
  end;
end;

procedure TGDAXTester.LedgerMoveForward(Sender: TObject);
var
  LError:String;
begin
  if Assigned(FLedger) then
  begin
    if not FLedger.Paged.Move(
      pdAfter,
      LError
    ) then
      ShowMessage(LError);
    btn_test_ledgerClick(Sender);
  end;
end;

procedure TGDAXTester.LedgerMoveBack(Sender: TObject);
var
  LError:String;
begin
  if Assigned(FLedger) then
  begin
    if not FLedger.Paged.Move(
      pdBefore,
      LError
    ) then
      ShowMessage(LError);
    btn_test_ledgerClick(Sender);
  end;
end;

procedure TGDAXTester.FillsMoveForward(Sender: TObject);
var
  LError:String;
begin
  if Assigned(FFills) then
  begin
    if not FFills.Paged.Move(
      pdAfter,
      LError
    ) then
      ShowMessage(LError);
    btn_test_fillsClick(Sender);
  end;
end;

procedure TGDAXTester.FillsMoveBack(Sender: TObject);
var
  LError:String;
begin
  if Assigned(FFills) then
  begin
    if not FFills.Paged.Move(
      pdBefore,
      LError
    ) then
      ShowMessage(LError);
    btn_test_fillsClick(Sender);
  end;
end;

procedure TGDAXTester.InitAuthenticator;
begin
  FAuthenticator.Key:=edit_auth_key.Text;
  FAuthenticator.Passphrase:=edit_auth_pass.Text;
  FAuthenticator.Secret:=edit_auth_secret.Text;
  if chk_sandbox.Checked then
    FAuthenticator.Mode:=gdSand
  else
    FAuthenticator.Mode:=gdProd;
  FAuthenticator.UseLocalTime:=chk_auth_time.Checked;
end;

procedure TGDAXTester.InitOrderTab;
var
  I:Integer;
begin
  combo_order_type.Clear;
  combo_order_side.Clear;
  for I:=Low(ORDER_SIDES) to High(ORDER_SIDES) do
    combo_order_side.Items.Add(ORDER_SIDES[I]);
  for I:=Low(ORDER_TYPES) to High(ORDER_TYPES) do
    combo_order_type.Items.Add(ORDER_TYPES[I]);
end;

procedure TGDAXTester.InitLedgerTab;
begin
  arrow_ledger_forward.OnClick:=LedgerMoveForward;
  arrow_ledger_back.OnClick:=LedgerMoveBack;
end;

procedure TGDAXTester.InitFillsTab;
begin
  arrow_fills_back.OnClick:=FillsMoveBack;
  arrow_fills_forward.OnClick:=FillsMoveForward;
end;

function TGDAXTester.TestTimeEndpoint: String;
var
  LTime:IGDAXTime;
  LError:String;
begin
  InitAuthenticator;
  LTime:=TGDAXTimeImpl.Create;
  LTime.Authenticator:=FAuthenticator;
  if not LTime.Get(Result,LError) then
    Result:=
      LError + sLineBreak +
      BuildFullEndpoint(GDAX_END_API_TIME,FAuthenticator.Mode) + sLineBreak +
      Result;
end;

function TGDAXTester.TestProducts(
  Const AQuoteCurrencyFilter: String): IGDAXProducts;
var
  LContent,LError:String;
begin
  InitAuthenticator;
  Result:=TGDAXProductsImpl.Create;
  Result.Authenticator:=FAuthenticator;
  Result.QuoteCurrency:=AQuoteCurrencyFilter;
  if not Result.Get(LContent,LError) then
    raise Exception.Create(LError);
end;

function TGDAXTester.TestAccounts: IGDAXAccounts;
var
  LContent,LError:String;
begin
  InitAuthenticator;
  Result:=TGDAXAccountsImpl.Create;
  Result.Authenticator:=FAuthenticator;
  if not Result.Get(LContent,LError) then
    raise Exception.Create(LError);
end;

function TGDAXTester.TestOrder(Const AProductID: String;
  Const ASide: TOrderSide; Const AType: TOrderType; Const APostOnly,
  AStop: Boolean; Const APrice, ASize: Extended; out Success: Boolean; out
  Content: String): IGDAXOrder;
var
  LError:String;
begin
  Success:=False;
  InitAuthenticator;
  Result:=TGDAXOrderImpl.Create;
  Result.Authenticator:=FAuthenticator;
  Result.Product.ID:=AProductID;
  Result.Side:=ASide;
  Result.OrderType:=AType;
  Result.Size:=ASize;
  Result.Price:=APrice;
  Result.StopOrder:=AStop;
  Result.PostOnly:=APostOnly;
  if not Result.Post(Content,LError) then
  begin
    Content:=LError;
    Exit;
  end;
  //if we made a successful web call, check the status to see if the order
  //actually was "successful"
  case Result.OrderStatus of
    stUnknown:
      begin
        Success:=False;
        Content:='order status is unknown after web call' + sLineBreak + Content;
        Exit;
      end;
    stRejected:
      begin
        Success:=False;
        Content:='Rejected: ' + Result.RejectReason + sLineBreak + Content;
        Exit;
      end;
  end;
  Success:=True;
end;

function TGDAXTester.TestLedger(Const AAcctID: String; out Content,
  Error: String; out Success: Boolean): IGDAXAccountLedger;
begin
  Success:=False;
  InitAuthenticator;
  Result:=TGDAXAccountLedgerImpl.Create;
  Result.Authenticator:=FAuthenticator;
  Result.AcctID:=AAcctID;
  if not Result.Get(Content,Error) then
    Exit;
  Success:=True;
end;

function TGDAXTester.TestFills(Const AProductID: String; out Content,
  Error: String; out Success: Boolean): IGDAXFills;
begin
  Success:=False;
  InitAuthenticator;
  Result:=TGDAXFillsImpl.Create;
  Result.Authenticator:=FAuthenticator;
  Result.ProductID:=AProductID;
  if not Result.Get(Content,Error) then
    Exit;
  Success:=True;
end;

end.

