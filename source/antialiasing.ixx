module;

#include <common.hxx>
#include <d3d11.h>
#include <aa/AntiAliasingD3D11.hpp>

export module antialiasing;

import common;
import settings;
import postfxcommon;

// Anti-aliasing: SMAA (postfx), and temporal anti-aliasing through the shared module of FusionFixUtils (aa/,
// external/FusionFixUtils): TAA, DLAA and FSR native AA, the last two run by FusionFixHub.exe. On the Direct3D 11
// renderer (TemporalAA11) and the Direct3D 9 one (TemporalAA, TAA only); the Direct3D 10 renderer keeps SMAA.
//
// - Jitter: the game camera director (sub_B10040) updates the game viewport through sub_496970, which ends with
//   grcViewport::Perspective (sub_EE74B0). Perspective builds the projection at +0x1C0 with the projection shift at
//   +0x358/+0x35C as P20/P21. Only there, for the game camera, the shift gets the jitter and Perspective runs again; the
//   shift stays in the viewport, so every render phase that copies it and builds its projection again (the G-buffer
//   phase's own Perspective, the scene phase) draws with the same jitter. The jitter is taken out of the shift again
//   before the next frame's Perspective. The front end director's camera isn't jittered.
// - The frame being drawn: RAGE draws on a render thread while the next frame is built. The draw list command that
//   sets a viewport (sub_6C2E30) carries a copy of it: its view and projection tell the library which recorded camera
//   the render thread is drawing (OnRenderedCamera).
// - Depth: _DEFERRED_GBUFFER_Z_ (created in sub_6AFC20), the scene's depth-stencil, standard [0, 1] depth (on Direct3D 9
//   a texture the depth-stencil can be read through). Not with the game's MSAA, which makes it multisampled: the
//   temporal modes aren't offered then.
// - Resolve: at the end of CRenderPhaseDrawScene's draw list (the command sub_6D71A0 that postfx's BeforeUIHook also
//   uses, the instance queued at 0x91F33F), into the back buffer: the scene is complete there, after the game's post
//   processing, before the HUD, so LDR.

namespace
{
    enum Setting
    {
        Off = 0, SMAA = 1, SMAAEdges = 2, TAA = 3, DLAA = 4, FSR = 5
    };

    // grcViewport
    constexpr size_t ViewOffset = 0x180;            // world -> view, sixteen floats
    constexpr size_t ProjectionOffset = 0x1C0;      // sixteen floats
    constexpr size_t ShiftOffset = 0x358;           // projection shift x, y in NDC, P20 and P21 of the projection

    // The game thread
    bool bGameCamera = false;                       // the game camera director updates its viewport
    uint8_t* pJitteredViewport = nullptr;
    float fAppliedShift[2] = {};

    // From the render thread
    std::atomic<uint32_t> nRenderWidth = 0;
    std::atomic<uint32_t> nRenderHeight = 0;
    std::atomic<bool> bDirect3D11 = false;
    std::atomic<bool> bDirect3D9 = false;           // the Direct3D 9 renderer runs
    std::atomic<bool> bDepth9Usable = false;        // and its depth can be read
    std::atomic<uint32_t> nDepth9Changes = 0;       // for the menu to ask again
    std::atomic<bool> bTemporal = false;            // TAA, DLAA or FSR chosen, read once per frame in Render

    void** ppDepthTarget = nullptr;                 // grcRenderTarget* of _DEFERRED_GBUFFER_Z_

    WFPAA::Mode ToMode(int value)
    {
        switch (value)
        {
        case TAA: return WFPAA::Mode::TAA;
        case DLAA: return WFPAA::Mode::DLAA;
        case FSR: return WFPAA::Mode::FSR;
        default: return WFPAA::Mode::Off;
        }
    }

    bool IsTemporalSetting()
    {
        return FusionFixSettings.GetInt(PREF_ANTIALIASING) >= TAA;
    }

    // -------------------------------------------------------------------------------------------------------------
    // Jitter

