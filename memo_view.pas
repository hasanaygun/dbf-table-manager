unit memo_view;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls;

type

  { TfrMemoView }

  TfrMemoView = class(TForm)
    bntOk: TButton;
    btnCancel: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Image1: TImage;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure bntOkClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    procedure ResizeImage;
  end;

var
  frMemoView: TfrMemoView;
  BlobType: (btText, btPicture);

implementation

{$R *.lfm}

{ TfrMemoView }

procedure TfrMemoView.ResizeImage;
var
  Ratio: Real;
  H,W: Integer;
begin
  Ratio := Image1.Picture.Width / Image1.Picture.Height;
  Image1.Top := 0;
  Image1.Left := 0;
  H := TabSheet2.Height;
  W := Trunc(H * Ratio);
  if W > TabSheet2.Width then
  begin
    W := TabSheet2.Width;
    Ratio := Image1.Picture.Height / Image1.Picture.Width;
    H := Trunc(W * Ratio);
  end;
  Image1.AutoSize := (Image1.Picture.Height < H) or (Image1.Picture.Width < W);
  if not Image1.AutoSize then
  begin
    Image1.Width := W;
    Image1.Height := H;
  end;
end;

procedure TfrMemoView.Button1Click(Sender: TObject);
begin
  OpenDialog1.Filter := 'Image files|*.jpg;*.jpeg;*.bmp;*.png;*.gif;*.Jpg;'+
    '*.Jpeg;*.Bmp;*.Png;*.Gif;*.JPG;*.JPEG;*.BMP;*.GIF;*.PNG|All files|*.*';
  if OpenDialog1.Execute then
  begin
    Image1.Picture.LoadFromFile(OpenDialog1.FileName);
    ResizeImage;
  end;
end;

procedure TfrMemoView.Button2Click(Sender: TObject);
begin
  if Assigned(Image1.Picture) then Image1.Picture := nil;
end;

procedure TfrMemoView.Button4Click(Sender: TObject);
begin
  BlobType := btPicture;
end;

procedure TfrMemoView.Button5Click(Sender: TObject);
begin
  OpenDialog1.Filter := 'Text files|*.txt;*.Txt;*.TXT|All files|*.*';
  if OpenDialog1.Execute then
    Memo1.Lines.LoadFromFile(OpenDialog1.FileName);
end;

procedure TfrMemoView.Button6Click(Sender: TObject);
begin
  Memo1.Lines.Clear;
end;

procedure TfrMemoView.FormCreate(Sender: TObject);
begin
  BlobType := btText;
end;

procedure TfrMemoView.FormPaint(Sender: TObject);
begin
  if BlobType = btPicture then ResizeImage;
end;

procedure TfrMemoView.FormShow(Sender: TObject);
begin
  case BlobType of
    btText : PageControl1.ActivePageIndex := 0;
    btPicture: PageControl1.ActivePageIndex := 1;
  end;
end;

procedure TfrMemoView.bntOkClick(Sender: TObject);
begin
  BlobType := btText;
end;

end.

