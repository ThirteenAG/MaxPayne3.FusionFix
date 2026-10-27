// Temporal resolve: a 3x3 Gaussian reconstruction around the jittered sample, the motion of the closest depth in the 3x3, Catmull-Rom history and a YCoCg variance
// clip. For LDR and HDR scenes alike (the luma weighted tonemap is reversible). Optionally, where the motion at the
// history's position last frame differs from this pixel's motion, the history belongs to something else (it was
// uncovered): the pixel follows the current frame there. And where the scene differs from its luma before transparent
// geometry (particles, glass: no motion vectors of their own), the current frame weighs more (reactive). Where the
// history's position was covered by something nearer last frame (a character that walked past), the history shows that
// and is rejected (disocclusion).

sampler2D CurrentTex : register(s0);
sampler2D HistoryTex : register(s1);
sampler2D MotionTex  : register(s2);
sampler2D DepthTex   : register(s3);                // standard [0, 1] depth, 0 near
sampler2D PreviousMotionTex : register(s4);         // last frame's motion, only read when gStatic.z > 0
sampler2D OpaqueLumaTex : register(s5);             // the scene's luma before transparent geometry, only read when gReactive.z > 0
sampler2D PreviousDepthTex : register(s6);          // last frame's standard depth, only read when gPrevious.z > 0

float4 gTexel : register(c0);                       // 1 / width, 1 / height, width, height
float4 gTaa   : register(c1);                       // xy: jitter in pixels (how far the content moved), z: history valid, w: variance clip gamma
float4 gBlend : register(c2);                       // x: minimum current weight, y: maximum current weight, z: weight per pixel of motion, w: luma weight
float4 gStatic : register(c3);                      // x: share of the unclipped history kept where nothing moves, y: motion in pixels below which a pixel is still,
                                                    // z: motion change in pixels from which the history is rejected (0: off), w: the change over which it is rejected fully
float4 gReactive : register(c4);                    // x: scale, y: maximum current weight, z: enabled
row_major float4x4 gReproject : register(c5);       // current clip space -> previous clip space, both without jitter
float4 gPrevious : register(c9);                    // x: near, y: far, z: relative depth difference from which the history counts as covered (0: off),
                                                    // w: the history's alpha holds how long it has been still (0: taken as always still)

#include "Temporal.hlsli"

static const float StillStep = 0.125;              // the history is kept as is fully after 8 still frames

// How much a pixel should follow the current frame: its difference from the luma before transparent geometry, compared
// after a tonemap so a bright particle on a dark background counts as much as a dark one on a bright background
float ReactiveValue(float scene, float opaque)
{
    scene = max(scene, 0.0);
    opaque = max(opaque, 0.0);
    float difference = abs(scene / (1.0 + scene) - opaque / (1.0 + opaque));
    return saturate(difference * gReactive.x) * gReactive.y;
}

float Distance(float depth)
{
    // Standard depth (0 near) back to the distance along the view direction
    return gPrevious.x * gPrevious.y / (gPrevious.y - depth * (gPrevious.y - gPrevious.x));
}

