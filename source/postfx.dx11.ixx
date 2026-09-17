module;

#include <common.hxx>
#include <d3d11.h>

export module postfxdx11;

import postfxcommon;

// ---------------------------------------------------------------------------
// PostFX backend for the Direct3D 10, 10.1 and 11 renderers.
//
// Same passes as the Direct3D 9 backend, but every feature level gets its own
// fxc precompiled shaders (win32_40 / win32_41 / win32_50), all of them are
// loaded up front so the console gamma preset can be switched at any time
// without reloading anything.
// ---------------------------------------------------------------------------

// shader resources, see source/resources/Shaders.rc
#define IDR_POSTFX_VS_DX10             161
#define IDR_POSTFX_PS_SMAA_EDGE_DX10   162
#define IDR_POSTFX_PS_SMAA_BLEND_DX10  163
#define IDR_POSTFX_PS_SMAA_OUTPUT_DX10 164
#define IDR_POSTFX_PS_BLUR_H_DX10      165
#define IDR_POSTFX_PS_BLUR_V_DX10      166

#define IDR_POSTFX_VS_DX10_1             171
#define IDR_POSTFX_PS_SMAA_EDGE_DX10_1   172
#define IDR_POSTFX_PS_SMAA_BLEND_DX10_1  173
#define IDR_POSTFX_PS_SMAA_OUTPUT_DX10_1 174
#define IDR_POSTFX_PS_BLUR_H_DX10_1      175
#define IDR_POSTFX_PS_BLUR_V_DX10_1      176

#define IDR_POSTFX_VS_DX11             181
#define IDR_POSTFX_PS_SMAA_EDGE_DX11   182
#define IDR_POSTFX_PS_SMAA_BLEND_DX11  183
#define IDR_POSTFX_PS_SMAA_OUTPUT_DX11 184
#define IDR_POSTFX_PS_BLUR_H_DX11      185
#define IDR_POSTFX_PS_BLUR_V_DX11      186

// console gamma, a vertex/pixel shader pair per preset
#define IDR_VS_BlitXenonGammaDX10   111
#define IDR_PS_BlitXenonGammaDX10   112
#define IDR_VS_BlitCellGammaDX10    113
#define IDR_PS_BlitCellGammaDX10    114

#define IDR_VS_BlitXenonGammaDX10_1 121
#define IDR_PS_BlitXenonGammaDX10_1 122
#define IDR_VS_BlitCellGammaDX10_1  123
#define IDR_PS_BlitCellGammaDX10_1  124

#define IDR_VS_BlitXenonGammaDX11   131
#define IDR_PS_BlitXenonGammaDX11   132
#define IDR_VS_BlitCellGammaDX11    133
#define IDR_PS_BlitCellGammaDX11    134

// precomputed SMAA textures
#define IDR_POSTFX_AREATEX   201
#define IDR_POSTFX_SEARCHTEX 202

export namespace PostFX11
{
    struct VertexFormat
    {
        float fPosition[4];
        float fTexCoord[2];
    };

    // -----------------------------------------------------------------------
    // one entry per feature level the game can create a device with
    // -----------------------------------------------------------------------
    struct ShaderProfile
    {
        D3D_FEATURE_LEVEL featureLevel;
        int iVS;
        int iSmaa[3];
        int iBlur[2];
        int iGammaVS[2];
        int iGammaPS[2];
    };

    inline const ShaderProfile shaderProfiles[] =
    {
        {
            D3D_FEATURE_LEVEL_10_0,
            IDR_POSTFX_VS_DX10,
            { IDR_POSTFX_PS_SMAA_EDGE_DX10, IDR_POSTFX_PS_SMAA_BLEND_DX10, IDR_POSTFX_PS_SMAA_OUTPUT_DX10 },
            { IDR_POSTFX_PS_BLUR_H_DX10, IDR_POSTFX_PS_BLUR_V_DX10 },
            { IDR_VS_BlitXenonGammaDX10, IDR_VS_BlitCellGammaDX10 },
            { IDR_PS_BlitXenonGammaDX10, IDR_PS_BlitCellGammaDX10 },
        },
        {
            D3D_FEATURE_LEVEL_10_1,
            IDR_POSTFX_VS_DX10_1,
            { IDR_POSTFX_PS_SMAA_EDGE_DX10_1, IDR_POSTFX_PS_SMAA_BLEND_DX10_1, IDR_POSTFX_PS_SMAA_OUTPUT_DX10_1 },
            { IDR_POSTFX_PS_BLUR_H_DX10_1, IDR_POSTFX_PS_BLUR_V_DX10_1 },
            { IDR_VS_BlitXenonGammaDX10_1, IDR_VS_BlitCellGammaDX10_1 },
            { IDR_PS_BlitXenonGammaDX10_1, IDR_PS_BlitCellGammaDX10_1 },
        },
        {
            D3D_FEATURE_LEVEL_11_0,
            IDR_POSTFX_VS_DX11,
            { IDR_POSTFX_PS_SMAA_EDGE_DX11, IDR_POSTFX_PS_SMAA_BLEND_DX11, IDR_POSTFX_PS_SMAA_OUTPUT_DX11 },
            { IDR_POSTFX_PS_BLUR_H_DX11, IDR_POSTFX_PS_BLUR_V_DX11 },
            { IDR_VS_BlitXenonGammaDX11, IDR_VS_BlitCellGammaDX11 },
            { IDR_PS_BlitXenonGammaDX11, IDR_PS_BlitCellGammaDX11 },
        },
    };

