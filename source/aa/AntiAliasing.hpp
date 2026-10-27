#pragma once

// Temporal anti-aliasing for Direct3D 9 games (x86, also D3D8 through d3d8to9), at native resolution: the built-in TAA
// (Halton(2, 3) jitter, motion vectors, history resolve; works on any D3D9), and DLAA / FSR native AA run by
// FusionFixHub.exe through its upscaler bridge (UpscalerD3D9.inl). DLAA and FSR need the game on DXVK or on D3D9on12 with
// an interop path (graphics_api.h): the D3D9 runtime of Windows can't share textures with the hub's D3D12 device.
//
// What a game provides (everything else is here):
// - Configure() once, with names for the logs and the bridge.
// - InstallGraphicsApi() before the game creates its Direct3D object, with the Graphics API setting.
// - The camera of each frame and its jitter, one of:
//   - OnCamera() once per frame with the view and the unjittered projection of the main camera, which returns the
//     jitter; the game moves its projection by it (JitterProjection) before the scene is drawn.
//     Engines that draw a frame on a render thread while the next one is built also call OnRenderedCamera() on the
//     render thread with each viewport set for drawing: the recorded frame it matches is the one Render() resolves.
//   - Engines that draw on a render thread: the game jitters its projection by JitterOf(its frame counter) where it
//     builds it, and calls BeginFrame() on the render thread, when the scene starts, with the camera the scene is drawn
//     with (unjittered projection and the jitter it has).
//   Only the main scene's view: anything jittered that isn't resolved afterwards shows the jitter.
// - The scene's depth as a texture in standard [0, 1] depth (0 near), e.g. the game's depth-stencil swapped for an INTZ
//   texture (ReplaceDepthStencil), or logarithmic (Options::LogarithmicDepth).
// - Either Render() where the scene is complete and the HUD isn't drawn yet (motion vectors and resolve at once), or the
//   steps one by one:
//   - RenderMotion() after the opaque scene, before transparent geometry (the motion through a window is the one
//     behind it). The game may draw the motion of its moving objects into MotionTexture() afterwards.
//   - CaptureOpaque() where transparent geometry starts, for the reactive mask (Options::ReactiveMask): particles,
//     glass and effects have no motion vectors, where the finished scene differs from it the current frame weighs more.
//   - Resolve() with the scene (e.g. HDR, before bloom and tone mapping) into the output.
//   Its result is LDR or HDR as the game's scene there (LowDynamicRange in Configure).
// - Update() every frame when it calls none of Render() and BeginFrame() (they start the hub), OnLostDevice() before the
//   device is reset, Shutdown() when the game ends.
//
// Motion vectors: the camera's, reprojected from the depth; what moves by itself (cars, people) has the motion of the
// world behind it, unless the game draws its own (MotionTexture) or Options::ObjectMotion searches it in the last
// frame's luma (BlockMotion.hlsl, MotionSelect.hlsl).

#include <windows.h>
#include <d3d9.h>
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <share.h>
#include <mutex>
#include <string>
#include "../upscaler/dxvk_interop.hpp"
#include <upscaler/upscaler_bridge_client.h>
#include "../upscaler/graphics_api.h"

namespace WFPAA
{
    enum class Mode
    {
        Off, TAA, DLAA, FSR
    };

    enum class Backend : uint32_t
    {
        DLSS = static_cast<uint32_t>(UpscalerBridge::Backend::DLSS),
        FSR = static_cast<uint32_t>(UpscalerBridge::Backend::FSR),
    };

    // ---------------------------------------------------------------------------------------------------------------
    // Math

    struct Matrix
    {
        double m[4][4]{};

        static Matrix Identity()
        {
            Matrix r;
            for (int i = 0; i < 4; ++i)
                r.m[i][i] = 1.0;
            return r;
        }

        // Sixteen floats, row by row
        static Matrix From(const float* f)
        {
            Matrix r;
            for (int i = 0; i < 4; ++i)
                for (int j = 0; j < 4; ++j)
                    r.m[i][j] = f[i * 4 + j];
            return r;
        }

        void To(float* f) const
        {
            for (int i = 0; i < 4; ++i)
                for (int j = 0; j < 4; ++j)
                    f[i * 4 + j] = static_cast<float>(m[i][j]);
        }

        Matrix operator*(const Matrix& b) const
        {
            Matrix r;
            for (int i = 0; i < 4; ++i)
                for (int j = 0; j < 4; ++j)
                    r.m[i][j] = m[i][0] * b.m[0][j] + m[i][1] * b.m[1][j] + m[i][2] * b.m[2][j] + m[i][3] * b.m[3][j];
            return r;
        }

        Matrix Inverse() const
        {
            // Gauss-Jordan with partial pivoting
            Matrix a = *this;
            Matrix r = Identity();
            for (int c = 0; c < 4; ++c)
            {
                int pivot = c;
                for (int i = c + 1; i < 4; ++i)
                    if (std::abs(a.m[i][c]) > std::abs(a.m[pivot][c]))
                        pivot = i;
                if (std::abs(a.m[pivot][c]) < 1e-12)
                    return Identity();
                std::swap(a.m[c], a.m[pivot]);
                std::swap(r.m[c], r.m[pivot]);
                double inv = 1.0 / a.m[c][c];
                for (int j = 0; j < 4; ++j)
                {
                    a.m[c][j] *= inv;
                    r.m[c][j] *= inv;
                }
                for (int i = 0; i < 4; ++i)
                {
                    if (i == c)
                        continue;
                    double f = a.m[i][c];
                    for (int j = 0; j < 4; ++j)
                    {
                        a.m[i][j] -= f * a.m[c][j];
                        r.m[i][j] -= f * r.m[c][j];
                    }
                }
            }
            return r;
        }
    };

    inline float Halton(uint32_t index, uint32_t base)
    {
        float f = 1.0f;
        float r = 0.0f;
        while (index > 0)
        {
            f /= static_cast<float>(base);
            r += f * static_cast<float>(index % base);
            index /= base;
        }
        return r;
    }

    // How far the rendered content moves this frame, in pixels of the render size: x right, y down. DLSS and FSR take
    // the same value (checked in GTA IV: with the opposite sign the noise of a still image doubles).
    struct Jitter
    {
        float X = 0.0f;
        float Y = 0.0f;
    };

    // Moves a Direct3D perspective projection (row vectors, clip = v * P, w = P[2][3] * z: 1 left-handed, -1
    // right-handed) by a jitter. P[2][0] and P[2][1] add P[2][3] * z to x and y, so NDC moves by exactly the added value.
    inline void JitterProjection(float* P, const Jitter& jitter, float width, float height)
    {
        P[8] += 2.0f * jitter.X / width * P[11];
        P[9] -= 2.0f * jitter.Y / height * P[11];
    }

    struct Camera
    {
        Matrix View;                // world -> view space
        Matrix Projection;          // as the game built it, without jitter; standard [0, 1] depth
        uint32_t Width = 0;         // render size
        uint32_t Height = 0;
    };

