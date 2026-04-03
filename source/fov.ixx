module;

#include <common.hxx>

export module fov;

import common;
import comvars;
import settings;
import natives;

bool bIsInDisplayMenu = false;

class FOV
{
public:
    FOV()
    {
        FusionFix::onInitEvent() += []()
        {
            auto pattern = hook::pattern("F3 0F 10 0D ? ? ? ? 0F 2F C8 77 ? F3 0F 11 4C 24 ? ? ? ? ? 51 8B CE");
            static auto camThirdPersonPedAimHook = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                float fCustomFOV = FusionFixSettings.GetFloat(PREF_CUSTOMFOV);

                if (bIsInDisplayMenu)
                {
                    static bool wasAddPressed = false;
                    static bool wasSubtractPressed = false;
                    static bool wasMultiplyPressed = false;

                    bool isAddPressed = IsKeyboardKeyPressed(VK_ADD) || IsKeyboardKeyPressed(VK_OEM_PLUS) || Natives::IsButtonJustPressed(0, BUTTON_TRIGGER_RIGHT);
                    bool isSubtractPressed = IsKeyboardKeyPressed(VK_SUBTRACT) || IsKeyboardKeyPressed(VK_OEM_MINUS) || Natives::IsButtonJustPressed(0, BUTTON_TRIGGER_LEFT);
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

                    fCustomFOV = std::clamp(fCustomFOV, 0.0f, 45.0f);
                    FusionFixSettings.SetFloat(PREF_CUSTOMFOV, fCustomFOV);
                }

                if (fCustomFOV > 0.0f)
                    *(float*)(regs.esp + 4) = std::clamp(*(float*)(regs.esp + 4) + fCustomFOV, 1.0f, 130.0f);
                else
                    *(float*)(regs.esp + 4) = std::clamp(*(float*)(regs.esp + 4), 1.0f, 130.0f);
            });

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