    struct TargetInfo
    {
        DXGI_FORMAT format = DXGI_FORMAT_UNKNOWN;
        UINT width = 0;
        UINT height = 0;
        UINT sampleCount = 1;
    };

    struct SavedState
    {
        ID3D11RenderTargetView* pRenderTarget = nullptr;
        ID3D11DepthStencilView* pDepthStencil = nullptr;

        ID3D11BlendState* pBlendState = nullptr;
        FLOAT fBlendFactor[4] = {};
        UINT uSampleMask = 0xFFFFFFFF;

        ID3D11DepthStencilState* pDepthStencilState = nullptr;
        UINT uStencilRef = 0;

        ID3D11RasterizerState* pRasterizerState = nullptr;

        ID3D11VertexShader* pVertexShader = nullptr;
        ID3D11PixelShader* pPixelShader = nullptr;

        ID3D11Buffer* pVertexBuffer = nullptr;
        UINT uVertexStride = 0;
        UINT uVertexOffset = 0;

        ID3D11InputLayout* pInputLayout = nullptr;
        D3D11_PRIMITIVE_TOPOLOGY topology = D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST;

        ID3D11ShaderResourceView* pShaderResources[3] = {};
        ID3D11SamplerState* pSamplers[2] = {};
        ID3D11Buffer* pConstantBuffer = nullptr;

        UINT uViewports = 0;
        D3D11_VIEWPORT viewports[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE] = {};

        UINT uScissors = 0;
        D3D11_RECT scissors[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE] = {};
    };

    inline ID3D11Device* pDevice = nullptr;
    inline ID3D11DeviceContext* pContext = nullptr;
    inline D3D_FEATURE_LEVEL featureLevel = (D3D_FEATURE_LEVEL)0;
    inline bool bInitialized = false;

    inline ID3D11VertexShader* pVS = nullptr;
    inline ID3D11PixelShader* pPSSmaa[3] = {};
    inline ID3D11PixelShader* pPSBlur[2] = {};
    inline ID3D11VertexShader* pVSGamma[2] = {};
    inline ID3D11PixelShader* pPSGamma[2] = {};

    inline ID3D11Buffer* pVertexBuffer = nullptr;
    inline ID3D11InputLayout* pInputLayout = nullptr;
    inline ID3D11SamplerState* pLinearSampler = nullptr;
    inline ID3D11SamplerState* pPointSampler = nullptr;
    inline ID3D11BlendState* pBlendState = nullptr;
    inline ID3D11DepthStencilState* pDepthStencilState = nullptr;
    inline ID3D11RasterizerState* pRasterizerState = nullptr;
    inline ID3D11Buffer* pConstantBuffer = nullptr;

    inline ID3D11Texture2D* pAreaTexture = nullptr;
    inline ID3D11ShaderResourceView* pAreaTextureView = nullptr;
    inline ID3D11Texture2D* pSearchTexture = nullptr;
    inline ID3D11ShaderResourceView* pSearchTextureView = nullptr;

    inline ID3D11Texture2D* pSceneTexture = nullptr;
    inline ID3D11ShaderResourceView* pSceneTextureView = nullptr;
    inline ID3D11Texture2D* pResolveTexture = nullptr;
    inline ID3D11ShaderResourceView* pResolveTextureView = nullptr;
    inline ID3D11Texture2D* pEdgeTexture = nullptr;
    inline ID3D11RenderTargetView* pEdgeView = nullptr;
    inline ID3D11ShaderResourceView* pEdgeTextureView = nullptr;
    inline ID3D11Texture2D* pBlendTexture = nullptr;
    inline ID3D11RenderTargetView* pBlendView = nullptr;
    inline ID3D11ShaderResourceView* pBlendTextureView = nullptr;
    inline ID3D11Texture2D* pBlurTexture = nullptr;
    inline ID3D11RenderTargetView* pBlurView = nullptr;
    inline ID3D11ShaderResourceView* pBlurTextureView = nullptr;

    inline ID3D11Texture2D* pCachedBackBuffer = nullptr;
    inline ID3D11RenderTargetView* pBackBufferView = nullptr;

    inline unsigned int uCreatedResources = 0;
    inline TargetInfo targetInfo{};

    enum PostFXResources
    {
        RES_SCENE = 1 << 0,
        RES_RESOLVE = 1 << 1,
        RES_SMAA = 1 << 2,
        RES_BLUR = 1 << 3,
    };

    template <typename T>
    inline void SafeRelease(T*& pResource)
    {
        if (pResource)
        {
            pResource->Release();
            pResource = nullptr;
        }
    }

    inline void ReleaseTextures()
    {
        SafeRelease(pBlurTextureView);
        SafeRelease(pBlurView);
        SafeRelease(pBlurTexture);
        SafeRelease(pBlendTextureView);
        SafeRelease(pBlendView);
        SafeRelease(pBlendTexture);
        SafeRelease(pEdgeTextureView);
        SafeRelease(pEdgeView);
        SafeRelease(pEdgeTexture);
        SafeRelease(pResolveTextureView);
        SafeRelease(pResolveTexture);
        SafeRelease(pSceneTextureView);
        SafeRelease(pSceneTexture);
    }

    inline void ReleaseBackBuffer()
    {
        SafeRelease(pBackBufferView);
        SafeRelease(pCachedBackBuffer);
    }

