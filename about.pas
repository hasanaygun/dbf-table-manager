unit about;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RichMemo, Forms, Controls, Graphics, Dialogs,
  Buttons, StdCtrls;

type

  { TfrAbout }

  TfrAbout = class(TForm)
    BitBtn1: TBitBtn;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frAbout: TfrAbout;

implementation

{$R *.lfm}

end.

