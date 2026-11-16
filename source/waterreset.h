#pragma once

#include <d3d9.h>
#include <d3d11.h>
#include <wrl/client.h>
#include <atomic>

namespace WaterRenderTargets
{
    using Microsoft::WRL::ComPtr;
    using TextureSet = std::array<ComPtr<ID3D11Texture2D>, 7>;

    // The final slot holds the shared normal map. The other slots are the
    // surface pair and the non-MSAA/MSAA ripple pairs in the water phase.
    constexpr std::array<size_t, 6> targetSlots{ 638, 639, 641, 642, 644, 645 };
    constexpr std::array<size_t, 4> simulationSlots{ 636, 637, 640, 643 };

    const uintptr_t* waterPhase = nullptr;
    const uintptr_t* normalTarget = nullptr;
    const unsigned* activeRenderer = nullptr;
    void (__cdecl* requestReset)() = nullptr;
    uint8_t* resetPending = nullptr;
    std::atomic<uintptr_t> restoredPhase{};
    std::mutex snapshotMutex;
    bool rebuildingWithoutResize = false;
    TextureSet savedTargets;
    constexpr std::array<size_t, 4> dx9Slots{638, 639, 641, 642};
    using Dx9MipChain = std::vector<ComPtr<IDirect3DSurface9>>;
    std::array<Dx9MipChain, dx9Slots.size() + 1> dx9Maps;
    uintptr_t liveWaterPhase = 0;
    struct ReflectionRefresh
    {
        uint32_t dueAt;
        uint32_t attemptsLeft;
    };
    std::atomic<ReflectionRefresh> reflectionRefresh{};
    constexpr std::array<uint32_t, 3> reflectionRetryDelayMs{ 0, 180, 80 };
    std::array<uintptr_t, simulationSlots.size()> savedSimulation{};

    ComPtr<ID3D11Texture2D> GetTexture(uintptr_t target)
    {
        ComPtr<ID3D11Texture2D> texture;
        if (target)
        {
            using GetResource = IUnknown* (__thiscall*)(uintptr_t);
            const auto vtable = *reinterpret_cast<const uintptr_t* const*>(target);
            if (auto resource = reinterpret_cast<GetResource>(vtable[18])(target))
                resource->QueryInterface(IID_PPV_ARGS(texture.GetAddressOf()));
        }
        return texture;
    }

    TextureSet ReadTargets(const uintptr_t* phase)
    {
        TextureSet result;
        for (size_t i = 0; i < targetSlots.size(); ++i)
            result[i] = GetTexture(phase[targetSlots[i]]);
        result.back() = GetTexture(*normalTarget);
        return result;
    }

    bool SameTextureLayout(ID3D11Texture2D* from, ID3D11Texture2D* to, ID3D11Device* device)
    {
        if (!from || !to)
            return from == to;

        D3D11_TEXTURE2D_DESC first{}, second{};
        from->GetDesc(&first);
        to->GetDesc(&second);
        ComPtr<ID3D11Device> firstDevice, secondDevice;
        from->GetDevice(&firstDevice);
        to->GetDevice(&secondDevice);

        return firstDevice.Get() == device && secondDevice.Get() == device
            && first.Width == second.Width && first.Height == second.Height
            && first.MipLevels == second.MipLevels && first.ArraySize == second.ArraySize
            && first.Format == second.Format
            && first.SampleDesc.Count == second.SampleDesc.Count
            && first.SampleDesc.Quality == second.SampleDesc.Quality;
    }

    void BeginRebuild(SafetyHookContext& regs)
    {
        using IsQualityOnly = bool (__thiscall*)(uintptr_t);
        const auto vtable = *reinterpret_cast<const uintptr_t* const*>(regs.ecx);
        const std::lock_guard lock(snapshotMutex);
        rebuildingWithoutResize = reinterpret_cast<IsQualityOnly>(vtable[100])(regs.ecx);
        savedTargets = {};
    }

    void SaveWaterTargets(SafetyHookContext& regs)
    {
        if (restoredPhase.load(std::memory_order_relaxed) == regs.ecx)
            restoredPhase.store(0, std::memory_order_relaxed);
        const std::lock_guard lock(snapshotMutex);
        if (liveWaterPhase == regs.ecx)
            liveWaterPhase = 0;
        if (!rebuildingWithoutResize || regs.ecx != *waterPhase)
            return;

        const auto phase = reinterpret_cast<const uintptr_t*>(regs.ecx);
        savedTargets = ReadTargets(phase);
        for (size_t i = 0; i < simulationSlots.size(); ++i)
            savedSimulation[i] = phase[simulationSlots[i]];
    }

