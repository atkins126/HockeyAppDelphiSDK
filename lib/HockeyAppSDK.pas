unit HockeyAppSDK;

interface

uses
  IdHTTP, System.Generics.Collections, System.JSON, IdMultipartFormData,
  IdComponent;

type
  THockeyNotesType = (Textile, Markdown);
  THockeyDownloadStatus = (Unkown, DontAllowDownload, AllowDownload);

  THockeyApp = class(TObject)
  private
    FTitle: String;
    FBundleIdentifier: String;
    FPlatform: String;
    FId: Int64;
    FPublicIdentifier: String;
  public
    procedure FromJson(jsonObj: TJSONObject);
    function ToString: String;override;

    property Id: Int64 read FId;
    property Title: String read FTitle;
    property BundleIdentifier: String read FBundleIdentifier;
    property Platform: String read FPlatform;
    property PublicIdentifier: String read FPublicIdentifier;
  end;

  THockeyAppList = class(TObjectList<THockeyApp>)
  public
    procedure FromJson(jsonArray: TJSONArray);
    function ToString: String;override;
  end;

  THockeyAppVersion = class(TObject)
  private
    FVersion: String;
    FShortVersion: String;
    FConfigURL: String;
    FDownloadURL: String;
    FNotes: String;
    FAppSize: Int64;
    FId: Integer;
  public
    procedure FromJson(jsonObj: TJSONObject);

    property Id: Integer read FId;
    property Verison: String read FVersion;
    property ShortVersion: String read FShortVersion;
    property ConfigURL: String read FConfigURL;
    property Notes: String read FNotes;
    property DownloadURL: String read FDownloadURL;
    property AppSize: Int64 read FAppSize;
  end;

  THockeyVersionList = class(TObjectList<THockeyAppVersion>)
  public
    procedure FromJson(jsonArray: TJSONArray);
    function ToString: String;override;
  end;

  THockeyCreateVersionInfo = record
    BundleVersion: String;
    BundleShortVersion: String;
    Notes: String;
    NotesType: THockeyNotesType;
    Status: THockeyDownloadStatus;
    Tags: String;
    Teams: String;
    Users: String;

    procedure AssignToFormStream(stream: TIdMultiPartFormDataStream);
  end;

  THockeyUpdateVersionInfo = record
    Ipa: String;
    Dsym: String;
    Notes: String;
    NotesType: THockeyNotesType;
    Notify: Integer;
    Status: THockeyDownloadStatus;
    Tags: String;
    Teams: String;
    Users: String;
    Mandatory: Integer;

    procedure AssignToFormStream(stream: TIdMultiPartFormDataStream);
  end;

  THockeyAppSDK = class(TObject)
  private
    FApiToken: String;
    FLastError: String;
    FOnWork: TWorkEvent;
    FOnWorkBegin: TWorkBeginEvent;
    function getHTTPClient: TIdHTTP;
  public
    function ListApps: THockeyAppList;
    function ListVersions(AppId: String): THockeyVersionList;
    function CreateVersion(AppId: String; createVersionInfo: THockeyCreateVersionInfo): THockeyAppVersion;
    function UpdateVersion(AppId: String; versionId: Integer; updateVersionInfo: THockeyUpdateVersionInfo): THockeyAppVersion;
    function UploadVersion(AppId: String; updateVersionInfo: THockeyUpdateVersionInfo): THockeyAppVersion;

    property LastError: String read FLastError;
    property ApiToken: String read FApiToken write FApiToken;
    property OnWorkBegin: TWorkBeginEvent read FOnWorkBegin write FOnWorkBegin;
    property OnWork: TWorkEvent read FOnWork write FOnWork;
  end;

implementation

uses
  System.SysUtils;


const C_ServiceURL = 'https://rink.hockeyapp.net/api/2/';

{ THockeyApp }

function THockeyAppSDK.CreateVersion(AppId: String;
  createVersionInfo: THockeyCreateVersionInfo): THockeyAppVersion;
var
  http: TIdHTTP;
  resp: string;
  stream: TIdMultiPartFormDataStream;
  jsonObj: TJSONObject;
