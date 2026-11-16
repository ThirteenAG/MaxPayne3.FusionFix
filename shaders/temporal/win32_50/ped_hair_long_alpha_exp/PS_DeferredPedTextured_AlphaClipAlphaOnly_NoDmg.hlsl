cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
};

cbuffer CachePedParam : register(b4)
{
	float HardAlphaBlend : packoffset(c0);
	float ArmourStrength : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
	float displacementScale : packoffset(c0.w);
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
	float3 texcoord7 : TEXCOORD7;
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

	int2 r0;
	r0.x = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).w);
	r0.x = asint(asfloat(r0.x) * i.texcoord2.w);
	r0.y = asint(asfloat(r0.x) * globalScalars.x + -0.501960814);
	r0.x = asint(asfloat(r0.x) * globalScalars.x);
	r0.y = asint(asfloat(r0.y) * 20.0787411 + -(asfloat(r0.x)));
	r0.x = asint(HardAlphaBlend * asfloat(r0.y) + asfloat(r0.x));
	r0.y = (0.501960814 >= asfloat(r0.x)) ? -1 : 0;
	o.sv_target.w = saturate(asfloat(r0.x) + 0.00784313772);
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
