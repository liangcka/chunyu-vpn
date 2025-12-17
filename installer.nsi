!define APP_NAME "chunyuvpn"
!define APP_VERSION "0.8.4"
!define COMPANY_NAME "chunyuvpn"
!define INSTALL_DIR_REGKEY "Software\\${COMPANY_NAME}\\${APP_NAME}"
!define EXE_NAME "chunyuvpn.exe"

!include "MUI2.nsh"

!define MUI_ABORTWARNING
!define MUI_ICON "C:\\Users\\xingy\\Downloads\\connecttool-qt-main\\qml\\ConnectTool\\logo.ico"
!define MUI_UNICON "C:\\Users\\xingy\\Downloads\\connecttool-qt-main\\qml\\ConnectTool\\logo.ico"

Unicode True
Name "${APP_NAME} ${APP_VERSION}"
OutFile "chunyuvpn-${APP_VERSION}-Setup.exe"

InstallDir "$PROGRAMFILES64\\${APP_NAME}"
InstallDirRegKey HKCU "${INSTALL_DIR_REGKEY}" "InstallLocation"

RequestExecutionLevel admin

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "SimpChinese"

Section "Install"
SetOutPath "$INSTDIR"
File /r "build_local_vs\\Release\\*.*"
WriteRegStr HKCU "${INSTALL_DIR_REGKEY}" "InstallLocation" "$INSTDIR"
WriteUninstaller "$INSTDIR\\Uninstall.exe"
CreateShortCut "$SMPROGRAMS\\${APP_NAME}.lnk" "$INSTDIR\\${EXE_NAME}"
CreateShortCut "$DESKTOP\\${APP_NAME}.lnk" "$INSTDIR\\${EXE_NAME}"
SectionEnd

Section "Uninstall"
Delete "$DESKTOP\\${APP_NAME}.lnk"
Delete "$SMPROGRAMS\\${APP_NAME}.lnk"
Delete "$INSTDIR\\Uninstall.exe"
RMDir /r "$INSTDIR"
DeleteRegKey HKCU "${INSTALL_DIR_REGKEY}"
SectionEnd
