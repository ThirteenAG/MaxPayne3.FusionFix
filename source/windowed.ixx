module;

#include <common.hxx>

export module windowed;

import common;
import comvars;
import settings;

BOOL WINAPI SetRect_Hook(LPRECT lprc, int xLeft, int yTop, int xRight, int yBottom)
{
    gRect = { xLeft, yTop, xRight, yBottom };
    return SetRect(lprc, xLeft, yTop, xRight, yBottom);
}

// True while the style is applied from here, so the size this file forces onto
// the window is not mistaken for the size the game wants to render at.
static bool bApplyingWindowStyle = false;

// The client area is what the game renders into, so that is the size worth
// remembering. SetRect only reports the resolution the game asked for while
// starting, the one the menu switches to has to be read off the window itself,
// otherwise the remembered size stays at the resolution from the start.
static void StoreCurrentClientSize(HWND hWnd)
{
    RECT rect{};
    if (GetClientRect(hWnd, &rect) && rect.right > 0 && rect.bottom > 0)
        gRect = { 0, 0, rect.right, rect.bottom };
}

BOOL WINAPI MoveWindow_Hook(HWND hWnd, int X, int Y, int nWidth, int nHeight, BOOL bRepaint)
{
    RECT rect = { X, Y, nWidth, nHeight };
    HMONITOR monitor = MonitorFromWindow(hWnd, MONITOR_DEFAULTTONEAREST);
    MONITORINFO info = {};
    info.cbSize = sizeof(MONITORINFO);
    GetMonitorInfo(monitor, &info);
    int32_t DesktopResW = info.rcMonitor.right - info.rcMonitor.left;
    int32_t DesktopResH = info.rcMonitor.bottom - info.rcMonitor.top;
    // A window as big as the desktop is the game going fullscreen, the size it
    // currently renders at is used instead of that request.
    if (((rect.right - rect.left >= DesktopResW) || (rect.bottom - rect.top >= DesktopResH)) &&
        gRect.right > 0 && gRect.bottom > 0)
        rect = gRect;
    rect.left = (LONG)(((float)DesktopResW / 2.0f) - ((float)rect.right / 2.0f));
    rect.top = (LONG)(((float)DesktopResH / 2.0f) - ((float)rect.bottom / 2.0f));

    BOOL bResult = MoveWindow(hWnd, rect.left, rect.top, rect.right, rect.bottom, bRepaint);

    if (!bApplyingWindowStyle && hWnd == gWnd)
        StoreCurrentClientSize(hWnd);

    return bResult;
}

// bForce: apply the style even when the window already has it. The window is
// created with a plain style, so the first call has to set the size as well.
// Editing the ini calls this too, and there it must not resize anything: the
// game keeps the resolution it is running at, restoring the remembered size
// used to put it back to the resolution the game started with.
void SwitchWindowStyle(bool bForce = true)
{
    if (gWnd)
    {
        static constexpr LONG lManagedStyle = WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU;

        LONG lStyle = GetWindowLong(gWnd, GWL_STYLE);
        LONG lNewStyle = FusionFixSettings.GetInt(PREF_BORDERLESS) ? (lStyle & ~lManagedStyle) : (lStyle | lManagedStyle);

        if (!bForce && lStyle == lNewStyle)
            return;

        RECT rect = gRect;
        if (rect.right - rect.left <= 0 || rect.bottom - rect.top <= 0)
            GetClientRect(gWnd, &rect);

        AdjustWindowRect(&rect, lNewStyle, FALSE);
        SetWindowLong(gWnd, GWL_STYLE, lNewStyle);

        bApplyingWindowStyle = true;
        MoveWindow_Hook(gWnd, 0, 0, rect.right - rect.left, rect.bottom - rect.top, TRUE);
        bApplyingWindowStyle = false;
    }
}

