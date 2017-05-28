unit filter_records;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, RTTICtrls, Forms, Controls,
  Graphics, Dialogs, Grids, Buttons, StdCtrls, MaskEdit, variants, db, strutils;

type

  { TfrFilter }

  TfrFilter = class(TForm)
    ckCaseSensitive: TCheckBox;
    ckPartialCompare: TCheckBox;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Edit1: TEdit;
    MaskEdit1: TMaskEdit;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    sgFields: TStringGrid;
    procedure ComboBox1EditingDone(Sender: TObject);
    procedure ComboBox1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ComboBox1KeyPress(Sender: TObject; var Key: char);
    procedure ComboBox2EditingDone(Sender: TObject);
    procedure ComboBox2KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ComboBox2KeyPress(Sender: TObject; var Key: char);
    procedure Edit1EditingDone(Sender: TObject);
    procedure Edit1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Edit1KeyPress(Sender: TObject; var Key: char);
    procedure MaskEdit1EditingDone(Sender: TObject);
    procedure sgFieldsCheckboxToggled(sender: TObject; aCol, aRow: Integer;
      aState: TCheckboxState);
    procedure sgFieldsKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure sgFieldsKeyPress(Sender: TObject; var Key: char);
    procedure sgFieldsSelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  TFilterType= record
    FldName: string;
    Op: string;
    FilterStr: string;
    Native: String;
  end;

var
  frFilter: TfrFilter;
  FilterOpts: TFilterOptions;

implementation

uses main_unit;

{$R *.lfm}

{ TfrFilter }

procedure TfrFilter.SpeedButton1Click(Sender: TObject);
var
  S: string;
  FilterStr,SearchStr: string;
  I,J: Integer;
  Dt: TDateTime;
  A: array of TFilterType;

