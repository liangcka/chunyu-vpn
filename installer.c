#define UNICODE
#define _UNICODE

#include <windows.h>
#include <shlobj.h>
#include <wchar.h>

static void get_module_directory(wchar_t *buffer, DWORD size)
{
    DWORD len = GetModuleFileNameW(NULL, buffer, size);
    if (len == 0 || len >= size)
        return;
    while (len > 0)
    {
        if (buffer[len - 1] == L'\\' || buffer[len - 1] == L'/')
            break;
        len--;
    }
    buffer[len] = L'\0';
}

static int ensure_trailing_backslash(wchar_t *path, DWORD size)
{
    size_t len = wcslen(path);
    if (len == 0)
        return 0;
    if (path[len - 1] == L'\\' || path[len - 1] == L'/')
        return 1;
    if (len + 1 >= size)
        return 0;
    path[len] = L'\\';
    path[len + 1] = L'\0';
    return 1;
}

static int copy_tree(const wchar_t *src, const wchar_t *dst, const wchar_t *self_path)
{
    wchar_t search[MAX_PATH];
    WIN32_FIND_DATAW data;
    HANDLE h;

    if (!CreateDirectoryW(dst, NULL))
    {
        DWORD err = GetLastError();
        if (err != ERROR_ALREADY_EXISTS)
            return 0;
    }

    if (wcslen(src) + 3 >= MAX_PATH)
        return 0;

    wcscpy_s(search, MAX_PATH, src);
    wcscat_s(search, MAX_PATH, L"*.*");

    h = FindFirstFileW(search, &data);
    if (h == INVALID_HANDLE_VALUE)
        return 0;

    do
    {
        if (wcscmp(data.cFileName, L".") == 0 || wcscmp(data.cFileName, L"..") == 0)
            continue;

        wchar_t src_path[MAX_PATH];
        wchar_t dst_path[MAX_PATH];

        if (wcslen(src) + wcslen(data.cFileName) + 1 >= MAX_PATH)
            continue;
        if (wcslen(dst) + wcslen(data.cFileName) + 1 >= MAX_PATH)
            continue;

        wcscpy_s(src_path, MAX_PATH, src);
        wcscat_s(src_path, MAX_PATH, data.cFileName);

        wcscpy_s(dst_path, MAX_PATH, dst);
        wcscat_s(dst_path, MAX_PATH, data.cFileName);

        if (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        {
            size_t len_src = wcslen(src_path);
            size_t len_dst = wcslen(dst_path);
            if (len_src + 1 < MAX_PATH)
            {
                src_path[len_src] = L'\\';
                src_path[len_src + 1] = L'\0';
            }
            if (len_dst + 1 < MAX_PATH)
            {
                dst_path[len_dst] = L'\\';
                dst_path[len_dst + 1] = L'\0';
            }
            copy_tree(src_path, dst_path, self_path);
        }
        else
        {
            if (_wcsicmp(src_path, self_path) == 0)
                continue;
            CopyFileW(src_path, dst_path, FALSE);
        }
    } while (FindNextFileW(h, &data));

    FindClose(h);
    return 1;
}

static int choose_directory(wchar_t *out_dir, DWORD size)
{
    BROWSEINFOW bi;
    LPITEMIDLIST pidl;

    ZeroMemory(&bi, sizeof(bi));
    bi.hwndOwner = NULL;
    bi.lpszTitle = L"Select install folder";
    bi.ulFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE | BIF_USENEWUI;

    pidl = SHBrowseForFolderW(&bi);
    if (!pidl)
        return 0;

    if (!SHGetPathFromIDListW(pidl, out_dir))
    {
        CoTaskMemFree(pidl);
        return 0;
    }

    CoTaskMemFree(pidl);
    return 1;
}

int APIENTRY wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow)
{
    wchar_t self_dir[MAX_PATH];
    wchar_t self_path[MAX_PATH];
    wchar_t target_root[MAX_PATH];
    wchar_t target_dir[MAX_PATH];

    int res;

    UNREFERENCED_PARAMETER(hInstance);
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);
    UNREFERENCED_PARAMETER(nCmdShow);

    MessageBoxW(NULL, L"Welcome to chunyu \u00b7 vpn", L"chunyu \u00b7 vpn Setup", MB_OK | MB_ICONINFORMATION);

    CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);

    if (!choose_directory(target_root, MAX_PATH))
    {
        CoUninitialize();
        return 0;
    }

    if (!ensure_trailing_backslash(target_root, MAX_PATH))
    {
        CoUninitialize();
        MessageBoxW(NULL, L"Install path is invalid", L"chunyu \u00b7 vpn Setup", MB_OK | MB_ICONERROR);
        return 0;
    }

    if (wcslen(target_root) + wcslen(L"chunyu \u00b7 vpn") + 1 >= MAX_PATH)
    {
        CoUninitialize();
        MessageBoxW(NULL, L"Install path is too long", L"chunyu \u00b7 vpn Setup", MB_OK | MB_ICONERROR);
        return 0;
    }

    wcscpy_s(target_dir, MAX_PATH, target_root);
    wcscat_s(target_dir, MAX_PATH, L"chunyu \u00b7 vpn");

    if (GetFileAttributesW(target_dir) != INVALID_FILE_ATTRIBUTES)
    {
        res = MessageBoxW(NULL, L"Target folder already exists. Overwrite files and continue?", L"chunyu \u00b7 vpn Setup", MB_YESNO | MB_ICONWARNING);
        if (res != IDYES)
        {
            CoUninitialize();
            return 0;
        }
    }

    if (!ensure_trailing_backslash(target_dir, MAX_PATH))
    {
        CoUninitialize();
        MessageBoxW(NULL, L"Install path is invalid", L"chunyu \u00b7 vpn Setup", MB_OK | MB_ICONERROR);
        return 0;
    }

    GetModuleFileNameW(NULL, self_path, MAX_PATH);
    get_module_directory(self_dir, MAX_PATH);
    ensure_trailing_backslash(self_dir, MAX_PATH);

    MessageBoxW(NULL, L"Copying files, please wait.", L"chunyu \u00b7 vpn Setup", MB_OK | MB_ICONINFORMATION);

    if (!copy_tree(self_dir, target_dir, self_path))
    {
        CoUninitialize();
        MessageBoxW(NULL, L"Install failed. Please check disk space and permissions.", L"chunyu \u00b7 vpn Setup", MB_OK | MB_ICONERROR);
        return 0;
    }

    CoUninitialize();

    MessageBoxW(NULL, L"Install finished.", L"chunyu \u00b7 vpn Setup", MB_OK | MB_ICONINFORMATION);
    return 0;
}
