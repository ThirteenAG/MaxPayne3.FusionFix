module;

#include <common.hxx>
#include <d3d11.h>

export module consolegammadx11;

import common;
import settings;

#ifndef SAFE_RELEASE
#define SAFE_RELEASE(p) { if (p) { (p)->Release(); (p)=NULL; } }
#endif

// DX10 (Shader Model 4.0)
#define IDR_VS_BlitXenonGammaDX10   111
#define IDR_PS_BlitXenonGammaDX10   112

#define IDR_VS_BlitCellGammaDX10    113
#define IDR_PS_BlitCellGammaDX10    114

// DX10.1 (Shader Model 4.1)
#define IDR_VS_BlitXenonGammaDX10_1 121
#define IDR_PS_BlitXenonGammaDX10_1 122

#define IDR_VS_BlitCellGammaDX10_1  123
#define IDR_PS_BlitCellGammaDX10_1  124

// DX11 (Shader Model 5.0)
#define IDR_VS_BlitXenonGammaDX11   131
#define IDR_PS_BlitXenonGammaDX11   132

#define IDR_VS_BlitCellGammaDX11    133
#define IDR_PS_BlitCellGammaDX11    134

class ConsoleGammaDX11
{
private:
    struct VertexFormat
    {
        float Pos[4];
        float TexCoord[2];
    };

    struct ShaderProgram
    {
        int vsResourceId;
        int psResourceId;
        ID3D11VertexShader** vs;
        ID3D11PixelShader** ps;
    };

    struct PipelineState
    {
        ID3D11RenderTargetView* renderTargetView = nullptr;
        ID3D11DepthStencilView* depthStencilView = nullptr;

        ID3D11BlendState* blendState = nullptr;
        FLOAT blendFactor[4] = { 0.0f, 0.0f, 0.0f, 0.0f };
        UINT sampleMask = 0xFFFFFFFF;

        ID3D11DepthStencilState* depthStencilState = nullptr;
        UINT stencilRef = 0;

        ID3D11RasterizerState* rasterizerState = nullptr;

        ID3D11VertexShader* vertexShader = nullptr;
        ID3D11PixelShader* pixelShader = nullptr;

        ID3D11Buffer* vertexBuffer = nullptr;
        UINT vertexStride = 0;
        UINT vertexOffset = 0;

        ID3D11InputLayout* inputLayout = nullptr;
        D3D11_PRIMITIVE_TOPOLOGY topology = D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST;

        ID3D11ShaderResourceView* pixelSRV = nullptr;
        ID3D11SamplerState* pixelSampler = nullptr;

        UINT numViewports = 0;
        D3D11_VIEWPORT viewports[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE] = {};

        UINT numScissors = 0;
        D3D11_RECT scissors[D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE] = {};
    };

    static inline bool g_initialized = false;
    static inline UINT g_width = 0;
    static inline UINT g_height = 0;

    static inline ID3D11Device* g_device = nullptr;
    static inline ID3D11DeviceContext* g_immediateContext = nullptr;

    static inline ID3D11VertexShader* g_vertexShader = nullptr;
    static inline ID3D11PixelShader* g_pixelShader = nullptr;

    static inline ID3D11Buffer* g_vertexBuffer = nullptr;
    static inline ID3D11InputLayout* g_inputLayout = nullptr;
    static inline ID3D11SamplerState* g_samplerState = nullptr;

    static inline ID3D11BlendState* g_blendState = nullptr;
    static inline ID3D11DepthStencilState* g_depthStencilState = nullptr;
    static inline ID3D11RasterizerState* g_rasterizerState = nullptr;

    static inline ID3D11Texture2D* g_copyTexture = nullptr;
    static inline ID3D11ShaderResourceView* g_copySRV = nullptr;
    static inline ID3D11RenderTargetView* g_renderTargetView = nullptr;

