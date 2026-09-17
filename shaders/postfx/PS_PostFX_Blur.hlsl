// Separable 9 tap Gaussian blur, one entry point per direction.
//
// Textures:
//   blurTex (s0/t0) - input color
//
// Constants:
//   vec4PostFXParams.xy - 1 / target size
//   vec4PostFXParams.z  - blur strength (0 disables the blur, 1 is the base look)

#include "PostFXCommon.hlsl"

#if defined(POSTFX_DX9)
sampler2D blurTex : register(s0);
#else
Texture2D blurTex : register(t0);
#endif

static const float POSTFX_BLUR_OFFSETS[9] = { -4, -3, -2, -1, 0, 1, 2, 3, 4 };
static const float POSTFX_BLUR_WEIGHTS[9] =
{
    0.016216, 0.054054, 0.121621, 0.194594, 0.227027,
    0.194594, 0.121621, 0.054054, 0.016216
};

float3 BlurSample(float2 texcoord, float2 direction)
{
    float3 sum = 0.0.xxx;

    for (int i = 0; i < 9; i++)
    {
        float2 uv = texcoord + vec4PostFXParams.xy * (POSTFX_BLUR_OFFSETS[i] * vec4PostFXParams.z) * direction;
        sum += POSTFX_SAMPLE(blurTex, uv).rgb * POSTFX_BLUR_WEIGHTS[i];
    }

    return sum;
}

float4 PSBlurHorizontal(PostFXPSInput In) : POSTFX_PS_OUTPUT_SEMANTIC
{
    return float4(BlurSample(In.TexCoord, float2(1.0, 0.0)), 1.0);
}

float4 PSBlurVertical(PostFXPSInput In) : POSTFX_PS_OUTPUT_SEMANTIC
{
    return float4(BlurSample(In.TexCoord, float2(0.0, 1.0)), 1.0);
}
