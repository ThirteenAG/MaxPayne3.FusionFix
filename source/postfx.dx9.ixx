module;

#include <common.hxx>
#include <d3d9.h>
#include <vector>

export module postfxdx9;

import postfxcommon;

// ---------------------------------------------------------------------------
// PostFX backend for the Direct3D 9 renderer (shader model 3.0).
//
// Every pass is a fullscreen quad drawn with fxc precompiled shaders that are
// embedded as RCDATA, no D3DX9 effect or runtime compilation is involved:
//   pass 1 (SMAA)  edge detection -> blending weights -> neighborhood blending
//   pass 2 (blur)  horizontal -> vertical
//   pass 3 (gamma) one of the console presets
// Each effect copies the current render target into an offscreen texture first
// and writes its result back into the very same render target, so the backend
// works both at the end of the frame (backbuffer) and in the middle of it
// (the scene render target, before the UI is drawn).
// ---------------------------------------------------------------------------

// shader resources, see source/resources/Shaders.rc
#define IDR_POSTFX_VS_DX9             151
#define IDR_POSTFX_PS_SMAA_EDGE_DX9   152
#define IDR_POSTFX_PS_SMAA_BLEND_DX9  153
#define IDR_POSTFX_PS_SMAA_OUTPUT_DX9 154
#define IDR_POSTFX_PS_BLUR_H_DX9      155
#define IDR_POSTFX_PS_BLUR_V_DX9      156
#define IDR_POSTFX_PS_GAMMA_XENON_DX9 157
#define IDR_POSTFX_PS_GAMMA_CELL_DX9  158

// precomputed SMAA textures
#define IDR_POSTFX_AREATEX   201
#define IDR_POSTFX_SEARCHTEX 202

export namespace PostFX9
{
    enum PostFXTargets
    {
        TARGET_SCENE = 1 << 0,
        TARGET_RESOLVE = 1 << 1,
        TARGET_SMAA = 1 << 2,
        TARGET_BLUR = 1 << 3,
    };

    struct RenderTargetInfo
    {
        D3DFORMAT format = D3DFMT_UNKNOWN;
        D3DMULTISAMPLE_TYPE multiSampleType = D3DMULTISAMPLE_NONE;
        DWORD multiSampleQuality = 0;
        UINT width = 0;
        UINT height = 0;
    };

    struct QuadVertex
    {
        float fX, fY, fZ;
        float fU, fV;
    };

    inline IDirect3DDevice9* pDevice = nullptr;
    inline bool bShadersLoaded = false;
    inline DWORD uCreatedTargets = 0;
    inline RenderTargetInfo targetInfo{};

    inline IDirect3DVertexShader9* pVS = nullptr;
    inline IDirect3DPixelShader9* pPSSmaa[3] = {};   // edge detection, blending weights, neighborhood blending
    inline IDirect3DPixelShader9* pPSBlur[2] = {};   // horizontal, vertical
    inline IDirect3DPixelShader9* pPSGamma[POSTFX_GAMMA_PRESETS] = {}; // Xenon, Cell

    inline IDirect3DTexture9* pSceneTexture = nullptr;
    inline IDirect3DSurface9* pSceneSurface = nullptr;
    inline IDirect3DSurface9* pResolveSurface = nullptr;
    inline IDirect3DTexture9* pEdgeTexture = nullptr;
    inline IDirect3DSurface9* pEdgeSurface = nullptr;
    inline IDirect3DTexture9* pBlendTexture = nullptr;
    inline IDirect3DSurface9* pBlendSurface = nullptr;
    inline IDirect3DTexture9* pBlurTexture = nullptr;
    inline IDirect3DSurface9* pBlurSurface = nullptr;
    inline IDirect3DTexture9* pAreaTexture = nullptr;
    inline IDirect3DTexture9* pSearchTexture = nullptr;

    template <typename T>
    inline void SafeRelease(T*& pResource)
    {
        if (pResource)
        {
            pResource->Release();
            pResource = nullptr;
        }
    }