begin
  http := getHTTPClient;
  stream := TIdMultiPartFormDataStream.Create;
  Result := THockeyAppVersion.Create;
  try
    try
      http.Request.CustomHeaders.AddValue('X-HockeyAppToken', FApiToken);
      createVersionInfo.AssignToFormStream(stream);

      resp := http.Post(C_ServiceURL+'apps/'+AppId+'/app_versions/new', stream);
      jsonObj := TJSONObject.ParseJSONValue(resp) as TJSONObject;
      Result.FromJson(jsonObj);
      jsonObj.Free;
    except
      on E:EIdHTTPProtocolException do
      begin
        FLastError := E.Message;
      end;
      on E:Exception do
      begin
        FLastError := E.Message;
      end;
    end;
  finally
    stream.Free;
    http.Free;
  end;
end;

function THockeyAppSDK.getHTTPClient: TIdHTTP;
begin
  Result := TIdHTTP.Create;
  Result.OnWork := FOnWork;
  Result.OnWorkBegin := FOnWorkBegin;
end;

function THockeyAppSDK.ListApps: THockeyAppList;
var
  http: TIdHTTP;
  resp: string;
  jsonObj: TJSONObject;
begin
  Result := THockeyAppList.Create;
  http := getHTTPClient;
  try
    try
      http.Request.CustomHeaders.AddValue('X-HockeyAppToken', FApiToken);
      resp := http.Get(C_ServiceURL+'apps');

      jsonObj := TJSONObject.ParseJSONValue(resp) as TJSONObject;
      Result.FromJson(TJsonArray(jsonObj.Values['apps']));
      jsonObj.Free;
    except
      on E:Exception do
      begin
        FLastError := E.Message;
      end;
    end;
  finally
    http.Free;
  end;
end;

function THockeyAppSDK.ListVersions(AppId: String): THockeyVersionList;
var
  http: TIdHTTP;
  resp: string;
  jsonObj: TJSONObject;
begin
  Result := THockeyVersionList.Create;
  http := getHTTPClient;
  try
    http.Request.CustomHeaders.AddValue('X-HockeyAppToken', FApiToken);
    try
      resp := http.Get(C_ServiceURL+'apps/'+AppId+'/app_versions');
      jsonObj := TJSONObject.ParseJSONValue(resp) as TJSONObject;
      Result.FromJson(TJsonArray(jsonObj.GetValue('app_versions')));
      jsonObj.Free;
    except
      on E: EIdHTTPProtocolException do
      begin
        FLastError :=  E.ErrorMessage;
      end;
      on E:Exception do
      begin
        FLastError := E.Message;
      end;
    end;
  finally
    http.Free;
  end;
end;

function THockeyAppSDK.UpdateVersion(AppId: String; versionId: Integer;
  updateVersionInfo: THockeyUpdateVersionInfo): THockeyAppVersion;
var
  http: TIdHTTP;
  resp: string;
  stream: TIdMultiPartFormDataStream;
  jsonObj: TJSONObject;
begin
  http := getHTTPClient;
  stream := TIdMultiPartFormDataStream.Create;
  Result := THockeyAppVersion.Create;
  try
    try
      http.Request.CustomHeaders.AddValue('X-HockeyAppToken', FApiToken);
      updateVersionInfo.AssignToFormStream(stream);

      http.Request.CustomHeaders.AddValue('Content-Type', stream.RequestContentType);

      resp := http.Put(C_ServiceURL+'apps/'+AppId+'/app_versions/'+IntToStr(versionId), stream);
      jsonObj := TJSONObject.ParseJSONValue(resp) as TJSONObject;
      Result.FromJson(jsonObj);
      jsonObj.Free;
    except
      on E:EIdHTTPProtocolException do
      begin
        FLastError := E.ErrorMessage;
      end;
      on E:Exception do
      begin
        FLastError := E.Message;
      end;
    end;
  finally
    stream.Free;
    http.Free;
  end;
end;

function THockeyAppSDK.UploadVersion(AppId: String;
  updateVersionInfo: THockeyUpdateVersionInfo): THockeyAppVersion;
var
  http: TIdHTTP;
  stream: TIdMultiPartFormDataStream;
  resp: string;
  jsonObj: TJSONObject;
begin
  Result := THockeyAppVersion.Create;
  http := getHTTPClient;
  stream := TIdMultiPartFormDataStream.Create;
  try
    updateVersionInfo.AssignToFormStream(stream);
    http.Request.CustomHeaders.AddValue('X-HockeyAppToken', FApiToken);
    http.Request.CustomHeaders.AddValue('Content-Type', stream.RequestContentType);

    try
      resp := http.Post(C_ServiceURL+'apps/'+AppId+'/app_versions/upload', stream);
      jsonObj := TJSONObject.ParseJSONValue(resp) as TJSONObject;
      Result.FromJson(jsonObj);
      jsonObj.Free;
    except
      on E:EIdHTTPProtocolException do
      begin
        FLastError := E.ErrorMessage;
      end;
      on E:Exception do
      begin
        FLastError := E.Message;
      end;
    end;
  finally
    http.Free;
    stream.Free;
  end;
