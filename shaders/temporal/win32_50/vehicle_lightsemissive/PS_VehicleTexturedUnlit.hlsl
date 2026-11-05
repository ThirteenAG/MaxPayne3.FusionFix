cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
};

cbuffer CacheVehicleParams : register(b4)
{
	float3 matDiffuseColor : packoffset(c0);
};

cbuffer VehicleMaterial : register(b9)
{
	float dirtLevel : packoffset(c0);
	float3 dirtColor : packoffset(c0.y);
};

SamplerState DiffuseSampler : register(s0);
SamplerState DirtSampler : register(s2);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D DirtSampler_tex : register(t2);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	int4 r1;
	r0 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r0.xyz = asint(asfloat(r0.xyz) * matDiffuseColor.xyz);
	r0 = asint(asfloat(r0) * i.texcoord2);
	o.w = asfloat(r0.w) * globalScalars.x;
	r0.w = (0 < dirtLevel) ? -1 : 0;
	if (r0.w != 0) {
		r0.w = asint(DirtSampler_tex.Sample(DirtSampler, i.texcoord1).x);
		r1.x = (0 < asfloat(r0.w)) ? -1 : 0;
		r1.y = asint(asfloat(r0.w) * dirtLevel);
		r0.w = asint(-(asfloat(r0.w)) * dirtLevel + 1);
		r1.yzw = asint(asfloat(r1.yyy) * dirtColor.xyz);
		r1.yzw = asint(asfloat(r0.xyz) * asfloat(r0.www) + asfloat(r1.yzw));
		o.xyz = (r1.xxx != 0) ? asfloat(r1.yzw) : asfloat(r0.xyz);
	} else {
		o.xyz = asfloat(r0.xyz);
	}

	return o;
}