    struct Options
    {
        std::wstring BridgeName;                // prefix of the bridge's shared objects, e.g. L"Local\\NFSCarbon.WidescreenFix.Upscaler"
        std::string ClientName;                 // for the hub's log
        std::filesystem::path Log;              // this library's log, empty for none
        std::filesystem::path HubLog;           // the hub's log, empty for none
        bool LowDynamicRange = true;            // the scene at Render() is in [0, 1]
        float CameraCutDistance = 25.0f;        // a camera that moved farther in one frame starts a new history (world units)
        float InfiniteFarScale = 100000.0f;     // a projection without a far plane: far = near * this, for the depth math
        float CurrentWeightMin = 0.08f;         // share of the current frame in the resolve, still
        float CurrentWeightMax = 0.2f;          // and moving fast
        float CurrentWeightPerPixel = 0.1f;     // from min to max per pixel of motion
        float VarianceClipGamma = 1.25f;
        float StaticHistoryTrust = 0.5f;        // share of the unclipped history kept where nothing moves (thin detail flickers less)
        float LumaWeight = 1.0f;
        float VelocityRejection = 0.0f;         // a change of the motion (pixels) between the history and now from which history is rejected,
                                                // 0 off: uneven frame pacing changes the motion of a turning camera every frame and makes it jitter
        float VelocityRejectionRange = 4.0f;    // and the change over which it's rejected fully
        float DisocclusionDepth = 0.0f;         // Direct3D 9 TAA: where the surface at the history's position last frame was nearer than this
                                                // pixel's by this share of its distance, it covered the pixel (a character walked past) and the
                                                // history is rejected; 0 off. Needs a depth that holds moving objects.
        uint32_t JitterPhases = 8;              // TAA; DLAA takes at least 32, FSR 16
        bool ObjectMotion = true;               // Direct3D 11: the motion of what moves on its own, searched in the last frame
        uint32_t ObjectMotionBlock = 8;         // block size of that search, pixels
        uint32_t ObjectMotionRadius = 6;        // how far it searches around the camera motion, pixels per frame
        float ObjectMotionMargin = 0.5f;        // a block's motion is taken where its difference is under this share of the camera motion's
        float ObjectMotionThreshold = 0.015f;   // mean luma difference per pixel (0 to 1, compressed) under which the camera motion fits
        float ObjectMotionDepth = 0.0001f;      // relative depth change under which a block's geometry counts as still
        uint32_t DLSSPreset = 0;                // NVSDK_NGX_DLSS_Hint_Render_Preset, 0 is the default
        uint32_t FSRJitterPhases = 16;          // at least, with FSR
        float FSRSharpness = 0.0f;              // FSR's own sharpening (RCAS), 0 to 1; the library's sharpening is separate
        bool D3D9On12Interop = false;           // Direct3D 9 on Windows' D3D9on12 (without the queued interop of Fusion Fix's build): DLAA and FSR anyway (slow)
        bool LogarithmicDepth = false;          // Direct3D 9: the depth given to RenderMotion is logarithmic (near * 2^(depth * log2(far / near)))
        bool ReactiveMask = false;              // Direct3D 9: the game calls CaptureOpaque before transparent geometry
        float ReactiveScale = 2.0f;             // how strongly a difference from the opaque scene makes a pixel follow the current frame
        float ReactiveMax = 0.75f;              // and at most how much
        bool StabilizeFSR = false;              // Direct3D 9: FSR's output stabilized over time (Stabilize.hlsl)
        float StabilizeCurrentWeight = 0.05f;   // share of FSR's output where nothing moves
        float StabilizeMotionThreshold = 0.5f;  // motion in pixels from which FSR's output is taken as it is
    };

    // ---------------------------------------------------------------------------------------------------------------
    // Graphics API

    using GraphicsApi = FusionFixGraphicsApi::Api;

    // Before the game creates its Direct3D object: the Graphics API setting on DXVK (vulkan.dll in the game folder, the
    // hub's build or the player's own) or on Fusion Fix's D3D9On12 driver (graphics_api.h). With the plugin's
    // settings (Options: the crash guard's marker folder and the callback that sets the setting back) when it has
    // them. Returns the API it will run on.
    inline GraphicsApi InstallGraphicsApi(const FusionFixGraphicsApi::Options& options)
    {
        return FusionFixGraphicsApi::Install(options).effective;
    }

    inline GraphicsApi InstallGraphicsApi(int setting)
    {
        return FusionFixGraphicsApi::Install(static_cast<GraphicsApi>(std::clamp(setting, 0, 2)));
    }

    // Whether the Vulkan choice can be offered: vulkan.dll is DXVK (the hub's build or the player's own)
    inline bool VulkanAvailable()
    {
        static int known = -1;
        if (known < 0)
            known = FusionFixGraphicsApi::VulkanAvailable() ? 1 : 0;
        return known == 1;
    }

    inline GraphicsApi RunningApi()
    {
        return FusionFixGraphicsApi::Running();
    }

    namespace detail
    {
        inline Options& Config()
        {
            static Options options;
            return options;
        }

        inline void Log(const char* format, ...)
        {
            static std::mutex mutex;
            static FILE* file = nullptr;
            static bool opened = false;
            std::lock_guard lock(mutex);
            if (!opened)
            {
                opened = true;
                if (!Config().Log.empty())
                    file = _wfsopen(Config().Log.c_str(), L"w", _SH_DENYWR);
            }
            if (!file)
                return;
            SYSTEMTIME t;
            GetLocalTime(&t);
            fprintf(file, "%02d:%02d:%02d.%03d ", t.wHour, t.wMinute, t.wSecond, t.wMilliseconds);
            va_list args;
            va_start(args, format);
            vfprintf(file, format, args);
            va_end(args);
            fputc('\n', file);
            fflush(file);
        }

        template <typename T>
        void SafeRelease(T*& p)
        {
            if (p)
            {
                p->Release();
                p = nullptr;
            }
        }

        inline HMODULE ThisModule()
        {
            HMODULE module = nullptr;
            GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                reinterpret_cast<LPCWSTR>(&ThisModule), &module);
            return module;
        }

        inline uint32_t AdapterVendor(IDirect3DDevice9* device)
        {
            uint32_t vendor = 0;
            IDirect3D9* d3d = nullptr;
            if (SUCCEEDED(device->GetDirect3D(&d3d)) && d3d)
            {
                D3DDEVICE_CREATION_PARAMETERS parameters{};
                D3DADAPTER_IDENTIFIER9 identifier{};
                if (SUCCEEDED(device->GetCreationParameters(&parameters)) && SUCCEEDED(d3d->GetAdapterIdentifier(parameters.AdapterOrdinal, 0, &identifier)))
                    vendor = identifier.VendorId;
                d3d->Release();
            }
            return vendor;
        }
    }
}

#include "UpscalerD3D9.inl"

namespace WFPAA
{
    // ---------------------------------------------------------------------------------------------------------------
    // Temporal anti-aliasing

    class TemporalAA
    {
        struct FrameCamera
        {
            Matrix View;
            Matrix Projection;              // without jitter
            Matrix ViewProjection;          // without jitter
            Jitter JitterPixels;
            float JitterNdc[2]{};           // how far the content moved in NDC (x right, y up)
            float Near = 0.0f;
            float Far = 0.0f;
            float FovY = 0.0f;
            uint32_t Width = 0;
            uint32_t Height = 0;
            uint32_t Frame = 0;
            bool Valid = false;
            float Rendered[32]{};           // the view and the jittered projection as the game draws with them
        };

        // Engines that draw on a render thread while the next frame is built (OnRenderedCamera): the cameras OnCamera
        // recorded, and the one the render thread draws
        static constexpr size_t RecordedCount = 8;
        static inline std::mutex mutex;
        static inline std::array<FrameCamera, RecordedCount> recorded{};
        static inline uint32_t recordedNext = 0;
        static inline FrameCamera rendered;
        static inline bool renderedMatched = false;
        static inline bool renderedByViewport = false;

        static inline std::atomic<Mode> requested = Mode::Off;
        static inline float sharpness = 0.0f;
        static inline std::atomic<uint32_t> frame = 0;  // advanced by OnCamera or BeginFrame, once per frame
        static inline std::atomic<uint32_t> resolveFrame = 0;   // frame of the last resolve
        static inline uint32_t motionFrame = 0;         // frame the motion vectors were rendered in
        static inline uint32_t historyFrame = 0;        // frame the history was written in
        static inline bool historyStabilized = false;   // the history is FSR's stabilized output
        static inline uint32_t upscalerFrame = 0;       // frame of the last DLAA or FSR frame
        static inline uint32_t historyIndex = 0;
        static inline uint32_t depthIndex = 0;          // depthTex of this frame
        static inline uint32_t depthFrame = 0;          // frame depthTex[depthIndex] was written in
        static inline bool previousDepthValid = false;  // depthTex[depthIndex ^ 1] holds the last frame's depth
        static inline uint32_t lumaIndex = 0;           // lumaTex of this frame
        static inline uint32_t lumaFrame = 0;
        static inline uint32_t opaqueFrame = 0;         // frame opaqueTex was written in
        static inline uint32_t previousMotionFrame = 0; // frame previousMotionTex holds the motion of
        static inline FrameCamera current;
        static inline FrameCamera previous;
        static inline LARGE_INTEGER lastTime{};
        static inline Mode lastLogged = Mode::Off;

