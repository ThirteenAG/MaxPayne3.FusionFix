module;

#include <common.hxx>

export module sprintlook;

import common;
import comvars;
import natives;
import settings;

// Sprinting switches the gameplay camera to SPRINT_AIM_CAMERA, whose metadata limits the pitch to 5 degrees up and
// down, and while the sprint camera is active the orientation update also pulls the view towards the horizon every
// frame (the vertical part of the look direction is scaled down by up to 20% per frame, so the pull gets stronger
// with the frame rate). With the option on, the sprint camera keeps the pitch limits of the camera used before it
// and the pull is off.
class SprintLook
{
    static constexpr uint32_t SPRINT_AIM_CAMERA = 0xCFAE9BEA;

    static inline float originalPull = 0.2f;
    static inline float lastMinPitch = 0.0f;
    static inline float lastMaxPitch = 0.0f;
    static inline bool haveLast = false;
    static inline SafetyHookInline shCreateCamera;

    static uint8_t* __cdecl CreateCamera(uint32_t name)
    {
        auto camera = shCreateCamera.ccall<uint8_t*>(name);
        if (!camera)
            return camera;
        // Metadata types 7 to 10 and 13 make a camThirdPersonPedAim
        auto metadata = *reinterpret_cast<uint8_t**>(camera + 0x120);
        auto type = metadata ? *metadata : 0;
        if (type < 7 || (type > 10 && type != 13))
            return camera;
        auto& minPitch = *reinterpret_cast<float*>(camera + 0x180);
        auto& maxPitch = *reinterpret_cast<float*>(camera + 0x184);
        if (name != SPRINT_AIM_CAMERA)
        {
            lastMinPitch = minPitch;
            lastMaxPitch = maxPitch;
            haveLast = true;
        }
        else if (haveLast && FusionFixSettings.GetInt(PREF_UNLOCKSPRINTLOOK))
        {
            minPitch = std::min(minPitch, lastMinPitch);
            maxPitch = std::max(maxPitch, lastMaxPitch);
        }
        return camera;
    }

public:
    SprintLook()
    {
        FusionFix::onInitEvent() += []()
        {
            // The camera factory (by name hash): the third-person aim cameras read their pitch limits from the metadata
            // in the constructor, radians at +0x180 and +0x184; the name is set after the constructor
            auto pattern = find_pattern("A1 ? ? ? ? 8B 48 08 2B 48 14 85 C9 7F 03 33 C0 C3 53 8B 5C 24 08 57");
            if (!pattern.empty())
                shCreateCamera = safetyhook::create_inline(pattern.get_first(0), CreateCamera);

            // The pull factor (0.2) is a global only this multiply reads
            static ProtectedGameRef<float> sprintPitchPull([]() -> float*
            {
                auto pattern = find_pattern("F3 0F 5E E9 F3 0F 59 2D ? ? ? ? F3 0F 10 0D ? ? ? ? F3 0F 5C CD");
                if (!pattern.empty())
                    return *pattern.get_first<float*>(8);
                return nullptr;
            });

            if (!sprintPitchPull.get_ptr())
                return;
            originalPull = sprintPitchPull;

            static auto Apply = []()
            {
                sprintPitchPull = FusionFixSettings.GetInt(PREF_UNLOCKSPRINTLOOK) ? 0.0f : originalPull;
            };

            Apply();

            FusionFix::onIniFileChange() += []()
            {
                Apply();
            };
        };
    }
} SprintLook;
