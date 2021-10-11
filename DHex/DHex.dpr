program DHex;

uses
  Forms,
  Main in 'Main.pas' {FrmMain},
  OvTEdit in 'OvTEdit.pas',
  MnTools in 'MnTools.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title:='DHex';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
