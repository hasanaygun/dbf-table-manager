unit locate_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics,
  Dialogs, Grids, Buttons, StdCtrls, MaskEdit, variants, db;

type

  { TfrLocate }

  TfrLocate = class(TForm)
    ckCaseSensitive: TCheckBox;
    ckPartialKey: TCheckBox;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    MaskEdit1: TMaskEdit;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    sgFields: TStringGrid;
    procedure ComboBox1EditingDone(Sender: TObject);
    procedure ComboBox1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ComboBox1KeyPress(Sender: TObject; var Key: char);
    procedure Edit1EditingDone(Sender: TObject);
    procedure Edit1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Edit1KeyPress(Sender: TObject; var Key: char);
    procedure MaskEdit1EditingDone(Sender: TObject);
    procedure sgFieldsCheckboxToggled(sender: TObject; aCol, aRow: Integer;
      aState: TCheckboxState);
    procedure sgFieldsSelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frLocate: TfrLocate;
  V: Variant;
  VarCreated: Boolean;
  SearchFld: string;
  SearchOpts: TLocateOptions;

implementation

uses main_unit;

{$R *.lfm}

{ TfrLocate }

procedure TfrLocate.SpeedButton1Click(Sender: TObject);
var
  C: Char;
  S: string;
  L: Boolean;
  Ok: Boolean;
  I,J: Integer;
