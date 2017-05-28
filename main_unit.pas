unit main_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, dbf, dbf_fields, dbf_common, FileUtil, RTTICtrls,
  Forms, Controls, Graphics, Dialogs, Menus, ExtCtrls, DBGrids, ComCtrls,
  DbCtrls, Buttons, Grids, StdCtrls, dbf_dbffile, dbf_idxfile,
  variants, fpSpreadsheet, fpsTypes;

type

  { TfrMain }

  TfrMain = class(TForm)
    cbIndexes: TComboBox;
    DataSource1: TDataSource;
    dbfMain: TDbf;
    dbGridMain: TDBGrid;
    dbNav: TDBNavigator;
    Image2: TImage;
    ImageList1: TImageList;
    Label4: TLabel;
    lbIndexes: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    Panel3: TPanel;
    smExport: TMenuItem;
    smCloneTable: TMenuItem;
    smPackTable: TMenuItem;
    smEmpty: TMenuItem;
    smRestructure: TMenuItem;
    smSearch: TMenuItem;
    smFilter: TMenuItem;
    smExclusive: TMenuItem;
    smAbout: TMenuItem;
    mmHelp: TMenuItem;
    smRegenIndexes: TMenuItem;
    smShowDeleted: TMenuItem;
    mmTools: TMenuItem;
    smIndexes: TMenuItem;
    smNewTable: TMenuItem;
    smOpenTable: TMenuItem;
    smCloseTable: TMenuItem;
    smExit: TMenuItem;
    mmFile: TMainMenu;
    OpenDialog1: TOpenDialog;
    sbMain: TStatusBar;
    ToolBar1: TToolBar;
    tbSearch: TToolButton;
    tbFilter: TToolButton;
    ToolBar2: TToolBar;
    tbNew: TToolButton;
    tbExport: TToolButton;
    tbOpen: TToolButton;
    tbClose: TToolButton;
    tbRestructure: TToolButton;
    tbIndexes: TToolButton;
    ToolButton1: TToolButton;
    tbClone: TToolButton;
    tbPack: TToolButton;
    tbEmpty: TToolButton;
    ToolButton6: TToolButton;
    tbExit: TToolButton;
    procedure cbIndexesChange(Sender: TObject);
    procedure dbfMainAfterClose(DataSet: TDataSet);
    procedure dbfMainAfterDelete(DataSet: TDataSet);
    procedure dbfMainAfterOpen(DataSet: TDataSet);
    procedure dbfMainAfterPost(DataSet: TDataSet);
    procedure dbfMainAfterRefresh(DataSet: TDataSet);
    procedure dbGridMainEditButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure mmToolsClick(Sender: TObject);
    procedure smAboutClick(Sender: TObject);
    procedure smCloneTableClick(Sender: TObject);
    procedure smExclusiveClick(Sender: TObject);
    procedure smExitClick(Sender: TObject);
    procedure smExportClick(Sender: TObject);
    procedure smFilterClick(Sender: TObject);
    procedure smIndexesClick(Sender: TObject);
    procedure smCloseTableClick(Sender: TObject);
    procedure smNewTableClick(Sender: TObject);
    procedure smOpenTableClick(Sender: TObject);
    procedure smPackTableClick(Sender: TObject);
    procedure smRegenIndexesClick(Sender: TObject);
    procedure smRestructureClick(Sender: TObject);
    procedure smSearchClick(Sender: TObject);
    procedure smShowDeletedClick(Sender: TObject);
    procedure smEmptyClick(Sender: TObject);
    procedure tbCloseClick(Sender: TObject);
    procedure tbEmptyClick(Sender: TObject);
    procedure tbExitClick(Sender: TObject);
    procedure tbExportClick(Sender: TObject);
    procedure tbFilterClick(Sender: TObject);
    procedure tbIndexesClick(Sender: TObject);
    procedure tbNewClick(Sender: TObject);
    procedure tbOpenClick(Sender: TObject);
    procedure tbPackClick(Sender: TObject);
    procedure tbRestructureClick(Sender: TObject);
    procedure tbSearchClick(Sender: TObject);
    procedure tbCloneClick(Sender: TObject);

  private
    function RecordCountStr(Dbf: TDbf): string;
    procedure SetIcon(Sender: TObject; Index: Integer);
    function ExportToSpreadSheet(Sender: TObject): Boolean;
    function ExportToCSV(Sender: TObject): Integer;
  public
    {}
  end;

var
  frMain: TfrMain;
  Filtered: Boolean;
  dbfMainInfo: string;

implementation

uses
  dbfpublics, createtable, createtable2, restructure_table, define_index,
  about, calendar_unit, memo_view, new_opt, filter_records, locate_unit,
  clonetable, export_dbf;

{$R *.lfm}

{ TfrMain }

function TfrMain.RecordCountStr(Dbf: TDbf): string;
begin
  if Dbf.ExactRecordCount > 0 then
    Result := IntToStr(Dbf.ExactRecordCount) + ' records'
  else
    Result := IntToStr(Dbf.ExactRecordCount) + ' record'
end;

procedure TfrMain.SetIcon(Sender: TObject; Index: Integer);
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  try
    if Sender.ClassName = 'TSpeedButton' then
      begin
        ImageList1.GetBitmap(Index,Bitmap);
        (Sender as TSpeedButton).Glyph.Assign(Bitmap);
      end
  finally
    Bitmap.Free;
  end;
end;

function TfrMain.ExportToSpreadSheet(Sender: TObject): Boolean;
var
  S: string;
  I,J: Integer;
  Bookmark: TBookmark;

