#define MyAppName "שמור וזכור"
#define MyAppExeName "ShamorVezachor.exe"
#define MyAppPublisher "NHLOCAL"
#define MyAppURL "https://github.com/NHLOCAL/Shamor-Zachor"

#ifndef MyAppVersion
#define MyAppVersion "0.0.0"
#endif

#ifndef MyAppSourceDir
#define MyAppSourceDir "..\..\src\build\windows\x64\runner\Release"
#endif

#ifndef MyAppOutputDir
#define MyAppOutputDir "..\..\dist"
#endif

#ifndef MyAppOutputBaseFilename
#define MyAppOutputBaseFilename "shamor-vezachor-windows-setup"
#endif

[Setup]
AppId={{90F9D86B-8E57-4E31-B890-6D95D80AF9C7}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases/latest
DefaultDirName={localappdata}\Programs\Shamor Vezachor
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
OutputDir={#MyAppOutputDir}
OutputBaseFilename={#MyAppOutputBaseFilename}
SetupIconFile=..\..\src\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0
SetupLogging=yes

[Languages]
Name: "hebrew"; MessagesFile: "compiler:Languages\Hebrew.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Messages]
hebrew.WelcomeLabel1=ברוכים הבאים להתקנת [name]
hebrew.WelcomeLabel2=אשף זה יתקין את [name/ver] במחשב.%n%nמומלץ לסגור את היישום לפני המשך ההתקנה.
hebrew.FinishedHeadingLabel=התקנת [name] הושלמה
hebrew.FinishedLabelNoIcons=התקנת [name] הסתיימה בהצלחה.
hebrew.SelectDirDesc=באיזו תיקייה להתקין את [name]?

[CustomMessages]
hebrew.CreateDesktopIcon=צור קיצור דרך בשולחן העבודה
hebrew.AdditionalIcons=קיצורי דרך נוספים:
english.CreateDesktopIcon=Create a desktop shortcut
english.AdditionalIcons=Additional shortcuts:
