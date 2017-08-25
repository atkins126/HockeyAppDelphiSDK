unit HockeyAppFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, HockeyAppSDK,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP;

type
  THockeyAppDlg = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private-Deklarationen }
    hockeyApp: THockeyAppSDK;
    versionInfo: THockeyAppVersion;
    procedure BeginUpload(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
    procedure Upload(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
  public
    { Public-Deklarationen }
  end;

var
  HockeyAppDlg: THockeyAppDlg;

implementation

uses
  IdMultipartFormData;

{$R *.dfm}

procedure THockeyAppDlg.BeginUpload(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
  Self.Caption := 'Max: '+IntToStr(AWorkCountMax);
end;

procedure THockeyAppDlg.Button1Click(Sender: TObject);
var
  liste: THockeyAppList;
begin
  liste := hockeyApp.ListApps;
  Memo1.Text := liste.ToString;
  liste.Free;
end;

procedure THockeyAppDlg.Button2Click(Sender: TObject);
var
  info: THockeyCreateVersionInfo;
begin
  info.BundleVersion := '2';
  info.BundleShortVersion := '1.0';
  info.Notes := 'Das ist ein Test';
  versionInfo := hockeyApp.CreateVersion('11c9dce486cf4a018aee5115a463789c', info);
  Memo1.Lines.Add(versionInfo.Notes);
  versionInfo.Free;
end;

procedure THockeyAppDlg.Button3Click(Sender: TObject);
var
  updateVersionInfo: THockeyUpdateVersionInfo;
  filename: string;
  neueVersion: THockeyAppVersion;
begin
  if PromptForFileName(filename) then
  begin
    updateVersionInfo := Default(THockeyUpdateVersionInfo);
    updateVersionInfo.Ipa := filename;
    updateVersionInfo.Notes := '- Erster Punkt'+#13#10+'- Zweiter Punkt';
    updateVersionInfo.NotesType := THockeyNotesType.Markdown;
    updateVersionInfo.Notify := 0;
    updateVersionInfo.Status := THockeyDownloadStatus.AllowDownload;
    neueVersion := hockeyApp.UpdateVersion('11c9dce486cf4a018aee5115a463789c', 2, updateVersionInfo);
    Memo1.Lines.Add(neueVersion.Notes);
    neueVersion.Free;
  end;
end;

procedure THockeyAppDlg.Button4Click(Sender: TObject);
var
  versions: THockeyVersionList;
begin
  versions := hockeyApp.ListVersions('11c9dce486cf4a018aee5115a463789c');
  versions.Free;
end;

procedure THockeyAppDlg.Button5Click(Sender: TObject);
var
  updateVersionInfo: THockeyUpdateVersionInfo;
  filename: string;
  neueVersion: THockeyAppVersion;
begin
  if PromptForFileName(filename) then
  begin
    updateVersionInfo := Default(THockeyUpdateVersionInfo);
    updateVersionInfo.Ipa := filename;
    updateVersionInfo.Notes := '- Erster Punkt'+#13#10+'- Zweiter Punkt';
    updateVersionInfo.NotesType := THockeyNotesType.Markdown;
    updateVersionInfo.Notify := 0;
    updateVersionInfo.Status := THockeyDownloadStatus.AllowDownload;
    neueVersion := hockeyApp.UploadVersion('11c9dce486cf4a018aee5115a463789c', updateVersionInfo);
    Memo1.Lines.Add(neueVersion.Notes);
    neueVersion.Free;
  end;
end;

procedure THockeyAppDlg.FormCreate(Sender: TObject);
begin
  hockeyApp := THockeyAppSDK.Create;
  hockeyApp.ApiToken := 'e9dfffc2c7ff4cae81137213cf9aafa0';
  hockeyApp.OnWorkBegin := BeginUpload;
  hockeyApp.OnWork := Upload;
end;

procedure THockeyAppDlg.FormDestroy(Sender: TObject);
begin
  hockeyApp.Free;
end;

procedure THockeyAppDlg.Upload(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
  Memo1.Lines.Add('Status: '+IntToStr(AWorkCount));
end;

end.
