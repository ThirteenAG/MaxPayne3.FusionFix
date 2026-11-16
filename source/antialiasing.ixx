module;

#include <common.hxx>
#include <aa/Upscaler.hpp>
#include <wrl/client.h>

export module antialiasing;

import common;
import comvars;
import settings;
import postfxcommon;
import temporal;
import menu;

namespace
{
    using Microsoft::WRL::ComPtr;
    using Matrix = Antialiasing::Matrix;
    using Jitter = Antialiasing::Jitter;
    using Backend = Antialiasing::Backend;
    namespace Bridge = Antialiasing::detail;

    enum Mode { Off, SMAA, SMAAEdges, TAA, DLAA, FSR };

    struct Camera
    {
        Matrix View, Projection, ViewProjection;
        Jitter Offset;
        uint64_t Serial{}, Time{};
        UINT Width{}, Height{};
        float Near{}, Far{}, Fov{};
        bool Valid{};
    };

    std::array<Camera, 16> Cameras;
    size_t NextCamera{};
    std::mutex CameraMutex;
    std::atomic<UINT> Width{}, Height{};
    std::atomic<bool> DepthReady{}, Ready{};
    std::atomic<uint32_t> AvailabilityGeneration{};
    std::atomic<int> SelectedMode{};
    uint64_t RenderSerial{}, LastResolve{};
    Camera Current, Previous;
    bool Matched{}, LastBridged{}, SceneResolved{};
    int LastMode{};
    void** DepthTarget{};
    thread_local bool GameCamera{};
    struct RenderViewport
    {
        uint8_t* Viewport;
        float Shift[2];
    };
    RenderViewport JitteredRenderViewport{};
    void* (__fastcall* Perspective)(uint8_t*, void*, float, float, float, float){};
    int (__fastcall* UpdateViewport)(void*, void*, void*){};

    struct Parameters
    {
        float Pixel[4];
        float Temporal[4];
        float Camera[4];
        float Jitter[4];
        float PreviousClip[16];
    };

    Parameters Constants;
    Jitter FrameOffset, SceneOffset;
    uint32_t* ViewportSlot{};
    uint32_t ViewportOffset{};

    // The game's MSAA, also when it's chosen on the Graphics page and not applied yet: the temporal modes need it off
    bool GameMSAA()
    {
        const uint32_t samples = nMSAASamples;
        return samples > 1 || nMSAAChoice > 0;
    }

    bool SameLens(const float* projection, const Matrix& camera)
    {
        return std::abs(projection[0] - camera.m[0][0]) <= 0.001 * std::abs(camera.m[0][0]) &&
            std::abs(projection[5] - camera.m[1][1]) <= 0.001 * std::abs(camera.m[1][1]);
    }

    void MatchCamera(uint8_t* viewport)
    {
        if (SceneResolved || !Ready || !TemporalMotion::IsReady())
            return;
        auto projection = reinterpret_cast<float*>(viewport + 0x1C0);
        if (projection[11] == 0)
            return;
        UINT width{}, height{};
        {
            std::lock_guard lock(CameraMutex);
            for (auto& camera : Cameras)
                if (camera.Valid && SameLens(projection, camera.Projection))
                {
                    width = camera.Width;
                    height = camera.Height;
                    break;
                }
        }
        if (!width || !height)
            return;
        auto shift = reinterpret_cast<float*>(viewport + 0x358);
        JitteredRenderViewport = { viewport, { shift[0], shift[1] } };
        shift[0] += 2 * FrameOffset.X / width * projection[11];
        shift[1] -= 2 * FrameOffset.Y / height * projection[11];
        auto parameters = reinterpret_cast<float*>(viewport + 0x338);
        Perspective(viewport, nullptr, parameters[0], parameters[1], parameters[2], parameters[3]);
    }

