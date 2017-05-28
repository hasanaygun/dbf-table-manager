unit createtable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, Dbf_Fields, dbf, FileUtil, Forms,
  Controls, Graphics, Dialogs, StdCtrls, Grids, Buttons;

type

  { TfrCreateTable }

  TfrCreateTable = class(TForm)
    cbFileType: TComboBox;
    dbfNew: TDbf;
    Label1: TLabel;
    SaveDialog1: TSaveDialog;
    sgNew: TStringGrid;
    btnOK: TSpeedButton;
    btnCancel: TSpeedButton;
    btnNewField: TSpeedButton;
    btnEdit: TSpeedButton;
    btnDelete: TSpeedButton;
    btnUp: TSpeedButton;
    btnDown: TSpeedButton;
    procedure cbFileTypeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnNewFieldClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
    procedure sgNewPrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
  private
    { private declarations }
  public
    { public declarations }
  end;


var
  frCreateTable: TfrCreateTable;

implementation

uses dbfpublics, addnewfield;

{$R *.lfm}

{ TfrCreateTable }

procedure TfrCreateTable.FormCreate(Sender: TObject);
begin
  sgNew.Cells[0,0] := '#  ';
end;

procedure TfrCreateTable.cbFileTypeChange(Sender: TObject);
var
  I,J: Integer;
  fldType: string;
  OldLevel: TLevel;

begin
  OldLevel := Level;
  I := cbFileType.ItemIndex;
  Level := TLevel(I);
  for I := 1 to sgNew.RowCount-1 do
    begin
      J := StrToInt(sgNew.Cells[5,I]);
      if not (Chr(J) in NativeChars[Level]) then
      begin
        fldType := sgNew.Cells[2,I];
        MessageDlg(#10'"'+fldType+'" field not supported by ' + cbFileType.Text,
          mtWarning,[mbOk],0);
        sgNew.Row := I;
        cbFileType.ItemIndex := Ord(OldLevel);
        Level := OldLevel;
        Exit;
      end;
    end;
end;

procedure TfrCreateTable.FormShow(Sender: TObject);
begin
  sgNew.SetFocus;
end;

procedure TfrCreateTable.btnOKClick(Sender: TObject);
var
  I,J: Integer;
  fPath,fName: string;
  TempFieldDefs: TDbfFieldDefs;
begin
  if sgNew.RowCount = 1 then
  begin
    MessageDlg(#10'A DBase file must have at least one field.',
      mtWarning,[mbOk],0);
    Exit;
  end;
  if SaveDialog1.Execute then
  begin
    fPath:=SaveDialog1.FileName;
    fName:=ExtractFileName(fPath);
    if FileExists(fPath) then
    begin
      I:=MessageDlg(#10+fName+' exist!'#10+
        'Overwrite this file?',mtConfirmation,[mbYes,mbNo],0);
      if I = mrNo then Exit;
    end;
  end else Exit;
  Application.ProcessMessages;
  with dbfNew do
  begin
    Close;
    FilePath := ExtractFilePath(fPath);
    case Level of
      L3: TableLevel := 3;
      L4: TableLevel := 4;
      L7: TableLevel := 7;
    end;
    Exclusive := True;
    TableName := fName;
    TempFieldDefs := TDbfFieldDefs.Create(Self);
    try
      for I:= 1 to sgNew.RowCount-1 do
        begin
          with TempFieldDefs.AddFieldDef do
          begin
            FieldName := sgNew.Cells[1,I];
            J := StrToIntDef(sgNew.Cells[5,I],0);
            NativeFieldType:=Chr(J);
            Size := StrToIntDef(sgNew.Cells[3,I],0);
            Precision := StrToIntDef(sgNew.Cells[4,I],0);
          end;
        end;
      //dbf_lang.pas içinde
      //dbfNew.LanguageID:=DbfLangId_TRK_857; Klavye çalışmadı.
      dbfNew.CreateTableEx(TempFieldDefs);
    finally
       FreeAndNil(TempFieldDefs);
    end;
    Sleep(500);  //View this file
    MessageDlg(#10+fName+' created successfully!',
      mtConfirmation,[mbOk],0);
  end;
  ModalResult := mrOK;
end;

procedure TfrCreateTable.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrCreateTable.btnNewFieldClick(Sender: TObject);
var
  S: string;
  I,J: Integer;
  NativeType: Char;
