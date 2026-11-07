module;

#include <common.hxx>
#include <d3d11_1.h>
#include <dxgi1_6.h>
#include <wrl/client.h>
#include <atomic>
#include <vector>
#include <thread>

export module hdr;

import common;
import settings;
import postfxcommon;

namespace
{
    using Microsoft::WRL::ComPtr;
    IDXGISwapChain* Chain{};
    HWND Window{};
    std::atomic<bool> Direct3D11{}, DisplayHDR{}, Unavailable{};
    std::atomic<float> SdrWhite{ 80.0f };
    uint64_t LastDisplayCheck{};
    HMONITOR DisplayMonitor{};
    ComPtr<IDXGIFactory1> DisplayFactory;
    SafetyHookInline PresentHook, ResizeHook;
    ComPtr<ID3D11Device> Device;
    ComPtr<ID3D11DeviceContext1> Context;
    ComPtr<ID3DDeviceContextState> State;
    ComPtr<ID3D11Texture2D> Copy;
    ComPtr<ID3D11ShaderResourceView> View;
    ComPtr<ID3D11VertexShader> Vertex;
    ComPtr<ID3D11PixelShader> Pixel, CopyPixel;
    ComPtr<ID3D11Buffer> Parameters, CopyParameters;
    ComPtr<ID3D11RenderTargetView> Target;
    ID3D11Texture2D* TargetTexture{};

    void Release()
    {
        Target.Reset();
        TargetTexture = nullptr;
        View.Reset();
        Copy.Reset();
        Parameters.Reset();
        CopyParameters.Reset();
        Vertex.Reset();
        Pixel.Reset();
        CopyPixel.Reset();
        State.Reset();
        Context.Reset();
        Device.Reset();
    }

    // Whether the display of the window and whether any display is in HDR mode (Windows HDR on). The outputs of every
    // adapter count: on a hybrid GPU the game's adapter doesn't own the display.
    struct DisplayState
    {
        bool Window{}, Any{};
    };