        // Resources (default pool, released before a reset)
        static inline IDirect3DPixelShader9* cameraMotionPS = nullptr;
        static inline IDirect3DPixelShader9* resolvePS = nullptr;
        static inline IDirect3DPixelShader9* outputPS = nullptr;
        static inline IDirect3DPixelShader9* copyPS = nullptr;
        static inline IDirect3DPixelShader9* depthPS = nullptr;
        static inline IDirect3DPixelShader9* lumaPS = nullptr;
        static inline IDirect3DPixelShader9* blockMotionPS = nullptr;
        static inline IDirect3DPixelShader9* motionSelectPS = nullptr;
        static inline IDirect3DPixelShader9* opaqueLumaPS = nullptr;
        static inline IDirect3DPixelShader9* reactivePS = nullptr;
        static inline IDirect3DPixelShader9* stabilizePS = nullptr;
        static inline IDirect3DStateBlock9* stateBlock = nullptr;
        static inline IDirect3DTexture9* sceneTex = nullptr;        // copy of the scene, the game's format (when it isn't a texture)
        static inline IDirect3DTexture9* motionTex = nullptr;       // G16R16F
        static inline IDirect3DTexture9* previousMotionTex = nullptr; // G16R16F, motionTex of the last resolve
        static inline IDirect3DTexture9* cameraMotionTex = nullptr; // A16B16G16R16F, the camera's motion and depth deviation (ObjectMotion)
        static inline IDirect3DTexture9* blockTex = nullptr;        // A16B16G16R16F, one pixel per block (ObjectMotion)
        static inline IDirect3DTexture9* lumaTex[2]{};              // R16F, this frame's luma and the last one's (ObjectMotion)
        static inline IDirect3DTexture9* historyTex[2]{};           // A16B16G16R16F
        static inline IDirect3DTexture9* colorTex = nullptr;        // A16B16G16R16F, the scene for DLAA and FSR
        static inline IDirect3DTexture9* depthTex[2]{};             // R32F copies of the depth, this frame's and the last one's
        static inline IDirect3DTexture9* upscaledTex = nullptr;     // A16B16G16R16F, written by DLAA or FSR
        static inline IDirect3DTexture9* opaqueTex = nullptr;       // R16F, the scene's luma before transparent geometry
        static inline IDirect3DTexture9* reactiveTex = nullptr;     // R16F, FSR's reactive mask
        static inline IDirect3DTexture9* intzTex = nullptr;         // the game's depth-stencil (ReplaceDepthStencil)
        static inline uint32_t width = 0;
        static inline uint32_t height = 0;
        static inline uint32_t blocksX = 0;
        static inline uint32_t blocksY = 0;
        static inline D3DFORMAT sceneFormat = D3DFMT_UNKNOWN;
        static inline bool failed = false;                          // resources or shaders couldn't be made: nothing until a reset

        static bool LoadShader(IDirect3DDevice9* device, const wchar_t* name, IDirect3DPixelShader9*& shader)
        {
            if (shader)
                return true;
            auto module = detail::ThisModule();
            auto resource = FindResourceW(module, name, MAKEINTRESOURCEW(10));     // RT_RCDATA
            auto data = resource ? LoadResource(module, resource) : nullptr;
            auto code = data ? LockResource(data) : nullptr;
            return code && SUCCEEDED(device->CreatePixelShader(static_cast<const DWORD*>(code), &shader)) && shader;
        }

        static bool CreateTexture(IDirect3DDevice9* device, D3DFORMAT format, IDirect3DTexture9*& texture, uint32_t w = 0, uint32_t h = 0)
        {
            if (texture)
                return true;
            return SUCCEEDED(device->CreateTexture(w ? w : width, h ? h : height, 1, D3DUSAGE_RENDERTARGET, format, D3DPOOL_DEFAULT, &texture, nullptr)) && texture;
        }

        static void ReleaseTargets()
        {
            for (auto texture : { &sceneTex, &motionTex, &previousMotionTex, &cameraMotionTex, &blockTex, &lumaTex[0], &lumaTex[1], &historyTex[0],
                &historyTex[1], &colorTex, &depthTex[0], &depthTex[1], &upscaledTex, &opaqueTex, &reactiveTex })
                detail::SafeRelease(*texture);
            width = height = 0;
            sceneFormat = D3DFMT_UNKNOWN;
            motionFrame = 0;
            depthFrame = 0;
            lumaFrame = 0;
            opaqueFrame = 0;
            previousMotionFrame = 0;
            historyFrame = 0;
            upscalerFrame = 0;
        }

        // The targets of a render size; the mode's own ones (DLAA and FSR, the reactive mask, the stabilization) when
        // it needs them
        static bool EnsureResources(IDirect3DDevice9* device, uint32_t w, uint32_t h)
        {
            if (failed)
                return false;
            if (w != width || h != height)
            {
                ReleaseTargets();
                width = w;
                height = h;
            }

            auto& config = detail::Config();
            bool ok = LoadShader(device, L"WFPAA_CAMERAMOTION", cameraMotionPS) && LoadShader(device, L"WFPAA_RESOLVE", resolvePS) &&
                LoadShader(device, L"WFPAA_OUTPUT", outputPS) && LoadShader(device, L"WFPAA_COPY", copyPS) && LoadShader(device, L"WFPAA_DEPTH", depthPS);
            ok = ok && (stateBlock || SUCCEEDED(device->CreateStateBlock(D3DSBT_ALL, &stateBlock)));
            ok = ok && CreateTexture(device, D3DFMT_G16R16F, motionTex) && CreateTexture(device, D3DFMT_G16R16F, previousMotionTex) &&
                CreateTexture(device, D3DFMT_A16B16G16R16F, historyTex[0]) && CreateTexture(device, D3DFMT_A16B16G16R16F, historyTex[1]) &&
                CreateTexture(device, D3DFMT_R32F, depthTex[0]) && CreateTexture(device, D3DFMT_R32F, depthTex[1]);
            if (ok && config.ObjectMotion)
            {
                auto block = (std::max)(config.ObjectMotionBlock, 4u);
                blocksX = (w + block - 1) / block;
                blocksY = (h + block - 1) / block;
                ok = LoadShader(device, L"WFPAA_LUMA", lumaPS) && LoadShader(device, L"WFPAA_BLOCKMOTION", blockMotionPS) &&
                    LoadShader(device, L"WFPAA_MOTIONSELECT", motionSelectPS) && CreateTexture(device, D3DFMT_A16B16G16R16F, cameraMotionTex) &&
                    CreateTexture(device, D3DFMT_A16B16G16R16F, blockTex, blocksX, blocksY) && CreateTexture(device, D3DFMT_R16F, lumaTex[0]) &&
                    CreateTexture(device, D3DFMT_R16F, lumaTex[1]);
            }
            if (!ok)
            {
                detail::Log("TAA: resources or shaders couldn't be created at %ux%u", w, h);
                failed = true;
                ReleaseTargets();
                return false;
            }

            // Optional: without them the mode runs without that part
            auto mode = EffectiveMode();
            bool bridge = mode == Mode::DLAA || mode == Mode::FSR;
            if (bridge && !(CreateTexture(device, D3DFMT_A16B16G16R16F, colorTex) && CreateTexture(device, D3DFMT_A16B16G16R16F, upscaledTex)))
            {
                detail::SafeRelease(colorTex);
                detail::SafeRelease(upscaledTex);
            }
            if (config.ReactiveMask && !(LoadShader(device, L"WFPAA_OPAQUELUMA", opaqueLumaPS) && CreateTexture(device, D3DFMT_R16F, opaqueTex)))
                detail::SafeRelease(opaqueTex);
            if (config.ReactiveMask && mode == Mode::FSR && !(LoadShader(device, L"WFPAA_REACTIVE", reactivePS) && CreateTexture(device, D3DFMT_R16F, reactiveTex)))
                detail::SafeRelease(reactiveTex);
            if (config.StabilizeFSR && mode == Mode::FSR)
                LoadShader(device, L"WFPAA_STABILIZE", stabilizePS);
            return true;
        }