    void* (__fastcall* Perspective)(uint8_t* viewport, void* edx, float fov, float aspect, float nearClip, float farClip) = nullptr;
    void* __fastcall PerspectiveHook(uint8_t* viewport, void* edx, float fov, float aspect, float nearClip, float farClip)
    {
        // The game's own shift again: last frame's jitter comes out first
        auto shift = reinterpret_cast<float*>(viewport + ShiftOffset);
        if (viewport == pJitteredViewport)
        {
            shift[0] -= fAppliedShift[0];
            shift[1] -= fAppliedShift[1];
            pJitteredViewport = nullptr;
        }

        auto result = Perspective(viewport, edx, fov, aspect, nearClip, farClip);
        if (!bGameCamera || !bTemporal)
            return result;

        WFPAA::Camera camera;
        camera.View = WFPAA::Matrix::From(reinterpret_cast<float*>(viewport + ViewOffset));
        camera.Projection = WFPAA::Matrix::From(reinterpret_cast<float*>(viewport + ProjectionOffset));
        camera.Width = nRenderWidth;
        camera.Height = nRenderHeight;
        auto jitter = bDirect3D9 ? WFPAA::TemporalAA::OnCamera(camera) : WFPAA::TemporalAA11::OnCamera(camera);
        if (jitter.X == 0.0f && jitter.Y == 0.0f)
            return result;

        // JitterProjection's change of P20 and P21, made through the shift so the copies of the viewport keep it
        float delta[16] = {};
        delta[11] = reinterpret_cast<float*>(viewport + ProjectionOffset)[11];
        WFPAA::JitterProjection(delta, jitter, static_cast<float>(camera.Width), static_cast<float>(camera.Height));
        fAppliedShift[0] = delta[8];
        fAppliedShift[1] = delta[9];
        shift[0] += delta[8];
        shift[1] += delta[9];
        pJitteredViewport = viewport;
        return Perspective(viewport, edx, fov, aspect, nearClip, farClip);
    }

    // sub_496970, the viewport update of a camera director, as called by the game camera director
    int (__fastcall* UpdateViewport)(void* viewport, void* edx, void* frame) = nullptr;
    int __fastcall GameCameraUpdateViewport(void* viewport, void* edx, void* frame)
    {
        bGameCamera = true;
        auto result = UpdateViewport(viewport, edx, frame);
        bGameCamera = false;
        return result;
    }

    // -------------------------------------------------------------------------------------------------------------
    // Depth

    bool ReadPointer(const void* address, void*& value)
    {
        __try
        {
            value = *static_cast<void* const*>(address);
            return true;
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            return false;
        }
    }

