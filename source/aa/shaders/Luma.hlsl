// The scene's luma, kept for one frame: the object motion search compares this frame's with the last one's

sampler2D Source : register(s0);

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    float3 c = max(tex2Dlod(Source, float4(uv, 0.0, 0.0)).rgb, 0.0);
    float luma = dot(c, float3(0.2126, 0.7152, 0.0722));
    return (luma / (1.0 + luma)).xxxx;
}
