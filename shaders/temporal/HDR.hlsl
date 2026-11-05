Texture2D<float4> Composite : register(t0);
cbuffer Parameters : register(b0)
{
    float4 Output;
};

float3 Decode(float3 color)
{
    return color <= 0.04045 ? color / 12.92 : pow((color + 0.055) / 1.055, 2.4);
}

float4 HDROutput(float4 position : SV_Position, float2 uv : TEXCOORD0) : SV_Target
{
    float3 color = max(Composite.Load(int3(position.xy, 0)).rgb, 0);
    if (Output.z == 0)
        return float4(Decode(saturate(color)), 1);
    float3 linearColor = Decode(color);
    float start = min(Output.y * 0.8, 1.0);
    float range = max(Output.y - start, 0.0001);
    linearColor = linearColor <= start ? linearColor : start + range * (1 - exp(-(linearColor - start) / range));
    return float4(linearColor * Output.x, 1);
}