    // -----------------------------------------------------------------------
    // State. The passes change a lot of the device, so everything they touch is
    // saved and put back by hand. A Direct3D 9 state block cannot be relied on
    // for this: one that fails to be created restores nothing at all, and then
    // the vertex and pixel shader of the last pass stay behind. Whatever the
    // game draws next, like the UI, is then drawn with them, which is what made
    // the HUD disappear on this renderer.
    // -----------------------------------------------------------------------
    inline constexpr D3DRENDERSTATETYPE postFXSavedRenderStates[] =
    {
        D3DRS_ZENABLE, D3DRS_ZWRITEENABLE, D3DRS_ALPHABLENDENABLE, D3DRS_ALPHATESTENABLE,
        D3DRS_SEPARATEALPHABLENDENABLE, D3DRS_STENCILENABLE, D3DRS_CULLMODE,
        D3DRS_SCISSORTESTENABLE, D3DRS_SRGBWRITEENABLE, D3DRS_COLORWRITEENABLE,
        D3DRS_FOGENABLE, D3DRS_VERTEXBLEND,
    };

    inline constexpr D3DSAMPLERSTATETYPE postFXSavedSamplerStates[] =
    {
        D3DSAMP_ADDRESSU, D3DSAMP_ADDRESSV, D3DSAMP_ADDRESSW,
        D3DSAMP_MINFILTER, D3DSAMP_MAGFILTER, D3DSAMP_MIPFILTER,
        D3DSAMP_SRGBTEXTURE, D3DSAMP_MAXANISOTROPY,
    };

    struct SavedState
    {
        IDirect3DSurface9* pRenderTarget = nullptr;
        D3DVIEWPORT9 viewport{};

        IDirect3DVertexShader9* pVertexShader = nullptr;
        IDirect3DPixelShader9* pPixelShader = nullptr;

        IDirect3DVertexBuffer9* pVertexBuffer = nullptr;
        UINT uVertexOffset = 0;
        UINT uVertexStride = 0;
        IDirect3DVertexDeclaration9* pVertexDeclaration = nullptr;
        DWORD dwFVF = 0;
        IDirect3DIndexBuffer9* pIndexBuffer = nullptr;

        PostFXConstants constants{};

        DWORD dwRenderStates[ARRAYSIZE(postFXSavedRenderStates)]{};
        DWORD dwTextureStageStates[3][4]{}; // colorop, colorarg1, alphaop, alphaarg1
        DWORD dwSamplerStates[3][ARRAYSIZE(postFXSavedSamplerStates)]{};
        IDirect3DBaseTexture9* pTextures[3]{};
    };

    inline void ReleaseShaders();
    inline void OnLostDevice();

    // -----------------------------------------------------------------------
    // shader loading
    // -----------------------------------------------------------------------
    inline bool CreateVertexShaderFromResource(IDirect3DDevice9* dev, int iResourceId, IDirect3DVertexShader9** ppShader)
    {
        HMODULE hModule = GetPostFXModuleHandle((const void*)&CreateVertexShaderFromResource);
        const void* pData = nullptr;
        UINT uSize = 0;

        if (!LoadPostFXResource(hModule, iResourceId, &pData, &uSize))
            return false;

        // Direct3D 9 wants DWORD aligned shader bytecode, resource data is not
        // guaranteed to be aligned, so hand it a copy.
        std::vector<DWORD> bytecode((uSize + sizeof(DWORD) - 1) / sizeof(DWORD));
        memcpy(bytecode.data(), pData, uSize);

        return SUCCEEDED(dev->CreateVertexShader(bytecode.data(), ppShader));
    }

    inline bool CreatePixelShaderFromResource(IDirect3DDevice9* dev, int iResourceId, IDirect3DPixelShader9** ppShader)
    {
        HMODULE hModule = GetPostFXModuleHandle((const void*)&CreatePixelShaderFromResource);
        const void* pData = nullptr;
        UINT uSize = 0;

        if (!LoadPostFXResource(hModule, iResourceId, &pData, &uSize))
            return false;

        std::vector<DWORD> bytecode((uSize + sizeof(DWORD) - 1) / sizeof(DWORD));
        memcpy(bytecode.data(), pData, uSize);

        return SUCCEEDED(dev->CreatePixelShader(bytecode.data(), ppShader));
    }

