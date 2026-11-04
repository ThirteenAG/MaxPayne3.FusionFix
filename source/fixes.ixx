module;

#include <common.hxx>
#include <format>

export module fixes;

import common;
import settings;

namespace TextNumbers
{
    int __cdecl Substitute(const wchar_t* text, int first, int second, int third, int fourth,
        int fifth, int sixth, float value, int precision, wchar_t* output)
    {
        if (!text)
        {
            *output = L'\0';
            return 0;
        }

        // The original uses wchar_t[10], including its terminator. A ten-digit
        // leaderboard score overwrites the return address with that terminator.
        const std::array numbers = { first, second, third, fourth, fifth, sixth };
        auto number = precision < 0 ? std::to_wstring(first)
            : std::format(L"{:.{}f}", static_cast<double>(value), precision);
        const std::wstring_view input(text);
        unsigned char substitutions = 0;
        for (size_t i = 0; i < input.size();)
        {
            if (i + 2 < input.size() &&
                ((input[i] == L'~' && input[i + 1] == L'1' && input[i + 2] == L'~') ||
                 (input[i] == L'|' && input[i + 1] == L'0' && input[i + 2] == L'\\')))
            {
                for (auto character : number) *output++ = character;
                i += 3;
                // Preserve the game's six arguments, including its behavior for
                // additional placeholders and the byte-sized substitution counter.
                if (++substitutions >= 1 && substitutions <= 5)
                    number = std::to_wstring(numbers[substitutions]);
            }
            else
                *output++ = input[i++];
        }
        *output = L'\0';
        return 0;
    }
}

class Fixes
{
public:
    Fixes()
    {
        FusionFix::onInitEventAsync() += []()
        {
            // Keep leaderboards usable when a record needs ten or more digits.
            {
                auto pattern = hook::pattern("83 EC 30 57 8B 7C 24 38 85 FF 75 ? 8B 4C 24 5C 33 C0 66 89 01");
                static auto TextNumbersFix = safetyhook::create_inline(pattern.get_first(), TextNumbers::Substitute);
            }

            // Disable WM_DEVICECHANGE message handler, since it pauses the game randomly for some reason
            {
                auto pattern = hook::pattern("74 ? 83 E8 ? 0F 85 ? ? ? ? E8 ? ? ? ? 84 C0 0F 84");
                static raw_mem pDeviceChangeCheck(pattern.get_first(0), { 0x90, 0x90 }); // nop

                static auto DeviceChangeCB = []()
                {
                    if (FusionFixSettings.GetInt(PREF_DEVICECHANGE))
                        pDeviceChangeCheck.Write();
                    else
                        pDeviceChangeCheck.Restore();
                };

                DeviceChangeCB();

                FusionFix::onIniFileChange() += []()
                {
                    DeviceChangeCB();
                };
            }

            // Cutscene panels animation fixes
            {
                // For the renderer command 0xB6 both PC version 22 and console sample around the center.
                // Whereas version 28 and above on PC calculate the sampling center from the coords which breaks the panels' movement.
                auto pattern = hook::pattern("F3 0F 59 CC F3 0F 59 C4 F3 0F 59 DC");
                injector::MakeNOP(pattern.get_first(0), 8, true);
                static auto CutscenePanelsAnimationFix = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
                {
                    regs.xmm1 = regs.xmm4;
                    regs.xmm0 = regs.xmm4;
                });

                // On PC the position deltas for LockSlide are missing fabs, adding them back fixes some panels
                pattern = hook::pattern("F3 0F 5C DA ? ? ? ? F3 0F 11 4C 24 ? ? ? ? ? F3 0F 59 D8");

                static auto CutscenePanelsLockSlideYFix = safetyhook::create_mid(pattern.get_first(0x12), [](SafetyHookContext& regs)
                    {
                        regs.xmm3.f32[0] = fabs(regs.xmm3.f32[0]);
                    });

                static auto CutscenePanelsLockSlideXFix = safetyhook::create_mid(pattern.get_first(0x27), [](SafetyHookContext& regs)
                    {
                        regs.xmm2.f32[0] = fabs(regs.xmm2.f32[0]);
                    });
            }
        };

        FusionFix::onInitEvent() += []()
        {
            // Intel GPU vendor checks fix
            // Some Intel GPUs are blocked from switching to anything else than DX9, probably meant for old iGPUs which usually didn't support certain features at the time.
            // Nowadays this is not usually the case anymore, and it kills the potential of more modern integrated chips (e.g. Iris XE) or perhaps even Intel ARC cards (Not tested) to brute force this game due to outdated DX9 drivers.
            // In case some older iGPUs have problems as a result of this change (Unlikely?!), it is gated around a hidden option, SkipIntelVendorChecks in the .cfg, to disable it.
            if (FusionFixSettings.GetInt(PREF_SKIPINTELVENDORCHECKS))
            {
                auto pattern = hook::pattern("0F 85 ? ? ? ? 81 BC 24");
                injector::WriteMemory<uint16_t>(pattern.get_first(0), 0xE990, true);
            }
        };
    }
} Fixes;
