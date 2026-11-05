cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
	float4 globalScalars2 : packoffset(c1);
	float4 globalScalars3 : packoffset(c2);
	float4 globalScalars4 : packoffset(c3);
	float4 globalFogParams : packoffset(c4);
	float4 globalFogColor : packoffset(c5);
	float4 globalFogOffsetN : packoffset(c6);
	float4 globalFogColorN : packoffset(c7);
	float4 globalScreenSize : packoffset(c8);
	float4 globalDayNightEffects : packoffset(c9);
	float4 ColorCorrectTopAndPedReflectScale : packoffset(c10);
	float4 ColorCorrectBottomOffset : packoffset(c11);
	float4 ColorShift : packoffset(c12);
	float4 deSatContrastGamma : packoffset(c13);
	float4 deSatContrastGammaIFX : packoffset(c14);
	float4 colorize : packoffset(c15);
	float4 globalUmScalars : packoffset(c16);
	float4 gToneMapScalers : packoffset(c17);
	float4 gAmbientOcclusionEffect : packoffset(c18);
};

cbuffer stipplingPattern : register(b3)
{
	float4 stipplePattern : packoffset(c0);
};

cbuffer CacheMegaVariables : register(b4)
{
	float3 ambientDecalMask : packoffset(c0);
};

static const float4 icb[4] =
{
	float4(1, 0, 0, 0),
	float4(0, 1, 0, 0),
	float4(0, 0, 1, 0),
	float4(0, 0, 0, 1),
};

SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	noperspective float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 texcoord6 : TEXCOORD6;
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

	int4 r0;
	r0.xy = asint(i.sv_position.xy * float2(0.5, 0.5));
	r0.zw = (asfloat(r0.xy) >= -(asfloat(r0.xy))) ? -1 : 0;
	r0.xy = asint(frac(abs(asfloat(r0.xy))));
	r0.xy = (r0.zw != 0) ? r0.xy : asint(-(asfloat(r0.xy)));
	r0.xy = asint(asfloat(r0.xy) + asfloat(r0.xy));
	r0.xy = asint(floor(asfloat(r0.xy)));
	r0.x = asint(asfloat(r0.y) * 2 + asfloat(r0.x));
	r0.x = (uint)asfloat(r0.x);
	r0.x = asint(dot(stipplePattern, icb[r0.x]));
	r0.x = (asfloat(r0.x) >= 0) ? -1 : 0;
	if (r0.x != 0) discard;
	r0 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r0.w = asint(asfloat(r0.w) * i.color.w);
	r0.x = asint(dot(asfloat(r0.xyz), ambientDecalMask.xyz));
	r0.x = asint(saturate(-(asfloat(r0.x)) + 1));
	r0.x = asint(asfloat(r0.w) * asfloat(r0.x));
	r0.x = asint(asfloat(r0.x) * globalScalars.x);
	o.sv_target2.w = asfloat(r0.x) * gAmbientOcclusionEffect.x;
	o.sv_target = float4(0, 0, 0, 0);
	o.sv_target1 = float4(0, 0, 0, 0);
	o.sv_target2.xyz = float3(0, 0, 0);
	o.sv_target3 = float4(0, 0, 0, 0);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
