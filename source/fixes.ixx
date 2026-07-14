module;

#include <common.hxx>

export module fixes;

import common;
import settings;

bool bSkipIntelVendorChecks = true;

class Fixes
{
public:
    Fixes()
    {
        FusionFix::onInitEventAsync() += []()
        {
            // Disable global leaderboards, fixes a crash while playing on the Hoboken Alleys coop map
            {
                auto pattern = hook::pattern("8B 81 ? ? ? ? 83 F8 ? 77 ? FF 24 85 ? ? ? ? B8");
                static raw_mem fnLeaderboards(pattern.get_first(0), { 0xC3 }); // ret

                static auto LeaderboardsCB = []()
                {
                    if (FusionFixSettings.GetInt(PREF_DISABLELEADERBOARDS))
                        fnLeaderboards.Write();
                    else
                        fnLeaderboards.Restore();
                };

                LeaderboardsCB();

                FusionFix::onIniFileChange() += []()
                {
                    LeaderboardsCB();
                };
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
            CIniReader iniReader("");

            // [MAIN]
            bSkipIntelVendorChecks = iniReader.ReadInteger("MAIN", "SkipIntelVendorChecks", 1) != 0;

            // Intel GPU vendor checks fix
            // Some Intel GPUs are blocked from switching to anything else than DX9, probably meant for old iGPUs which usually didn't support certain features at the time.
            // Nowadays this is not usually the case anymore, and it kills the potential of more modern integrated chips (e.g. Iris XE) or perhaps even Intel ARC cards (Not tested) to brute force this game due to outdated DX9 drivers.
            // In case some older iGPUs have problems as a result of this change (Unlikely?!), it is gated around a hidden option which can be added in the .ini to disable it.
            if (bSkipIntelVendorChecks)
            {
                auto pattern = hook::pattern("0F 85 ? ? ? ? 81 BC 24");
                injector::WriteMemory<uint16_t>(pattern.get_first(0), 0xE990, true);
            }
        };
    }
} Fixes;