    inline bool LoadManagedTexture(IDirect3DDevice9* dev, int iResourceId, D3DFORMAT format, IDirect3DTexture9** ppTexture)
    {
        if (*ppTexture)
            return true;

        HMODULE hModule = GetPostFXModuleHandle((const void*)&LoadManagedTexture);
        const void* pData = nullptr;
        UINT uSize = 0;
        PostFXTextureData textureData{};

        if (!LoadPostFXResource(hModule, iResourceId, &pData, &uSize) ||
            !ParsePostFXTexture(pData, uSize, textureData))
        {
            ReportPostFXFailure(POSTFX_FAILURE_SMAA_TEXTURES, "smaa texture resource (d3d9)", iResourceId);
            return false;
        }

        if (FAILED(dev->CreateTexture(textureData.uWidth, textureData.uHeight, 1, 0, format, D3DPOOL_MANAGED, ppTexture, nullptr)))
            return false;

        D3DLOCKED_RECT locked{};
        if (FAILED((*ppTexture)->LockRect(0, &locked, nullptr, 0)))
        {
            SafeRelease(*ppTexture);
            return false;
        }

        const UINT uRowSize = textureData.uWidth * textureData.uBytesPerPixel;
        for (UINT y = 0; y < textureData.uHeight; y++)
        {
            memcpy((BYTE*)locked.pBits + (SIZE_T)y * locked.Pitch, textureData.pPixels + (SIZE_T)y * uRowSize, uRowSize);
        }

        (*ppTexture)->UnlockRect(0);
        return true;
    }

    inline bool LoadShaders(IDirect3DDevice9* dev)
    {
        if (bShadersLoaded)
            return true;

        if (!CreateVertexShaderFromResource(dev, IDR_POSTFX_VS_DX9, &pVS) ||
            !CreatePixelShaderFromResource(dev, IDR_POSTFX_PS_SMAA_EDGE_DX9, &pPSSmaa[0]) ||
            !CreatePixelShaderFromResource(dev, IDR_POSTFX_PS_SMAA_BLEND_DX9, &pPSSmaa[1]) ||
            !CreatePixelShaderFromResource(dev, IDR_POSTFX_PS_SMAA_OUTPUT_DX9, &pPSSmaa[2]) ||
            !CreatePixelShaderFromResource(dev, IDR_POSTFX_PS_BLUR_H_DX9, &pPSBlur[0]) ||
            !CreatePixelShaderFromResource(dev, IDR_POSTFX_PS_BLUR_V_DX9, &pPSBlur[1]) ||
            !CreatePixelShaderFromResource(dev, IDR_POSTFX_PS_GAMMA_XENON_DX9, &pPSGamma[0]) ||
            !CreatePixelShaderFromResource(dev, IDR_POSTFX_PS_GAMMA_CELL_DX9, &pPSGamma[1]))
        {
            ReportPostFXFailure(POSTFX_FAILURE_COMMON_SHADERS, "shader (d3d9)");
            ReleaseShaders();
            return false;
        }

        if (!LoadManagedTexture(dev, IDR_POSTFX_AREATEX, D3DFMT_A8L8, &pAreaTexture) ||
            !LoadManagedTexture(dev, IDR_POSTFX_SEARCHTEX, D3DFMT_L8, &pSearchTexture))
        {
            ReleaseShaders();
            return false;
        }

        bShadersLoaded = true;
        return true;
    }

    inline void ReleaseShaders()
    {
        bShadersLoaded = false;
        SafeRelease(pVS);
        SafeRelease(pPSSmaa[0]);
        SafeRelease(pPSSmaa[1]);
        SafeRelease(pPSSmaa[2]);
        SafeRelease(pPSBlur[0]);
        SafeRelease(pPSBlur[1]);
        for (int i = 0; i < POSTFX_GAMMA_PRESETS; i++)
            SafeRelease(pPSGamma[i]);
        SafeRelease(pAreaTexture);
        SafeRelease(pSearchTexture);
    }

    // -----------------------------------------------------------------------
    // render target sized resources
    // -----------------------------------------------------------------------
    inline void ReleaseTargets()
    {
        SafeRelease(pBlurSurface);
        SafeRelease(pBlurTexture);
        SafeRelease(pBlendSurface);
        SafeRelease(pBlendTexture);
        SafeRelease(pEdgeSurface);
        SafeRelease(pEdgeTexture);
        SafeRelease(pSceneSurface);
        SafeRelease(pSceneTexture);
        SafeRelease(pResolveSurface);
        uCreatedTargets = 0;
    }

