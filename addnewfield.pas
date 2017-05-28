unit addnewfield;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Buttons, Spin;

type

  { TfrAddNewField }

  TfrAddNewField = class(TForm)
    cbFieldType: TComboBox;
    edFieldName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    OkBtn: TSpeedButton;
    CancelBtn: TSpeedButton;
    seDigit: TSpinEdit;
    seSize: TSpinEdit;
    procedure cbFieldTypeChange(Sender: TObject);
    procedure edFieldNameKeyPress(Sender: TObject; var Key: char);
    procedure OkBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
  private
    { private declarations }
  public

  end;

var
  frAddNewField: TfrAddNewField;

implementation

uses dbfpublics;

{$R *.lfm}

{ TfrAddNewField }

procedure TfrAddNewField.OkBtnClick(Sender: TObject);
var
  S1,S2: string;
begin
  S1 := edFieldName.Text;
  S2 := cbFieldType.Text;
  if (S1 = '') or (S2 = '') then Exit;
  if S1 > '' then
  begin
    if (S2 = 'String') and (seSize.Value < 1) then Exit;
  end;
  ModalResult := mrOk;
end;

procedure TfrAddNewField.CancelBtnClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrAddNewField.edFieldNameKeyPress(Sender: TObject; var Key: char);
begin
  Key:=UpCase(Key);
  if not (Key in [#8,#9,#13,#27,'0'..'9','_','A'..'Z']) then Key := #0;
end;

procedure TfrAddNewField.cbFieldTypeChange(Sender: TObject);
var
  I: Integer;
begin
  I:=cbFieldType.ItemIndex+1;
  seSize.MinValue:=XBase[Level,I].Size.Min;
  seSize.MaxValue:=XBase[Level,I].Size.Max;
  seSize.Value:=XBase[Level,I].Size.Def;
  seSize.Enabled:=not XBase[Level,I].sFixed;
  //
  seDigit.MinValue:=XBase[Level,I].Digit.Min;
  seDigit.MaxValue:=XBase[Level,I].Digit.Max;
  seDigit.Value:=XBase[Level,I].Digit.Def;
  seDigit.Enabled:=not XBase[Level,I].dFixed;
end;


end.

