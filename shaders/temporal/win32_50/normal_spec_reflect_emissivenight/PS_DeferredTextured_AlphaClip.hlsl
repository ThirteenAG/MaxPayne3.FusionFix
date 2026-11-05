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
	float emissiveMultiplier : packoffset(c0);
	float emissiveReflectMultiplier : packoffset(c0.y);
	float specularFactor : packoffset(c0.z);
	float3 specMapIntMask : packoffset(c1);
	float4 specMapExpMask : packoffset(c2);
	float bumpiness : packoffset(c3);
	float reflectivePower : packoffset(c3.y);
	float fresnelRolloff : packoffset(c3.z);
	float3 specMapReflectMask : packoffset(c4);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState SpecSampler : register(s2);
SamplerState EnvironmentSampler : register(s3);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D SpecSampler_tex : register(t2);
Texture2D EnvironmentSampler_tex : register(t3);

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
	float3 r4;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0 = r0 * colorize;
	r0.w = r0.w * i.color.w;
	r0.w = r0.w * globalScalars.x;
	r1.x = (g_AlphaRef >= r0.w) ? -1 : 0;
	if (r1.x != 0) discard;
	r1.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r1.w = asint(-(asfloat(r1.z)) + 1);
	r1.w = (asfloat(r1.w) < asfloat(r1.x)) ? -1 : 0;
	r1.w = r1.w & 1065353216;
	r2.xy = -(asfloat(r1.zy)) + asfloat(r1.xy);
	r1.xy = asint(asfloat(r1.ww) * r2.xy + asfloat(r1.zy));
	r1.xy = asint(asfloat(r1.xy) * float2(2, 2) + float2(-1, -1));
	r1.xy = asint(asfloat(r1.xy) * bumpiness);
	r1.z = asint(dot(asfloat(r1.xy), asfloat(r1.xy)));
	r1.z = asint(-(asfloat(r1.z)) + 1);
	r1.z = asint(max(asfloat(r1.z), 0));
	r1.z = asint(sqrt(asfloat(r1.z)));
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r1.w = asint(dot(r2, specMapExpMask));
	r1.w = asint(asfloat(r1.w) * specularFactor);
	o.sv_target2.x = dot(r2.xyz, specMapIntMask.xyz);
	r1.w = asint(max(asfloat(r1.w), 1));
	r3 = asfloat(r1.xxx) * i.texcoord4.xyz;
	r3 = asfloat(r1.zzz) * i.texcoord1.xyz + r3.xyz;
	r1.xyz = asint(asfloat(r1.yyy) * i.texcoord5.xyz + r3.xyz);
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.w = dot(asfloat(r1.xyz), asfloat(r1.xyz));
	r2.w = rsqrt(r2.w);
	r1.xyz = asint(asfloat(r1.xyz) * r2.www);
	r3 = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.w = dot(r3.xyz, r3.xyz);
	r2.w = rsqrt(r2.w);
	r3 = r2.www * r3.xyz;
	r2.w = dot(-(r3.xyz), asfloat(r1.xyz));
	r2.w = r2.w + r2.w;
	r4 = asfloat(r1.xyz) * -(r2.www) + -(r3.xyz);
	r4 = r4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.w = dot(r4.xyz, r4.xyz);
	r2.w = rsqrt(r2.w);
	r4.xy = r4.xz * r2.ww + float2(1, 1);
	r4.xy = r4.xy * float2(-0.5, -0.5);
	r4 = EnvironmentSampler_tex.Sample(EnvironmentSampler, r4.xy).xyz;
	r2.w = saturate(dot(r3.xyz, asfloat(r1.xyz)));
	r3.x = -(fresnelRolloff) + 1;
	r2.w = -(r2.w) + 1.00001001;
	r3.y = r2.w * r2.w;
	r3.y = r3.y * r3.y;
	r2.w = r2.w * r3.y;
	r2.w = fresnelRolloff * r2.w + r3.x;
	r3 = r2.www * r4.xyz;
	r3 = r3.xyz * reflectivePower;
	r2.x = dot(r2.xyz, specMapReflectMask.xyz);
	r2.xyz = r2.xxx * r3.xyz;
	r2.xyz = r2.xyz * globalScalars.www;
	r2.w = saturate(globalScalars.z + -1);
	o.sv_target.xyz = r2.www * globalScalars2.zzz + r0.xyz;
	o.sv_target1.xyz = asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = asfloat(r1.w) * 0.00510204071;
	r0.x = min(r0.x, 1);
	r0.x = sqrt(r0.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.z = globalScalars.z * gAmbientOcclusionEffect.w;
	r0.xyz = saturate(r2.xyz * float3(0.0625, 0.0625, 0.0625));
	o.sv_target3.xyz = sqrt(r0.xyz);
	o.sv_target.w = r0.w;
	o.sv_target1.w = r0.w;
	o.sv_target2.w = r0.w;
	o.sv_target3.w = r0.w;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
