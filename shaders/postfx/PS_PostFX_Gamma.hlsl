// The console gamma curves, one file for every preset.
//
// The curve is picked with POSTFX_GAMMA_PRESET, which the build passes per
// compilation (see the shader table in premake5.lua), so one more console is a
// branch below plus one row in that table. Sampling, the output semantic and
// the difference between Direct3D 9 and the later versions all come from
// PostFXCommon.hlsl, and the fullscreen vertex shader is shared with the other
// post processing passes.
//
// A new preset touches:
//   - a branch below, with the next POSTFX_GAMMA_ number
//   - the shader table in premake5.lua, one row with that number
//   - source/resources/Shaders.rc, one id per profile
//   - the shader profile tables and the shader defines in postfx.dx11.ixx and
//     postfx.dx9.ixx, where the presets are also created one by one
//   - POSTFX_GAMMA_PRESETS in postfx.common.ixx

#include "PostFXCommon.hlsl"

#define POSTFX_GAMMA_XENON 1 // Xbox 360
#define POSTFX_GAMMA_CELL  2 // PlayStation 3
//                         3 // free

#ifndef POSTFX_GAMMA_PRESET
#error POSTFX_GAMMA_PRESET is missing, see the shader table in premake5.lua
#endif

#if defined(POSTFX_DX9)
sampler2D frameBufferTex : register(s0);
#else
Texture2D frameBufferTex : register(t0);
#endif

// Everything below only describes the curve itself, it never touches how the
// frame is sampled, so a new preset does not have to care about the renderer.

float3 GammaSRGBDecode(float3 color)
{
    float3 linearSection = color / 12.92f;
    float3 clampedColor = max(color, 0.0f);
    float3 powerSection = pow((clampedColor + 0.055f) / 1.055f, 2.4f);

    return (color >= 0.04045f) ? powerSection : linearSection;
}

float3 GammaRec709Encode(float3 color)
{
    float3 linearSection = color * 4.5f;
    float3 powerSection = 1.099f * pow(max(color, 0.0f), 0.45f) - 0.099f;

    return (color >= 0.018f) ? powerSection : linearSection;
}

float4 PSMain(PostFXPSInput In) : POSTFX_PS_OUTPUT_SEMANTIC
{
    float4 color = POSTFX_SAMPLE(frameBufferTex, In.TexCoord);

#if POSTFX_GAMMA_PRESET == POSTFX_GAMMA_XENON
    color.rgb = GammaRec709Encode(GammaSRGBDecode(color.rgb));
#elif POSTFX_GAMMA_PRESET == POSTFX_GAMMA_CELL
    color.rgb = pow(max(color.rgb, 0.0f), 1.2f);
#endif

    return color;
}