    bool RestoreWaterTargets(uintptr_t* phase)
    {
        if (!savedTargets[0] || !savedTargets[1] || !savedTargets.back())
            return false;

        const auto targets = ReadTargets(phase);
        ComPtr<ID3D11Device> device;
        savedTargets[0]->GetDevice(&device);
        for (size_t i = 0; i < targets.size(); ++i)
        {
            if (!SameTextureLayout(savedTargets[i].Get(), targets[i].Get(), device.Get()))
                return false;
        }

        ComPtr<ID3D11DeviceContext> context;
        device->GetImmediateContext(&context);
        for (size_t i = 0; i < targets.size(); ++i)
        {
            if (targets[i] && targets[i].Get() != savedTargets[i].Get())
                context->CopyResource(targets[i].Get(), savedTargets[i].Get());
        }
        for (size_t i = 0; i < simulationSlots.size(); ++i)
            phase[simulationSlots[i]] = savedSimulation[i];

        return true;
    }

    IDirect3DTexture9* GetDx9Texture(uintptr_t target, bool allocate)
    {
        if (!target)
            return nullptr;

        const auto vtable = *reinterpret_cast<const uintptr_t* const*>(target);
        if (allocate)
        {
            using EnsureTarget = void (__thiscall*)(uintptr_t, unsigned);
            reinterpret_cast<EnsureTarget>(vtable[27])(target, 0);
        }

        using GetResource = IDirect3DTexture9* (__thiscall*)(uintptr_t);
        return reinterpret_cast<GetResource>(vtable[18])(target);
    }

    bool SaveDx9Mips(IDirect3DTexture9* texture, Dx9MipChain& saved)
    {
        if (!texture)
            return false;

        ComPtr<IDirect3DDevice9> device;
        if (FAILED(texture->GetDevice(device.GetAddressOf())))
            return false;

        const auto levels = texture->GetLevelCount();
        for (UINT level = 0; level < levels; ++level)
        {
            D3DSURFACE_DESC desc{};
            ComPtr<IDirect3DSurface9> source, copy;
            if (FAILED(texture->GetSurfaceLevel(level, source.GetAddressOf()))
                || FAILED(source->GetDesc(&desc)) || !(desc.Usage & D3DUSAGE_RENDERTARGET)
                || FAILED(device->CreateOffscreenPlainSurface(desc.Width, desc.Height, desc.Format,
                    D3DPOOL_SYSTEMMEM, copy.GetAddressOf(), nullptr))
                || FAILED(device->GetRenderTargetData(source.Get(), copy.Get())))
                return false;
            saved.push_back(std::move(copy));
        }
        return levels != 0;
    }

    bool RestoreDx9Mips(IDirect3DTexture9* texture, const Dx9MipChain& saved)
    {
        if (!texture || texture->GetLevelCount() != saved.size())
            return false;

        ComPtr<IDirect3DDevice9> device;
        if (FAILED(texture->GetDevice(device.GetAddressOf())))
            return false;

        for (UINT level = 0; level < saved.size(); ++level)
        {
            D3DSURFACE_DESC from{}, to{};
            ComPtr<IDirect3DSurface9> dest;
            if (FAILED(texture->GetSurfaceLevel(level, dest.GetAddressOf()))
                || FAILED(saved[level]->GetDesc(&from)) || FAILED(dest->GetDesc(&to))
                || from.Width != to.Width || from.Height != to.Height || from.Format != to.Format
                || FAILED(device->UpdateSurface(saved[level].Get(), nullptr, dest.Get(), nullptr)))
                return false;
        }
        return true;
    }

    uintptr_t Dx9Target(const uintptr_t* phase, size_t index)
    {
        return index < dx9Slots.size() ? phase[dx9Slots[index]] : *normalTarget;
    }

    void SaveDx9BeforeReset(SafetyHookContext&)
    {
        const std::lock_guard lock(snapshotMutex);
        dx9Maps = {};
        if (*activeRenderer != 900 || !liveWaterPhase || liveWaterPhase != *waterPhase)
            return;

        const auto phase = reinterpret_cast<const uintptr_t*>(liveWaterPhase);
        if (phase[644] || phase[645])
            return;

        // Only system-memory surfaces survive the upcoming D3D9 reset.
        for (size_t i = 0; i < dx9Maps.size(); ++i)
        {
            if (!SaveDx9Mips(GetDx9Texture(Dx9Target(phase, i), false), dx9Maps[i]))
            {
                dx9Maps = {};
                return;
            }
        }

        for (size_t i = 0; i < simulationSlots.size(); ++i)
            savedSimulation[i] = phase[simulationSlots[i]];
    }