    // A Direct3D 11 object: its vtable is in d3d11.dll
    bool IsD3D11Object(void* object)
    {
        static auto d3d11 = GetModuleHandleW(L"d3d11.dll");
        void* vtable = nullptr;
        HMODULE module = nullptr;
        return object && ReadPointer(object, vtable) && vtable &&
            GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, static_cast<LPCWSTR>(vtable), &module) &&
            module == d3d11;
    }

    bool IsDepthFormat(DXGI_FORMAT format)
    {
        return format == DXGI_FORMAT_R24G8_TYPELESS || format == DXGI_FORMAT_R32G8X24_TYPELESS || format == DXGI_FORMAT_R32_TYPELESS;
    }

    // The texture of a grcRenderTargetDX11, with a reference. The member that holds it is found once, by looking for a
    // Direct3D 11 depth texture among the first members.
    ID3D11Texture2D* DepthTexture(void* target)
    {
        static int offset = -1;
        if (!target)
            return nullptr;

        auto textureAt = [&](int at) -> ID3D11Texture2D*
        {
            void* member = nullptr;
            if (!ReadPointer(static_cast<uint8_t*>(target) + at, member) || !IsD3D11Object(member))
                return nullptr;
            ID3D11Texture2D* texture = nullptr;
            if (FAILED(static_cast<IUnknown*>(member)->QueryInterface(IID_PPV_ARGS(&texture))) || !texture)
                return nullptr;
            D3D11_TEXTURE2D_DESC desc{};
            texture->GetDesc(&desc);
            if (IsDepthFormat(desc.Format))
                return texture;
            texture->Release();
            return nullptr;
        };

        if (offset >= 0)
            return textureAt(offset);
        for (int at = 4; at < 0x100; at += 4)
        {
            if (auto texture = textureAt(at))
            {
                offset = at;
                char text[96];
                sprintf_s(text, "Depth: the texture of _DEFERRED_GBUFFER_Z_ is at +0x%X", at);
                WFPAA::TemporalAA11::Log(text);
                return texture;
            }
        }
        return nullptr;
    }

    // Formats a Direct3D 9 depth can be sampled in (the hardware depth formats, or depth written to a float target)
    bool IsDepthFormat9(D3DFORMAT format)
    {
        return format == static_cast<D3DFORMAT>(MAKEFOURCC('I', 'N', 'T', 'Z')) || format == static_cast<D3DFORMAT>(MAKEFOURCC('D', 'F', '2', '4')) ||
            format == static_cast<D3DFORMAT>(MAKEFOURCC('D', 'F', '1', '6')) || format == D3DFMT_R32F;
    }

    // The texture of the grcRenderTargetDX9 (sub_EFD070 creates it, the destructor sub_EFCE60 releases it), with a
    // reference, when it's in a format the depth can be sampled in
    IDirect3DTexture9* DepthTexture9(void* target)
    {
        constexpr size_t TextureOffset = 0x38;
        static D3DFORMAT logged = D3DFMT_UNKNOWN;
        void* member = nullptr;
        void* vtable = nullptr;
        if (!target || !ReadPointer(static_cast<uint8_t*>(target) + TextureOffset, member) || !member || !ReadPointer(member, vtable) || !vtable)
            return nullptr;
        IDirect3DTexture9* texture = nullptr;
        if (FAILED(static_cast<IUnknown*>(member)->QueryInterface(IID_IDirect3DTexture9, reinterpret_cast<void**>(&texture))) || !texture)
            return nullptr;
        D3DSURFACE_DESC desc{};
        texture->GetLevelDesc(0, &desc);
        if (desc.Format != logged)
        {
            logged = desc.Format;
            char text[128];
            sprintf_s(text, "Depth: the Direct3D 9 texture of _DEFERRED_GBUFFER_Z_ has the format 0x%X, %ux%u%s", static_cast<unsigned>(desc.Format),
                desc.Width, desc.Height, IsDepthFormat9(desc.Format) ? "" : ", which can't be read");
            WFPAA::TemporalAA::Log(text);
        }
        if (IsDepthFormat9(desc.Format) && desc.MultiSampleType == D3DMULTISAMPLE_NONE)
            return texture;
        texture->Release();
        return nullptr;
    }

    // The Direct3D 9 device of the renderer, with a reference, or null on Direct3D 10 and 11
    IDirect3DDevice9* Direct3D9Device()
    {
        auto object = ppPostFXDevice ? *ppPostFXDevice : nullptr;
        IDirect3DDevice9* device = nullptr;
        if (!object || FAILED(object->QueryInterface(IID_PostFXDirect3DDevice9, reinterpret_cast<void**>(&device))))
            return nullptr;
        return device;
    }

    // Direct3D 9: the scene in the render target the scene's draw list ends with
    void Render9(IDirect3DDevice9* device)
    {
        bDirect3D9 = true;
        if (FAILED(device->TestCooperativeLevel()))
            return;
        WFPAA::TemporalAA::SetMode(ToMode(FusionFixSettings.GetInt(PREF_ANTIALIASING)), FusionFixSettings.GetFloat(PREF_AASHARPNESS) / 100.0f);

        IDirect3DSurface9* target = nullptr;
        if (FAILED(device->GetRenderTarget(0, &target)) || !target)
            return;
        D3DSURFACE_DESC desc{};
        target->GetDesc(&desc);
        nRenderWidth = desc.Width;
        nRenderHeight = desc.Height;

        auto depth = ppDepthTarget ? DepthTexture9(*ppDepthTarget) : nullptr;
        if (bDepth9Usable.exchange(depth != nullptr) != (depth != nullptr))
            ++nDepth9Changes;
        if (depth && desc.MultiSampleType == D3DMULTISAMPLE_NONE)
            WFPAA::TemporalAA::Render(device, target, depth, target);
        else
            WFPAA::TemporalAA::Update(device);
        if (depth)
            depth->Release();
        target->Release();
    }
}

