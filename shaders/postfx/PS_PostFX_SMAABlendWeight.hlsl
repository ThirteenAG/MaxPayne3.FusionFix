// SMAA pass 2 of 3: blending weight calculation.
//
// Textures:
//   edgesTex  (s0/t0) - result of the edge detection pass
//   areaTex   (s1/t1) - precomputed area texture
//   searchTex (s2/t2) - precomputed search texture (point sampled)

#include "PostFXCommon.hlsl"

#if defined(POSTFX_DX9)
sampler2D edgesTex  : register(s0);
sampler2D areaTex   : register(s1);
sampler2D searchTex : register(s2);
#else
Texture2D edgesTex  : register(t0);
Texture2D areaTex   : register(t1);
Texture2D searchTex : register(t2);
#endif

#include "SMAA.hlsl"

float4 PSMain(PostFXPSInput In) : POSTFX_PS_OUTPUT_SEMANTIC
{
    float2 pixcoord;
    float4 offset[3];
    SMAABlendingWeightCalculationVS(In.TexCoord, pixcoord, offset);

    return SMAABlendingWeightCalculationPS(In.TexCoord, pixcoord, offset, edgesTex, areaTex, searchTex, float4(0.0, 0.0, 0.0, 0.0));
}