    static void SaveState(PipelineState& st)
    {
        g_immediateContext->OMGetRenderTargets(1, &st.renderTargetView, &st.depthStencilView);
        g_immediateContext->OMGetBlendState(&st.blendState, st.blendFactor, &st.sampleMask);
        g_immediateContext->OMGetDepthStencilState(&st.depthStencilState, &st.stencilRef);
        g_immediateContext->RSGetState(&st.rasterizerState);

        g_immediateContext->VSGetShader(&st.vertexShader, nullptr, nullptr);
        g_immediateContext->PSGetShader(&st.pixelShader, nullptr, nullptr);

        g_immediateContext->IAGetVertexBuffers(0, 1, &st.vertexBuffer, &st.vertexStride, &st.vertexOffset);
        g_immediateContext->IAGetInputLayout(&st.inputLayout);
        g_immediateContext->IAGetPrimitiveTopology(&st.topology);

        g_immediateContext->PSGetShaderResources(0, 1, &st.pixelSRV);
        g_immediateContext->PSGetSamplers(0, 1, &st.pixelSampler);

        st.numViewports = D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
        g_immediateContext->RSGetViewports(&st.numViewports, st.viewports);

        st.numScissors = D3D11_VIEWPORT_AND_SCISSORRECT_OBJECT_COUNT_PER_PIPELINE;
        g_immediateContext->RSGetScissorRects(&st.numScissors, st.scissors);
    }

    static void RestoreState(PipelineState& st)
    {
        g_immediateContext->OMSetRenderTargets(1, &st.renderTargetView, st.depthStencilView);
        g_immediateContext->OMSetBlendState(st.blendState, st.blendFactor, st.sampleMask);
        g_immediateContext->OMSetDepthStencilState(st.depthStencilState, st.stencilRef);
        g_immediateContext->RSSetState(st.rasterizerState);

        g_immediateContext->VSSetShader(st.vertexShader, nullptr, 0);
        g_immediateContext->PSSetShader(st.pixelShader, nullptr, 0);

        g_immediateContext->IASetVertexBuffers(0, 1, &st.vertexBuffer, &st.vertexStride, &st.vertexOffset);
        g_immediateContext->IASetInputLayout(st.inputLayout);
        g_immediateContext->IASetPrimitiveTopology(st.topology);

        g_immediateContext->PSSetShaderResources(0, 1, &st.pixelSRV);
        g_immediateContext->PSSetSamplers(0, 1, &st.pixelSampler);

        g_immediateContext->RSSetViewports(st.numViewports, st.viewports);
        g_immediateContext->RSSetScissorRects(st.numScissors, st.scissors);

        // Release the references we got from Get* calls
        SAFE_RELEASE(st.renderTargetView);
        SAFE_RELEASE(st.depthStencilView);
        SAFE_RELEASE(st.blendState);
        SAFE_RELEASE(st.depthStencilState);
        SAFE_RELEASE(st.rasterizerState);
        SAFE_RELEASE(st.vertexShader);
        SAFE_RELEASE(st.pixelShader);
        SAFE_RELEASE(st.vertexBuffer);
        SAFE_RELEASE(st.inputLayout);
        SAFE_RELEASE(st.pixelSRV);
        SAFE_RELEASE(st.pixelSampler);
    }

    // Shader identifiers
    static inline ID3D11VertexShader* VS_BlitXenonGammaDX10 = nullptr;
    static inline ID3D11PixelShader* PS_BlitXenonGammaDX10 = nullptr;

    static inline ID3D11VertexShader* VS_BlitCellGammaDX10 = nullptr;
    static inline ID3D11PixelShader* PS_BlitCellGammaDX10 = nullptr;

    static inline ID3D11VertexShader* VS_BlitXenonGammaDX10_1 = nullptr;
    static inline ID3D11PixelShader* PS_BlitXenonGammaDX10_1 = nullptr;

    static inline ID3D11VertexShader* VS_BlitCellGammaDX10_1 = nullptr;
    static inline ID3D11PixelShader* PS_BlitCellGammaDX10_1 = nullptr;

    static inline ID3D11VertexShader* VS_BlitXenonGammaDX11 = nullptr;
    static inline ID3D11PixelShader* PS_BlitXenonGammaDX11 = nullptr;

    static inline ID3D11VertexShader* VS_BlitCellGammaDX11 = nullptr;
    static inline ID3D11PixelShader* PS_BlitCellGammaDX11 = nullptr;

    static bool LoadCompiledShaderResource(HMODULE hModule, int resourceId, const void** data, UINT* size)
    {
        HRSRC hRes = FindResourceW(hModule, MAKEINTRESOURCEW(resourceId), RT_RCDATA);
        if (!hRes)
            return false;

        HGLOBAL hGlob = LoadResource(hModule, hRes);
        if (!hGlob)
            return false;

        *data = LockResource(hGlob);
        if (!*data)
            return false;

        *size = SizeofResource(hModule, hRes);
        return *size != 0;
    }

