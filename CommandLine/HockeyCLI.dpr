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

procedure UploadPackage(packageName: String);
begin
  hockeyCliInstance := THockeyCli.Create(configFileName);
  try
    Writeln('Upload Package to HockeyApp');
    hockeyCliInstance.PackageFileName := packageName;
    if hockeyCliInstance.NeedUpload then hockeyCliInstance.DoHockeyAppUpload;
  finally
    hockeyCliInstance.Free;
  end;
end;

begin
  try
    { TODO -oUser -cConsole Main : Code hier einfügen }
    if FindCmdLineSwitch('config', configFileName) then
    begin
      if FileExists(configFileName) then
      begin
        Writeln('Compile and Create Package');
        msbuildInstance := TMSBuild.Create(configFileName);
        try
          if (not msbuildInstance.CanRunMSBuild) then
          begin
            UploadPackage('');
          end else if msbuildInstance.DoMSBUILD then
          begin
            UploadPackage(msbuildInstance.PackageFileName);
          end;
        finally
          msbuildInstance.Free;
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
