module;

#include <common.hxx>

export module drawdistance;

import common;
import settings;

// The camera update takes the LOD factor of the camera and stores it, scaled, in the view and in the global that model
// LOD and culling distances are multiplied by. Scaling it there moves both together.
class DrawDistance
{
public:
    DrawDistance()
    {
        FusionFix::onInitEvent() += []()
        {
            auto pattern = hook::pattern("F3 0F 10 86 9C 09 00 00 0F 28 C8 F3 0F 59 0D ? ? ? ? F3 0F 11 8E D4 09 00 00 F3 0F 59 05 ? ? ? ? F3 0F 11 05 ? ? ? ? 80 7E 1E 00");
            static auto LodFactor = safetyhook::create_mid(pattern.get_first(8), [](SafetyHookContext& regs)
            {
                regs.xmm0.f32[0] *= FusionFixSettings.GetFloat(PREF_DRAWDISTANCE);
            });
        };
    }
} DrawDistance;