        // The scene as a texture: the game's own, or a copy when it's a plain surface or the output itself
        static IDirect3DTexture9* SceneTexture(IDirect3DDevice9* device, IDirect3DSurface9* scene, IDirect3DSurface9* output)
        {
            IDirect3DTexture9* texture = nullptr;
            if (scene != output && SUCCEEDED(scene->GetContainer(__uuidof(IDirect3DTexture9), reinterpret_cast<void**>(&texture))) && texture)
            {
                texture->Release();     // the game holds it
                return texture;
            }

            D3DSURFACE_DESC desc{};
            scene->GetDesc(&desc);
            if (desc.Format != sceneFormat)
            {
                detail::SafeRelease(sceneTex);
                sceneFormat = desc.Format;
            }
            if (!CreateTexture(device, desc.Format, sceneTex))
                return nullptr;
            IDirect3DSurface9* surface = nullptr;
            if (FAILED(sceneTex->GetSurfaceLevel(0, &surface)) || !surface)
                return nullptr;
            bool copied = SUCCEEDED(device->StretchRect(scene, nullptr, surface, nullptr, D3DTEXF_NONE));
            surface->Release();
            return copied ? sceneTex : nullptr;
        }

        struct ScreenVertex
        {
            float x, y, z, rhw;
            float u, v;
        };

        static void DrawFullscreen(IDirect3DDevice9* device, IDirect3DSurface9* target, IDirect3DPixelShader9* shader, uint32_t w = 0, uint32_t h = 0)
        {
            device->SetRenderTarget(0, target);
            device->SetPixelShader(shader);
            auto fw = static_cast<float>(w ? w : width);
            auto fh = static_cast<float>(h ? h : height);
            ScreenVertex vertices[4] =
            {
                { -0.5f,      -0.5f,      0.0f, 1.0f, 0.0f, 0.0f },
                { -0.5f,      fh - 0.5f,  0.0f, 1.0f, 0.0f, 1.0f },
                { fw - 0.5f,  -0.5f,      0.0f, 1.0f, 1.0f, 0.0f },
                { fw - 0.5f,  fh - 0.5f,  0.0f, 1.0f, 1.0f, 1.0f },
            };
            device->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, vertices, sizeof(ScreenVertex));
        }

        static void DrawFullscreen(IDirect3DDevice9* device, IDirect3DTexture9* target, IDirect3DPixelShader9* shader, uint32_t w = 0, uint32_t h = 0)
        {
            IDirect3DSurface9* surface = nullptr;
            if (FAILED(target->GetSurfaceLevel(0, &surface)) || !surface)
                return;
            DrawFullscreen(device, surface, shader, w, h);
            surface->Release();
        }

        static void SetSampler(IDirect3DDevice9* device, DWORD stage, IDirect3DBaseTexture9* texture, D3DTEXTUREFILTERTYPE filter)
        {
            device->SetTexture(stage, texture);
            device->SetSamplerState(stage, D3DSAMP_ADDRESSU, D3DTADDRESS_CLAMP);
            device->SetSamplerState(stage, D3DSAMP_ADDRESSV, D3DTADDRESS_CLAMP);
            device->SetSamplerState(stage, D3DSAMP_MINFILTER, filter);
            device->SetSamplerState(stage, D3DSAMP_MAGFILTER, filter);
            device->SetSamplerState(stage, D3DSAMP_MIPFILTER, D3DTEXF_NONE);
            device->SetSamplerState(stage, D3DSAMP_SRGBTEXTURE, FALSE);
        }

        static void ClearSamplers(IDirect3DDevice9* device)
        {
            for (DWORD s = 0; s < 7; ++s)
                device->SetTexture(s, nullptr);
        }

        static void SetFullscreenStates(IDirect3DDevice9* device)
        {
            for (DWORD i = 1; i < 4; ++i)
                device->SetRenderTarget(i, nullptr);
            device->SetDepthStencilSurface(nullptr);
            device->SetVertexShader(nullptr);
            device->SetFVF(D3DFVF_XYZRHW | D3DFVF_TEX1);
            device->SetRenderState(D3DRS_ZENABLE, FALSE);
            device->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
            device->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
            device->SetRenderState(D3DRS_ALPHATESTENABLE, FALSE);
            device->SetRenderState(D3DRS_STENCILENABLE, FALSE);
            device->SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
            device->SetRenderState(D3DRS_COLORWRITEENABLE, 0x0F);
            device->SetRenderState(D3DRS_SCISSORTESTENABLE, FALSE);
            device->SetRenderState(D3DRS_SRGBWRITEENABLE, FALSE);
            device->SetRenderState(D3DRS_FILLMODE, D3DFILL_SOLID);
            device->SetRenderState(D3DRS_CLIPPLANEENABLE, 0);
            device->SetRenderState(D3DRS_FOGENABLE, FALSE);
            device->SetRenderState(D3DRS_MULTISAMPLEANTIALIAS, FALSE);
        }

        // The game's state around the passes: render targets, depth-stencil, viewport and vertex streams aside, the
        // state block. A state block doesn't bring back a stream's offset on DXVK (it comes back as 0): a game that
        // draws from a ring buffer would then draw its next quads with old vertices.
        struct SavedState
        {
            static constexpr DWORD StreamCount = 4;

            IDirect3DDevice9* device = nullptr;
            IDirect3DSurface9* targets[4]{};
            IDirect3DSurface9* depth = nullptr;
            D3DVIEWPORT9 viewport{};
            IDirect3DVertexBuffer9* streams[StreamCount]{};
            UINT offsets[StreamCount]{};
            UINT strides[StreamCount]{};
            IDirect3DIndexBuffer9* indices = nullptr;

            explicit SavedState(IDirect3DDevice9* d) : device(d)
            {
                for (DWORD i = 0; i < 4; ++i)
                    device->GetRenderTarget(i, &targets[i]);
                device->GetDepthStencilSurface(&depth);
                device->GetViewport(&viewport);
                for (DWORD i = 0; i < StreamCount; ++i)
                    device->GetStreamSource(i, &streams[i], &offsets[i], &strides[i]);
                device->GetIndices(&indices);
                stateBlock->Capture();
            }

            ~SavedState()
            {
                ClearSamplers(device);
                for (DWORD i = 0; i < 4; ++i)
                    device->SetRenderTarget(i, targets[i]);
                device->SetDepthStencilSurface(depth);
                stateBlock->Apply();
                device->SetViewport(&viewport);
                for (DWORD i = 0; i < StreamCount; ++i)
                    device->SetStreamSource(i, streams[i], offsets[i], strides[i]);
                device->SetIndices(indices);
                for (auto& target : targets)
                    detail::SafeRelease(target);
                detail::SafeRelease(depth);
                for (auto& stream : streams)
                    detail::SafeRelease(stream);
                detail::SafeRelease(indices);
            }
        };

        static bool IsCameraCut()
        {
            auto currentInverse = current.View.Inverse();
            auto previousInverse = previous.View.Inverse();
            auto dx = currentInverse.m[3][0] - previousInverse.m[3][0];
            auto dy = currentInverse.m[3][1] - previousInverse.m[3][1];
            auto dz = currentInverse.m[3][2] - previousInverse.m[3][2];
            auto distance = static_cast<double>(detail::Config().CameraCutDistance);
            if (dx * dx + dy * dy + dz * dz > distance * distance)
                return true;

            // Forward vectors more than ~60 degrees apart
            auto dot = currentInverse.m[2][0] * previousInverse.m[2][0] + currentInverse.m[2][1] * previousInverse.m[2][1] +
                currentInverse.m[2][2] * previousInverse.m[2][2];
            return dot < 0.5;
        }

