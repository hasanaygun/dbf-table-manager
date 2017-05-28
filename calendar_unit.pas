unit calendar_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Calendar,
  StdCtrls;

type

  { TfrCalendar }

  TfrCalendar = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Calendar1: TCalendar;
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frCalendar: TfrCalendar;

implementation

{$R *.lfm}

end.