    inline bool CreateRenderTargetTexture(IDirect3DDevice9* dev, const RenderTargetInfo& info, D3DFORMAT format,
        IDirect3DTexture9** ppTexture, IDirect3DSurface9** ppSurface)
    {
        if (FAILED(dev->CreateTexture(info.width, info.height, 1, D3DUSAGE_RENDERTARGET, format, D3DPOOL_DEFAULT, ppTexture, nullptr)))
            return false;

        if (FAILED((*ppTexture)->GetSurfaceLevel(0, ppSurface)))
        {
            SafeRelease(*ppTexture);
            return false;
        }

        return true;
    }

    inline bool EnsureTargets(IDirect3DDevice9* dev, const RenderTargetInfo& info, const PostFXOptions& options, unsigned int uStages)
    {
        DWORD uRequired = TARGET_SCENE;
        if (options.bSmaa && (uStages & POSTFX_STAGE_SMAA))
            uRequired |= TARGET_SMAA;
        if (options.bBlur && (uStages & POSTFX_STAGE_BLUR))
            uRequired |= TARGET_BLUR;
        if (info.multiSampleType != D3DMULTISAMPLE_NONE)
            uRequired |= TARGET_RESOLVE;

        const bool bMatchesCurrent = (uCreatedTargets == uRequired) &&
            targetInfo.format == info.format &&
            targetInfo.multiSampleType == info.multiSampleType &&
            targetInfo.width == info.width &&
            targetInfo.height == info.height;

        if (bMatchesCurrent)
            return true;

        ReleaseTargets();

        if (!CreateRenderTargetTexture(dev, info, info.format, &pSceneTexture, &pSceneSurface))
        {
            ReportPostFXFailure(POSTFX_FAILURE_TARGETS, "scene texture (d3d9)", (int)info.width);
            ReleaseTargets();
            return false;
        }

        if ((uRequired & TARGET_RESOLVE) &&
            FAILED(dev->CreateRenderTarget(info.width, info.height, info.format, D3DMULTISAMPLE_NONE, 0, FALSE, &pResolveSurface, nullptr)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_TARGETS, "resolve surface (d3d9)", (int)info.width);
            ReleaseTargets();
            return false;
        }

        // SMAA needs both of its intermediate buffers in a plain 32 bit format
        if ((uRequired & TARGET_SMAA) &&
            (!CreateRenderTargetTexture(dev, info, D3DFMT_A8R8G8B8, &pEdgeTexture, &pEdgeSurface) ||
             !CreateRenderTargetTexture(dev, info, D3DFMT_A8R8G8B8, &pBlendTexture, &pBlendSurface)))
        {
            ReportPostFXFailure(POSTFX_FAILURE_TARGETS, "smaa targets (d3d9)", (int)info.width);
            ReleaseTargets();
            return false;
        }

        if ((uRequired & TARGET_BLUR) &&
            !CreateRenderTargetTexture(dev, info, info.format, &pBlurTexture, &pBlurSurface))
        {
            ReportPostFXFailure(POSTFX_FAILURE_TARGETS, "blur texture (d3d9)", (int)info.width);
            ReleaseTargets();
            return false;
        }

        targetInfo = info;
        uCreatedTargets = uRequired;
        return true;
    }

    inline RenderTargetInfo GetRenderTargetInfo(IDirect3DSurface9* pRenderTarget)
    {
        RenderTargetInfo info{};

        D3DSURFACE_DESC desc{};
        if (SUCCEEDED(pRenderTarget->GetDesc(&desc)))
        {
            info.format = desc.Format;
            info.multiSampleType = desc.MultiSampleType;
            info.multiSampleQuality = desc.MultiSampleQuality;
            info.width = desc.Width;
            info.height = desc.Height;
        }

        return info;
    }

