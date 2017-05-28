unit define_index;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, dbf, FileUtil, Forms, Controls, Graphics,
  Dialogs, StdCtrls, Grids, Buttons, ExtCtrls;

type

  { TfrDefineIndex }

  TfrDefineIndex = class(TForm)
    btnNew: TSpeedButton;
    btnSave: TSpeedButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    edExpression: TEdit;
    edIndexName: TEdit;
    edIndexField: TEdit;
    Label4: TLabel;
    pnlOptions: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    sgIndex: TStringGrid;
    btnDelete: TSpeedButton;
    btnClose: TSpeedButton;
    SpeedButton1: TSpeedButton;
    procedure CheckBox1Click(Sender: TObject);
    procedure edExpressionChange(Sender: TObject);
    procedure edExpressionKeyPress(Sender: TObject; var Key: char);
    procedure edIndexNameChange(Sender: TObject);
    procedure edIndexNameKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure sgIndexClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure sgIndexDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { private declarations }
  public
    procedure SetIndexOptions(B: Byte);
  end;

var
  frDefineIndex: TfrDefineIndex;

implementation

uses dbfpublics, table_fields, index_help;

{$R *.lfm}

{ TfrDefineIndex }

procedure TfrDefineIndex.SetIndexOptions(B: Byte);
var
  XOpt: TIndexOption;
  XOpts: TIndexOptions;
begin
  XOpts:=ByteToXOpts(B);
  for XOpt:=Low(XOpt) to High(XOpt) do
    case XOpt of
      ixPrimary:
        CheckBox1.Checked:=XOpt in XOpts;
      ixUnique:
        CheckBox2.Checked:=XOpt in XOpts;
      ixDescending:
        CheckBox3.Checked:=XOpt in XOpts;
    end;
end;

procedure TfrDefineIndex.FormShow(Sender: TObject);
var
  I: Integer;
begin
  for I:=1 to sgIndex.RowCount-1 do sgIndex.Rows[I].Clear;
  sgIndex.RowCount:=1;
  I:=Length(XItems.Values);
  if I > 0 then sgIndex.RowCount := I+1;
  for I:=Low(XItems.Values) to High(XItems.Values) do
    begin
      sgIndex.Cells[0,I+1]:=XItems.Values[I].Exp;
      sgIndex.Cells[1,I+1]:=XItems.Values[I].Name;
      sgIndex.Cells[2,I+1]:=IntToStr(XOptsToByte(XItems.Values[I].Opts));
      if FldItems.IndexOf(XItems.Values[I].Exp) >= 0 then
        sgIndex.Cells[4,I+1]:=XItems.Values[I].Exp;
    end;
  btnSave.Enabled := False;
  btnDelete.Enabled := sgIndex.RowCount > 1;
  sgIndex.SetFocus;
  sgIndexClick(sgIndex);
end;

procedure TfrDefineIndex.CheckBox1Click(Sender: TObject);
var
  I,J,K: Integer;
  XOpts: TIndexOptions;
begin
  if sgIndex.RowCount = 1 then Exit;
  I:=sgIndex.Row;
  K:=StrToIntDef(sgIndex.Cells[2,I],0);
  XOpts:=ByteToXOpts(K);
  with (Sender as TCheckBox) do
  begin
    J:=Tag;
    case J of
      0: if Checked then XOpts:=XOpts+[ixPrimary]
         else XOpts:=XOpts-[ixPrimary];
      1: if Checked then XOpts:=XOpts+[ixUnique]
         else XOpts:=XOpts-[ixUnique];
      2: if Checked then XOpts:=XOpts+[ixDescending]
         else XOpts:=XOpts-[ixDescending];
    end;
  end;
  K:=XOptsToByte(XOpts);
  sgIndex.Cells[2,I]:=IntToStr(K);
  btnSave.Enabled := True;
end;

procedure TfrDefineIndex.edExpressionChange(Sender: TObject);
begin
  sgIndex.Cells[0,sgIndex.Row]:=edExpression.Text;
end;

