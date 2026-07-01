module;

#include <common.hxx>

export module cutsceneskip;

import common;
import natives;

std::string szLastCutsceneName;

class CutsceneSkip
{
public:
    CutsceneSkip()
    {
        //FusionFix::onInitEvent() += []()
        //{
        //    auto pattern = hook::pattern("C7 86 ? ? ? ? ? ? ? ? C7 86 ? ? ? ? ? ? ? ? 75");
        //    static auto cutsManagerHook = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
        //    {
        //        szLastCutsceneName = (const char*)(regs.esi + 0x2DD8);
        //
        //        std::ofstream file("cutscene_log.txt", std::ios::app);
        //        if (file.is_open())
        //            file << szLastCutsceneName << "\n";
        //    });
        //};
        //
        //FusionFix::onGameProcessEvent() += []()
        //{
        //    auto bTransitionMoviePlaying = Natives::IsTransitionMoviePlaying();
        //    Natives::SetTransitionMovieSkippable(bTransitionMoviePlaying);
        //
        //    auto bCutsceneFinished = Natives::HasCutsceneFinished();
        //    Natives::CutsceneEnableSkip(!bCutsceneFinished);
        //};
    }
} CutsceneSkip;