    inline void ReleaseShaders()
    {
        SafeRelease(pVS);
        SafeRelease(pPSSmaa[0]);
        SafeRelease(pPSSmaa[1]);
        SafeRelease(pPSSmaa[2]);
        SafeRelease(pPSBlur[0]);
        SafeRelease(pPSBlur[1]);
        SafeRelease(pVSGamma[0]);
        SafeRelease(pPSGamma[0]);
        SafeRelease(pVSGamma[1]);
        SafeRelease(pPSGamma[1]);
    }

    inline void ReleaseDeviceObjects()
    {
        ReleaseTextures();
        ReleaseBackBuffer();
        SafeRelease(pInputLayout);
        SafeRelease(pVertexBuffer);
        SafeRelease(pLinearSampler);
        SafeRelease(pPointSampler);
        SafeRelease(pBlendState);
        SafeRelease(pDepthStencilState);
        SafeRelease(pRasterizerState);
        SafeRelease(pConstantBuffer);
        SafeRelease(pAreaTextureView);
        SafeRelease(pAreaTexture);
        SafeRelease(pSearchTextureView);
        SafeRelease(pSearchTexture);
    }

    inline void Shutdown()
    {
        ReleaseShaders();
        ReleaseDeviceObjects();
        SafeRelease(pContext);
        SafeRelease(pDevice);
        bInitialized = false;
        uCreatedResources = 0;
        targetInfo = {};
    }

    // A swapchain resize invalidates every resource sized after the render
    // target and the cached backbuffer, drop them, the next frame recreates them.
    inline void OnResize()
    {
        ReleaseTextures();
        ReleaseBackBuffer();
        uCreatedResources = 0;
        targetInfo = {};
    }

    // -----------------------------------------------------------------------
    // shader and state objects
    // -----------------------------------------------------------------------
    inline bool LoadShaderResource(HMODULE hModule, int iResourceId, const void** ppData, UINT* puSize)
    {
        return LoadPostFXResource(hModule, iResourceId, ppData, puSize);
    }

    inline const ShaderProfile& GetShaderProfile(D3D_FEATURE_LEVEL level)
    {
        // an 11.1 or 12.0 device runs the 11.0 shaders just fine, same for 10.1
        const ShaderProfile* pProfile = &shaderProfiles[0];
        for (const auto& profile : shaderProfiles)
        {
            if (level >= profile.featureLevel)
                pProfile = &profile;
        }

        return *pProfile;
    }

    inline bool CreatePixelShaderFromResource(HMODULE hModule, int iResourceId, ID3D11PixelShader** ppShader, unsigned int uFailure)
    {
        const void* pData = nullptr;
        UINT uSize = 0;

        if (!LoadShaderResource(hModule, iResourceId, &pData, &uSize) ||
            FAILED(pDevice->CreatePixelShader(pData, uSize, nullptr, ppShader)))
        {
            ReportPostFXFailure(uFailure, "pixel shader", iResourceId);
            return false;
        }

        return true;
    }

    inline bool CreateVertexShaderFromResource(HMODULE hModule, int iResourceId, ID3D11VertexShader** ppShader, unsigned int uFailure)
    {
        const void* pData = nullptr;
        UINT uSize = 0;

        if (!LoadShaderResource(hModule, iResourceId, &pData, &uSize) ||
            FAILED(pDevice->CreateVertexShader(pData, uSize, nullptr, ppShader)))
        {
            ReportPostFXFailure(uFailure, "vertex shader", iResourceId);
            return false;
        }

        return true;
    }