    void SceneViewport()
    {
        if (SceneResolved || Matched || !Ready || !Width || !Height)
            return;
        auto storage = reinterpret_cast<uint8_t**>(__readfsdword(0x2C))[*ViewportSlot];
        auto viewport = *reinterpret_cast<uint8_t**>(storage + ViewportOffset);
        if (!viewport || reinterpret_cast<float*>(viewport + 0x1C0)[11] == 0)
            return;
        auto parameters = reinterpret_cast<float*>(viewport + 0x338);
        Camera camera;
        camera.Width = Width;
        camera.Height = Height;
        camera.View = Matrix::From(reinterpret_cast<float*>(viewport + 0x180));
        camera.Projection = Matrix::From(reinterpret_cast<float*>(viewport + 0x1C0));
        bool jittered = JitteredRenderViewport.Viewport == viewport;
        if (jittered)
        {
            camera.Projection.m[2][0] = JitteredRenderViewport.Shift[0];
            camera.Projection.m[2][1] = JitteredRenderViewport.Shift[1];
        }
        camera.ViewProjection = camera.View * camera.Projection;
        camera.Near = parameters[2];
        camera.Far = parameters[3];
        camera.Fov = static_cast<float>(2 * std::atan(1.0 / std::abs(camera.Projection.m[1][1])));
        camera.Valid = camera.Near > 0 && camera.Far > camera.Near;
        camera.Offset = jittered ? FrameOffset : Jitter{};
        camera.Serial = RenderSerial + 1;
        camera.Time = GetTickCount64();
        Current = camera;
        Matched = true;
        TemporalMotion::SetPixelParameters(1.0f / camera.Width, 1.0f / camera.Height,
            (Current.Offset.X - SceneOffset.X) / camera.Width, (Current.Offset.Y - SceneOffset.Y) / camera.Height);
    }

    void* __fastcall PerspectiveHook(uint8_t* viewport, void* edx, float fov, float aspect, float nearClip, float farClip)
    {
        auto result = Perspective(viewport, edx, fov, aspect, nearClip, farClip);
        if (!GameCamera || SelectedMode < TAA || !Ready || !TemporalMotion::IsReady())
            return result;
        Camera camera;
        camera.Width = Width;
        camera.Height = Height;
        if (!camera.Width || !camera.Height)
            return result;
        camera.View = Matrix::From(reinterpret_cast<float*>(viewport + 0x180));
        camera.Projection = Matrix::From(reinterpret_cast<float*>(viewport + 0x1C0));
        camera.ViewProjection = camera.View * camera.Projection;
        camera.Near = nearClip;
        camera.Far = farClip;
        camera.Fov = static_cast<float>(2 * std::atan(1.0 / std::abs(camera.Projection.m[1][1])));
        camera.Valid = nearClip > 0 && farClip > nearClip;
        {
            std::lock_guard lock(CameraMutex);
            Cameras[NextCamera] = camera;
            NextCamera = (NextCamera + 1) % Cameras.size();
        }
        return result;
    }

    int __fastcall CameraViewport(void* viewport, void* edx, void* frame)
    {
        GameCamera = true;
        auto result = UpdateViewport(viewport, edx, frame);
        GameCamera = false;
        return result;
    }

    void RestoreViewport()
    {
        auto entry = std::exchange(JitteredRenderViewport, {});
        if (!entry.Viewport)
            return;
        auto shift = reinterpret_cast<float*>(entry.Viewport + 0x358);
        shift[0] = entry.Shift[0];
        shift[1] = entry.Shift[1];
        auto parameters = reinterpret_cast<float*>(entry.Viewport + 0x338);
        Perspective(entry.Viewport, nullptr, parameters[0], parameters[1], parameters[2], parameters[3]);
    }

    bool ValidHistory(int mode)
    {
        if (!Previous.Valid || LastResolve + 1 != RenderSerial || LastMode != mode || Current.Width != Previous.Width ||
            Current.Height != Previous.Height || Current.Time < Previous.Time || Current.Time - Previous.Time > 250)
            return false;
        auto current = Current.View.Inverse();
        auto previous = Previous.View.Inverse();
        double distance{}, direction{};
        for (size_t i = 0; i < 3; ++i)
        {
            auto difference = current.m[3][i] - previous.m[3][i];
            distance += difference * difference;
            direction += current.m[2][i] * previous.m[2][i];
        }
        return distance < 625 && direction > 0.5 && std::abs(Current.Projection.m[0][0] / Previous.Projection.m[0][0] - 1) < 0.1;
    }

