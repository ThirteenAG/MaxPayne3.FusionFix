#include <d3d11_4.h>

namespace Antialiasing::detail
{
class D3D11Bridge
{
public:
    LUID luid{};
    uint32_t vendorId = 0;
    uint32_t width = 0;
    uint32_t height = 0;

    ID3D11Device5* device = nullptr;
    ID3D11DeviceContext4* context = nullptr;
    std::array<ID3D11Texture2D*, TextureCount> textures{};
    ID3D11Fence* fence = nullptr;

    static constexpr DXGI_FORMAT Formats[TextureCount] =
    {
        DXGI_FORMAT_R16G16B16A16_FLOAT, DXGI_FORMAT_R32_FLOAT, DXGI_FORMAT_R16G16_FLOAT, DXGI_FORMAT_R16_FLOAT, DXGI_FORMAT_R16G16B16A16_FLOAT
    };

    bool Init(ID3D11Device* d3dDevice)
    {
        if (FAILED(d3dDevice->QueryInterface(IID_PPV_ARGS(&device))) || !device)
            return false;
        ID3D11DeviceContext* immediate = nullptr;
        device->GetImmediateContext(&immediate);
        bool ok = immediate && SUCCEEDED(immediate->QueryInterface(IID_PPV_ARGS(&context))) && context;
        SafeRelease(immediate);
        if (!ok)
            return false;

        IDXGIDevice* dxgiDevice = nullptr;
        IDXGIAdapter* adapter = nullptr;
        DXGI_ADAPTER_DESC desc{};
        ok = SUCCEEDED(device->QueryInterface(IID_PPV_ARGS(&dxgiDevice))) && SUCCEEDED(dxgiDevice->GetAdapter(&adapter)) && SUCCEEDED(adapter->GetDesc(&desc));
        SafeRelease(adapter);
        SafeRelease(dxgiDevice);
        luid = desc.AdapterLuid;
        vendorId = desc.VendorId;
        return ok;
    }

    void ReleaseImports()
    {
        for (auto& texture : textures)
            SafeRelease(texture);
        SafeRelease(fence);
        width = height = 0;
    }

    void Release()
    {
        ReleaseImports();
        SafeRelease(context);
        SafeRelease(device);
    }

    bool Import(Protocol::Shared& shared, uint32_t w, uint32_t h)
    {
        ReleaseImports();

        for (size_t i = 0; i < textures.size(); ++i)
        {
            auto handle = reinterpret_cast<HANDLE>(shared.TextureHandles[i]);
            auto hr = handle ? device->OpenSharedResource1(handle, IID_PPV_ARGS(&textures[i])) : E_HANDLE;
            if (FAILED(hr) || !textures[i])
            {
                Log("Bridge: shared texture %u couldn't be opened (0x%08X)", static_cast<uint32_t>(i), static_cast<uint32_t>(hr));
                ReleaseImports();
                return false;
            }
        }
        auto fenceHandle = reinterpret_cast<HANDLE>(shared.FenceHandle);
        auto hr = fenceHandle ? device->OpenSharedFence(fenceHandle, IID_PPV_ARGS(&fence)) : E_HANDLE;
        if (FAILED(hr) || !fence)
        {
            Log("Bridge: the shared fence couldn't be opened (0x%08X)", static_cast<uint32_t>(hr));
            ReleaseImports();
            return false;
        }

        width = w;
        height = h;
        return true;
    }

    bool Matches(ID3D11Texture2D* texture, size_t index) const
    {
        D3D11_TEXTURE2D_DESC desc{};
        texture->GetDesc(&desc);
        return desc.Format == Formats[index] && desc.Width == width && desc.Height == height && desc.SampleDesc.Count == 1;
    }