procedure TfrDefineIndex.edExpressionKeyPress(Sender: TObject; var Key: char);
begin
  Key:=UpCase(Key);
  if not (Key in [#8,#9,#13,#27,'+',',','(',')','0'..'9','_','A'..'Z']) then Key := #0;

end;

procedure TfrDefineIndex.edIndexNameChange(Sender: TObject);
var
  I: Integer;
  S: string;
begin
  S:=edIndexName.Text;
  I:=sgIndex.Cols[1].IndexOf(S);
  if (S > '') and (I > 0) and (I <> sgIndex.Row)then
  begin
    MessageDlg(#10'Index name "'+S+'" is already assigned!', mtWarning,[mbOK],0);
    sgIndex.Cells[1,sgIndex.Row]:='';
    edIndexName.SetFocus;
    edIndexName.SelectAll;
  end
  else
    sgIndex.Cells[1,sgIndex.Row]:=edIndexName.Text;
end;

procedure TfrDefineIndex.edIndexNameKeyPress(Sender: TObject; var Key: char);
begin
  Key:=UpCase(Key);
  if not (Key in [#8,#9,#13,#27,'0'..'9','_','A'..'Z']) then Key := #0;
end;

procedure TfrDefineIndex.sgIndexClick(Sender: TObject);
var
  I: Integer;
begin
  edIndexName.OnChange:=nil;
  edExpression.OnChange:=nil;
  I:=sgIndex.Row;
  if I > 0 then
  begin
    edExpression.Text := sgIndex.Cells[0,I]; //Exp
    edIndexField.Text := sgIndex.Cells[4,I]; //Field
    if edExpression.Text = edIndexField.Text then edExpression.Text := '';
    edIndexName.Text:=sgIndex.Cells[1,I];
    SetIndexOptions(StrToIntDef(sgIndex.Cells[2,I],0));
    edIndexName.Enabled:=XItems.IndexOf(sgIndex.Cells[1,I]) < 0;
    edExpression.Enabled:=edIndexName.Enabled;
    pnlOptions.Enabled:=True;;
  end
  else
  begin
    edIndexField.Text:='';
    edIndexName.Text:='';
    edExpression.Text:='';
    pnlOptions.Enabled:=False;
    edIndexName.Enabled:=False;
    edExpression.Enabled:=False;
  end;
  edIndexName.OnChange:=@edIndexNameChange;
  edExpression.OnChange:=@edExpressionChange;

end;

procedure TfrDefineIndex.btnNewClick(Sender: TObject);
var
  I,J: Integer;
begin
  for I := 1 to sgIndex.RowCount-1 do
    if sgIndex.Cells[1,I]='' then
    begin
      MessageDlg(#10'"Index Name" is empty!',
          mtWarning,[mbOK],0);
      sgIndex.Row:=I;
      edIndexName.SetFocus;
      Exit;
    end;
  with frTableFields do
  begin
    for I:=1 to sgFields.RowCount-1 do sgFields.Rows[I].Clear;
    J := Length(FldItems.Fields);
    if J > 0 then sgFields.RowCount := J+1;
    for I:=0 to J-1 do
      begin
        sgFields.Cells[0,I+1]:=FldItems.Fields[I].Name;
        sgFields.Cells[1,I+1]:=FldItems.Fields[I].VCLType;
        sgFields.Cells[2,I+1]:=IntToStr(Ord(FldItems.Fields[I].NativeType));
      end;
    ShowModal;
    if ModalResult <> mrOK then Exit;
  end; {frFields}
  btnSave.Enabled := True;
  btnDelete.Enabled := sgIndex.RowCount > 1;
  edIndexName.SetFocus;
end;

procedure TfrDefineIndex.btnSaveClick(Sender: TObject);
var
  I,J,K: Integer;
  Exp,FldName,XName: string;

begin
  if sgIndex.RowCount=1 then Exit;
  for I := 1 to sgIndex.RowCount-1 do
    begin
      XName := Trim(sgIndex.Cells[1,I]);
      if XName = '' then
      begin
        MessageDlg(#10'"Index Name" is empty!',
          mtWarning,[mbOK],0);
        sgIndex.Row := I;
        Exit;
      end;
    end;
  IndexedFields := TStringList.Create;
  try
    for I := 1 to sgIndex.RowCount-1 do
    begin
      XName := sgIndex.Cells[1,I]; //Index name
      J:=XItems.IndexOf(XName);    //Already indexed
      if J >= 0 then Continue;
      Exp := sgIndex.Cells[0,I];   //Exp
      if GetIndexFields(Exp,IndexedFields) > 0 then
      begin
        J := MessageDlg(#10'"This Expression seems wrong!'#10+
          'Do you want to continue?',mtWarning,[mbYes,mbNo],0);
        if J <> mrYes then Exit;
      end;
      for J := 0 to IndexedFields.Count-1 do
        begin
          K := FldItems.IndexOf(IndexedFields[J]);
          if K < 0 then
          begin
            MessageDlg(#10'Field name "'+IndexedFields[J]+
              '" not found in the field list',
              mtWarning,[mbOK],0);
            Exit;
          end;
          if not (FldItems.Fields[K].NativeType in FldIndexable) then
          begin
            MessageDlg(#10'Field Name: '+IndexedFields[J]+
              #10'Field Type: '+FldItems.Fields[K].VCLType+
              #10'Invalide index type! Use only string, numeric or date.',
              mtWarning,[mbOK],0);
            Exit;
          end;
          FldName := sgIndex.Cells[4,I]; //Field name
          K := IndexedFields.IndexOf(FldName);
          if K < 0 then
          begin
            MessageDlg(#10'Field name "'+FldName+'" not found in the expression!',
              mtWarning,[mbOK],0);
            Exit;
          end;
        end;
    end;
  finally
    IndexedFields.Free;
  end;
  for I := 1 to sgIndex.RowCount-1 do
    begin
      J := StrToIntDef(sgIndex.Cells[2,I],0); //Opts
      Xname := sgIndex.Cells[1,I];            //Index name
      K := XItems.IndexOf(XName);
      if K < 0 then
      begin
        SetLength(XItems.Values,Length(XItems.Values)+1);
        Exp := sgIndex.Cells[0,I];
        if Exp = '' then Exp := sgIndex.Cells[4,I];
        XItems.Values[High(XItems.Values)].Exp := Exp;
        XItems.Values[High(XItems.Values)].Name := sgIndex.Cells[1,I];
        XItems.Values[High(XItems.Values)].Opts := ByteToXOpts(J);
        XItems.Values[High(XItems.Values)].NewIndex := True;
      end
      else
      begin
        if XItems.Values[K].Opts <> ByteToXOpts(J) then
          XItems.Values[K].Opts := ByteToXOpts(J)
        else
          DeleteX(XItems.Values,K);
      end;
    end;
  ModalResult := mrOK;
end;

procedure TfrDefineIndex.sgIndexDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
  with (Sender as TStringGrid) do
  begin
    if not (gdFixed in aState) then
    begin
      if XItems.IndexOf(Cells[1,aRow]) < 0 then
      begin
        Canvas.Font.Style := [fsBold];
        Canvas.FillRect(aRect);
        Canvas.TextRect(aRect, aRect.Left + 2, aRect.Top + 2, Cells[aCol, aRow]);
      end;
    end;
  end;
end;

procedure TfrDefineIndex.btnDeleteClick(Sender: TObject);
var
  I,J,K: Integer;
begin
  if sgIndex.RowCount=1 then Exit;
  I:=sgIndex.Row;
  K:=XItems.IndexOf(sgIndex.Cells[1,I]);
  if K < 0 then
  begin
    if MessageDlg(#10'Delete from list?',
      mtConfirmation,[mbYes,mbNo],0) = mrNo then Exit;
  end
  else
  for J:=0 to TmpDbf.Indexes.Count-1 do
    if sgIndex.Cells[1,I]=TmpDbf.Indexes[J].Name then
    begin
      if MessageDlg(#10'Table Name: '+TmpDbf.TableName+
        #10'Index Field: '+TmpDbf.Indexes[J].Expression+
        #10'Index Name: '+TmpDbf.Indexes[J].Name+#10'Delete?',
        mtConfirmation,[mbYes,mbNo],0) = mrNo then Exit;
      TmpDbf.DeleteIndex(sgIndex.Cells[1,I]);
      DeleteX(XItems.Values,K);
      Break;
    end;
  sgIndex.Rows[I].Clear;
  for J := I to sgIndex.RowCount-2 do
     sgIndex.ExchangeColRow(False,J+1,J);
  sgIndex.RowCount:=sgIndex.RowCount-1;
  sgIndexClick(sgIndex);
  if sgIndex.RowCount = 1 then btnSave.Enabled := False;
  btnDelete.Enabled := sgIndex.RowCount > 1;
end;

procedure TfrDefineIndex.btnCloseClick(Sender: TObject);
begin
  ModalResult:=mrCancel;
end;

procedure TfrDefineIndex.SpeedButton1Click(Sender: TObject);
begin
  frmIndexHelp:=TfrmIndexHelp.Create(nil);
  try
    frmIndexHelp.ShowModal;
  finally
    frmIndexHelp.Free;
  end;
end;


end.

