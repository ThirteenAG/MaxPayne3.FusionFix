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
	float4 gWaterGlobals : packoffset(c19);
};

cbuffer AlphaTest : register(b11)
{
	float g_AlphaRef : packoffset(c0);
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
	float reflectivePower : packoffset(c2.y);
	float fresnelRolloff : packoffset(c2.z);
	float3 specMapReflectMask : packoffset(c3);
};

cbuffer Wet : register(b9)
{
	float4 WetDarken : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState PuddleMaskSampler : register(s2);
SamplerState SpecSampler : register(s3);
SamplerState EnvironmentSampler : register(s4);
SamplerState WaterRainRippleNormalSampler : register(s14);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D PuddleMaskSampler_tex : register(t2);
Texture2D SpecSampler_tex : register(t3);
Texture2D EnvironmentSampler_tex : register(t4);
Texture2D WaterRainRippleNormalSampler_tex : register(t14);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
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
	int4 r2;
	int4 r3;
	float3 r4;
	float3 r5;
	r0.x = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).w);
	r0.yzw = asint(i.texcoord7.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.yz = asint(asfloat(r0.ww) * asfloat(r0.yz));
	r0.w = asint(parallaxScaleBias * 0.5);
	r0.x = asint(asfloat(r0.x) * parallaxScaleBias + -(asfloat(r0.w)));
	r0.xy = asint(asfloat(r0.xx) * asfloat(r0.yz) + i.texcoord.xy);
	r0.zw = asint(BumpSampler_tex.Sample(BumpSampler, asfloat(r0.xy)).xy);
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.zw) * float2(2, 2) + float2(-1, -1));
	r2.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.x = asint(dot(asfloat(r2.xy), asfloat(r2.xy)));
	r0.x = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(max(asfloat(r0.x), 0));
	r2.z = asint(sqrt(asfloat(r0.x)));
	r3 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r0.x = asint(dot(asfloat(r3), specMapExpMask));
	r0.x = asint(asfloat(r0.x) * specularFactor);
	r0.y = asint(dot(asfloat(r3.xyz), specMapIntMask));
	r0.x = asint(max(asfloat(r0.x), 1));
	r2.w = (0 < i.color.y) ? -1 : 0;
	r4.xy = i.texcoord6.xy * WetDarken.ww;
	r3.w = asint(PuddleMaskSampler_tex.Sample(PuddleMaskSampler, r4.xy).x);
	r4.xy = i.texcoord6.xy * float2(0.300000012, 0.300000012);
	r4 = WaterRainRippleNormalSampler_tex.Sample(WaterRainRippleNormalSampler, r4.xy).xyz;
	if (r2.w != 0) {
		r2.w = asint(asfloat(r3.w) + gWaterGlobals.y);
		r2.w = asint(saturate(asfloat(r2.w) + -(i.color.y)));
		r3.w = (0 < asfloat(r2.w)) ? -1 : 0;
		if (r3.w != 0) {
			r1.xyz = r1.xyz * WetDarken.xyz;
			r3.w = asint(-(asfloat(r0.y)) + gWaterGlobals.z);
			r0.y = asint(asfloat(r2.w) * asfloat(r3.w) + asfloat(r0.y));
			r3.w = asint(-(asfloat(r0.x)) + gWaterGlobals.w);
			r0.x = asint(asfloat(r2.w) * asfloat(r3.w) + asfloat(r0.x));
			r4 = r4.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
			r4 = r4.xyz * i.texcoord1.zzz + -(asfloat(r2.xyz));
			r4 = asfloat(r2.www) * r4.xyz + asfloat(r2.xyz);
			r4 = r4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
			r2.w = asint(dot(r4.xyz, r4.xyz));
			r2.w = asint(rsqrt(asfloat(r2.w)));
			r2.xyz = asint(asfloat(r2.www) * r4.xyz);
		} else {
			r2.w = asint(saturate(gWaterGlobals.y));
			r4 = r1.xyz * WetDarken.xyz + -(r1.xyz);
			r1.xyz = asfloat(r2.www) * r4.xyz + r1.xyz;
		}
	}
	r1.w = r1.w * i.color.w;
	r1.w = r1.w * globalScalars.x;
	r2.w = (g_AlphaRef >= r1.w) ? -1 : 0;
	if (r2.w != 0) discard;
	r4 = asfloat(r2.xxx) * i.texcoord4.xyz;
	r2.xzw = asint(asfloat(r2.zzz) * i.texcoord1.xyz + r4.xyz);
	r2.xyz = asint(asfloat(r2.yyy) * i.texcoord5.xyz + asfloat(r2.xzw));
	r2.xyz = asint(asfloat(r2.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r2.xyz = asint(asfloat(r2.www) * asfloat(r2.xyz));
	r4 = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.w = asint(dot(r4.xyz, r4.xyz));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r4 = asfloat(r2.www) * r4.xyz;
	r2.w = asint(dot(-(r4.xyz), asfloat(r2.xyz)));
	r2.w = asint(asfloat(r2.w) + asfloat(r2.w));
	r5 = asfloat(r2.xyz) * -(asfloat(r2.www)) + -(r4.xyz);
	r5 = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.w = asint(dot(r5.xyz, r5.xyz));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r5.xy = r5.xz * asfloat(r2.ww) + float2(1, 1);
	r5.xy = r5.xy * float2(-0.5, -0.5);
	r5 = EnvironmentSampler_tex.Sample(EnvironmentSampler, r5.xy).xyz;
	r2.w = asint(saturate(dot(r4.xyz, asfloat(r2.xyz))));
	r3.w = asint(-(fresnelRolloff) + 1);
	r2.w = asint(-(asfloat(r2.w)) + 1.00001001);
	r4.x = asfloat(r2.w) * asfloat(r2.w);
	r4.x = r4.x * r4.x;
	r2.w = asint(asfloat(r2.w) * r4.x);
	r2.w = asint(fresnelRolloff * asfloat(r2.w) + asfloat(r3.w));
	r4 = asfloat(r2.www) * r5.xyz;
	r4 = r4.xyz * reflectivePower;
	r2.w = asint(dot(asfloat(r3.xyz), specMapReflectMask.xyz));
	r3.xyz = asint(asfloat(r2.www) * r4.xyz);
	r3.xyz = asint(asfloat(r3.xyz) * globalScalars.www);
	r0.z = asint(dot(asfloat(r0.zw), asfloat(r0.zw)));
	r0.z = (asfloat(r0.z) >= 0.00200000009) ? -1 : 0;
	r0.z = r0.z & 1065353216;
	r0.w = asint(asfloat(r0.z) * i.color.x);
	o.sv_target2.x = asfloat(r0.z) * asfloat(r0.y);
	r0.y = asint(saturate(i.color.x * asfloat(r0.z) + -1));
	r0.y = asint(asfloat(r0.y) * globalScalars2.z);
	o.sv_target.xyz = r1.xyz * asfloat(r0.zzz) + asfloat(r0.yyy);
	o.sv_target1.xyz = asfloat(r2.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = asint(saturate(asfloat(r0.x) * 0.00510204071));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	o.sv_target2.z = asfloat(r0.w) * gAmbientOcclusionEffect.w;
	r0.xyz = asint(saturate(asfloat(r3.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.sv_target3.xyz = sqrt(asfloat(r0.xyz));
	o.sv_target.w = r1.w;
	o.sv_target1.w = r1.w;
	o.sv_target2.w = r1.w;
	o.sv_target3.w = r1.w;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
