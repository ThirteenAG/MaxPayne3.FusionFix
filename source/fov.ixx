module;

#include <common.hxx>

export module fov;

import common;
import comvars;
import settings;
import natives;

bool bIsInDisplayMenu = false;

void __fastcall SetFovValue(float* _this, void* edx, float value)
{
    float fCustomFOV = FusionFixSettings.GetFloat(PREF_CUSTOMFOV);

    if (bIsInDisplayMenu)
    {
        static bool wasAddPressed = false;
        static bool wasSubtractPressed = false;
        static bool wasMultiplyPressed = false;

        bool isAddPressed = IsKeyboardKeyPressed(VK_ADD) || Natives::IsButtonJustPressed(0, BUTTON_TRIGGER_RIGHT);
        bool isSubtractPressed = IsKeyboardKeyPressed(VK_SUBTRACT) || Natives::IsButtonJustPressed(0, BUTTON_TRIGGER_LEFT);
        bool isMultiplyPressed = IsKeyboardKeyPressed(VK_MULTIPLY);

        if ((!wasAddPressed && isAddPressed))
        {
            fCustomFOV += 5.0f;
        }

        if ((!wasSubtractPressed && isSubtractPressed))
        {
            fCustomFOV -= 5.0f;
        }

        if ((!wasMultiplyPressed && isMultiplyPressed))
        {
            fCustomFOV = 0.0f;
        }

        wasAddPressed = isAddPressed;
        wasSubtractPressed = isSubtractPressed;
        wasMultiplyPressed = isMultiplyPressed;

        fCustomFOV = std::clamp(fCustomFOV, 45.0f, 95.0f);
        FusionFixSettings.SetFloat(PREF_CUSTOMFOV, fCustomFOV);
    }

    if (fCustomFOV > 45.0f)
        _this[20] = std::clamp(fCustomFOV, 1.0f, 130.0f);
    else
        _this[20] = std::clamp(value, 1.0f, 130.0f);
}

class FOV
{
public:
    FOV()
    {
        FusionFix::onInitEvent() += []()
        {
            auto pattern = hook::pattern("D9 1C 24 F3 0F 11 8E ? ? ? ? E8");
            injector::MakeCALL(pattern.get_first(11), SetFovValue, true);

            pattern = hook::pattern("E8 ? ? ? ? 8B E8 83 FD ? 75 ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 8B E8 8B 0D ? ? ? ? 6A ? E8 ? ? ? ? ? ? ? ? 8B 0D ? ? ? ? F3 0F 11 44 24");
            static auto MS_DisplayHookEnter = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                bIsInDisplayMenu = true;
            });

            pattern = hook::pattern("8B 86 ? ? ? ? F3 0F 2C 88 ? ? ? ? 6A ? 68 ? ? ? ? BA");
            static auto MS_DisplayHookExit = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                bIsInDisplayMenu = false;

                CIniReader iniWriter("");
                iniWriter.WriteFloat("MAIN", "CustomFOV", FusionFixSettings.GetFloat(PREF_CUSTOMFOV));
            });
        };
    }
} FOV;