Texture2D<float4> Scene : register(t0);
Texture2D<float4> Motion : register(t1);
Texture2D<float> Depth : register(t2);
Texture2D<float4> History : register(t3);
Texture2D<float> PreviousDepth : register(t4);
Texture2D<float4> Original : register(t5);
SamplerState PointSampler : register(s0);
SamplerState LinearSampler : register(s1);
cbuffer Parameters : register(b0)
{
    float4 Pixel;
    float4 Temporal;
    float4 Camera;
    float4 Jitter;
    row_major float4x4 PreviousClip;
};
#define POINT(texture, uv) texture.SampleLevel(PointSampler, uv, 0)
#define LINEAR(texture, uv) texture.SampleLevel(LinearSampler, uv, 0)
#define OUTPUT SV_Target
#define PIXEL_INPUT float4 position : SV_Position, float2 uv : TEXCOORD0

struct VertexOutput
{
    float4 Position : SV_Position;
    float2 UV : TEXCOORD0;
};

VertexOutput Fullscreen(uint index : SV_VertexID)
{
    VertexOutput output;
    output.UV = float2((index << 1) & 2, index & 2);
    output.Position = float4(output.UV * float2(2, -2) + float2(-1, 1), 0, 1);
    return output;
}

float3 ToYCoCg(float3 color)
{
    return float3(dot(color, float3(0.25, 0.5, 0.25)), color.r - color.b, color.g - (color.r + color.b) * 0.5);
}

float3 SceneColor(float2 uv)
{
    float3 color = max(LINEAR(Scene, uv).rgb, 0);
    return color;
}

float3 FromYCoCg(float3 color)
{
    return float3(color.x + (color.y - color.z) * 0.5, color.x + color.z * 0.5, color.x - (color.y + color.z) * 0.5);
}

float4 Reproject(float2 uv, float depth)
{
    float2 unjittered = uv - Jitter.xy;
    return mul(float4(unjittered * float2(2, -2) + float2(-1, 1), depth, 1), PreviousClip);
}

float4 ScreenMotion(float2 uv)
{
    float2 center = (floor(uv / Pixel.xy) + 0.5) * Pixel.xy;
    float2 nearest = center;
    float nearestDepth = POINT(Depth, center).r;
    [unroll] for (int y = -1; y <= 1; ++y)
    {
        [unroll] for (int x = -1; x <= 1; ++x)
        {
            float2 sampleUV = center + float2(x, y) * Pixel.xy;
            float sampleDepth = POINT(Depth, sampleUV).r;
            if (sampleDepth < nearestDepth)
            {
                nearestDepth = sampleDepth;
                nearest = sampleUV;
            }
        }
    }
    float2 velocity = POINT(Motion, nearest).rg;
    if (nearestDepth >= 0.9999999 || any(abs(velocity) > 1.5))
    {
        float4 previous = Reproject(nearest, nearestDepth);
        velocity = previous.xy / max(previous.w, 0.000001) * float2(0.5, -0.5) + 0.5 - (nearest - Jitter.xy);
    }
    return float4(velocity, nearest);
}

float3 SampleHistory(float2 uv)
{
    float2 size = 1.0 / Pixel.xy;
    float2 position = uv * size;
    float2 center = floor(position - 0.5) + 0.5;
    float2 f = position - center;
    float2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
    float2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
    float2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
    float2 w3 = f * f * (-0.5 + 0.5 * f);
    float2 w12 = w1 + w2;
    float2 uv0 = (center - 1) * Pixel.xy;
    float2 uv3 = (center + 2) * Pixel.xy;
    float2 uv12 = (center + w2 / w12) * Pixel.xy;
    float3 color = LINEAR(History, float2(uv12.x, uv0.y)).rgb * w12.x * w0.y;
    color += LINEAR(History, float2(uv0.x, uv12.y)).rgb * w0.x * w12.y;
    color += LINEAR(History, uv12).rgb * w12.x * w12.y;
    color += LINEAR(History, float2(uv3.x, uv12.y)).rgb * w3.x * w12.y;
    color += LINEAR(History, float2(uv12.x, uv3.y)).rgb * w12.x * w3.y;
    float weight = w12.x * w0.y + w0.x * w12.y + w12.x * w12.y + w3.x * w12.y + w12.x * w3.y;
    return max(color / weight, 0);
}

