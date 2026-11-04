sampler2D AdapLumSampler : register(s1);
sampler2D BloomSampler : register(s10);
sampler2D CurLumSampler : register(s0);
sampler2D DeathSampler : register(s15);
sampler2D GBufferTextureSamplerSSAODepth : register(s4);
sampler2D HDRSampler : register(s5);
float4 SunRaysParams : register(c192);
float4 ToneMapParams : register(c144);
float4 lightrayParams : register(c191);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float3 r2;
	r0 = tex2D(CurLumSampler, texcoord.xy);
	r0.x = r0.x * 0.6 + 1;
	r0.x = r0.x * r0.x;
	r0.x = 1 / r0.x;
	r1 = tex2D(GBufferTextureSamplerSSAODepth, texcoord.xy);
	r0.y = r1.x * 4;
	r0.x = r0.x * r0.y;
	r1 = tex2D(HDRSampler, texcoord.xy);
	r0.yzw = r1.xyz * SunRaysParams.xyz;
	r0.yzw = r0.yzw * 16;
	r0.xyz = lightrayParams.xyz * r0.xxx + r0.yzw;
	r1 = tex2D(AdapLumSampler, 0);
	r0.w = 1 / r1.x;
	r0.w = r0.w * ToneMapParams.y;
	r0.w = 1 / r0.w;
	r1 = tex2D(BloomSampler, texcoord.xy);
	r2 = max(r1.xyz, 0);
	r1.xyz = min(r2.xyz, 11);
	r1.xyz = ToneMapParams.xxx * -r0.www + r1.xyz;
	r2 = max(r1.xyz, 0);
	r1 = tex2D(DeathSampler, texcoord.xy);
	r0.w = -r1.x + 1;
	r1.x = -ToneMapParams.z + ToneMapParams.w;
	r0.w = r0.w * r1.x + ToneMapParams.z;
	r0.w = 1 / r0.w;
	o.xyz = r0.xyz * r0.www + r2.xyz;
	o.w = 1;

	return o;
}