    bool SubmitInputs(ID3D11Texture2D* const (&inputs)[InputCount], uint64_t signalValue)
    {
        for (size_t i = 0; i < InputCount; ++i)
            if (inputs[i] && !Matches(inputs[i], i))
                return false;

        for (size_t i = 0; i < InputCount; ++i)
            if (inputs[i])
                context->CopyResource(textures[i], inputs[i]);
        if (FAILED(context->Signal(fence, signalValue)))
            return false;
        context->Flush();
        return true;
    }

    bool SubmitOutput(ID3D11Texture2D* target, uint64_t waitValue)
    {
        if (!Matches(target, OutputIndex) || FAILED(context->Wait(fence, waitValue)))
            return false;
        context->CopyResource(target, textures[OutputIndex]);
        return true;
    }
};

struct UpscalerFrame11
{
    ID3D11Texture2D* Color = nullptr;       // R16G16B16A16_FLOAT
    ID3D11Texture2D* Depth = nullptr;       // R32_FLOAT, standard [0, 1] depth
    ID3D11Texture2D* Motion = nullptr;      // R16G16_FLOAT, previous - current in texture coordinates
    ID3D11Texture2D* Output = nullptr;      // R16G16B16A16_FLOAT
    uint32_t Width = 0;
    uint32_t Height = 0;
    Jitter JitterPixels;
    float CameraNear = 0.1f;
    float CameraFar = 1000.0f;
    float CameraFovY = 1.0f;
    float FrameTimeMs = 16.6f;
    uint32_t DLSSPreset = 0;
    bool Reset = false;
};

class Upscaler11
{
public:
    enum class State
    {
        Idle, Starting, Ready, Failed
    };

    State state = State::Idle;
    D3D11Bridge bridge;
    Protocol::Client hub;
    std::atomic<bool> dlssAvailable = false;
    std::atomic<bool> fsrAvailable = false;
    std::atomic<uint32_t> generation = 0;

    uint32_t configuredBackend = 0;
    uint32_t configuredWidth = 0;
    uint32_t configuredHeight = 0;
    uint32_t configuredPreset = 0;
    bool configuredLowDynamicRange = true;
    bool configureFailed = false;
    uint64_t fenceValue = 0;

    void Fail(const char* why)
    {
        Log("Bridge: %s, DLAA and FSR are off", why);
        state = State::Failed;
        dlssAvailable = false;
        fsrAvailable = false;
        ++generation;
        bridge.ReleaseImports();
        hub.Stop(true);
    }

    void Update(ID3D11Device* device)
    {
        if (state == State::Idle)
        {
            if (!device)
                return;
            state = State::Failed;

            if (!bridge.Init(device))
            {
                Log("Bridge: the device has no ID3D11Device5 (Windows 10 1703 or later), DLAA and FSR are off");
                bridge.Release();
                return;
            }

            auto root = Protocol::GameRoot();
            if (!Protocol::Present(root, bridge.vendorId == 0x10DE))
            {
                Log("Bridge: FusionFixHub.exe or the vendor runtimes in the game's folder are missing");
                return;
            }

            auto& config = Config();
            if (!hub.Start(root, bridge.luid, config.BridgeName, config.ClientName.c_str(), config.HubLog))
            {
                Log("Bridge: FusionFixHub.exe didn't start (%u)", GetLastError());
                hub.Stop(false);
                return;
            }
            Log("Bridge: FusionFixHub.exe started");
            state = State::Starting;
        }

        if (state == State::Starting)
        {
            bool ok = false;
            if (!hub.PollStarted(ok))
                return;
            if (!ok)
            {
                Fail(hub.shared && hub.shared->Message[0] ? hub.shared->Message : "the hub didn't start");
                return;
            }
            dlssAvailable = hub.IsAvailable(Protocol::Backend::DLSS);
            fsrAvailable = hub.IsAvailable(Protocol::Backend::FSR);
            Log("Bridge: ready, DLSS %s, FSR %s (%s)", dlssAvailable ? "yes" : "no", fsrAvailable ? "yes" : "no", hub.shared->Message);
            state = State::Ready;
            ++generation;
        }
    }

