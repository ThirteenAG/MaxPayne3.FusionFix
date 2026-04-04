module;

#include <common.hxx>
#include <filewatch.hpp>
#include <variant>

export module settings;

import common;
import comvars;

export enum Pref
{
    PREF_SKIPINTRO,
    PREF_HIDESKIP,
    PREF_DISABLELEADERBOARDS,
    PREF_SUBTITLESIZE,
    PREF_OUTLINESIZE,
    PREF_BORDERLESS,
    PREF_LEDILLUMINATION,
    PREF_BUTTONS,
    PREF_DEVICECHANGE,
    PREF_HUDASPECTRATIOCONSTRAINT,
    PREF_CUSTOMFOV,
    PREF_CONSOLEGAMMA,

    COUNT,
};

export class CSettings
{
private:
    static inline std::array<std::variant<int32_t, float, std::string>, static_cast<size_t>(Pref::COUNT)> mFusionPrefs;

public:
    static inline void ReadIniSettings()
    {
        CIniReader iniReader("");
        mFusionPrefs[PREF_SKIPINTRO] = std::clamp(iniReader.ReadInteger("MAIN", "SkipIntro", 1), 0, 1);
        mFusionPrefs[PREF_HIDESKIP] = std::clamp(iniReader.ReadInteger("MAIN", "HideSkipButton", 1), 0, 1);
        mFusionPrefs[PREF_DISABLELEADERBOARDS] = std::clamp(iniReader.ReadInteger("MAIN", "DisableGlobalLeaderboards", 1), 0, 1);
        mFusionPrefs[PREF_SUBTITLESIZE] = std::clamp(iniReader.ReadFloat("MAIN", "SubtitlesSizeMultiplier", 1.0f), 0.0f, 10.0f);
        mFusionPrefs[PREF_OUTLINESIZE] = std::clamp(iniReader.ReadFloat("MAIN", "OutlinesSizeMultiplier", 1.0f), 0.0f, 10.0f);
        mFusionPrefs[PREF_BORDERLESS] = std::clamp(iniReader.ReadInteger("MAIN", "BorderlessWindowed", 1), 0, 1);
        mFusionPrefs[PREF_LEDILLUMINATION] = std::clamp(iniReader.ReadInteger("MAIN", "LightSyncRGB", 1), 0, 1);
        mFusionPrefs[PREF_BUTTONS] = std::clamp(iniReader.ReadInteger("MAIN", "GamepadIcons", 0), 0, gLastControllerTextureIndex);
        mFusionPrefs[PREF_DEVICECHANGE] = std::clamp(iniReader.ReadInteger("MAIN", "DisableDeviceChangeEvent", 1), 0, 1);
        mFusionPrefs[PREF_HUDASPECTRATIOCONSTRAINT] = ParseWidescreenHudOffset(iniReader.ReadString("MAIN", "HudAspectRatioConstraint", "")).value_or(-1.0f);
        mFusionPrefs[PREF_CUSTOMFOV] = std::clamp(iniReader.ReadFloat("MAIN", "CustomFOV", 0.0f), 0.0f, 45.0f);
        mFusionPrefs[PREF_CONSOLEGAMMA] = std::clamp(iniReader.ReadInteger("MAIN", "ConsoleGamma", 0), 0, 1);

        static std::once_flag flag;
        std::call_once(flag, [&]()
        {
            if (std::filesystem::exists(iniReader.GetIniPath()))
            {
                static filewatch::FileWatch<std::string> watch(iniReader.GetIniPath().string(), [&](const std::string& path, const filewatch::Event change_type)
                {
                    if (change_type == filewatch::Event::modified)
                    {
                        ReadIniSettings();
                        FusionFix::onIniFileChange().executeAll();
                    }
                });
            }
        });
    }

    CSettings()
    {
        auto pattern = hook::pattern("FF 86 ? ? ? ? 0F B7 8E ? ? ? ? 8B 86 ? ? ? ? 3B C1 7C 0A");
        struct Inc
        {
            void operator()(injector::reg_pack& regs)
            {
                auto name = std::string_view((const char*)regs.esi + 0x4);
                auto oldVal = *(int32_t*)(regs.esi + 0xE4);
                *(int32_t*)(regs.esi + 0xE4) += 1;
                FusionFix::onMenuOptionChange().executeAll(name, oldVal, *(int32_t*)(regs.esi + 0xE4));
            }
        }; injector::MakeInline<Inc>(pattern.get_first(0), pattern.get_first(6));

        pattern = hook::pattern("FF 8E ? ? ? ? 8B 86 ? ? ? ? 8B 8E");
        struct Dec
        {
            void operator()(injector::reg_pack& regs)
            {
                auto name = std::string_view((const char*)regs.esi + 0x4);
                auto oldVal = *(int32_t*)(regs.esi + 0xE4);
                *(int32_t*)(regs.esi + 0xE4) -= 1;
                FusionFix::onMenuOptionChange().executeAll(name, oldVal, *(int32_t*)(regs.esi + 0xE4));
            }
        }; injector::MakeInline<Dec>(pattern.get_first(0), pattern.get_first(6));

        pattern = hook::pattern("C7 86 ? ? ? ? ? ? ? ? 8B 86 ? ? ? ? 8B 8E ? ? ? ? 8B 11");
        struct Zero
        {
            void operator()(injector::reg_pack& regs)
            {
                auto name = std::string_view((const char*)regs.esi + 0x4);
                auto oldVal = *(int32_t*)(regs.esi + 0xE4);
                *(int32_t*)(regs.esi + 0xE4) = 0;
                FusionFix::onMenuOptionChange().executeAll(name, oldVal, *(int32_t*)(regs.esi + 0xE4));
            }
        }; injector::MakeInline<Zero>(pattern.get_first(0), pattern.get_first(10));
    }

public:
    int32_t GetInt(Pref name) { return std::get<int32_t>(mFusionPrefs[name]); }
    float GetFloat(Pref name) { return std::get<float>(mFusionPrefs[name]); }
    std::string GetString(Pref name) { return std::get<std::string>(mFusionPrefs[name]); }
    void SetInt(Pref name, int32_t value) { mFusionPrefs[name] = value; }
    void SetFloat(Pref name, float value) { mFusionPrefs[name] = value; }
    void SetString(Pref name, std::string value) { mFusionPrefs[name] = value; }
} FusionFixSettings;