module;

#include <common.hxx>
#include "garagepanel.h"
#include <format>

export module fixes;

import common;
import settings;

namespace BusDepotStreaming
{
    struct StreamEntry
    {
        uint32_t fileHandle;
        uint32_t state;
        uint32_t moduleData;
    };

    struct StreamCatalog
    {
        StreamEntry* entries;
        uint32_t count;
    };

    struct ReadRetry
    {
        uint16_t assetId = 0xFFFF;
        ULONGLONG retryAt = 0;
    };

    constexpr unsigned OutroAssetId = 256;
    constexpr uint32_t OutroFileHandle = 0x00A900E8;
    constexpr uint32_t PriorityRequest = 0x04;
    constexpr uint32_t ListRetention = 0x20;
    constexpr uint32_t Retained = ListRetention << 15;
    constexpr uint8_t ListActive = 2;
    constexpr ULONGLONG RetryDelayMs = 100;
    constexpr ULONGLONG PreloadTimeoutMs = 2000;

    using RequestAsset = uint8_t (__thiscall*)(StreamCatalog*, unsigned, uint32_t);
    using ReleaseAsset = int (__thiscall*)(StreamCatalog*, unsigned, uint32_t);
    StreamCatalog* catalog = nullptr;
    RequestAsset requestAsset = nullptr;
    ReleaseAsset releaseAsset = nullptr;

    const uint8_t* preloadList = nullptr;
    StreamEntry* heldEntries = nullptr;
    ULONGLONG preloadStarted = 0;
    bool preloadPending = false;
    bool releasePending = false;
    bool preloadFailed = false;

    const uint8_t* outroList = nullptr;
    std::array<ReadRetry, 16> readRetries{};

    bool IsOutroActive()
    {
        return outroList && (outroList[0] & ListActive);
    }

    void OnListOpened(const char* path, const uint8_t* list)
    {
        constexpr char Prefix[] = "common:/data/streaming/";
        bool otherChapter = false;
        if (_strnicmp(path, Prefix, sizeof(Prefix) - 1) == 0)
        {
            const auto name = path + sizeof(Prefix) - 1;
            const auto numbered = name[0] >= '0' && name[0] <= '9'
                && name[1] >= '0' && name[1] <= '9' && name[2] == '_';
            otherChapter = numbered && (name[0] != '1' || name[1] != '0');
        }
        if (heldEntries && (otherChapter || outroList))
            releasePending = true;

        preloadPending = _stricmp(path, "common:/data/streaming/10_01_bus_concat.srl") == 0
            || _stricmp(path, "common:/data/streaming/10_02_bus_concat.srl") == 0;
        preloadList = preloadPending ? list : nullptr;
        outroList = _stricmp(path, "common:/data/streaming/10_05_bus_concat.srl") == 0 ? list : nullptr;
        readRetries.fill({});
    }

    void UpdatePreload()
    {
        const auto canPreload = preloadPending && preloadList && (preloadList[0] & ListActive);
        if (!heldEntries && !canPreload)
            return;

        const auto entries = catalog->entries;
        const auto valid = entries && catalog->count > OutroAssetId && entries[OutroAssetId].fileHandle == OutroFileHandle;
        if (heldEntries)
        {
            if (!valid || heldEntries != entries || (entries[OutroAssetId].state & Retained) == 0)
            {
                heldEntries = nullptr;
                return;
            }

            const auto resident = (entries[OutroAssetId].state & 3u) == 1u;
            const auto timedOut = !resident && GetTickCount64() - preloadStarted > PreloadTimeoutMs;
            if (preloadFailed || releasePending || timedOut || (outroList && !IsOutroActive()))
            {
                releaseAsset(catalog, OutroAssetId, ListRetention);
                heldEntries = nullptr;
            }
            return;
        }

        preloadPending = false;
        if (!valid || (entries[OutroAssetId].state & (Retained | 3u)) != 0)
            return;

        // The outro resource requires 8 MiB blocks in the streaming heap. Load it
        // in one of the opening scenes, before the heap becomes fragmented.
        if (requestAsset(catalog, OutroAssetId, ListRetention | PriorityRequest))
        {
            heldEntries = entries;
            preloadStarted = GetTickCount64();
            preloadFailed = false;
            releasePending = false;
        }
    }

