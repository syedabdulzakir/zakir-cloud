#define MyAppName "Boot2Docker for Windows"
#define MyAppVersion "1.8.0"
#define MyAppPublisher "Docker Inc"
#define MyAppURL "https://docker.com"
#define MyAppContact "https://docs.docker.com"

#define b2dIso ".\bundle\Boot2Docker\boot2docker.iso"
#define b2dCli ".\bundle\Boot2Docker\boot2docker.exe"

#define dockerCli ".\bundle\docker\docker.exe"

#define msysGit ".\bundle\msysGit\Git.exe"

#define virtualBoxCommon ".\bundle\VirtualBox\common.cab"
#define virtualBoxMsi ".\bundle\VirtualBox\VirtualBox_amd64.msi"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{05BD04E9-4AB5-46AC-891E-60EA8FD57D56}
AppCopyright={#MyAppPublisher}
AppContact={#MyAppContact}
AppComments={#MyAppURL}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName=Docker
; lets not be annoying
;InfoBeforeFile=.\LICENSE
;DisableFinishedPage
;InfoAfterFile=
OutputBaseFilename=docker-install
Compression=lzma
SolidCompression=yes
WizardImageFile=logo-docker-side.bmp
WizardSmallImageFile=logo-docker-small.bmp
WizardImageStretch=no
WizardImageBackColor=$325461

; in the installer itself:
SetupIconFile=boot2docker.ico
; in the "Add/Remove" list:
UninstallDisplayIcon={app}\boot2docker.ico

SignTool=ksign /d $q{#MyAppName}$q /du $q{#MyAppURL}$q $f

; for modpath.iss
ChangesEnvironment=true

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "upgrade"; Description: "Upgrade Boot2Docker only"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Tasks]
Name: desktopicon; Description: "{cm:CreateDesktopIcon}"
Name: modifypath; Description: "Add docker.exe/boot2docker.exe to &PATH"
Name: rebootwindows; Description: "&Reboot Windows at the end of installation"; Flags: restart unchecked

[Components]
Name: "Docker"; Description: "Docker Client for Windows" ; Types: full upgrade
Name: "Boot2Docker"; Description: "Boot2Docker management tool and ISO" ; Types: full upgrade
Name: "VirtualBox"; Description: "VirtualBox"; Types: full
Name: "MSYS"; Description: "MSYS-git UNIX tools"; Types: full

[Files]
Source: ".\boot2docker.ico"; DestDir: "{app}"; Flags: ignoreversion

; Docker
Source: "{#dockerCli}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Docker"

; Boot2Docker
Source: "{#b2dIso}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Boot2Docker"
Source: "{#b2dCli}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Boot2Docker"
Source: ".\start.sh"; DestDir: "{app}"; Flags: ignoreversion; Components: "Boot2Docker"
Source: ".\delete.sh"; DestDir: "{app}"; Flags: ignoreversion; Components: "Boot2Docker"

; msys-Git
Source: "{#msysGit}"; DestDir: "{app}\installers\msys-git"; DestName: "msys-git.exe"; AfterInstall: RunInstallMSYS();  Components: "MSYS"

; VirtualBox
Source: "{#virtualBoxCommon}"; DestDir: "{app}\installers\virtualbox"; Components: "VirtualBox"
Source: "{#virtualBoxMsi}"; DestDir: "{app}\installers\virtualbox"; DestName: "virtualbox.msi"; AfterInstall: RunInstallVirtualBox(); Components: "VirtualBox"

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{cm:ProgramOnTheWeb,{#MyAppName}}"; Filename: "{#MyAppURL}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{group}\Boot2Docker Start"; WorkingDir: "{app}"; Filename: "{app}\start.sh"; IconFilename: "{app}/boot2docker.ico"
Name: "{commondesktop}\Boot2Docker Start"; WorkingDir: "{app}"; Filename: "{app}\start.sh"; IconFilename: "{app}/boot2docker.ico"; Tasks: desktopicon
Name: "{commonprograms}\Boot2Docker Start"; WorkingDir: "{app}"; Filename: "{app}\start.sh"; IconFilename: "{app}/boot2docker.ico"
Name: "{group}\Delete Boot2Docker VM"; WorkingDir: "{app}"; Filename: "{app}\delete.sh"

[UninstallRun]
Filename: "{app}\delete.sh"

[Code]
var
	restart: boolean;
// http://stackoverflow.com/questions/9238698/show-licenseagreement-link-in-innosetup-while-installation
	DockerInstallDocs: TLabel;
const
	UninstallKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#SetupSetting("AppId")}_is1';
//  32 bit on 64  HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
function IsUpgrade: Boolean;
var
	Value: string;
begin
	Result := (
		RegQueryStringValue(HKLM, UninstallKey, 'UninstallString', Value)
		or
		RegQueryStringValue(HKCU, UninstallKey, 'UninstallString', Value)
	) and (Value <> '');
end;
function NeedRestart(): Boolean;
begin
	Result := restart;
end;
function NeedToInstallVirtualBox(): Boolean;
begin
	Result := (
		(GetEnv('VBOX_INSTALL_PATH') = '')
		and
		(GetEnv('VBOX_MSI_INSTALL_PATH') = '')
	);
end;
function NeedToInstallMSYS(): Boolean;
begin
	Result := not RegKeyExists(HKEY_LOCAL_MACHINE, 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1');
end;
procedure DocLinkClick(Sender: TObject);
var
	ErrorCode: Integer;
begin
	ShellExec('', 'https://docs.docker.com/installation/windows/', '', '', SW_SHOW, ewNoWait, ErrorCode);
end;
procedure InitializeWizard;
begin
	DockerInstallDocs := TLabel.Create(WizardForm);
	DockerInstallDocs.Parent := WizardForm;
	DockerInstallDocs.Left := 8;
	DockerInstallDocs.Top := WizardForm.ClientHeight - DockerInstallDocs.ClientHeight - 8;
	DockerInstallDocs.Cursor := crHand;
	DockerInstallDocs.Font.Color := clBlue;
	DockerInstallDocs.Font.Style := [fsUnderline];
	DockerInstallDocs.Caption := '{#MyAppName} installation documentation';
	DockerInstallDocs.OnClick := @DocLinkClick;
end;
procedure CurPageChanged(CurPageID: Integer);
begin
	DockerInstallDocs.Visible := True;
	WizardForm.FinishedLabel.AutoSize := True;
	WizardForm.FinishedLabel.Caption :=
		'{#MyAppName} installation completed.' + \
		#13#10 + \
		#13#10 + \
		'Run using the `Boot2Docker Start` icon on your desktop or in [Program Files] - then start a test container with:' + \
		#13#10 + \
		'         `docker run hello-world`' + \
		#13#10 + \
		#13#10 + \
		// TODO: it seems making hyperlinks is hard :/
		//'To save and share container images, automate workflows, and more sign-up for a free <a href="http://hub.docker.com/?utm_source=b2d&utm_medium=installer&utm_term=summary&utm_content=windows&utm_campaign=product">Docker Hub account</a>.' + \
		#13#10 + \
		#13#10 +
		'You can upgrade your existing Boot2Docker VM without data loss by running:' + \
		#13#10 + \
		'         `boot2docker upgrade`' + \
		#13#10 + \
		#13#10 + \
		'For further information, please see the {#MyAppName} installation documentation link.'
	;
	//if CurPageID = wpSelectDir then
		// to go with DisableReadyPage=yes and DisableProgramGroupPage=yes
		//WizardForm.NextButton.Caption := SetupMessage(msgButtonInstall)
	//else
		//WizardForm.NextButton.Caption := SetupMessage(msgButtonNext);
	//if CurPageID = wpFinished then
		//WizardForm.NextButton.Caption := SetupMessage(msgButtonFinish)
		if CurPageID = wpSelectComponents then
		begin
			if IsUpgrade() then
			begin
				Wizardform.TypesCombo.ItemIndex := 2
			end;
			Wizardform.ComponentsList.Checked[2] := NeedToInstallVirtualBox();
			Wizardform.ComponentsList.Checked[3] := NeedToInstallMSYS();
		end;
end;
procedure RunInstallVirtualBox();
var
	ResultCode: Integer;
begin
	WizardForm.FilenameLabel.Caption := 'installing VirtualBox'
	if Exec(ExpandConstant('msiexec'), ExpandConstant('/qn /i "{app}\installers\virtualbox\virtualbox.msi" /norestart'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
	begin
		// handle success if necessary; ResultCode contains the exit code
		//MsgBox('virtualbox install OK', mbInformation, MB_OK);
	end
	else begin
		// handle failure if necessary; ResultCode contains the error code
		MsgBox('virtualbox install failure', mbInformation, MB_OK);
	end;
	//restart := True;
end;
procedure RunInstallMSYS();
var
	ResultCode: Integer;
begin
	WizardForm.FilenameLabel.Caption := 'installing MSYS Git'
	if Exec(ExpandConstant('{app}\installers\msys-git\msys-git.exe'), '/sp- /verysilent /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
	begin
		// handle success if necessary; ResultCode contains the exit code
		//MsgBox('msys installed OK', mbInformation, MB_OK);
	end
	else begin
		// handle failure if necessary; ResultCode contains the error code
		MsgBox('msys install failure', mbInformation, MB_OK);
	end;
end;
const
	ModPathName = 'modifypath';
	ModPathType = 'user';
function ModPathDir(): TArrayOfString;
begin
	setArrayLength(Result, 1);
	Result[0] := ExpandConstant('{app}');
end;
#include "modpath.iss"
