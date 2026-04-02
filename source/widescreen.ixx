module;

#include <common.hxx>

export module widescreen;

import common;
import settings;

namespace MonitorConfiguration
{
    struct MonitorConfiguration
    {
        int field_0;
        int field_4;
        int field_8;
        float ar;
        //...
    }; GameRef<MonitorConfiguration> sm_MonitorConfig;
}

SafetyHookInline shsub_110F3F0 = {};
void __fastcall sub_110F3F0(void* _this, void* edx, float a2, float a3, unsigned int a4)
{
    float ar = MonitorConfiguration::sm_MonitorConfig->ar;

    if (ar > (16.0f / 9.0f))
    {
        if (a4 == 0x7CABD323)
        {
            a2 /= ar / (16.0f / 9.0f);
        }

        if (a4 == 0xB50EFAA2)
        {
            auto fHudAspectRatioConstraint = FusionFixSettings.GetFloat(PREF_HUDASPECTRATIOCONSTRAINT);
            if (fHudAspectRatioConstraint >= (16.0f / 9.0f))
                a2 /= ar / fHudAspectRatioConstraint;
        }
    }

    return shsub_110F3F0.unsafe_fastcall(_this, edx, a2, a3, a4);
}

class Widescreen
{
public:
    Widescreen()
    {
        FusionFix::onInitEvent() += []()
        {
            auto pattern = hook::pattern("B9 ? ? ? ? E8 ? ? ? ? 8B 15 ? ? ? ? 52 FF 15");
            MonitorConfiguration::sm_MonitorConfig.SetAddress(*pattern.get_first<MonitorConfiguration::MonitorConfiguration*>(1));

            // Disable SUPPORT_MULTI_MONITOR
            pattern = hook::pattern("0F 85 ? ? ? ? 57 E8 ? ? ? ? 8B 0D ? ? ? ? 50");
            injector::WriteMemory<uint16_t>(pattern.get_first(), 0xE990, true);

            pattern = hook::pattern("74 ? 8B CE E8 ? ? ? ? 8B 0D ? ? ? ? 8B 15");
            injector::WriteMemory<uint8_t>(pattern.get_first(), 0xEB, true);

            pattern = hook::pattern("75 ? 8B 46 ? 2B 46");
            injector::WriteMemory<uint8_t>(pattern.get_first(), 0xEB, true);

            //UIParent
            pattern = hook::pattern("8B 44 24 ? F3 0F 10 44 24 ? 33 D2 F3 0F 11 41 ? 39 41 ? 74 ? 89 41 ? 89 51 ? F3 0F 10 44 24");
            shsub_110F3F0 = safetyhook::create_inline(pattern.get_first(), sub_110F3F0);

            pattern = hook::pattern("F3 0F 11 44 24 ? E8 ? ? ? ? 83 C4 ? E8 ? ? ? ? 84 C0");
            static auto camBulletHook = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                float ar = MonitorConfiguration::sm_MonitorConfig->ar;
                if (ar > (16.0f / 9.0f))
                    *(float*)(regs.esp + 0x10) /= ar / (16.0f / 9.0f);
            });

            // Videos
            pattern = hook::pattern("F3 0F 11 44 24 ? E8 ? ? ? ? 8D 4F ? E8");
            static auto DrawMovieQuadHook = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                float screenWidth = *(float*)(regs.esp + 0x24);
                float screenHeight = *(float*)(regs.esp + 0x24 + 0x18);
                float movieWidth = *(float*)(regs.esp + 0x28);
                float movieHeight = *(float*)(regs.esp + 0x28 + 0x10);

                float screenAspect = screenWidth / screenHeight;
                float movieAspect = movieWidth / movieHeight;

                float dstX0 = 0.0f;
                float dstY0 = 0.0f;
                float dstX1 = screenWidth;
                float dstY1 = screenHeight;

                if (screenAspect > movieAspect) // pillarbox
                {
                    float scaledWidth = screenHeight * movieAspect;
                    float offsetX = (screenWidth - scaledWidth) * 0.5f;
                    dstX0 = offsetX;
                    dstX1 = offsetX + scaledWidth;
                }
                else if (screenAspect < movieAspect) // letterbox
                {
                    float scaledHeight = screenWidth / movieAspect;
                    float offsetY = (screenHeight - scaledHeight) * 0.5f;
                    dstY0 = offsetY;
                    dstY1 = offsetY + scaledHeight;
                }

                *(float*)(regs.esp + 0x70) = dstX0;
                *(float*)(regs.esp + 0x74) = dstY0;
                *(float*)(regs.esp + 0x60) = dstX1;
                *(float*)(regs.esp + 0x64) = dstY0;
                *(float*)(regs.esp + 0x50) = dstX0;
                *(float*)(regs.esp + 0x54) = dstY1;
                *(float*)(regs.esp + 0x40) = dstX1;
                *(float*)(regs.esp + 0x44) = dstY1;
            });
        };
    }
} Widescreen;