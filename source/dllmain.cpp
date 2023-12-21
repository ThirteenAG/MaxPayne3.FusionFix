#include <common.hxx>
#include <shellapi.h>
#include <Commctrl.h>
#pragma comment(lib,"Comctl32.lib")
#pragma comment(linker,"\"/manifestdependency:type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

import common;
import comvars;
import settings;
import natives;

injector::hook_back<void(__cdecl*)()> hbCGameProcess;
void __cdecl CGameProcessHook()
{
    static std::once_flag of;
    std::call_once(of, []()
    {
        FusionFix::onGameInitEvent().executeAll();
    });

    static auto oldMenuState = 0;
    if (!Natives::IsPauseMenuActive())
    {
        auto curMenuState = false;
        if (curMenuState != oldMenuState)
        {
            FusionFix::onMenuExitEvent().executeAll();
        }
        oldMenuState = curMenuState;
        FusionFix::onGameProcessEvent().executeAll();
    }
    else
    {
        auto curMenuState = true;
        if (curMenuState != oldMenuState) {
            FusionFix::onMenuEnterEvent().executeAll();
        }
        oldMenuState = curMenuState;
        FusionFix::onMenuDrawingEvent().executeAll();
    }

    return hbCGameProcess.fun();
}

void Init()
{
    FusionFixSettings.ReadIniSettings();

    auto pattern = hook::pattern("E8 ? ? ? ? E8 ? ? ? ? 8B 0D ? ? ? ? 8B 15 ? ? ? ? 89 0D");
    hbCGameProcess.fun = injector::MakeCALL(pattern.get_first(0), CGameProcessHook, true).get();

    static auto futures = FusionFix::onInitEventAsync().executeAllAsync();

    FusionFix::onGameInitEvent() += []()
    {
        for (auto& f : futures.get())
            f.wait();
        futures.get().clear();
    };

    FusionFix::onInitEvent().executeAll();
}

HRESULT CALLBACK TaskDialogCallbackProc(HWND hwnd, UINT uNotification, WPARAM wParam, LPARAM lParam, LONG_PTR dwRefData)
{
    switch (uNotification)
    {
    case TDN_HYPERLINK_CLICKED:
        ShellExecuteW(hwnd, L"open", (LPCWSTR)lParam, NULL, NULL, SW_SHOW);
        break;
    }

    return S_OK;
}

void UALCompat()
{
    if (IsUALPresent())
        return;

    TASKDIALOGCONFIG tdc = { sizeof(TASKDIALOGCONFIG) };
    int nClickedBtn;
    BOOL bCheckboxChecked;
    LPCWSTR
        szTitle = L"MaxPayne3.FusionFix",
        szHeader = L"You are running Max Payne 3 Fusion Fix with an incompatible version of ASI Loader",
        szContent = L"It requires the latest version of " \
        L"<a href=\"https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/latest\">Ultimate ASI Loader</a>\n\n" \
        L"<a href=\"https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/latest\">https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/latest</a>";
    TASKDIALOG_BUTTON aCustomButtons[] = { { 1000, L"Close the program" } };
    
    tdc.hwndParent = gWnd;
    tdc.dwFlags = TDF_USE_COMMAND_LINKS | TDF_ENABLE_HYPERLINKS | TDF_SIZE_TO_CONTENT | TDF_CAN_BE_MINIMIZED;
    tdc.pButtons = aCustomButtons;
    tdc.cButtons = _countof(aCustomButtons);
    tdc.pszWindowTitle = szTitle;
    tdc.pszMainIcon = TD_INFORMATION_ICON;
    tdc.pszMainInstruction = szHeader;
    tdc.pszContent = szContent;
    tdc.pfCallback = TaskDialogCallbackProc;
    tdc.lpCallbackData = 0;
    
    auto hr = TaskDialogIndirect(&tdc, &nClickedBtn, NULL, &bCheckboxChecked);
    TerminateProcess(GetCurrentProcess(), 0);
}

extern "C"
{
    void __declspec(dllexport) InitializeASI()
    {
        std::call_once(CallbackHandler::flag, []()
        {
            CallbackHandler::RegisterCallback(Init, hook::pattern("C6 44 24 ? ? F3 0F 11 44 24 ? F3 0F 11 44 24 ? 89 4C 24 54"));
        });
    }
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID lpReserved)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        if (!IsUALPresent()) { InitializeASI(); }
    }
    if (reason == DLL_PROCESS_DETACH)
    {
        FusionFix::onShutdownEvent().executeAll();
    }
    return TRUE;
}
