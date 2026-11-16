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
	float zShiftScale : packoffset(c0);
	float parallaxScaleBias : packoffset(c0.y);
};

cbuffer CacheMegaVariables : register(b7)
{
	float specularFactor : packoffset(c0);
	float3 specMapIntMask : packoffset(c0.y);
	float4 specMapExpMask : packoffset(c1);
	float bumpiness : packoffset(c2);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s2);
SamplerState SpecSampler : register(s3);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t2);
Texture2D SpecSampler_tex : register(t3);

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

	float4 r0;
	float4 r1;
	int4 r2;
	int4 r3;
	float2 r4;
	float4 r5;
	r0 = BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy);
	r1.xyz = i.texcoord7.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.z = dot(r1.xyz, r1.xyz);
	r1.z = rsqrt(r1.z);
	r1.xy = r1.zz * r1.xy;
	r1.xy = -(r1.xy) * parallaxScaleBias;
	r2.xyz = asint(r0.xyz);
	r1.zw = i.texcoord.xy;
	r2.w = -1082130432;
	r3.x = asint(-(r0.w));
	r3.y = 0;
	while (true) {
		r3.z = (r3.y >= 2) ? -1 : 0;
		if (r3.z != 0) break;
		r3.z = (asfloat(r2.w) < asfloat(r3.x)) ? -1 : 0;
		r4 = r1.xy * float2(0.5, 0.5) + r1.zw;
		r5 = BumpSampler_tex.Sample(BumpSampler, r4.xy);
		if (r3.z != 0) {
			r2.w = asint(asfloat(r2.w) + 0.5);
			r2.xyz = asint(r5.xyz);
			r1.zw = r4.xy;
			r3.x = asint(-(r5.w));
		}
		r3.y = r3.y + 1;
	}
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, r1.zw);
	r1.xy = asfloat(r2.xy) * float2(2, 2) + float2(-1, -1);
	r1.xy = r1.xy * bumpiness;
	r1.z = dot(r1.xy, r1.xy);
	r1.z = -(r1.z) + 1;
	r1.z = max(r1.z, 0);
	r1.z = sqrt(r1.z);
	r3 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r1.w = dot(asfloat(r3), specMapExpMask);
	r1.w = r1.w * specularFactor;
	r2.w = asint(dot(asfloat(r3.xyz), specMapIntMask));
	r1.w = max(r1.w, 1);
	r3.xyz = asint(r1.xxx * i.texcoord4.xyz);
	r3.xyz = asint(r1.zzz * i.texcoord1.xyz + asfloat(r3.xyz));
	r1.xyz = r1.yyy * i.texcoord5.xyz + asfloat(r3.xyz);
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r3.x = asint(dot(r1.xyz, r1.xyz));
	r3.x = asint(rsqrt(asfloat(r3.x)));
	r1.xyz = r1.xyz * asfloat(r3.xxx);
	r2.x = asint(dot(asfloat(r2.xy), asfloat(r2.xy)));
	r2.x = (asfloat(r2.x) >= 0.00200000009) ? -1 : 0;
	r2.x = r2.x & 1065353216;
	r2.y = asint(asfloat(r2.x) * i.color.x);
	o.sv_target2.x = asfloat(r2.x) * asfloat(r2.w);
	r0.w = r0.w * i.color.w;
	r2.w = asint(saturate(i.color.x * asfloat(r2.x) + -1));
	r2.w = asint(asfloat(r2.w) * globalScalars2.z);
	o.sv_target.xyz = r0.xyz * asfloat(r2.xxx) + asfloat(r2.www);
	o.sv_target1.xyz = r1.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = r1.w * 0.00510204071;
	r0.x = min(r0.x, 1);
	r0.x = sqrt(r0.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.z = asfloat(r2.y) * gAmbientOcclusionEffect.w;
	r0.x = r0.w * globalScalars.x;
	r0.y = r0.w * asfloat(r2.z);
	o.sv_target1.w = r0.y * globalScalars.x;
	o.sv_target.w = r0.x;
	o.sv_target2.w = r0.x;
	o.sv_target3.xyz = float3(0, 0, 0);
	o.sv_target3.w = r0.x;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
