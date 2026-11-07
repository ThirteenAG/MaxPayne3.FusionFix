module;

#include <common.hxx>
#include <d3d11_1.h>
#include <dxgi1_6.h>
#include <wrl/client.h>
#include <atomic>

export module hdr;

import common;
import settings;
import postfxcommon;

namespace
{
    using Microsoft::WRL::ComPtr;
    IDXGISwapChain* Chain{};
    HWND Window{};
    std::atomic<bool> Direct3D11{}, DisplayHDR{};
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
    ComPtr<ID3D11PixelShader> Pixel;
    ComPtr<ID3D11Buffer> Parameters;

    void Release()
    {
        View.Reset();
        Copy.Reset();
        Parameters.Reset();
        Vertex.Reset();
        Pixel.Reset();
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

    // HDR can be chosen on the DirectX 11 renderer with the game window on an HDR display
    bool Supported()
    {
        return Direct3D11 && DisplayHDR;
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
            !LoadPostFXResource(module, 320, &code, &size) || FAILED(Device->CreatePixelShader(code, size, nullptr, &Pixel)))
            return false;
        D3D11_BUFFER_DESC buffer{};
        buffer.ByteWidth = 16;
        buffer.Usage = D3D11_USAGE_DEFAULT;
        buffer.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
        if (FAILED(Device->CreateBuffer(&buffer, nullptr, &Parameters)))
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
        ComPtr<ID3D11RenderTargetView> target;
        if (FAILED(Device->CreateRenderTargetView(output.Get(), nullptr, &target)))
            return;
        const bool enabled = DisplayHDR && FusionFixSettings.GetInt(PREF_HDR) != 0;
        const float white = enabled ? std::clamp(FusionFixSettings.GetFloat(PREF_HDRWHITE), 80.0f, 500.0f) : 80.0f;
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
        Context->OMSetRenderTargets(1, target.GetAddressOf(), nullptr);
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
        // The player's choice, before availability can change the value in effect
        static const bool wanted = FusionFixSettings.GetInt(PREF_HDR) != 0;
        Window = description.OutputWindow;
        Direct3D11 = !count || levels[0] >= D3D_FEATURE_LEVEL_11_0;
        const auto displays = ReadDisplays(Window);
        DisplayHDR = displays.Window;
        LastDisplayCheck = GetTickCount64();
        ApplyAvailability();
        // Any HDR display: the window can start on another display and move, the output follows it
        if (!wanted || !Direct3D11 || !displays.Any || description.SampleDesc.Count != 1)
            return false;
        description.BufferDesc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
        description.BufferCount = std::max(2u, description.BufferCount);
        description.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
        return true;
    }

    bool Attach(IDXGISwapChain* chain)
    {
        ComPtr<ID3D11Device> device;
        if (FAILED(chain->GetDevice(IID_PPV_ARGS(&device))) || device->GetFeatureLevel() < D3D_FEATURE_LEVEL_11_0)
            return false;
        ComPtr<IDXGISwapChain3> modern;
        UINT support{};
        if (FAILED(chain->QueryInterface(IID_PPV_ARGS(&modern))) ||
            FAILED(modern->CheckColorSpaceSupport(DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709, &support)) ||
            !(support & DXGI_SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG_PRESENT) ||
            FAILED(modern->SetColorSpace1(DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709)))
            return false;
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
