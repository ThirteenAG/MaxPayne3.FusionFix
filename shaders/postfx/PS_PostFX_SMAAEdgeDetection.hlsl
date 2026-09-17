// SMAA pass 1 of 3: edge detection.
//
// Textures:
//   colorTex (s0/t0) - scene color, must not be sRGB encoded

#include "PostFXCommon.hlsl"

#if defined(POSTFX_DX9)
sampler2D colorTex : register(s0);
#else
Texture2D colorTex : register(t0);
#endif

#include "SMAA.hlsl"

float4 PSMain(PostFXPSInput In) : POSTFX_PS_OUTPUT_SEMANTIC
{
    float4 offset[3];
    SMAAEdgeDetectionVS(In.TexCoord, offset);

    return float4(SMAALumaEdgeDetectionPS(In.TexCoord, offset, colorTex), 0.0, 0.0);
}