    inline bool LoadShaders(D3D_FEATURE_LEVEL level)
    {
        if (pVS)
            return true;

        HMODULE hModule = GetPostFXModuleHandle((const void*)&LoadShaders);
        const ShaderProfile& profile = GetShaderProfile(level);
        const void* pData = nullptr;
        UINT uSize = 0;

        // fullscreen vertex shader, also used for the input layout. Everything
        // else depends on it, so this is the only part that can fail the setup.
        if (!LoadShaderResource(hModule, profile.iVS, &pData, &uSize))
        {
            ReportPostFXFailure(POSTFX_FAILURE_COMMON_SHADERS, "vertex shader resource", profile.iVS);
            return false;
        }
        if (FAILED(pDevice->CreateVertexShader(pData, uSize, nullptr, &pVS)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_COMMON_SHADERS, "vertex shader", profile.iVS);
            return false;
        }

        const D3D11_INPUT_ELEMENT_DESC layout[] =
        {
            { "POSITION", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, offsetof(VertexFormat, fPosition), D3D11_INPUT_PER_VERTEX_DATA, 0 },
            { "TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT,       0, offsetof(VertexFormat, fTexCoord), D3D11_INPUT_PER_VERTEX_DATA, 0 },
        };

        if (FAILED(pDevice->CreateInputLayout(layout, ARRAYSIZE(layout), pData, uSize, &pInputLayout)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_COMMON_SHADERS, "input layout", profile.iVS);
            return false;
        }

        // One set per effect. A set that cannot be created leaves its shaders
        // empty, which disables that effect and nothing else, the passes check
        // for their own shaders before they draw.
        for (int i = 0; i < 3; i++)
            CreatePixelShaderFromResource(hModule, profile.iSmaa[i], &pPSSmaa[i], POSTFX_FAILURE_SMAA_SHADERS);

        for (int i = 0; i < 2; i++)
        {
            CreatePixelShaderFromResource(hModule, profile.iBlur[i], &pPSBlur[i], POSTFX_FAILURE_BLUR_SHADERS);

            // both console gamma presets stay resident, the ini decides which
            // one is used while rendering
            CreateVertexShaderFromResource(hModule, profile.iGammaVS[i], &pVSGamma[i], POSTFX_FAILURE_GAMMA_SHADERS);
            CreatePixelShaderFromResource(hModule, profile.iGammaPS[i], &pPSGamma[i], POSTFX_FAILURE_GAMMA_SHADERS);
        }

        return true;
    }

    inline bool LoadTextureFromResource(HMODULE hModule, int iResourceId, ID3D11Texture2D** ppTexture, ID3D11ShaderResourceView** ppView)
    {
        const void* pData = nullptr;
        UINT uSize = 0;
        PostFXTextureData textureData{};

        if (!LoadPostFXResource(hModule, iResourceId, &pData, &uSize) ||
            !ParsePostFXTexture(pData, uSize, textureData))
        {
            ReportPostFXFailure(POSTFX_FAILURE_SMAA_TEXTURES, "smaa texture resource", iResourceId);
            return false;
        }

        D3D11_TEXTURE2D_DESC desc{};
        desc.Width = textureData.uWidth;
        desc.Height = textureData.uHeight;
        desc.MipLevels = 1;
        desc.ArraySize = 1;
        desc.Format = textureData.uBytesPerPixel == 2 ? DXGI_FORMAT_R8G8_UNORM : DXGI_FORMAT_R8_UNORM;
        desc.SampleDesc.Count = 1;
        desc.Usage = D3D11_USAGE_IMMUTABLE;
        desc.BindFlags = D3D11_BIND_SHADER_RESOURCE;

        D3D11_SUBRESOURCE_DATA initData{};
        initData.pSysMem = textureData.pPixels;
        initData.SysMemPitch = textureData.uWidth * textureData.uBytesPerPixel;

        if (FAILED(pDevice->CreateTexture2D(&desc, &initData, ppTexture)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_SMAA_TEXTURES, "smaa texture", iResourceId);
            return false;
        }

        if (FAILED(pDevice->CreateShaderResourceView(*ppTexture, nullptr, ppView)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_SMAA_TEXTURES, "smaa texture view", iResourceId);
            return false;
        }

        return true;
    }

    inline bool CreateDeviceObjects()
    {
        // fullscreen triangle strip, clip space, oversized by one pixel so
        // that the texture coordinate 0..1 covers the texel centers
        const VertexFormat vertices[4] =
        {
            { { -1.0f,  1.0f, 0.5f, 1.0f }, { 0.0f, 0.0f } },
            { {  1.0f,  1.0f, 0.5f, 1.0f }, { 1.0f, 0.0f } },
            { { -1.0f, -1.0f, 0.5f, 1.0f }, { 0.0f, 1.0f } },
            { {  1.0f, -1.0f, 0.5f, 1.0f }, { 1.0f, 1.0f } },
        };

        D3D11_BUFFER_DESC bufferDesc{};
        bufferDesc.ByteWidth = sizeof(vertices);
        bufferDesc.Usage = D3D11_USAGE_IMMUTABLE;
        bufferDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;

        D3D11_SUBRESOURCE_DATA initData{};
        initData.pSysMem = vertices;

        if (FAILED(pDevice->CreateBuffer(&bufferDesc, &initData, &pVertexBuffer)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_STATE_OBJECTS, "vertex buffer");
            return false;
        }

        D3D11_SAMPLER_DESC samplerDesc{};
        samplerDesc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
        samplerDesc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
        samplerDesc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
        samplerDesc.ComparisonFunc = D3D11_COMPARISON_NEVER;
        samplerDesc.MaxLOD = D3D11_FLOAT32_MAX;

        samplerDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
        if (FAILED(pDevice->CreateSamplerState(&samplerDesc, &pLinearSampler)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_STATE_OBJECTS, "linear sampler");
            return false;
        }

        samplerDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_POINT;
        if (FAILED(pDevice->CreateSamplerState(&samplerDesc, &pPointSampler)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_STATE_OBJECTS, "point sampler");
            return false;
        }

        D3D11_BLEND_DESC blendDesc{};
        blendDesc.RenderTarget[0].BlendEnable = FALSE;
        blendDesc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
        if (FAILED(pDevice->CreateBlendState(&blendDesc, &pBlendState)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_STATE_OBJECTS, "blend state");
            return false;
        }

        D3D11_DEPTH_STENCIL_DESC depthStencilDesc{};
        depthStencilDesc.DepthEnable = FALSE;
        depthStencilDesc.StencilEnable = FALSE;
        if (FAILED(pDevice->CreateDepthStencilState(&depthStencilDesc, &pDepthStencilState)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_STATE_OBJECTS, "depth stencil state");
            return false;
        }

        D3D11_RASTERIZER_DESC rasterizerDesc{};
        rasterizerDesc.FillMode = D3D11_FILL_SOLID;
        rasterizerDesc.CullMode = D3D11_CULL_NONE;
        rasterizerDesc.ScissorEnable = FALSE;
        rasterizerDesc.DepthClipEnable = TRUE;
        if (FAILED(pDevice->CreateRasterizerState(&rasterizerDesc, &pRasterizerState)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_STATE_OBJECTS, "rasterizer state");
            return false;
        }

        D3D11_BUFFER_DESC constantBufferDesc{};
        constantBufferDesc.ByteWidth = sizeof(PostFXConstants);
        constantBufferDesc.Usage = D3D11_USAGE_DYNAMIC;
        constantBufferDesc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
        constantBufferDesc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        if (FAILED(pDevice->CreateBuffer(&constantBufferDesc, nullptr, &pConstantBuffer)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_STATE_OBJECTS, "constant buffer");
            return false;
        }

        return true;
    }

    // The game hands over whatever it keeps in its globals - the device, a
    // device context or the swapchain - and a device is derived from it.
    // Everything else is derived from that device.
    inline bool GetDeviceFromObject(IUnknown* pObject, ID3D11Device** ppDevice)
    {
        if (!pObject)
            return false;

        if (SUCCEEDED(pObject->QueryInterface(__uuidof(ID3D11Device), (void**)ppDevice)) && *ppDevice)
            return true;

        ID3D11DeviceContext* pDeviceContext = nullptr;
        if (SUCCEEDED(pObject->QueryInterface(__uuidof(ID3D11DeviceContext), (void**)&pDeviceContext)) && pDeviceContext)
        {
            pDeviceContext->GetDevice(ppDevice);
            pDeviceContext->Release();
            if (*ppDevice)
                return true;
        }

        IDXGISwapChain* pSwapChain = nullptr;
        if (SUCCEEDED(pObject->QueryInterface(__uuidof(IDXGISwapChain), (void**)&pSwapChain)) && pSwapChain)
        {
            pSwapChain->GetDevice(__uuidof(ID3D11Device), (void**)ppDevice);
            pSwapChain->Release();
            if (*ppDevice)
                return true;
        }

        ReportPostFXFailure(POSTFX_FAILURE_DEVICE, "device not resolved from object");
        return false;
    }

    // Everything is created for the device that is currently in use, when the
    // game swaps the device (renderer change, display change, device reset)
    // all of it is rebuilt for the new one.
    inline bool EnsureInitialized(IUnknown* pObject)
    {
        ID3D11Device* pResolvedDevice = nullptr;
        if (!GetDeviceFromObject(pObject, &pResolvedDevice))
            return false;

        if (bInitialized && pResolvedDevice == pDevice)
        {
            pResolvedDevice->Release();
            return true;
        }

        Shutdown();
        pDevice = pResolvedDevice;

        pDevice->GetImmediateContext(&pContext);
        featureLevel = pDevice->GetFeatureLevel();

        if (!LoadShaders(featureLevel) || !CreateDeviceObjects())
        {
            Shutdown();
            return false;
        }
        bInitialized = true;
        return true;
    }

    // -----------------------------------------------------------------------
    // render target sized resources
    // -----------------------------------------------------------------------
    inline bool CreateRenderTargetTexture(const TargetInfo& info, DXGI_FORMAT format, bool bShaderResource,
        ID3D11Texture2D** ppTexture, ID3D11RenderTargetView** ppRenderTargetView, ID3D11ShaderResourceView** ppShaderResourceView)
    {
        D3D11_TEXTURE2D_DESC desc{};
        desc.Width = info.width;
        desc.Height = info.height;
        desc.MipLevels = 1;
        desc.ArraySize = 1;
        desc.Format = format;
        desc.SampleDesc.Count = 1;
        desc.Usage = D3D11_USAGE_DEFAULT;
        desc.BindFlags = D3D11_BIND_RENDER_TARGET | (bShaderResource ? D3D11_BIND_SHADER_RESOURCE : 0);

        if (FAILED(pDevice->CreateTexture2D(&desc, nullptr, ppTexture)))
            return false;

        if (ppRenderTargetView && FAILED(pDevice->CreateRenderTargetView(*ppTexture, nullptr, ppRenderTargetView)))
            return false;

        if (ppShaderResourceView && FAILED(pDevice->CreateShaderResourceView(*ppTexture, nullptr, ppShaderResourceView)))
            return false;

        return true;
    }

    // The resources are sized after the target the current call renders into,
    // so both calls of a frame agree on the set when they agree on the size.
    inline bool EnsureResources(const TargetInfo& info, const PostFXOptions& options)
    {
        unsigned int uRequired = RES_SCENE;
        if (options.bSmaa)
            uRequired |= RES_SMAA;
        if (options.bBlur)
            uRequired |= RES_BLUR;
        if (info.sampleCount > 1)
            uRequired |= RES_RESOLVE;

        const bool bMatchesCurrent = (uCreatedResources == uRequired) &&
            targetInfo.format == info.format &&
            targetInfo.width == info.width &&
            targetInfo.height == info.height &&
            targetInfo.sampleCount == info.sampleCount;

        if (bMatchesCurrent)
            return true;

        ReleaseTextures();

        if (!CreateRenderTargetTexture(info, info.format, true, &pSceneTexture, nullptr, &pSceneTextureView))
        {
            ReportPostFXFailure(POSTFX_FAILURE_TARGETS, "scene texture", (int)info.width);
            ReleaseTextures();
            return false;
        }

        if ((uRequired & RES_RESOLVE) &&
            !CreateRenderTargetTexture(info, info.format, true, &pResolveTexture, nullptr, &pResolveTextureView))
        {
            ReportPostFXFailure(POSTFX_FAILURE_TARGETS, "resolve texture", (int)info.width);
            ReleaseTextures();
            return false;
        }

        // SMAA intermediate buffers, they only have to carry the edge data
        if ((uRequired & RES_SMAA) &&
            (!CreateRenderTargetTexture(info, DXGI_FORMAT_R8G8B8A8_UNORM, true, &pEdgeTexture, &pEdgeView, &pEdgeTextureView) ||
             !CreateRenderTargetTexture(info, DXGI_FORMAT_R8G8B8A8_UNORM, true, &pBlendTexture, &pBlendView, &pBlendTextureView)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_TARGETS, "smaa targets", (int)info.width);
            ReleaseTextures();
            return false;
        }

        if ((uRequired & RES_BLUR) &&
            !CreateRenderTargetTexture(info, info.format, true, &pBlurTexture, &pBlurView, &pBlurTextureView))
        {
            ReportPostFXFailure(POSTFX_FAILURE_TARGETS, "blur texture", (int)info.width);
            ReleaseTextures();
            return false;
        }

        // The precomputed SMAA textures, loaded the first time SMAA is actually
        // asked for, so that they cannot keep the other effects from running.
        if (uRequired & RES_SMAA)
        {
            HMODULE hModule = GetPostFXModuleHandle((const void*)&EnsureResources);
            if (!pAreaTexture)
                LoadTextureFromResource(hModule, IDR_POSTFX_AREATEX, &pAreaTexture, &pAreaTextureView);
            if (!pSearchTexture)
                LoadTextureFromResource(hModule, IDR_POSTFX_SEARCHTEX, &pSearchTexture, &pSearchTextureView);
        }

        targetInfo = info;
        uCreatedResources = uRequired;
        return true;
    }

    // -----------------------------------------------------------------------
    // state
    // -----------------------------------------------------------------------
    inline void SaveState(SavedState& state)
    {
        pContext->OMGetRenderTargets(1, &state.pRenderTarget, &state.pDepthStencil);
        pContext->OMGetBlendState(&state.pBlendState, state.fBlendFactor, &state.uSampleMask);
        pContext->OMGetDepthStencilState(&state.pDepthStencilState, &state.uStencilRef);
        pContext->RSGetState(&state.pRasterizerState);

        pContext->VSGetShader(&state.pVertexShader, nullptr, nullptr);
        pContext->PSGetShader(&state.pPixelShader, nullptr, nullptr);

        pContext->IAGetVertexBuffers(0, 1, &state.pVertexBuffer, &state.uVertexStride, &state.uVertexOffset);
        pContext->IAGetInputLayout(&state.pInputLayout);
        pContext->IAGetPrimitiveTopology(&state.topology);

        pContext->PSGetShaderResources(0, ARRAYSIZE(state.pShaderResources), state.pShaderResources);
        pContext->PSGetSamplers(0, ARRAYSIZE(state.pSamplers), state.pSamplers);
        pContext->PSGetConstantBuffers(0, 1, &state.pConstantBuffer);

        state.uViewports = D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
        pContext->RSGetViewports(&state.uViewports, state.viewports);

        state.uScissors = D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
        pContext->RSGetScissorRects(&state.uScissors, state.scissors);
    }

    inline void RestoreState(SavedState& state)
    {
        pContext->OMSetRenderTargets(1, &state.pRenderTarget, state.pDepthStencil);
        pContext->OMSetBlendState(state.pBlendState, state.fBlendFactor, state.uSampleMask);
        pContext->OMSetDepthStencilState(state.pDepthStencilState, state.uStencilRef);
        pContext->RSSetState(state.pRasterizerState);

        pContext->VSSetShader(state.pVertexShader, nullptr, 0);
        pContext->PSSetShader(state.pPixelShader, nullptr, 0);

        pContext->IASetVertexBuffers(0, 1, &state.pVertexBuffer, &state.uVertexStride, &state.uVertexOffset);
        pContext->IASetInputLayout(state.pInputLayout);
        pContext->IASetPrimitiveTopology(state.topology);

        pContext->PSSetShaderResources(0, ARRAYSIZE(state.pShaderResources), state.pShaderResources);
        pContext->PSSetSamplers(0, ARRAYSIZE(state.pSamplers), state.pSamplers);
        pContext->PSSetConstantBuffers(0, 1, &state.pConstantBuffer);

        pContext->RSSetViewports(state.uViewports, state.viewports);
        pContext->RSSetScissorRects(state.uScissors, state.scissors);

        // release the references the Get calls handed out
        SafeRelease(state.pRenderTarget);
        SafeRelease(state.pDepthStencil);
        SafeRelease(state.pBlendState);
        SafeRelease(state.pDepthStencilState);
        SafeRelease(state.pRasterizerState);
        SafeRelease(state.pVertexShader);
        SafeRelease(state.pPixelShader);
        SafeRelease(state.pVertexBuffer);
        SafeRelease(state.pInputLayout);
        SafeRelease(state.pConstantBuffer);
        for (auto& pResource : state.pShaderResources)
            SafeRelease(pResource);
        for (auto& pSampler : state.pSamplers)
            SafeRelease(pSampler);
    }

    inline void SetupPass(ID3D11RenderTargetView* pTarget, ID3D11VertexShader* pVertexShader,
        ID3D11PixelShader* pPixelShader, const PostFXConstants& constants)
    {
        D3D11_MAPPED_SUBRESOURCE mapped{};
        if (SUCCEEDED(pContext->Map(pConstantBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, &mapped)))
        {
            memcpy(mapped.pData, &constants, sizeof(constants));
            pContext->Unmap(pConstantBuffer, 0);
        }

        const D3D11_VIEWPORT viewport = { 0.0f, 0.0f, (float)targetInfo.width, (float)targetInfo.height, 0.0f, 1.0f };

        pContext->OMSetRenderTargets(1, &pTarget, nullptr);
        pContext->OMSetBlendState(pBlendState, nullptr, 0xFFFFFFFF);
        pContext->OMSetDepthStencilState(pDepthStencilState, 0);
        pContext->RSSetState(pRasterizerState);
        pContext->RSSetViewports(1, &viewport);

        const UINT uStride = sizeof(VertexFormat);
        const UINT uOffset = 0;
        pContext->IASetInputLayout(pInputLayout);
        pContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP);
        pContext->IASetVertexBuffers(0, 1, &pVertexBuffer, &uStride, &uOffset);

        pContext->VSSetShader(pVertexShader, nullptr, 0);
        pContext->PSSetShader(pPixelShader, nullptr, 0);
        pContext->PSSetConstantBuffers(0, 1, &pConstantBuffer);
        pContext->PSSetSamplers(0, 1, &pLinearSampler);
        pContext->PSSetSamplers(1, 1, &pPointSampler);
    }

