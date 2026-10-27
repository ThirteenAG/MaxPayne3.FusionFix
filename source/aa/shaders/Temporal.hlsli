// Shared by the resolve passes (Resolve.hlsl, Stabilize.hlsl): included after their CurrentTex, HistoryTex, gTexel (1 / width,
// 1 / height, width, height) and gBlend (w: luma weight).

float Luma(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

// Luminance weighted reversible tonemap: keeps bright samples from dominating the filters
float3 Compress(float3 c)
{
    return c / (1.0 + Luma(c) * gBlend.w);
}

float3 Expand(float3 c)
{
    return c / max(1.0 - Luma(c) * gBlend.w, 1.0 / 65504.0);
}

float3 ToYCoCg(float3 c)
{
    return float3(dot(c, float3(0.25, 0.5, 0.25)), dot(c, float3(0.5, 0.0, -0.5)), dot(c, float3(-0.25, 0.5, -0.25)));
}

float3 FromYCoCg(float3 c)
{
    return float3(c.x + c.y - c.z, c.x + c.z, c.x - c.y - c.z);
}

float3 FetchCurrent(float2 uv)
{
    float3 c = tex2Dlod(CurrentTex, float4(uv, 0.0, 0.0)).rgb;
    return ToYCoCg(Compress(clamp(c, 0.0, 65000.0)));
}

float3 FetchHistory(float2 uv)
{
    // Catmull-Rom through five bilinear taps
    float2 position = uv * gTexel.zw;
    float2 center = floor(position - 0.5) + 0.5;
    float2 f = position - center;

    float2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
    float2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
    float2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
    float2 w3 = f * f * (-0.5 + 0.5 * f);

    float2 w12 = w1 + w2;
    float2 tc12 = (center + w2 / w12) * gTexel.xy;
    float2 tc0 = (center - 1.0) * gTexel.xy;
    float2 tc3 = (center + 2.0) * gTexel.xy;

    float4 result = float4(tex2Dlod(HistoryTex, float4(tc12.x, tc0.y, 0.0, 0.0)).rgb, 1.0) * (w12.x * w0.y);
    result += float4(tex2Dlod(HistoryTex, float4(tc0.x, tc12.y, 0.0, 0.0)).rgb, 1.0) * (w0.x * w12.y);
    result += float4(tex2Dlod(HistoryTex, float4(tc12.x, tc12.y, 0.0, 0.0)).rgb, 1.0) * (w12.x * w12.y);
    result += float4(tex2Dlod(HistoryTex, float4(tc3.x, tc12.y, 0.0, 0.0)).rgb, 1.0) * (w3.x * w12.y);
    result += float4(tex2Dlod(HistoryTex, float4(tc12.x, tc3.y, 0.0, 0.0)).rgb, 1.0) * (w12.x * w3.y);

    return ToYCoCg(Compress(clamp(result.rgb / result.a, 0.0, 65000.0)));
}

float3 ClipTowardsCenter(float3 boxMin, float3 boxMax, float3 history)
{
    float3 center = 0.5 * (boxMax + boxMin);
    float3 extents = 0.5 * (boxMax - boxMin) + 0.00001;
    float3 offset = history - center;
    float3 units = abs(offset / extents);
    float maxUnit = max(units.x, max(units.y, units.z));
    return maxUnit > 1.0 ? center + offset / maxUnit : history;
}