    void SetConstants(bool history)
    {
        Constants = {};
        Constants.Pixel[0] = 1.0f / Current.Width;
        Constants.Pixel[1] = 1.0f / Current.Height;
        Constants.Pixel[2] = 0;
        Constants.Pixel[3] = 0;
        Constants.Temporal[0] = 0.05f;
        Constants.Temporal[1] = 0.2f;
        Constants.Temporal[2] = 1.25f;
        Constants.Temporal[3] = history ? 1.0f : 0;
        Constants.Camera[0] = Current.Near;
        Constants.Camera[1] = Current.Far;
        Constants.Camera[2] = 0.1f;
        Constants.Camera[3] = FusionFixSettings.GetFloat(PREF_AASHARPNESS) / 100.0f;
        Constants.Jitter[0] = Current.Offset.X / Current.Width;
        Constants.Jitter[1] = Current.Offset.Y / Current.Height;
        (Current.ViewProjection.Inverse() * (Previous.Valid ? Previous.ViewProjection : Current.ViewProjection)).To(Constants.PreviousClip);
    }

    bool Program(UINT id, const void** code, UINT* size)
    {
        return LoadPostFXResource(GetPostFXModuleHandle(&Program), id, code, size);
    }

    DXGI_FORMAT Typed(DXGI_FORMAT format)
    {
        switch (format)
        {
        case DXGI_FORMAT_R16G16B16A16_TYPELESS: return DXGI_FORMAT_R16G16B16A16_FLOAT;
        case DXGI_FORMAT_R32G32B32A32_TYPELESS: return DXGI_FORMAT_R32G32B32A32_FLOAT;
        case DXGI_FORMAT_R8G8B8A8_TYPELESS: return DXGI_FORMAT_R8G8B8A8_UNORM;
        case DXGI_FORMAT_R10G10B10A2_TYPELESS: return DXGI_FORMAT_R10G10B10A2_UNORM;
        default: return format;
        }
    }

    struct Target11
    {
        ComPtr<ID3D11Texture2D> Texture;
        ComPtr<ID3D11RenderTargetView> Target;
        ComPtr<ID3D11ShaderResourceView> View;
    };

    struct Renderer11
    {
        ComPtr<ID3D11Device> Device;
        ComPtr<ID3D11DeviceContext1> Context;
        ComPtr<ID3DDeviceContextState> State;
        ComPtr<ID3D11VertexShader> Vertex;
        std::array<ComPtr<ID3D11PixelShader>, 6> Shaders;
        ComPtr<ID3D11Buffer> Parameters;
        ComPtr<ID3D11SamplerState> Point, Linear;
        Target11 Scene, History[2], Depth[2];
        UINT Width{}, Height{}, Index{};
        DXGI_FORMAT Format{};
        bool Complete{};

        bool MakeTarget(Target11& target, DXGI_FORMAT format)
        {
            D3D11_TEXTURE2D_DESC description{};
            description.Width = Width;
            description.Height = Height;
            description.MipLevels = description.ArraySize = 1;
            description.Format = format;
            description.SampleDesc.Count = 1;
            description.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
            return SUCCEEDED(Device->CreateTexture2D(&description, nullptr, &target.Texture)) &&
                SUCCEEDED(Device->CreateRenderTargetView(target.Texture.Get(), nullptr, &target.Target)) &&
                SUCCEEDED(Device->CreateShaderResourceView(target.Texture.Get(), nullptr, &target.View));
        }