    inline void BindTextures(ID3D11ShaderResourceView* const* ppViews, UINT uCount)
    {
        pContext->PSSetShaderResources(0, uCount, ppViews);
    }

    inline void DrawQuad()
    {
        pContext->Draw(4, 0);
    }

    // -----------------------------------------------------------------------
    // passes
    // -----------------------------------------------------------------------
    inline bool RenderSmaa(ID3D11RenderTargetView* pTarget, ID3D11ShaderResourceView* pSceneView, bool bDebug)
    {
        if (!(uCreatedResources & RES_SMAA) || !pPSSmaa[0] || !pPSSmaa[1] || !pPSSmaa[2])
            return false;

        if (!pAreaTextureView || !pSearchTextureView)
            return false;

        const PostFXConstants constants = MakePostFXConstants(targetInfo.width, targetInfo.height, 1.0f);

        // 1. edge detection
        const float fClearColor[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
        pContext->ClearRenderTargetView(pEdgeView, fClearColor);
        SetupPass(pEdgeView, pVS, pPSSmaa[0], constants);
        BindTextures(&pSceneView, 1);
        DrawQuad();

        // Diagnostic view: the detected edges, white on black, through the gamma
        // pair, which passes a 0 and a 1 through unchanged. A frame that stays
        // black means the edge detection found nothing to antialias.
        if (bDebug)
        {
            SetupPass(pTarget, pVSGamma[0], pPSGamma[0], constants);
            BindTextures(&pEdgeTextureView, 1);
            DrawQuad();
            return true;
        }

        // 2. blending weights
        pContext->ClearRenderTargetView(pBlendView, fClearColor);
        SetupPass(pBlendView, pVS, pPSSmaa[1], constants);
        ID3D11ShaderResourceView* pBlendViews[3] = { pEdgeTextureView, pAreaTextureView, pSearchTextureView };
        BindTextures(pBlendViews, 3);
        DrawQuad();

        // 3. neighborhood blending, straight back into the target we read from
        SetupPass(pTarget, pVS, pPSSmaa[2], constants);
        ID3D11ShaderResourceView* pOutputViews[2] = { pSceneView, pBlendTextureView };
        BindTextures(pOutputViews, 2);
        DrawQuad();

        return true;
    }

    inline bool RenderBlur(ID3D11RenderTargetView* pTarget, ID3D11ShaderResourceView* pSceneView, float fBlurStrength)
    {
        if (!(uCreatedResources & RES_BLUR) || !pPSBlur[0] || !pPSBlur[1])
            return false;

        if (fBlurStrength <= 0.001f)
            return false;

        const PostFXConstants constants = MakePostFXConstants(targetInfo.width, targetInfo.height, fBlurStrength);

        SetupPass(pBlurView, pVS, pPSBlur[0], constants);
        BindTextures(&pSceneView, 1);
        DrawQuad();

        SetupPass(pTarget, pVS, pPSBlur[1], constants);
        BindTextures(&pBlurTextureView, 1);
        DrawQuad();

        return true;
    }

    inline bool RenderGamma(ID3D11RenderTargetView* pTarget, ID3D11ShaderResourceView* pSceneView, int nConsoleGamma)
    {
        if (nConsoleGamma < 1 || nConsoleGamma > 2)
            return false;

        // both presets are resident, the ini value decides per frame
        if (!pVSGamma[nConsoleGamma - 1] || !pPSGamma[nConsoleGamma - 1])
            return false;

        const PostFXConstants constants = MakePostFXConstants(targetInfo.width, targetInfo.height, 1.0f);

        SetupPass(pTarget, pVSGamma[nConsoleGamma - 1], pPSGamma[nConsoleGamma - 1], constants);
        BindTextures(&pSceneView, 1);
        DrawQuad();

        return true;
    }

    // Reads a texture and returns a shader resource view holding its contents,
    // resolving multisampling when needed.
    inline bool UpdateSceneTexture(ID3D11Resource* pSource, UINT uSampleCount, ID3D11ShaderResourceView** ppSceneView)
    {
        // The destination is the texture the previous pass read from, and a
        // resource may not be bound as a shader resource while it is written to.
        ID3D11ShaderResourceView* pNullViews[3] = {};
        pContext->PSSetShaderResources(0, 3, pNullViews);

        bool bResult = false;

        if (uSampleCount > 1)
        {
            if (pResolveTexture)
            {
                pContext->ResolveSubresource(pResolveTexture, 0, pSource, 0, targetInfo.format);
                *ppSceneView = pResolveTextureView;
                bResult = true;
            }
            else
            {
                ReportPostFXFailure(POSTFX_FAILURE_SCENE_COPY, "no resolve target for sample count", (int)uSampleCount);
            }
        }
        else
        {
            // Same format and size, so the whole resource is copied, the read
            // and the write of an end of frame pass share the backbuffer size.
            pContext->CopyResource(pSceneTexture, pSource);
            *ppSceneView = pSceneTextureView;
            bResult = true;
        }

        return bResult;
    }

    // Reads the source texture and runs the requested passes in order. Every
    // pass reads what the previous one left in the target, so the copy is
    // refreshed before each of them, which is what makes SMAA, the blur and the
    // gamma stack on top of each other in a single call.
    inline bool RenderEffects(ID3D11Resource* pSource, ID3D11RenderTargetView* pTarget, UINT uSampleCount,
        const PostFXOptions& options, unsigned int uStages)
    {
        bool bRendered = false;

        auto GetSceneView = [&]() -> ID3D11ShaderResourceView*
        {
            ID3D11ShaderResourceView* pSceneView = nullptr;
            return UpdateSceneTexture(pSource, uSampleCount, &pSceneView) ? pSceneView : nullptr;
        };

        if (options.bSmaa && (uStages & POSTFX_STAGE_SMAA))
        {
            if (ID3D11ShaderResourceView* pSceneView = GetSceneView())
                bRendered |= RenderSmaa(pTarget, pSceneView, options.bSmaaDebug);
        }

        if (options.bBlur && (uStages & POSTFX_STAGE_BLUR))
        {
            if (ID3D11ShaderResourceView* pSceneView = GetSceneView())
                bRendered |= RenderBlur(pTarget, pSceneView, options.fBlurStrength);
        }

        if (options.nConsoleGamma && (uStages & POSTFX_STAGE_GAMMA))
        {
            if (ID3D11ShaderResourceView* pSceneView = GetSceneView())
                bRendered |= RenderGamma(pTarget, pSceneView, options.nConsoleGamma);
        }

        return bRendered;
    }

    // Size and format of a texture.
    inline bool GetTextureInfo(ID3D11Resource* pResource, TargetInfo& info)
    {
        ID3D11Texture2D* pTexture = nullptr;
        if (FAILED(pResource->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&pTexture)) || !pTexture)
            return false;

        D3D11_TEXTURE2D_DESC desc{};
        pTexture->GetDesc(&desc);
        pTexture->Release();

        info.format = desc.Format;
        info.width = desc.Width;
        info.height = desc.Height;
        info.sampleCount = desc.SampleDesc.Count;

        return info.width != 0 && info.height != 0;
    }