        // The camera of the frame before is the last frame's
        static bool PreviousUsable()
        {
            return previous.Valid && previous.Frame + 1 == current.Frame;
        }

        static bool HistoryUsable(uint32_t since)
        {
            return since != 0 && since + 1 == current.Frame && PreviousUsable() && !IsCameraCut();
        }

        static void SetCamera(const FrameCamera& c)
        {
            if (current.Valid)
                previous = current;
            current = c;
        }

        static FrameCamera MakeCamera(const Matrix& view, const Matrix& projection, uint32_t w, uint32_t h, float nearClip, float farClip)
        {
            FrameCamera c;
            c.View = view;
            c.Projection = projection;
            c.ViewProjection = view * projection;
            c.Width = w;
            c.Height = h;

            // Standard [0, 1] depth: depth = (P22 z + P32) / (P23 z), 0 at near, 1 at far. P22 = P23 has no far plane
            // (True Crime: New York City): depth = 1 + P32 / (P23 z), and a far plane InfiniteFarScale times the near
            // one stands in for it.
            auto& P = projection.m;
            if (nearClip > 0.0f && farClip > nearClip)
            {
                c.Near = nearClip;
                c.Far = farClip;
            }
            else if (P[2][2] != 0.0 && P[2][2] != P[2][3])
            {
                c.Near = static_cast<float>(std::abs(-P[3][2] / P[2][2]));
                c.Far = static_cast<float>(std::abs(-P[3][2] / (P[2][2] - P[2][3])));
            }
            else if (P[2][2] != 0.0)
            {
                c.Near = static_cast<float>(std::abs(-P[3][2] / P[2][2]));
                c.Far = c.Near * detail::Config().InfiniteFarScale;
            }
            c.FovY = P[1][1] != 0.0 ? static_cast<float>(2.0 * std::atan(1.0 / std::abs(P[1][1]))) : 1.0f;
            c.Valid = c.Width > 0 && c.Height > 0 && c.Near > 0.0f && c.Far > c.Near && P[2][3] != 0.0;
            return c;
        }

        static void SetJitter(FrameCamera& c, const Jitter& jitter)
        {
            c.JitterPixels = jitter;
            c.JitterNdc[0] = 2.0f * jitter.X / static_cast<float>(c.Width);
            c.JitterNdc[1] = -2.0f * jitter.Y / static_cast<float>(c.Height);
        }

        // Depth copy, camera motion and (Options::ObjectMotion) the motion of what moves on its own
        static void RenderMotionPasses(IDirect3DDevice9* device, IDirect3DBaseTexture9* depth, IDirect3DTexture9* scene)
        {
            auto& config = detail::Config();

            // This frame's depth as standard R32F: the next frame checks its motion against it, the resolve, DLAA and
            // FSR take it
            auto previousDepth = depthIndex;
            bool previousValid = depthFrame != 0 && depthFrame + 1 == current.Frame && PreviousUsable();
            previousDepthValid = previousValid;
            depthIndex ^= 1u;
            float depthConstants[4] = { config.LogarithmicDepth ? 1.0f : 0.0f, current.Near, std::log2(current.Far / current.Near), current.Far };
            SetSampler(device, 0, depth, D3DTEXF_POINT);
            device->SetPixelShaderConstantF(0, depthConstants, 1);
            DrawFullscreen(device, depthTex[depthIndex], depthPS);
            depthFrame = current.Frame;

            // current clip space -> previous clip space, without jitter
            auto& last = PreviousUsable() ? previous : current;
            auto reproject = current.ViewProjection.Inverse() * last.ViewProjection;

            float constants[7 * 4]{};
            constants[0] = current.JitterNdc[0];
            constants[1] = current.JitterNdc[1];
            reproject.To(&constants[4]);
            constants[20] = current.Near;
            constants[21] = current.Far;
            constants[22] = previousValid ? 1.0f : 0.0f;
            constants[24] = 1.0f / static_cast<float>(width);
            constants[25] = 1.0f / static_cast<float>(height);

            bool objectMotion = cameraMotionTex && scene;
            SetSampler(device, 0, depthTex[depthIndex], D3DTEXF_POINT);
            SetSampler(device, 1, depthTex[previousDepth], D3DTEXF_POINT);
            device->SetPixelShaderConstantF(0, constants, 7);
            DrawFullscreen(device, objectMotion ? cameraMotionTex : motionTex, cameraMotionPS);
            ClearSamplers(device);
            if (objectMotion)
                RenderObjectMotion(device, scene);
            motionFrame = current.Frame;
        }

        // What moves on its own (animated characters, vehicles) when the game has no motion vectors for it: the camera
        // motion doesn't describe it, and the history of such a pixel would lag behind and catch up in steps. Found by
        // comparing this frame's luma with the last one's (BlockMotion, MotionSelect).
        static void RenderObjectMotion(IDirect3DDevice9* device, IDirect3DTexture9* scene)
        {
            auto& config = detail::Config();
            auto previousLuma = lumaIndex;
            bool previousValid = lumaFrame != 0 && lumaFrame + 1 == current.Frame && PreviousUsable();
            lumaIndex ^= 1u;
            SetSampler(device, 0, scene, D3DTEXF_POINT);
            DrawFullscreen(device, lumaTex[lumaIndex], lumaPS);
            lumaFrame = current.Frame;
            if (!previousValid)
            {
                SetSampler(device, 0, cameraMotionTex, D3DTEXF_POINT);
                DrawFullscreen(device, motionTex, copyPS);
                ClearSamplers(device);
                return;
            }

            auto block = static_cast<float>((std::max)(config.ObjectMotionBlock, 4u));
            float constants[4 * 4] =
            {
                1.0f / static_cast<float>(width), 1.0f / static_cast<float>(height), static_cast<float>(width), static_cast<float>(height),
                previous.JitterPixels.X - current.JitterPixels.X, previous.JitterPixels.Y - current.JitterPixels.Y, static_cast<float>(blocksX), static_cast<float>(blocksY),
                block, static_cast<float>(config.ObjectMotionRadius), config.ObjectMotionMargin, config.ObjectMotionThreshold,
                config.ObjectMotionDepth, 0.0f, 0.0f, 0.0f,
            };

            D3DVIEWPORT9 blocks{ 0, 0, blocksX, blocksY, 0.0f, 1.0f };
            device->SetViewport(&blocks);
            SetSampler(device, 0, lumaTex[lumaIndex], D3DTEXF_POINT);
            SetSampler(device, 1, lumaTex[previousLuma], D3DTEXF_LINEAR);
            SetSampler(device, 2, cameraMotionTex, D3DTEXF_POINT);
            device->SetPixelShaderConstantF(0, constants, 4);
            DrawFullscreen(device, blockTex, blockMotionPS, blocksX, blocksY);
            D3DVIEWPORT9 full{ 0, 0, width, height, 0.0f, 1.0f };
            device->SetViewport(&full);

            constants[9] = config.ObjectMotionMargin;
            constants[10] = config.ObjectMotionThreshold;
            SetSampler(device, 3, blockTex, D3DTEXF_POINT);
            device->SetPixelShaderConstantF(0, constants, 4);
            DrawFullscreen(device, motionTex, motionSelectPS);
            ClearSamplers(device);
        }

        static bool OpaqueReady()
        {
            return opaqueTex && opaqueFrame == current.Frame;
        }

        static void RenderOutput(IDirect3DDevice9* device, IDirect3DTexture9* source, IDirect3DSurface9* output)
        {
            float constants[4] = { 1.0f / static_cast<float>(width), 1.0f / static_cast<float>(height), sharpness,
                detail::Config().LowDynamicRange ? 1.0f : 0.0f };
            SetSampler(device, 0, source, D3DTEXF_POINT);
            device->SetPixelShaderConstantF(0, constants, 1);
            DrawFullscreen(device, output, outputPS);
        }

