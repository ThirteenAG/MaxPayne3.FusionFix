module;

#include <common.hxx>
#include <cmath>

export module widescreen;

import common;
import settings;

namespace FusionFixUI
{
// Scale the width of the game's centered HUD parent, never beyond the viewport.
// A nonpositive constraint means Auto (the full available width).
inline float HudWidthScale(float displayAspect, float constraint)
{
    if (!std::isfinite(displayAspect) || displayAspect <= 0 ||
        !std::isfinite(constraint) || constraint <= 0)
        return 1.0f;
    return std::min(constraint, displayAspect) / displayAspect;
}
}

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

    }

    if (a4 == 0xB50EFAA2)
        a2 *= FusionFixUI::HudWidthScale(ar, FusionFixSettings.GetFloat(PREF_HUDASPECTRATIOCONSTRAINT));

    return shsub_110F3F0.unsafe_fastcall(_this, edx, a2, a3, a4);
}

// Screen-space quads of the cinematic cameras (intro overlays, kill cams). Each entry is 144 bytes: top left,
// top right and bottom left corners in pixels, then the scale the quad grows by around its center.
namespace CinematicOverlay
{
    constexpr size_t EntrySize = 144;
    constexpr size_t TopRightOffset = 0x10;
    constexpr size_t BottomLeftOffset = 0x20;
    constexpr size_t ScaleOffset = 0x7C;
    constexpr size_t RelativeTypeOffset = 0x85;
    constexpr uint8_t RelativeTypeScreen = 3;

    uint8_t* pQuads = nullptr;
    float* (__cdecl* NormalizedRectToViewportPixels)(int useMonitor, float* rect) = nullptr;

    // The full-frame tint and scanline layer is designed slightly narrower than the picture; at 16:9 the
    // picture's own borders hide that, at wider screens it leaves plain strips at the sides. A quad that
    // already spans most of the screen width and is centered gets stretched to the whole width; the
    // picture's black borders are drawn over it.
    SafetyHookInline shDrawScreenQuad = {};
    void __cdecl DrawScreenQuad(int index, char pass)
    {
        auto entry = pQuads + EntrySize * index;
        auto topLeft = reinterpret_cast<float*>(entry);
        auto topRight = reinterpret_cast<float*>(entry + TopRightOffset);
        auto bottomLeft = reinterpret_cast<float*>(entry + BottomLeftOffset);
        float scale = *reinterpret_cast<float*>(entry + ScaleOffset);

        if (entry[RelativeTypeOffset] == RelativeTypeScreen && scale > 0.0f &&
            std::fabs(topLeft[1] - topRight[1]) < 0.5f && std::fabs(topLeft[0] - bottomLeft[0]) < 0.5f)
        {
            float screen[4] = { 0.0f, 0.0f, 1.0f, 1.0f };
            NormalizedRectToViewportPixels(1, screen);
            float screenWidth = screen[2] - screen[0];
            float screenCenter = (screen[0] + screen[2]) * 0.5f;
            float quadCenter = (topLeft[0] + topRight[0]) * 0.5f;
            float quadWidth = (topRight[0] - topLeft[0]) * scale;

            if (screenWidth > 0.0f && quadWidth >= screenWidth * 0.9f && std::fabs(quadCenter - screenCenter) <= screenWidth * 0.05f)
            {
                float left = topLeft[0], right = topRight[0], bottom = bottomLeft[0];
                float halfWidth = screenWidth * 0.5f / scale;
                topLeft[0] = bottomLeft[0] = screenCenter - halfWidth;
                topRight[0] = screenCenter + halfWidth;
                shDrawScreenQuad.unsafe_ccall(index, pass);
                topLeft[0] = left;
                topRight[0] = right;
                bottomLeft[0] = bottom;
                return;
            }
        }

        shDrawScreenQuad.unsafe_ccall(index, pass);
    }
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

            // Cinematic camera overlays
            pattern = hook::pattern("83 EC 10 80 7C 24 14 00 0F 57 C0 F3 0F 11 04 24 F3 0F 11 44 24 0C 74");
            CinematicOverlay::NormalizedRectToViewportPixels = reinterpret_cast<decltype(CinematicOverlay::NormalizedRectToViewportPixels)>(pattern.get_first());

            pattern = hook::pattern("55 8B EC 83 E4 F0 8B 55 08 81 EC 74 05 00 00 80 BA ? ? ? ? 00 53 56 57 0F 84 ? ? ? ? 8D 34 D2 C1 E6 04 80 BE");
            CinematicOverlay::pQuads = *pattern.get_first<uint8_t*>(0x27) - 0x30; // the entry's active flag is at +0x30
            CinematicOverlay::shDrawScreenQuad = safetyhook::create_inline(pattern.get_first(), CinematicOverlay::DrawScreenQuad);

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
