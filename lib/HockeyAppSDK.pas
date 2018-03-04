// Stacktrace for iOS and Android is from here
// https://blog.grijjy.com/2017/02/09/build-your-own-error-reporter-part-1-ios/

unit HockeyAppSDK;

interface

uses
  System.Generics.Collections, System.JSON, System.Net.HttpClient,
  System.Net.Mime, System.Net.URLClient, System.Messaging;

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
    function ToString: String;override;

    property Id: Integer read FId;
    property Version: String read FVersion;
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

    procedure AssignToFormStream(var stream: TMultipartFormData);
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

    procedure AssignToFormStream(stream: TMultipartFormData);
  end;

  THockeyAppCrash = class(TObject)
  private
    FLogFile: String;
    FDescription: String;
    FUserId: String;
    FContact: String;
  public
    procedure AssignToFormStream(stream: TMultipartFormData);


    property LogFile: String read FLogFile write FLogFile;
    property Description: String read FDescription write FDescription;
    property UserID: String read FUserId write FUserId;
    property Contact: String read FContact write FContact;
  end;

  THockeyAppSDK = class(TObject)
  private
    FApiToken: String;
    FLastError: String;
    FOnReceiveData: TReceiveDataEvent;
    function getHTTPClient: THTTPClient;
  public
    function ListApps: THockeyAppList;
    function ListVersions(AppId: String): THockeyVersionList;
    function CreateVersion(AppId: String; createVersionInfo: THockeyCreateVersionInfo): THockeyAppVersion;
    function UpdateVersion(AppId: String; versionId: Integer; updateVersionInfo: THockeyUpdateVersionInfo): THockeyAppVersion;
    function UploadVersion(AppId: String; updateVersionInfo: THockeyUpdateVersionInfo): THockeyAppVersion;

    function UploadCrash(AppId: String; crash: THockeyAppCrash): Boolean;

    property LastError: String read FLastError;
    property ApiToken: String read FApiToken write FApiToken;
    property OnReceiveData: TReceiveDataEvent read FOnReceiveData write FOnReceiveData;
  end;

  THockeyAppExceptionHandler = class(TObject)
  private
    class var
    fCurrent: THockeyAppExceptionHandler;
    FApiToken: String;
    FAppId: String;
    FBundleIdentifier: String;
    FVersion: String;
  private
    var
    FCrashLogs: TObjectList<THockeyAppCrash>;
    procedure LoadCrashLogs;
    procedure SendAsyncToHockey;

    procedure HandleExceptionMessage(const Sender: TObject; const M: TMessage);
  public
    constructor Create;
    destructor Destroy;override;

    procedure Init(ApiToken: String; AppId: String; BundleIdentifier: String; Version: String);
  public
    class function Current: THockeyAppExceptionHandler;
  end;

implementation

uses
  Forms, System.SysUtils, System.Classes, System.IOUtils,
  System.Types, Grijjy.ErrorReporting;


const C_ServiceURL = 'https://rink.hockeyapp.net/api/2/';

{ THockeyApp }

function THockeyAppSDK.CreateVersion(AppId: String;
  createVersionInfo: THockeyCreateVersionInfo): THockeyAppVersion;
var
  http: THTTPClient;
  stream: TMultipartFormData;
  jsonObj: TJSONObject;
  resp: IHTTPResponse;
begin
  http := getHTTPClient;
  stream := TMultipartFormData.Create;
  Result := nil;
  try
    try
      http.CustomHeaders['X-HockeyAppToken'] := FApiToken;
      createVersionInfo.AssignToFormStream(stream);

      resp := http.Post(C_ServiceURL+'apps/'+AppId+'/app_versions/new', stream);
      if resp.StatusCode = 201 then
      begin
        Result := THockeyAppVersion.Create;
        jsonObj := TJSONObject.ParseJSONValue(resp.ContentAsString) as TJSONObject;
        Result.FromJson(jsonObj);
        jsonObj.Free;
      end else
      begin
        FLastError := resp.ContentAsString;
      end;
    except
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

function THockeyAppSDK.getHTTPClient: THTTPClient;
begin
  Result := THTTPClient.Create;
  Result.OnReceiveData := FOnReceiveData;
end;

function THockeyAppSDK.ListApps: THockeyAppList;
var
  jsonObj: TJSONObject;
  http: THTTPClient;
  resp: IHTTPResponse;
