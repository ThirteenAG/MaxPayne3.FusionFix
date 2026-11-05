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
SamplerState DirtSampler : register(s3);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D DirtSampler_tex : register(t3);

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

	float4 r0;
	float4 r1;
	int4 r2;
	float4 r3;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.xyz = r0.xyz * matDiffuseColor.xyz;
	r0 = r0 * i.texcoord2;
	r1.w = r0.w * globalScalars.x;
	r2.x = (0 < dirtLevel) ? -1 : 0;
	if (r2.x != 0) {
		r2.x = asint(DirtSampler_tex.Sample(DirtSampler, i.texcoord1).x);
		r2.y = (0 < asfloat(r2.x)) ? -1 : 0;
		r2.z = asint(asfloat(r2.x) * dirtLevel);
		r2.w = asint(-(asfloat(r2.x)) * dirtLevel + 1);
		r3.xyz = asfloat(r2.zzz) * dirtColor.xyz;
		r3.xyz = r0.xyz * asfloat(r2.www) + r3.xyz;
		r3.w = r0.w * globalScalars.x + asfloat(r2.x);
		r1.xyz = r0.xyz;
		o = (r2.y != 0) ? r3 : r1;
	} else {
		o.xyz = r0.xyz;
		o.w = r1.w;
	}

	return o;
}
