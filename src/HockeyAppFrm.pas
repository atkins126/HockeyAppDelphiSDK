unit HockeyAppFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, HockeyAppSDK, Vcl.ExtCtrls;

type
  THockeyAppDlg = class(TForm)
    Button1: TButton;
    MResponse: TMemo;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Panel1: TPanel;
    EdApiToken: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Panel2: TPanel;
    rgNotesType: TRadioGroup;
    MReleaseNotes: TMemo;
    cbApps: TComboBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EdApiTokenChange(Sender: TObject);
  private
    { Private-Deklarationen }
    hockeyApp: THockeyAppSDK;
    liste: THockeyAppList;
  public
    { Public-Deklarationen }
  end;

var
  HockeyAppDlg: THockeyAppDlg;

implementation


{$R *.dfm}

procedure THockeyAppDlg.Button1Click(Sender: TObject);
var
  app: THockeyApp;
begin
  if Assigned(liste) then liste.Free;
  liste := hockeyApp.ListApps;
  if liste = nil then
  begin
    MResponse.Text := hockeyApp.LastError;
  end else
  begin
    cbApps.Clear;
    for app in liste do
    begin
      cbApps.Items.AddObject(app.Title + ' - ' + app.Platform, app);
    end;
  end;
end;

procedure THockeyAppDlg.Button2Click(Sender: TObject);
var
  info: THockeyCreateVersionInfo;
  versionInfo: THockeyAppVersion;
  app: THockeyApp;
begin
  app := THockeyApp(cbApps.Items.Objects[cbApps.ItemIndex]);

  info := Default(THockeyCreateVersionInfo);
  info.BundleVersion := '2';
  info.BundleShortVersion := '2.0';
  info.Notes := MReleaseNotes.Text;
  info.NotesType := THockeyNotesType(rgNotesType.ItemIndex);
  versionInfo := hockeyApp.CreateVersion(app.PublicIdentifier, info);
  if versionInfo = nil then
  begin
    MResponse.Text := hockeyApp.LastError;
  end else
  begin
    MResponse.Text := versionInfo.Notes;
  end;
  versionInfo.Free;
end;

procedure THockeyAppDlg.Button3Click(Sender: TObject);
var
  updateVersionInfo: THockeyUpdateVersionInfo;
  filename: string;
  neueVersion: THockeyAppVersion;
  app: THockeyApp;
begin
  if PromptForFileName(filename) then
  begin
    app := THockeyApp(cbApps.Items.Objects[cbApps.ItemIndex]);
    updateVersionInfo := Default(THockeyUpdateVersionInfo);
    updateVersionInfo.Ipa := filename;
    updateVersionInfo.Notes := MReleaseNotes.Text;
    updateVersionInfo.NotesType := THockeyNotesType(rgNotesType.ItemIndex);
    updateVersionInfo.Notify := 0;
    updateVersionInfo.Status := THockeyDownloadStatus.AllowDownload;
    neueVersion := hockeyApp.UpdateVersion(app.PublicIdentifier, 11, updateVersionInfo);
    if neueVersion = nil then
    begin
      MResponse.Text := hockeyApp.LastError;
    end else
    begin
      MResponse.Text := neueVersion.Notes;
    end;
    neueVersion.Free;
  end;
end;

procedure THockeyAppDlg.Button4Click(Sender: TObject);
var
  versions: THockeyVersionList;
  app: THockeyApp;
begin
  app := THockeyApp(cbApps.Items.Objects[cbApps.ItemIndex]);
  versions := hockeyApp.ListVersions(app.PublicIdentifier);
  if versions = nil then
  begin
    MResponse.Text := hockeyApp.LastError;
  end else
  begin
    MResponse.Text := versions.ToString;
  end;
  versions.Free;
end;

procedure THockeyAppDlg.Button5Click(Sender: TObject);
var
  updateVersionInfo: THockeyUpdateVersionInfo;
  filename: string;
  neueVersion: THockeyAppVersion;
  app: THockeyApp;
begin
  if PromptForFileName(filename) then
  begin
    app := THockeyApp(cbApps.Items.Objects[cbApps.ItemIndex]);
    updateVersionInfo := Default(THockeyUpdateVersionInfo);
    updateVersionInfo.Ipa := filename;
    updateVersionInfo.Notes := MReleaseNotes.Text;
    updateVersionInfo.NotesType := THockeyNotesType(rgNotesType.ItemIndex);
    updateVersionInfo.Notify := 0;
    updateVersionInfo.Status := THockeyDownloadStatus.AllowDownload;
    neueVersion := hockeyApp.UploadVersion(app.PublicIdentifier, updateVersionInfo);
    if neueVersion = nil then
    begin
      MResponse.Text := hockeyApp.LastError;
    end else
    begin
      MResponse.Text := neueVersion.Notes;
    end;
    neueVersion.Free;
  end;
end;

procedure THockeyAppDlg.EdApiTokenChange(Sender: TObject);
begin
  hockeyApp.ApiToken := EdApiToken.Text;
end;

procedure THockeyAppDlg.FormCreate(Sender: TObject);
begin
  hockeyApp := THockeyAppSDK.Create;
end;

procedure THockeyAppDlg.FormDestroy(Sender: TObject);
begin
  hockeyApp.Free;
end;


end.