begin
  Result := nil;
  http := getHTTPClient;
  try
    try
      http.CustomHeaders['X-HockeyAppToken']:= FApiToken;
      resp := http.Get(C_ServiceURL+'apps');

      if resp.StatusCode = 200 then
      begin
        Result := THockeyAppList.Create;
        jsonObj := TJSONObject.ParseJSONValue(resp.ContentAsString) as TJSONObject;
        Result.FromJson(TJsonArray(jsonObj.Values['apps']));
        jsonObj.Free;
      end else
      begin
        FLastError := resp.ContentAsString;
      end;
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
  jsonObj: TJSONObject;
  http: THTTPClient;
  resp: IHTTPResponse;
begin
  Result := nil;
  http := getHTTPClient;
  try
    http.CustomHeaders['X-HockeyAppToken']:= FApiToken;
    try
      resp := http.Get(C_ServiceURL+'apps/'+AppId+'/app_versions');
      if resp.StatusCode = 200 then
      begin
        Result := THockeyVersionList.Create;
        jsonObj := TJSONObject.ParseJSONValue(resp.ContentAsString) as TJSONObject;
        Result.FromJson(TJsonArray(jsonObj.GetValue('app_versions')));
        jsonObj.Free;
      end else
      begin
        FLastError := resp.ContentAsString;
      end;
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

function THockeyAppSDK.UpdateVersion(AppId: String; versionId: Integer;
  updateVersionInfo: THockeyUpdateVersionInfo): THockeyAppVersion;
var
  stream: TMultipartFormData;
  jsonObj: TJSONObject;
  http: THTTPClient;
  resp: IHTTPResponse;
  tmpStream: TMemoryStream;
begin
  http := getHTTPClient;
  stream := TMultipartFormData.Create;
  Result := nil;
  try
    try
      http.CustomHeaders['X-HockeyAppToken']:= FApiToken;
      updateVersionInfo.AssignToFormStream(stream);

      tmpStream := stream.Stream;
      tmpStream.Position := 0;
      http.ContentType := stream.MimeTypeHeader;
      resp := http.Put(C_ServiceURL+'apps/'+AppId+'/app_versions/'+IntToStr(versionId), tmpStream);

      if resp.StatusCode = 201 then
      begin
        Result := THockeyAppVersion.Create;
        jsonObj := TJSONObject.ParseJSONValue(resp.ContentAsString) as TJSONObject;
        Result.FromJson(jsonObj);
        jsonObj.Free;
      end else
      begin
        FLastError := resp.ContentAsString;
      end;
    except
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

function THockeyAppSDK.UploadCrash(AppId: String; crash: THockeyAppCrash): Boolean;
var
  http: THTTPClient;
  resp: IHTTPResponse;
  stream: TMultipartFormData;
begin
  http := getHTTPClient;
  stream := TMultipartFormData.Create;
  try
    http.CustomHeaders['X-HockeyAppToken']:= FApiToken;

    crash.AssignToFormStream(stream);
    http.ContentType := 'multipart/form-data';//stream.MimeTypeHeader;
    resp := http.Post(C_ServiceURL+'apps/'+AppId+'/crashes/upload', stream);
    Result := resp.StatusCode = 201;
  finally
    http.DisposeOf;
    stream.Free;
  end;
end;

function THockeyAppSDK.UploadVersion(AppId: String;
  updateVersionInfo: THockeyUpdateVersionInfo): THockeyAppVersion;
var
  stream: TMultipartFormData;
  jsonObj: TJSONObject;
  http: THTTPClient;
  resp: IHTTPResponse;
begin
  Result := nil;
  http := getHTTPClient;
  stream := TMultipartFormData.Create;
  try
    updateVersionInfo.AssignToFormStream(stream);
    http.CustomHeaders['X-HockeyAppToken']:= FApiToken;

    try
      resp := http.Post(C_ServiceURL+'apps/'+AppId+'/app_versions/upload', stream);
      if resp.StatusCode = 201 then
      begin
        Result := THockeyAppVersion.Create;
        jsonObj := TJSONObject.ParseJSONValue(resp.ContentAsString) as TJSONObject;
        Result.FromJson(jsonObj);
        jsonObj.Free;
      end else
      begin
        FLastError := resp.ContentAsString;
      end;
    except
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
  var stream: TMultipartFormData);
begin
  stream.AddField('bundle_version', Self.BundleVersion);