// 1 where the surface at the history's position last frame was nearer than what this pixel shows: it covered this
// pixel's surface then, and the history holds it. tapUV and depth: the pixel the motion was taken from.
float Disocclusion(float2 tapUV, float depth, float2 motion, float2 historyUV)
{
    float2 ndc = float2(tapUV.x * 2.0 - 1.0, 1.0 - tapUV.y * 2.0) - float2(2.0, -2.0) * gTaa.xy * gTexel.xy;
    float4 previous = mul(float4(ndc, depth, 1.0), gReproject);
    float w = abs(previous.w) > 1e-6 ? previous.w : 1e-6;
    float2 cameraMotion = (previous.xy / w - ndc) * float2(0.5, -0.5);

    // Where the world was still, the distance this point had last frame is known exactly. What moved by itself is
    // compared with its distance now, with more room for its own motion along the view.
    bool moved = length((motion - cameraMotion) * gTexel.zw) > 0.5;
    float expected = moved ? Distance(depth) : Distance(previous.z / w);
    float tolerance = gPrevious.z * (moved ? 4.0 : 1.0);

    // Covered only when all the depths around were nearer: depth changes fast between pixels at edges and at grazing
    // angles, and a still edge must keep its history
    float farthest = 0.0;
    [unroll]
    for (int y = -1; y <= 1; ++y)
    {
        [unroll]
        for (int x = -1; x <= 1; ++x)
            farthest = max(farthest, Distance(tex2Dlod(PreviousDepthTex, float4(historyUV + float2(x, y) * gTexel.xy, 0.0, 0.0)).r));
    }
    return saturate((1.0 - farthest / max(expected, 1e-6) - tolerance) / tolerance);
}

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    static const float2 offsets[9] =
    {
        float2(-1.0, -1.0), float2(0.0, -1.0), float2(1.0, -1.0),
        float2(-1.0,  0.0), float2(0.0,  0.0), float2(1.0,  0.0),
        float2(-1.0,  1.0), float2(0.0,  1.0), float2(1.0,  1.0)
    };

    float3 m1 = 0.0;
    float3 m2 = 0.0;
    float3 boxMin = 65504.0;
    float3 boxMax = -65504.0;
    float3 filtered = 0.0;
    float filterWeight = 0.0;

    float closestDepth = 1.0;
    float2 closestOffset = 0.0;

    [unroll]
    for (int i = 0; i < 9; ++i)
    {
        float2 tap = uv + offsets[i] * gTexel.xy;
        float3 c = FetchCurrent(tap);

        m1 += c;
        m2 += c * c;
        boxMin = min(boxMin, c);
        boxMax = max(boxMax, c);

        // Each pixel holds the scene sampled at its center minus the jitter
        float2 d = offsets[i] - gTaa.xy;
        float w = exp(-2.29 * dot(d, d));
        filtered += c * w;
        filterWeight += w;

        float depth = tex2Dlod(DepthTex, float4(tap, 0.0, 0.0)).r;
        if (depth < closestDepth)
        {
            closestDepth = depth;
            closestOffset = offsets[i];
        }
    }

    filtered /= filterWeight;

    float2 motion = tex2Dlod(MotionTex, float4(uv + closestOffset * gTexel.xy, 0.0, 0.0)).xy;
    float2 historyUV = uv + motion;

    float3 mean = m1 / 9.0;
    float3 sigma = sqrt(max(m2 / 9.0 - mean * mean, 0.0));
    float3 clipMin = max(boxMin, mean - gTaa.w * sigma);
    float3 clipMax = min(boxMax, mean + gTaa.w * sigma);

    float3 result = filtered;
    float stillAge = 0.0;
    bool onScreen = all(historyUV == saturate(historyUV));

    if (gTaa.z > 0.0 && onScreen)
    {
        float3 rawHistory = FetchHistory(historyUV);
        float3 history = ClipTowardsCenter(clipMin, clipMax, rawHistory);

        float disocclusion = 0.0;
        if (gPrevious.z > 0.0)
            disocclusion = Disocclusion(uv + closestOffset * gTexel.xy, closestDepth, motion, historyUV);

        // Detail thinner than a pixel is only hit by some of the jitter positions. In the frames it's missed by all nine
        // samples, the box doesn't contain it and the clip throws it out of the history, so it flickers even with a still
        // camera. Where nothing moves, part of the history is kept as is. Only once the pixel has been still for a few
        // frames: where something has just moved away, the history still holds it, and keeping it as is would leave a
        // trail behind every walking character.
        float speed = length(motion * gTexel.zw);
        float still = saturate(1.0 - speed / gStatic.y) * (1.0 - disocclusion);
        float stillFor = gPrevious.w > 0.0 ? tex2Dlod(HistoryTex, float4(historyUV, 0.0, 0.0)).a : 1.0;
        history = lerp(history, rawHistory, gStatic.x * still * stillFor);
        float currentWeight = max(lerp(gBlend.x, gBlend.y, saturate(speed * gBlend.z)), disocclusion);
        stillAge = still * saturate(stillFor + StillStep);
        if (gReactive.z > 0.0)
        {
            float scene = Luma(tex2Dlod(CurrentTex, float4(uv, 0.0, 0.0)).rgb);
            float opaque = tex2Dlod(OpaqueLumaTex, float4(uv, 0.0, 0.0)).r;
            currentWeight = max(currentWeight, ReactiveValue(scene, opaque));
        }
        result = lerp(history, filtered, currentWeight);

        if (gStatic.z > 0.0)
        {
            float2 previousMotion = tex2Dlod(PreviousMotionTex, float4(historyUV, 0.0, 0.0)).xy;
            float change = length((previousMotion - motion) * gTexel.zw);
            result = lerp(result, filtered, saturate((change - gStatic.z) / gStatic.w));
        }
    }

    return float4(Expand(FromYCoCg(result)), gPrevious.w > 0.0 ? stillAge : 1.0);
}
