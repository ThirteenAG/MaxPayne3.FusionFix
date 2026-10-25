module;

#include <common.hxx>

export module cutsceneskip;

import common;
import comvars;
import natives;
import settings;

// Cutscenes are skipped with the game's own skip prompt and button.
//
// - Cutscenes the scripts let you skip: unchanged, the game jumps to the end and the scripts handle the skip.
// - Cutscenes the scripts don't let you skip (CUTSCENE_ENABLE_SKIP(FALSE), mostly scenes that hand over to an
//   interactive sequence, a blend-out camera or the next section): the skip moves the cutscene to a few seconds before
//   its end instead. The scripts' timed steps (requests for the next section, music, flags) run then, everything they
//   requested is loaded before the rest plays, and the cutscene ends normally, so the scripts take the path they were
//   made for.
// - Transition movies: the scripts make them skippable once the game has no streaming requests left; with the option,
//   that's the rule for every movie.
namespace CutsceneSkip
{
    // CutSceneManager (singleton)
    constexpr ptrdiff_t CutsceneState = 0x104;      // int, 8 = playing
    constexpr ptrdiff_t CutsceneActive = 0x130;     // byte, HAS_CUTSCENE_FINISHED = !active
    constexpr ptrdiff_t CutsceneTime = 0x13C;       // float, seconds from the start frame
    constexpr ptrdiff_t CutsceneStartFrame = 0x2D44;
    constexpr ptrdiff_t CutsceneEndFrame = 0x2D48;
    constexpr ptrdiff_t CutsceneSeekPending = 0x3508; // 0 = seek to CutsceneSeekFrame
    constexpr ptrdiff_t CutsceneSeekFrame = 0x3520;
    constexpr ptrdiff_t CutsceneSkippable = 0x39F8; // byte, CUTSCENE_ENABLE_SKIP
    // Movie player, slot 0 is the transition movie
    constexpr ptrdiff_t MovieSkippable = 0x62;      // byte, SET_TRANSITION_MOVIE_SKIPPABLE

    constexpr int CutsceneFps = 30;
    // How much of a script-locked cutscene still plays after a skip, in frames
    constexpr int LockedTailFrames = 3 * CutsceneFps;

    uint8_t** ppCutSceneManager = nullptr;
    uint8_t* pMoviePlayer = nullptr;

    // The game's helpers used by its own skip check
    void* (__cdecl* GetControls)(char) = nullptr;
    bool(__fastcall* IsSkipJustPressed)(void*) = nullptr;
    void* (__cdecl* GetCutsceneAudio)() = nullptr;
    void(__fastcall* AudioSkipSpeech)(void*, void*, float) = nullptr;
    void(__fastcall* AudioSkipStreams)(void*, void*, float) = nullptr;
    uint8_t* pMultiplayerFlags = nullptr;
    uint8_t* pFrontendActive = nullptr;

    // What the scripts asked for the current cutscene (the game resets it to skippable for every cutscene)
    bool scriptAllowsSkip = true;
    // A script-locked cutscene moved towards its end: load what the scripts request once they've seen the new time
    int lockedSkipFrame = -1;
    int lockedSkipWait = 0;

    struct NativeHandler
    {
        int32_t index;
        void(__cdecl* fun)(scrNativeCallContext*);
    };

    void(__cdecl* EnableSkipOriginal)(scrNativeCallContext*) = nullptr;

    bool Enabled()
    {
        return FusionFixSettings.GetInt(PREF_CUTSCENESKIP) != 0;
    }

    uint8_t* Manager()
    {
        return ppCutSceneManager ? *ppCutSceneManager : nullptr;
    }

    void __cdecl EnableSkipHook(scrNativeCallContext* context)
    {
        auto args = static_cast<int32_t*>(context->GetArgumentBuffer());
        auto requested = args[0];
        scriptAllowsSkip = requested != 0;
        if (!requested && Enabled())
        {
            args[0] = 1;
            EnableSkipOriginal(context);
            args[0] = requested;
            return;
        }
        EnableSkipOriginal(context);
    }