    bool IsAvailable(Backend backend) const
    {
        return backend == Backend::DLSS ? dlssAvailable.load() : fsrAvailable.load();
    }

    bool Evaluate(Backend backend, const UpscalerFrame11& frame)
    {
        if (state != State::Ready || !IsAvailable(backend) || !frame.Color || !frame.Depth || !frame.Motion || !frame.Output)
            return false;

        auto backendId = static_cast<uint32_t>(backend);
        bool reconfigure = configuredBackend != backendId || configuredWidth != frame.Width || configuredHeight != frame.Height ||
            configuredPreset != frame.DLSSPreset || configuredLowDynamicRange != Config().LowDynamicRange;
        if (reconfigure)
        {
            bridge.ReleaseImports();
            configuredBackend = backendId;
            configuredWidth = frame.Width;
            configuredHeight = frame.Height;
            configuredPreset = frame.DLSSPreset;
            configuredLowDynamicRange = Config().LowDynamicRange;
            configureFailed = true;

            auto& shared = *hub.shared;
            shared.ConfigureBackend = static_cast<Protocol::Backend>(backendId);
            shared.Width = frame.Width;
            shared.Height = frame.Height;
            shared.OutputWidth = frame.Width;
            shared.OutputHeight = frame.Height;
            shared.DLSSPreset = frame.DLSSPreset;
            shared.Flags = (Config().LowDynamicRange ? Protocol::ConfigureFlags::LowDynamicRange : 0u) | Protocol::ConfigureFlags::SharedWithD3D11;
            if (!hub.Request(Protocol::Command::Configure, 15000))
            {
                if (hub.Exited())
                    Fail("the hub ended");
                else
                    Log("Bridge: %s %ux%u not configured (%s)", backend == Backend::DLSS ? "DLSS" : "FSR", frame.Width, frame.Height, shared.Message);
                return false;
            }
            bool imported = bridge.Import(shared, frame.Width, frame.Height);
            hub.CloseSharedHandles();
            if (!imported)
            {
                Log("Bridge: the shared textures couldn't be opened on the game's device");
                return false;
            }

            Log("Bridge: %s %ux%u configured", backend == Backend::DLSS ? "DLAA" : "FSR", frame.Width, frame.Height);
            configureFailed = false;
            fenceValue = 0;
        }
        else if (configureFailed)
        {
            return false;
        }

        auto inputValue = ++fenceValue;
        auto outputValue = ++fenceValue;

        ID3D11Texture2D* const inputs[InputCount] = { frame.Color, frame.Depth, frame.Motion, nullptr };
        if (!bridge.SubmitInputs(inputs, inputValue))
        {
            Log("Bridge: the inputs couldn't be copied");
            configureFailed = true;
            return false;
        }

        auto& shared = *hub.shared;
        shared.WaitValue = inputValue;
        shared.SignalValue = outputValue;
        shared.JitterX = frame.JitterPixels.X;
        shared.JitterY = frame.JitterPixels.Y;
        shared.MotionScaleX = static_cast<float>(frame.Width);
        shared.MotionScaleY = static_cast<float>(frame.Height);
        shared.CameraNear = frame.CameraNear;
        shared.CameraFar = frame.CameraFar;
        shared.CameraFovY = frame.CameraFovY;
        shared.FrameTimeMs = frame.FrameTimeMs;
        shared.Sharpness = 0.0f;
        shared.Reset = frame.Reset ? 1 : 0;

        if (!hub.Request(Protocol::Command::Evaluate, 500))
        {
            if (hub.Exited())
                Fail("the hub ended");
            else
            {
                Log("Bridge: evaluate failed (%s)", shared.Message);
                configureFailed = true;
            }
            return false;
        }

        return bridge.SubmitOutput(frame.Output, outputValue);
    }
};

inline Upscaler11& TheUpscaler11()
{
    static Upscaler11 upscaler;
    return upscaler;
}

}
