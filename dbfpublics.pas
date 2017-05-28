unit dbfpublics;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, db, dbf, dbf_fields, dbf_common, dialogs, strutils;

type
  _TSize= record
    Min, Max, Def: Integer;
  end;

  TNativeType = record
    Name: string;
    NativeType: Char;
    Size: _TSize;
    Digit: _TSize;
    sFixed: Boolean;
    dFixed: Boolean;
  end;

  TLevel= (L3,L4,L7);

  TXItem= record
    Exp: string;
    Name: string;
    NewIndex: Boolean;
    Opts: TIndexOptions;
  end;

  TFldItem= record
    Name: string;
    VCLType: string;
    NativeType: Char;
  end;

  TXItems= array of TXItem;
  TFldItems= array of TFldItem;

  TXObject= object
    Values: TXItems;
    function IndexOf(const S: string): Integer;
  end;

  TFldObject= object
    Fields: TFldItems;
    function IndexOf(const S: string): Integer;
  end;

var
  Level: TLevel;
  FieldTypeCount: array[TLevel] of Byte= (5, 6, 11);
  MaxFieldLen: array[TLevel] of Byte=(10,10,31);
  NativeField: TNativeType;
  FldItems: TFldObject;
  XItems: TXObject;

  XBase: array[TLevel,1..11] of TNativeType;

  NativeChars: array[TLevel] of set of Char=
    (['C','N','D','L','M'],
     ['C','F','N','D','L','M'],
     ['+','C','I','F','N','L','D','@','B','M','G']);

  TmpFieldDefs: TDbfFieldDefs;

  DbfVer: array[TXBaseVersion] of string=
    ('Unknown','Clipper','dBaseIII','dBaseIV',
    'dBaseV','FoxPro','dBaseVII','VisualFoxPro');

  FldIndexable: set of Char=['+','@','C','D','F','I','N','O','V'];

  {'+','I','O','@','C','L','F','N','D','M','B','G','Y','0','P','V','W','Q'}
  {dbf_fields.pas: VCLToNative ve NativeToVCL}

  {+ = AutoInc     F = Float      Y = BCD
   I = Integer     N = Numeric    0 = Bytes
   O = Float       D = Date       P = Blob
   @ = DateTime    M = Memo       V = String
   C = String      B = Blob       W = Blob
   L = Boolean     G = DbaseOle   Q = VarBytes }

  TmpDbf: TDbf;
  IndexedFields: TStringList;

  procedure TrimBrackets(var S: string);
  function XOptsToByte(Opts: TIndexOptions): Byte;
  function ByteToXOpts(B: Byte): TIndexOptions;
  procedure DeleteX(var XItems: TXItems; const Index: Cardinal);
  procedure DeleteFld(var FldItems: TFldItems; const Index: Cardinal);
  function GetIndexFields(Exp: string; IndexedFields: TStringList): Integer;
  procedure InitFieldProperties;
  function ExpressionIsOk(var Fld: String; Fn: string): Boolean;
  function RightPos(C: Char; const S: string): Integer;
  function VCLType(NativeType: Char; Level: TLevel): string;
  function DBaseVersion(Dbf: TDbf): string;

implementation

procedure TrimBrackets(var S: string);
var
  Yes: Boolean;
begin
  if Length(S) > 1 then
    begin
      Yes:=(S[1]='(') and (S[Length(S)]=')');
      while Yes do
      begin
        Delete(S,1,1);
        Delete(S,Length(S),1);
        Yes:=(S[1]='(') and (S[Length(S)]=')');
      end;
    end;
end;

