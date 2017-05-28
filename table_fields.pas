unit table_fields;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Grids, Buttons, db;

type

  { TfrTableFields }

  TfrTableFields = class(TForm)
    sgFields: TStringGrid;
    btnAdd: TSpeedButton;
    btnCancel: TSpeedButton;
    procedure btnAddClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure sgFieldsDblClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  frTableFields: TfrTableFields;

implementation

uses dbfpublics, define_index;

{$R *.lfm}

{ TfrTableFields }

procedure TfrTableFields.btnAddClick(Sender: TObject);
var
  S: string;
  I,J,X: Integer;
begin
  X:=sgFields.Row; //Selected row
  J:=StrToIntDef(sgFields.Cells[2,X],0);//Native
  if not (Chr(J) in FldIndexable) then
  begin
    MessageDlg(#10'Invalide index type!'#10+
      'Use only string, numeric or date.',
      mtWarning,[mbOK],0);
    Exit;
  end;
  S:=sgFields.Cells[0,X]; //FieldName
  with frDefineIndex do
  begin
    for I:=1 to sgIndex.RowCount-1 do
      if S=sgIndex.Cells[0,I] then
      begin
        if MessageDlg(#10+S+' field has a index! Continue?',
          mtWarning,[mbYes,mbNo],0)=mrNo then Exit;
      end;
    sgIndex.RowCount:=sgIndex.RowCount+1;
    I:=sgIndex.RowCount-1;
    sgIndex.Cells[0,I] := S;  //field name
    sgIndex.Cells[1,I] := ''; //index name
    if Chr(J) = '+' then      //Autoinc
      sgIndex.Cells[2,I]:=IntToStr(XOptsToByte([ixPrimary,ixExpression]))
    else
      sgIndex.Cells[2,I]:=IntToStr(XOptsToByte([ixExpression]));
    sgIndex.Cells[3,I] := IntToStr(J); //Native
    sgIndex.Cells[4,I] := S; //field name
    if Chr(J) in ['@','D'] then sgIndex.Cells[0,I] := 'DTOS('+S+')';
    sgIndex.Row:=I;
    sgIndexClick(sgIndex); {!!!}
  end;
  ModalResult:=mrOK;
end;

procedure TfrTableFields.btnCancelClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TfrTableFields.sgFieldsDblClick(Sender: TObject);
begin
  btnAddClick(nil);
end;

end.

