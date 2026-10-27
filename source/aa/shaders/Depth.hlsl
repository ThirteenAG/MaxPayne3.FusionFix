// The scene's depth as R32F standard [0, 1] depth (0 near), for the motion vectors, the resolve, DLAA and FSR: the depth
// texture itself (INTZ) can't be copied to a shared texture. A logarithmic depth (distance = near * 2^(depth *
// log2(far / near))) is converted.

sampler2D SceneDepth : register(s0);

float4 gDepth : register(c0);                       // x: 1 logarithmic, 0 standard; y: near, z: log2(far / near), w: far

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    float depth = tex2Dlod(SceneDepth, float4(uv, 0.0, 0.0)).r;
    if (gDepth.x > 0.0)
    {
        float distance = gDepth.y * exp2(depth * gDepth.z);
        depth = gDepth.w * (distance - gDepth.y) / (distance * (gDepth.w - gDepth.y));
    }
    return depth.xxxx;
}