HWND WINAPI CreateWindowExA_Hook(DWORD dwExStyle, LPCSTR lpClassName, LPCSTR lpWindowName, DWORD dwStyle, int X, int Y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam)
{
    gWnd = CreateWindowExA(dwExStyle, lpClassName, lpWindowName, 0, X, Y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
    SwitchWindowStyle();
    return gWnd;
}

HWND WINAPI CreateWindowExW_Hook(DWORD dwExStyle, LPCWSTR lpClassName, LPCWSTR lpWindowName, DWORD dwStyle, int X, int Y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam)
{
    gWnd = CreateWindowExW(dwExStyle, lpClassName, lpWindowName, 0, X, Y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
    SwitchWindowStyle();
    return gWnd;
}

BOOL WINAPI CenterWindowPosition(int nWidth, int nHeight)
{
    // fix the window to open at the center of the screen...
    HMONITOR monitor = MonitorFromWindow(GetDesktopWindow(), MONITOR_DEFAULTTONEAREST);
    MONITORINFOEX info = { sizeof(MONITORINFOEX) };
    GetMonitorInfo(monitor, &info);
    DEVMODE devmode = {};
    devmode.dmSize = sizeof(DEVMODE);
    EnumDisplaySettings(info.szDevice, ENUM_CURRENT_SETTINGS, &devmode);
    DWORD DesktopX = devmode.dmPelsWidth;
    DWORD DesktopY = devmode.dmPelsHeight;

    int newWidth = nWidth;
    int newHeight = nHeight;

    int WindowPosX = (int)(((float)DesktopX / 2.0f) - ((float)newWidth / 2.0f));
    int WindowPosY = (int)(((float)DesktopY / 2.0f) - ((float)newHeight / 2.0f));

    return SetWindowPos(gWnd, 0, WindowPosX, WindowPosY, newWidth, newHeight, SWP_NOZORDER | SWP_FRAMECHANGED);
}

BOOL WINAPI AdjustWindowRect_Hook(LPRECT lpRect, DWORD dwStyle, BOOL bMenu)
{
    if (FusionFixSettings.GetInt(PREF_BORDERLESS))
        dwStyle &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
    else
        dwStyle |= (WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);

    return AdjustWindowRect(lpRect, dwStyle, bMenu);
}

static void afterCreateWindow()
{
    LONG lStyle = GetWindowLong(gWnd, GWL_STYLE);

    if (FusionFixSettings.GetInt(PREF_BORDERLESS))
        lStyle &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
    else
    {
        lStyle |= (WS_MINIMIZEBOX | WS_SYSMENU);
    }

    SetWindowLong(gWnd, GWL_STYLE, lStyle);
    SetWindowPos(gWnd, 0, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE | SWP_NOZORDER | SWP_FRAMECHANGED);
}

BOOL WINAPI SetWindowPos_Hook(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags)
{
    BOOL res = SetWindowPos(hWnd, hWndInsertAfter, X, Y, cx, cy, uFlags);
    if (FusionFixSettings.GetInt(PREF_BORDERLESS))
    {
        afterCreateWindow();
        RECT rect;
        GetClientRect(hWnd, &rect);
        CenterWindowPosition(rect.right, rect.bottom);
        return TRUE;
    }

    if (!bApplyingWindowStyle && hWnd == gWnd)
        StoreCurrentClientSize(hWnd);

    return res;
}

LONG WINAPI SetWindowLongA_Hook(HWND hWnd, int nIndex, LONG dwNewLong)
{
    if (FusionFixSettings.GetInt(PREF_BORDERLESS))
    {
        afterCreateWindow();
        RECT rect;
        GetClientRect(hWnd, &rect);
        CenterWindowPosition(rect.right, rect.bottom);
        return dwNewLong;
    }
    else
    {
        dwNewLong |= (WS_MINIMIZEBOX | WS_SYSMENU);
    }

    return SetWindowLongA(hWnd, GWL_STYLE, dwNewLong);
}

class Windowed
{
public:
    Windowed()
    {
        FusionFix::onInitEvent() += []()
        {
            IATHook::Replace(GetModuleHandleA(NULL), "USER32.DLL",
                std::forward_as_tuple("CreateWindowExA", CreateWindowExA_Hook),
                std::forward_as_tuple("CreateWindowExW", CreateWindowExW_Hook),
                std::forward_as_tuple("MoveWindow", MoveWindow_Hook),
                std::forward_as_tuple("AdjustWindowRect", AdjustWindowRect_Hook),
                std::forward_as_tuple("SetRect", SetRect_Hook),
                std::forward_as_tuple("SetWindowLongA", SetWindowLongA_Hook),
                std::forward_as_tuple("SetWindowPos", SetWindowPos_Hook)
            );

            FusionFix::onIniFileChange() += []()
            {
                // the style only, an option that has nothing to do with the
                // window must not change its size
                SwitchWindowStyle(false);
            };

            FusionFix::onMenuOptionChange() += [](std::string_view name, int32_t oldVal, int32_t curVal)
            {
                if (name == "MS_Graphics.FullScreenList")
                {
                    if (curVal == 0) // windowed
                    {
                        static auto counter = 0;

                        CIniReader iniWriter("");
                        iniWriter.WriteInteger("MAIN", "BorderlessWindowed", counter);

                        counter++;

                        if (counter > 1)
                            counter = 0;
                        else if (counter < 0)
                            counter = 1;
                    }
                }
            };
        };
    }
} Windowed;