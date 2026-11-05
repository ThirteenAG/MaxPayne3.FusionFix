cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
};

cbuffer CacheMegaVariables : register(b4)
{
	float emissiveMultiplier : packoffset(c0);
	float emissiveReflectMultiplier : packoffset(c0.y);
	float specularFactor : packoffset(c0.z);
	float specularColorFactor : packoffset(c0.w);
};

SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	r0.x = asint(-(i.texcoord3.z) + -512);
	r0.x = (asfloat(r0.x) < 0) ? -1 : 0;
	if (r0.x != 0) discard;
	r0 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r0 = asint(abs(asfloat(r0)) + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0 = asint(log2(asfloat(r0)));
	r0 = asint(asfloat(r0) * float4(2.20001006, 2.20001006, 2.20001006, 2.20001006));
	r0 = asint(exp2(asfloat(r0)));
	r0 = asint(asfloat(r0) * i.color);
	r0.w = asint(asfloat(r0.w) * globalScalars.x);
	r0.xyz = asint(asfloat(r0.xyz) * emissiveMultiplier);
	r0.xyz = asint(saturate(asfloat(r0.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.xyz = sqrt(asfloat(r0.xyz));
	r0.x = asint(-(i.texcoord1.w) + 64);
	r0.x = asint(saturate(asfloat(r0.x) * 0.25));
	o.w = asfloat(r0.x) * asfloat(r0.w);

	return o;
}
