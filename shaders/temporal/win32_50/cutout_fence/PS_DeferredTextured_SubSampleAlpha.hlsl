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

cbuffer AlphaTest : register(b11)
{
	float g_AlphaRef : packoffset(c0);
};

cbuffer CacheMegaVariables : register(b4)
{
	float HardAlphaBlend : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	noperspective float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
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
	float4 r1;
	r0.x = asint(i.sv_position.y + i.sv_position.x);
	r0.x = (uint)asfloat(r0.x);
	r0.x = r0.x & 1;
	r0.x = (r0.x == 0) ? -1 : 0;
	r0.y = asint(-(g_AlphaRef) + 1);
	r0.y = asint(asfloat(r0.y) * 0.100000001);
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.z = asint(r1.w * globalScalars.x + -(g_AlphaRef));
	r0.y = asint(asfloat(r0.z) / asfloat(r0.y));
	r0.y = asint(-(r1.w) * globalScalars.x + asfloat(r0.y));
	r0.z = asint(r1.w * globalScalars.x);
	r0.y = asint(HardAlphaBlend * asfloat(r0.y) + asfloat(r0.z));
	r0.z = (asfloat(r0.y) < 0.949999988) ? -1 : 0;
	r0.y = (0.00392156886 >= asfloat(r0.y)) ? -1 : 0;
	r0.x = r0.x & r0.z;
	r0.x = r0.y | r0.x;
	if (r0.x != 0) discard;
	r0.x = asint(saturate(i.color.x + -1));
	o.sv_target.xyz = asfloat(r0.xxx) * globalScalars2.zzz + r1.xyz;
	r0.x = asint(r1.w * i.color.w);
	r0.w = asint(asfloat(r0.x) * globalScalars.x);
	o.sv_target.w = 0;
	r1.xyz = i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = asint(dot(r1.xyz, r1.xyz));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r1.xyz = asfloat(r0.zzz) * r1.xyz;
	o.sv_target1.xyz = r1.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = asfloat(r0.w);
	r0.xy = int2(0, 1048576000);
	o.sv_target2.xyw = asfloat(r0.xyw);
	o.sv_target3 = asfloat(r0.xxxw);
	o.sv_target2.z = i.color.x * gAmbientOcclusionEffect.w;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
