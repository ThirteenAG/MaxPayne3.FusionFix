// The scene's luma before transparent geometry (particles, glass): the resolve and FSR's reactive mask compare the
// finished scene with it

sampler2D Source : register(s0);

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    return dot(tex2Dlod(Source, float4(uv, 0.0, 0.0)).rgb, float3(0.2126, 0.7152, 0.0722)).xxxx;
}