    // -----------------------------------------------------------------------
    // state capture, everything the passes touch is restored afterwards
    // -----------------------------------------------------------------------
    inline void CaptureState(IDirect3DDevice9* dev, SavedState& state)
    {
        dev->GetRenderTarget(0, &state.pRenderTarget);
        dev->GetViewport(&state.viewport);

        dev->GetVertexShader(&state.pVertexShader);
        dev->GetPixelShader(&state.pPixelShader);

        dev->GetFVF(&state.dwFVF);
        if (!state.dwFVF)
            dev->GetVertexDeclaration(&state.pVertexDeclaration);

        dev->GetStreamSource(0, &state.pVertexBuffer, &state.uVertexOffset, &state.uVertexStride);
        dev->GetIndices(&state.pIndexBuffer);

        dev->GetPixelShaderConstantF(0, state.constants.fMetrics, 1);
        dev->GetPixelShaderConstantF(1, state.constants.fParams, 1);

        for (SIZE_T i = 0; i < ARRAYSIZE(postFXSavedRenderStates); i++)
            dev->GetRenderState(postFXSavedRenderStates[i], &state.dwRenderStates[i]);

        for (DWORD dwStage = 0; dwStage < 3; dwStage++)
        {
            dev->GetTextureStageState(dwStage, D3DTSS_COLOROP, &state.dwTextureStageStates[dwStage][0]);
            dev->GetTextureStageState(dwStage, D3DTSS_COLORARG1, &state.dwTextureStageStates[dwStage][1]);
            dev->GetTextureStageState(dwStage, D3DTSS_ALPHAOP, &state.dwTextureStageStates[dwStage][2]);
            dev->GetTextureStageState(dwStage, D3DTSS_ALPHAARG1, &state.dwTextureStageStates[dwStage][3]);

            for (SIZE_T i = 0; i < ARRAYSIZE(postFXSavedSamplerStates); i++)
                dev->GetSamplerState(dwStage, postFXSavedSamplerStates[i], &state.dwSamplerStates[dwStage][i]);

            dev->GetTexture(dwStage, &state.pTextures[dwStage]);
        }
    }

    inline void RestoreState(IDirect3DDevice9* dev, SavedState& state)
    {
        dev->SetRenderTarget(0, state.pRenderTarget);
        dev->SetViewport(&state.viewport);

        dev->SetVertexShader(state.pVertexShader);
        dev->SetPixelShader(state.pPixelShader);

        // an FVF and a declaration clear each other, so only the one that was
        // in use is put back
        if (state.dwFVF)
            dev->SetFVF(state.dwFVF);
        else
            dev->SetVertexDeclaration(state.pVertexDeclaration);

        dev->SetStreamSource(0, state.pVertexBuffer, state.uVertexOffset, state.uVertexStride);
        dev->SetIndices(state.pIndexBuffer);

        dev->SetPixelShaderConstantF(0, state.constants.fMetrics, 1);
        dev->SetPixelShaderConstantF(1, state.constants.fParams, 1);

        for (SIZE_T i = 0; i < ARRAYSIZE(postFXSavedRenderStates); i++)
            dev->SetRenderState(postFXSavedRenderStates[i], state.dwRenderStates[i]);

        for (DWORD dwStage = 0; dwStage < 3; dwStage++)
        {
            dev->SetTextureStageState(dwStage, D3DTSS_COLOROP, state.dwTextureStageStates[dwStage][0]);
            dev->SetTextureStageState(dwStage, D3DTSS_COLORARG1, state.dwTextureStageStates[dwStage][1]);
            dev->SetTextureStageState(dwStage, D3DTSS_ALPHAOP, state.dwTextureStageStates[dwStage][2]);
            dev->SetTextureStageState(dwStage, D3DTSS_ALPHAARG1, state.dwTextureStageStates[dwStage][3]);

            for (SIZE_T i = 0; i < ARRAYSIZE(postFXSavedSamplerStates); i++)
                dev->SetSamplerState(dwStage, postFXSavedSamplerStates[i], state.dwSamplerStates[dwStage][i]);

            dev->SetTexture(dwStage, state.pTextures[dwStage]);
        }

        SafeRelease(state.pRenderTarget);
        SafeRelease(state.pVertexShader);
        SafeRelease(state.pPixelShader);
        SafeRelease(state.pVertexBuffer);
        SafeRelease(state.pVertexDeclaration);
        SafeRelease(state.pIndexBuffer);
        for (auto& pTexture : state.pTextures)
            SafeRelease(pTexture);
    }

