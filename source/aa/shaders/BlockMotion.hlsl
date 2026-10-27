// Object motion, per block of pixels: what the camera's motion doesn't describe (an animated character, a moving car)
// is found by searching the last frame's luma around where the camera motion puts the block. The target has one pixel
// per block; xy: the block's motion (previous - current position in texture coordinates, jitter excluded, like the
// camera motion), z: the block's difference at that motion, w: the difference at the camera motion.

sampler2D CurrentLuma : register(s0);
sampler2D PreviousLuma : register(s1);              // linear
sampler2D CameraMotion : register(s2);

float4 gTexel : register(c0);                       // 1 / width, 1 / height, width, height
float4 gBlocks : register(c1);                      // xy: the last frame's jitter - this frame's, in pixels; zw: blocks across, down
float4 gSearch : register(c2);                      // x: block size in pixels, y: search radius in pixels, z: share of the camera motion's difference
                                                    // the best motion must stay under, w: mean difference per pixel below which
                                                    // the camera motion fits
float4 gGeometry : register(c3);                    // x: depth deviation (CameraMotion's z) under which the block's geometry didn't move

static const int Taps = 16;

float Difference(float2 origin, float2 offset)
{
    float sum = 0.0;
    [loop]
    for (int i = 0; i < Taps; ++i)
    {
        float2 p = origin + float2(i % 4, i / 4) * (gSearch.x * 0.25);
        float current = tex2Dlod(CurrentLuma, float4(p * gTexel.xy, 0.0, 0.0)).r;
        sum += abs(current - tex2Dlod(PreviousLuma, float4((p + offset) * gTexel.xy, 0.0, 0.0)).r);
    }
    return sum;
}

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    // Pixel centers of a 4x4 grid over the block
    float2 origin = floor(uv * gBlocks.zw) * gSearch.x + gSearch.x * 0.125 + 0.5;
    float deviation = 0.0;
    [loop]
    for (int i = 0; i < Taps; ++i)
    {
        float2 p = origin + float2(i % 4, i / 4) * (gSearch.x * 0.25);
        deviation = max(deviation, tex2Dlod(CameraMotion, float4(p * gTexel.xy, 0.0, 0.0)).z);
    }

    float2 camera = tex2Dlod(CameraMotion, float4((origin + gSearch.x * 0.375) * gTexel.xy, 0.0, 0.0)).xy * gTexel.zw;
    // Geometry where the camera motion puts it: a change of the picture there is lighting, flicker or an effect
    if (deviation < gGeometry.x)
        return float4(camera * gTexel.xy, 0.0, 0.0);
    float2 base = camera + gBlocks.xy;

    float cameraDifference = Difference(origin, base);
    float best = cameraDifference;
    if (cameraDifference < gSearch.w * Taps)
        return float4(camera * gTexel.xy, cameraDifference, cameraDifference);
    float2 bestOffset = 0.0;
    int radius = (int)gSearch.y;
    [loop]
    for (int y = -radius; y <= radius; ++y)
    {
        [loop]
        for (int x = -radius; x <= radius; ++x)
        {
            float d = Difference(origin, base + float2(x, y));
            // Only a clearly lower difference replaces the motion found so far
            if (d < best - 1e-4)
            {
                best = d;
                bestOffset = float2(x, y);
            }
        }
    }

    // Not clearly better: brightness changes, flicker or noise rather than motion
    if (best >= cameraDifference * gSearch.z)
        return float4(camera * gTexel.xy, cameraDifference, cameraDifference);

    // Sub-pixel: a parabola through the differences next to the best offset
    float2 sub = 0.0;
    if (any(bestOffset != 0.0))
    {
        float l = Difference(origin, base + bestOffset - float2(1.0, 0.0));
        float r = Difference(origin, base + bestOffset + float2(1.0, 0.0));
        float u = Difference(origin, base + bestOffset - float2(0.0, 1.0));
        float d = Difference(origin, base + bestOffset + float2(0.0, 1.0));
        float dx = l - 2.0 * best + r;
        float dy = u - 2.0 * best + d;
        sub.x = dx > 1e-5 ? clamp((l - r) / (2.0 * dx), -0.5, 0.5) : 0.0;
        sub.y = dy > 1e-5 ? clamp((u - d) / (2.0 * dy), -0.5, 0.5) : 0.0;
    }

    return float4((camera + bestOffset + sub) * gTexel.xy, best, cameraDifference);
}
