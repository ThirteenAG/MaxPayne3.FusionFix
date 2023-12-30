module;

#include <common.hxx>
#include <string>

export module buttons;

import common;
import comvars;
import settings;

class Buttons
{
private:
    static inline std::vector<std::string> btnPrefix = {
        "", //XBOX360
        "XBONE_",
        "PS3_",
        "PS4_",
        "PS5_",
        "SWITCH_",
        "SD_",
        "SC_",
    };

    static inline std::vector<std::string> buttons = {
        "UP_ARROW", "", "", "DOWN_ARROW", "", "", "LEFT_ARROW", "", "", "RIGHT_ARROW", "", "", "DPAD_UP", "", "",
        "DPAD_DOWN", "", "", "DPAD_LEFT", "", "", "DPAD_RIGHT", "", "", "DPAD_NONE", "", "", "DPAD_ALL", "", "",
        "DPAD_UPDOWN", "", "", "DPAD_LEFTRIGHT", "", "", "LSTICK_UP", "", "", "LSTICK_DOWN", "", "", "LSTICK_LEFT",
        "", "", "LSTICK_RIGHT", "", "", "LSTICK_NONE", "", "", "LSTICK_ALL", "", "", "LSTICK_UPDOWN", "", "",
        "LSTICK_LEFTRIGHT", "", "", "RSTICK_UP", "", "", "RSTICK_DOWN", "", "", "RSTICK_LEFT", "", "", "RSTICK_RIGHT",
        "", "", "RSTICK_NONE", "", "", "RSTICK_ALL", "", "", "RSTICK_UPDOWN", "", "", "RSTICK_LEFTRIGHT", "", "", "A_BUTT",
        "", "", "B_BUTT", "", "", "X_BUTT", "", "", "Y_BUTT", "", "", "LB_BUTT", "", "", "LT_BUTT", "", "", "RB_BUTT", "",
        "", "RT_BUTT", "", "", "START_BUTT", "", "", "BACK_BUTT", "", "", "A_BUTT", "", "", "B_BUTT"
    };

    static inline std::vector<void*> controllerTexPtrs;
    static inline std::vector<uint32_t> controllerTexHashes;
    static inline std::vector<std::vector<void*>> buttonTexPtrs;
    static inline void** gameButtonPtrs = nullptr;
    static inline void** gameControllerPtrs = nullptr;
    static inline void** controllerDstTexPtr = nullptr;
    static void ButtonsCallback()
    {
        auto prefvalueindex = FusionFixSettings.GetInt("PREF_BUTTONS");
        if (gameButtonPtrs)
        {
            for (auto b = buttons.begin(); b < buttons.end(); b++)
            {
                if (!b->empty())
                {
                    auto i = std::distance(std::begin(buttons), b);
                    auto ptr = buttonTexPtrs[prefvalueindex][i];
                    if (ptr)
                        gameButtonPtrs[i] = ptr;
                }
            }
        }
    }

    static inline injector::hook_back<void(__fastcall*)(void*, void*, const char*)> CTxdStore__LoadTexture;
    static void __fastcall LoadCustomButtons(void* dst, void* edx, const char* name)
    {
        CTxdStore__LoadTexture.fun(dst, edx, name);

        buttonTexPtrs.clear();
        buttonTexPtrs.resize(btnPrefix.size());

        for (auto& v : buttonTexPtrs)
            v.resize(buttons.size());

        for (auto prefix = btnPrefix.begin(); prefix < btnPrefix.end(); prefix++)
        {
            for (auto b = buttons.begin(); b < buttons.end(); b++)
            {
                if (!b->empty())
                {
                    auto texName = *prefix + *b;
                    CTxdStore__LoadTexture.fun(&buttonTexPtrs[std::distance(std::begin(btnPrefix), prefix)][std::distance(std::begin(buttons), b)], edx, texName.c_str());
                }
            }
        }

        ButtonsCallback();
    }

    static inline bool bIsController = false;
    static inline injector::hook_back<uint32_t(__cdecl*)(const char*, int)> hbsub_DCFB30;
    static uint32_t __cdecl sub_DCFB30(const char* name, int a2)
    {
        if (iequals(std::string(name), "controller"))
        {
            bIsController = true;

            controllerTexHashes.clear();
            controllerTexHashes.resize(btnPrefix.size());
            controllerTexPtrs.clear();
            controllerTexPtrs.resize(btnPrefix.size());

            for (auto prefix = btnPrefix.begin(); prefix < btnPrefix.end(); prefix++)
            {
                auto texName = *prefix + "CONTROLLER";
                controllerTexHashes[std::distance(std::begin(btnPrefix), prefix)] = hbsub_DCFB30.fun(texName.c_str(), a2);
            }
        }
        return hbsub_DCFB30.fun(name, a2);
    }

