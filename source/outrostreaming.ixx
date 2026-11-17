module;

#include <common.hxx>

export module outrostreaming;

import common;

// The outro of chapter 10 (the bus depot) streams Da Silva's model too late, and while it waits the other models of the
// scene don't load either. The model is loaded at the start of the chapter and held until the outro has played, and
// the outro's requests go ahead of assets still queued from gameplay.
namespace OutroStreaming
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

    // Da Silva's outro model: its asset index and file in the game's archives
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
}

class OutroStreamingFix
{
public:
    OutroStreamingFix()
    {
        FusionFix::onInitEvent() += []()
        {
            using namespace OutroStreaming;

            auto pattern = hook::pattern("8B 44 24 08 56 8B F1 89 46 0C E8 ? ? ? ? 8B 4C 24 08 0F 57 C0 83 0E 02");
            static auto OpenList = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                const auto path = *reinterpret_cast<const char* const*>(regs.esp + 4);
                OnListOpened(path, reinterpret_cast<const uint8_t*>(regs.ecx));
            });

            pattern = hook::pattern("83 C4 08 6A 20 50 B9 ? ? ? ? E8 19 AB F8 FF 47 3B FB 7C ? 5E 5F 5B C2 04 00");
            catalog = *pattern.get_first<StreamCatalog*>(7);
            requestAsset = reinterpret_cast<RequestAsset>(injector::GetBranchDestination(pattern.get_first(11)).as_int());

            // The outro's streaming list waits for queued assets to start loading before it submits
            // another batch. Prioritize its requests over assets still queued from gameplay.
            static auto PrioritizeRequests = safetyhook::create_mid(pattern.get_first(11), [](SafetyHookContext& regs)
            {
                if (outroList)
                    *reinterpret_cast<uint32_t*>(regs.esp + 4) |= PriorityRequest;
            });

            // A failed read is retried after a short delay instead of right away while the outro streams
            {
                auto failedRead = hook::pattern("56 8B CF E8 BE FA FF FF 5F 5E 5D 32 C0 5B 83 C4 08 C2 04 00");
                auto chooseAsset = hook::pattern("89 4C 24 30 89 44 24 1C 74 18 83 BB BC 00 00 00 00 74 0F 8B 51 04 C1 EA 11 F6 C2 01 0F 84 ? ? ? ?");
                auto fallback = hook::pattern("8B 4C 24 48 6A 00 51 8D 54 24 54 52 8B CB E8 01 FE FF FF 66 8B 00 66 89 45 00 8B C5");

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

                // The queue search retries with priority filtering off. Once that pass
                // has also found no candidate, return the empty result to the frame update.
                static auto EndFallback = safetyhook::create_mid(fallback.get_first(), [](SafetyHookContext& regs)
                {
                    if (IsOutroActive() && *reinterpret_cast<const uint8_t*>(regs.esp + 0x4C) == 0)
                        regs.eip = noCandidate;
                });

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
            }

            // The preload, from the streaming update while it holds the engine lock
            {
                auto releaseSite = hook::pattern("83 C4 08 6A 20 50 B9 ? ? ? ? E8 39 AA F8 FF 47 3B FB 7C ? 5E 5F 5B C2 04 00");
                releaseAsset = reinterpret_cast<ReleaseAsset>(injector::GetBranchDestination(releaseSite.get_first(11)).as_int());

                auto pump = hook::pattern("E8 36 A7 05 00 B9 ? ? ? ? E8 AC B4 05 00 6A 73 B9 ? ? ? ? E8 40 27 00 00");
                static auto Preload = safetyhook::create_mid(pump.get_first(5), [](SafetyHookContext&)
                {
                    UpdatePreload();
                });
            }
        };
    }
} OutroStreamingFix;