    // CutSceneManager's skip check, called every frame of a playing cutscene after its first second
    SafetyHookInline shSkipCheck;
    void __fastcall SkipCheck(uint8_t* manager)
    {
        if (!Enabled() || scriptAllowsSkip)
            return shSkipCheck.thiscall<void>(manager);

        if (!manager[CutsceneActive] || !manager[CutsceneSkippable])
            return;
        auto pressed = IsSkipJustPressed(GetControls(1));
        if ((pMultiplayerFlags[0] || pMultiplayerFlags[1]) && *pFrontendActive)
            pressed = false;
        if (!pressed)
            return;

        auto start = *reinterpret_cast<int32_t*>(manager + CutsceneStartFrame);
        auto end = *reinterpret_cast<int32_t*>(manager + CutsceneEndFrame);
        auto current = start + int32_t(*reinterpret_cast<float*>(manager + CutsceneTime) * CutsceneFps);
        auto target = end - LockedTailFrames;
        if (target <= current + CutsceneFps / 2)
            return;

        *reinterpret_cast<int32_t*>(manager + CutsceneSeekFrame) = target;
        *reinterpret_cast<int32_t*>(manager + CutsceneSeekPending) = 0;
        if (auto audio = *reinterpret_cast<void**>(reinterpret_cast<uint8_t*>(GetCutsceneAudio()) + 0x58))
        {
            AudioSkipSpeech(audio, nullptr, float(target) / CutsceneFps);
            AudioSkipStreams(audio, nullptr, float(target) / CutsceneFps);
        }
        lockedSkipFrame = target;
        lockedSkipWait = 0;
    }

    bool HookNative(uint32_t hash, void(__cdecl* hook)(scrNativeCallContext*), void(__cdecl*& original)(scrNativeCallContext*))
    {
        if (!getNativeAddress || !nativeHandlerPtrAddress)
            return false;
        auto handler = static_cast<NativeHandler*>(getNativeAddress(nativeHandlerPtrAddress, 0, hash));
        if (!handler || !handler->fun || handler->fun == hook)
            return false;
        original = handler->fun;
        handler->fun = hook;
        return true;
    }

    void Update()
    {
        auto manager = Manager();
        if (lockedSkipFrame >= 0 && manager)
        {
            auto start = *reinterpret_cast<int32_t*>(manager + CutsceneStartFrame);
            auto end = *reinterpret_cast<int32_t*>(manager + CutsceneEndFrame);
            auto frame = start + int32_t(*reinterpret_cast<float*>(manager + CutsceneTime) * CutsceneFps);
            if (!manager[CutsceneActive])
                lockedSkipFrame = -1;
            // The seek is done once the cutscene plays again at the new time; the scripts need a couple of frames to
            // see it and make their requests. What's still streaming in when the cutscene is about to end is loaded
            // then, as the rest of the cutscene would have given it time to.
            else if (*reinterpret_cast<int32_t*>(manager + CutsceneState) == 8 && frame >= lockedSkipFrame - 1)
            {
                ++lockedSkipWait;
                auto last = frame >= end - CutsceneFps / 2;
                if (lockedSkipWait == 3 || (last && Natives::GetNumberOfStreamingRequests() > 0))
                    Natives::LoadAllObjectsNow();
                if (last && lockedSkipWait > 3)
                    lockedSkipFrame = -1;
            }
        }

        if (Enabled() && pMoviePlayer && !pMoviePlayer[MovieSkippable] && Natives::IsTransitionMoviePlaying() &&
            Natives::GetNumberOfStreamingRequests() == 0)
            pMoviePlayer[MovieSkippable] = 1;
    }

