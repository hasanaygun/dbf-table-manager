unit createtable2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, Dbf_Fields, dbf, FileUtil, RTTICtrls, Forms,
  Controls, Graphics, Dialogs, StdCtrls, Grids, Buttons, ComCtrls, ExtCtrls;

type

  { TfrCreateTable2 }

  TfrCreateTable2 = class(TForm)
    ckDeleted: TCheckBox;
    dbfDest: TDbf;
    dbfSrc: TDbf;
    SaveDialog1: TSaveDialog;
    sgNew: TStringGrid;
    btnOK: TSpeedButton;
    btnCancel: TSpeedButton;
    btnNewField: TSpeedButton;
    btnEdit: TSpeedButton;
    btnUp: TSpeedButton;
    btnDown: TSpeedButton;
    sbNewTable: TStatusBar;
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnNewFieldClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;


var
  frCreateTable2: TfrCreateTable2;
  SrcPath, SrcName: string;

implementation

uses dbfpublics, addnewfield;

{$R *.lfm}

{ TfrCreateTable2 }

procedure TfrCreateTable2.FormShow(Sender: TObject);
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
  sgNew.SetFocus;
end;

procedure TfrCreateTable2.btnOKClick(Sender: TObject);
var
  I,J: Integer;
  Buf: Pointer;
  fPath,fName: string;
  DbfFiles: TStringList;
  DbfFileNames: TDbfFileNames;
  TempFieldDefs: TDbfFieldDefs;
