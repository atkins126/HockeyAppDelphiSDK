unit HockeyCliLib;

interface

uses
  System.JSON;

type
  THockeyCli = class(TObject)
  private
    FAPIToken: String;
    FPublicIdentifier: String;
    FTeams: String;
  public
    constructor Create;overload;
    constructor Create(json: TJSONObject);overload;
    constructor Create(configFile: String);overload;

    procedure DoHockeyAppUpload(packageFileName: String);

    function NeedUpload: Boolean;

    property APIToken: String read FAPIToken write FAPIToken;
    property PublicIdentifier: String read FPublicIdentifier write FPublicIdentifier;
  end;

implementation

uses
  System.IOUtils, System.SysUtils, HockeyAppSDK;

{ THockeyCli }

constructor THockeyCli.Create;
begin
  APIToken := '';
  PublicIdentifier := '';
end;

constructor THockeyCli.Create(json: TJSONObject);
begin
  Create;
  if json.Values['APIToken'] <> nil then FAPIToken := json.Values['APIToken'].Value;
  if json.Values['PublicIdentifier'] <> nil then FPublicIdentifier := json.Values['PublicIdentifier'].Value;
  if json.Values['Teams'] <> nil then FTeams := json.Values['Teams'].Value;
end;

constructor THockeyCli.Create(configFile: String);
var
  fileContents: string;
  obj: TJSONObject;
begin
  fileContents := TFile.ReadAllText(configFile);
  obj := TJSONObject.ParseJSONValue(fileContents) as TJSONObject;
  if (obj <> nil) and (obj.Values['HockeyApp'] <> nil) then Create(obj.Values['HockeyApp'] as TJSONObject);
  obj.Free;
end;

procedure THockeyCli.DoHockeyAppUpload(packageFileName: String);
var
  hockeySDK: THockeyAppSDK;
  versionInfo: THockeyUpdateVersionInfo;
begin
  if not APIToken.IsEmpty and not PublicIdentifier.IsEmpty and FileExists(packageFileName) then
  begin
    versionInfo := Default(THockeyUpdateVersionInfo);
    versionInfo.Ipa := packageFileName;
    versionInfo.Notify := 0;
    versionInfo.Status := THockeyDownloadStatus.AllowDownload;
    versionInfo.Notes := '';
    versionInfo.Teams := FTeams;

    hockeySDK := THockeyAppSDK.Create;
    hockeySDK.ApiToken := APIToken;
    hockeySDK.UploadVersion(PublicIdentifier, versionInfo);
    hockeySDK.Free;
  end;
end;

function THockeyCli.NeedUpload: Boolean;
begin
  Result := not APIToken.IsEmpty and not PublicIdentifier.IsEmpty;
end;

end.