    bool RestoreDx9WaterTargets(uintptr_t* phase)
    {
        if (*activeRenderer != 900 || dx9Maps.front().empty() || phase[644] || phase[645])
            return false;

        for (size_t i = 0; i < dx9Maps.size(); ++i)
        {
            if (!RestoreDx9Mips(GetDx9Texture(Dx9Target(phase, i), true), dx9Maps[i]))
                return false;
        }

        for (size_t i = 0; i < simulationSlots.size(); ++i)
            phase[simulationSlots[i]] = savedSimulation[i];

        return true;
    }

    void AfterWaterCreation(SafetyHookContext&)
    {
        const std::lock_guard lock(snapshotMutex);
        liveWaterPhase = *waterPhase;
        auto phase = reinterpret_cast<uintptr_t*>(liveWaterPhase);
        if (phase && (RestoreWaterTargets(phase) || RestoreDx9WaterTargets(phase)))
        {
            *resetPending = 0;
            restoredPhase.store(*waterPhase, std::memory_order_relaxed);
        }
        else
            requestReset();
        savedTargets = {};
        dx9Maps = {};
    }

    void InitReflectionRefresh()
    {
        auto applied = hook::pattern("66 39 5C 24 7E 74 0D 8B 54 24 78 52 E8 ? ? ? ? 83 C4 04 66 39 5C 24 76");
        auto created = hook::pattern("89 A8 F4 09 00 00 89 B8 F8 09 00 00 8B BC 24 80 00 00 00");
        auto cameraCheck = hook::pattern("F3 0F 11 05 ? ? ? ? 3A C3 75 0D E8 ? ? ? ? 85 C0 0F 84 ? ? ? ? 8B 0D");
        auto coverageCheck = hook::pattern("69 C0 A0 06 00 00 0F 2F 80 ? ? ? ? 76 0C C7 86 D8 09 00 00 FF FF FF FF");
        auto mirrorCheck = hook::pattern("39 58 30 74 09 39 58 38 0F 8F ? ? ? ? 83 BE D8 09 00 00 FF 0F 84");
        auto simulationPause = hook::pattern("E8 91 D2 E8 FF 8A 15 ? ? ? ? 0A 15 ? ? ? ? 75 5C");
        if (applied.size() != 1 || created.size() != 1 || cameraCheck.size() != 1
            || coverageCheck.size() != 1 || simulationPause.size() != 1 || mirrorCheck.size() != 1)
            return;

        static const auto pauseMask = *simulationPause.get_first<const uint16_t*>(7);
        static const auto coverage = *coverageCheck.get_first<const uintptr_t*>(9);
        static auto AllowDistantReflection = safetyhook::create_mid(coverageCheck.get_first(6), [](SafetyHookContext& regs)
        {
            const auto pending = reflectionRefresh.load(std::memory_order_relaxed);
            if (pending.attemptsLeft == 0)
                return;

            const float visible = *reinterpret_cast<const float*>(coverage + regs.eax);
            if (visible > 0.0f && visible < regs.xmm0.f32[0])
                regs.xmm0.f32[0] = visible;
        });
        static auto AllowWaterWithMirror = safetyhook::create_mid(mirrorCheck.get_first(8), [](SafetyHookContext& regs)
        {
            const auto pending = reflectionRefresh.load(std::memory_order_relaxed);
            if (*pauseMask == 0 || pending.attemptsLeft == 0
                || static_cast<int32_t>(GetTickCount() - pending.dueAt) < 0)
                return;

            constexpr auto zeroFlag = 1u << 6;
            constexpr auto signFlag = 1u << 7;
            constexpr auto overflowFlag = 1u << 11;
            const auto flags = regs.eflags;
            if ((flags & zeroFlag) || ((flags & signFlag) != 0) != ((flags & overflowFlag) != 0))
                return;

            const auto phase = reinterpret_cast<const uintptr_t*>(regs.esi);
            if (phase[630] == static_cast<uintptr_t>(-1))
                return;

            // The mirror pass usually takes priority here. Let this one
            // settings refresh also submit to the water reflection target.
            regs.eflags |= zeroFlag;

        });
        static auto DrawReflection = safetyhook::create_mid(cameraCheck.get_first(), [](SafetyHookContext& regs)
        {
            auto pending = reflectionRefresh.load(std::memory_order_relaxed);
            if (pending.attemptsLeft == 0)
                return;

            const uint32_t now = GetTickCount();
            if (static_cast<int32_t>(now - pending.dueAt) < 0)
                return;

            const uint32_t remaining = pending.attemptsLeft - 1;
            const ReflectionRefresh next{now + reflectionRetryDelayMs[remaining], remaining};
            if (!reflectionRefresh.compare_exchange_strong(pending, next, std::memory_order_relaxed))
                return;

            // A newly created target can be rendered before the rebuilt
            // view has finished populating. Schedule two later refreshes.
            regs.eax = (regs.eax & ~0xFFu) | ((regs.ebx ^ 1u) & 0xFFu);
        });
        const auto requestRefresh = [](SafetyHookContext&)
        {
            reflectionRefresh.store({GetTickCount(), static_cast<uint32_t>(reflectionRetryDelayMs.size())},
                std::memory_order_relaxed);
        };
        static auto AfterApply = DrawReflection && AllowWaterWithMirror
            ? safetyhook::create_mid(applied.get_first(), requestRefresh) : SafetyHookMid{};
        static auto AfterCreate = AfterApply
            ? safetyhook::create_mid(created.get_first(12), requestRefresh) : SafetyHookMid{};
        if (!AfterCreate)
        {
            AllowDistantReflection.reset();
            AllowWaterWithMirror.reset();
            AfterApply.reset();
            DrawReflection.reset();
        }
    }