begin
  J := 0;
  SearchFld := '';
  for I := 1 to sgFields.RowCount - 1 do
    if sgFields.Cells[0,I] = '1' then
    begin
      Inc(J);
      SearchFld := SearchFld + sgFields.Cells[1,I] + ';';
    end;
  Delete(SearchFld,Length(SearchFld),1);
  if (J < 1) then
  begin
    MessageDlg(#10'Select at least one field and '+
      'enter a search string!',
      mtWarning, [mbOk], 0);
    Exit;
  end;
  if not VarCreated then
  begin
    V := VarArrayCreate([0, J-1], varVariant);
    VarCreated := True;
  end
  else
    VarArrayRedim(V, J-1);
  J := -1;
  for I := 1 to sgFields.RowCount - 1 do
    if sgFields.Cells[0,I] = '1' then
    begin
      Inc(J);
      S := sgFields.Cells[3,I]; //1
      C := S[1]; //NativeType   //2
      S := sgFields.Cells[2,I]; //3
      if C = 'L' then           //Logic
      begin
        if S = 'Yes' then L := True else
        if S = 'No' then L := False;
        if S ='' then V[J] := Null else V[J] := L;
      end
      else
      if S = '' then V[J] := Null else V[J] := S;
    end;
  SearchOpts := [loCaseInsensitive];
  if ckCaseSensitive.Checked then SearchOpts := SearchOpts - [loCaseInsensitive];
  if ckPartialKey.Checked then SearchOpts := SearchOpts + [loPartialKey];
  if J = 0 then
  begin
    if S='' then
      Ok := frMain.dbfMain.Locate(SearchFld, Null, SearchOpts)
    else
    if C = 'L' then
      Ok := frMain.dbfMain.Locate(SearchFld, L, SearchOpts)
    else
      Ok := frMain.dbfMain.Locate(SearchFld, S, SearchOpts);
  end
  else
    Ok := frMain.dbfMain.Locate(SearchFld, V, SearchOpts);
  if not Ok then
  begin
    MessageDlg(#10'Record not found!', mtWarning, [mbOk], 0);
    Exit;
  end;
  ModalResult := mrOk;
end;

procedure TfrLocate.sgFieldsCheckboxToggled(sender: TObject; aCol, aRow: Integer;
  aState: TCheckboxState);
var
  I,J: Integer;
begin
  {if aState = cbUnchecked then sgFields.Cells[2,aRow] := '';
  sgFields.Columns[2].ReadOnly := aState = cbUnchecked;}
  if aState = cbUnchecked then
  begin
    sgFields.Cells[2,aRow] := '';
    J := 0;
    for I := 1 to sgFields.RowCount-1 do
      if sgFields.Cells[0,I] = '1' then Inc(J);
    sgFields.Columns[2].ReadOnly := J = 0;
  end
  else
    sgFields.Columns[2].ReadOnly := False;
end;

procedure TfrLocate.ComboBox1EditingDone(Sender: TObject);
begin
  sgFields.Cells[sgFields.Col,sgFields.Row]:=ComboBox1.Text;
end;

procedure TfrLocate.ComboBox1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  I: Integer;
begin
  I := sgFields.Row;
  if Key = 46 then Key := 0 else
  if (Key = 38) and (I > 1) then sgFields.Row := I-1 else
  if (Key = 40) and (I < sgFields.RowCount) then sgFields.Row:=I+1
end;

procedure TfrLocate.ComboBox1KeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in [#13,#27]) then Key := #0;
end;

procedure TfrLocate.Edit1EditingDone(Sender: TObject);
begin
  sgFields.Cells[sgFields.Col,sgFields.Row]:=Edit1.Text;
end;

procedure TfrLocate.Edit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  I: Integer;
begin
  I := sgFields.Row;
  if (Key = 38) and (I > 1) then sgFields.Row := I-1 else
  if (Key = 40) and (I < sgFields.RowCount) then sgFields.Row:=I+1
end;

procedure TfrLocate.Edit1KeyPress(Sender: TObject; var Key: char);
var
  S: string;
  Digit: Integer;
begin
  if sgFields.Col = 2 then
  begin
    if sgFields.Cells[0,sgFields.Row]='1' then
    begin
      S := sgFields.Cells[3,sgFields.Row];
      Digit := StrToInt(sgFields.Cells[4,sgFields.Row]);
      case S[1] of
        '+': if not (Key in [#8,#13,#27,'0'..'9']) then Key := #0;
        'F','I','N':
            if Digit = 0 then
              if not (Key in [#8,#13,#27,'0'..'9','-','+']) then Key := #0 else
            else
              if not (Key in [#8,#13,#27,'0'..'9','-','+',DecimalSeparator]) then Key := #0;
        '@','D':
            if not (Key in [#8,#13,#27,'0'..'9','.','-','/']) then Key := #0;
      end;
    end
    else
      Key := #0;
  end
  else
    Key := #0;
end;

procedure TfrLocate.MaskEdit1EditingDone(Sender: TObject);
begin
  sgFields.Cells[sgFields.Col,sgFields.Row]:=MaskEdit1.Text;
end;

procedure TfrLocate.sgFieldsSelectEditor(Sender: TObject; aCol, aRow: Integer;
  var Editor: TWinControl);
var
  S: string;
begin
  S := sgFields.Cells[3,aRow];
  if aCol=2 then
  begin
    if sgFields.Cells[0,aRow]='0' then
    begin
      Editor:=nil;
      Exit;
    end;
    if S[1] = 'L' then
    begin
      ComboBox1.BoundsRect:=sgFields.CellRect(aCol,aRow);
      ComboBox1.Text:=sgFields.Cells[sgFields.Col,sgFields.Row];
      Editor:=ComboBox1;
    end
    else
    if S[1] in ['@','D'] then
    begin
      MaskEdit1.BoundsRect:=sgFields.CellRect(aCol,aRow);
      S := sgFields.Cells[sgFields.Col,sgFields.Row];
      if S > '' then MaskEdit1.Text := sgFields.Cells[sgFields.Col,sgFields.Row];
      Editor:=MaskEdit1;
    end
    else
    begin
      Edit1.BoundsRect:=sgFields.CellRect(aCol,aRow);
      Edit1.Text:=sgFields.Cells[sgFields.Col,sgFields.Row];
      Editor:=Edit1;
    end;
  end;
end;

procedure TfrLocate.SpeedButton2Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.