        bool Initialize(ID3D11Device* device, UINT width, UINT height, DXGI_FORMAT format)
        {
            if (!Complete || Device.Get() != device || Width != width || Height != height || Format != format)
                *this = {};
            if (!Device)
            {
                Device = device;
                Width = width;
                Height = height;
                Format = format;
                ComPtr<ID3D11Device1> modern;
                ComPtr<ID3D11DeviceContext> context;
                Device->GetImmediateContext(&context);
                if (FAILED(Device.As(&modern)) || FAILED(context.As(&Context)))
                    return false;
                auto feature = device->GetFeatureLevel();
                auto flags = (device->GetCreationFlags() & D3D11_CREATE_DEVICE_SINGLETHREADED) ? D3D11_1_CREATE_DEVICE_CONTEXT_STATE_SINGLETHREADED : 0u;
                if (FAILED(modern->CreateDeviceContextState(flags, &feature, 1, D3D11_SDK_VERSION, __uuidof(ID3D11Device), nullptr, &State)))
                    return false;
                const void* code{};
                UINT size{};
                if (!Program(300, &code, &size) || FAILED(Device->CreateVertexShader(code, size, nullptr, &Vertex)))
                    return false;
                for (UINT i = 0; i < Shaders.size(); ++i)
                    if (!Program(311 + i, &code, &size) || FAILED(Device->CreatePixelShader(code, size, nullptr, &Shaders[i])))
                        return false;
                D3D11_BUFFER_DESC buffer{};
                buffer.ByteWidth = sizeof(Constants);
                buffer.Usage = D3D11_USAGE_DEFAULT;
                buffer.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
                if (FAILED(Device->CreateBuffer(&buffer, nullptr, &Parameters)))
                    return false;
                D3D11_SAMPLER_DESC sampler{};
                sampler.AddressU = sampler.AddressV = sampler.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
                sampler.MaxLOD = D3D11_FLOAT32_MAX;
                sampler.Filter = D3D11_FILTER_MIN_MAG_MIP_POINT;
                if (FAILED(Device->CreateSamplerState(&sampler, &Point)))
                    return false;
                sampler.Filter = D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT;
                if (FAILED(Device->CreateSamplerState(&sampler, &Linear)))
                    return false;
                if (!MakeTarget(Scene, Typed(Format)) || !MakeTarget(History[0], DXGI_FORMAT_R16G16B16A16_FLOAT) ||
                    !MakeTarget(History[1], DXGI_FORMAT_R16G16B16A16_FLOAT) || !MakeTarget(Depth[0], DXGI_FORMAT_R32_FLOAT) ||
                    !MakeTarget(Depth[1], DXGI_FORMAT_R32_FLOAT))
                    return false;
                Complete = true;
            }
            return State && History[1].Texture;
        }

        ComPtr<ID3D11ShaderResourceView> View(ID3D11Texture2D* texture, bool depth)
        {
            if (!texture)
                return {};
            D3D11_TEXTURE2D_DESC description{};
            texture->GetDesc(&description);
            if (description.SampleDesc.Count != 1)
                return {};
            D3D11_SHADER_RESOURCE_VIEW_DESC view{};
            view.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
            view.Texture2D.MipLevels = 1;
            view.Format = description.Format;
            if (!depth)
                view.Format = Typed(view.Format);
            if (depth)
            {
                if (view.Format == DXGI_FORMAT_R24G8_TYPELESS)
                    view.Format = DXGI_FORMAT_R24_UNORM_X8_TYPELESS;
                else if (view.Format == DXGI_FORMAT_R32G8X24_TYPELESS)
                    view.Format = DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS;
                else if (view.Format == DXGI_FORMAT_R32_TYPELESS)
                    view.Format = DXGI_FORMAT_R32_FLOAT;
            }
            ComPtr<ID3D11ShaderResourceView> result;
            Device->CreateShaderResourceView(texture, &view, &result);
            return result;
        }

        void Pass(ID3D11RenderTargetView* output, size_t shader, ID3D11ShaderResourceView* scene, ID3D11ShaderResourceView* motion,
            ID3D11ShaderResourceView* depth, ID3D11ShaderResourceView* history, ID3D11ShaderResourceView* previousDepth,
            ID3D11ShaderResourceView* original = nullptr)
        {
            ID3D11ShaderResourceView* inputs[]{ scene, motion, depth, history, previousDepth, original };
            ID3D11ShaderResourceView* empty[std::size(inputs)]{};
            Context->PSSetShaderResources(0, UINT(std::size(empty)), empty);
            Context->OMSetRenderTargets(1, &output, nullptr);
            Context->PSSetShaderResources(0, UINT(std::size(inputs)), inputs);
            Context->PSSetShader(Shaders[shader].Get(), nullptr, 0);
            Context->Draw(3, 0);
            Context->PSSetShaderResources(0, UINT(std::size(empty)), empty);
        }

