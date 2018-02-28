program HockeyApp;

uses
  Vcl.Forms,
  HockeyAppFrm in 'HockeyAppFrm.pas' {HockeyAppDlg},
  HockeyAppSDK in '..\lib\HockeyAppSDK.pas',
  Grijjy.SymbolTranslator in '..\lib\Grijjy.SymbolTranslator.pas',
  Grijjy.ErrorReporting in '..\lib\Grijjy.ErrorReporting.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(THockeyAppDlg, HockeyAppDlg);
  Application.Run;
end.