    static ShaderProgram GetShaderProgram(D3D_FEATURE_LEVEL featureLevel, int ConsoleGamma)
    {
        if (ConsoleGamma == 1) // Xenon gamma
        {
            if (featureLevel == D3D_FEATURE_LEVEL_10_0) return { IDR_VS_BlitXenonGammaDX10,   IDR_PS_BlitXenonGammaDX10,   &VS_BlitXenonGammaDX10,   &PS_BlitXenonGammaDX10   };
            if (featureLevel == D3D_FEATURE_LEVEL_10_1) return { IDR_VS_BlitXenonGammaDX10_1, IDR_PS_BlitXenonGammaDX10_1, &VS_BlitXenonGammaDX10_1, &PS_BlitXenonGammaDX10_1 };
            if (featureLevel == D3D_FEATURE_LEVEL_11_0) return { IDR_VS_BlitXenonGammaDX11,   IDR_PS_BlitXenonGammaDX11,   &VS_BlitXenonGammaDX11,   &PS_BlitXenonGammaDX11   };
        }
        else if (ConsoleGamma == 2) // Cell gamma
        {
            if (featureLevel == D3D_FEATURE_LEVEL_10_0) return { IDR_VS_BlitCellGammaDX10,   IDR_PS_BlitCellGammaDX10,   &VS_BlitCellGammaDX10,   &PS_BlitCellGammaDX10   };
            if (featureLevel == D3D_FEATURE_LEVEL_10_1) return { IDR_VS_BlitCellGammaDX10_1, IDR_PS_BlitCellGammaDX10_1, &VS_BlitCellGammaDX10_1, &PS_BlitCellGammaDX10_1 };
            if (featureLevel == D3D_FEATURE_LEVEL_11_0) return { IDR_VS_BlitCellGammaDX11,   IDR_PS_BlitCellGammaDX11,   &VS_BlitCellGammaDX11,   &PS_BlitCellGammaDX11   };
        }

        return { 0, 0, nullptr, nullptr };
    };

    static void ReloadShaders()
    {
        // Force reinitialization
        g_initialized = false;

        // Release current shaders and vertex stuff (Is this needed?)
        SAFE_RELEASE(g_vertexShader);
        SAFE_RELEASE(g_pixelShader);
        SAFE_RELEASE(g_inputLayout);
        SAFE_RELEASE(g_vertexBuffer);

        // Release all cached shaders so they get recreated
        SAFE_RELEASE(VS_BlitXenonGammaDX10);
        SAFE_RELEASE(PS_BlitXenonGammaDX10);
        SAFE_RELEASE(VS_BlitCellGammaDX10);
        SAFE_RELEASE(PS_BlitCellGammaDX10);
        SAFE_RELEASE(VS_BlitXenonGammaDX10_1);
        SAFE_RELEASE(PS_BlitXenonGammaDX10_1);
        SAFE_RELEASE(VS_BlitCellGammaDX10_1);
        SAFE_RELEASE(PS_BlitCellGammaDX10_1);
        SAFE_RELEASE(VS_BlitXenonGammaDX11);
        SAFE_RELEASE(PS_BlitXenonGammaDX11);
        SAFE_RELEASE(VS_BlitCellGammaDX11);
        SAFE_RELEASE(PS_BlitCellGammaDX11);
    }

    static void OnResize()
    {
        SAFE_RELEASE(g_renderTargetView);
        SAFE_RELEASE(g_copySRV);
        SAFE_RELEASE(g_copyTexture);
        g_width = 0;
        g_height = 0;
    }

    static bool Initialize(IDXGISwapChain* swapChain)
    {
        if (g_initialized || !swapChain)
            return g_initialized;

        HRESULT hResult = swapChain->GetDevice(__uuidof(ID3D11Device), (void**)&g_device);
        if (FAILED(hResult))
            return false;
        g_device->GetImmediateContext(&g_immediateContext);

        D3D_FEATURE_LEVEL featureLevel = g_device->GetFeatureLevel();
        int ConsoleGamma = FusionFixSettings.GetInt(PREF_CONSOLEGAMMA);

        if (ConsoleGamma != 1 && ConsoleGamma != 2)
            return false;

        HMODULE hModule = NULL;
        GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, (LPCWSTR)&Initialize, &hModule);

        auto shaderProgram = GetShaderProgram(featureLevel, ConsoleGamma);

        if (shaderProgram.vsResourceId == 0)
            return false;

        const void* vsData = nullptr;
        UINT vsSize = 0;
        const void* psData = nullptr;
        UINT psSize = 0;