end;

{ THockeyApp }

procedure THockeyApp.FromJson(jsonObj: TJSONObject);
begin
  FTitle := jsonObj.Values['title'].Value;
  FBundleIdentifier := jsonObj.Values['bundle_identifier'].Value;
  FPlatform  := jsonObj.Values['platform'].Value;
  jsonObj.Values['id'].TryGetValue<Int64>(FId);
  FPublicIdentifier := jsonObj.Values['public_identifier'].Value;
end;

function THockeyApp.ToString: String;
begin
  Result := Format('Id: %d / Title: %s / BIdent: %s / Platform: %s / PIdent: %s', [Id, Title, BundleIdentifier, Platform, PublicIdentifier]);
end;

{ THockeyAppList }

procedure THockeyAppList.FromJson(jsonArray: TJSONArray);
var
  i: Integer;
  jsonObj: TJSONObject;
  app: THockeyApp;
begin
  Self.Clear;

  for i := 0 to jsonArray.Count-1 do
  begin
    jsonObj :=  jsonArray.Items[i] as TJSONObject;
    app := THockeyApp.Create;
    app.FromJson(jsonObj);
    Self.Add(app);
  end;
end;

function THockeyAppList.ToString: String;
var
  app: THockeyApp;
begin
  Result := '';
  for app in Self do
  begin
    if Result <> '' then Result := Result +#13#10;
    Result := Result + app.ToString;
  end;
end;

{ THockeyCreateVersionInfo }

procedure THockeyCreateVersionInfo.AssignToFormStream(
  stream: TIdMultiPartFormDataStream);
begin
  stream.AddFormField('bundle_version', Self.BundleVersion);
  stream.AddFormField('bundle_short_version', Self.BundleShortVersion);
  stream.AddFormField('notes', Self.Notes);
  stream.AddFormField('notes_type', IntToStr(Integer(NotesType)));
  stream.AddFormField('status', IntToStr(Integer(Self.Status)));
  stream.AddFormField('tags', Self.Tags);
  stream.AddFormField('teams', Self.Teams);
  stream.AddFormField('users', Self.Users);
end;

{ THockeyAppVersion }

procedure THockeyAppVersion.FromJson(jsonObj: TJSONObject);
begin
  jsonObj.TryGetValue<Integer>('id', FId);
  jsonObj.TryGetValue<String>('version', FVersion);
  jsonObj.TryGetValue<String>('shortversion', FShortVersion);
  jsonObj.TryGetValue<String>('config_url', FConfigURL);
  jsonObj.TryGetValue<String>('download_url', FDownloadURL);
  jsonObj.TryGetValue<String>('notes', FNotes);
  jsonObj.TryGetValue<Int64>('appsize', FAppSize);
end;

{ THockeyVersionList }

procedure THockeyVersionList.FromJson(jsonArray: TJSONArray);
var
  i: Integer;
  jsonObj: TJSONObject;
  version: THockeyAppVersion;
begin
  Self.Clear;

  for i := 0 to jsonArray.Count-1 do
  begin
    jsonObj :=  jsonArray.Items[i] as TJSONObject;
    version := THockeyAppVersion.Create;
    version.FromJson(jsonObj);
    Self.Add(version);
  end;
end;

function THockeyVersionList.ToString: String;
var
  version: THockeyAppVersion;
begin
  Result := '';
  for version in Self do
  begin
    if Result <> '' then Result := Result +#13#10;
    Result := Result + version.ToString;
  end;
end;

{ THockeyUpdateVersionInfo }

procedure THockeyUpdateVersionInfo.AssignToFormStream(
  stream: TIdMultiPartFormDataStream);
begin
  if ipa <> '' then stream.AddFile('ipa', Ipa);
  if Dsym <> '' then stream.AddFile('dsym', Dsym);
  stream.AddFormField('notes', notes);
  stream.AddFormField('notes_type', IntToStr(Integer(NotesType)));
  stream.AddFormField('notify', IntToStr(Notify));
  stream.AddFormField('status', IntToStr(Integer(Status)));
  stream.AddFormField('tags', Tags);
  stream.AddFormField('teams', Teams);
  stream.AddFormField('users', Users);
  stream.AddFormField('mandatory', IntToStr(Mandatory));
end;

end.
