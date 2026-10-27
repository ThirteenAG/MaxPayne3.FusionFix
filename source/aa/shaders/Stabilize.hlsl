// FSR's native output is already reconstructed at pixel centers: this only stabilizes its residual temporal variation
// (a small periodic variation on subpixel geometry), with the center sample as it is, so wires and other fine detail
// don't soften. History alpha: 1 where the pixel was still.

sampler2D CurrentTex : register(s0);                // FSR's output
sampler2D HistoryTex : register(s1);
sampler2D MotionTex  : register(s2);
sampler2D DepthTex   : register(s3);                // standard [0, 1] depth, 0 near
sampler2D ReactiveTex : register(s4);               // FSR's reactive mask, only read when gReactive.z > 0

float4 gTexel : register(c0);                       // 1 / width, 1 / height, width, height
float4 gTaa   : register(c1);                       // xy: jitter in pixels, z: history valid, w: current weight
float4 gBlend : register(c2);                       // w: luma weight
float4 gStatic : register(c3);                      // y: motion in pixels from which the history is bypassed
float4 gReactive : register(c4);                    // z: enabled

#include "Temporal.hlsli"

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    float3 current = FetchCurrent(uv);
    float3 boxMin = current;
    float3 boxMax = current;
    float speed = 0.0;
    float closestDepth = 1.0;
    float2 motion = 0.0;
    float reactive = 0.0;
    // Motion, depth and the mask are still on the jittered input grid, unlike FSR's output
    float2 inputUV = uv + gTaa.xy * gTexel.xy;
    [unroll]
    for (int y = -1; y <= 1; ++y)
    {
        [unroll]
        for (int x = -1; x <= 1; ++x)
        {
            float2 offset = float2(x, y) * gTexel.xy;
            float3 color = FetchCurrent(uv + offset);
            boxMin = min(boxMin, color);
            boxMax = max(boxMax, color);
            float2 velocity = tex2Dlod(MotionTex, float4(inputUV + offset, 0.0, 0.0)).xy;
            speed = max(speed, length(velocity * gTexel.zw));
            float depth = tex2Dlod(DepthTex, float4(inputUV + offset, 0.0, 0.0)).r;
            if (depth < closestDepth)
            {
                closestDepth = depth;
                motion = velocity;
            }
            if (gReactive.z > 0.0)
                reactive = max(reactive, tex2Dlod(ReactiveTex, float4(inputUV + offset, 0.0, 0.0)).r);
        }
    }

    float2 historyUV = uv + motion;
    float3 result = current;
    bool onScreen = all(historyUV == saturate(historyUV));
    if (gTaa.z > 0.0 && onScreen)
    {
        // A moving foreground must not leave its color behind on a newly exposed still pixel
        float previousWasStill = tex2Dlod(HistoryTex, float4(historyUV, 0.0, 0.0)).a;
        if (previousWasStill > 0.5)
        {
            // Subpixel fluctuation within a small share of the local contrast is allowed, without pulling a thin line
            // towards its darkest sample; flat newly exposed regions still reject the old color
            float3 margin = (boxMax - boxMin) * 0.1;
            float3 history = ClipTowardsCenter(boxMin - margin, boxMax + margin, FetchHistory(historyUV));
            float weight = max(reactive, lerp(gTaa.w, 1.0, saturate(speed / gStatic.y)));
            result = lerp(history, current, weight);
        }
    }

    return float4(Expand(FromYCoCg(result)), speed < gStatic.y ? 1.0 : 0.0);
}
