module;

#include <common.hxx>
#include <Commctrl.h>
#include <atomic>
#include "OverlayInput.hpp"
#include "MouseMotion.hpp"

export module rawinput;

import common;
import comvars;
import settings;

// Keeps the cursor inside the game window's client area while the game has the focus (MAIN.ConfineCursor). The game's
// own clips (the whole window, fullscreen only) are left out, see Overlay.cpp.
export namespace CursorClip
{
    std::atomic<bool> clipped = false;
    RECT wanted{};      // the client area in screen coordinates
    RECT applied{};     // what Windows made of it, clamped to the desktop
    constexpr UINT_PTR subclassId = 0x46464343;

    void Release()
    {
        if (clipped.exchange(false))
            ClipCursor(nullptr);
    }

    void Update()
    {
        // Free while unfocused or minimized, and while the settings overlay is open
        if (!FusionFixSettings.GetInt(PREF_CONFINECURSOR) || !gWnd || GetForegroundWindow() != gWnd || IsIconic(gWnd) || MP3Overlay::BlocksInput())
        {
            Release();
            return;
        }

        RECT rect;
        if (!GetClientRect(gWnd, &rect) || IsRectEmpty(&rect))
            return;
        MapWindowPoints(gWnd, nullptr, (LPPOINT)&rect, 2);

        // Set again when the window moved or was resized, or something else changed the clip
        RECT current;
        GetClipCursor(&current);
        if (clipped && EqualRect(&rect, &wanted) && EqualRect(&current, &applied))
            return;

        if (ClipCursor(&rect))
        {
            wanted = rect;
            GetClipCursor(&applied);
            clipped = true;
        }
    }

    LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wp, LPARAM lp, UINT_PTR, DWORD_PTR)
    {
        switch (message)
        {
            case WM_ACTIVATEAPP:
                if (wp)
                    Update();
                else
                    Release();
                break;
            case WM_SIZE:
            case WM_MOVE:
                Update();
                break;
            case WM_NCDESTROY:
                Release();
                RemoveWindowSubclass(hwnd, WindowProc, subclassId);
                break;
        }
        return DefSubclassProc(hwnd, message, wp, lp);
    }

    // Focus changes, moves and resizes, also while the game doesn't run its frames
    void AttachWindow(HWND window)
    {
        if (window)
            SetWindowSubclass(window, WindowProc, subclassId, 0);
    }
}

class RawInput
{
    static inline SafetyHookMid mouseMotionHook;
    static inline const DIMOUSESTATE2* mouseState = nullptr;

    static void ReadMouseMotion(SafetyHookContext& context)
    {
        MouseMotion::UseImmediateState(context.esp, *mouseState);
    }

public:
    RawInput()
    {
        FusionFix::onInitEventAsync() += []()
        {
            // Use the accumulated axes from the successful state read instead of the 16-event batch.
            auto mouse = find_pattern("68 ? ? ? ? 6A 14 50 FF D2 85 C0 74 26 89 3D ? ? ? ? 89 3D ? ? ? ? 89 3D ? ? ? ? 89 3D ? ? ? ? 89 3D ? ? ? ? 5F 81 C4 4C 01 00 00 C3 8B 44 24 04 53 55 56 33 ED 33 DB 33 F6");
            if (mouse.size() == 1)
            {
                mouseState = *mouse.get_first<DIMOUSESTATE2*>(1);
                mouseMotionHook = safetyhook::create_mid(mouse.get_first(52), ReadMouseMotion);
            }

            // Main menu cursor acceleration, was 1.6
            static float f1 = 1.0f;
            auto pattern = hook::pattern("F3 0F 59 05 ? ? ? ? F3 0F 10 15 ? ? ? ? F3 0F 11 4C 24");
            if (!pattern.empty())
                injector::WriteMemory(pattern.get_first(4), &f1, true);

            pattern = hook::pattern("F3 0F 59 05 ? ? ? ? 0F 57 C9 0F 2F C8 77 ? F3 0F 10 0D ? ? ? ? 0F 2F C1 76 ? F3 0F 11 4C 24");
            if (!pattern.empty())
                injector::WriteMemory(pattern.get_first(4), &f1, true);

            // Force fetching system cursor position
            pattern = hook::pattern("74 ? 8D 44 24 ? 50 FF 15 ? ? ? ? 83 F8");
            if (!pattern.empty())
                injector::MakeNOP(pattern.get_first(), 2, true);
        };

        FusionFix::onInitEvent() += []()
        {
            SettingsPlugin().OnChange("MAIN.ConfineCursor", []
            {
                if (!FusionFixSettings.GetInt(PREF_CONFINECURSOR))
                    CursorClip::Release();
            });
        };

        // Every frame, menus included; the clip is only set again when it changed
        FusionFix::onGameProcessEvent() += CursorClip::Update;
        FusionFix::onMenuDrawingEvent() += CursorClip::Update;
    }
} RawInput;