    void InitReadRetries()
    {
        auto failedRead = hook::pattern("56 8B CF E8 BE FA FF FF 5F 5E 5D 32 C0 5B 83 C4 08 C2 04 00");
        auto chooseAsset = hook::pattern("89 4C 24 30 89 44 24 1C 74 18 83 BB BC 00 00 00 00 74 0F 8B 51 04 C1 EA 11 F6 C2 01 0F 84 ? ? ? ?");
        auto fallback = hook::pattern("8B 4C 24 48 6A 00 51 8D 54 24 54 52 8B CB E8 01 FE FF FF 66 8B 00 66 89 45 00 8B C5");
        if (failedRead.size() != 1 || chooseAsset.size() != 1 || fallback.size() != 1)
            return;

        const auto chooser = chooseAsset.get_first<uint8_t>();
        static const auto nextCandidate = reinterpret_cast<uintptr_t>(chooser + 34 + *chooseAsset.get_first<int32_t>(30));
        static const auto noCandidate = reinterpret_cast<uintptr_t>(fallback.get_first(26));

        static auto DelayRetry = safetyhook::create_mid(failedRead.get_first(), [](SafetyHookContext& regs)
        {
            const auto assetId = *reinterpret_cast<const uint16_t*>(regs.esi + 8);
            if (heldEntries && assetId == OutroAssetId)
                preloadFailed = true;
            if (IsOutroActive())
                readRetries[assetId % readRetries.size()] = { assetId, GetTickCount64() + RetryDelayMs };
        });
        if (!DelayRetry)
            return;

        // The queue search retries with priority filtering off. Once that pass
        // has also found no candidate, return the empty result to the frame update.
        static auto EndFallback = safetyhook::create_mid(fallback.get_first(), [](SafetyHookContext& regs)
        {
            if (IsOutroActive() && *reinterpret_cast<const uint8_t*>(regs.esp + 0x4C) == 0)
                regs.eip = noCandidate;
        });
        if (!EndFallback)
        {
            DelayRetry.reset();
            return;
        }

        static auto SkipDelayed = safetyhook::create_mid(chooser + 8, [](SafetyHookContext& regs)
        {
            if (IsOutroActive())
            {
                const auto assetId = static_cast<uint16_t>(regs.esi);
                const auto& retry = readRetries[assetId % readRetries.size()];
                if (retry.assetId == assetId && GetTickCount64() < retry.retryAt)
                    regs.eip = nextCandidate;
            }
        });
        if (!SkipDelayed)
        {
            EndFallback.reset();
            DelayRetry.reset();
        }
    }

    void InitPreload(StreamCatalog* streamCatalog, RequestAsset request)
    {
        auto releaseSite = hook::pattern("83 C4 08 6A 20 50 B9 ? ? ? ? E8 39 AA F8 FF 47 3B FB 7C ? 5E 5F 5B C2 04 00");
        auto pump = hook::pattern("E8 36 A7 05 00 B9 ? ? ? ? E8 AC B4 05 00 6A 73 B9 ? ? ? ? E8 40 27 00 00");
        if (releaseSite.size() != 1 || pump.size() != 1)
            return;

        catalog = streamCatalog;
        requestAsset = request;
        releaseAsset = reinterpret_cast<ReleaseAsset>(injector::GetBranchDestination(releaseSite.get_first(11)).as_int());

        // The streaming update holds the engine lock at this point.
        static auto Preload = safetyhook::create_mid(pump.get_first(5), [](SafetyHookContext&)
        {
            UpdatePreload();
        });
    }

