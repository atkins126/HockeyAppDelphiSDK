program HockeyCLI;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  HockeyAppSDK in '..\lib\HockeyAppSDK.pas',
  Grijjy.ErrorReporting in '..\lib\Grijjy.ErrorReporting.pas',
  Grijjy.SymbolTranslator in '..\lib\Grijjy.SymbolTranslator.pas',
  HockeyCliLib in 'HockeyCliLib.pas',
  MSBuildLib in 'MSBuildLib.pas';

var
  configFileName: String;
  hockeyCliInstance: THockeyCli;
  msbuildInstance: TMSBuild;
begin
  try
    { TODO -oUser -cConsole Main : Code hier einfügen }
    if FindCmdLineSwitch('config', configFileName) then
    begin
      if FileExists(configFileName) then
      begin
        Writeln('Compile and Create Package');
        msbuildInstance := TMSBuild.Create(configFileName);
        hockeyCliInstance := THockeyCli.Create(configFileName);
        try
          if msbuildInstance.DoMSBUILD and hockeyCliInstance.NeedUpload then
          begin
            Writeln('Upload Package to HockeyApp');
            hockeyCliInstance.DoHockeyAppUpload(msbuildInstance.PackageFileName);
          end;
        finally
          msbuildInstance.Free;
          hockeyCliInstance.Free;
        end;
      end;
      Writeln('Done...');
    end;
    Readln(configFileName);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
