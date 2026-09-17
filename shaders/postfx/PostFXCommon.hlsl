// Shared declarations for every PostFX pass.
//
// The very same sources are compiled for each DirectX version the game supports:
//   win32_30 -> vs_3_0 / ps_3_0   (POSTFX_DX9 defined)
//   win32_40 -> vs_4_0 / ps_4_0
//   win32_41 -> vs_4_1 / ps_4_1
//   win32_50 -> vs_5_0 / ps_5_0
//
// Constants:
//   vec4SMAARTMetrics  xy = 1 / target size, zw = target size in pixels
//   vec4PostFXParams   xy = 1 / target size, z  = blur strength
//
// They are set as shader constants in c0/c1 on Direct3D 9 (no constant buffers
// there) and as a single constant buffer in b0 on Direct3D 10 and above. Keep
// the layout in sync with PostFXConstants in postfx.ixx.

#if defined(POSTFX_DX9)

struct PostFXVSInput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct PostFXVSOutput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct PostFXPSInput
{
    float2 TexCoord : TEXCOORD0;
};

float4 vec4SMAARTMetrics : register(c0);
float4 vec4PostFXParams  : register(c1);

#define POSTFX_PS_OUTPUT_SEMANTIC COLOR0
#define POSTFX_SAMPLE(tex, uv) tex2D(tex, uv)

#else

struct PostFXVSInput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct PostFXVSOutput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

// The position has to be part of the input signature even though no pass uses
// it. Direct3D 10 and above match the stages by register, the vertex shader
// writes SV_POSITION to o0 and the texcoord to o1, a pixel shader that declares
// the texcoord alone would read v0 and the draw would be dropped with a stage
// linkage error.
struct PostFXPSInput
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
};

cbuffer PostFXConstants : register(b0)
{
    float4 vec4SMAARTMetrics;
    float4 vec4PostFXParams;
};

SamplerState postFXLinearSampler : register(s0);
SamplerState postFXPointSampler  : register(s1);

#define POSTFX_PS_OUTPUT_SEMANTIC SV_TARGET
#define POSTFX_SAMPLE(tex, uv) tex.Sample(postFXLinearSampler, uv)

#endif

// -------------------------------------------------------------
// SMAA configuration
//
// Identical for all three SMAA passes, the blend weight pass expects the same
// values the edge detection pass was compiled with.
// Enhanced Subpixel Morphological Antialiasing, by iryoku:
// https://github.com/iryoku/smaa

#define SMAA_RT_METRICS vec4SMAARTMetrics
#define SMAA_THRESHOLD 0.05
#define SMAA_MAX_SEARCH_STEPS 16
#define SMAA_MAX_SEARCH_STEPS_DIAG 8
#define SMAA_CORNER_ROUNDING 25

#if defined(POSTFX_DX9)
// Direct3D 9 has no separate texture/sampler objects, every texture is a
// sampler2D bound to a sampler stage by the runtime.
#define SMAA_HLSL_3
#else
// SMAA.hlsl ships sampler declarations in effect syntax for SM4/5, so hand the
// porting over to us (SMAA_CUSTOM_SL) and use plain textures plus samplers that
// the device binds. Sampler0 = linear/clamp, sampler1 = point/clamp.
#define SMAA_CUSTOM_SL
#define SMAATexture2D(tex) Texture2D tex
#define SMAATexturePass2D(tex) tex
#define SMAASampleLevelZero(tex, coord) tex.SampleLevel(postFXLinearSampler, coord, 0)
#define SMAASampleLevelZeroPoint(tex, coord) tex.SampleLevel(postFXPointSampler, coord, 0)
#define SMAASampleLevelZeroOffset(tex, coord, offset) tex.SampleLevel(postFXLinearSampler, coord, 0, offset)
#define SMAASample(tex, coord) tex.Sample(postFXLinearSampler, coord)
#define SMAASamplePoint(tex, coord) tex.Sample(postFXPointSampler, coord)
#define SMAASampleOffset(tex, coord, offset) tex.Sample(postFXLinearSampler, coord, offset)
#define SMAA_FLATTEN [flatten]
#define SMAA_BRANCH [branch]
#endif