begin
  J := 0;
  for I := 1 to sgNew.RowCount-1 do
    if sgNew.Cells[0,I] = '1' then Inc(J);
  if J < 1 then
  begin
    MessageDlg(#10'Select at least one field!', mtWarning,[mbOk],0);
    Exit;
  end;
  if not SaveDialog1.Execute then Exit;
  if SaveDialog1.FileName = SrcPath+SrcName then
  begin
    MessageDlg(#10'Source file name is same as target file name!',
      mtWarning, [mbOk], 0 );
    Exit;
  end;
  fPath:=SaveDialog1.FileName;
  fName:=ExtractFileName(fPath);
  if FileExists(fPath) then
  begin
    I:=MessageDlg(#10+fName+' exist!'#10+
      'Overwrite this file?',mtConfirmation,[mbYes,mbNo],0);
    if I = mrNo then Exit;
    DbfFiles := TStringList.Create;
    try
      dbfSrc.GetFileNames(DbfFiles,DbfFileNames);
      if DbfFiles.Count > 0 then
      begin
        //if dfDbf in DbfFileNames then DeleteFile(ChangeFileExt(fPath,'.dbf'));
        if dfMemo in DbfFileNames then DeleteFile(ChangeFileExt(fPath,'.dbt'));
        if dfIndex in DbfFileNames then DeleteFile(ChangeFileExt(fPath,'.mdx'));
      end;
    finally
      DbfFiles.Free;
    end;
  end;
  with dbfDest do
  begin
    if Active then Close;
    Exclusive := True;
    FilePath := ExtractFilePath(fPath);
    TableName := fName;
    case Level of
      L3: TableLevel := 3;
      L4: TableLevel := 4;
      L7: TableLevel := 7;
    end;
    TempFieldDefs := TDbfFieldDefs.Create(Self);
    try
      for I:= 1 to sgNew.RowCount-1 do
        if sgNew.Cells[0,I] = '1' then
          with TempFieldDefs.AddFieldDef do
          begin
            FieldName := sgNew.Cells[1,I];
            J := StrToIntDef(sgNew.Cells[5,I],0);
            NativeFieldType:=Chr(J);
            Size := StrToIntDef(sgNew.Cells[3,I],0);
            Precision := StrToIntDef(sgNew.Cells[4,I],0);
            Required := sgNew.Cells[6,I] = '1';
          end;
      //dbf_lang.pas:
      //dbfSrc.LanguageID:=DbfLangId_TRK_857; keyboard not work!
      dbfDest.CreateTableEx(TempFieldDefs);
    finally
       FreeAndNil(TempFieldDefs);
    end;
    Sleep(500);  //View this file
    if MessageDlg(#10+fName+' created successfully!'+
      #10'Click "Yes" to transfer the data from '+dbfSrc.TableName,
      mtConfirmation,[mbYes,mbNo],0) <> mrYes then
    begin
      ModalResult := mrOk;
      Exit;
    end;
    Screen.Cursor := crHourGlass;
    Application.ProcessMessages;
    dbfDest.Open;
    try
      J := 0; //fields to transfer into new table
      for I := 0 to dbfSrc.Fields.Count-1 do
      begin
        if sgNew.Cells[0,I] <> '1' then Continue;
        fName := dbfSrc.Fields[I].FieldName;
        if sgNew.Cols[7].IndexOf(fName) >= 0 then Inc(J);
      end;
      if J > 0 then
      begin
        dbfSrc.ShowDeleted := ckDeleted.Checked;
        dbfSrc.First;
        while not dbfSrc.EOF do
        begin
          dbfDest.Append;
          for I := 0 to dbfSrc.Fields.Count-1 do
            begin
              fName := dbfSrc.Fields[I].FieldName;
              J := sgNew.Cols[7].IndexOf(fName); //old name
              if J < 0 then Continue;
              if sgNew.Cells[0,J] = '1' then
              begin
                fName := sgNew.Cells[1,J]; //new name
                if not (dbfSrc.Fields[I].IsNull) then
                  dbfDest.FieldByName(fName).Assign(dbfSrc.Fields[I]);
              end;
            end;
          if ckDeleted.Checked and dbfSrc.IsDeleted then
          begin
            Buf := dbfSrc.ActiveBuffer; //dbfSrc.GetCurrentBuffer?;
            pDbfRecord(dbfDest.ActiveBuffer)^.DeletedFlag :=
              pDbfRecord(dbfSrc.ActiveBuffer)^.DeletedFlag;
          end;
          dbfDest.Post;
          dbfSrc.Next;
        end;
      end;
    finally
      dbfDest.Close;
      Screen.Cursor := crDefault;
    end;
  end;
  ModalResult := mrOK;
end;

procedure TfrCreateTable2.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrCreateTable2.btnNewFieldClick(Sender: TObject);
var
  S: string;
  I,J: Integer;
  NativeType: Char;
begin
  frAddNewField := TfrAddNewField.Create(nil);
  try
    with frAddNewField do
    begin
      Caption := 'New Field';
      cbFieldType.Items.Clear;
      for J := 1 to FieldTypeCount[Level] do
        cbFieldType.Items.Add(XBase[Level,J].Name);
      edFieldName.MaxLength := MaxFieldLen[Level];
      cbFieldType.ItemIndex := 0;     //1
      cbFieldTypeChange(cbFieldType); //2
      edFieldName.Text := '';
      ShowModal;
      if ModalResult <> mrOk then Exit;

      J:=cbFieldType.ItemIndex+1;
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
      sgNew.Cells[0,I] := '1';              //Checked
      sgNew.Cells[1,I] := edFieldName.Text; //FieldName
      sgNew.Cells[2,I] := cbFieldType.Text; //FieldType
      sgNew.Cells[3,I] := IntToStr(seSize.Value);
      sgNew.Cells[4,I] := IntToStr(seDigit.Value);
      sgNew.Cells[5,I] := IntToStr(Ord(NativeType));
      sgNew.Cells[6,I] := '0'; //required (not work!)
      sgNew.Row := I;
    end;
  finally
    frAddNewField.Free;
  end;
end;

procedure TfrCreateTable2.btnEditClick(Sender: TObject);
var
  I,J: Integer;
  S1,S2: string;
  NativeType: Char;
begin
  if sgNew.RowCount = 1 then Exit;
  frAddNewField:=TfrAddNewField.Create(nil);
  try
    with frAddNewField do
    begin
      Caption := 'Edit Field';
      cbFieldType.Items.Clear;
      for I := 1 to FieldTypeCount[Level] do
        cbFieldType.Items.Add(XBase[Level,I].Name);
      I := sgNew.Row;
      edFieldName.MaxLength := MaxFieldLen[Level];
      edFieldName.Text := sgNew.Cells[1,I];
      cbFieldType.Text := sgNew.Cells[2,I];
      cbFieldTypeChange(cbFieldType);//must be here!
      seSize.Value := StrToIntDef(sgNew.Cells[3,I],0);
      seDigit.Value := StrToIntDef(sgNew.Cells[4,I],0);
      ShowModal;
      if ModalResult <> mrOk then Exit;

      J := cbFieldType.ItemIndex+1;
      NativeType := XBase[Level,J].NativeType;

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

      S1:=edFieldName.Text; //New field name
      J:=sgNew.Cols[1].IndexOf(S1);
      if (J <> I) and (J >= 0) then  //dont use I
      begin
        MessageDlg(#10'Field Name "'+S1+'" already exists!',
          mtWarning,[mbOK],0);
        sgNew.Row := I;
        Exit;
      end;

      S2:=sgNew.Cells[1,I]; //Old Field name
      if (S1 = S2) and (sgNew.Cells[2,I] <> cbFieldType.Text) then
      begin
        if MessageDlg(#10'Old field type: '+sgNew.Cells[2,I]+
          #10'New field type: '+cbFieldType.Text+
          #10'Changing field type, can causes loss of data!'+
          #10'Continue?', mtConfirmation,[mbYes,mbNo],0) = mrNo then Exit;
      end;

      sgNew.Cells[1,sgNew.Row] := edFieldName.Text;
      sgNew.Cells[2,sgNew.Row] := cbFieldType.Text;
      sgNew.Cells[3,sgNew.Row] := IntToStr(seSize.Value);
      sgNew.Cells[4,sgNew.Row] := IntToStr(seDigit.Value);
      sgNew.Cells[5,sgNew.Row] := IntToStr(Ord(NativeType));
    end;
  finally
    frAddNewField.Free;
  end;
end;

procedure TfrCreateTable2.btnUpClick(Sender: TObject);
var
  I,J: Integer;
begin
  I := sgNew.RowCount;
  if I < 3 then Exit;
  J := sgNew.Row;
  if J > 1 then sgNew.ExchangeColRow(False,J,J-1);
end;

procedure TfrCreateTable2.btnDownClick(Sender: TObject);
var
  I,J: Integer;
begin
  I := sgNew.RowCount;
  if I < 3 then Exit;
  J := sgNew.Row;
  if (J < I-1) then sgNew.ExchangeColRow(False,J,J+1);
end;

end.