        bool Render(ID3D11Texture2D* output, ID3D11Texture2D* depth, ID3D11Texture2D* motion, int mode, bool valid)
        {
            auto depthView = View(depth, true);
            auto motionView = View(motion, false);
            ComPtr<ID3D11RenderTargetView> outputView;
            D3D11_TEXTURE2D_DESC outputDescription{};
            output->GetDesc(&outputDescription);
            D3D11_RENDER_TARGET_VIEW_DESC target{ Typed(outputDescription.Format), D3D11_RTV_DIMENSION_TEXTURE2D };
            if (!depthView || !motionView || FAILED(Device->CreateRenderTargetView(output, &target, &outputView)))
                return false;
            ComPtr<ID3DDeviceContextState> previousState;
            Context->SwapDeviceContextState(State.Get(), &previousState);
            Context->CopyResource(Scene.Texture.Get(), output);
            D3D11_VIEWPORT viewport{ 0, 0, static_cast<float>(Width), static_cast<float>(Height), 0, 1 };
            Context->RSSetViewports(1, &viewport);
            Context->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
            Context->VSSetShader(Vertex.Get(), nullptr, 0);
            Context->UpdateSubresource(Parameters.Get(), 0, nullptr, &Constants, 0, 0);
            Context->PSSetConstantBuffers(0, 1, Parameters.GetAddressOf());
            ID3D11SamplerState* samplers[]{ Point.Get(), Linear.Get() };
            Context->PSSetSamplers(0, 2, samplers);
            bool bridged{};
            auto& upscaler = Bridge::TheUpscaler11();
            if (mode == DLAA || mode == FSR)
            {
                Bridge::Config().LowDynamicRange = mode == DLAA;
                Bridge::UpscalerFrame11 frame;
                frame.Width = Width;
                frame.Height = Height;
                frame.JitterPixels = Current.Offset;
                frame.CameraNear = Current.Near;
                frame.CameraFar = Current.Far;
                frame.CameraFovY = Current.Fov;
                frame.FrameTimeMs = Previous.Valid ? std::clamp(static_cast<float>(Current.Time - Previous.Time), 1.0f, 100.0f) : 16.6f;
                frame.Reset = !valid;
                if (upscaler.Prepare(mode == DLAA ? Backend::DLSS : Backend::FSR, frame))
                {
                    // The hub's inputs are drawn straight into the textures it shares
                    auto& shared = upscaler.bridge.targets;
                    Constants.Pixel[2] = mode == DLAA ? 1.0f : 0.0f;
                    Context->UpdateSubresource(Parameters.Get(), 0, nullptr, &Constants, 0, 0);
                    Pass(shared[size_t(Bridge::Protocol::Texture::Color)], 3, Scene.View.Get(), nullptr, nullptr, nullptr, nullptr);
                    Pass(shared[size_t(Bridge::Protocol::Texture::Depth)], 2, nullptr, nullptr, depthView.Get(), nullptr, nullptr);
                    Pass(shared[size_t(Bridge::Protocol::Texture::Motion)], 1, nullptr, motionView.Get(), depthView.Get(), nullptr, nullptr);
                    bridged = upscaler.Evaluate(frame);
                }
            }
            if (!bridged)
            {
                Constants.Temporal[3] = valid && !LastBridged ? 1.0f : 0;
                Context->UpdateSubresource(Parameters.Get(), 0, nullptr, &Constants, 0, 0);
                Pass(History[Index].Target.Get(), 0, Scene.View.Get(), motionView.Get(), depthView.Get(), History[Index ^ 1].View.Get(), Depth[Index ^ 1].View.Get());
            }
            Constants.Pixel[2] = bridged && mode == DLAA ? 1.0f : 0.0f;
            Context->UpdateSubresource(Parameters.Get(), 0, nullptr, &Constants, 0, 0);
            Pass(outputView.Get(), 4, bridged ? upscaler.bridge.output : History[Index].View.Get(), nullptr, nullptr, nullptr, nullptr, Scene.View.Get());
            Pass(Depth[Index].Target.Get(), 5, nullptr, nullptr, depthView.Get(), nullptr, nullptr);
            Context->SwapDeviceContextState(previousState.Get(), nullptr);
            LastBridged = bridged;
            Index ^= 1;
            return true;
        }
    } Modern;