    void Init()
    {
        auto openList = hook::pattern("8B 44 24 08 56 8B F1 89 46 0C E8 ? ? ? ? 8B 4C 24 08 0F 57 C0 83 0E 02");
        auto requestAsset = hook::pattern("83 C4 08 6A 20 50 B9 ? ? ? ? E8 19 AB F8 FF 47 3B FB 7C ? 5E 5F 5B C2 04 00");
        if (openList.size() != 1 || requestAsset.size() != 1)
            return;

        static auto OpenList = safetyhook::create_mid(openList.get_first(), [](SafetyHookContext& regs)
        {
            const auto path = *reinterpret_cast<const char* const*>(regs.esp + 4);
            OnListOpened(path, reinterpret_cast<const uint8_t*>(regs.ecx));
        });
        if (!OpenList)
            return;

        const auto streamCatalog = *requestAsset.get_first<StreamCatalog*>(7);
        const auto request = reinterpret_cast<RequestAsset>(injector::GetBranchDestination(requestAsset.get_first(11)).as_int());

        // The outro's streaming list waits for queued assets to start loading before it submits
        // another batch. Prioritize its requests over assets still queued from gameplay.
        static auto PrioritizeRequests = safetyhook::create_mid(requestAsset.get_first(11), [](SafetyHookContext& regs)
        {
            if (outroList)
                *reinterpret_cast<uint32_t*>(regs.esp + 4) |= PriorityRequest;
        });
        if (!PrioritizeRequests)
        {
            OpenList.reset();
            return;
        }
        InitReadRetries();
        InitPreload(streamCatalog, request);
    }
}

namespace TextNumbers
{
    int __cdecl Substitute(const wchar_t* text, int first, int second, int third, int fourth,
        int fifth, int sixth, float value, int precision, wchar_t* output)
    {
        if (!text)
        {
            *output = L'\0';
            return 0;
        }

        // The original uses wchar_t[10], including its terminator. A ten-digit
        // leaderboard score overwrites the return address with that terminator.
        const std::array numbers = { first, second, third, fourth, fifth, sixth };
        auto number = precision < 0 ? std::to_wstring(first)
            : std::format(L"{:.{}f}", static_cast<double>(value), precision);
        const std::wstring_view input(text);
        unsigned char substitutions = 0;
        for (size_t i = 0; i < input.size();)
        {
            if (i + 2 < input.size() &&
                ((input[i] == L'~' && input[i + 1] == L'1' && input[i + 2] == L'~') ||
                 (input[i] == L'|' && input[i + 1] == L'0' && input[i + 2] == L'\\')))
            {
                for (auto character : number) *output++ = character;
                i += 3;
                // Preserve the game's six arguments, including its behavior for
                // additional placeholders and the byte-sized substitution counter.
                if (++substitutions >= 1 && substitutions <= 5)
                    number = std::to_wstring(numbers[substitutions]);
            }
            else
                *output++ = input[i++];
        }
        *output = L'\0';
        return 0;
    }
}