    // The backbuffer of the game's swapchain, that is the surface the frame is
    // presented from. The view is rebuilt whenever the backbuffer changes (a
    // resize, a mode change). Both pointers are borrowed, do not release them.
    inline bool GetBackBuffer(IUnknown* pObject, ID3D11Texture2D** ppTexture, ID3D11RenderTargetView** ppView, TargetInfo& info)
    {
        IDXGISwapChain* pSwapChain = nullptr;
        if (FAILED(pObject->QueryInterface(__uuidof(IDXGISwapChain), (void**)&pSwapChain)) || !pSwapChain)
            return false;

        ID3D11Texture2D* pBackBuffer = nullptr;
        const HRESULT hResult = pSwapChain->GetBuffer(0, __uuidof(ID3D11Texture2D), (void**)&pBackBuffer);
        pSwapChain->Release();

        if (FAILED(hResult) || !pBackBuffer)
        {
            ReportPostFXFailure(POSTFX_FAILURE_BACKBUFFER, "swapchain buffer 0", (int)hResult);
            return false;
        }

        if (pBackBuffer == pCachedBackBuffer)
        {
            pBackBuffer->Release();
        }
        else
        {
            SafeRelease(pBackBufferView);
            if (FAILED(pDevice->CreateRenderTargetView(pBackBuffer, nullptr, &pBackBufferView)))
            {
                ReportPostFXFailure(POSTFX_FAILURE_BACKBUFFER, "backbuffer render target view");
                pBackBuffer->Release();
                return false;
            }

            SafeRelease(pCachedBackBuffer);
            pCachedBackBuffer = pBackBuffer; // keeps the reference GetBuffer handed out
        }

        if (!GetTextureInfo(pCachedBackBuffer, info))
            return false;

        *ppTexture = pCachedBackBuffer;
        *ppView = pBackBufferView;
        return true;
    }

    // Runs the requested passes on the backbuffer of the swapchain that is about
    // to be presented, in the order SMAA, blur, gamma. Called before the UI is
    // drawn for the scene effects, at the end of the frame for the gamma.
    inline void Render(IUnknown* pObject, const PostFXOptions& options, unsigned int uStages)
    {
        if (!pObject || !options.AnyEnabled())
            return;

        if (!EnsureInitialized(pObject))
            return;

        ID3D11Texture2D* pBackBuffer = nullptr;
        ID3D11RenderTargetView* pBackBufferView = nullptr;
        TargetInfo info{};

        if (!GetBackBuffer(pObject, &pBackBuffer, &pBackBufferView, info) || !EnsureResources(info, options))
            return;

        SavedState state{};
        SaveState(state);

        RenderEffects(pBackBuffer, pBackBufferView, info.sampleCount, options, uStages);

        ID3D11ShaderResourceView* pNullViews[3] = {};
        pContext->PSSetShaderResources(0, 3, pNullViews);

        RestoreState(state);
    }
}