    IUnknown* DepthTexture()
    {
        auto target = DepthTarget ? *DepthTarget : nullptr;
        return target ? *reinterpret_cast<IUnknown**>(static_cast<uint8_t*>(target) + 0x38) : nullptr;
    }

    void ChangeReady(bool ready)
    {
        if (Ready.exchange(ready) != ready)
            ++AvailabilityGeneration;
    }

    void Render11(int mode, bool resolve)
    {
        ComPtr<IDXGISwapChain> swapChain;
        auto object = ppPostFXSwapChain ? *ppPostFXSwapChain : nullptr;
        if (!object || FAILED(object->QueryInterface(IID_PPV_ARGS(&swapChain))))
        {
            ChangeReady(false);
            return;
        }
        ComPtr<ID3D11Device> device;
        ComPtr<ID3D11Texture2D> output, depth, motion;
        output.Attach(TemporalMotion::AcquireSceneTexture11());
        if (!output || FAILED(swapChain->GetDevice(IID_PPV_ARGS(&device))))
            return;
        if (device->GetFeatureLevel() < D3D_FEATURE_LEVEL_11_0 || FAILED(device->GetDeviceRemovedReason()))
        {
            ChangeReady(false);
            return;
        }
        Bridge::TheUpscaler11().Update(device.Get());
        D3D11_TEXTURE2D_DESC description{};
        output->GetDesc(&description);
        Width = description.Width;
        Height = description.Height;
        auto texture = DepthTexture();
        if (texture)
            texture->QueryInterface(IID_PPV_ARGS(&depth));
        D3D11_TEXTURE2D_DESC depthDescription{};
        if (depth)
            depth->GetDesc(&depthDescription);
        DepthReady = depth && (depthDescription.BindFlags & D3D11_BIND_SHADER_RESOURCE) &&
            depthDescription.SampleDesc.Count == 1 && description.SampleDesc.Count == 1;
        ChangeReady(DepthReady && TemporalMotion::IsReady());
        if (!resolve || mode < TAA || !Ready || !Matched || Current.Serial == Previous.Serial)
            return;
        motion.Attach(TemporalMotion::AcquireTexture11());
        if (!motion || !Modern.Initialize(device.Get(), description.Width, description.Height, description.Format))
            return;
        auto valid = ValidHistory(mode);
        SetConstants(valid);
        if (Modern.Render(output.Get(), depth.Get(), motion.Get(), mode, valid))
        {
            Previous = Current;
            LastResolve = RenderSerial;
            LastMode = mode;
        }
    }
}

export namespace AntiAliasing
{
    int SmaaMode()
    {
        auto value = FusionFixSettings.GetInt(PREF_ANTIALIASING);
        return value == SMAA || value == SMAAEdges ? value : 0;
    }

    void EndFrame()
    {
        if (!SceneResolved)
            ++RenderSerial;
        auto mode = FusionFixSettings.GetInt(PREF_ANTIALIASING);
        SelectedMode = mode;
        TemporalMotion::SetEnabled(mode >= TAA && Ready);
        Render11(mode, false);
        RestoreViewport();
        TemporalMotion::SetEnabled(mode >= TAA && Ready);
        if (RenderSerial <= 2 || RenderSerial % 120 == 0)
            Bridge::Log("Temporal frame %llu: mode %d, ready %d, camera %d, resolved %d", RenderSerial,
                mode, Ready.load(), Matched, LastResolve == RenderSerial);
        TemporalMotion::EndFrame();
        SceneOffset = Matched ? Current.Offset : Jitter{};
        Matched = false;
        SceneResolved = false;
        auto index = static_cast<uint32_t>((RenderSerial + 1) % (mode == DLAA ? 32 : 16)) + 1;
        FrameOffset = { Antialiasing::Halton(index, 2) - 0.5f, Antialiasing::Halton(index, 3) - 0.5f };
        if (mode < TAA)
        {
            Previous = {};
            LastBridged = false;
        }
    }

