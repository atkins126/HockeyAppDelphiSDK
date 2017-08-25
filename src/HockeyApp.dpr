program HockeyApp;

uses
  Vcl.Forms,
  HockeyAppFrm in 'HockeyAppFrm.pas' {HockeyAppDlg},
  HockeyAppSDK in '..\lib\HockeyAppSDK.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(THockeyAppDlg, HockeyAppDlg);
  Application.Run;
end.
