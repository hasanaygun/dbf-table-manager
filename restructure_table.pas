unit restructure_table;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dbf_Fields, dbf, FileUtil, Forms,
  Controls, Graphics, Dialogs, StdCtrls, Grids, Buttons, ExtCtrls, ComCtrls;

type

  { TfrRestructure }

  TfrRestructure = class(TForm)
    btnEdit: TSpeedButton;
    btnNew: TSpeedButton;
    btnOK: TSpeedButton;
    sgRestruct: TStringGrid;
    btnCancel: TSpeedButton;
    sbRestructure: TStatusBar;
    btnDelete: TSpeedButton;
    procedure btnDeleteClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure sgRestructDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure sgRestructPrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure sgRestructSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
  private
    { private declarations }
  public
    { public declarations }
  end;


var
  frRestructure: TfrRestructure;

implementation

uses dbfpublics, addnewfield;

{$R *.lfm}

{ TfrRestructure }

procedure TfrRestructure.FormCreate(Sender: TObject);
begin
  sgRestruct.Cells[0,0] := '#  ';
end;

procedure TfrRestructure.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #27 then btnCancelClick(btnCancel);
end;

procedure TfrRestructure.btnNewClick(Sender: TObject);
var
  S: string;
  I,aRow: Integer;
  NativeType: Char;
begin
  frAddNewField:=TfrAddNewField.Create(nil);
  try
    with frAddNewField do
    begin
      Caption := 'New Field';
      cbFieldType.Items.Clear;
      for I := 1 to FieldTypeCount[Level] do
        cbFieldType.Items.Add(XBase[Level,I].Name);
      edFieldName.MaxLength:=MaxFieldLen[Level];
      cbFieldType.ItemIndex:=0;       //1
      cbFieldTypeChange(cbFieldType); //2
      edFieldName.Text:='';
      ShowModal;
      if ModalResult <> mrOk then Exit;

      I := cbFieldType.ItemIndex+1;
      NativeType := XBase[Level,I].NativeType;
      aRow := sgRestruct.Row;
      I := sgRestruct.Cols[5].IndexOf('43'); //'+'=Autoinc
      if (I >= 0) and (NativeType = '+') then
      begin
        MessageDlg(#10'An "AutoInc" field already exists!',
          mtWarning, [mbOk], 0);
        begin
          sgRestruct.Row := aRow;
          Exit;
        end;
      end;
      S := edFieldName.Text;
      I := sgRestruct.Cols[1].IndexOf(S);
      if I >= 0 then
      begin
        MessageDlg(#10'Field Name "'+S+'" already exists!',
          mtWarning,[mbOK],0);
        sgRestruct.Row := aRow;
        Exit;
      end;
      aRow := sgRestruct.RowCount;
      sgRestruct.RowCount := aRow + 1;
      sgRestruct.Cells[0,aRow] := IntToStr(aRow);
      sgRestruct.Cells[1,aRow] := edFieldName.Text; //FieldName
      sgRestruct.Cells[2,aRow] := cbFieldType.Text; //FieldType
      sgRestruct.Cells[3,aRow] := IntToStr(seSize.Value);
      sgRestruct.Cells[4,aRow] := IntToStr(seDigit.Value);
      sgRestruct.Cells[5,aRow] := IntToStr(Ord(NativeType));
      sgRestruct.Cells[7,aRow] := '1';
      sgRestruct.Row := aRow;
      with TmpFieldDefs.AddFieldDef do
      begin
        FieldName := edFieldName.Text;
        I := StrToIntDef(sgRestruct.Cells[5,aRow],0);
        NativeFieldType := Chr(I);
        Size := StrToIntDef(sgRestruct.Cells[3,aRow],0);
        Precision := StrToIntDef(sgRestruct.Cells[4,aRow],0);
      end;
    end;
  finally
    frAddNewField.Free;
  end;

end;

procedure TfrRestructure.btnDeleteClick(Sender: TObject);
var
  I,J: Integer;