    void OnResize()
    {
        Modern = {};
        Previous = {};
        ChangeReady(false);
        TemporalMotion::OnLostDevice();
    }

    void OnLostDevice()
    {
        OnResize();
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
            auto& configuration = Bridge::Config();
            configuration.BridgeName = L"Local\\" + name + L".Upscaler";
            configuration.ClientName = "MaxPayne3.FusionFix";
            configuration.LowDynamicRange = true;
#ifdef _DEBUG
            configuration.Log = GetThisModulePath() / (name + L".AntiAliasing.log");
            configuration.HubLog = GetThisModulePath() / (name + L".Upscaler.log");
#endif
            TemporalMotion::Initialize();
            TemporalMotion::SetResolveCallback([]
            {
                if (SceneResolved)
                    return;
                SceneResolved = true;
                ++RenderSerial;
                Render11(FusionFixSettings.GetInt(PREF_ANTIALIASING), true);
            });
            nMSAASamples.SetAddress(*hook::get_pattern<uint32_t*>("A1 ? ? ? ? 3B C3 74 20 83 F8 01", 1));
            SettingsPlugin().Availability("MAIN.AntiAliasing", [](std::string_view value)
            {
                if (value == "3")
                    return Ready && !GameMSAA();
                if (value == "4")
                    return Ready && !GameMSAA() && Bridge::TheUpscaler11().IsAvailable(Backend::DLSS);
                if (value == "5")
                    return Ready && !GameMSAA() && Bridge::TheUpscaler11().IsAvailable(Backend::FSR);
                return true;
            }, []
            {
                return GameMSAA() ? FusionFixText("antialiasing.msaa") : std::string();
            });
            static auto refresh = []()
            {
                static uint32_t generation = UINT32_MAX;
                auto current = AvailabilityGeneration.load() + Bridge::TheUpscaler11().generation.load() + (GameMSAA() ? 0x80000000u : 0);
                if (generation != current)
                {
                    generation = current;
                    SettingsPlugin().Refresh("MAIN.AntiAliasing");
                }
            };
            FusionFix::onGameProcessEvent() += refresh;
            FusionFix::onMenuDrawingEvent() += refresh;
            auto pattern = hook::pattern("56 8B CB 89 83 A0 05 00 00 E8");
            UpdateViewport = injector::MakeCALL(pattern.get_first(9), CameraViewport, true).get();
            pattern = hook::pattern("D9 46 54 D9 5C 24 08 D9 5C 24 04 D9 46 50 D9 1C 24 E8");
            Perspective = injector::MakeCALL(pattern.get_first(17), PerspectiveHook, true).get();
            pattern = hook::pattern("80 B9 80 04 00 00 00 56 74 13 6A 01 6A 01 6A 00 E8");
            static auto viewport = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& registers)
            {
                auto command = reinterpret_cast<uint8_t*>(registers.ecx);
                RestoreViewport();
                if (!command[0x480] && SelectedMode >= TAA)
                    MatchCamera(command + 16);
            });
            // The current viewport is a thread-local whose offset in the TLS block differs between builds
            pattern = hook::pattern("8B 35 ? ? ? ? 8B 0C B0 57 8B B9 ? ? 00 00 75 14");
            ViewportSlot = *pattern.get_first<uint32_t*>(2);
            ViewportOffset = *pattern.get_first<uint32_t>(12);
            TemporalMotion::SetSceneCallback(SceneViewport);
            pattern = hook::pattern("68 ? ? ? ? FF D0 81 3D ? ? ? ? E8 03 00 00 8B 0D ? ? ? ? A3");
            DepthTarget = *pattern.get_first<void**>(24);
        };
        FusionFix::onShutdownEvent() += []()
        {
            AntiAliasing::OnLostDevice();
            AntiAliasing::OnResize();
            auto& upscaler = Bridge::TheUpscaler11();
            upscaler.hub.Stop(false);
            upscaler.bridge.Release();
        };
    }
} AntiAliasingInit;
