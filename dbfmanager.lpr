program dbfmanager;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, dbflaz, lazcontrols, runtimetypeinfocontrols, laz_fpspreadsheet,
  main_unit, createtable2, addnewfield, restructure_table, dbfpublics,
  define_index, table_fields, index_help, about, memo_view, new_opt,
  createtable, filter_records, locate_unit, clonetable, export_dbf;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TfrMain, frMain);
  Application.CreateForm(TfrCreateTable, frCreateTable);
  Application.CreateForm(TfrCreateTable2, frCreateTable2);
  Application.CreateForm(TfrDefineIndex, frDefineIndex);
  Application.CreateForm(TfrTableFields, frTableFields);
  Application.Run;
end.

