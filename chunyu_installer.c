﻿#include <windows.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <objbase.h>
#include <stdio.h>

int wmain(void) {
    wchar_t programFilesPath[MAX_PATH];
    if (SHGetFolderPathW(NULL, CSIDL_PROGRAM_FILES, NULL, SHGFP_TYPE_CURRENT, programFilesPath) != S_OK) {
        MessageBoxW(NULL, L"无法获取 Program Files 目录。", L"chunyu·vpn 安装程序", MB_ICONERROR | MB_OK);
        return 1;
    }

    wchar_t installPath[MAX_PATH];
    swprintf(installPath, MAX_PATH, L"%s\\chunyu·vpn", programFilesPath);

    if (!CreateDirectoryW(installPath, NULL)) {
        DWORD err = GetLastError();
        if (err != ERROR_ALREADY_EXISTS) {
            MessageBoxW(NULL, L"无法创建安装目录。", L"chunyu·vpn 安装程序", MB_ICONERROR | MB_OK);
            return 1;
        }
    }

    wchar_t sourceExe[MAX_PATH] = L".\\build_local_vs\\Release\\chunyuvpn.exe";
    wchar_t targetExe[MAX_PATH];
    swprintf(targetExe, MAX_PATH, L"%s\\chunyuvpn.exe", installPath);

    if (!CopyFileW(sourceExe, targetExe, FALSE)) {
        MessageBoxW(NULL, L"复制主程序失败，请确认已构建 Release 版本。", L"chunyu·vpn 安装程序", MB_ICONERROR | MB_OK);
        return 1;
    }

    wchar_t desktopPath[MAX_PATH];
    if (SHGetFolderPathW(NULL, CSIDL_DESKTOPDIRECTORY, NULL, SHGFP_TYPE_CURRENT, desktopPath) == S_OK) {
        wchar_t linkPath[MAX_PATH];
        swprintf(linkPath, MAX_PATH, L"%s\\chunyu·vpn.lnk", desktopPath);

        HRESULT hr = CoInitialize(NULL);
        if (SUCCEEDED(hr)) {
            IShellLinkW *psl = NULL;
            HRESULT hCreate = CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER,
                                               IID_IShellLinkW, (LPVOID*)&psl);
            if (SUCCEEDED(hCreate) && psl != NULL) {
                psl->SetPath(targetExe);
                psl->SetDescription(L"chunyu·vpn");

                IPersistFile *ppf = NULL;
                HRESULT hQuery = psl->QueryInterface(IID_IPersistFile, (void**)&ppf);
                if (SUCCEEDED(hQuery) && ppf != NULL) {
                    ppf->Save(linkPath, TRUE);
                    ppf->Release();
                }
                psl->Release();
            }
            CoUninitialize();
        }
    }

    MessageBoxW(NULL, L"chunyu·vpn 已安装完成。", L"chunyu·vpn 安装程序", MB_ICONINFORMATION | MB_OK);
    return 0;
}