begin
  if sgRestruct.RowCount < 2 then Exit;
  J := sgRestruct.Row;
  if MessageDlg(#10'Delete selected row?',mtConfirmation,[mbYes,mbNo],0)=mrYes then
  begin
    sgRestruct.DeleteRow(sgRestruct.Row);
    for I := 1 to sgRestruct.RowCount-1 do
      sgRestruct.Cells[0,I] := IntToStr(I);
    TmpFieldDefs.Delete(J-1)
  end;
end;

procedure TfrRestructure.FormShow(Sender: TObject);
var
  J: Integer;
begin
  frAddNewField:=TfrAddNewField.Create(nil);
  try
    with frAddNewField do
    begin
      cbFieldType.Items.Clear;
      for J := 1 to FieldTypeCount[Level] do
        cbFieldType.Items.Add(XBase[Level,J].Name);
      edFieldName.MaxLength := MaxFieldLen[Level];
    end;
  finally
    frAddNewField.Free;
  end;
  sgRestruct.SetFocus;
end;

procedure TfrRestructure.sgRestructDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
begin
  with (Sender as TStringGrid) do
  begin
    if not (gdFixed in aState) then
    begin
      if (aCol = 1) and (Cells[7,aRow] = '1') then
      begin
        Canvas.Font.Style := [fsBold];
        Canvas.FillRect(aRect);
        Canvas.TextRect(aRect, aRect.Left + 2, aRect.Top + 2, Cells[aCol, aRow]);
      end;
    end;
  end;
end;

procedure TfrRestructure.sgRestructPrepareCanvas(sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
var
  MyTextStyle: TTextStyle;
begin
  if aCol in [0,3,4] then
  begin
    MyTextStyle := sgRestruct.Canvas.TextStyle;
    MyTextStyle.Alignment := taRightJustify;
    sgRestruct.Canvas.TextStyle := MyTextStyle;
  end;
end;

procedure TfrRestructure.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TfrRestructure.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrRestructure.btnEditClick(Sender: TObject);
var
  S1,S2: string;
  I,aRow: Integer;
  NativeType: Char;
begin
  if sgRestruct.RowCount = 1 then Exit;
  frAddNewField:=TfrAddNewField.Create(nil);
  try
    with frAddNewField do
    begin
      Caption := 'Edit Field';
      cbFieldType.Items.Clear;
      for I := 1 to FieldTypeCount[Level] do
        cbFieldType.Items.Add(XBase[Level,I].Name);
      aRow := sgRestruct.Row;
      edFieldName.MaxLength:=MaxFieldLen[Level];
      edFieldName.Text:=sgRestruct.Cells[1,aRow];
      cbFieldType.Text:=sgRestruct.Cells[2,aRow];
      cbFieldTypeChange(cbFieldType);//must be here!
      seSize.Value:=StrToIntDef(sgRestruct.Cells[3,aRow],0);
      seDigit.Value:=StrToIntDef(sgRestruct.Cells[4,aRow],0);
      ShowModal;
      if ModalResult <> mrOk then Exit;
      I := cbFieldType.ItemIndex + 1;
      NativeType := XBase[Level,I].NativeType;

      I := sgRestruct.Cols[5].IndexOf('43'); //'+'=Autoinc
      if (I >= 0) and (aRow <> I) and (NativeType = '+') then
      begin
        MessageDlg(#10'An "AutoInc" field already exists!',
          mtWarning, [mbOk], 0);
        begin
          sgRestruct.Row := aRow;
          Exit;
        end;
      end;

      S1:=edFieldName.Text; //New field name
      I:=sgRestruct.Cols[1].IndexOf(S1);
      if (I <> aRow) and (I >= 0) then  //dont use I
      begin
        MessageDlg(#10'Field Name "'+S1+'" already exists!',
          mtWarning,[mbOK],0);
        sgRestruct.Row := aRow;
        Exit;
      end;

      S2:=sgRestruct.Cells[1,aRow]; //Old Field name
      if sgRestruct.Cells[6,aRow] = '*' then //Indexed?
      begin
        if S1 <> S2 then
        begin
          MessageDlg(#10'"'+S2+'" is indexed field.'+
            #10'Can''t change name!', mtWarning,[mbOK],0);
          Exit;
        end;
        if (S1 = S2) and (sgRestruct.Cells[2,aRow] <> cbFieldType.Text) then
        begin
          MessageDlg(#10'"'+S2+'" is indexed field.'+
            #10'Can''t change field type!', mtWarning,[mbOK],0);
          Exit;
        end;
      end else
      if (S1 = S2) and (sgRestruct.Cells[2,aRow] <> cbFieldType.Text) then
      begin
        if MessageDlg(#10'Old field type: '+sgRestruct.Cells[2,aRow]+
          #10'New field type: '+cbFieldType.Text+
          #10'Changing field type, can causes loss of data!'+
          #10'Continue?', mtConfirmation,[mbYes,mbNo],0) = mrNo then Exit;
      end;
      sgRestruct.Cells[1,aRow] := edFieldName.Text;
      sgRestruct.Cells[2,aRow] := cbFieldType.Text;
      sgRestruct.Cells[3,aRow] := IntToStr(seSize.Value);
      sgRestruct.Cells[4,aRow] := IntToStr(seDigit.Value);
      sgRestruct.Cells[5,aRow] := IntToStr(Ord(NativeType));
      with TmpFieldDefs.Items[aRow-1] do
      begin
        FieldName := edFieldName.Text;
        I := StrToIntDef(sgRestruct.Cells[5,aRow],0);
        NativeFieldType := Chr(I);
        Size := StrToIntDef(sgRestruct.Cells[3,aRow],0);
        Precision := StrToIntDef(sgRestruct.Cells[4,aRow],0);
      end;
    end;
  finally
    frAddNewField.Free;
  end;
end;

procedure TfrRestructure.sgRestructSelectCell(Sender: TObject; aCol,
  aRow: Integer; var CanSelect: Boolean);
begin
  btnDelete.Enabled := sgRestruct.Cells[7, aRow] = '1';
end;


end.

