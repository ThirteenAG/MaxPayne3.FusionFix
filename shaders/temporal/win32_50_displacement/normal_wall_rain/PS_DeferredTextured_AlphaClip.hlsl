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

cbuffer CacheMegaVariables : register(b4)
{
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
};

cbuffer WallWet : register(b7)
{
	float4 WetDarken : packoffset(c0);
	float4 RainNormalControls : packoffset(c1);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState RainNormalSampler : register(s2);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpTex : register(t1);
Texture2D RainNormalSampler_tex : register(t2);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
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
	int4 r1;
	int4 r2;
	int4 r3;
	int3 r4;
	r0.xyz = asint(BumpTex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = asint(-(asfloat(r0.zy)) + asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.ww) * asfloat(r1.xy) + asfloat(r0.zy));
	r1 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.w = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.w = asint(-(asfloat(r0.w)) + 1);
	r0.w = asint(max(asfloat(r0.w), 0));
	r0.z = asint(sqrt(asfloat(r0.w)));
	r0.w = asint(max(specularFactor, 1));
	r2.x = (0 < i.color.y) ? -1 : 0;
	r2.yz = asint(globalScalars2.yy * RainNormalControls.zw);
	r2.yz = asint(i.texcoord.xy * RainNormalControls.xy + asfloat(r2.yz));
	r2.yzw = asint(RainNormalSampler_tex.Sample(RainNormalSampler, asfloat(r2.yz)).xyw);
	if (r2.x != 0) {
		r2.x = asint(saturate(-(i.color.y) + gWaterGlobals.y));
		r3.x = (0 < asfloat(r2.x)) ? -1 : 0;
		if (r3.x != 0) {
			r1.xyz = asint(asfloat(r1.xyz) * WetDarken.xyz);
			r3.x = asint(gWaterGlobals.z + -(specularColorFactor));
			r3.x = asint(asfloat(r2.x) * asfloat(r3.x) + specularColorFactor);
			r4.x = asint(-(asfloat(r0.w)) + gWaterGlobals.w);
			r0.w = asint(asfloat(r2.x) * asfloat(r4.x) + asfloat(r0.w));
			r4.x = asint(-(asfloat(r2.w)) + 1);
			r4.x = (asfloat(r4.x) < asfloat(r2.y)) ? -1 : 0;
			r4.x = r4.x & 1065353216;
			r4.yz = asint(-(asfloat(r2.wz)) + asfloat(r2.yz));
			r2.yz = asint(asfloat(r4.xx) * asfloat(r4.yz) + asfloat(r2.wz));
			r2.yz = asint(asfloat(r2.yz) * float2(2, 2) + float2(-1, -1));
			r4.xy = asint(asfloat(r2.yz) * WetDarken.ww);
			r2.y = asint(dot(asfloat(r4.xy), asfloat(r4.xy)));
			r2.y = asint(-(asfloat(r2.y)) + 1);
			r2.y = asint(max(asfloat(r2.y), 0));
			r4.z = asint(sqrt(asfloat(r2.y)));
			r2.yzw = asint(-(asfloat(r0.xyz)) + asfloat(r4.xyz));
			r2.xyz = asint(asfloat(r2.xxx) * asfloat(r2.yzw) + asfloat(r0.xyz));
			r2.xyz = asint(asfloat(r2.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
			r2.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
			r2.w = asint(rsqrt(asfloat(r2.w)));
			r0.xyz = asint(asfloat(r2.www) * asfloat(r2.xyz));
		} else {
			r2.x = asint(saturate(gWaterGlobals.y));
			r2.yzw = asint(asfloat(r1.xyz) * WetDarken.xyz + -(asfloat(r1.xyz)));
			r1.xyz = asint(asfloat(r2.xxx) * asfloat(r2.yzw) + asfloat(r1.xyz));
			r3.x = asint(specularColorFactor);
		}
	} else {
		r3.x = asint(specularColorFactor);
	}
	r1.w = asint(asfloat(r1.w) * i.color.w);
	r3.w = asint(asfloat(r1.w) * globalScalars.x);
	r1.w = (g_AlphaRef >= asfloat(r3.w)) ? -1 : 0;
	if (r1.w != 0) discard;
	r2.xyz = asint(asfloat(r0.xxx) * i.texcoord4.xyz);
	r2.xyz = asint(asfloat(r0.zzz) * i.texcoord1.xyz + asfloat(r2.xyz));
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r2.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r1.www));
	r1.w = asint(saturate(i.color.x + -1));
	o.sv_target.xyz = asfloat(r1.www) * globalScalars2.zzz + asfloat(r1.xyz);
	o.sv_target1.xyz = asfloat(r0.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = asint(saturate(asfloat(r0.w) * 0.00510204071));
	r0.x = asint(sqrt(asfloat(r0.x)));
	r3.y = asint(sqrt(asfloat(r0.x)));
	r3.z = asint(i.color.x * gAmbientOcclusionEffect.w);
	o.sv_target.w = asfloat(r3.w);
	o.sv_target1.w = asfloat(r3.w);
	o.sv_target2 = asfloat(r3);
	o.sv_target3.xyz = float3(0, 0, 0);
	o.sv_target3.w = asfloat(r3.w);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