begin
  J := 0;
  for I := 1 to sgFields.RowCount - 1 do
    if sgFields.Cells[0,I] = '1' then Inc(J);
  if (J < 1) then
  begin
    MessageDlg(#10'Select at least one field and '+
      'enter a filter string!',
      mtWarning, [mbOk], 0);
    Exit;
  end;
  SetLength(A,J);
  J := 0;
  for I := 1 to sgFields.RowCount - 1 do
    if sgFields.Cells[0,I] = '1' then
    begin
      A[J].FldName := sgFields.Cells[1,I];
      A[J].Op := sgFields.Cells[2,I];
      A[J].Op := ' '+ Trim(A[J].Op) + ' ';
      A[J].FilterStr := sgFields.Cells[3,I];
      A[J].Native := sgFields.Cells[4,I];
      Inc(J);
    end;
  FilterStr := '';
  SearchStr := '';
  for I := Low(A) to High(A) do
  begin
    S := A[I].Native;
    case S[1] of
      '+','F','I','N':
         if not ckPartialCompare.Checked then
         begin
           if A[I].FilterStr = '' then
           begin
             A[I].FilterStr := '0';
             FilterStr := 'STR('+ A[I].FldName+ ')' + A[I].Op + QuotedStr(A[I].FilterStr);
           end
           else
             FilterStr := A[I].FldName + A[I].Op + A[I].FilterStr;
         end
         else
           FilterStr := 'STR('+A[I].FldName+ ')' + A[I].Op + QuotedStr(A[I].FilterStr+'*');
      '@','D':
         begin
           if TryStrToDate(A[I].FilterStr,Dt) then
             A[I].FilterStr := FormatDateTime('yyyymmdd',Dt)
           else
             A[I].FilterStr := '';
           FilterStr := 'DTOS('+A[I].FldName+')' + A[I].Op + QuotedStr(A[I].FilterStr);
         end;
      'C':
         if ckPartialCompare.Checked then
           FilterStr := A[I].FldName + A[I].Op + QuotedStr(A[I].FilterStr+'*')
         else
           FilterStr := A[I].FldName + A[I].Op + QuotedStr(A[I].FilterStr);
      'L':
         if A[I].FilterStr = 'Yes' then FilterStr := A[I].FldName
         else FilterStr := 'not '+A[I].FldName;
    end;
    if I = Low(A) then SearchStr := FilterStr else SearchStr := SearchStr + ' and '+ FilterStr;
  end;
  FilterOpts := [foCaseInsensitive,foNoPartialCompare];
  if ckCaseSensitive.Checked then FilterOpts := FilterOpts - [foCaseInsensitive];
  if ckPartialCompare.Checked then FilterOpts := FilterOpts - [foNoPartialCompare];
  with frMain.dbfMain do
  begin
    Filtered := False;
    FilterOptions := FilterOpts;
    Filter := FilterStr;
    Filtered := True;
    if not FindFirst then
    begin
      Filtered := False;
      MessageDlg(#10'Record not found!', mtWarning, [mbOk], 0);
      SetLength(A,0);
      Exit;
    end;
  end;
  SetLength(A,0);
  ModalResult := mrOk;
end;

procedure TfrFilter.sgFieldsCheckboxToggled(sender: TObject; aCol, aRow: Integer;
  aState: TCheckboxState);
var
  I,J: Integer;
begin
  {if aState = cbUnchecked then sgFields.Cells[3,aRow] := '';
  sgFields.Columns[3].ReadOnly := aState = cbUnchecked;}
  if aState = cbUnchecked then
  begin
    sgFields.Cells[3,aRow] := '';
    J := 0;
    for I := 1 to sgFields.RowCount-1 do
      if sgFields.Cells[0,I] = '1' then Inc(J);
    sgFields.Columns[3].ReadOnly := J = 0;
  end
  else
    sgFields.Columns[3].ReadOnly := False;
end;

procedure TfrFilter.sgFieldsKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 46 then Key := 0;
end;

procedure TfrFilter.sgFieldsKeyPress(Sender: TObject; var Key: char);
begin
  if sgFields.Col = 2 then
    if not (Key in [#13,#27]) then Key := #0;;
end;

procedure TfrFilter.ComboBox1EditingDone(Sender: TObject);
begin
  sgFields.Cells[sgFields.Col,sgFields.Row]:=ComboBox1.Text;
end;

procedure TfrFilter.ComboBox1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  I: Integer;
begin
  I := sgFields.Row;
  if Key = 46 then Key := 0 else
  if (Key = 38) and (I > 1) then sgFields.Row := I-1 else
  if (Key = 40) and (I < sgFields.RowCount) then sgFields.Row:=I+1
end;

procedure TfrFilter.ComboBox1KeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in [#13,#27]) then Key := #0;
end;

procedure TfrFilter.ComboBox2EditingDone(Sender: TObject);
begin
  sgFields.Cells[sgFields.Col,sgFields.Row]:=ComboBox2.Text;
end;

procedure TfrFilter.ComboBox2KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  I: Integer;
begin
  I := sgFields.Row;
  if Key = 46 then Key := 0 else
  if (Key = 38) and (I > 1) then sgFields.Row := I-1 else
  if (Key = 40) and (I < sgFields.RowCount) then sgFields.Row:=I+1
end;

procedure TfrFilter.ComboBox2KeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in [#13,#27]) then Key := #0;
end;

procedure TfrFilter.Edit1EditingDone(Sender: TObject);
begin
  sgFields.Cells[sgFields.Col,sgFields.Row]:=Edit1.Text;
end;

procedure TfrFilter.Edit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  I: Integer;
begin
  I := sgFields.Row;
  if (Key = 38) and (I > 1) then sgFields.Row := I-1 else
  if (Key = 40) and (I < sgFields.RowCount) then sgFields.Row:=I+1
end;

procedure TfrFilter.Edit1KeyPress(Sender: TObject; var Key: char);
var
  S: string;
  Digit: Integer;
begin
  if sgFields.Col = 3 then
  begin
    if sgFields.Cells[0,sgFields.Row]='1' then
    begin
      S := sgFields.Cells[4,sgFields.Row];
      Digit := StrToInt(sgFields.Cells[5,sgFields.Row]);
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

procedure TfrFilter.MaskEdit1EditingDone(Sender: TObject);
begin
  sgFields.Cells[sgFields.Col,sgFields.Row]:=MaskEdit1.Text;
end;

procedure TfrFilter.sgFieldsSelectEditor(Sender: TObject; aCol, aRow: Integer;
  var Editor: TWinControl);
var
  S: string;
begin
  S := sgFields.Cells[4,aRow]; //Field type
  if aCol=3 then
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
  end
  else
  if aCol = 2 then
  begin
    if S[1] <> 'L' then
    begin
      ComboBox2.BoundsRect:=sgFields.CellRect(aCol,aRow);
      ComboBox2.Text:=sgFields.Cells[sgFields.Col,sgFields.Row];
      Editor:=ComboBox2;
    end
  end;

end;

procedure TfrFilter.SpeedButton2Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.