        // The constants of Resolve.hlsl and Stabilize.hlsl
        static void ResolveConstants(float (&constants)[5 * 4], bool historyValid, bool stabilize, bool reactive)
        {
            auto& config = detail::Config();
            auto w = static_cast<float>(width);
            auto h = static_cast<float>(height);
            float values[5 * 4] =
            {
                1.0f / w, 1.0f / h, w, h,
                current.JitterPixels.X, current.JitterPixels.Y, historyValid ? 1.0f : 0.0f, stabilize ? config.StabilizeCurrentWeight : config.VarianceClipGamma,
                config.CurrentWeightMin, config.CurrentWeightMax, config.CurrentWeightPerPixel, config.LumaWeight,
                config.StaticHistoryTrust, stabilize ? config.StabilizeMotionThreshold : 0.1f,
                previousMotionFrame + 1 == current.Frame ? config.VelocityRejection : 0.0f, (std::max)(config.VelocityRejectionRange, 0.01f),
                config.ReactiveScale, config.ReactiveMax, reactive ? 1.0f : 0.0f, 0.0f,
            };
            std::memcpy(constants, values, sizeof(values));
        }

        static void RenderResolve(IDirect3DDevice9* device, IDirect3DTexture9* scene)
        {
            auto previousIndex = historyIndex;
            auto currentIndex = historyIndex ^ 1u;
            bool historyValid = HistoryUsable(historyFrame) && !historyStabilized;
            bool reactive = OpaqueReady();

            float constants[5 * 4];
            ResolveConstants(constants, historyValid, false, reactive);

            // Disocclusion: the last frame's depth where the history comes from, and where this pixel's point was then
            auto& config = detail::Config();
            bool disocclusion = config.DisocclusionDepth > 0.0f && previousDepthValid && PreviousUsable();
            float previousConstants[5 * 4]{};
            if (disocclusion)
            {
                auto reproject = current.ViewProjection.Inverse() * previous.ViewProjection;
                reproject.To(previousConstants);
            }
            previousConstants[16] = current.Near;
            previousConstants[17] = current.Far;
            previousConstants[18] = disocclusion ? config.DisocclusionDepth : 0.0f;
            previousConstants[19] = 1.0f;     // the history's alpha: how long each pixel has been still

            SetSampler(device, 0, scene, D3DTEXF_POINT);
            SetSampler(device, 1, historyTex[previousIndex], D3DTEXF_LINEAR);
            SetSampler(device, 2, motionTex, D3DTEXF_POINT);
            SetSampler(device, 3, depthTex[depthIndex], D3DTEXF_POINT);
            SetSampler(device, 4, previousMotionTex, D3DTEXF_POINT);
            SetSampler(device, 5, reactive ? opaqueTex : nullptr, D3DTEXF_POINT);
            SetSampler(device, 6, disocclusion ? depthTex[depthIndex ^ 1u] : nullptr, D3DTEXF_POINT);
            device->SetPixelShaderConstantF(0, constants, 5);
            device->SetPixelShaderConstantF(5, previousConstants, 5);
            DrawFullscreen(device, historyTex[currentIndex], resolvePS);
            ClearSamplers(device);

            historyIndex = currentIndex;
            historyFrame = current.Frame;
            historyStabilized = false;
        }

        // FSR's output, stabilized over time (Options::StabilizeFSR)
        static void RenderStabilize(IDirect3DDevice9* device, bool reactive)
        {
            auto previousIndex = historyIndex;
            auto currentIndex = historyIndex ^ 1u;
            bool historyValid = HistoryUsable(historyFrame) && historyStabilized;

            float constants[5 * 4];
            ResolveConstants(constants, historyValid, true, reactive);
            SetSampler(device, 0, upscaledTex, D3DTEXF_POINT);
            SetSampler(device, 1, historyTex[previousIndex], D3DTEXF_LINEAR);
            SetSampler(device, 2, motionTex, D3DTEXF_POINT);
            SetSampler(device, 3, depthTex[depthIndex], D3DTEXF_POINT);
            SetSampler(device, 4, reactive ? reactiveTex : nullptr, D3DTEXF_POINT);
            device->SetPixelShaderConstantF(0, constants, 5);
            DrawFullscreen(device, historyTex[currentIndex], stabilizePS);
            ClearSamplers(device);

            historyIndex = currentIndex;
            historyFrame = current.Frame;
            historyStabilized = true;
        }

        static bool RenderUpscaler(IDirect3DDevice9* device, Backend backend, IDirect3DTexture9* scene, bool& reactiveUsed)
        {
            reactiveUsed = false;
            if (!colorTex || !upscaledTex)
                return false;

            // The scene in the format of the shared texture, unless it is in it already
            auto color = scene;
            D3DSURFACE_DESC desc{};
            if (FAILED(scene->GetLevelDesc(0, &desc)) || desc.Format != D3DFMT_A16B16G16R16F)
            {
                SetSampler(device, 0, scene, D3DTEXF_POINT);
                DrawFullscreen(device, colorTex, copyPS);
                ClearSamplers(device);
                color = colorTex;
            }

            // FSR's reactive mask (NVIDIA advises against one for DLSS)
            IDirect3DTexture9* reactive = nullptr;
            if (backend == Backend::FSR && reactiveTex && reactivePS && OpaqueReady())
            {
                auto& config = detail::Config();
                float constants[4] = { config.ReactiveScale, config.ReactiveMax, 0.0f, 0.0f };
                SetSampler(device, 0, scene, D3DTEXF_POINT);
                SetSampler(device, 1, opaqueTex, D3DTEXF_POINT);
                device->SetPixelShaderConstantF(0, constants, 1);
                DrawFullscreen(device, reactiveTex, reactivePS);
                ClearSamplers(device);
                reactive = reactiveTex;
            }

            LARGE_INTEGER now, frequency;
            QueryPerformanceCounter(&now);
            QueryPerformanceFrequency(&frequency);
            auto frameTime = lastTime.QuadPart ? static_cast<float>(static_cast<double>(now.QuadPart - lastTime.QuadPart) * 1000.0 / static_cast<double>(frequency.QuadPart)) : 16.6f;
            lastTime = now;

            detail::UpscalerFrame data;
            data.Color = color;
            data.Depth = depthTex[depthIndex];
            data.Motion = motionTex;
            data.Reactive = reactive;
            data.Output = upscaledTex;
            data.Width = width;
            data.Height = height;
            data.JitterPixels = current.JitterPixels;
            data.CameraNear = current.Near;
            data.CameraFar = current.Far;
            data.CameraFovY = current.FovY;
            data.FrameTimeMs = std::clamp(frameTime, 1.0f, 200.0f);
            data.Sharpness = backend == Backend::FSR ? detail::Config().FSRSharpness : 0.0f;
            data.DLSSPreset = detail::Config().DLSSPreset;
            data.Reset = !HistoryUsable(upscalerFrame);

            if (!detail::TheUpscaler().Evaluate(backend, data))
                return false;
            upscalerFrame = current.Frame;
            reactiveUsed = reactive != nullptr;
            return true;
        }

        static void LogMode()
        {
            auto mode = EffectiveMode();
            if (mode != lastLogged)
            {
                detail::Log("Mode: %s", mode == Mode::Off ? "off" : mode == Mode::TAA ? "TAA" : mode == Mode::DLAA ? "DLAA" : "FSR");
                lastLogged = mode;
            }
        }

    public:
        static void Configure(const Options& options)
        {
            detail::Config() = options;
        }

        // The mode the player chose; DLAA and FSR fall back to TAA while the bridge can't run them
        static void SetMode(Mode mode, float sharpen)
        {
            requested = mode;
            sharpness = std::clamp(sharpen, 0.0f, 1.0f);
        }

        static Mode EffectiveMode()
        {
            switch (requested.load())
            {
            case Mode::DLAA:
                return detail::TheUpscaler().IsAvailable(Backend::DLSS) ? Mode::DLAA : Mode::TAA;
            case Mode::FSR:
                return detail::TheUpscaler().IsAvailable(Backend::FSR) ? Mode::FSR : Mode::TAA;
            default:
                return requested.load();
            }
        }

