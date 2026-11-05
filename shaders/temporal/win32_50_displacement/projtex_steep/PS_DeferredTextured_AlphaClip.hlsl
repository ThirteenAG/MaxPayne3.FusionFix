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
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s2);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpTex : register(t2);

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
	int4 r1;
	float4 r2;
	float3 r3;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.w = r0.w * i.color.w;
	r1.x = asint(r0.w * globalScalars.x);
	r1.y = (g_AlphaRef >= asfloat(r1.x)) ? -1 : 0;
	if (r1.y != 0) discard;
	r1.yzw = asint(BumpTex.Sample(BumpSampler, i.texcoord.xy).xyz);
	r2.xy = asfloat(r1.yz) * float2(2, 2) + float2(-1, -1);
	r2.xy = r2.xy * bumpiness;
	r2.z = dot(r2.xy, r2.xy);
	r2.z = -(r2.z) + 1;
	r2.z = max(r2.z, 0);
	r2.z = sqrt(r2.z);
	r2.w = max(specularFactor, 1);
	r3 = r2.xxx * i.texcoord4.xyz;
	r3 = r2.zzz * i.texcoord1.xyz + r3.xyz;
	r2.xyz = r2.yyy * i.texcoord5.xyz + r3.xyz;
	r2.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r3.x = dot(r2.xyz, r2.xyz);
	r3.x = rsqrt(r3.x);
	r2.xyz = r2.xyz * r3.xxx;
	r1.y = asint(dot(asfloat(r1.yz), asfloat(r1.yz)));
	r1.y = (asfloat(r1.y) >= 0.00200000009) ? -1 : 0;
	r1.y = r1.y & 1065353216;
	r1.z = asint(asfloat(r1.y) * i.color.x);
	o.sv_target2.x = asfloat(r1.y) * specularColorFactor;
	r3.x = saturate(i.color.x * asfloat(r1.y) + -1);
	r3.x = r3.x * globalScalars2.z;
	o.sv_target.xyz = r0.xyz * asfloat(r1.yyy) + r3.xxx;
	o.sv_target1.xyz = r2.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = r2.w * 0.00510204071;
	r0.x = min(r0.x, 1);
	r0.x = sqrt(r0.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.z = asfloat(r1.z) * gAmbientOcclusionEffect.w;
	r0.x = r0.w * asfloat(r1.w);
	o.sv_target1.w = r0.x * globalScalars.x;
	o.sv_target.w = asfloat(r1.x);
	o.sv_target2.w = asfloat(r1.x);
	o.sv_target3.xyz = float3(0, 0, 0);
	o.sv_target3.w = asfloat(r1.x);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
