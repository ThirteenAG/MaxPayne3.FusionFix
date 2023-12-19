module;

#include <common.hxx>
#include <filewatch.hpp>
#include <variant>

export module settings;

import common;
import comvars;



export class CSettings
{
private:
    static inline std::map<std::string_view, std::variant<int32_t, float, std::string>> mFusionPrefs;

public:
    static inline void ReadIniSettings()
    {
        CIniReader iniReader("");
        mFusionPrefs["PREF_HIDESKIP"] = std::clamp(iniReader.ReadInteger("MAIN", "HideSkipButton", 1), 0, 1);
        mFusionPrefs["PREF_DISABLELEADERBOARDS"] = std::clamp(iniReader.ReadInteger("MAIN", "DisableGlobalLeaderboards", 1), 0, 1);
        mFusionPrefs["PREF_OUTLINESIZE"] = std::clamp(iniReader.ReadFloat("MAIN", "OutlinesSizeMultiplier", 1.0f), 0.0f, 10.0f);
        mFusionPrefs["PREF_BORDERLESS"] = std::clamp(iniReader.ReadInteger("MAIN", "BorderlessWindowed", 1), 0, 1);
        mFusionPrefs["PREF_BUTTONS"] = std::clamp(iniReader.ReadInteger("MAIN", "GamepadIcons", 0), 0, 6);

        static std::once_flag flag;
        std::call_once(flag, [&]()
        {
            if (std::filesystem::exists(iniReader.GetIniPath()))
            {
                static filewatch::FileWatch<std::string> watch(iniReader.GetIniPath(), [&](const std::string& path, const filewatch::Event change_type)
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
    int32_t GetInt(std::string_view name) { return std::get<int32_t>(mFusionPrefs[name]); }
    float GetFloat(std::string_view name) { return std::get<float>(mFusionPrefs[name]); }
    std::string GetString(std::string_view name) { return std::get<std::string>(mFusionPrefs[name]); }
    void SetInt(std::string_view name, int32_t value) { mFusionPrefs[name] = value;  }
} FusionFixSettings;