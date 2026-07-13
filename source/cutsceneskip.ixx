module;

#include <common.hxx>

export module cutsceneskip;

import common;
import natives;
import settings;

std::string szLastCutsceneName;

class CutsceneSkip
{
public:
    CutsceneSkip()
    {
        FusionFix::onInitEventAsync() += []()
        {
            // Hide skip button
            {
                auto pattern = hook::pattern("8B C8 89 86 ? ? ? ? E8 ? ? ? ? D9 EE 8B 86 ? ? ? ? 8B 38 83 EC ? D9 54 24 ? 8D 4C 24 ? D9 1C 24 E8 ? ? ? ? F3 0F 7E 00 8B 97 ? ? ? ? 83 EC ? 8B CC 66 0F D6 01 F3 0F 7E 40 ? 66 0F D6 41 ? F3 0F 7E 40 ? 6A ? 68 ? ? ? ? 66 0F D6 41 ? 8B 8E ? ? ? ? 6A ? FF D2 8D 4C 24 ? E8 ? ? ? ? 8B 8E");
                static raw_mem fnHideSkip1(pattern.count(2).get(0).get<void*>(8), {0x90, 0x90, 0x90, 0x90, 0x90}); // nop x5
                static raw_mem fnHideSkip2(pattern.count(2).get(1).get<void*>(8), {0x90, 0x90, 0x90, 0x90, 0x90}); // nop x5

                static auto HideSkipCB = []()
                {
                    if (FusionFixSettings.GetInt(PREF_HIDESKIP))
                    {
                        fnHideSkip1.Write();
                        fnHideSkip2.Write();
                    }
                    else
                    {
                        fnHideSkip1.Restore();
                        fnHideSkip2.Restore();
                    }
                };

                HideSkipCB();

                FusionFix::onIniFileChange() += []()
                {
                    HideSkipCB();
                };
            }
            
            // TODO: Cook a list of safe cutscene names to skip
            /*auto pattern = hook::pattern("C7 86 ? ? ? ? ? ? ? ? C7 86 ? ? ? ? ? ? ? ? 75");
            static auto CutsManagerHook = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
            {
                szLastCutsceneName = (const char*)(regs.esi + 0x2DD8);
        
                std::ofstream file("cutscene_log.txt", std::ios::app);
                if (file.is_open())
                    file << szLastCutsceneName << "\n";
            });*/
        };
        
        // TODO: For this, a lot probably
        /*FusionFix::onGameProcessEvent() += []()
        {
            auto bTransitionMoviePlaying = Natives::IsTransitionMoviePlaying();
            Natives::SetTransitionMovieSkippable(bTransitionMoviePlaying);
        
            auto bCutsceneFinished = Natives::HasCutsceneFinished();
            Natives::CutsceneEnableSkip(!bCutsceneFinished);
        };*/
    }
} CutsceneSkip;