    void Init()
    {
        auto pattern = find_pattern("83 3D ? ? ? ? 00 75 28 68 00 3A 00 00");
        if (!pattern.empty())
            ppCutSceneManager = *pattern.get_first<uint8_t**>(2);

        pattern = find_pattern("8B 44 24 04 50 6A 00 B9 ? ? ? ? E8 ? ? ? ? C3");
        if (!pattern.empty())
            pMoviePlayer = *pattern.get_first<uint8_t*>(8);

        // The game resets the skip flag to on for every cutscene
        pattern = find_pattern<2>("C6 86 F8 39 00 00 01");
        if (pattern.size() == 2)
        {
            static auto ResetHook1 = safetyhook::create_mid(pattern.get(0).get<void>(0), [](SafetyHookContext& regs) { scriptAllowsSkip = true; });
            static auto ResetHook2 = safetyhook::create_mid(pattern.get(1).get<void>(0), [](SafetyHookContext& regs) { scriptAllowsSkip = true; });
        }

        pattern = find_pattern("56 8B F1 E8 ? ? ? ? 84 C0 0F 84 ? ? ? ? 6A 01 E8 ? ? ? ? 83 C4 04 8B C8 E8 ? ? ? ? 8A 0D ? ? ? ? 0A 0D ? ? ? ? 74 0B 80 3D ? ? ? ? 00 74 02 32 C0 80 BE F8 39 00 00 00");
        if (ppCutSceneManager && !pattern.empty())
        {
            auto check = pattern.get_first<uint8_t>(0);
            GetControls = reinterpret_cast<decltype(GetControls)>(injector::GetBranchDestination(check + 0x12).as_int());
            IsSkipJustPressed = reinterpret_cast<decltype(IsSkipJustPressed)>(injector::GetBranchDestination(check + 0x1C).as_int());
            pMultiplayerFlags = *reinterpret_cast<uint8_t**>(check + 0x23);
            pFrontendActive = *reinterpret_cast<uint8_t**>(check + 0x31);
            GetCutsceneAudio = reinterpret_cast<decltype(GetCutsceneAudio)>(injector::GetBranchDestination(check + 0x6A).as_int());
            AudioSkipSpeech = reinterpret_cast<decltype(AudioSkipSpeech)>(injector::GetBranchDestination(check + 0x8A).as_int());
            AudioSkipStreams = reinterpret_cast<decltype(AudioSkipStreams)>(injector::GetBranchDestination(check + 0xA3).as_int());
            shSkipCheck = safetyhook::create_inline(check, SkipCheck);
        }

        FusionFix::onGameInitEvent() += []()
        {
            HookNative(std::to_underlying(Natives::NativeHashes::CUTSCENE_ENABLE_SKIP), EnableSkipHook, EnableSkipOriginal);
        };

        FusionFix::onGameProcessEvent() += []()
        {
            Update();
        };
    }
}

class CutsceneSkipFix
{
public:
    CutsceneSkipFix()
    {
        FusionFix::onInitEventAsync() += []()
        {
            // Hide skip button
            {
                auto pattern = hook::pattern("8B C8 89 86 ? ? ? ? E8 ? ? ? ? D9 EE 8B 86 ? ? ? ? 8B 38 83 EC ? D9 54 24 ? 8D 4C 24 ? D9 1C 24 E8 ? ? ? ? F3 0F 7E 00 8B 97 ? ? ? ? 83 EC ? 8B CC 66 0F D6 01 F3 0F 7E 40 ? 66 0F D6 41 ? F3 0F 7E 40 ? 6A ? 68 ? ? ? ? 66 0F D6 41 ? 8B 8E ? ? ? ? 6A ? FF D2 8D 4C 24 ? E8 ? ? ? ? 8B 8E");
                static raw_mem fnHideSkip1(pattern.count(2).get(0).get<void*>(8), { 0x90, 0x90, 0x90, 0x90, 0x90 }); // nop x5
                static raw_mem fnHideSkip2(pattern.count(2).get(1).get<void*>(8), { 0x90, 0x90, 0x90, 0x90, 0x90 }); // nop x5

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
        };

        FusionFix::onInitEvent() += []()
        {
            CutsceneSkip::Init();
        };
    }
} CutsceneSkipFix;