//  stream.AddField('bundle_short_version', Self.BundleShortVersion);
  stream.AddField('notes', Self.Notes);
  stream.AddField('notes_type', IntToStr(Integer(NotesType)));
  stream.AddField('status', IntToStr(Integer(Self.Status)));
  stream.AddField('tags', Self.Tags);
  stream.AddField('teams', Self.Teams);
  stream.AddField('users', Self.Users);
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

function THockeyAppVersion.ToString: String;
begin
  Result := Format('%s - %s', [Version, Notes]);
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
  stream: TMultipartFormData);
begin
  if ipa <> '' then stream.AddFile('ipa', Ipa);
  if Dsym <> '' then stream.AddFile('dsym', Dsym);
  stream.AddField('notes', notes);
  stream.AddField('notes_type', IntToStr(Integer(NotesType)));
  stream.AddField('notify', IntToStr(Notify));
  stream.AddField('status', IntToStr(Integer(Status)));
  stream.AddField('tags', Tags);
  stream.AddField('teams', Teams);
  stream.AddField('users', Users);
  stream.AddField('mandatory', IntToStr(Mandatory));
end;

{ THockeyAppCrash }

procedure THockeyAppCrash.AssignToFormStream(stream: TMultipartFormData);
begin
  if LogFile <> '' then stream.AddFile('log', LogFile);
//  stream.AddField('description', description);
  if not UserID.IsEmpty then stream.AddField('userID', UserID);
  if not Contact.IsEmpty then stream.AddField('contact ', Contact);
end;

{ THockeyAppExceptionHandler }

constructor THockeyAppExceptionHandler.Create;
begin
  Application.OnException := TgoExceptionReporter.ExceptionHandler;
  TMessageManager.DefaultManager.SubscribeToMessage(TgoExceptionReportMessage, HandleExceptionMessage);

  FCrashLogs := TObjectList<THockeyAppCrash>.Create;
  LoadCrashLogs;

  if FCrashLogs.Count > 0 then
  begin
    SendAsyncToHockey;
  end;
end;

class function THockeyAppExceptionHandler.Current: THockeyAppExceptionHandler;
begin
  if fCurrent = nil then fCurrent := THockeyAppExceptionHandler.Create;
  Result := fCurrent;
end;

destructor THockeyAppExceptionHandler.Destroy;
begin
  FCrashLogs.DisposeOf;
  inherited;
end;

procedure THockeyAppExceptionHandler.HandleExceptionMessage(
  const Sender: TObject; const M: TMessage);
var
  filename: string;
  hockeyText: string;
begin
  if M is TgoExceptionReportMessage then
  begin
    filename := TPath.Combine(TPath.GetDocumentsPath, Format('Exception%s.log', [FormatDateTime('yyyymmddhhnnss', Now)]));
    hockeyText := 'Package: '+ FBundleIdentifier +#13#10+
                  'Version: ' + FVersion +#13#10+
                  'Date: '+DateTimeToStr(Now)+#13#10+
                  #13#10;
    TFile.WriteAllText(filename, hockeyText + TgoExceptionReportMessage(M).Report.Report);
  end;
end;

procedure THockeyAppExceptionHandler.Init(ApiToken, AppId, BundleIdentifier,
  Version: String);
begin
  FApiToken := ApiToken;
  FAppId := AppId;
  FBundleIdentifier := BundleIdentifier;
  FVersion := Version;
end;

procedure THockeyAppExceptionHandler.LoadCrashLogs;
var
  files: TStringDynArray;
  logFile: String;
  crash: THockeyAppCrash;
  filepath: string;
  guid: string;
begin
  filepath := TPath.GetDocumentsPath;
  files := TDirectory.GetFiles(filepath, '*.log');
  guid := TGUID.NewGuid.ToString;
  for logFile in files do
  begin
    crash := THockeyAppCrash.Create;
    crash.LogFile := logFile;
    crash.UserID := guid;
    FCrashLogs.Add(crash);
  end;
end;

procedure THockeyAppExceptionHandler.SendAsyncToHockey;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      hockey: THockeyAppSDK;
      crash: THockeyAppCrash;
    begin
      hockey := THockeyAppSDK.Create;
      hockey.ApiToken := FApiToken;
      for crash in FCrashLogs do
      begin
        hockey.UploadCrash(FAppId, crash);
        TFile.Delete(crash.LogFile);
      end;
    end).Start;
end;

end.