begin
  I := cbFileType.ItemIndex; //must be here
  frAddNewField := TfrAddNewField.Create(nil);
  try
    with frAddNewField do
    begin
      Caption := 'New Field';
      cbFieldType.Items.Clear;
      case I of
        0: Level := L3;
        1: Level := L4;
        2: Level := L7;
      end;
      for J := 1 to FieldTypeCount[Level] do
        cbFieldType.Items.Add(XBase[Level,J].Name);

      edFieldName.MaxLength := MaxFieldLen[Level];
      cbFieldType.ItemIndex := 0;     //1
      cbFieldTypeChange(cbFieldType); //2
      edFieldName.Text := '';
      ShowModal;
      if ModalResult = mrOk then
      begin
        J := cbFieldType.ItemIndex+1;
        NativeType := XBase[Level,J].NativeType;
        I := sgNew.Row;
        J := sgNew.Cols[5].IndexOf('43'); //'+'=Autoinc
        if (J >= 0) and (NativeType = '+') then
        begin
          MessageDlg(#10'An "AutoInc" field already exists!',
            mtWarning, [mbOk], 0);
          begin
            sgNew.Row := I;
            Exit;
          end;
        end;
        S := edFieldName.Text; //field name
        J := sgNew.Cols[1].IndexOf(S);
        if J >= 0 then
        begin
          MessageDlg(#10'Field Name "'+S+'" already exists!',
            mtWarning,[mbOK],0);
          sgNew.Row := I;
          Exit;
        end;
        I := sgNew.RowCount;
        sgNew.RowCount := I + 1;
        sgNew.Cells[0,I] := IntToStr(I);
        sgNew.Cells[1,I] := edFieldName.Text; //FieldName
        sgNew.Cells[2,I] := cbFieldType.Text; //FieldType
        sgNew.Cells[3,I] := IntToStr(seSize.Value);
        sgNew.Cells[4,I] := IntToStr(seDigit.Value);
        sgNew.Cells[5,I] := IntToStr(Ord(NativeType));
        sgNew.Row := I;
      end;
    end;
  finally
    frAddNewField.Free;
  end;

end;

procedure TfrCreateTable.btnEditClick(Sender: TObject);
var
  S: string;
  I,J: Integer;
  NativeType: Char;
begin
  if sgNew.RowCount = 1 then Exit;
  I := cbFileType.ItemIndex; //must be here
  frAddNewField:=TfrAddNewField.Create(nil);
  try
    with frAddNewField do
    begin
      Caption := 'Edit Field';
      cbFieldType.Items.Clear;
      case I of
        0: Level := L3;
        1: Level := L4;
        2: Level := L7;
      end;
      for J := 1 to FieldTypeCount[Level] do
        cbFieldType.Items.Add(XBase[Level,J].Name);

      edFieldName.MaxLength := MaxFieldLen[Level];
      edFieldName.Text := sgNew.Cells[1,sgNew.Row];
      cbFieldType.Text := sgNew.Cells[2,sgNew.Row];
      cbFieldTypeChange(cbFieldType);//must be here!
      seSize.Value := StrToIntDef(sgNew.Cells[3,sgNew.Row],0);
      seDigit.Value := StrToIntDef(sgNew.Cells[4,sgNew.Row],0);
      ShowModal;
      if ModalResult = mrOk then
      begin
        J:=cbFieldType.ItemIndex+1;
        NativeType := XBase[Level,J].NativeType;
        I := sgNew.Row;
        J := sgNew.Cols[5].IndexOf('43'); //'+'=Autoinc
        if (J >= 0) and (I <> J) and (NativeType = '+') then
        begin
          MessageDlg(#10'An "AutoInc" field already exists!',
            mtWarning, [mbOk], 0);
          begin
            sgNew.Row := I;
            Exit;
          end;
        end;
        S := edFieldName.Text; //field name
        J := sgNew.Cols[1].IndexOf(S);
        if (J >= 0) and (I <> J) then
        begin
          MessageDlg(#10'Field Name "'+S+'" already exists!',
            mtWarning,[mbOK],0);
          sgNew.Row := I;
          Exit;
        end;
        sgNew.Cells[1,sgNew.Row] := edFieldName.Text;
        sgNew.Cells[2,sgNew.Row] := cbFieldType.Text;
        sgNew.Cells[3,sgNew.Row] := IntToStr(seSize.Value);
        sgNew.Cells[4,sgNew.Row] := IntToStr(seDigit.Value);
        sgNew.Cells[5,sgNew.Row] := IntToStr(Ord(NativeType));
      end;
    end;
  finally
    frAddNewField.Free;
  end;
end;

procedure TfrCreateTable.btnDeleteClick(Sender: TObject);
var
  I: Integer;
begin
  if sgNew.RowCount = 1 then Exit;
  if MessageDlg(#10'Delete selected row?',mtConfirmation,[mbYes,mbNo],0)=mrYes then
  begin
    if sgNew.RowCount>1 then
    begin
      sgNew.DeleteRow(sgNew.Row);
      for I := 1 to sgNew.RowCount-1 do
        sgNew.Cells[0,I] := IntToStr(I);
    end;
  end;
end;

procedure TfrCreateTable.btnUpClick(Sender: TObject);
var
  I,J,K: Integer;
begin
  I := sgNew.RowCount;
  if I < 3 then Exit;
  J := sgNew.Row;
  if J > 1 then
  begin
    sgNew.ExchangeColRow(False,J,J-1);
    for K := 1 to sgNew.RowCount-1 do
      sgNew.Cells[0,K] := InttoStr(K);
  end;
end;

procedure TfrCreateTable.btnDownClick(Sender: TObject);
var
  I,J,K: Integer;
begin
  I := sgNew.RowCount;
  if I < 3 then Exit;
  J := sgNew.Row;
  if (J < I-1) then
  begin
    sgNew.ExchangeColRow(False,J,J+1);
    for K := 1 to sgNew.RowCount-1 do
      sgNew.Cells[0,K] := InttoStr(K);
  end;
end;

procedure TfrCreateTable.sgNewPrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  MyTextStyle: TTextStyle;
begin
  if aCol = 0 then
  begin
    MyTextStyle := sgNew.Canvas.TextStyle;
    MyTextStyle.Alignment := taRightJustify;
    sgNew.Canvas.TextStyle := MyTextStyle;
  end;

end;

end.

