cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
};

cbuffer AlphaTest : register(b11)
{
	float g_AlphaRef : packoffset(c0);
};

cbuffer CacheVehicleParams : register(b4)
{
	float3 matDiffuseColor : packoffset(c0);
	float4 matDiffuseColor2 : packoffset(c1);
	float HardAlphaBlend : packoffset(c2);
};

SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float3 temporalPrevious : TEXCOORD15;
};

struct PS_OUT
{
	float4 sv_target : SV_Target;
	float4 sv_target1 : SV_Target1;
	float4 sv_target2 : SV_Target2;
	float4 sv_target3 : SV_Target3;
	float2 temporalVelocity : SV_Target4;
};

PS_OUT main(PS_IN i)
{
	PS_OUT o;

	int3 r0;
	r0.x = asint(-(g_AlphaRef) + 1);
	r0.x = asint(asfloat(r0.x) * 0.100000001);
	r0.y = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).w);
	r0.y = asint(asfloat(r0.y) * i.texcoord2.w);
	r0.z = asint(asfloat(r0.y) * globalScalars.x + -(g_AlphaRef));
	r0.x = asint(asfloat(r0.z) / asfloat(r0.x));
	r0.x = asint(-(asfloat(r0.y)) * globalScalars.x + asfloat(r0.x));
	r0.y = asint(asfloat(r0.y) * globalScalars.x);
	r0.x = asint(HardAlphaBlend * asfloat(r0.x) + asfloat(r0.y));
	r0.y = (0.00392156886 >= asfloat(r0.x)) ? -1 : 0;
	o.sv_target.w = asfloat(r0.x);
	if (r0.y != 0) discard;
	o.sv_target.xyz = float3(0, 0, 0);
	o.sv_target1 = float4(0, 0, 0, 0);
	o.sv_target2 = float4(0, 0, 0, 0);
	o.sv_target3 = float4(0, 0, 0, 0);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
