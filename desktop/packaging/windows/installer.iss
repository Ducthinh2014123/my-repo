; Inno Setup script — build file setup.exe cho Windows
; Bien VARIANT duoc truyen tu build_windows.bat: /DVARIANT=CPU hoac /DVARIANT=GPU
#ifndef VARIANT
  #define VARIANT "CPU"
#endif

[Setup]
AppName=WhisperSub
AppVersion=1.0.0
AppPublisher=Milan
DefaultDirName={autopf}\WhisperSub
DefaultGroupName=WhisperSub
OutputDir=..\..\dist-installer
OutputBaseFilename=WhisperSub-Setup-{#VARIANT}-1.0.0
SetupIconFile=..\..\assets\icon.ico
Compression=lzma2/max
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
DisableDirPage=no
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
; Bo comment neu da cai goi ngon ngu tieng Viet cho Inno Setup:
; Name: "vietnamese"; MessagesFile: "compiler:Languages\Vietnamese.isl"

[Tasks]
Name: "desktopicon"; Description: "Tạo shortcut ngoài Desktop"; Flags: unchecked

[Files]
Source: "..\..\dist\WhisperSub\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\WhisperSub"; Filename: "{app}\WhisperSub.exe"
Name: "{autodesktop}\WhisperSub"; Filename: "{app}\WhisperSub.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\WhisperSub.exe"; Description: "Mở WhisperSub"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Xoa model da tai khi go app (xoa dong nay neu muon giu model)
Type: filesandordirs; Name: "{userappdata}\WhisperSub\models"
