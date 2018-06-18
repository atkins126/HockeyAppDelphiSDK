unit MSBuildLib;

interface

uses
  System.JSON, System.Classes;

type
  TConfiguration = (cDebug, cRelease);
  TPlatform = (pAndroid, piOS);
  TBuildType = (btDebug, btAdhoc, btAppStore);

  TConfigurationHelper = record helper for TConfiguration
    class function fromString(value: String): TConfiguration;static;
    function ToString: String;
  end;

  TPlatformHelper = record helper for TPlatform
    class function fromString(value: String): TPlatform;static;
    function ToString: String;
  end;

  TBuildTypeHelper = record helper for TBuildType
    class function fromString(value: String): TBuildType;static;
    function ToString: String;
  end;

  TMSBuild = class(TObject)
  private
    FDelphiPath: String;
    FConfiguration: TConfiguration;
    FPlatform: TPlatform;
    FBuildType: TBuildType;
    FProjectFileName: String;
    FProjectPath: String;
    function getMSBuildString: String;

    function RunFile(filename: String): Boolean;
    function getPackageFileName: String;
  public
    constructor Create;overload;
    constructor Create(json: TJSONObject);overload;
    constructor Create(configFile: String);overload;

    function DoMSBUILD: Boolean;

    property DelphiPath: String read FDelphiPath write FDelphiPath;
    property Configuration: TConfiguration read FConfiguration write FConfiguration;
    property Platform: TPlatform read FPlatform write FPlatform;
    property BuildType: TBuildType read FBuildType write FBuildType;
    property ProjectPath: String read FProjectPath write FProjectPath;
    property ProjectFileName: String read FProjectFileName write FProjectFileName;

    property PackageFileName: String read getPackageFileName;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, Winapi.Windows;

{ TMSBuild }

constructor TMSBuild.Create;
begin
  FDelphiPath := '';
  FConfiguration := TConfiguration.cRelease;
  FPlatform := TPlatform.pAndroid;
  FBuildType := TBuildType.btDebug;
end;

constructor TMSBuild.Create(json: TJSONObject);
begin
  Create;
  if json.Values['DelphiPath'] <> nil then FDelphiPath := json.Values['DelphiPath'].Value;
  if json.Values['Configuration'] <> nil then FConfiguration := TConfiguration.FromString(json.Values['Configuration'].Value);
  if json.Values['Platform'] <> nil then FPlatform := TPlatform.FromString(json.Values['Platform'].Value);
  if json.Values['BuildType'] <> nil then FBuildType := TBuildType.FromString(json.Values['BuildType'].Value);
  if json.Values['ProjectPath'] <> nil then ProjectPath := json.Values['ProjectPath'].Value;
  if json.Values['ProjectFileName'] <> nil then FProjectFileName := json.Values['ProjectFileName'].Value;
end;

constructor TMSBuild.Create(configFile: String);
var
  fileContents: String;
  obj: TJSONObject;
begin
  fileContents := TFile.ReadAllText(configFile);
  obj := TJSONObject.ParseJSONValue(fileContents) as TJSONObject;
  if (obj <> nil) and (obj.Values['MSBUILD'] <> nil) then Create(obj.Values['MSBUILD'] as TJSONObject);
  obj.Free;
end;

function TMSBuild.DoMSBUILD: Boolean;
var
  sl: TStringList;
  filename: String;
begin
  filename := TPath.Combine(ProjectPath,'autoBuild.bat');
  sl := TStringList.Create;
  sl.Add('call "'+IncludeTrailingPathDelimiter(FDelphiPath)+'bin\rsvars.bat"');
  sl.Add(getMSBuildString);
  sl.SaveToFile(filename);
  sl.Free;

  Result := RunFile(filename);
end;

function TMSBuild.getMSBuildString: String;
var
  configStr: String;
  platformStr: String;
  buildTypeStr: String;
  verbosityStr: String;
begin
  configStr := '/p:Config='+FConfiguration.ToString;
  platformStr := '/p:Platform='+FPlatform.ToString;
  buildTypeStr := '/p:BT_BuildType='+FBuildType.ToString;
  verbosityStr := '/verbosity:diagnostic';
  Result := Format('msbuild %s %s %s %s %s /t:Make;Deploy', [ProjectFilename, configStr, platformStr, buildTypeStr, verbosityStr]);
end;

function TMSBuild.getPackageFileName: String;
begin
  Result := ProjectPath;
  case Platform of
    pAndroid: Result := TPath.Combine(Result, 'Android');
    piOS: Result := TPath.Combine(Result, 'iOSDevice64');
  end;

  case Configuration of
    cDebug: Result := TPath.Combine(Result, 'Debug');
    cRelease: Result := TPath.Combine(Result, 'Release');
  end;

  if Platform = TPlatform.pAndroid then
  begin
    Result := TPath.Combine(Result, ChangeFileExt(ProjectFileName, ''));
    Result := TPath.Combine(Result, 'bin');
    Result := TPath.Combine(Result, ChangeFileExt(ProjectFileName, '.apk'));
  end else
  if Platform = TPlatform.piOS then
  begin
    Result := TPath.Combine(Result, ChangeFileExt(ProjectFileName, '.ipa'));
  end;
end;

function TMSBuild.RunFile(filename: String): Boolean;
var
  si : TStartUpInfo;
  pi : PROCESS_INFORMATION;
  dir: PChar;
  exitCode: Cardinal;
begin
  FillChar(si,SizeOf(si),#0);
  si.cb:= SizeOf(si);
  si.dwFlags := STARTF_USESHOWWINDOW;
  si.wShowWindow := SW_SHOWNORMAL;
  si.lpReserved:= NIL;
  si.cbReserved2:= 0;
  si.lpReserved2:= NIL;
  si.lpTitle:= NIL;
  si.lpDesktop:= PCHAR(''#0);
  dir := PChar(FProjectPath);

  result := CreateProcess (nil, // pointer to name of executable module
    PCHAR(filename+ #0), // pointer to command line string
    NIL, // pointer to process security attributes
    NIL, // pointer to thread security attributes
    false, // new process inherits handles
    0,// oder CREATE_DEFAULT_ERROR_MODE or NORMAL_PRIORITY_CLASS, // creation flags
    PCHAR(''#0), // pointer to new environment block
    dir, // pointer to current directory name
    si, // pointer to STARTUPINFO
    pi); // pointer to PROCESS_INFORMATION
  if result then
  begin
    // auf das Programm-Ende warten
    Result := false;
    if WaitForSingleObject( pi.hProcess, Infinite)=WAIT_OBJECT_0 then
    begin
      GetExitCodeProcess(pi.hProcess, exitCode);
      Result := exitCode = 0;
    end;
    // Close process and thread handles.
    CloseHandle( pi.hProcess );
    CloseHandle( pi.hThread );
  end else
  begin
    RaiseLastOSError
  end;
end;

{ TBuildTypeHelper }

class function TBuildTypeHelper.fromString(value: String): TBuildType;
begin
  Result := TBuildType.btDebug;
  if SameText(value, 'Adhoc') then Result := TBuildType.btAdhoc;
  if SameText(value, 'AppStore') then Result := TBuildType.btAppStore;
end;

function TBuildTypeHelper.ToString: String;
begin
  case self of
    btDebug: Result := 'Debug';
    btAdhoc: Result := 'Adhoc';
    btAppStore: Result := 'AppStore';
  end;
end;

{ TPlatformHelper }

class function TPlatformHelper.fromString(value: String): TPlatform;
begin
  Result := TPlatform.pAndroid;
  if SameText(value, 'iOS') then Result := TPlatform.piOS;
end;

function TPlatformHelper.ToString: String;
begin
  case self of
    pAndroid: Result := 'Android';
    piOS: Result := 'iOSDevice64';
  end;
end;

{ TConfigurationHelper }

class function TConfigurationHelper.fromString(value: String): TConfiguration;
begin
  Result := TConfiguration.cDebug;
  if SameText(value, 'Release') then Result := TConfiguration.cRelease;
end;

function TConfigurationHelper.ToString: String;
begin
  case self of
    cDebug: Result := 'Debug';
    cRelease: Result := 'Release';
  end;
end;

end.
