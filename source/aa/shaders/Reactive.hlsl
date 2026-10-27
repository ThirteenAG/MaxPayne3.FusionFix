// FSR's reactive mask: how much a pixel should follow the current frame, from its difference with the scene's luma
// before transparent geometry (particles, glass and effects have no motion vectors of their own)

sampler2D SceneTex : register(s0);
sampler2D OpaqueTex : register(s1);

float4 gReactive : register(c0);                    // x: scale, y: maximum

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    float scene = max(dot(tex2Dlod(SceneTex, float4(uv, 0.0, 0.0)).rgb, float3(0.2126, 0.7152, 0.0722)), 0.0);
    float opaque = max(tex2Dlod(OpaqueTex, float4(uv, 0.0, 0.0)).r, 0.0);
    // Compared after a tonemap: a bright particle on a dark background counts as much as a dark one on a bright one
    float difference = abs(scene / (1.0 + scene) - opaque / (1.0 + opaque));
    return (saturate(difference * gReactive.x) * gReactive.y).xxxx;
}