    void EndRebuild(SafetyHookContext&)
    {
        const std::lock_guard lock(snapshotMutex);
        rebuildingWithoutResize = false;
        // The render graph can recreate the water phase on a later frame.
        // Keep the snapshot for its first creation or the next device reset.
    }

    void __cdecl RequestWaterResetWhileInactive()
    {
        // The simulation asks for a reset each inactive frame. When the maps
        // survived the quality rebuild, resume them on the first active frame.
        const auto restored = restoredPhase.load(std::memory_order_relaxed);
        if (!restored || restored != *waterPhase)
            requestReset();
    }

    void Init(const unsigned* renderer)
    {
        activeRenderer = renderer;
        InitReflectionRefresh();

        auto created = hook::pattern("A3 ? ? ? ? E8 ? ? ? ? 89 6C 24 14 F7 C7 00 00 00 10 74 2D 68 00 0A 00 00");
        auto reset = hook::pattern("C6 05 ? ? ? ? 01 C3 CC CC CC CC CC CC CC CC 56 8B 35 ? ? ? ? 85 F6 74 28 8D 46 08");
        if (created.size() != 1 || reset.size() != 1)
            return;
        waterPhase = *created.get_first<const uintptr_t*>(1);
        requestReset = reinterpret_cast<decltype(requestReset)>(reset.get_first());
        resetPending = *reset.get_first<uint8_t*>(2);
        static auto AfterCreate = safetyhook::create_mid(created.get_first(10), AfterWaterCreation);

        auto start = hook::pattern("81 EC 98 00 00 00 56 8B F1 8B 06 8B 90 38 01 00 00 57 6A 01 FF D2");
        auto finish = hook::pattern("E8 6B DB FC FF 8B 16 8B 82 A4 01 00 00 6A 00 8B CE FF D0");
        auto destroy = hook::pattern("51 53 55 56 57 89 4C 24 10 8D B9 04 0A 00 00 BB 02 00 00 00");
        auto normal = hook::pattern("83 EB 01 75 AA 8B 35 ? ? ? ? 3B F5 74 24 8D 4E 08");
        auto paused = hook::pattern("E8 91 D2 E8 FF 8A 15 ? ? ? ? 0A 15 ? ? ? ? 75 5C");
        if (!AfterCreate || start.size() != 1 || finish.size() != 1 || destroy.size() != 1
            || normal.size() != 1 || paused.size() != 1)
            return;
        normalTarget = *normal.get_first<const uintptr_t*>(7);
        static auto Begin = safetyhook::create_mid(start.get_first(), BeginRebuild);
        static auto End = safetyhook::create_mid(finish.get_first(5), EndRebuild);
        static auto Save = safetyhook::create_mid(destroy.get_first(), SaveWaterTargets);
        if (Begin && End && Save)
        {
            injector::MakeCALL(paused.get_first(), RequestWaterResetWhileInactive, true);
            auto dx9Reset = hook::pattern("8B 82 68 01 00 00 6A 01 8B CE FF D0 80 BC 24 98 00 00 00 00 8B 16 8B 82 B8 03 00 00");
            if (dx9Reset.size() == 1)
                static auto BeforeDx9Reset = safetyhook::create_mid(dx9Reset.get_first(12), SaveDx9BeforeReset);
        }
        else
        {
            Begin.reset();
            End.reset();
            Save.reset();
        }
    }
}
