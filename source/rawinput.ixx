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

    // The camera multiplies each frame's mouse movement by the frame time, so the same movement turned the camera
    // less the higher the frame rate. Scaled to a 144 fps frame, the turn depends only on the movement, and the
    // sensitivity slider covers the range players knew at high frame rates (at 60 fps even its lowest value was fast).
    static inline bool (__fastcall* ReadCameraInput)(void*, void*, uint8_t*, float*, float*, float*) = nullptr;
    static inline uint8_t* (__cdecl* GetPlayerControls)(int) = nullptr;
    static inline GameRef<float> fCameraTimeStep;

    static bool __fastcall ReadCameraMouse(void* camera, void* edx, uint8_t* controls, float* amount, float* x, float* y)
    {
        const bool result = ReadCameraInput(camera, edx, controls, amount, x, y);
        auto state = GetPlayerControls(0);
        if ((state[7658] || state[7656]) && fCameraTimeStep > 0.0f)
        {
            // This step is twice the frame time, 1/72 s at 144 fps
            const float scale = 1.0f / (72.0f * fCameraTimeStep);
            *amount *= scale;
            *x *= scale;
            *y *= scale;
        }
        return result;
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

            auto camera = hook::pattern("8B CE E8 ? ? ? ? 8A 4E 41 F3 0F 10 44 24 08 C0 E0 07 80 E1 7F 0A C1 6A 00 88 46 41 F3 0F 11 44 24 3C E8 ? ? ? ? 83 C4 04 80 B8 EA 1D 00 00 00").get_first<uint8_t>();
            ReadCameraInput = reinterpret_cast<decltype(ReadCameraInput)>(injector::GetBranchDestination(camera + 2).as_int());
            GetPlayerControls = reinterpret_cast<decltype(GetPlayerControls)>(injector::GetBranchDestination(camera + 35).as_int());
            fCameraTimeStep.SetAddress(*hook::get_pattern<float*>("F6 06 01 F3 0F 10 0D ? ? ? ? F3 0F 59 4C 24 3C", 7));
            injector::MakeCALL(camera + 2, ReadCameraMouse, true);

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