    DisplayState ReadDisplays(HWND window)
    {
        DisplayState state;
        DisplayMonitor = MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST);
        if ((!DisplayFactory || !DisplayFactory->IsCurrent()) && FAILED(CreateDXGIFactory1(IID_PPV_ARGS(DisplayFactory.ReleaseAndGetAddressOf()))))
            return state;
        ComPtr<IDXGIAdapter1> adapter;
        for (UINT a = 0; DisplayFactory->EnumAdapters1(a, &adapter) != DXGI_ERROR_NOT_FOUND; ++a)
        {
            ComPtr<IDXGIOutput> output;
            for (UINT o = 0; adapter->EnumOutputs(o, &output) != DXGI_ERROR_NOT_FOUND; ++o)
            {
                ComPtr<IDXGIOutput6> modern;
                DXGI_OUTPUT_DESC1 description{};
                if (FAILED(output.As(&modern)) || FAILED(modern->GetDesc1(&description)) ||
                    description.ColorSpace != DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020)
                    continue;
                state.Any = true;
                state.Window |= description.Monitor == DisplayMonitor;
            }
        }
        return state;
    }

    // Brightness of SDR white that Windows uses on the window's display while HDR is on
    float ReadSdrWhite(HWND window)
    {
        MONITORINFOEXW monitor{};
        monitor.cbSize = sizeof(monitor);
        if (!GetMonitorInfoW(MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST), &monitor))
            return 80.0f;
        UINT32 pathCount{}, modeCount{};
        if (GetDisplayConfigBufferSizes(QDC_ONLY_ACTIVE_PATHS, &pathCount, &modeCount) != ERROR_SUCCESS)
            return 80.0f;
        std::vector<DISPLAYCONFIG_PATH_INFO> paths(pathCount);
        std::vector<DISPLAYCONFIG_MODE_INFO> modes(modeCount);
        if (QueryDisplayConfig(QDC_ONLY_ACTIVE_PATHS, &pathCount, paths.data(), &modeCount, modes.data(), nullptr) != ERROR_SUCCESS)
            return 80.0f;
        for (UINT32 i = 0; i < pathCount; ++i)
        {
            DISPLAYCONFIG_SOURCE_DEVICE_NAME source{};
            source.header = { DISPLAYCONFIG_DEVICE_INFO_GET_SOURCE_NAME, sizeof(source), paths[i].sourceInfo.adapterId, paths[i].sourceInfo.id };
            if (DisplayConfigGetDeviceInfo(&source.header) != ERROR_SUCCESS || wcscmp(source.viewGdiDeviceName, monitor.szDevice))
                continue;
            DISPLAYCONFIG_SDR_WHITE_LEVEL white{};
            white.header = { DISPLAYCONFIG_DEVICE_INFO_GET_SDR_WHITE_LEVEL, sizeof(white), paths[i].targetInfo.adapterId, paths[i].targetInfo.id };
            if (DisplayConfigGetDeviceInfo(&white.header) == ERROR_SUCCESS)
                return white.SDRWhiteLevel * 80.0f / 1000.0f;
        }
        return 80.0f;
    }

    // HDR can be chosen on the DirectX 11 renderer with the game window on an HDR display, when the game started with
    // the scRGB swap chain
    bool Supported()
    {
        return Direct3D11 && DisplayHDR && !Unavailable;
    }

    // The choice stays in effect until the renderer is known: Prepare reads it, and DirectX 9 never calls Prepare
    void ApplyAvailability()
    {
        static std::atomic<bool> registered{};
        if (!registered.exchange(true))
            SettingsPlugin().Availability("MAIN.HDR", [](std::string_view value) { return value == "0" || Supported(); });
        else
            SettingsPlugin().Refresh("MAIN.HDR");
    }

    void CheckDisplay()
    {
        static std::atomic<bool> rendererKnown{};
        if (!Window && ppPostFXDevice && *ppPostFXDevice && !rendererKnown.exchange(true))
            ApplyAvailability();
        const auto now = GetTickCount64();
        if (!Window || now - LastDisplayCheck < 1000)
            return;
        LastDisplayCheck = now;
        // With HDR off the picture follows the desktop's SDR brightness, which can change at any time. Reading it
        // takes long enough to stall a frame, so it is read beside the game.
        static std::atomic<bool> reading{};
        if (Chain && DisplayHDR && !FusionFixSettings.GetInt(PREF_HDR) && !reading.exchange(true))
            std::thread([window = Window] { SdrWhite = ReadSdrWhite(window); reading = false; }).detach();
        // The factory goes stale when the displays change, Windows HDR included
        if (MonitorFromWindow(Window, MONITOR_DEFAULTTONEAREST) == DisplayMonitor && DisplayFactory && DisplayFactory->IsCurrent())
            return;
        const bool hdr = ReadDisplays(Window).Window;
        if (DisplayHDR.exchange(hdr) != hdr)
            SettingsPlugin().Refresh("MAIN.HDR");
    }

    bool Initialize(IDXGISwapChain* chain, ID3D11Texture2D* output)
    {
        D3D11_TEXTURE2D_DESC description{}, existing{};
        output->GetDesc(&description);
        if (Copy)
            Copy->GetDesc(&existing);
        ComPtr<ID3D11Device> device;
        if (FAILED(chain->GetDevice(IID_PPV_ARGS(&device))))
            return false;
        if (Device != device || existing.Width != description.Width || existing.Height != description.Height)
            Release();
        if (Copy)
            return true;
        Device = device;
        ComPtr<ID3D11Device1> modern;
        ComPtr<ID3D11DeviceContext> context;
        Device->GetImmediateContext(&context);
        if (FAILED(Device.As(&modern)) || FAILED(context.As(&Context)))
            return false;
        auto feature = Device->GetFeatureLevel();
        auto flags = (Device->GetCreationFlags() & D3D11_CREATE_DEVICE_SINGLETHREADED) ? D3D11_1_CREATE_DEVICE_CONTEXT_STATE_SINGLETHREADED : 0u;
        if (FAILED(modern->CreateDeviceContextState(flags, &feature, 1, D3D11_SDK_VERSION, __uuidof(ID3D11Device), nullptr, &State)))
            return false;
        const void* code{};
        UINT size{};
        auto module = GetPostFXModuleHandle(&Initialize);
        if (!LoadPostFXResource(module, 300, &code, &size) || FAILED(Device->CreateVertexShader(code, size, nullptr, &Vertex)) ||
            !LoadPostFXResource(module, 320, &code, &size) || FAILED(Device->CreatePixelShader(code, size, nullptr, &Pixel)) ||
            !LoadPostFXResource(module, 321, &code, &size) || FAILED(Device->CreatePixelShader(code, size, nullptr, &CopyPixel)))
            return false;
        D3D11_BUFFER_DESC buffer{};
        buffer.ByteWidth = 16;
        buffer.Usage = D3D11_USAGE_DEFAULT;
        buffer.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
        if (FAILED(Device->CreateBuffer(&buffer, nullptr, &Parameters)) || FAILED(Device->CreateBuffer(&buffer, nullptr, &CopyParameters)))
            return false;
        description.BindFlags = D3D11_BIND_SHADER_RESOURCE;
        description.MiscFlags = description.CPUAccessFlags = 0;
        description.Usage = D3D11_USAGE_DEFAULT;
        if (FAILED(Device->CreateTexture2D(&description, nullptr, &Copy)) || FAILED(Device->CreateShaderResourceView(Copy.Get(), nullptr, &View)))
        {
            Release();
            return false;
        }
        return true;
    }

    void Render(IDXGISwapChain* chain)
    {
        ComPtr<ID3D11Texture2D> output;
        if (FAILED(chain->GetBuffer(0, IID_PPV_ARGS(&output))) || !Initialize(chain, output.Get()))
            return;
        // A flip-model chain returns the same texture for the current buffer every frame
        if (TargetTexture != output.Get())
        {
            Target.Reset();
            if (FAILED(Device->CreateRenderTargetView(output.Get(), nullptr, &Target)))
                return;
            TargetTexture = output.Get();
        }
        const bool enabled = DisplayHDR && FusionFixSettings.GetInt(PREF_HDR) != 0;
        const float white = enabled ? std::clamp(FusionFixSettings.GetFloat(PREF_HDRWHITE), 80.0f, 500.0f) : DisplayHDR ? SdrWhite.load() : 80.0f;
        const float peak = std::max(white, FusionFixSettings.GetFloat(PREF_HDRPEAK));
        float parameters[]{ white / 80.0f, peak / white, enabled ? 1.0f : 0.0f, 0 };
        ComPtr<ID3DDeviceContextState> previous;
        Context->SwapDeviceContextState(State.Get(), &previous);
        Context->ClearState();
        Context->CopyResource(Copy.Get(), output.Get());
        D3D11_TEXTURE2D_DESC description{};
        output->GetDesc(&description);
        D3D11_VIEWPORT viewport{ 0, 0, float(description.Width), float(description.Height), 0, 1 };
        Context->RSSetViewports(1, &viewport);
        Context->OMSetRenderTargets(1, Target.GetAddressOf(), nullptr);
        Context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
        Context->VSSetShader(Vertex.Get(), nullptr, 0);
        Context->PSSetShader(Pixel.Get(), nullptr, 0);
        Context->PSSetShaderResources(0, 1, View.GetAddressOf());
        Context->UpdateSubresource(Parameters.Get(), 0, nullptr, parameters, 0, 0);
        Context->PSSetConstantBuffers(0, 1, Parameters.GetAddressOf());
        Context->Draw(3, 0);
        Context->ClearState();
        Context->SwapDeviceContextState(previous.Get(), nullptr);
    }

    DXGI_FORMAT SdrTarget(DXGI_FORMAT format)
    {
        switch (format)
        {
        case DXGI_FORMAT_R8G8B8A8_TYPELESS:
        case DXGI_FORMAT_R8G8B8A8_UNORM:
        case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
            return DXGI_FORMAT_R8G8B8A8_UNORM;
        case DXGI_FORMAT_B8G8R8A8_TYPELESS:
        case DXGI_FORMAT_B8G8R8A8_UNORM:
        case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
            return DXGI_FORMAT_B8G8R8A8_UNORM;
        default:
            return DXGI_FORMAT_UNKNOWN;
        }
    }

    // What the copy's draw changes on the game's context. Binding a target unbinds it from the stages it's read in, so
    // the shader resources the game had there are kept too.
    struct CopyState
    {
        static constexpr UINT Resources = 16;
        ComPtr<ID3D11RenderTargetView> Targets[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
        ComPtr<ID3D11DepthStencilView> Depth;
        ComPtr<ID3D11BlendState> Blend;
        float BlendFactor[4]{};
        UINT SampleMask{};
        ComPtr<ID3D11DepthStencilState> DepthState;
        UINT StencilRef{};
        ComPtr<ID3D11RasterizerState> Rasterizer;
        D3D11_VIEWPORT Viewports[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE]{};
        UINT ViewportCount = D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
        D3D11_PRIMITIVE_TOPOLOGY Topology{};
        ComPtr<ID3D11InputLayout> Layout;
        ComPtr<ID3D11VertexShader> VertexShader;
        ComPtr<ID3D11HullShader> HullShader;
        ComPtr<ID3D11DomainShader> DomainShader;
        ComPtr<ID3D11GeometryShader> GeometryShader;
        ComPtr<ID3D11PixelShader> PixelShader;
        ComPtr<ID3D11ShaderResourceView> PixelResources[Resources], VertexResources[Resources];
        ComPtr<ID3D11Buffer> PixelConstants;

        template<typename T, size_t N>
        static void Adopt(ComPtr<T> (&out)[N], T* (&raw)[N])
        {
            for (size_t i = 0; i < N; ++i)
                out[i].Attach(raw[i]);
        }

        void Save(ID3D11DeviceContext* context)
        {
            ID3D11RenderTargetView* targets[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT]{};
            context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, targets, &Depth);
            Adopt(Targets, targets);
            context->OMGetBlendState(&Blend, BlendFactor, &SampleMask);
            context->OMGetDepthStencilState(&DepthState, &StencilRef);
            context->RSGetState(&Rasterizer);
            context->RSGetViewports(&ViewportCount, Viewports);
            context->IAGetPrimitiveTopology(&Topology);
            context->IAGetInputLayout(&Layout);
            context->VSGetShader(&VertexShader, nullptr, nullptr);
            context->HSGetShader(&HullShader, nullptr, nullptr);
            context->DSGetShader(&DomainShader, nullptr, nullptr);
            context->GSGetShader(&GeometryShader, nullptr, nullptr);
            context->PSGetShader(&PixelShader, nullptr, nullptr);
            ID3D11ShaderResourceView* pixel[Resources]{};
            ID3D11ShaderResourceView* vertex[Resources]{};
            context->PSGetShaderResources(0, Resources, pixel);
            context->VSGetShaderResources(0, Resources, vertex);
            Adopt(PixelResources, pixel);
            Adopt(VertexResources, vertex);
            context->PSGetConstantBuffers(1, 1, &PixelConstants);
        }

        void Restore(ID3D11DeviceContext* context)
        {
            ID3D11ShaderResourceView* pixel[Resources]{};
            ID3D11ShaderResourceView* vertex[Resources]{};
            for (UINT i = 0; i < Resources; ++i)
            {
                pixel[i] = PixelResources[i].Get();
                vertex[i] = VertexResources[i].Get();
            }
            // The targets first: a resource the game reads may only be bound once it's no longer a target
            ID3D11RenderTargetView* targets[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT]{};
            for (UINT i = 0; i < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT; ++i)
                targets[i] = Targets[i].Get();
            ID3D11ShaderResourceView* none[Resources]{};
            context->PSSetShaderResources(0, Resources, none);
            context->OMSetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, targets, Depth.Get());
            context->PSSetShaderResources(0, Resources, pixel);
            context->VSSetShaderResources(0, Resources, vertex);
            context->OMSetBlendState(Blend.Get(), BlendFactor, SampleMask);
            context->OMSetDepthStencilState(DepthState.Get(), StencilRef);
            context->RSSetState(Rasterizer.Get());
            context->RSSetViewports(ViewportCount, Viewports);
            context->IASetPrimitiveTopology(Topology);
            context->IASetInputLayout(Layout.Get());
            context->VSSetShader(VertexShader.Get(), nullptr, 0);
            context->HSSetShader(HullShader.Get(), nullptr, 0);
            context->DSSetShader(DomainShader.Get(), nullptr, 0);
            context->GSSetShader(GeometryShader.Get(), nullptr, 0);
            context->PSSetShader(PixelShader.Get(), nullptr, 0);
            context->PSSetConstantBuffers(1, 1, PixelConstants.GetAddressOf());
        }
    };

    // The game makes some targets in the back buffer format it asked for and copies the back buffer into them, for
    // example the picture the painkiller flash fades from. A copy between different formats does nothing, so with the
    // scRGB chain the same picture is drawn into them instead. Only copies from the back buffer: other copies between
    // these formats do nothing in the original game either.
    bool CopyToSdr(ID3D11Resource* destination, UINT x, UINT y, ID3D11Resource* source, const D3D11_BOX* box)
    {
        if (!Chain || !CopyPixel || !TargetTexture || source != TargetTexture)
            return false;
        D3D11_RESOURCE_DIMENSION a{}, b{};
        destination->GetType(&a);
        source->GetType(&b);
        if (a != D3D11_RESOURCE_DIMENSION_TEXTURE2D || b != D3D11_RESOURCE_DIMENSION_TEXTURE2D)
            return false;
        D3D11_TEXTURE2D_DESC target{}, picture{};
        static_cast<ID3D11Texture2D*>(destination)->GetDesc(&target);
        static_cast<ID3D11Texture2D*>(source)->GetDesc(&picture);
        const auto format = SdrTarget(target.Format);
        if (picture.Format != DXGI_FORMAT_R16G16B16A16_FLOAT || format == DXGI_FORMAT_UNKNOWN || !(target.BindFlags & D3D11_BIND_RENDER_TARGET) ||
            !(picture.BindFlags & D3D11_BIND_SHADER_RESOURCE) || target.SampleDesc.Count != 1 || picture.SampleDesc.Count != 1)
            return false;
        D3D11_BOX region = box ? *box : D3D11_BOX{ 0, 0, 0, picture.Width, picture.Height, 1 };
        region.right = std::min({ region.right, picture.Width, region.left + (target.Width > x ? target.Width - x : 0) });
        region.bottom = std::min({ region.bottom, picture.Height, region.top + (target.Height > y ? target.Height - y : 0) });
        if (region.right <= region.left || region.bottom <= region.top)
            return true;
        ComPtr<ID3D11RenderTargetView> output;
        ComPtr<ID3D11ShaderResourceView> input;
        D3D11_RENDER_TARGET_VIEW_DESC view{ format, D3D11_RTV_DIMENSION_TEXTURE2D };
        if (FAILED(Device->CreateRenderTargetView(destination, &view, &output)) || FAILED(Device->CreateShaderResourceView(source, nullptr, &input)))
            return false;
        const int offset[4]{ int(region.left) - int(x), int(region.top) - int(y), 0, 0 };
        // The copy comes in the middle of the game's frame: only the state the draw changes is put back. Swapping the
        // whole context state there leaves characters unlit now and then.
        CopyState saved;
        saved.Save(Context.Get());
        D3D11_VIEWPORT viewport{ float(x), float(y), float(region.right - region.left), float(region.bottom - region.top), 0, 1 };
        Context->RSSetViewports(1, &viewport);
        Context->RSSetState(nullptr);
        Context->OMSetRenderTargets(1, output.GetAddressOf(), nullptr);
        Context->OMSetBlendState(nullptr, nullptr, 0xFFFFFFFF);
        Context->OMSetDepthStencilState(nullptr, 0);
        Context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
        Context->IASetInputLayout(nullptr);
        Context->VSSetShader(Vertex.Get(), nullptr, 0);
        Context->HSSetShader(nullptr, nullptr, 0);
        Context->DSSetShader(nullptr, nullptr, 0);
        Context->GSSetShader(nullptr, nullptr, 0);
        Context->PSSetShader(CopyPixel.Get(), nullptr, 0);
        Context->PSSetShaderResources(0, 1, input.GetAddressOf());
        Context->UpdateSubresource(CopyParameters.Get(), 0, nullptr, offset, 0, 0);
        Context->PSSetConstantBuffers(1, 1, CopyParameters.GetAddressOf());
        Context->Draw(3, 0);
        saved.Restore(Context.Get());
        return true;
    }

    HRESULT STDMETHODCALLTYPE Present(IDXGISwapChain* chain, UINT interval, UINT flags)
    {
        ComPtr<ID3D11RenderTargetView> targets[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
        ID3D11RenderTargetView* views[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT]{};
        ComPtr<ID3D11DepthStencilView> depth;
        const bool render = chain == Chain && !(flags & DXGI_PRESENT_TEST);
        if (render)
        {
            Render(chain);
            if (Context)
            {
                Context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, views, &depth);
                for (UINT i = 0; i < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT; ++i)
                    targets[i].Attach(views[i]);
            }
        }
        auto result = PresentHook.stdcall<HRESULT>(chain, interval, flags);
        if (render && Context && SUCCEEDED(result))
            Context->OMSetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, views, depth.Get());
        return result;
    }

    HRESULT STDMETHODCALLTYPE Resize(IDXGISwapChain* chain, UINT count, UINT width, UINT height, DXGI_FORMAT format, UINT flags)
    {
        if (chain == Chain)
        {
            Release();
            format = DXGI_FORMAT_R16G16B16A16_FLOAT;
            count = std::max(count, 2u);
        }
        return ResizeHook.stdcall<HRESULT>(chain, count, width, height, format, flags);
    }
}