        // Load compiled vertex shader 
        if (!*shaderProgram.vs)
        {
            if (!LoadCompiledShaderResource(hModule, shaderProgram.vsResourceId, &vsData, &vsSize))
                return false;

            hResult = g_device->CreateVertexShader(vsData, vsSize, nullptr, shaderProgram.vs);
            if (FAILED(hResult))
                return false;
        }

        // Load compiled pixel shader
        if (!*shaderProgram.ps)
        {
            if (!LoadCompiledShaderResource(hModule, shaderProgram.psResourceId, &psData, &psSize))
                return false;

            hResult = g_device->CreatePixelShader(psData, psSize, nullptr, shaderProgram.ps);
            if (FAILED(hResult))
                return false;
        }

        g_vertexShader = *shaderProgram.vs;
        g_pixelShader = *shaderProgram.ps;

        D3D11_INPUT_ELEMENT_DESC layoutDesc[] =
        {
            { "POSITION", 0, DXGI_FORMAT_R32G32B32A32_FLOAT, 0, offsetof(VertexFormat, Pos),      D3D11_INPUT_PER_VERTEX_DATA, 0 },
            { "TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT,       0, offsetof(VertexFormat, TexCoord), D3D11_INPUT_PER_VERTEX_DATA, 0 },
        };

        hResult = g_device->CreateInputLayout(layoutDesc, ARRAYSIZE(layoutDesc), vsData, vsSize, &g_inputLayout);
        if (FAILED(hResult))
            return false;

        VertexFormat vertices[] =
        {
            { {-1, -1, 0, 1}, {0,1} },
            { {-1,  1, 0, 1}, {0,0} },
            { { 1, -1, 0, 1}, {1,1} },

            { { 1, -1, 0, 1}, {1,1} },
            { {-1,  1, 0, 1}, {0,0} },
            { { 1,  1, 0, 1}, {1,0} },
        };

        D3D11_BUFFER_DESC bufferDesc = {};

        bufferDesc.ByteWidth = sizeof(vertices);
        bufferDesc.Usage = D3D11_USAGE_IMMUTABLE;
        bufferDesc.BindFlags = D3D11_BIND_VERTEX_BUFFER;

        D3D11_SUBRESOURCE_DATA initData = {};

        initData.pSysMem = vertices;

        hResult = g_device->CreateBuffer(&bufferDesc, &initData, &g_vertexBuffer);
        if (FAILED(hResult))
            return false;

        // Sampler (Linear, clamp)
        D3D11_SAMPLER_DESC samplerDesc = {};

        samplerDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
        samplerDesc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
        samplerDesc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
        samplerDesc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
        samplerDesc.ComparisonFunc = D3D11_COMPARISON_NEVER;

        hResult = g_device->CreateSamplerState(&samplerDesc, &g_samplerState);
        if (FAILED(hResult))
            return false;

        // Blend state (No blending)
        D3D11_BLEND_DESC blendDesc = {};

        blendDesc.RenderTarget[0].BlendEnable = FALSE;
        blendDesc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;

        hResult = g_device->CreateBlendState(&blendDesc, &g_blendState);
        if (FAILED(hResult))
            return false;

        // Depth-stencil state (Depth disabled)
        D3D11_DEPTH_STENCIL_DESC depthStencilDesc = {};

        depthStencilDesc.DepthEnable = FALSE;
        depthStencilDesc.StencilEnable = FALSE;

        hResult = g_device->CreateDepthStencilState(&depthStencilDesc, &g_depthStencilState);
        if (FAILED(hResult))
            return false;

        // Rasterizer state (No culling, no scissor)
        D3D11_RASTERIZER_DESC rasterizerDesc = {};

        rasterizerDesc.FillMode = D3D11_FILL_SOLID;
        rasterizerDesc.CullMode = D3D11_CULL_NONE;
        rasterizerDesc.ScissorEnable = FALSE;
        rasterizerDesc.DepthClipEnable = TRUE;

        hResult = g_device->CreateRasterizerState(&rasterizerDesc, &g_rasterizerState);
        if (FAILED(hResult))
            return false;

        g_initialized = true;
        return true;
    }