float LinearDepth(float depth)
{
    return Camera.x * Camera.y / max(Camera.y - depth * (Camera.y - Camera.x), 0.000001);
}

float4 Resolve(PIXEL_INPUT) : OUTPUT
{
    float2 currentUV = uv + Jitter.xy;
    float3 current = SceneColor(currentUV);
    float4 sample = ScreenMotion(currentUV);
    float2 closest = sample.zw;
    float depth = POINT(Depth, closest).r;
    float2 motion = sample.xy;
    float2 historyUV = uv + motion;
    if (Temporal.w == 0 || any(historyUV < 0) || any(historyUV > 1))
        return float4(current, 1);
    float4 previous = Reproject(closest, depth);
    float expected = LinearDepth(previous.z / max(previous.w, 0.000001));
    float farthest = 0;
    [unroll] for (int sy = -1; sy <= 1; ++sy)
        [unroll] for (int sx = -1; sx <= 1; ++sx)
            farthest = max(farthest, LinearDepth(POINT(PreviousDepth, historyUV + float2(sx, sy) * Pixel.xy).r));
    if (farthest < expected * 0.96)
        return float4(current, 1);
    float3 mean = 0;
    float3 square = 0;
    [unroll] for (int y = -1; y <= 1; ++y)
    {
        [unroll] for (int x = -1; x <= 1; ++x)
        {
            float3 color = ToYCoCg(SceneColor(currentUV + float2(x, y) * Pixel.xy));
            mean += color;
            square += color * color;
        }
    }
    mean /= 9;
    float3 sigma = sqrt(max(square / 9 - mean * mean, 0)) * Temporal.z;
    float3 history = ToYCoCg(SampleHistory(historyUV));
    float3 offset = history - mean;
    float3 extent = abs(offset) / max(sigma, 0.0001);
    history = mean + offset / max(1, max(extent.x, max(extent.y, extent.z)));
    float weight = lerp(Temporal.x, Temporal.y, saturate(length(motion / Pixel.xy) * Camera.z));
    return float4(max(FromYCoCg(lerp(history, ToYCoCg(current), weight)), 0), 1);
}

float3 Compress(float3 color)
{
    return color / (1 + max(color.r, max(color.g, color.b)));
}

float3 Expand(float3 color)
{
    return color / max(1 - max(color.r, max(color.g, color.b)), 0.0001);
}

float4 BridgeColor(PIXEL_INPUT) : OUTPUT
{
    float3 color = SceneColor(uv);
    return float4(Pixel.z > 0 ? Compress(color) : color, 1);
}

float4 CopyDepth(PIXEL_INPUT) : OUTPUT
{
    return float4(POINT(Depth, uv).r, 0, 0, 0);
}

float4 HistoryDepth(PIXEL_INPUT) : OUTPUT
{
    return float4(POINT(Depth, uv + Jitter.xy).r, 0, 0, 0);
}

float4 BridgeMotion(PIXEL_INPUT) : OUTPUT
{
    return float4(ScreenMotion(uv).xy, 0, 0);
}

float3 Resolved(float2 uv)
{
    float3 color = POINT(Scene, uv).rgb;
    return Pixel.z > 0 ? Expand(color) : color;
}

float4 Output(PIXEL_INPUT) : OUTPUT
{
    float3 current = Resolved(uv);
    float3 north = Resolved(uv - float2(0, Pixel.y));
    float3 south = Resolved(uv + float2(0, Pixel.y));
    float3 west = Resolved(uv - float2(Pixel.x, 0));
    float3 east = Resolved(uv + float2(Pixel.x, 0));
    float3 low = min(current, min(min(north, south), min(west, east)));
    float3 high = max(current, max(max(north, south), max(west, east)));
    current = clamp(current + Camera.w * (current - (north + south + west + east) * 0.25), low, high);
    return float4(current, POINT(Original, uv).a);
}