export namespace HDR
{
    void CheckDisplay()
    {
        ::CheckDisplay();
    }

    bool CopyToSdr(ID3D11Resource* destination, UINT x, UINT y, ID3D11Resource* source, const D3D11_BOX* box)
    {
        return ::CopyToSdr(destination, x, y, source, box);
    }

    bool Active()
    {
        return Chain && DisplayHDR && FusionFixSettings.GetInt(PREF_HDR);
    }

    void Shutdown()
    {
        Chain = nullptr;
        Release();
        DisplayFactory.Reset();
    }

    bool Prepare(const D3D_FEATURE_LEVEL* levels, UINT count, DXGI_SWAP_CHAIN_DESC& description)
    {
        Window = description.OutputWindow;
        Direct3D11 = !count || levels[0] >= D3D_FEATURE_LEVEL_11_0;
        const auto displays = ReadDisplays(Window);
        DisplayHDR = displays.Window;
        LastDisplayCheck = GetTickCount64();
        // Any HDR display: the window can start on another display and move, the output follows it. The scRGB chain
        // is made whatever the setting, so that switching HDR applies at once.
        Unavailable = !Direct3D11 || !displays.Any || description.SampleDesc.Count != 1;
        ApplyAvailability();
        if (Unavailable)
            return false;
        SdrWhite = ReadSdrWhite(Window);
        description.BufferDesc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
        description.BufferCount = std::max(2u, description.BufferCount);
        description.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
        return true;
    }

    bool Attach(IDXGISwapChain* chain)
    {
        ComPtr<ID3D11Device> device;
        if (FAILED(chain->GetDevice(IID_PPV_ARGS(&device))) || device->GetFeatureLevel() < D3D_FEATURE_LEVEL_11_0)
        {
            Unavailable = true;
            ApplyAvailability();
            return false;
        }
        ComPtr<IDXGISwapChain3> modern;
        UINT support{};
        if (FAILED(chain->QueryInterface(IID_PPV_ARGS(&modern))) ||
            FAILED(modern->CheckColorSpaceSupport(DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709, &support)) ||
            !(support & DXGI_SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG_PRESENT) ||
            FAILED(modern->SetColorSpace1(DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709)))
        {
            Unavailable = true;
            ApplyAvailability();
            return false;
        }
        Chain = chain;
        DXGI_SWAP_CHAIN_DESC description{};
        chain->GetDesc(&description);
        Window = description.OutputWindow;
        if (!PresentHook)
        {
            auto table = *reinterpret_cast<void***>(chain);
            PresentHook = safetyhook::create_inline(table[8], Present);
            ResizeHook = safetyhook::create_inline(table[13], Resize);
        }
        return true;
    }
}
