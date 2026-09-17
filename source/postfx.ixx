module;

#include <common.hxx>
#include <d3d9.h>
#include <d3d11.h>

export module postfx;

import common;
import settings;

import postfxcommon;
import postfxdx9;
import postfxdx11;

// ===========================================================================
// Post processing for every renderer Max Payne 3 can run on:
//
//   Direct3D 9      vs_3_0 / ps_3_0   win32_30
//   Direct3D 10     vs_4_0 / ps_4_0   win32_40
//   Direct3D 10.1   vs_4_1 / ps_4_1   win32_41
//   Direct3D 11     vs_5_0 / ps_5_0   win32_50
//
// All effects - SMAA, blur and the console gamma presets - share the same
// shader sources (shaders/postfx), the same options and the same entry points.
// Shaders are compiled by fxc during the prebuild step and embedded as RCDATA,
// nothing is compiled at runtime.
//
// Options are re-read from the ini on every call, so changing any of them,
// including which console gamma preset is used, takes effect immediately
// without reloading shaders.
// ===========================================================================
export class CPostFX
{
public:
    static inline PostFXOptions Options{};

    static void UpdateOptions()
    {
        const int nSmaa = FusionFixSettings.GetInt(PREF_SMAA); // 0 off, 1 on, 2 on with the edge view

        Options.nConsoleGamma = FusionFixSettings.GetInt(PREF_CONSOLEGAMMA); // 0 off, 1 Xenon, 2 Cell
        Options.bSmaa = nSmaa != 0;
        Options.bSmaaDebug = nSmaa == 2;
        Options.bBlur = FusionFixSettings.GetInt(PREF_BLUR) != 0;
        Options.fBlurStrength = FusionFixSettings.GetFloat(PREF_BLURSTRENGTH);
    }

    static void Shutdown()
    {
        PostFX9::Shutdown();
        PostFX11::Shutdown();
    }

    static void Render(unsigned int uStages = POSTFX_STAGE_SMAA | POSTFX_STAGE_GAMMA)
    {
        IDirect3DDevice9* pDevice = nullptr;
        if (AcquireDirect3D9Device(&pDevice))
        {
            Render(pDevice, uStages);
            pDevice->Release();
            return;
        }

        Render((IDXGISwapChain*)GetCommonSwapChain(), uStages);
    }

    // -----------------------------------------------------------------------
    // Direct3D 9
    // -----------------------------------------------------------------------
    static void Render(IDirect3DDevice9* pDevice, unsigned int uStages = POSTFX_STAGE_SMAA | POSTFX_STAGE_GAMMA)
    {
        if (!pDevice)
            return;

        UpdateOptions();
        PostFX9::Render(pDevice, Options, uStages);
    }

    // From the hook that runs before the game resets or recreates its device.
    static void OnLostDevice()
    {
        PostFX9::OnLostDevice();
    }

    // -----------------------------------------------------------------------
    // Direct3D 10, 10.1 and 11
    // -----------------------------------------------------------------------
    static void Render(IDXGISwapChain* pSwapChain, unsigned int uStages = POSTFX_STAGE_SMAA | POSTFX_STAGE_GAMMA)
    {
        if (!pSwapChain)
            return;

        UpdateOptions();
        PostFX11::Render(pSwapChain, Options, uStages);
    }

    static void OnResize()
    {
        PostFX11::OnResize();
    }

public:
    static IUnknown* GetCommonDevice()
    {
        return ppPostFXDevice ? *ppPostFXDevice : nullptr;
    }

    static IUnknown* GetCommonSwapChain()
    {
        return ppPostFXSwapChain ? *ppPostFXSwapChain : nullptr;
    }

    // hands out a reference the caller has to release
    static bool AcquireDirect3D9Device(IDirect3DDevice9** ppDevice)
    {
        IUnknown* candidates[] = { GetCommonDevice(), GetCommonSwapChain() };
        for (IUnknown* pObject : candidates)
        {
            if (!pObject)
                continue;

            if (SUCCEEDED(pObject->QueryInterface(IID_PostFXDirect3DDevice9, (void**)ppDevice)) && *ppDevice)
                return true;
        }

        return false;
    }
};

class PostFX
{
public:
    PostFX()
    {
        FusionFix::onInitEventAsync() += []()
        {
            ppPostFXDevice = *hook::get_pattern<IUnknown**>("68 ? ? ? ? 68 ? ? ? ? 8B D7 83 CA 10", 1);
            ppPostFXSwapChain = *hook::get_pattern<IUnknown**>("A1 ? ? ? ? 8B 08 53 8D 54 24 14 52 50", 1);

            auto pattern = hook::pattern("68 ? ? ? ? E8 ? ? ? ? 8B 15 ? ? ? ? 8B 0D ? ? ? ? 8B 04 95 ? ? ? ? 83 C4 08 03 C1");
            static auto BeforeUIHook = safetyhook::create_mid(*pattern.get_first<void*>(1), [](SafetyHookContext& ctx)
            {
                CPostFX::Render(POSTFX_STAGE_SMAA | POSTFX_STAGE_BLUR);
            });

            pattern = hook::pattern("0F B6 C8 8B 07 F7 D9 1B C9 F7 D1 23 0D ? ? ? ? 51 52 FF D0 8B F8 81 FF ? ? ? ? 75");
            static auto DX11PresentHook1 = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
            {
                CPostFX::Render(POSTFX_STAGE_GAMMA);
            });

            pattern = hook::pattern("8B 07 F7 D9 1B C9 F7 D1 23 0D ? ? ? ? 51 52 FF D0 8B F8 81 FF ? ? ? ? 74");
            static auto DX11PresentHook2 = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
            {
                CPostFX::Render(POSTFX_STAGE_GAMMA);
            });

            pattern = hook::pattern("6A ? 51 55 53 52");
            static auto DX11ResizeBuffersHook = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
            {
                CPostFX::OnResize();
            });

            // Direct3D 9
            pattern = hook::pattern("8B 06 8B 90 ? ? ? ? 6A 00 8B CE ? ? ? ? ? ? ? ? ? ? 8B CE FF D2 A1");
            static auto DeviceResetHook = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                CPostFX::OnLostDevice();
            });

            pattern = hook::pattern("A1 ? ? ? ? ? ? 8B 91 ? ? ? ? 50 FF D2 A1 ? ? ? ? 50");
            static auto EndSceneHook = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                CPostFX::Render(POSTFX_STAGE_GAMMA);
            });
        };

        FusionFix::onShutdownEvent() += []()
        {
            CPostFX::Shutdown();
        };
    }
} PostFX;
