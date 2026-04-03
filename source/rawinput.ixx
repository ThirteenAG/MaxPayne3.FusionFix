module;

#include <common.hxx>

export module rawinput;

import common;
import comvars;
import settings;

class RawInput
{
public:
    RawInput()
    {
        FusionFix::onInitEventAsync() += []()
        {
            // Main menu cursor acceleration, was 1.6
            static float f1 = 1.0f;
            auto pattern = hook::pattern("F3 0F 59 05 ? ? ? ? F3 0F 10 15 ? ? ? ? F3 0F 11 4C 24");
            injector::WriteMemory(pattern.get_first(4), &f1, true);

            pattern = hook::pattern("F3 0F 59 05 ? ? ? ? 0F 57 C9 0F 2F C8 77 ? F3 0F 10 0D ? ? ? ? 0F 2F C1 76 ? F3 0F 11 4C 24");
            injector::WriteMemory(pattern.get_first(4), &f1, true);

            // Force fetching system cursor position
            pattern = hook::pattern("74 ? 8D 44 24 ? 50 FF 15 ? ? ? ? 83 F8");
            injector::MakeNOP(pattern.get_first(), 2, true);

            // Clip cursor, maybe not the best place to do it
            pattern = hook::pattern("FF 15 ? ? ? ? 85 C0 74 ? A1");
            static auto MenuCursorHook = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                RECT rec;
                GetWindowRect((HWND)regs.edx, &rec);
                ClipCursor(&rec);
            });
        };
    }
} RawInput;