function RightPos(C: Char; const S: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Length(S) downto 1 do
    if S[I] = C then
    begin
      Result := I;
      Break;
    end;
end;

function TXObject.IndexOf(const S: string): Integer;
var
  I: Integer;
begin
  Result:=-1;
  for I:=Low(Values) to High(Values) do
    if S=Values[I].Name then
    begin
      Result:=I;
      Break;
    end;
end;

function TFldObject.IndexOf(const S: string): Integer;
var
  I: Integer;
begin
  Result:=-1;
  for I:=Low(Fields) to High(Fields) do
    if S=Fields[I].Name then
    begin
      Result:=I;
      Break;
    end;
end;

procedure DeleteX(var XItems: TXItems; const Index: Cardinal);
var
  I,ALength: Cardinal;
begin
  ALength := Length(XItems);
  Assert(ALength > 0);
  Assert(Index < ALength);
  for I := Index + 1 to ALength - 1 do
    XItems[I - 1] := XItems[I];
  SetLength(XItems, ALength - 1);
end;

procedure DeleteFld(var FldItems: TFldItems; const Index: Cardinal);
var
  I,ALength: Cardinal;
begin
  ALength := Length(FldItems);
  Assert(ALength > 0);
  Assert(Index < ALength);
  for I := Index + 1 to ALength - 1 do
    FldItems[I - 1] := FldItems[I];
  SetLength(FldItems, ALength - 1);
end;

function XOptsToByte(Opts: TIndexOptions): Byte;
var
  XOpt: TIndexOption;
begin
  Result:=0;
  for XOpt:= Low(XOpt) to High(XOpt) do
    if XOpt in Opts then Result:=Result or (1 shl Ord(XOpt));
end;

function ByteToXOpts(B: Byte): TIndexOptions;
var
  I: Byte;
  XOpt: TIndexOption;
begin
  Result := [];
  for XOpt:= Low(XOpt) to High(XOpt) do
  begin
    I := B and (1 shl Ord(XOpt));
    if I > 0 then Result := Result + [XOpt];
  end;
end;

function GetIndexFields(Exp: string; IndexedFields: TStringList): Integer;
var
  I,J: Integer;
  Fld: string;
  List: TStringList;

begin
  Result := 0;
  Exp := DelSpace(Exp);
  List:=TStringList.Create;
  try
    I:=Pos('+',Exp);
    while I > 0 do
    begin
      List.Add(Copy(Exp,1,I-1));
      Delete(Exp,1,I);
      I:=Pos('+',Exp);
    end;
    List.Add(Exp);
    for I:=0 to List.Count-1 do
      begin
        if ExpressionIsOk(Fld, List[I]) then
        begin
          J := IndexedFields.IndexOf(Fld);
          if J < 0 then IndexedFields.Add(Fld);
        end
        else
          Inc(Result); //No ExpressionIsOk
      end;
  finally
    List.Free;
  end;
end;

function ExpressionIsOk(var Fld: String; Fn: string): Boolean;

  function RightPos(C: Char; const S: string): Integer;
  var
    I: Integer;
  begin
    Result := 0;
    for I := Length(S) downto 1 do
      if S[I] = C then
      begin
        Result := I;
        Break;
      end;
  end;

  function STRParamsIsOk(var Fn: string): Boolean;
  var
    S: string;
    P: Integer;

    function StrToNum(const S: string): Boolean;
    var
      Err,Num: Integer;
    begin
      if S > '' then
      begin
        Val(S, Num, Err);
        Result := (Err = 0) and (Num >= 0);
      end
      else
        Result := True;
    end;

  begin
    Result := False;
    Delete(Fn, 1, 4);
    P := RightPos(')',Fn);
    if P < Length(Fn) then Exit;
    Delete(Fn,P,1);
    P := RightPos(',',Fn);
    if P < 1 then            //no comma
    begin
      Result := True;
      TrimBrackets(Fn);
      Exit;
    end;
    S := Copy(Fn,P+1,Length(Fn)-P);
    Delete(Fn,P,(Length(Fn)-P)+1);
    if not StrToNum(S) then Exit;
    P := RightPos(',',Fn);
    if P < 1 then
    begin
      Result := True;
      TrimBrackets(Fn);
      Exit;
    end;
    Delete(Fn,P,(Length(Fn)-P)+1);
    if not StrToNum(S) then Exit;
    Result := True;
    TrimBrackets(Fn);
  end;

  function SUBSTRParamsIsOk(var Fn: string): Boolean;
  var
    S: string;
    P: Integer;

    function StrToNum(const S: string): Boolean;
    var
      Err,Num: Integer;
    begin
      Val(S, Num, Err);
      Result := (Err = 0) and (Num > 0);
    end;

  begin
    Result := False;
    Delete(Fn, 1, 7);               //NAME,1,10)
    P := RightPos(')',Fn);          //P = 10
    if P < Length(Fn) then Exit;
    Delete(Fn,P,1);                 //NAME,1,10
    P := RightPos(',',Fn);          //P=7
    if P < 1 then Exit;
    S := Copy(Fn,P+1,Length(Fn)-P); //NAME,1,10
    Delete(Fn,P,(Length(Fn)-P)+1);  //NAME,1
    if not StrToNum(S) then Exit;
    P := RightPos(',',Fn);          //NAME,1
    if P < 1 then  Exit;
    S := Copy(Fn,P+1,Length(Fn)-P); //S=1
    Delete(Fn,P,(Length(Fn)-P)+1);  //NAME
    if not StrToNum(S) then Exit;
    TrimBrackets(Fn);
    Result := True;
  end;

  function DTOSParamsIsOk(var Fn: string): Boolean;
  var
    P: Integer;
  begin
    Delete(Fn, 1, 5);
    P := RightPos(')',Fn);
    Result := P = Length(Fn);
    if Result then
    begin
      Delete(Fn,P,1);
      TrimBrackets(Fn);
    end;
  end;

  function LOWERParamsIsOk(var Fn: string): Boolean;
  var
    P: Integer;
  begin
    Delete(Fn, 1, 6);
    P := RightPos(')',Fn);
    Result := P = Length(Fn);
    if Result then
    begin
      Delete(Fn,P,1);
      TrimBrackets(Fn);
    end;
  end;

  function UPPERParamsIsOk(var Fn: string): Boolean;
  var
    P: Integer;
  begin
    Delete(Fn, 1, 6);
    P := RightPos(')',Fn);
    Result := P = Length(Fn);
    if Result then
    begin
      Delete(Fn,P,1);
      TrimBrackets(Fn);
    end;
  end;

var
  I,J,P: Integer;
  FnList: TStringList;
  Funcs: array[0..4] of string= ('DTOS(','LOWER(','UPPER(','SUBSTR(','STR(');

  function ValidFunction(Fn: string): Boolean;
  var
    S: string;
    A,B,I,P: Integer;
    List: TStringList;
  begin
    Result := False;
    List := TStringList.Create;
    try
      A := 0; B := 0;
      for I := 1 to Length(Fn) do
      begin
        if  Fn[I]='(' then Inc(A) else
        if  Fn[I]=')' then Inc(B);
      end;
      if A <> B then Exit;
      for I := 0 to 4 do List.Add(Funcs[I]);
      P := Pos('(',Fn);
      while P > 0 do
      begin
        S := Copy(Fn,1,P);
        I := List.IndexOf(S);
        if I >= 0 then FnList.Add(S);
        Delete(Fn,1,P);
        P := Pos('(',Fn);
      end;
      Result := True;
    finally
      List.Free;
    end;
  end;

begin
  Result := False;
  FnList:=TStringList.Create;
  try
    Fn := DelSpace(Fn);
    if not ValidFunction(Fn) then Exit;
    J := FnList.Count;
    if J = 0 then
    begin
      Fld := Fn;
      TrimBrackets(Fld);
      Result := True;
      Exit;
    end;
    for I := 1 to J do
    begin
      TrimBrackets(Fn);
      if Pos('STR(',Fn) = 1 then
      begin
        if STRParamsIsOk(Fn) then
        begin
          P := FnList.IndexOf('STR(');
          FnList.Delete(P);
          Fld := Fn;
          Result := True;
        end else Exit;
      end
      else
      if Pos('DTOS(',Fn) = 1 then
      begin
        if DTOSParamsIsOk(Fn) then
        begin
          P := FnList.IndexOf('DTOS(');
          FnList.Delete(P);
          Fld := Fn;
          Result := True;
        end else Exit;
      end
      else
      if Pos('LOWER(',Fn) = 1 then
      begin
        if LOWERParamsIsOk(Fn) then
        begin
          P := FnList.IndexOf('LOWER(');
          FnList.Delete(P);
          Fld := Fn;
          Result := True;
        end else Exit;
      end
      else
      if Pos('UPPER(',Fn) = 1 then
      begin
        if UPPERParamsIsOk(Fn) then
        begin
          P := FnList.IndexOf('UPPER(');
          FnList.Delete(P);
          Fld := Fn;
          Result := True;
        end else Exit;
      end
      else
      if Pos('SUBSTR(',Fn) = 1 then
      begin
        if SUBSTRParamsIsOk(Fn) then
        begin
          P := FnList.IndexOf('SUBSTR(');
          FnList.Delete(P);
          Fld := Fn;
          Result := True;
        end else Exit;
      end;
    end; {for}
  finally
    FnList.Free;
  end;
end;

procedure InitFieldProperties;
begin
  (****** dBASE VII ***********)
  with XBase[L7,1] do
  begin
    Name:='AutoInc'; NativeType:= '+';
      Size.Max:=4; Size.Min:=4; Size.Def:=4;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L7,2] do
  begin
    Name:='String'; NativeType:= 'C';
      Size.Max:=255; Size.Min:=1; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=False; dFixed:=True;
  end;
  with XBase[L7,3] do
  begin
    Name:='Integer'; NativeType:= 'I';
      Size.Max:=4; Size.Min:=4; Size.Def:=4;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L7,4] do
  begin
    Name:='Float'; NativeType:= 'F';
      Size.Max:=20; Size.Min:=1; Size.Def:=10;
      Digit.Max:=18; Digit.Min:=0; Digit.Def:=2;
      sFixed:=False; dFixed:=False;
  end;
  with XBase[L7,5] do
  begin
    Name:='Largeint'; NativeType:= 'N';
      Size.Max:=20; Size.Min:=1; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=False; dFixed:=True;
  end;
  with XBase[L7,6] do
  begin
    Name:='Boolean'; NativeType:= 'L';
      Size.Max:=1; Size.Min:=1; Size.Def:=1;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L7,7] do
  begin
    Name:='Date'; NativeType:= 'D';
      Size.Max:=8; Size.Min:=8; Size.Def:=8;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L7,8] do
  begin
    Name:='DateTime'; NativeType:= '@';
      Size.Max:=8; Size.Min:=8; Size.Def:=8;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L7,9] do
  begin
    Name:='Blob'; NativeType:= 'B';
      Size.Max:=10; Size.Min:=10; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L7,10] do
  begin
    Name:='Memo'; NativeType:= 'M';
      Size.Max:=10; Size.Min:=10; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L7,11] do
  begin
    Name:='DBaseOle'; NativeType:= 'G';
      Size.Max:=10; Size.Min:=10; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  (****** dBASE IV ************)
  with XBase[L4,1] do
  begin
    Name:='String'; NativeType:= 'C';
      Size.Max:=255; Size.Min:=1; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=False; dFixed:=True;
  end;
  with XBase[L4,2] do
  begin
    Name:='Float'; NativeType:= 'F';
      Size.Max:=20; Size.Min:=1; Size.Def:=10;
      Digit.Max:=18; Digit.Min:=0; Digit.Def:=2;
      sFixed:=False; dFixed:=False;
  end;
  with XBase[L4,3] do
  begin
    Name:='Integer'; NativeType:= 'N';
      Size.Max:=20; Size.Min:=1; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=False; dFixed:=True;
  end;
  with XBase[L4,4] do
  begin
    Name:='Date'; NativeType:= 'D';
      Size.Max:=8; Size.Min:=8; Size.Def:=8;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L4,5] do
  begin
    Name:='Boolean'; NativeType:= 'L';
      Size.Max:=1; Size.Min:=1; Size.Def:=1;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L4,6] do
  begin
    Name:='Memo'; NativeType:= 'M';
      Size.Max:=10; Size.Min:=10; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  (****** dBASE III ************)
  with XBase[L3,1] do
  begin
    Name:='String'; NativeType:= 'C';
      Size.Max:=255; Size.Min:=1; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=False; dFixed:=True;
  end;
  with XBase[L3,2] do
  begin
    Name:='Numeric'; NativeType:= 'N';
      Size.Max:=20; Size.Min:=1; Size.Def:=10;
      Digit.Max:=18; Digit.Min:=0; Digit.Def:=2;
      sFixed:=False; dFixed:=False;
  end;
  with XBase[L3,3] do
  begin
    Name:='Date'; NativeType:= 'D';
      Size.Max:=8; Size.Min:=8; Size.Def:=8;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L3,4] do
  begin
    Name:='Boolean'; NativeType:= 'L';
      Size.Max:=1; Size.Min:=1; Size.Def:=1;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
  with XBase[L3,5] do
  begin
    Name:='Memo'; NativeType:= 'M';
      Size.Max:=10; Size.Min:=10; Size.Def:=10;
      Digit.Max:=0; Digit.Min:=0; Digit.Def:=0;
      sFixed:=True; dFixed:=True;
  end;
end;

function VCLType(NativeType: Char; Level: TLevel): string;
var
  I: Integer;
begin
  case Level of
    L3,L4,L7:
      for I := 1 to FieldTypeCount[Level] do
        if NativeType = XBase[Level,I].NativeType then
        begin
          Result := XBase[Level,I].Name;
          Exit;
        end;
  end;
  Result := 'Unknown';
end;

function DBaseVersion(Dbf: TDbf): string;
begin
  Result := DbfVer[Dbf.DbfFieldDefs.DbfVersion];
end;

initialization
  DefaultFormatSettings.ShortDateFormat :=
    'dd'+DateSeparator+'mm'+DateSeparator+'yyyy';
  DefaultFormatSettings.LongDateFormat :=
    'dd'+DateSeparator+'mm'+DateSeparator+'yyyy';
  DefaultFormatSettings.DateSeparator := DateSeparator;
  DefaultFormatSettings.DecimalSeparator := DecimalSeparator;
  (********)
  InitFieldProperties;

end.

