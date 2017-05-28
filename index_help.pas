unit index_help;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RichMemo, Forms, Controls, Graphics, Dialogs,
  Buttons, StdCtrls;

type

  { TfrmIndexHelp }

  TfrmIndexHelp = class(TForm)
    Button1: TButton;
    RichMemo1: TRichMemo;
    procedure Button1Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frmIndexHelp: TfrmIndexHelp;

implementation

{$R *.lfm}

{ TfrmIndexHelp }

procedure TfrmIndexHelp.Button1Click(Sender: TObject);
begin

end;

end.

