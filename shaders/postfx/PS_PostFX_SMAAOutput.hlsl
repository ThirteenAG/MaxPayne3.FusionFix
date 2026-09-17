// SMAA pass 3 of 3: neighborhood blending.
//
// Textures:
//   colorTex (s0/t0) - scene color, must not be sRGB encoded
//   blendTex (s1/t1) - result of the blending weight calculation pass
//
// sRGB reads/writes are deliberately not used: the games render target is a
// plain UNORM surface, so SMAA runs in gamma space (SMAA handles that fine).

#include "PostFXCommon.hlsl"

#if defined(POSTFX_DX9)
sampler2D colorTex : register(s0);
sampler2D blendTex : register(s1);
#else
Texture2D colorTex : register(t0);
Texture2D blendTex : register(t1);
#endif

#include "SMAA.hlsl"

float4 PSMain(PostFXPSInput In) : POSTFX_PS_OUTPUT_SEMANTIC
{
    float4 offset;
    SMAANeighborhoodBlendingVS(In.TexCoord, offset);

    return SMAANeighborhoodBlendingPS(In.TexCoord, offset, colorTex, blendTex);
}
