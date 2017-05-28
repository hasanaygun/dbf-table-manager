unit new_opt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TfrNewOpt }

  TfrNewOpt = class(TForm)
    Button1: TButton;
    Button2: TButton;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure RadioButton1Change(Sender: TObject);
    procedure RadioButton2Change(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frNewOpt: TfrNewOpt;

implementation

{$R *.lfm}

{ TfrNewOpt }

procedure TfrNewOpt.RadioButton1Change(Sender: TObject);
begin
  if RadioButton1.Checked then
  begin
    RadioButton1.Font.Color := clBlue;
    RadioButton2.Font.Color := clDefault;
  end;
end;

procedure TfrNewOpt.FormCreate(Sender: TObject);
begin
  RadioButton1.Font.Color := clBlue;
end;

procedure TfrNewOpt.RadioButton2Change(Sender: TObject);
begin
  if RadioButton2.Checked then
  begin
    RadioButton2.Font.Color := clBlue;
    RadioButton1.Font.Color := clDefault;
  end;
end;

end.

