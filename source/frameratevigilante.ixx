module;

#include <common.hxx>
#include <cmath>

export module frameratevigilante;

import common;
import comvars;

// The camera's blend into and out of ragdoll (shootdodge landings) moves a fixed share of the remaining distance per
// frame, tuned for 30 fps. Scaled to the camera time step, the remaining distance after dt seconds is
// (1 - blend)^(30 * dt) at any frame rate and in bullet time.
namespace LandingCamera
{
    float* fCameraTimeStep = nullptr;
    int32_t nBlendRateOffset = 0;

    void UpdateBlend(SafetyHookContext& regs)
    {
        auto blend = *reinterpret_cast<float*>(regs.ecx + nBlendRateOffset);
        auto weight = 1.0f - std::pow(1.0f - blend, 30.0f * *fCameraTimeStep);

        // xmm0 = (1.0 - current) * blend, xmm3 = current
        regs.xmm0.f32[0] = (1.0f - regs.xmm3.f32[0]) * weight;
    }
}

namespace CWater
{
    SafetyHookInline shAddToDynamicWaterSpeed = {};
    void __cdecl AddToDynamicWaterSpeed(int a1, int a2, float a3)
    {
        return shAddToDynamicWaterSpeed.unsafe_ccall(a1, a2, a3 * (CTimer::fTimeStep / (1.0f / 30.0f)));
    }

    SafetyHookInline shModifyDynamicWaterSpeed = {};
    void __cdecl ModifyDynamicWaterSpeed(int a1, int a2, float a3, float a4)
    {
        return shModifyDynamicWaterSpeed.unsafe_ccall(a1, a2, a3, a4 * (CTimer::fTimeStep / (1.0f / 30.0f)));
    }
}

class FramerateVigilante
{
public:
	FramerateVigilante()
	{
		FusionFix::onInitEventAsync() += []()
		{
            // Ragdoll camera blend
            {
                auto pattern = hook::pattern("F3 0F 10 05 ? ? ? ? 0F 57 DB F3 0F 59 C1 F3 0F 59 05 ? ? ? ? 0F 2F D8 77 ? F3 0F 10 1D");
                LandingCamera::fCameraTimeStep = *pattern.get_first<float*>(4);

                pattern = hook::pattern("F3 0F 5C C3 F3 0F 59 81 ? ? ? ? 5F F3 0F 58 C3 F3 0F 11 05 ? ? ? ? 5E 8B E5 5D C2 04 00");
                LandingCamera::nBlendRateOffset = *pattern.get_first<int32_t>(8);
                static auto LandingBlendHook = safetyhook::create_mid(pattern.get_first(12), LandingCamera::UpdateBlend);
            }

            // Fix water physics and effects
            {
                // Helicopter downwash force
                auto pattern = hook::pattern("8B 44 24 ? 99 2B C2 D1 F8 05 ? ? ? ? 8B C8 81 E1 ? ? ? ? 79 ? 49 83 C9 ? 41 8B 44 24 ? 99 2B C2 D1 F8 05 ? ? ? ? 25 ? ? ? ? 79 ? 48 83 C8 ? 40 F3 0F 10 0D");
                CWater::shAddToDynamicWaterSpeed = safetyhook::create_inline(pattern.get_first(0), CWater::AddToDynamicWaterSpeed);

                // Buoyancy (Affects everything floating on any body of water that is flagged as physical)
                // First pattern: 1.0.0.255; second: 1.0.0.216 and 1.0.0.276
                pattern = find_pattern("8B 44 24 ? 99 2B C2 D1 F8 05 ? ? ? ? 8B C8 81 E1 ? ? ? ? 79 ? 49 83 C9 ? 41 8B 44 24 ? 99 2B C2 D1 F8 05 ? ? ? ? 25 ? ? ? ? 79 ? 48 83 C8 ? 40 0F 57 C0",
                                       "8B 44 24 ? 99 2B C2 D1 F8 05 ? ? ? ? 8B C8 81 E1 ? ? ? ? 79 ? 49 83 C9 ? 41 8B 44 24 ? 99 2B C2 D1 F8 05 ? ? ? ? 25 ? ? ? ? 79 ? 48 83 C8 ? 40 0F 57 C9");
                CWater::shModifyDynamicWaterSpeed = safetyhook::create_inline(pattern.get_first(0), CWater::ModifyDynamicWaterSpeed);

                // Helicopter downwash wind particles
                pattern = hook::pattern("F7 F1 85 D2 75 ? D9 EE");
                static auto CVehicleFx__UpdateFxHeliDownwash_Hook = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
                {
                    float f = std::min(CTimer::fTimeStep / (1.0f / 30.0f), 1.0f);

                    regs.ecx = std::max((int)((float)regs.ecx / f), 1);
                });

                // Boat ripple particles
                pattern = hook::pattern("F7 F6 85 D2");
                static auto CWaterFx__RegisterWakePoint_Hook = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
                {
                    float f = std::min(CTimer::fTimeStep / (1.0f / 30.0f), 1.0f);

                    regs.esi = std::max((int)((float)regs.esi / f), 1);
                });

                // Swim ripple particles
                pattern = hook::pattern("F7 F1 85 D2 0F 85 ? ? ? ? 8B 55");
                static auto CBuoyancy__ProcessSplashVfx_Hook = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
                {
                    float f = std::min(CTimer::fTimeStep / (1.0f / 30.0f), 1.0f);

                    regs.ecx = std::max((int)((float)regs.ecx / f), 1);
                });
            }
		};
	}
} FramerateVigilante;