class Fixes
{
public:
    Fixes()
    {
        FusionFix::onInitEventAsync() += []()
        {
            // Keep leaderboards usable when a record needs ten or more digits.
            {
                auto pattern = hook::pattern("83 EC 30 57 8B 7C 24 38 85 FF 75 ? 8B 4C 24 5C 33 C0 66 89 01");
                static auto TextNumbersFix = safetyhook::create_inline(pattern.get_first(), TextNumbers::Substitute);
            }

            // The title screen is built again when the opening of a new game ends. For a profile that is signed in
            // but offline its update then sets the help text of the Store row before the row exists, the one
            // case it doesn't check, and the game crashes.
            {
                auto pattern = hook::pattern("8B 8E ? ? ? ? 68 ? ? ? ? E9 ? ? ? ? 80 BE ? ? ? ? 00 8D BE");
                static auto nStoreRowOffset = *pattern.get_first<uint32_t>(2);
                static auto pAfterStoreText = (uintptr_t)hook::get_pattern("8B 8E ? ? ? ? 85 C9 74 ? 84 DB 75 ? 38 1D");
                static auto OfflineStoreTextFix = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
                {
                    if (!*(void**)(regs.esi + nStoreRowOffset))
                        regs.eip = pAfterStoreText;
                });
            }

            // Disable WM_DEVICECHANGE message handler, since it pauses the game randomly for some reason
            {
                auto pattern = hook::pattern("74 ? 83 E8 ? 0F 85 ? ? ? ? E8 ? ? ? ? 84 C0 0F 84");
                static raw_mem pDeviceChangeCheck(pattern.get_first(0), { 0x90, 0x90 }); // nop

                static auto DeviceChangeCB = []()
                {
                    if (FusionFixSettings.GetInt(PREF_DEVICECHANGE))
                        pDeviceChangeCheck.Write();
                    else
                        pDeviceChangeCheck.Restore();
                };

                DeviceChangeCB();

                FusionFix::onIniFileChange() += []()
                {
                    DeviceChangeCB();
                };
            }

            // Cutscene panels animation fixes
            {
                // For the renderer command 0xB6 both PC version 22 and console sample around the center.
                // Whereas version 28 and above on PC calculate the sampling center from the coords which breaks the panels' movement.
                auto pattern = hook::pattern("F3 0F 59 CC F3 0F 59 C4 F3 0F 59 DC");
                injector::MakeNOP(pattern.get_first(0), 8, true);
                static auto CutscenePanelsAnimationFix = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
                {
                    regs.xmm1 = regs.xmm4;
                    regs.xmm0 = regs.xmm4;
                });

                // On PC the position deltas for LockSlide are missing fabs, adding them back fixes some panels
                pattern = hook::pattern("F3 0F 5C DA ? ? ? ? F3 0F 11 4C 24 ? ? ? ? ? F3 0F 59 D8");

                static auto CutscenePanelsLockSlideYFix = safetyhook::create_mid(pattern.get_first(0x12), [](SafetyHookContext& regs)
                    {
                        regs.xmm3.f32[0] = fabs(regs.xmm3.f32[0]);
                    });

                static auto CutscenePanelsLockSlideXFix = safetyhook::create_mid(pattern.get_first(0x27), [](SafetyHookContext& regs)
                    {
                        regs.xmm2.f32[0] = fabs(regs.xmm2.f32[0]);
                    });

                GaragePanels::Init();
            }
        };

        FusionFix::onInitEvent() += []()
        {
            BusDepotStreaming::Init();

            // Shader containers of the title update archive take precedence over loose files, so the fix's shaders
            // in update/common/shaders are opened by their full path.
            {
                static std::string root = (std::filesystem::path(GetExeModulePath()) / "update" / "common" / "shaders").string();
                static thread_local std::string path;
                auto pattern = hook::pattern("8B 87 B8 00 00 00 6A 01 50 E8");
                static auto ShaderPath = safetyhook::create_mid(pattern.count(2).get(0).get<void>(6), [](SafetyHookContext& regs)
                {
                    constexpr std::string_view device = "common:/shaders/";
                    std::string_view name = reinterpret_cast<const char*>(regs.eax);
                    if (!name.starts_with(device))
                        return;
                    path = root + "\\" + std::string(name.substr(device.size()));
                    if (GetFileAttributesA(path.c_str()) != INVALID_FILE_ATTRIBUTES)
                        regs.eax = reinterpret_cast<uintptr_t>(path.c_str());
                });
            }

            // Intel GPU vendor checks fix
            // Some Intel GPUs are blocked from switching to anything else than DX9, probably meant for old iGPUs which usually didn't support certain features at the time.
            // Nowadays this is not usually the case anymore, and it kills the potential of more modern integrated chips (e.g. Iris XE) or perhaps even Intel ARC cards (Not tested) to brute force this game due to outdated DX9 drivers.
            // In case some older iGPUs have problems as a result of this change (Unlikely?!), it is gated around a hidden option, SkipIntelVendorChecks in the .cfg, to disable it.
            if (FusionFixSettings.GetInt(PREF_SKIPINTELVENDORCHECKS))
            {
                auto pattern = hook::pattern("0F 85 ? ? ? ? 81 BC 24");
                injector::WriteMemory<uint16_t>(pattern.get_first(0), 0xE990, true);
            }
        };
    }
} Fixes;