begin
  Result := False;
  with (Sender as TfrExport) do
  begin
    J := 0;
    for I := 1 to sgFields.RowCount-1 do
      if sgFields.Cells[0,I] = '1' then Inc(J);
    SetLength(fSelected, J);
    try
      J := 0;
      for I := 1 to sgFields.RowCount-1 do
      if sgFields.Cells[0,I] = '1' then
      begin
        fSelected[J].fName := sgFields.Cells[1,I];
        fSelected[J].fDigit := StrToInt(sgFields.Cells[4,I]);
        S := sgFields.Cells[5,I];
        fSelected[J].fType := S[1];
        Inc(J);
      end;
      Dataprovider := TDataProvider.Create;
      Dataprovider.Dbf := dbfMain;
      try
        Workbook := TsWorkbook.Create;
        dbfMain.DisableControls;
        Bookmark := dbfMain.Bookmark;
        try
          Worksheet := Workbook.AddWorksheet(dbfMain.TableName);
          Workbook.Options := [boVirtualMode];
          //Workbook.Options := [boVirtualMode, boBufStream];
          { boBufStream can be omitted, but is important for large files: it causes
            writing temporary data to a buffered file stream instead of a pure
            memory stream which can overflow memory. In cases, the option can slow
            down the writing process a bit. }

          { Next two numbers define the size of virtual spreadsheet.
            In case of a database, VirtualRowCount is the RecordCount, VirtualColCount
            the number of fields to be written to the spreadsheet file }

          {Don't use dbfMain.RecordCount}
          Worksheet.VirtualRowCount := dbfMain.ExactRecordCount+1; //+1 for header
          Worksheet.VirtualColCount := Length(fSelected);
          dbfMain.First;
          { The event handler for OnWriteCellData links the Workbook to the method
            from which it gets the data to be written. }
          Worksheet.OnWriteCellData := @Dataprovider.WriteCellDataHandler;

          { If we want to change the format of some cells we have to provide this
            format in template cells of the Worksheet. In the example, the first
            row whould be in bold letters and have a gray background.
            Therefore, we define a "header template cell" and pass this in the
            NeedCellData event handler.}
          Worksheet.WriteFontStyle(0, 0, [fssBold]);
          Worksheet.WriteBackgroundColor(0, 0, scSilver);
          Worksheet.WriteBorders(0, 0, [cbEast, cbNorth, cbWest, cbSouth]);
          //Worksheet.WriteHorAlignment(0,0,haRight);
          HeaderTemplate := Worksheet.FindCell(0, 0);

          Worksheet.WriteFontStyle(1, 0, []);
          //Worksheet.WriteBorders(1, 0, [cbEast, cbNorth, cbWest, cbSouth]);
          Worksheet.WriteHorAlignment(1,0,haRight);
          OtherTemplate := Worksheet.FindCell(1, 0);

          Counter := 0;
          { In case of a database, you would open the dataset before calling this: }
          Workbook.WriteToFile(fPath, FILE_FORMATS[rgFileFormat.ItemIndex], true);

        finally
          dbfMain.Bookmark := Bookmark;
          dbfMain.EnableControls;
          Workbook.Free;
        end;
      finally
        Dataprovider.Dbf := nil;
        Dataprovider.Free;
      end;
    finally
      SetLength(fSelected, 0);
    end;
  end;
  Result := True;
end;

function TfrMain.ExportToCSV(Sender: TObject): Integer;
var
  F: Text;
  AData,S: string;
  I,J: Integer;
  Bookmark: TBookmark;

begin
  Result := 0;
  System.Assign(F,fPath);
  {$i-} Rewrite(F); {$i+}
  if IOresult <> 0 then
  begin
    Result := -1;
    Exit;
  end;
  with (Sender as TfrExport) do
  try
    J := 0;
    for I := 1 to sgFields.RowCount-1 do
      if sgFields.Cells[0,I] = '1' then Inc(J);
    SetLength(fSelected, J);
    dbfMain.DisableControls;
    Bookmark := dbfMain.Bookmark;
    try
      J := 0;
      for I := 1 to sgFields.RowCount-1 do
        if sgFields.Cells[0,I] = '1' then
        begin
          fSelected[J].fName := sgFields.Cells[1,I];
          fSelected[J].fDigit := StrToInt(sgFields.Cells[4,I]);
          S := sgFields.Cells[5,I];
          fSelected[J].fType := S[1];
          Inc(J);
        end;

      AData := '';
      for I := Low(fSelected) to High(fSelected) do
        AData := AData + csvQuoteChar + fSelected[I].fName + csvQuoteChar + csvDelimiter;
      Delete(AData, Length(AData),1);
      WriteLn(F, AData);

      Counter := 0;
      dbfMain.First;
      while not dbfMain.EOF do
      begin
        AData := '';
        for I := Low(fSelected) to High(fSelected) do
          begin
            case fSelected[I].fType of
              'B':
                if dbfMain.FieldByName(fSelected[I].fName).IsNull then S := ''
                else S := '[Blob]';
              'G':
                if dbfMain.FieldByName(fSelected[I].fName).IsNull then S := ''
                else S := '[DbaseOle]';
              'M':
                if dbfMain.FieldByName(fSelected[I].fName).IsNull then S := ''
                else S := '[Memo]';
              '@','D':
                if dbfMain.FieldByName(fSelected[I].fName).IsNull then S := ''
                else
                  S := FormatDateTime('DD'+DateSeparator+'MM'+DateSeparator+'YYYY',
                    dbfMain.FieldByName(fSelected[I].fName).AsDateTime);
              'F','N':
                begin
                  if dbfMain.FieldByName(fSelected[I].fName).IsNull then S := ''
                  else if fSelected[I].fDigit > 0 then
                    S := FormatFloat('0.'+StringOfChar('0',fSelected[I].fDigit),
                      dbfMain.FieldByName(fSelected[I].fName).AsFloat)
                  else
                    S := dbfMain.FieldByName(fSelected[I].fName).Text;
                end;
              else
                if dbfMain.FieldByName(fSelected[I].fName).IsNull then S := ''
                else S := dbfMain.FieldByName(fSelected[I].fName).Text;
            end;
            AData := AData + csvQuoteChar + S + csvQuoteChar + csvDelimiter;
          end;
        Delete(AData,Length(AData),1);
        WriteLn(F, AData);
        dbfMain.Next;
        Inc(Counter);
      end;

    finally
      dbfMain.Bookmark := Bookmark;
      dbfMain.EnableControls;
      SetLength(fSelected, 0);
    end;
  finally
    {$i-} System.Close(F); {$i+}
  end;
  Result := 1;
end;

procedure TfrMain.FormShow(Sender: TObject);
begin
  tbNew.Enabled := not dbfMain.Active;
  tbClose.Enabled := dbfMain.Active;
  tbExport.Enabled := dbfMain.Active;
  tbEmpty.Enabled := dbfMain.Active;
  tbPack.Enabled := dbfMain.Active;
  tbIndexes.Enabled := dbfMain.Active;
  tbRestructure.Enabled := dbfMain.Active;
  cbIndexes.Enabled := False;
  lbIndexes.Enabled := False;
  tbFilter.Enabled := False;
  tbFilter.Caption := 'Filter ';
  tbFilter.ImageIndex := 11;
  tbSearch.Enabled := False;
  smFilter.Caption := 'Filter Records...';
  if ParamCount > 0 then
  begin
    dbfMain.TableName := ParamStr(1);
    dbfMain.Exclusive := True; //Before open;
    dbfMain.Open;
  end;

end;

procedure TfrMain.MenuItem1Click(Sender: TObject);
begin
  smNewTable.Enabled := tbNew.Enabled;
  smOpenTable.Enabled := tbOpen.Enabled;
  smCloneTable.Enabled := tbOpen.Enabled;
  smEmpty.Enabled := (dbfMain.Active) and (dbfMain.RecordCount > 0) and (not dbfMain.Filtered);
  smExport.Enabled := (dbfMain.Active) and (dbfMain.ExactRecordCount > 0);
  smPackTable.Enabled := (dbfMain.Active) and (not dbfMain.Filtered);
  smRestructure.Enabled := tbRestructure.Enabled;
  smCloseTable.Enabled := tbClose.Enabled;
  smExit.Enabled := tbExit.Enabled;
end;

procedure TfrMain.mmToolsClick(Sender: TObject);
begin
  smFilter.Enabled := tbFilter.Enabled;
  smSearch.Enabled := tbSearch.Enabled;
  smExclusive.Enabled := dbfMain.Active;
  smExclusive.Checked:=dbfMain.Exclusive;
  smIndexes.Enabled := tbIndexes.Enabled;
  smRegenIndexes.Enabled := (dbfMain.Active) and (dbfMain.Indexes.Count > 0);
  smShowDeleted.Enabled := (dbfMain.Active) and (dbfMain.RecordCount > 0);
  smShowDeleted.Checked := dbfMain.ShowDeleted;
end;

procedure TfrMain.smAboutClick(Sender: TObject);
begin
  frAbout := TfrAbout.Create(nil);
  try
    frAbout.ShowModal;
  finally
    frAbout.Free;
  end;
end;

procedure TfrMain.smCloneTableClick(Sender: TObject);
var
  C: Char;
  I: Integer;
  Ok: Boolean;
begin
  Ok := dbfMain.Active;
  if not Ok then
    if not OpenDialog1.Execute then Exit;
  frCloneTable := TfrCloneTable.Create(nil);
  with frCloneTable do
  try
    if Ok then
    begin
      if not dbfMain.Exclusive then smExclusiveClick(smExclusive);
      dbfSrc := dbfMain;
    end
    else
    begin
      dbfSrc := TDbf.Create(nil);
      dbfSrc.TableName := OpenDialog1.FileName;
      dbfSrc.Exclusive := True; //Before open;
    end;
    try
      if not dbfSrc.Active then dbfSrc.Open;
      case dbfSrc.TableLevel of
        3: Level := L3;
        4: Level := L4;
        7: Level := L7;
        else
          begin
            MessageDlg(#10'Unsupported file type: "'+
              DBaseVersion(dbfSrc)+'"', mtWarning,[mbOK],0);
            Exit;
          end;
      end;
      sbCloneTable.Panels[0].Text :='   '+ ExtractFileName(OpenDialog1.FileName)+
        ' - [ '+DBaseVersion(dbfSrc)+' ]' + '    '+ RecordCountStr(dbfSrc);
      for I := 1 to sgFields.RowCount-1 do sgFields.Rows[I].Clear;
      sgFields.RowCount := dbfSrc.DbfFieldDefs.Count+1;
      for I := 1 to dbfSrc.DbfFieldDefs.Count do
        with dbfSrc.DbfFieldDefs do
        begin
          sgFields.Cells[0,I] := Items[I-1].FieldName;
          C := Items[I-1].NativeFieldType;
          sgFields.Cells[1,I] := VCLType(C,Level);
        end;
      for I := 1 to sgIndexes.RowCount-1 do sgIndexes.Rows[I].Clear;
      sgIndexes.RowCount := dbfSrc.IndexDefs.Count+1;
      for I := 1 to dbfSrc.IndexDefs.Count do
        sgIndexes.Cells[0,I] := dbfSrc.IndexDefs[I-1].Name;
      SrcPath := dbfSrc.FilePath;
      SrcName := dbfSrc.TableName;
      ShowModal;
      if ModalResult <> mrOk then Exit;
    finally
      if not Ok then
      begin
        if dbfSrc.Active then dbfSrc.Close;
        dbfSrc.Free;
      end
      else
        dbfSrc := nil;
    end;
    if dbfMain.Active then dbfMain.Close;
    dbfMain.Exclusive := True;
    dbfMain.FilePath := dbfDest.FilePath;
    dbfMain.FilePathFull := dbfDest.FilePathFull;
    dbfMain.TableName := dbfDest.TableName;
    dbfMain.ShowDeleted := False;
    dbfMain.Open;
    MessageDlg(#10'Process completed successfully!', mtConfirmation,[mbOk],0);
  finally
    frCloneTable.Free;
  end;

end;

procedure TfrMain.smExclusiveClick(Sender: TObject);
begin
  smExclusive.Checked := not smExclusive.Checked;
  dbfMain.Close;
  dbfMain.Exclusive := smExclusive.Checked;
  dbfMain.Open;
end;

procedure TfrMain.smExitClick(Sender: TObject);
begin
  tbExitClick(tbExit);
end;

procedure TfrMain.smExportClick(Sender: TObject);
var
  C: Char;
  I: Integer;
begin
  frExport := TfrExport.Create(nil);
  with frExport do
  try
    case dbfMain.TableLevel of
      3: Level := L3;
      4: Level := L4;
      7: Level := L7;
      else
        begin
          MessageDlg(#10'Unsupported file type: "'+
            DbaseVersion(dbfMain)+'"', mtWarning,[mbOK],0);
          Exit;
        end;
    end;
    sgFields.RowCount := 1;
    for I := 0 to dbfMain.DbfFieldDefs.Count-1 do
      begin
        C := dbfMain.DbfFieldDefs.Items[I].NativeFieldType;
        sgFields.RowCount := I+2;
        sgFields.Cells[0,I+1] := '1';
        sgFields.Cells[1,I+1] := dbfMain.DbfFieldDefs.Items[I].FieldName;
        sgFields.Cells[2,I+1] := VCLType(C,Level);
        sgFields.Cells[3,I+1] := IntToStr(dbfMain.DbfFieldDefs.Items[I].Size);
        sgFields.Cells[4,I+1] := IntToStr(dbfMain.DbfFieldDefs.Items[I].Precision);
        sgFields.Cells[5,I+1] := C; //NativeType
      end;
    ShowModal;
    if ModalResult <> mrOk then Exit;

    Screen.Cursor := crHourGlass;
    try
      Application.ProcessMessages;
      if rgFileFormat.ItemIndex = 5 then
      begin
        I := ExportToCSV(frExport);
        if I = -1 then
        begin
          Screen.Cursor := crDefault;
          MessageDlg(#10'Error when writing to disk!', mtError, [mbOk], 0)
        end
        else
        if I = 0 then
        begin
          Screen.Cursor := crDefault;
          MessageDlg(#10'Failed to export database table!', mtError, [mbOk], 0)
        end
        else
        begin
          Screen.Cursor := crDefault;
          MessageDlg(#10+IntToStr(Counter)+' records exported successfully'+
            #10'from "'+dbfMain.TableName+'" to "'+ ExtractFileName(fPath)+'*',
            mtInformation, [mbOk], 0);
        end;
      end
      else
      begin
        if ExportToSpreadSheet(frExport) then
        begin
          Screen.Cursor := crDefault;
          MessageDlg(#10+IntToStr(Counter)+' records exported successfully'+
            #10'from "'+dbfMain.TableName+'" to "'+ ExtractFileName(fPath)+'*',
            mtInformation, [mbOk], 0);
        end
        else
        begin
          Screen.Cursor := crDefault;
          MessageDlg(#10'Failed to export database table!', mtError, [mbOk], 0)
        end;
      end;

    finally
      Screen.Cursor := crDefault;
    end;

  finally
    Free;
  end;

end;

procedure TfrMain.smFilterClick(Sender: TObject);
var
  C: Char;
  I,J: Integer;
begin
  if Filtered then
  begin
    dbfMain.Filtered := False;
    dbfMain.Filter := '';
    Filtered := False;
    tbFilter.Caption := 'Filter ';
    tbFilter.ImageIndex := 11;
    smFilter.Caption := 'Filter Records...';
    tbRestructure.Enabled := True;
    tbIndexes.Enabled := True;
    tbSearch.Enabled := True;
    Exit;
  end;
  frFilter := TfrFilter.Create(nil);
  dbfMain.DisableControls;
  with frFilter do
  try
    for I := 1 to sgFields.RowCount - 1 do
      sgFields.Rows[I].Clear;
    sgFields.RowCount := 1;
    J := 0;
    for I := 0 to dbfMain.DbfFieldDefs.Count - 1 do
      begin
        C := dbfMain.DbfFieldDefs.Items[I].NativeFieldType;
        if C in ['+','C','I','F','N','L','D','@'] then
        begin
          Inc(J); //1.
          sgFields.RowCount := J + 1;
          sgFields.Cells[0,J] := '0';
          sgFields.Cells[1,J] := dbfMain.DbfFieldDefs.Items[I].FieldName;
          sgFields.Cells[2,J] := '=';
          sgFields.Cells[4,J] := dbfMain.DbfFieldDefs.Items[I].NativeFieldType;
          sgFields.Cells[5,J] := IntToStr(dbfMain.DbfFieldDefs.Items[I].Precision);
        end;
      end;
    ShowModal;
    if ModalResult = mrOk then
    begin
      Filtered := True;
      tbSearch.Enabled := False;
      tbRestructure.Enabled := False;
      tbIndexes.Enabled := False;
      tbFilter.Caption := 'Unfilter ';
      tbFilter.ImageIndex := 12;
      smFilter.Caption := 'Remove Filter';
    end;
  finally
    dbfMain.EnableControls;
    frFilter.Free;
  end;
end;

procedure TfrMain.smIndexesClick(Sender: TObject);
begin
  tbIndexesClick(tbIndexes);
end;

procedure TfrMain.dbfMainAfterClose(DataSet: TDataSet);
begin
  if dbfMain.Filtered then
  begin
    dbfMain.Filtered := False;
    dbfMain.Filter := '';
  end;
  dbGridMain.Columns.Clear;
  Filtered := False;
  smFilter.Caption := 'Filter Records...';
  tbNew.Enabled := True;
  tbOpen.Enabled := True;
  tbClose.Enabled := False;
  tbExport.Enabled := False;
  tbEmpty.Enabled := False;
  tbPack.Enabled := False;
  tbIndexes.Enabled := False;
  tbRestructure.Enabled := False;
  tbFilter.Caption := 'Filter ';
  tbFilter.ImageIndex := 11;
  tbFilter.Enabled := False;
  tbSearch.Enabled := False;
  cbIndexes.Items.Clear;
  cbIndexes.Enabled := False;
  lbIndexes.Enabled := False;
  sbMain.Panels[0].Text := '';
end;

procedure TfrMain.dbfMainAfterDelete(DataSet: TDataSet);
begin
  dbfMain.ShowDeleted := False;
  sbMain.Panels[0].Text := dbfMainInfo + '    ' + RecordCountStr(dbfMain);
end;

procedure TfrMain.cbIndexesChange(Sender: TObject);
begin
  if cbIndexes.Items.Count > 0 then
    dbfMain.IndexName:=cbIndexes.Text;
end;

procedure TfrMain.dbfMainAfterOpen(DataSet: TDataSet);
var
  S: string;
  I,J: Integer;
begin
  J := 0;
  dbGridMain.Columns.Clear;
  with TDbf(DataSet) do
  for I := 0 to DbfFieldDefs.Count-1 do
  begin
    dbGridMain.Columns.Add;
    dbGridMain.Columns[J].FieldName := DbfFieldDefs.Items[J].FieldName;
    if DbfFieldDefs.Items[J].NativeFieldType in ['@','B','D','G','M'] then
      dbGridMain.Columns[J].ButtonStyle := cbsEllipsis;
    Inc(J);
  end;
  for I := 0 to DataSet.Fields.Count-1 do
    case DataSet.Fields[I].DataType of
      ftSmallint,ftInteger,ftWord,ftFloat,ftLargeint:
        begin
          J:=DataSet.Fields[I].FieldDef.Precision;
          if J>0 then
          begin
            SetLength(S,J);
            FillChar(S[1],J,'0');
            TFloatfield(DataSet.Fields[I]).DisplayFormat := '0.' + S;
            //TFloatfield(DataSet.Fields[I]).DisplayFormat:='####0.00';
          end;
        end;
    end;
  Filtered := dbfMain.Filtered;
  tbNew.Enabled := False;
  tbOpen.Enabled := False;
  tbClose.Enabled := True;
  tbExport.Enabled := True;
  tbEmpty.Enabled := True;
  tbPack.Enabled := True;
  tbIndexes.Enabled := True;
  tbRestructure.Enabled := True;
  tbFilter.Enabled := True;
  tbFilter.Caption := 'Filter';
  tbFilter.ImageIndex := 11;
  tbSearch.Enabled := True;
  cbIndexes.Items.Clear;
  if dbfMain.Indexes.Count > 0 then
  begin
    cbIndexes.Items.Add('');
    for I := 0 to dbfMain.Indexes.Count-1 do
      cbIndexes.Items.Add(dbfMain.Indexes[I].Name);
    cbIndexes.Enabled := True;
    lbIndexes.Enabled := True;
    cbIndexes.ItemIndex := -1;
  end
  else
  begin
    cbIndexes.Enabled := False;
    lbIndexes.Enabled := False;
  end;
  dbfMainInfo := dbfMain.FilePath + dbfMain.TableName + ' - [ '+DBaseVersion(dbfMain)+' ]';
  sbMain.Panels[0].Text := dbfMainInfo + '    ' + RecordCountStr(dbfMain);
end;

procedure TfrMain.dbfMainAfterPost(DataSet: TDataSet);
begin
  sbMain.Panels[0].Text := dbfMainInfo + '    ' + RecordCountStr(dbfMain);
end;

procedure TfrMain.dbfMainAfterRefresh(DataSet: TDataSet);
begin
  sbMain.Panels[0].Text := dbfMainInfo + '    ' + RecordCountStr(dbfMain);
end;

procedure TfrMain.dbGridMainEditButtonClick(Sender: TObject);
var
  I: Integer;
  BlobStream: TStream;
begin
  I := (Sender as TDBGrid).SelectedIndex;
  if dbfMain.DbfFieldDefs.Items[I].NativeFieldType in ['@','D'] then
  begin
    frCalendar := TfrCalendar.Create(nil);
    with frCalendar do
    try
      Left:=Mouse.CursorPos.x;
      Top:=Mouse.CursorPos.y;
      if dbfMain.Fields[I].AsString > '' then
        Calendar1.DateTime := dbfMain.Fields[I].AsDateTime;
      ShowModal;
      if ModalResult <> mrOk then Exit;
      dbfMain.Edit;
      dbfMain.Fields[I].AsDateTime:=Calendar1.DateTime;
      dbfMain.Post;
    finally
      Free;
    end;
  end
  else
  if dbfMain.DbfFieldDefs.Items[I].NativeFieldType in ['B','G','M'] then
  begin
    frMemoView := TfrMemoView.Create(nil);
    with frMemoView do
    try
      Caption := (Sender as TDBGrid).Columns[I].FieldName;
      if dbfMain.Fields[I].IsBlob then
      begin
        if not dbfMain.Fields[I].IsNull then
        begin
          BlobStream:= dbfMain.CreateBlobStream(dbfMain.Fields[I], bmread);
          try
            try
              BlobType := btPicture;
              Image1.Picture.LoadFromStream(BlobStream);
            except
              BlobType := btText;
              Memo1.Lines.LoadFromStream(BlobStream);
            end;
          finally
            BlobStream.free;
          end;
        end;
        ShowModal;
        if ModalResult <> mrOk then Exit;
        dbfMain.Edit;
        BlobStream := dbfMain.CreateBlobStream(dbfMain.Fields[I], bmwrite);
        try
          if BlobType = btPicture then
            Image1.Picture.SaveToStream(BlobStream)
          else
            Memo1.Lines.SaveToStream(BlobStream);
        finally
          BlobStream.Free;
        end;
        dbfMain.Post;
      end;
    finally
      Free;
    end;
  end;
end;

procedure TfrMain.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  I: Integer;
begin
  CanClose := False;
  if dbfMain.State in [dsEdit, dsInsert] then
  begin
    I := MessageDlg(#10'Do you want to save the changes?',
      mtConfirmation, [mbYes,mbNo,mbCancel],0);
    if I = mrCancel then Exit;
    if I = mrYes then dbNav.BtnClick(nbPost) else
    if I = mrNo then dbNav.BtnClick(nbCancel);
  end;
  if dbfMain.Active then dbfMain.Close;
  CanClose := True;
end;

procedure TfrMain.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
begin
  if Length(FileNames) > 1 then
  begin
    MessageDlg(#10'Drag and drop only one file!', mtWarning, [mbOk], 0);
    Exit;
  end;
  if Length(FileNames) = 1 then
  begin
    if dbfMain.Active then tbCloseClick(tbClose);
    if dbfMain.Active then Exit;
    dbfMain.TableName := FileNames[0];
    dbfMain.Exclusive := True; //Before open;
    dbfMain.Open;
  end;
end;

procedure TfrMain.FormResize(Sender: TObject);
begin
  if Height < 580 then Height := 580;
  if Width < 896 then Width := 896;
  sbMain.Panels[0].Width := Width;
end;

procedure TfrMain.smCloseTableClick(Sender: TObject);
begin
  tbCloseClick(tbClose);
end;

procedure TfrMain.smNewTableClick(Sender: TObject);
begin
  tbNewClick(tbNew);
end;

procedure TfrMain.smOpenTableClick(Sender: TObject);
begin
  tbOpenClick(tbOpen);
end;

procedure TfrMain.smPackTableClick(Sender: TObject);
var
  Ok: Boolean;
begin
  if MessageDlg(#10'Deleted records will be physically removed!'+
    #10'Do you want to pack this table?',
    mtConfirmation, [mbYes,mbNo],0) = mrYes then
    begin
      Ok := dbfMain.Exclusive;
      if not Ok then
      begin
        dbfMain.Close;
        dbfMain.Exclusive := True;
        dbfMain.Open;
      end;
      Screen.Cursor := crHourGlass;
      try
        Application.ProcessMessages;
        dbfMain.PackTable;
      finally
        Screen.Cursor := crDefault;
      end;
      if not Ok then
      begin
        dbfMain.Close;
        dbfMain.Exclusive := False;
        dbfMain.Open;
      end
      else
        dbfMain.Refresh;
    end;
end;

procedure TfrMain.smRegenIndexesClick(Sender: TObject);
var
  Ok: Boolean;
begin
  if MessageDlg(#10'All indexes will be re-created!'+
    #10'Do you want to continue?',
    mtConfirmation, [mbYes,mbNo],0) = mrYes then
    begin
      Ok := dbfMain.Exclusive;
      if not Ok then
      begin
        dbfMain.Close;
        dbfMain.Exclusive:=True;
        dbfMain.Open;
      end;
      Screen.Cursor := crHourGlass;
      try
        Application.ProcessMessages;
        dbfMain.RegenerateIndexes;
      finally
        Screen.Cursor := crDefault;
      end;
      if not Ok then
      begin
        dbfMain.Close;
        dbfMain.Exclusive := False;
        dbfMain.Open;
      end
      else
        dbfMain.Refresh;
    end;
end;

procedure TfrMain.smRestructureClick(Sender: TObject);
begin
  tbRestructureClick(tbRestructure);
end;

procedure TfrMain.smSearchClick(Sender: TObject);
var
  C: Char;
  I,J: Integer;
begin
  frLocate := TfrLocate.Create(nil);
  dbfMain.DisableControls;
  with frLocate do
  try
    for I := 1 to sgFields.RowCount - 1 do
      sgFields.Rows[I].Clear;
    sgFields.RowCount := 1;
    J := 0;
    for I := 0 to dbfMain.DbfFieldDefs.Count - 1 do
      begin
        C := dbfMain.DbfFieldDefs.Items[I].NativeFieldType;
        if C in ['+','C','I','F','N','L','D','@'] then
        begin
          Inc(J); //1.
          sgFields.RowCount := J + 1;
          sgFields.Cells[0,J] := '0';
          sgFields.Cells[1,J] := dbfMain.DbfFieldDefs.Items[I].FieldName;
          sgFields.Cells[3,J] := dbfMain.DbfFieldDefs.Items[I].NativeFieldType;
          sgFields.Cells[4,J] := IntToStr(dbfMain.DbfFieldDefs.Items[I].Precision);
        end;
      end;
    VarCreated := False;
    ShowModal;
    if VarCreated then
    begin
      VarClear(V);
      V := Unassigned;
    end;
  finally
    dbfMain.EnableControls;
    frLocate.Free;
  end;

end;

procedure TfrMain.smShowDeletedClick(Sender: TObject);
begin
  dbfMain.ShowDeleted := not dbfMain.ShowDeleted;
  smShowDeleted.Checked := dbfMain.ShowDeleted;
end;

procedure TfrMain.smEmptyClick(Sender: TObject);
var
  Ok: Boolean;
begin
  if MessageDlg(#10'All records will be deleted from the table!'+
    #10'Do you want to continue?',
    mtConfirmation, [mbYes,mbNo],0) = mrYes then
    begin
      Ok := dbfMain.Exclusive;
      if not Ok then
      begin
        dbfMain.Close;
        dbfMain.Exclusive := True;
        dbfMain.Open;
      end;
      dbfMain.EmptyTable;
      if not Ok then
      begin
        dbfMain.Close;
        dbfMain.Exclusive := False;
        dbfMain.Open;
      end;
      dbfMain.Refresh;
    end;
end;

procedure TfrMain.tbCloseClick(Sender: TObject);
  var
  I: Integer;
begin
  if dbfMain.State in [dsEdit, dsInsert] then
  begin
    I := MessageDlg(#10'Do you want to save the changes?',
      mtConfirmation, [mbYes,mbNo,mbCancel],0);
    if I = mrCancel then Exit;
    if I = mrYes then dbNav.BtnClick(nbPost) else
    if I = mrNo then dbNav.BtnClick(nbCancel);
  end;
  dbfMain.Close;
end;

procedure TfrMain.tbEmptyClick(Sender: TObject);
begin
  smEmptyClick(smEmpty);
end;

procedure TfrMain.tbExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrMain.tbExportClick(Sender: TObject);
begin
  smExportClick(smExport);
end;

procedure TfrMain.tbFilterClick(Sender: TObject);
begin
  smFilterClick(smFilter);
end;

procedure TfrMain.tbIndexesClick(Sender: TObject);
var
  Ch: Char;
  I,J,K: Integer;
  Ver: TXBaseVersion;

begin
  with frDefineIndex do
  begin
    if not (dbfMain.TableLevel in [3,4,7]) then
    begin
      Ver := dbfMain.DbfFieldDefs.DbfVersion;
      MessageDlg(#10'Unsupported file type: "'+DbfVer[Ver]+'"',
        mtWarning,[mbOK],0);
      Exit;
    end;
    case dbfMain.TableLevel of
      3: Level := L3;
      4: Level := L4;
      7: Level := L7
    end;
    TmpDbf := TDbf.Create(nil);
    TmpDbf.FilePath := dbfMain.FilePath;
    TmpDbf.FilePathFull := dbfMain.FilePathFull;
    TmpDbf.TableName := dbfMain.TableName;
    TmpDbf.TableLevel := dbfMain.TableLevel;
    dbfMain.Close;
    TmpDbf.Exclusive := True;    //before open
    TmpDbf.Open;                 //1
    J := TmpDbf.Indexes.Count;   //2
    SetLength(XItems.Values,J);  //3
    SetLength(FldItems.Fields,TmpDbf.DbfFieldDefs.Count);
    try
      with TmpDbf do
      begin
        for I := 0 to Length(FldItems.Fields)-1 do
        begin
          FldItems.Fields[I].Name := DbfFieldDefs.Items[I].FieldName;
          Ch := DbfFieldDefs.Items[I].NativeFieldType;
          FldItems.Fields[I].NativeType := Ch;
          FldItems.Fields[I].VCLType := VCLType(Ch,Level);
        end;
        for I := 0 to J-1 do
          begin
            XItems.Values[I].Exp := Indexes[I].Expression;
            XItems.Values[I].Name := Indexes[I].Name;
            XItems.Values[I].Opts := Indexes[I].Options;
            XItems.Values[I].NewIndex := False;
          end;
        case TmpDbf.TableLevel of
          3: Level := L3;
          4: Level := L4;
          7: Level := L7;
        end;
        edIndexName.MaxLength := MaxFieldLen[Level];
        ShowModal;
        if ModalResult <> mrOk then Exit;
        J := 0; {Created}
        K := 0; {Updated}
        for I := Low(XItems.Values) to High(XItems.Values) do
          begin
            if XItems.Values[I].NewIndex then Inc(J) else Inc(K);
            AddIndex(XItems.Values[I].Name,XItems.Values[I].Exp,XItems.Values[I].Opts);
          end;
        MessageDlg(#10'Created index : ' + IntToStr(J) +
          #10'Updated index : '+IntToStr(K), mtInformation,[mbOK],0);
      end;
    finally
      TmpDbf.Close;
      TmpDbf.Free;
      Finalize(XItems);
      Finalize(FldItems);
      dbfMain.Open;
    end;
  end;
end;

procedure TfrMain.tbNewClick(Sender: TObject);
var
  C: Char;
  I: Integer;
begin
  frNewOpt := TfrNewOpt.Create(nil);
  try
    frNewOpt.ShowModal;
    if frNewOpt.ModalResult <> mrOk then Exit;
    if frNewOpt.RadioButton1.Checked then I := 1 else I := 2;
  finally
    frNewOpt.Free;
  end;
  if I = 1 then with frCreateTable do
  begin
    cbFileType.ItemIndex := 2;
    FillChar(Level,1,2);
    ShowModal;
    for I := 1 to sgNew.RowCount-1 do sgNew.Rows[I].Clear;
    sgNew.RowCount := 1;
    if ModalResult <> mrOK then Exit;
    if dbfMain.Active then dbfMain.Close;
    dbfMain.FilePath := dbfNew.FilePath;
    dbfMain.FilePathFull := dbfNew.FilePathFull;
    dbfMain.TableName := dbfNew.TableName;
    dbfMain.Open;
  end
  else
  with frCreateTable2 do
  begin
    if not OpenDialog1.Execute then Exit;
    dbfSrc.TableName := OpenDialog1.FileName;
    dbfSrc.Exclusive := True; //Before open;
    dbfSrc.Open;
    try
      case dbfSrc.TableLevel of
        3: Level := L3;
        4: Level := L4;
        7: Level := L7;
        else
          begin
            MessageDlg(#10'Unsupported file type: "'+
              DBaseVersion(dbfSrc)+'"', mtWarning,[mbOK],0);
            Exit;
          end;
      end;
      sbNewTable.Panels[0].Text :='   '+ ExtractFileName(OpenDialog1.FileName)+
        ' - [ '+DBaseVersion(dbfSrc)+' ]' + '    '+ RecordCountStr(dbfSrc);
      for I := 1 to sgNew.RowCount-1 do sgNew.Rows[I].Clear;
      sgNew.RowCount := dbfSrc.DbfFieldDefs.Count+1;
      for I := 1 to dbfSrc.DbfFieldDefs.Count do
        with dbfSrc.DbfFieldDefs do
        begin
          sgNew.Cells[0,I] := '1';
          sgNew.Cells[1,I] := Items[I-1].FieldName;
          C := Items[I-1].NativeFieldType;
          sgNew.Cells[2,I] := VCLType(C,Level);
          sgNew.Cells[3,I] := IntToStr(Items[I-1]. Size);
          sgNew.Cells[4,I] := IntToStr(Items[I-1].Precision);
          sgNew.Cells[5,I] := IntToStr(Ord(Items[I-1].NativeFieldType));
          sgNew.Cells[6,I] := IntToStr(Ord(Items[I-1].Required));
          sgNew.Cells[7,I] := Items[I-1].FieldName;
        end;
      SrcPath := dbfSrc.FilePath;
      SrcName := dbfSrc.TableName;
      ShowModal;
    finally
      dbfSrc.Close;
    end;
    if ModalResult <> mrOk then Exit;
    if dbfMain.Active then dbfMain.Close;
    dbfMain.Exclusive := True;
    dbfMain.FilePath := dbfDest.FilePath;
    dbfMain.FilePathFull := dbfDest.FilePathFull;
    dbfMain.TableName := dbfDest.TableName;
    dbfMain.Open;
    MessageDlg(#10'Process completed successfully!', mtConfirmation,[mbOk],0);
  end;

end;

procedure TfrMain.tbOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    dbfMain.TableName := OpenDialog1.FileName;
    dbfMain.Exclusive := True; //Before open;
    dbfMain.Open;
  end;
end;

procedure TfrMain.tbPackClick(Sender: TObject);
begin
  smPackTableClick(smPackTable);
end;

procedure TfrMain.tbRestructureClick(Sender: TObject);
var
  C: Char;
  I: Integer;
  S: string;
begin
  frRestructure:=TfrRestructure.Create(nil);
  try
    with frRestructure do
    begin
      case dbfMain.TableLevel of
        3: Level := L3;
        4: Level := L4;
        7: Level := L7;
        else
          begin
            MessageDlg(#10'Unsupported file type: "'+
              DbaseVersion(dbfMain)+'"', mtWarning,[mbOK],0);
            Exit;
          end;
      end;
      sbRestructure.Panels[0].Text :='   '+ dbfMain.FilePath +
        dbfMain.TableName + ' - [ '+DBaseVersion(dbfMain)+' ]';
      //for I:= 1 to sgRestruct.RowCount-1 do sgRestruct.Rows[I].Clear;
      IndexedFields := TStringList.Create;
      try
        for I := 0 to dbfMain.Indexes.Count-1 do
          GetIndexFields(dbfMain.Indexes[I].Expression, IndexedFields);
        sgRestruct.RowCount := dbfMain.DbfFieldDefs.Count+1;
        for I := 1 to dbfMain.DbfFieldDefs.Count do
          with dbfMain.DbfFieldDefs do
          begin
            sgRestruct.Cells[0,I] := IntToStr(I);
            S := Items[I-1].FieldName;
            sgRestruct.Cells[1,I] := S;
            C := Items[I-1].NativeFieldType;
            sgRestruct.Cells[2,I] := VCLType(C,Level);
            sgRestruct.Cells[3,I] := IntToStr(Items[I-1]. Size);
            sgRestruct.Cells[4,I] := IntToStr(Items[I-1].Precision);
            sgRestruct.Cells[5,I] := IntToStr(Ord(Items[I-1].NativeFieldType));
            if IndexedFields.IndexOf(S) >= 0 then sgRestruct.Cells[6,I] := '*';
            sgRestruct.Cells[7,I] := '0';
          end;
      finally
        IndexedFields.Free;
      end;
      TmpFieldDefs := TDbfFieldDefs.Create(Self);
      try
        TmpFieldDefs.Assign(dbfMain.DbfFieldDefs);
        btnDelete.Enabled := False;
        ShowModal;
        if ModalResult <> mrOk then Exit;
        dbfMain.Close;
        dbfMain.Exclusive := True;
        case Level of
          L3: TmpFieldDefs.DbfVersion := xBaseIII;
          L4: TmpFieldDefs.DbfVersion := xBaseIV;
          L7: TmpFieldDefs.DbfVersion := xBaseVII;
        end;
        Screen.Cursor := crHourGlass;
        try
          Application.ProcessMessages;
          dbfMain.RestructureTable(TmpFieldDefs,False);
        finally
          dbfMain.Open;
          Screen.Cursor := crDefault;
        end;
      finally
        FreeAndNil(TmpFieldDefs);
      end;
    end;
  finally
    frRestructure.Free;
  end;

end;

procedure TfrMain.tbSearchClick(Sender: TObject);
begin
  smSearchClick(smSearch);
end;

procedure TfrMain.tbCloneClick(Sender: TObject);
begin
  smCloneTableClick(smCloneTable);
end;

end.