    inline void SetupSampler(IDirect3DDevice9* dev, DWORD dwStage, D3DTEXTUREFILTERTYPE filter)
    {
        dev->SetSamplerState(dwStage, D3DSAMP_ADDRESSU, D3DTADDRESS_CLAMP);
        dev->SetSamplerState(dwStage, D3DSAMP_ADDRESSV, D3DTADDRESS_CLAMP);
        dev->SetSamplerState(dwStage, D3DSAMP_ADDRESSW, D3DTADDRESS_CLAMP);
        dev->SetSamplerState(dwStage, D3DSAMP_MINFILTER, filter);
        dev->SetSamplerState(dwStage, D3DSAMP_MAGFILTER, filter);
        dev->SetSamplerState(dwStage, D3DSAMP_MIPFILTER, D3DTEXF_POINT);
        dev->SetSamplerState(dwStage, D3DSAMP_SRGBTEXTURE, FALSE);
        dev->SetSamplerState(dwStage, D3DSAMP_MAXANISOTROPY, 1);
    }

    inline void BindTexture(IDirect3DDevice9* dev, DWORD dwStage, IDirect3DBaseTexture9* pTexture, D3DTEXTUREFILTERTYPE filter)
    {
        dev->SetTexture(dwStage, pTexture);
        SetupSampler(dev, dwStage, filter);
    }

    inline void SetupPass(IDirect3DDevice9* dev, IDirect3DSurface9* pTarget,
        IDirect3DVertexShader9* pVertexShader, IDirect3DPixelShader9* pPixelShader, const PostFXConstants& constants)
    {
        dev->SetRenderTarget(0, pTarget);

        const D3DVIEWPORT9 viewport = { 0, 0, targetInfo.width, targetInfo.height, 0.0f, 1.0f };
        dev->SetViewport(&viewport);

        dev->SetVertexShader(pVertexShader);
        dev->SetPixelShader(pPixelShader);
        dev->SetStreamSource(0, nullptr, 0, 0);
        dev->SetIndices(nullptr);

        // A vertex shader gets its inputs through the declaration, an FVF is
        // one, so it has to stay set. Calling SetVertexDeclaration(nullptr)
        // after this clears it again and the draw walks a null declaration,
        // which ends in an access violation inside the runtime.
        dev->SetFVF(D3DFVF_XYZ | D3DFVF_TEX1);

        dev->SetPixelShaderConstantF(0, constants.fMetrics, 1);
        dev->SetPixelShaderConstantF(1, constants.fParams, 1);

        dev->SetRenderState(D3DRS_ZENABLE, FALSE);
        dev->SetRenderState(D3DRS_ZWRITEENABLE, FALSE);
        dev->SetRenderState(D3DRS_ALPHABLENDENABLE, FALSE);
        dev->SetRenderState(D3DRS_ALPHATESTENABLE, FALSE);
        dev->SetRenderState(D3DRS_SEPARATEALPHABLENDENABLE, FALSE);
        dev->SetRenderState(D3DRS_STENCILENABLE, FALSE);
        dev->SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
        dev->SetRenderState(D3DRS_SCISSORTESTENABLE, FALSE);
        dev->SetRenderState(D3DRS_SRGBWRITEENABLE, FALSE);
        dev->SetRenderState(D3DRS_COLORWRITEENABLE,
            D3DCOLORWRITEENABLE_RED | D3DCOLORWRITEENABLE_GREEN | D3DCOLORWRITEENABLE_BLUE | D3DCOLORWRITEENABLE_ALPHA);
        dev->SetRenderState(D3DRS_FOGENABLE, FALSE);
        dev->SetRenderState(D3DRS_VERTEXBLEND, D3DVBF_DISABLE);

        // a pixel shader only samples textures that are enabled in the
        // fixed function pipeline, D3DTOP_DISABLE makes a sampled texture
        // return 1.0 instead of the texel value
        for (DWORD dwStage = 0; dwStage < 3; dwStage++)
        {
            dev->SetTextureStageState(dwStage, D3DTSS_COLOROP, D3DTOP_SELECTARG1);
            dev->SetTextureStageState(dwStage, D3DTSS_COLORARG1, D3DTA_TEXTURE);
            dev->SetTextureStageState(dwStage, D3DTSS_ALPHAOP, D3DTOP_SELECTARG1);
            dev->SetTextureStageState(dwStage, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
        }
    }

    // Fullscreen quad in clip space, shifted half a texel to the left and up.
    // Direct3D 9 lands a pixel center half a texel off a clip space -1..1 quad,
    // so the shift is what makes a pass sample exactly the texel of the pixel it
    // covers. Expanding the quad instead would rescale the sampled image, and
    // sampling between two texels is what turns into a visible blur.
    inline void DrawQuad(IDirect3DDevice9* dev, UINT uWidth, UINT uHeight)
    {
        const float fOffsetX = 1.0f / (float)uWidth;
        const float fOffsetY = 1.0f / (float)uHeight;

        const QuadVertex quad[4] =
        {
            { -1.0f - fOffsetX,  1.0f + fOffsetY, 0.5f, 0.0f, 0.0f },
            {  1.0f - fOffsetX,  1.0f + fOffsetY, 0.5f, 1.0f, 0.0f },
            { -1.0f - fOffsetX, -1.0f + fOffsetY, 0.5f, 0.0f, 1.0f },
            {  1.0f - fOffsetX, -1.0f + fOffsetY, 0.5f, 1.0f, 1.0f },
        };

        dev->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, quad, sizeof(QuadVertex));
    }

