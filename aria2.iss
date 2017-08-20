#include "compiler:WaterLib.iss"
[Setup]
AppId={{93DD9CDA-9477-49D5-AC51-479CF0C598E7}
AppName=Aria2
AppVersion=1.32
DefaultDirName={pf}\aria2
DefaultGroupName=aria2
UninstallDisplayIcon={app}\aria2.exe
Compression=lzma2
SolidCompression=yes
OutputDir=.
OutputBaseFilename=aria2setup
VersionInfoVersion=1.32.0.0
ArchitecturesInstallIn64BitMode=x64 ia64
DisableProgramGroupPage=yes
DisableWelcomePage=no
WizardImageFile=compiler:WizModernImage-Is.bmp

[Files]
#ifndef ISVersion
Source: InnoCallback.dll; DestDir: {tmp}; Flags: dontcopy noencryption
#endif
Source: "winsw.net2.exe"; DestDir: "{app}"; DestName: "aria2-winsw.exe";Check: not HasNet4
Source: "winsw.net4.exe"; DestDir: "{app}"; DestName: "aria2-winsw.exe";Check: HasNet4
Source: "aria2-winsw.xml"; DestDir: "{app}"
Source: "aria2c-x64.exe"; DestDir: "{app}"; DestName: "aria2c.exe"; Check: IsX64
Source: "aria2c-x86.exe"; DestDir: "{app}"; DestName: "aria2c.exe"; Check: not IsX64
Source: "aria2.conf"; DestDir: "{app}"
Source: "aria2.log"; DestDir: "{app}"
Source: "aria2.session"; DestDir: "{app}";AfterInstall: MyAfterInstall


[Icons]
Name: "{group}\����aria2"; Filename: "{app}\aria2-winsw.exe";Parameters: "start"
Name: "{group}\ֹͣaria2"; Filename: "{app}\aria2-winsw.exe";Parameters: "stop"
Name: "{group}\����"; Filename: "{app}\aria2.conf"
Name: "{group}\ж��aria2"; Filename: "{uninstallexe}"

[INI]
Filename: "{app}\aria2.conf"; Section: "config"; Key: "dir"; String: "{code:SelectDir}"
Filename: "{app}\aria2.conf"; Section: "config"; Key: "input-file"; String: "{app}\aria2.session"
Filename: "{app}\aria2.conf"; Section: "config"; Key: "save-session"; String: "{app}\aria2.session"

[RUN]
Filename: "{app}\aria2-winsw.exe"; Parameters: "install";Flags:runhidden

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[UninstallRun]
Filename: "{app}\aria2-winsw.exe"; Parameters: "uninstall";Flags:runhidden

[Code]
var
  ResultCode: Integer;
  ResultDir: String;
  WaterHandle:Integer;

#ifndef ISVersion
type
 TTimerProc = procedure(H: LongWord; MSG: LongWord; idEvent: LongWord; dwTime: LongWord);

function WrapTimerProc(CallBack: TTimerProc; ParamCount: Integer): LongWord;
  external 'InnoCallback@files:InnoCallBack.dll stdcall';

function SetTimer(hWnd: LongWord; nIDEvent, uElapse: LongWord; lpTimerFunc: LongWord): LongWord;
  external 'SetTimer@user32.dll stdcall';
#endif

function HasNet2():Boolean;
begin
  Result := RegKeyExists(HKLM,'SOFTWARE\Microsoft\.NETFramework\policy\v2.0');
end;

function HasNet4():Boolean;
begin
  Result := RegKeyExists(HKLM,'SOFTWARE\Microsoft\.NETFramework\policy\v4.0');
end;

function InitializeSetup (): Boolean;
begin
  Result := True;
  if (not HasNet2()) and (not HasNet4()) then
  begin
      MsgBox('��Ҫ.net2.0��4.0֧��!', mbInformation, MB_OK);
      Result := False;
  end;
end;

procedure InitializeWizard ();
var
  Page: TInputDirWizardPage;
  F: AnsiString;
  #ifndef ISVersion
  TimerCallBack: LongWord;
  #endif
begin
  WaterSupportAuthor(False);

  F:= ExpandConstant('{tmp}\WizardImage.bmp');
  WizardForm.WizardBitmapImage.Bitmap.SaveToFile(F);
  WaterHandle := WaterInit(WizardForm.WelcomePage.Handle, 2, 2);
  WaterSetBounds(WaterHandle, WizardForm.WizardBitmapImage.Left, WizardForm.WizardBitmapImage.Top, WizardForm.WizardBitmapImage.Width, WizardForm.WizardBitmapImage.Height);
  WaterSetFile(WaterHandle, AnsiString(F));
  WaterSetActive(WaterHandle, True);
  DeleteFile(F);

  Page := CreateInputDirPage(wpSelectDir,
    'ѡ�������ļ��洢λ��', '���뽫�����ļ��洢��ʲô�ط���',
    '�����ļ����洢�������ļ����С� '#13#10#13#10 +
    '��������һ�����������������ѡ�������ļ��У��������������',
    False, '�½��ļ���');

  // �����Ŀ (�ÿձ���)
  Page.Add('');

  // ���ó�ʼֵ (��ѡ)
  Page.Values[0] := ExpandConstant('{%HOMEPATH}\Downloads');
   // ��ȡֵ������
  ResultDir := Page.Values[0];
end;

// eg:LoadValueFromXML('...\Setup.xml', '//Setup/FirstNode');
function LoadValueFromXML(const AFileName, APath: string): string;
var
  XMLNode: Variant;
  XMLDocument: Variant;
begin
  Result := '';
  XMLDocument := CreateOleObject('MSXML2.DOMDocument');
  try
    XMLDocument.async := False;
    XMLDocument.load(AFileName);
    if (XMLDocument.parseError.errorCode <> 0) then
      MsgBox('The XML file could not be parsed. ' +
        XMLDocument.parseError.reason, mbError, MB_OK)
    else
    begin
      XMLDocument.setProperty('SelectionLanguage', 'XPath');
      XMLNode := XMLDocument.selectSingleNode(APath);
      Result := XMLNode.text;
    end;
  except
    MsgBox('An error occured!' + #13#10 + GetExceptionMessage, mbError, MB_OK);
  end;
end;

// eg:SaveValueToXML('...\Setup.xml', '//Setup/FirstNode', 'newValue');
procedure SaveValueToXML(const AFileName, APath, AValue: string);
var
  XMLNode: Variant;
  XMLDocument: Variant;
begin
  XMLDocument := CreateOleObject('Msxml2.DOMDocument');
  try
    XMLDocument.async := False;
    XMLDocument.load(AFileName);
    if (XMLDocument.parseError.errorCode <> 0) then
      MsgBox('The XML file could not be parsed. ' +
        XMLDocument.parseError.reason, mbError, MB_OK)
    else
    begin
      XMLDocument.setProperty('SelectionLanguage', 'XPath');
      XMLNode := XMLDocument.selectSingleNode(APath);
      XMLNode.text := AValue;
      XMLDocument.save(AFileName);
    end;
  except
    MsgBox('An error occured!' + #13#10 + GetExceptionMessage, mbError, MB_OK);
  end;
end;

function SelectDir(Param:String): String;
begin
    Result := ResultDir;
end;

function IsX64: Boolean;
begin
  Result := Is64BitInstallMode and (ProcessorArchitecture = paX64);
end;

procedure MyAfterInstall();
begin
  // modify config in aria2-winsw.xml
  SaveValueToXML(WizardDirValue + '\aria2-winsw.xml', '//service/executable', WizardDirValue + '\aria2c.exe');
  SaveValueToXML(WizardDirValue + '\aria2-winsw.xml', '//service/logpath', WizardDirValue + '\');
  SaveValueToXML(WizardDirValue + '\aria2-winsw.xml', '//service/startargument', '--conf-path=' + WizardDirValue +'\aria2.conf');
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  Case CurPageID of
    wpWelcome : WaterSetParentWindow(WaterHandle, WizardForm.WelcomePage.Handle);  //��ˮ���ƶ�����һ�������
    wpFinished: WaterSetParentWindow(WaterHandle, WizardForm.FinishedPage.Handle); //��ˮ���ƶ�����һ�������
  end;
end;

//�ͷ�����ˮ������
procedure DeinitializeSetup();
begin
  WaterAllFree;
end;