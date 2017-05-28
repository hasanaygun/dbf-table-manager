unit clonetable;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, Dbf_Fields, dbf, FileUtil, RTTICtrls, Forms,
  Controls, Graphics, Dialogs, StdCtrls, Grids, Buttons, ComCtrls, ExtCtrls;

type

  { TfrCloneTable }

  TfrCloneTable = class(TForm)
    ckDeleted: TCheckBox;
    dbfDest: TDbf;
    SaveDialog1: TSaveDialog;
    sgFields: TStringGrid;
    btnOK: TSpeedButton;
    btnCancel: TSpeedButton;
    sgIndexes: TStringGrid;
    sbCloneTable: TStatusBar;
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;


var
  frCloneTable: TfrCloneTable;
  SrcPath, SrcName: string;
  dbfSrc: TDbf;

implementation

uses dbfpublics;

{$R *.lfm}

{ TfrCloneTable }

procedure TfrCloneTable.btnOKClick(Sender: TObject);
var
  I: Integer;
  Buf: Pointer;
  fPath,fName: string;
begin
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
  end;
  Application.ProcessMessages;
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
    TmpFieldDefs := TDbfFieldDefs.Create(Self);
    try
      TmpFieldDefs.Assign(dbfSrc.DbfFieldDefs);
      dbfDest.IndexDefs.Assign(dbfSrc.IndexDefs);
      for I := 0 to TmpFieldDefs.Count-1 do
        if TmpFieldDefs.Items[I].NativeFieldType = '+' then
          TmpFieldDefs.Items[I].AutoInc := 0;
      dbfDest.CreateTableEx(TmpFieldDefs);
    finally
      FreeAndNil(TmpFieldDefs);
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
    dbfSrc.DisableControls;
    dbfDest.Open;
    try
      dbfSrc.ShowDeleted := ckDeleted.Checked;
      dbfSrc.First;
      while not dbfSrc.EOF do
      begin
        dbfDest.Append;
        for I:=0 to dbfSrc.Fields.Count-1 do
          if not (dbfSrc.Fields[I].IsNull) then
            dbfDest.Fields[I].Assign(dbfSrc.Fields[I]);
        if ckDeleted.Checked and dbfSrc.IsDeleted then
        begin
          Buf := dbfSrc.ActiveBuffer; //Dbf1.GetCurrentBuffer;
          pDbfRecord(dbfDest.ActiveBuffer)^.DeletedFlag := pDbfRecord(Buf)^.DeletedFlag;
        end;
        dbfDest.Post;
        dbfSrc.Next;
      end;
    finally
      dbfSrc.Close;
      dbfDest.Close;
      dbfSrc.EnableControls;
      Screen.Cursor := crDefault;
    end;
  end;
  ModalResult := mrOK;
end;

procedure TfrCloneTable.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;


end.