    // Copies the current render target into the scene texture, resolving
    // multisampling first when needed.
    inline bool UpdateSceneTexture(IDirect3DDevice9* dev, IDirect3DSurface9* pRenderTarget)
    {
        IDirect3DSurface9* pSource = pRenderTarget;

        if (targetInfo.multiSampleType != D3DMULTISAMPLE_NONE)
        {
            if (!pResolveSurface)
                return false;

            if (FAILED(dev->StretchRect(pRenderTarget, nullptr, pResolveSurface, nullptr, D3DTEXF_LINEAR)))
                return false;

            pSource = pResolveSurface;
        }

        return SUCCEEDED(dev->StretchRect(pSource, nullptr, pSceneSurface, nullptr, D3DTEXF_POINT));
    }

    // -----------------------------------------------------------------------
    // passes
    // -----------------------------------------------------------------------
    inline bool RenderSmaa(IDirect3DDevice9* dev, IDirect3DSurface9* pRenderTarget, bool bDebug)
    {
        if (!(uCreatedTargets & TARGET_SMAA) || !pPSSmaa[0] || !pPSSmaa[1] || !pPSSmaa[2])
            return false;

        if (!pAreaTexture || !pSearchTexture)
            return false;

        if (!UpdateSceneTexture(dev, pRenderTarget))
            return false;

        const PostFXConstants constants = MakePostFXConstants(targetInfo.width, targetInfo.height, 1.0f);

        // 1. edge detection
        SetupPass(dev, pEdgeSurface, pVS, pPSSmaa[0], constants);
        dev->Clear(0, nullptr, D3DCLEAR_TARGET, D3DCOLOR_ARGB(0, 0, 0, 0), 1.0f, 0);
        BindTexture(dev, 0, pSceneTexture, D3DTEXF_LINEAR);
        DrawQuad(dev, targetInfo.width, targetInfo.height);

        // Diagnostic view: the detected edges, white on black, through the gamma
        // shader, which passes a 0 and a 1 through unchanged. A frame that stays
        // black means the edge detection found nothing to antialias.
        if (bDebug)
        {
            SetupPass(dev, pRenderTarget, pVS, pPSGamma[0], constants);
            BindTexture(dev, 0, pEdgeTexture, D3DTEXF_POINT);
            DrawQuad(dev, targetInfo.width, targetInfo.height);
            return true;
        }

        // 2. blending weights
        SetupPass(dev, pBlendSurface, pVS, pPSSmaa[1], constants);
        dev->Clear(0, nullptr, D3DCLEAR_TARGET, D3DCOLOR_ARGB(0, 0, 0, 0), 1.0f, 0);
        BindTexture(dev, 0, pEdgeTexture, D3DTEXF_LINEAR);
        BindTexture(dev, 1, pAreaTexture, D3DTEXF_LINEAR);
        BindTexture(dev, 2, pSearchTexture, D3DTEXF_POINT);
        DrawQuad(dev, targetInfo.width, targetInfo.height);

        // 3. neighborhood blending, straight back into the target we read from
        SetupPass(dev, pRenderTarget, pVS, pPSSmaa[2], constants);
        BindTexture(dev, 0, pSceneTexture, D3DTEXF_LINEAR);
        BindTexture(dev, 1, pBlendTexture, D3DTEXF_LINEAR);
        DrawQuad(dev, targetInfo.width, targetInfo.height);

        return true;
    }