    static void Render(IDXGISwapChain* swapChain)
    {
        if (!FusionFixSettings.GetInt(PREF_CONSOLEGAMMA) || !swapChain)
            return;

        if (!g_initialized && !Initialize(swapChain))
            return;

        ID3D11Texture2D* backBuffer = nullptr;
        HRESULT hResult = swapChain->GetBuffer(0, __uuidof(ID3D11Texture2D), (void**)&backBuffer);
        if (FAILED(hResult))
            return;

        D3D11_TEXTURE2D_DESC backBufferDesc;
        backBuffer->GetDesc(&backBufferDesc);

        // (Re)create copy texture if resolution has changed
        if (!g_copyTexture || backBufferDesc.Width != g_width || backBufferDesc.Height != g_height)
        {
            g_width = backBufferDesc.Width;
            g_height = backBufferDesc.Height;

            SAFE_RELEASE(g_copySRV);
            SAFE_RELEASE(g_copyTexture);
            SAFE_RELEASE(g_renderTargetView);

            D3D11_TEXTURE2D_DESC copyDesc = backBufferDesc;

            copyDesc.BindFlags = D3D11_BIND_SHADER_RESOURCE;
            copyDesc.MiscFlags = 0;

            hResult = g_device->CreateTexture2D(&copyDesc, nullptr, &g_copyTexture);
            if (FAILED(hResult))
            {
                SAFE_RELEASE(backBuffer);

                return;
            }

            D3D11_SHADER_RESOURCE_VIEW_DESC srvDesc = {};

            srvDesc.Format = backBufferDesc.Format;
            srvDesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
            srvDesc.Texture2D.MipLevels = 1;

            hResult = g_device->CreateShaderResourceView(g_copyTexture, &srvDesc, &g_copySRV);
            if (FAILED(hResult))
            {
                SAFE_RELEASE(backBuffer);

                return;
            }

            hResult = g_device->CreateRenderTargetView(backBuffer, nullptr, &g_renderTargetView);
            if (FAILED(hResult))
            {
                SAFE_RELEASE(backBuffer);

                return;
            }
        }

        PipelineState old = {};

        SaveState(old);

        g_immediateContext->CopyResource(g_copyTexture, backBuffer);
        SAFE_RELEASE(backBuffer);

        D3D11_VIEWPORT viewport = { 0.0f, 0.0f, (float)g_width, (float)g_height, 0.0f, 1.0f };
        g_immediateContext->RSSetViewports(1, &viewport);
        g_immediateContext->RSSetState(g_rasterizerState);

        g_immediateContext->OMSetRenderTargets(1, &g_renderTargetView, nullptr);
        g_immediateContext->OMSetBlendState(g_blendState, nullptr, 0xFFFFFFFF);
        g_immediateContext->OMSetDepthStencilState(g_depthStencilState, 0);

        g_immediateContext->IASetInputLayout(g_inputLayout);
        g_immediateContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

        UINT stride = sizeof(VertexFormat);
        UINT offset = 0;
        g_immediateContext->IASetVertexBuffers(0, 1, &g_vertexBuffer, &stride, &offset);

        g_immediateContext->VSSetShader(g_vertexShader, nullptr, 0);
        g_immediateContext->PSSetShader(g_pixelShader, nullptr, 0);
        g_immediateContext->PSSetShaderResources(0, 1, &g_copySRV);
        g_immediateContext->PSSetSamplers(0, 1, &g_samplerState);

        g_immediateContext->Draw(6, 0);

        ID3D11ShaderResourceView* nullSRV = nullptr;
        g_immediateContext->PSSetShaderResources(0, 1, &nullSRV);

        RestoreState(old);
    }
public:
    ConsoleGammaDX11()
    {
        FusionFix::onIniFileChange() += []()
        {
            ReloadShaders();
        };

        FusionFix::onInitEventAsync() += []()
        {
            auto pattern = hook::pattern("0F B6 C8 8B 07 F7 D9 1B C9 F7 D1 23 0D ? ? ? ? 51 52 FF D0 8B F8 81 FF ? ? ? ? 75");
            static auto DX11PresentHook1 = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
            {
                IDXGISwapChain* swapChain = (IDXGISwapChain*)regs.edx;

                ConsoleGammaDX11::Render(swapChain);
            });

            pattern = hook::pattern("8B 07 F7 D9 1B C9 F7 D1 23 0D ? ? ? ? 51 52 FF D0 8B F8 81 FF ? ? ? ? 74");
            static auto DX11PresentHook2 = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
            {
                IDXGISwapChain* swapChain = (IDXGISwapChain*)regs.edx;

                ConsoleGammaDX11::Render(swapChain);
            });

            pattern = hook::pattern("6A ? 51 55 53 52");
            static auto DX11ResizeBuffersHook = safetyhook::create_mid(pattern.get_first(0), [](SafetyHookContext& regs)
            {
                IDXGISwapChain* swapChain = (IDXGISwapChain*)regs.edi;

                ConsoleGammaDX11::OnResize();
            });
        };
    }
} ConsoleGammaDX11;