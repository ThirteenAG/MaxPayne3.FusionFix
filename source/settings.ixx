module;

#include <common.hxx>
#include <atomic>
#include <cmath>
#include <asi_settings/asi_settings.hpp>

export module settings;

import common;
import comvars;

export enum Pref
{
    PREF_SKIPINTRO, PREF_HIDESKIP, PREF_DISABLELEADERBOARDS, PREF_SUBTITLESIZE,
    PREF_OUTLINESIZE, PREF_BORDERLESS, PREF_LEDILLUMINATION, PREF_BUTTONS,
    PREF_DEVICECHANGE, PREF_HUDASPECTRATIOCONSTRAINT, PREF_CUSTOMFOV,
    PREF_CONSOLEGAMMA, PREF_ANTIALIASING, PREF_AASHARPNESS,
    PREF_SKIPINTELVENDORCHECKS, PREF_CONFINECURSOR, PREF_CUTSCENESKIP, PREF_UNLOCKSPRINTLOOK, COUNT,
};

// The settings are described in settings/MaxPayne3.FusionFix.json, which the build embeds
// as a resource together with its translations (see docs/settings.md). asi_settings::Plugin
// takes the defaults from it, reads and writes MaxPayne3.FusionFix.cfg next to the plugin,
// and answers menu hosts and editors through the AsiSettings_GetApi export below.
export asi_settings::Plugin& SettingsPlugin()
{
    static asi_settings::Plugin plugin;
    return plugin;
}

ASI_SETTINGS_EXPORT(SettingsPlugin())

export class CSettings
{
    static inline const std::array<const char*, COUNT> ids = {
        "MAIN.SkipIntro", "MAIN.HideSkipButton", "MAIN.DisableGlobalLeaderboards", "MAIN.SubtitlesSizeMultiplier",
        "MAIN.OutlinesSizeMultiplier", "MAIN.BorderlessWindowed", "MAIN.LightSyncRGB", "MAIN.GamepadIcons",
        "MAIN.DisableDeviceChangeEvent", "MAIN.HudAspectRatioConstraint", "MAIN.CustomFOV",
        "MAIN.ConsoleGamma", "MAIN.AntiAliasing", "MAIN.AntiAliasingSharpness",
        "MAIN.SkipIntelVendorChecks", "MAIN.ConfineCursor", "MAIN.CutsceneSkip", "MAIN.UnlockSprintLook",
    };
    // References into the plugin's values, which follow every change from menus and editors
    static inline std::array<const int*, COUNT> ints{};
    static inline std::array<const float*, COUNT> floats{};
    // The HUD aspect ratio is text in the file ("Auto", "16:9", "1.78"); the code uses
    // the ratio, -1 for Auto.
    static inline std::atomic<float> hudAspectRatio = -1.0f;
    static inline std::atomic<bool> changed = false;

    static void UpdateHudAspectRatio()
    {
        auto ratio = ParseWidescreenHudOffset(SettingsPlugin().String(ids[PREF_HUDASPECTRATIOCONSTRAINT]));
        hudAspectRatio = ratio && std::isfinite(*ratio) && *ratio > 0 ? *ratio : -1.0f;
    }

    // Changes may come from any thread (an editor asking for a reload, another menu host).
    // The feature callbacks apply window styles, controller textures and RGB, so they
    // run on the game thread, once per frame at most.
    static void ApplyChanges()
    {
        if (changed.exchange(false))
            FusionFix::onIniFileChange().executeAll();
    }

public:
    static void Load()
    {
        auto& plugin = SettingsPlugin();
        if (!plugin.Load())
            OutputDebugStringA(("Fusion Fix: settings unavailable, " + plugin.Error() + ".\n").c_str());
        for (size_t i = 0; i < ids.size(); ++i)
        {
            auto setting = plugin.GetDescription().Find(ids[i]);
            if (setting && setting->type == asi_settings::Type::Float)
                floats[i] = &plugin.Float(ids[i]);
            else
                ints[i] = &plugin.Int(ids[i]);
            plugin.OnChange(ids[i], [] { changed = true; });
        }
        UpdateHudAspectRatio();
        plugin.OnChange(ids[PREF_HUDASPECTRATIOCONSTRAINT], UpdateHudAspectRatio);
        FusionFix::onGameProcessEvent() += ApplyChanges;
        FusionFix::onMenuDrawingEvent() += ApplyChanges;
        // FusionFixHub changes the values while the game runs (the live link, served for all plugins of the game)
        asi_settings::LiveLink::Start();
    }

    // Whether the last write of MaxPayne3.FusionFix.cfg worked. Where the plugin's folder can't be written, the plugin
    // writes to its fallback in %LOCALAPPDATA%\FusionFixHub, so this fails only when neither can be written.
    static bool CanSave()
    {
        return !SettingsPlugin().SaveFailed();
    }

    static int32_t GetInt(Pref name) { return ints.at(name) ? *ints[name] : 0; }
    static float GetFloat(Pref name)
    {
        if (name == PREF_HUDASPECTRATIOCONSTRAINT) return hudAspectRatio;
        return floats.at(name) ? *floats[name] : 0.0f;
    }
} FusionFixSettings;
