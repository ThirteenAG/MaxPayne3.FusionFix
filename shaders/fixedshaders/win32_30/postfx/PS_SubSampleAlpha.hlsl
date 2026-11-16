sampler2D GBufferTextureSampler2 : register(s2);
sampler2D HDRPointSampler : register(s6);
float4 TexelSize : register(c88);

struct PS_IN
{
	float2 texcoord : TEXCOORD;
	float2 vpos : VPOS;
};

float4 main(PS_IN i) : COLOR
{
	float4 o;

	float3 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	r0.x = i.vpos.y + i.vpos.x;
	r0.y = frac(r0.x);
	r0.z = (-r0.y >= 0) ? 0 : 1;
	r0.y = r0.x + -r0.y;
	r0.x = (r0.x >= 0) ? 0 : r0.z;
	r0.x = r0.x + r0.y;
	r0.yz = (r0.xx >= 0) ? float2(2, 0.5) : float2(-2, -0.5);
	r0.x = r0.z * r0.x;
	r0.x = frac(r0.x);
	r0.x = r0.x * r0.y;
	r0.y = frac(r0.x);
	r0.z = (-r0.y >= 0) ? 0 : 1;
	r0.y = r0.x + -r0.y;
	r0.x = (r0.x >= 0) ? 0 : r0.z;
	r0.x = r0.x + r0.y;
	r1 = tex2D(GBufferTextureSampler2, i.texcoord.xy);
	r0.y = (-abs(r1.w) >= 0) ? 1 : r1.w;
	r0.z = -r0.y + 1;
	r0.x = (-abs(r0.x) >= 0) ? r0.y : r0.z;
	r1.xy = float2(1, 0);
	r0.yz = TexelSize.xy * r1.xy + i.texcoord.xy;
	r2 = tex2D(HDRPointSampler, r0.yz);
	r3 = tex2D(HDRPointSampler, i.texcoord.xy);
	r4 = lerp(r3, r2, r0.x);
	o = (-abs(r1.w) >= 0) ? r3 : r4;

	return o;
}