        // Jitter only while the frames are resolved: one that isn't (post processing failed, a screen without the
        // resolve) would show it
        static bool IsJitterActive()
        {
            auto resolved = resolveFrame.load();
            return requested.load() != Mode::Off && resolved != 0 && frame.load() - resolved <= 10;
        }

        // The jitter of a frame of the game (its own frame counter, one step per frame: the sign and the per-frame order
        // matter, two steps per frame put every sample in one half of the pixel), for the mode chosen now. NVIDIA
        // recommends at least 16 phases for DLSS, 32 or more preferred.
        static Jitter JitterOf(uint32_t gameFrame)
        {
            auto phases = std::clamp(detail::Config().JitterPhases, 2u, 128u);
            auto mode = EffectiveMode();
            if (mode == Mode::DLAA)
                phases = (std::max)(phases, 32u);
            else if (mode == Mode::FSR)
                phases = (std::max)(phases, detail::Config().FSRJitterPhases);
            auto index = (gameFrame % phases) + 1;
            return { Halton(index, 2) - 0.5f, Halton(index, 3) - 0.5f };
        }

        // The main camera of this frame, once per frame, with the projection as the game built it. Returns the jitter
        // to move the projection by (JitterProjection), zero while nothing is resolved.
        static Jitter OnCamera(const Camera& camera)
        {
            auto c = MakeCamera(camera.View, camera.Projection, camera.Width, camera.Height, 0.0f, 0.0f);
            c.Frame = ++frame;
            if (c.Valid && IsJitterActive())
                SetJitter(c, JitterOf(c.Frame));

            // What the game will draw with, for OnRenderedCamera
            c.View.To(c.Rendered);
            c.Projection.To(c.Rendered + 16);
            if (c.JitterPixels.X != 0.0f || c.JitterPixels.Y != 0.0f)
                JitterProjection(c.Rendered + 16, c.JitterPixels, static_cast<float>(c.Width), static_cast<float>(c.Height));

            std::lock_guard lock(mutex);
            recorded[recordedNext] = c;
            recordedNext = (recordedNext + 1) % RecordedCount;
            if (!renderedByViewport)
                SetCamera(c);
            return c.JitterPixels;
        }

        // Engines that draw a frame on a render thread while the next one is built (RAGE), with OnCamera: on the render
        // thread, a viewport set for drawing, its view and projection (sixteen floats each, row by row). When they are
        // those of a frame OnCamera recorded, that frame is the one the next Render resolves; a frame no viewport
        // matched (a menu's own camera) isn't resolved.
        static void OnRenderedCamera(const float* view, const float* projection)
        {
            auto matches = [](const float* a, const float* b)
            {
                for (size_t i = 0; i < 16; ++i)
                    if (std::abs(a[i] - b[i]) > 1e-5f * (std::max)(1.0f, std::abs(a[i])))
                        return false;
                return true;
            };

            std::lock_guard lock(mutex);
            renderedByViewport = true;
            for (size_t i = 1; i <= RecordedCount; ++i)
            {
                auto& c = recorded[(recordedNext + RecordedCount - i) % RecordedCount];
                if (c.Valid && matches(c.Rendered + 16, projection) && matches(c.Rendered, view))
                {
                    rendered = c;
                    renderedMatched = true;
                    return;
                }
            }
        }

        // Engines that draw on a render thread and know the camera of the scene being drawn there (instead of
        // OnCamera): once per frame before RenderMotion, with the view, the projection without jitter and the jitter
        // the scene is drawn with (JitterOf). nearClip and farClip may be 0 to take them from the projection. Also starts
        // the hub, so call it every frame, whatever the mode.
        static void BeginFrame(IDirect3DDevice9* device, const Matrix& view, const Matrix& projection, const Jitter& jitter, uint32_t w, uint32_t h,
            float nearClip = 0.0f, float farClip = 0.0f)
        {
            Update(device);
            auto c = MakeCamera(view, projection, w, h, nearClip, farClip);
            c.Frame = ++frame;
            if (c.Valid)
                SetJitter(c, jitter);
            SetCamera(c);
        }

        // Every frame, whatever the mode: starts the hub once the device is known, logs mode changes
        static void Update(IDirect3DDevice9* device)
        {
            if (!device)
                return;
            detail::TheUpscaler().Update(device);
            LogMode();
        }

        // After the opaque scene (before transparent geometry, so the motion through a window is the one behind it):
        // this frame's depth (standard [0, 1] depth, or Options::LogarithmicDepth) into motion vectors of the camera,
        // and with Options::ObjectMotion and the scene also of what moves on its own. The game can draw the motion of
        // its moving objects into MotionTexture afterwards.
        static bool RenderMotion(IDirect3DDevice9* device, IDirect3DBaseTexture9* depth, IDirect3DTexture9* scene = nullptr)
        {
            if (!device || !depth || EffectiveMode() == Mode::Off || !current.Valid || (!renderedByViewport && current.Frame != frame.load()) ||
                motionFrame == current.Frame)
                return false;
            if (!EnsureResources(device, current.Width, current.Height))
                return false;

            SavedState state(device);
            SetFullscreenStates(device);
            D3DVIEWPORT9 full{ 0, 0, width, height, 0.0f, 1.0f };
            device->SetViewport(&full);
            RenderMotionPasses(device, depth, detail::Config().ObjectMotion ? scene : nullptr);
            return true;
        }

        // The motion vectors of this frame (G16R16F, previous - current position in texture coordinates, jitter
        // excluded), after RenderMotion: a render target the game may draw its moving objects' motion into
        static IDirect3DTexture9* MotionTexture()
        {
            return motionFrame != 0 && motionFrame == current.Frame ? motionTex : nullptr;
        }

        // This frame's depth as standard [0, 1] R32F, after RenderMotion
        static IDirect3DTexture9* StandardDepthTexture()
        {
            return depthFrame != 0 && depthFrame == current.Frame ? depthTex[depthIndex] : nullptr;
        }

        // Where transparent geometry starts (Options::ReactiveMask): the scene's luma, which the resolve and FSR's
        // reactive mask compare the finished scene with
        static void CaptureOpaque(IDirect3DDevice9* device, IDirect3DTexture9* scene)
        {
            if (!device || !scene || !opaqueTex || !opaqueLumaPS || motionFrame != current.Frame || opaqueFrame == current.Frame)
                return;
            D3DSURFACE_DESC desc{};
            if (FAILED(scene->GetLevelDesc(0, &desc)) || desc.Width != width || desc.Height != height)
                return;

            SavedState state(device);
            SetFullscreenStates(device);
            D3DVIEWPORT9 full{ 0, 0, width, height, 0.0f, 1.0f };
            device->SetViewport(&full);
            SetSampler(device, 0, scene, D3DTEXF_POINT);
            DrawFullscreen(device, opaqueTex, opaqueLumaPS);
            opaqueFrame = current.Frame;
        }