export namespace AntiAliasing
{
    // SMAA, for postfx: 0 off, 1 on, 2 the edge view
    int SmaaMode()
    {
        auto value = FusionFixSettings.GetInt(PREF_ANTIALIASING);
        return value == SMAA || value == SMAAEdges ? value : 0;
    }

    // Before the HUD, at the end of the scene's draw list on the render thread. Without a temporal mode there's no
    // jitter and no pass; only every 30th frame the library looks at the device and the depth and starts the hub, so
    // the menu knows which temporal modes it can offer.
    void Render()
    {
        static uint32_t idleFrames = 0;
        bTemporal = IsTemporalSetting();
        if (bTemporal)
            idleFrames = 0;
        else if (idleFrames++ % 30 != 0)
            return;

        if (auto device9 = Direct3D9Device())
        {
            Render9(device9);
            device9->Release();
            return;
        }

        IDXGISwapChain* swapChain = nullptr;
        auto object = ppPostFXSwapChain ? *ppPostFXSwapChain : nullptr;
        if (!object || FAILED(object->QueryInterface(IID_PPV_ARGS(&swapChain))) || !swapChain)
            return;

        ID3D11Device* device = nullptr;
        ID3D11Texture2D* backBuffer = nullptr;
        if (SUCCEEDED(swapChain->GetDevice(IID_PPV_ARGS(&device))) && device && SUCCEEDED(swapChain->GetBuffer(0, IID_PPV_ARGS(&backBuffer))) && backBuffer)
        {
            bDirect3D11 = device->GetFeatureLevel() >= D3D_FEATURE_LEVEL_11_0;
            D3D11_TEXTURE2D_DESC desc{};
            backBuffer->GetDesc(&desc);
            nRenderWidth = desc.Width;
            nRenderHeight = desc.Height;

            if (bDirect3D11)
            {
                WFPAA::TemporalAA11::SetMode(ToMode(FusionFixSettings.GetInt(PREF_ANTIALIASING)), FusionFixSettings.GetFloat(PREF_AASHARPNESS) / 100.0f);
                ID3D11DeviceContext* context = nullptr;
                device->GetImmediateContext(&context);
                auto depth = ppDepthTarget ? DepthTexture(*ppDepthTarget) : nullptr;
                WFPAA::TemporalAA11::Render(context, backBuffer, depth, backBuffer);
                if (depth)
                    depth->Release();
                if (context)
                    context->Release();
            }
        }
        if (backBuffer)
            backBuffer->Release();
        if (device)
            device->Release();
        swapChain->Release();
    }

    // Before the swap chain's buffers are resized
    void OnResize()
    {
        WFPAA::TemporalAA11::OnResize();
    }

    // Direct3D 9: before the device is reset
    void OnLostDevice()
    {
        WFPAA::TemporalAA::OnLostDevice();
    }
}