    static inline injector::hook_back<void* (__fastcall*)(void*, void*, uint32_t)> hbsub_CE8060;
    static void* __fastcall sub_CE8060(void* _this, void* edx, uint32_t hash)
    {
        if (bIsController)
        {
            for (auto prefix = btnPrefix.begin(); prefix < btnPrefix.end(); prefix++)
            {
                auto texName = *prefix + "CONTROLLER";
                controllerTexPtrs[std::distance(std::begin(btnPrefix), prefix)] = hbsub_CE8060.fun(_this, edx, controllerTexHashes[std::distance(std::begin(btnPrefix), prefix)]);
            }
        }
        return hbsub_CE8060.fun(_this, edx, hash);
    }

public:
    Buttons()
    {
        FusionFix::onInitEvent() += []()
        {
            assert(gLastControllerTextureIndex == (btnPrefix.size() - 1));

            auto pattern = hook::pattern("B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? B9");
            gameButtonPtrs = *pattern.get_first<void**>(1);

            pattern = hook::pattern("E8 ? ? ? ? 83 C4 08 EB 02 33 C0 8B 4C 24 08 8B 16");
            hbsub_DCFB30.fun = injector::MakeCALL(pattern.get_first(0), sub_DCFB30).get();

            pattern = hook::pattern("E8 ? ? ? ? 89 86 ? ? ? ? 85 C0 74 1B");
            hbsub_CE8060.fun = injector::MakeCALL(pattern.get_first(0), sub_CE8060).get();

            pattern = hook::pattern("E8 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? C6 05 ? ? ? ? ? 5E");
            CTxdStore__LoadTexture.fun = injector::MakeCALL(pattern.get_first(), LoadCustomButtons).get();

            pattern = hook::pattern("89 86 ? ? ? ? 85 C0 74 1B");
            struct LoadControllerTexture
            {
                void operator()(injector::reg_pack& regs)
                {
                    *(uint32_t*)(regs.esi + 0x104) = regs.eax;
                    if (bIsController)
                    {
                        controllerDstTexPtr = (void**)(regs.esi + 0x104);
                        auto v = FusionFixSettings.GetInt("PREF_BUTTONS");
                        if (v > gLastControllerTextureIndex) v = 0; else if (v < 0) v = gLastControllerTextureIndex;
                        if (controllerTexPtrs[v])
                            *controllerDstTexPtr = controllerTexPtrs[v];
                    }
                    bIsController = false;
                }
            }; injector::MakeInline<LoadControllerTexture>(pattern.get_first(0), pattern.get_first(6));

            FusionFix::onIniFileChange() += []()
            {
                ButtonsCallback();
            };

            FusionFix::onMenuOptionChange() += [](std::string_view name, int32_t oldVal, int32_t curVal)
            {
                if (name == "MS_Control.ConfigurationList")
                {
                    if (oldVal == 3 && curVal == 4)
                    {
                        auto v = FusionFixSettings.GetInt("PREF_BUTTONS") + 1;
                        if (v > gLastControllerTextureIndex) v = 0; else if (v < 0) v = gLastControllerTextureIndex;

                        CIniReader iniWriter("");
                        iniWriter.WriteInteger("MAIN", "GamepadIcons", v);
                        if (controllerDstTexPtr && controllerTexPtrs[v])
                            *controllerDstTexPtr = controllerTexPtrs[v];
                    }
                    else if (oldVal == 4 && curVal == 3)
                    {
                        auto v = FusionFixSettings.GetInt("PREF_BUTTONS") - 1;
                        if (v > gLastControllerTextureIndex) v = 0; else if (v < 0) v = gLastControllerTextureIndex;

                        CIniReader iniWriter("");
                        iniWriter.WriteInteger("MAIN", "GamepadIcons", v);
                        if (controllerDstTexPtr && controllerTexPtrs[v])
                            *controllerDstTexPtr = controllerTexPtrs[v];
                    }
                }
            };
        };
    }
} Buttons;