        // The scene (a texture the size of the render, not the output) anti-aliased into output, after RenderMotion.
        // Returns whether output was written.
        static bool Resolve(IDirect3DDevice9* device, IDirect3DTexture9* scene, IDirect3DSurface9* output)
        {
            auto mode = EffectiveMode();
            if (!device || !scene || !output || mode == Mode::Off || !current.Valid || motionFrame != current.Frame || resolveFrame == current.Frame)
                return false;
            D3DSURFACE_DESC desc{};
            if (FAILED(scene->GetLevelDesc(0, &desc)) || desc.Width != width || desc.Height != height)
                return false;

            SavedState state(device);
            SetFullscreenStates(device);
            D3DVIEWPORT9 full{ 0, 0, width, height, 0.0f, 1.0f };
            device->SetViewport(&full);

            bool done = false;
            if (mode == Mode::DLAA || mode == Mode::FSR)
            {
                bool reactive = false;
                if (RenderUpscaler(device, mode == Mode::DLAA ? Backend::DLSS : Backend::FSR, scene, reactive))
                {
                    if (mode == Mode::FSR && stabilizePS && detail::Config().StabilizeFSR)
                    {
                        RenderStabilize(device, reactive);
                        RenderOutput(device, historyTex[historyIndex], output);
                    }
                    else
                    {
                        // The TAA history didn't follow these frames
                        historyFrame = 0;
                        RenderOutput(device, upscaledTex, output);
                    }
                    done = true;
                }
            }
            if (!done)
            {
                upscalerFrame = 0;
                RenderResolve(device, scene);
                RenderOutput(device, historyTex[historyIndex], output);
            }

            // The resolve of the next frame compares its motion with this frame's
            IDirect3DSurface9* from = nullptr;
            IDirect3DSurface9* to = nullptr;
            if (SUCCEEDED(motionTex->GetSurfaceLevel(0, &from)) && SUCCEEDED(previousMotionTex->GetSurfaceLevel(0, &to)) &&
                SUCCEEDED(device->StretchRect(from, nullptr, to, nullptr, D3DTEXF_NONE)))
                previousMotionFrame = current.Frame;
            detail::SafeRelease(from);
            detail::SafeRelease(to);

            resolveFrame = current.Frame;
            return true;
        }

        // Where the scene is complete and the HUD isn't drawn yet: motion vectors (unless RenderMotion ran) and the
        // resolve of the scene (a surface the size of the render) into output (may be the same surface). depth: the
        // scene's depth in standard [0, 1] depth. Returns whether output was written. Also starts the hub, so call it
        // every frame, whatever the mode.
        static bool Render(IDirect3DDevice9* device, IDirect3DSurface9* scene, IDirect3DBaseTexture9* depth, IDirect3DSurface9* output)
        {
            Update(device);
            {
                // The camera of the frame the render thread draws (OnRenderedCamera)
                std::lock_guard lock(mutex);
                if (renderedByViewport)
                {
                    if (!renderedMatched)
                        return false;
                    renderedMatched = false;
                    if (rendered.Frame != current.Frame)
                        SetCamera(rendered);
                }
            }
            if (!device || EffectiveMode() == Mode::Off || !scene || !depth || !output || !current.Valid ||
                (!renderedByViewport && current.Frame != frame.load()) || resolveFrame == current.Frame)
                return false;

            D3DSURFACE_DESC desc{};
            if (FAILED(scene->GetDesc(&desc)) || desc.Width != current.Width || desc.Height != current.Height)
                return false;
            if (!EnsureResources(device, desc.Width, desc.Height))
                return false;
            auto sceneTexture = SceneTexture(device, scene, output);
            if (!sceneTexture)
                return false;

            if (motionFrame != current.Frame)
                RenderMotion(device, depth, sceneTexture);
            return Resolve(device, sceneTexture, output);
        }

        // The scene of this frame went through the resolve, DLAA or FSR
        static bool IsSceneResolved()
        {
            return current.Valid && resolveFrame.load() == current.Frame;
        }

        // Whether the hardware can sample the depth-stencil as a texture (INTZ). DXVK and every GPU of the last fifteen
        // years can.
        static bool IntzSupported(IDirect3DDevice9* device)
        {
            IDirect3D9* d3d = nullptr;
            if (!device || FAILED(device->GetDirect3D(&d3d)) || !d3d)
                return false;
            D3DDEVICE_CREATION_PARAMETERS parameters{};
            D3DDISPLAYMODE displayMode{};
            device->GetCreationParameters(&parameters);
            d3d->GetAdapterDisplayMode(parameters.AdapterOrdinal, &displayMode);
            bool ok = SUCCEEDED(d3d->CheckDeviceFormat(parameters.AdapterOrdinal, parameters.DeviceType, displayMode.Format,
                D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_TEXTURE, static_cast<D3DFORMAT>(MAKEFOURCC('I', 'N', 'T', 'Z'))));
            d3d->Release();
            return ok;
        }

        // For games whose scene depth isn't a texture: an INTZ texture of the same size that the game uses as its
        // depth-stencil instead of original. Returns its surface with a reference for the game (which releases it like
        // the original), or null when it can't be done (multisampled, no INTZ): the game keeps the original then.
        static IDirect3DSurface9* ReplaceDepthStencil(IDirect3DDevice9* device, IDirect3DSurface9* original)
        {
            D3DSURFACE_DESC desc{};
            if (!device || !original || FAILED(original->GetDesc(&desc)))
                return nullptr;
            if (desc.MultiSampleType != D3DMULTISAMPLE_NONE)
            {
                detail::Log("Depth: the depth-stencil is multisampled, temporal anti-aliasing needs the game's MSAA off");
                return nullptr;
            }
            if (!IntzSupported(device))
            {
                detail::Log("Depth: INTZ isn't supported");
                return nullptr;
            }
            detail::SafeRelease(intzTex);
            if (FAILED(device->CreateTexture(desc.Width, desc.Height, 1, D3DUSAGE_DEPTHSTENCIL, static_cast<D3DFORMAT>(MAKEFOURCC('I', 'N', 'T', 'Z')),
                D3DPOOL_DEFAULT, &intzTex, nullptr)) || !intzTex)
            {
                detail::Log("Depth: the INTZ texture couldn't be created (%ux%u)", desc.Width, desc.Height);
                return nullptr;
            }
            IDirect3DSurface9* surface = nullptr;
            if (FAILED(intzTex->GetSurfaceLevel(0, &surface)) || !surface)
            {
                detail::SafeRelease(intzTex);
                return nullptr;
            }
            detail::Log("Depth: the depth-stencil is an INTZ texture (%ux%u)", desc.Width, desc.Height);
            return surface;
        }

        // The texture of ReplaceDepthStencil
        static IDirect3DTexture9* DepthTexture()
        {
            return intzTex;
        }

        // Before the device is reset: what the bridge queued is executed, the default pool goes
        static void OnLostDevice()
        {
            detail::TheUpscaler().BeforeReset();
            ReleaseTargets();
            detail::SafeRelease(intzTex);
            detail::SafeRelease(stateBlock);
            failed = false;
        }

        // The shaders belong to the device: after it was released for a new one, not for a reset
        static void OnDeviceReleased()
        {
            OnLostDevice();
            for (auto shader : { &cameraMotionPS, &resolvePS, &outputPS, &copyPS, &depthPS, &lumaPS, &blockMotionPS, &motionSelectPS, &opaqueLumaPS,
                &reactivePS, &stabilizePS })
                detail::SafeRelease(*shader);
        }

        // When the game ends: the hub ends with it (job object), this only lets it go
        static void Shutdown()
        {
            detail::TheUpscaler().Shutdown();
        }

        // Whether DLAA (Backend::DLSS) or FSR can be used now: the hub started and reported the backend
        static bool IsAvailable(Backend backend)
        {
            return detail::TheUpscaler().IsAvailable(backend);
        }

        // Changes whenever IsAvailable may have changed, for settings to ask again
        static uint32_t Generation()
        {
            return detail::TheUpscaler().Generation();
        }

        // Whether DLAA or FSR could become available at all, before the hub runs: FusionFixHub.exe and a vendor runtime
        // are in the game folder (the game must also run on DXVK or D3D9on12 with an interop path: BridgeAvailable)
        static bool BridgePossible()
        {
            auto root = UpscalerBridge::GameRoot();
            std::error_code ec;
            return std::filesystem::is_regular_file(UpscalerBridge::HubPath(root), ec) &&
                (UpscalerBridge::RuntimePresent(root, UpscalerBridge::Backend::DLSS) || UpscalerBridge::RuntimePresent(root, UpscalerBridge::Backend::FSR));
        }

        // Whether DLAA or FSR can become available on this device: an interop path to the hub, the hub and a runtime the
        // GPU can use in the game folder
        static bool BridgeAvailable(IDirect3DDevice9* device)
        {
            return detail::TheUpscaler().BridgeAvailable(device);
        }

        static void Log(const char* text)
        {
            detail::Log("%s", text);
        }
    };
}