class AntiAliasingInit
{
public:
    AntiAliasingInit()
    {
        FusionFix::onInitEvent() += []()
        {
            auto name = GetThisModuleName<std::wstring>();
            name = name.substr(0, name.find_last_of(L'.'));
            WFPAA::Options options;
            options.BridgeName = L"Local\\" + name + L".Upscaler";
            options.ClientName = "MaxPayne3.FusionFix";
            options.Log = GetThisModulePath() / (name + L".AntiAliasing.log");
            options.HubLog = GetThisModulePath() / (name + L".Upscaler.log");
            options.LowDynamicRange = true;
            options.CurrentWeightMin = 0.1f;   // a tenth of the current frame where nothing moves
            WFPAA::TemporalAA11::Configure(options);

            // The temporal modes on Direct3D 11 or 9 with a readable depth, DLAA and FSR once the hub reported them (it
            // starts with the first frame)
            SettingsPlugin().Availability("MAIN.AntiAliasing", [](std::string_view value)
            {
                bool d3d9 = bDirect3D9 && bDepth9Usable;
                bool d3d11 = !bDirect3D9 && WFPAA::TemporalAA11::IsRunning();
                if (value == "3")
                    return d3d9 || d3d11;
                if (value == "4")
                    return (d3d9 && WFPAA::TemporalAA::IsAvailable(WFPAA::Backend::DLSS)) || (d3d11 && WFPAA::TemporalAA11::IsAvailable(WFPAA::Backend::DLSS));
                if (value == "5")
                    return (d3d9 && WFPAA::TemporalAA::IsAvailable(WFPAA::Backend::FSR)) || (d3d11 && WFPAA::TemporalAA11::IsAvailable(WFPAA::Backend::FSR));
                return true;
            });

            static auto refresh = []()
            {
                static uint32_t generation = 0;
                auto now = WFPAA::TemporalAA11::Generation() + WFPAA::TemporalAA::Generation() + nDepth9Changes;
                if (generation != now)
                {
                    generation = now;
                    SettingsPlugin().Refresh("MAIN.AntiAliasing");
                }
            };
            FusionFix::onGameProcessEvent() += refresh;
            FusionFix::onMenuDrawingEvent() += refresh;

            // The game camera director's call of sub_496970
            auto pattern = hook::pattern("56 8B CB 89 83 A0 05 00 00 E8");
            if (!pattern.empty())
                UpdateViewport = injector::MakeCALL(pattern.get_first(9), GameCameraUpdateViewport, true).get();

            // grcViewport::Perspective in sub_496970
            pattern = hook::pattern("D9 46 54 D9 5C 24 08 D9 5C 24 04 D9 46 50 D9 1C 24 E8");
            if (!pattern.empty())
                Perspective = injector::MakeCALL(pattern.get_first(17), PerspectiveHook, true).get();

            // The viewport command of the draw lists (sub_6C2E30), on the render thread: ecx is the command, the viewport
            // is at +16 unless the byte at +0x480 resets it
            pattern = hook::pattern("80 B9 80 04 00 00 00 56 74 13 6A 01 6A 01 6A 00 E8");
            bool viewportHooked = !pattern.empty();
            if (viewportHooked)
            {
                static auto SetViewportHook = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
                {
                    auto command = reinterpret_cast<uint8_t*>(regs.ecx);
                    if (command[0x480] || !bTemporal)
                        return;
                    auto viewport = command + 16;
                    auto view = reinterpret_cast<float*>(viewport + ViewOffset);
                    auto projection = reinterpret_cast<float*>(viewport + ProjectionOffset);
                    if (bDirect3D9)
                        WFPAA::TemporalAA::OnRenderedCamera(view, projection);
                    else
                        WFPAA::TemporalAA11::OnRenderedCamera(view, projection);
                });
            }

            // _DEFERRED_GBUFFER_Z_, stored in sub_6AFC20
            pattern = hook::pattern("68 ? ? ? ? FF D0 81 3D ? ? ? ? E8 03 00 00 8B 0D ? ? ? ? A3");
            if (!pattern.empty())
                ppDepthTarget = *pattern.get_first<void**>(24);

            if (!UpdateViewport || !Perspective || !viewportHooked || !ppDepthTarget)
                WFPAA::TemporalAA11::Log("Hooks: a pattern wasn't found, temporal anti-aliasing won't work");
        };

        FusionFix::onShutdownEvent() += []()
        {
            WFPAA::TemporalAA11::Shutdown();
            WFPAA::TemporalAA::Shutdown();
        };
    }
} AntiAliasingInit;
