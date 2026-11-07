Texture2D<float4> Composite : register(t0);
cbuffer Parameters : register(b0)
{
    float4 Output; // x: paper white or SDR white / 80 nits, y: peak / paper white, z: HDR enabled
};

float3 DecodeSRGB(float3 color)
{
    return color <= 0.04045 ? color / 12.92 : pow((color + 0.055) / 1.055, 2.4);
}

float4 HDROutput(float4 position : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
    float3 color = max(Composite.Load(int3(position.xy, 0)).rgb, 0);

    // HDR off: the original picture, at the brightness Windows gives SDR content on this display
    if (Output.z == 0)
        return float4(DecodeSRGB(saturate(color)) * Output.x, 1);

    // The game is graded for a 2.2 display, the piecewise sRGB curve would lift its dark scenes
    float3 linearColor = pow(color, 2.2);

    // Highlights above paper white roll off towards the peak, keeping their hue
    float peak = Output.y;
    float brightest = max(linearColor.r, max(linearColor.g, linearColor.b));
    if (brightest > 1)
    {
        float range = max(peak - 1, 0.0001);
        linearColor *= (1 + range * (1 - exp(-(brightest - 1) / range))) / brightest;
    }
    return float4(linearColor * Output.x, 1);
}
