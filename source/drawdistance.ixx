module;

#include <common.hxx>
#include <atomic>
#include <charconv>

export module drawdistance;

import common;
import settings;

namespace
{
    constexpr auto SettingId = "MAIN.DrawDistance";
    std::atomic<float> DrawDistanceScale{ 1.0f };

    void UpdateDrawDistanceScale()
    {
        static std::mutex mutex;
        std::lock_guard lock(mutex);
        const auto text = SettingsPlugin().Get(SettingId);
        float value{};
        const auto end = text.data() + text.size();
        const auto parsed = std::from_chars(text.data(), end, value);
        const bool valid = parsed.ec == std::errc{} && parsed.ptr == end && value >= 1.0f && value <= 2.0f;
        DrawDistanceScale.store(valid ? value : 1.0f, std::memory_order_relaxed);
    }

    void InitializeDrawDistance()
    {
        auto pattern = hook::pattern(
            "F3 0F 10 86 9C 09 00 00 0F 28 C8 F3 0F 59 0D ? ? ? ? F3 0F 11 8E D4 09 00 00 "
            "F3 0F 59 05 ? ? ? ? F3 0F 11 05 ? ? ? ? 80 7E 1E 00");

        static SafetyHookMid cameraLodHook;
        if (pattern.size() == 1)
        {
            // Scale the camera's LOD factor before it goes to both the view and the global used by model LOD and culling.
            cameraLodHook = safetyhook::create_mid(pattern.get_first(8), [](SafetyHookContext& context)
            {
                const auto scale = DrawDistanceScale.load(std::memory_order_relaxed);
                if (scale != 1.0f)
                    context.xmm0.f32[0] *= scale;
            });
        }

        if (!cameraLodHook)
        {
            SettingsPlugin().Availability(SettingId, [](std::string_view) { return false; });
            return;
        }

        SettingsPlugin().OnChange(SettingId, UpdateDrawDistanceScale);
        UpdateDrawDistanceScale();
    }

    struct DrawDistanceInit
    {
        DrawDistanceInit()
        {
            FusionFix::onInitEvent() += InitializeDrawDistance;
        }
    } DrawDistanceInitInstance;
}
