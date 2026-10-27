// The motion of each pixel: the camera's, or the motion of its block or of a block next to it (BlockMotion) where that
// matches the last frame clearly better around the pixel. Previous - current position in texture coordinates, jitter
// excluded.

sampler2D CurrentLuma : register(s0);
sampler2D PreviousLuma : register(s1);              // linear
sampler2D CameraMotion : register(s2);
sampler2D BlockMotion : register(s3);

float4 gTexel : register(c0);                       // 1 / width, 1 / height, width, height
float4 gBlocks : register(c1);                      // xy: the last frame's jitter - this frame's, in pixels; zw: blocks across, down
float4 gSelect : register(c2);                      // x: block size in pixels, y: share of the camera motion's difference a block's must stay under,
                                                    // z: mean difference per pixel below which the camera motion fits

float Difference(float current[9], float2 uv, float2 motion)
{
    float2 shift = motion + gBlocks.xy * gTexel.xy;
    float sum = 0.0;
    [unroll]
    for (int i = 0; i < 9; ++i)
    {
        float2 tap = uv + float2(i % 3 - 1, i / 3 - 1) * gTexel.xy;
        sum += abs(current[i] - tex2Dlod(PreviousLuma, float4(tap + shift, 0.0, 0.0)).r);
    }
    return sum;
}

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    float current[9];
    [unroll]
    for (int i = 0; i < 9; ++i)
        current[i] = tex2Dlod(CurrentLuma, float4(uv + float2(i % 3 - 1, i / 3 - 1) * gTexel.xy, 0.0, 0.0)).r;

    float2 camera = tex2Dlod(CameraMotion, float4(uv, 0.0, 0.0)).xy;
    float2 best = camera;
    float cameraDifference = Difference(current, uv, camera);
    float bestDifference = cameraDifference * gSelect.y;
    if (cameraDifference < gSelect.z * 9.0)
        return float4(camera, 0.0, 1.0);

    float2 block = floor(uv * gTexel.zw / gSelect.x);
    [unroll]
    for (int j = 0; j < 9; ++j)
    {
        float2 b = block + float2(j % 3 - 1, j / 3 - 1);
        if (any(b < 0.0) || any(b >= gBlocks.zw))
            continue;
        float4 candidate = tex2Dlod(BlockMotion, float4((b + 0.5) / gBlocks.zw, 0.0, 0.0));
        // Blocks where the camera motion fit as well have nothing else to offer
        if (candidate.z >= candidate.w)
            continue;
        float d = Difference(current, uv, candidate.xy);
        if (d < bestDifference)
        {
            bestDifference = d;
            best = candidate.xy;
        }
    }

    return float4(best, 0.0, 1.0);
}
