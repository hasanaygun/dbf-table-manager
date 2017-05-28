unit export_dbf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, Dbf_Fields, dbf, FileUtil, Forms, Controls, Graphics,
  Dialogs, StdCtrls, Grids, Buttons, ComCtrls, ExtCtrls, fpsTypes, fpSpreadsheet,
  fpsUtils, fpsallformats, xlsbiff5, fpscsv;

type

  { TfrExport }

  TfrExport = class(TForm)
    cbDelimiter: TComboBox;
    cbQuote: TComboBox;
    GbCSVOptions: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    rgFileFormat: TRadioGroup;
    SaveDialog1: TSaveDialog;
    sgFields: TStringGrid;
    btnOK: TSpeedButton;
    btnCancel: TSpeedButton;
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure rgFileFormatClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  TDataprovider = class
    Dbf: TDbf;
    procedure WriteCellDataHandler(Sender: TsWorksheet; ARow,ACol: Cardinal;
      var AData: Variant; var AStyleCell: PCell);
  end;

  TfSelected = record
    fName: string;
    fType: Char;
    fDigit: Integer;
  end;

var
  frExport: TfrExport;
  fPath,fName: string;
  Counter : Integer;
  Workbook: TsWorkbook;
  Worksheet: TsWorksheet;
  Dataprovider: TDataProvider;
  HeaderTemplate: PCell;
  OtherTemplate: PCell;
  csvDelimiter: string;
  csvQuoteChar: string;
  fSelected: array of TfSelected;

const
  FILE_FORMATS: array[0..5] of TsSpreadsheetFormat =
    (sfExcel2, sfExcel5, sfExcel8, sfOOXML, sfOpenDocument, sfCSV);


implementation

uses dbfpublics;

{$R *.lfm}

{ TfrExport }

procedure TDataprovider.WriteCellDataHandler(Sender: TsWorksheet;
    ARow, ACol: Cardinal; var AData: Variant; var AStyleCell: PCell);
var
  C: Char;
  Fld: string;
  Digit: Integer;

  begin
    C := fSelected[ACol].fType;
    Fld := fSelected[ACol].fName;
    Digit := fSelected[ACol].fDigit;
    if ARow = 0 then
    begin
      AData := Dbf.FieldByName(Fld).FieldName;
      AStyleCell := HeaderTemplate;
      // This makes the style of the "HeaderTemplate" cell available to
      // formatting of all virtual cells in row 0.
      // Important: The template cell must be an existing cell in the Worksheet.
    end
    else
    begin
      case C of
        'B':
          if Dbf.FieldByName(Fld).IsNull then AData := Null
          else AData := '[Blob]';
        'G':
          if Dbf.FieldByName(Fld).IsNull then AData := Null
          else AData := '[DbaseOle]';
        'M':
          if Dbf.FieldByName(Fld).IsNull then AData := Null
          else AData := '[Memo]';
        '@','D':
          if Dbf.FieldByName(Fld).IsNull then AData := Null
          else
            AData := FormatDateTime('DD'+DateSeparator+'MM'+DateSeparator+'YYYY',
              Dbf.FieldByName(Fld).AsDateTime);
        'F','N':
          begin
            AStyleCell := OtherTemplate;
            if Dbf.FieldByName(Fld).IsNull then AData := Null else
            if Digit > 0 then
              AData := FormatFloat('0.'+StringOfChar('0',Digit),
                Dbf.FieldByName(Fld).AsFloat)
            else
              AData := Dbf.FieldByName(Fld).AsVariant;
          end;
        else
          if Dbf.FieldByName(Fld).IsNull then AData := Null
          else AData := Dbf.FieldByName(Fld).AsVariant;
      end;
      if ACol = Length(fSelected)-1 then
      begin
        Dbf.Next;
        Inc(Counter);
      end;
    end;
    // you can use the event handler also to provide feedback on how the process
    // progresses:
    // if (ACol = 0) and (ARow mod frMain.dbfMain.RecordCount = 0) then ...
end;


procedure TfrExport.btnOKClick(Sender: TObject);
var
  I: Integer;
begin
  if not SaveDialog1.Execute then Exit;
  fPath:=SaveDialog1.FileName;
  case FILE_FORMATS[rgFileFormat.ItemIndex] of
    sfExcel2, sfExcel5, sfExcel8:
      fPath := ChangeFileExt(fPath,'.xls');
    sfOOXML:
      fPath := ChangeFileExt(fPath,'.xlsx');
    sfOpenDocument:
      fPath := ChangeFileExt(fPath,'.ods');
    sfCSV:
      fPath := ChangeFileExt(fPath,'.csv');
  end;
  fName:=ExtractFileName(fPath);
  if FileExists(fPath) then
  begin
    I:=MessageDlg(#10+fName+' exist!'#10+
      'Overwrite this file?',mtConfirmation,[mbYes,mbNo],0);
    if I = mrNo then Exit;
  end;

  case cbDelimiter.ItemIndex of
    0: csvDelimiter := ',';
    1: csvDelimiter := ';';
    2: csvDelimiter := ' ';
    3: csvDelimiter := #9;
    else
  end;
  if cbQuote.ItemIndex = 0 then csvQuoteChar := #39
  else csvQuoteChar := '"';

  ModalResult := mrOk;
end;

procedure TfrExport.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrExport.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #27 then btnCancelClick(btnCancel);
end;

procedure TfrExport.FormShow(Sender: TObject);
begin
  {$ifdef WINDOWS}
    cbDelimiter.ItemIndex := 1;
  {$else}
    cbDelimiter.ItemIndex := 0;
  {$endif}
  cbQuote.ItemIndex := 1;
  GbCSVOptions.Enabled := rgFileFormat.ItemIndex = 5;
end;

procedure TfrExport.rgFileFormatClick(Sender: TObject);
begin
  GbCSVOptions.Enabled := rgFileFormat.ItemIndex = 5;
end;


end.

