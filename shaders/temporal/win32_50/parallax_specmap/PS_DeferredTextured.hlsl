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

cbuffer CacheZShiftandParallax : register(b4)
{
	float parallaxScaleBias : packoffset(c0);
};

cbuffer CacheMegaVariables : register(b7)
{
	float specularFactor : packoffset(c0);
	float3 specMapIntMask : packoffset(c0.y);
	float4 specMapExpMask : packoffset(c1);
	float bumpiness : packoffset(c2);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState SpecSampler : register(s2);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D SpecSampler_tex : register(t2);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float4 texcoord7 : TEXCOORD7;
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
	r0.xyz = asint(i.texcoord7.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.z = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r0.xy = asint(asfloat(r0.zz) * asfloat(r0.xy));
	r0.z = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).w);
	r0.w = asint(parallaxScaleBias * 0.5);
	r0.z = asint(asfloat(r0.z) * parallaxScaleBias + -(asfloat(r0.w)));
	r0.xy = asint(asfloat(r0.zz) * asfloat(r0.xy) + i.texcoord.xy);
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, asfloat(r0.xy));
	r0.xy = asint(BumpSampler_tex.Sample(BumpSampler, asfloat(r0.xy)).xy);
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.z = (asfloat(r0.z) >= 0.00200000009) ? -1 : 0;
	r0.z = r0.z & 1065353216;
	r0.w = asint(saturate(i.color.x * asfloat(r0.z) + -1));
	r0.w = asint(asfloat(r0.w) * globalScalars2.z);
	o.sv_target.xyz = r1.xyz * asfloat(r0.zzz) + asfloat(r0.www);
	r0.w = asint(r1.w * i.color.w);
	r0.w = asint(asfloat(r0.w) * globalScalars.x);
	o.sv_target.w = asfloat(r0.w);
	r1.x = dot(asfloat(r0.xy), asfloat(r0.xy));
	r1.x = -(r1.x) + 1;
	r1.x = max(r1.x, 0);
	r1.x = sqrt(r1.x);
	r1.yzw = asfloat(r0.xxx) * i.texcoord4.xyz;
	r1.xyz = r1.xxx * i.texcoord1.xyz + r1.yzw;
	r1.xyz = asfloat(r0.yyy) * i.texcoord5.xyz + r1.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = asint(dot(r1.xyz, r1.xyz));
	r0.x = asint(rsqrt(asfloat(r0.x)));
	r1.xyz = asfloat(r0.xxx) * r1.xyz;
	o.sv_target1.xyz = r1.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = asfloat(r0.w);
	r0.x = asint(asfloat(r0.z) * i.color.x);
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	o.sv_target2.w = asfloat(r0.w);
	o.sv_target3.w = asfloat(r0.w);
	r1 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.x = asint(dot(r1.xyz, specMapIntMask));
	r0.y = asint(dot(r1, specMapExpMask));
	r0.y = asint(asfloat(r0.y) * specularFactor);
	r0.y = asint(max(asfloat(r0.y), 1));
	r0.y = asint(asfloat(r0.y) * 0.00510204071);
	r0.y = asint(min(asfloat(r0.y), 1));
	r0.y = asint(sqrt(asfloat(r0.y)));
	o.sv_target2.y = sqrt(asfloat(r0.y));
	o.sv_target2.x = asfloat(r0.z) * asfloat(r0.x);
	o.sv_target3.xyz = float3(0, 0, 0);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
