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

cbuffer CacheMegaVariables : register(b4)
{
	float specularFactor : packoffset(c0);
	float3 specMapIntMask : packoffset(c0.y);
	float4 specMapExpMask : packoffset(c1);
	float bumpiness : packoffset(c2);
	float reflectivePower : packoffset(c2.y);
	float fresnelRolloff : packoffset(c2.z);
	float3 specMapReflectMask : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState SpecSampler : register(s2);
SamplerState EnvironmentSampler : register(s3);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpTex : register(t1);
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
	float3 r2;
	r0.x = saturate(i.color.x + -1);
	r1 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	o.sv_target.xyz = r0.xxx * globalScalars2.zzz + asfloat(r1.xyz);
	r0.x = asfloat(r1.w) * i.color.w;
	r0.x = r0.x * globalScalars.x;
	o.sv_target.w = r0.x;
	o.sv_target1.w = r0.x;
	r0.yzw = BumpTex.Sample(BumpSampler, i.texcoord.xy).xyw;
	r1.x = asint(-(r0.w) + 1);
	r1.x = (asfloat(r1.x) < r0.y) ? -1 : 0;
	r1.x = r1.x & 1065353216;
	r1.yz = asint(-(r0.wz) + r0.yz);
	r0.yz = asfloat(r1.xx) * asfloat(r1.yz) + r0.wz;
	r0.yz = r0.yz * float2(2, 2) + float2(-1, -1);
	r0.yz = r0.yz * bumpiness;
	r0.w = dot(r0.yz, r0.yz);
	r0.w = -(r0.w) + 1;
	r0.w = max(r0.w, 0);
	r0.w = sqrt(r0.w);
	r1.xyz = asint(r0.yyy * i.texcoord4.xyz);
	r1.xyz = asint(r0.www * i.texcoord1.xyz + asfloat(r1.xyz));
	r0.yzw = r0.zzz * i.texcoord5.xyz + asfloat(r1.xyz);
	r0.yzw = r0.yzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = asint(dot(r0.yzw, r0.yzw));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.yzw = r0.yzw * asfloat(r1.xxx);
	o.sv_target1.xyz = r0.yzw * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target2.w = r0.x;
	o.sv_target3.w = r0.x;
	r1 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r0.x = dot(asfloat(r1), specMapExpMask);
	r0.x = r0.x * specularFactor;
	r0.x = max(r0.x, 1);
	r0.x = r0.x * 0.00510204071;
	r0.x = min(r0.x, 1);
	r0.x = sqrt(r0.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.z = i.color.x * gAmbientOcclusionEffect.w;
	o.sv_target2.x = dot(asfloat(r1.xyz), specMapIntMask);
	r0.x = dot(asfloat(r1.xyz), specMapReflectMask.xyz);
	r1.xyz = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r1.w = asint(dot(-(asfloat(r1.xyz)), r0.yzw));
	r1.w = asint(asfloat(r1.w) + asfloat(r1.w));
	r2 = r0.yzw * -(asfloat(r1.www)) + -(asfloat(r1.xyz));
	r0.y = saturate(dot(asfloat(r1.xyz), r0.yzw));
	r0.y = -(r0.y) + 1.00001001;
	r1.xyz = asint(r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.z = dot(asfloat(r1.xyz), asfloat(r1.xyz));
	r0.z = rsqrt(r0.z);
	r0.zw = asfloat(r1.xz) * r0.zz + float2(1, 1);
	r0.zw = r0.zw * float2(-0.5, -0.5);
	r1.xyz = asint(EnvironmentSampler_tex.Sample(EnvironmentSampler, r0.zw).xyz);
	r0.z = r0.y * r0.y;
	r0.z = r0.z * r0.z;
	r0.y = r0.z * r0.y;
	r0.z = -(fresnelRolloff) + 1;
	r0.y = fresnelRolloff * r0.y + r0.z;
	r0.yzw = r0.yyy * asfloat(r1.xyz);
	r0.yzw = r0.yzw * reflectivePower;
	r0.xyz = r0.xxx * r0.yzw;
	r0.xyz = r0.xyz * globalScalars.www;
	r0.xyz = saturate(r0.xyz * float3(0.0625, 0.0625, 0.0625));
	o.sv_target3.xyz = sqrt(r0.xyz);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