    inline bool RenderBlur(IDirect3DDevice9* dev, IDirect3DSurface9* pRenderTarget, float fBlurStrength)
    {
        if (!(uCreatedTargets & TARGET_BLUR) || !pPSBlur[0] || !pPSBlur[1])
            return false;

        if (fBlurStrength <= 0.001f)
            return false;

        if (!UpdateSceneTexture(dev, pRenderTarget))
            return false;

        const PostFXConstants constants = MakePostFXConstants(targetInfo.width, targetInfo.height, fBlurStrength);

        SetupPass(dev, pBlurSurface, pVS, pPSBlur[0], constants);
        BindTexture(dev, 0, pSceneTexture, D3DTEXF_LINEAR);
        DrawQuad(dev, targetInfo.width, targetInfo.height);

        SetupPass(dev, pRenderTarget, pVS, pPSBlur[1], constants);
        BindTexture(dev, 0, pBlurTexture, D3DTEXF_LINEAR);
        DrawQuad(dev, targetInfo.width, targetInfo.height);

        return true;
    }

    inline bool RenderGamma(IDirect3DDevice9* dev, IDirect3DSurface9* pRenderTarget, int nConsoleGamma)
    {
        if (nConsoleGamma < 1 || nConsoleGamma > POSTFX_GAMMA_PRESETS)
            return false;

        // the preset is picked every frame, switching it in the ini does not
        // reload anything
        if (!pPSGamma[nConsoleGamma - 1])
            return false;

        if (!UpdateSceneTexture(dev, pRenderTarget))
            return false;

        const PostFXConstants constants = MakePostFXConstants(targetInfo.width, targetInfo.height, 1.0f);

        SetupPass(dev, pRenderTarget, pVS, pPSGamma[nConsoleGamma - 1], constants);
        BindTexture(dev, 0, pSceneTexture, D3DTEXF_LINEAR);
        DrawQuad(dev, targetInfo.width, targetInfo.height);

        return true;
    }

    inline void Render(IDirect3DDevice9* dev, const PostFXOptions& options, unsigned int uStages)
    {
        if (!dev || !options.AnyEnabled())
            return;

        // the device can be recreated (switching the renderer, a hardware
        // change), everything cached for the old one has to go first
        if (pDevice && pDevice != dev)
            OnLostDevice();

        pDevice = dev;

        // nothing can be done while the device is lost, release everything so
        // that it gets recreated after the game reset the device
        if (FAILED(dev->TestCooperativeLevel()))
        {
            OnLostDevice();
            return;
        }

        IDirect3DSurface9* pRenderTarget = nullptr;
        if (FAILED(dev->GetRenderTarget(0, &pRenderTarget)) || !pRenderTarget)
        {
            ReportPostFXFailure(POSTFX_FAILURE_BACKBUFFER, "render target (d3d9)");
            return;
        }

        const RenderTargetInfo info = GetRenderTargetInfo(pRenderTarget);
        if (info.format == D3DFMT_UNKNOWN || info.width == 0 || info.height == 0)
        {
            pRenderTarget->Release();
            return;
        }

        if (LoadShaders(dev) && EnsureTargets(dev, info, options, uStages))
        {
            SavedState state{};
            CaptureState(dev, state);

            if (options.bSmaa && (uStages & POSTFX_STAGE_SMAA))
                RenderSmaa(dev, pRenderTarget, options.bSmaaDebug);
            if (options.bBlur && (uStages & POSTFX_STAGE_BLUR))
                RenderBlur(dev, pRenderTarget, options.fBlurStrength);
            if (options.nConsoleGamma && (uStages & POSTFX_STAGE_GAMMA))
                RenderGamma(dev, pRenderTarget, options.nConsoleGamma);

            RestoreState(dev, state);
        }

        pRenderTarget->Release();
    }

    inline void OnLostDevice()
    {
        // unbind everything that is about to be released
        if (pDevice)
        {
            for (DWORD dwStage = 0; dwStage < 4; dwStage++)
                pDevice->SetTexture(dwStage, nullptr);
        }

        ReleaseTargets();
        ReleaseShaders();
        pDevice = nullptr;
    }

    inline void Shutdown()
    {
        OnLostDevice();
    }
}
