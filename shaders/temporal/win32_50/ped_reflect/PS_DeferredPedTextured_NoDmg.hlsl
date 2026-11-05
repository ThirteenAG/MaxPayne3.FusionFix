cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

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

cbuffer CachePedParam : register(b4)
{
	float ArmourStrength : packoffset(c0);
	float reflectivePower : packoffset(c0.y);
	float3 specMapReflectMask : packoffset(c1);
	float fresnelRolloff : packoffset(c1.w);
	float bumpiness : packoffset(c2);
	float displacementScale : packoffset(c2.y);
	float specularFactor : packoffset(c2.z);
	float3 specMapIntMask : packoffset(c3);
	float4 specMapExpMask : packoffset(c4);
	float4 matMaterialColorScale : packoffset(c5);
};

cbuffer Details : register(b7)
{
	float4 detailSettings : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState EnvironmentSampler : register(s1);
SamplerState BumpSampler : register(s5);
SamplerState SpecSampler : register(s6);
SamplerState VolumeSampler : register(s7);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D EnvironmentSampler_tex : register(t1);
Texture2D BumpSampler_tex : register(t5);
Texture2D SpecSampler_tex : register(t6);
Texture3D VolumeSampler_tex : register(t7);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
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

	int4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	r0.x = asint(i.texcoord2.w * detailSettings.x);
	r1.xy = i.texcoord.xy * detailSettings.zw;
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.y = asint(r2.z * 16);
	r0.y = asint(trunc(asfloat(r0.y)));
	r0.y = asint(asfloat(r0.y) + 0.5);
	r1.z = asfloat(r0.y) * 0.0625;
	r0.yzw = asint(VolumeSampler_tex.Sample(VolumeSampler, r1.xyz).xyz);
	r0.yzw = asint(asfloat(r0.zwy) * float3(2, 2, 2) + float3(-1, -1, -1));
	r0.x = asint(asfloat(r0.w) * asfloat(r0.x) + 1);
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r1.xyz = r1.xyz * matMaterialColorScale.xxx;
	r0.w = asint(r1.w * i.texcoord2.w);
	r0.w = asint(asfloat(r0.w) * globalScalars.x);
	o.sv_target.xyz = asfloat(r0.xxx) * r1.xyz;
	o.sv_target.w = asfloat(r0.w);
	o.sv_target1.w = asfloat(r0.w);
	r1.xyz = asfloat(r0.zzz) * i.texcoord5.xyz;
	r1.xyz = i.texcoord4.xyz * asfloat(r0.yyy) + r1.xyz;
	r1.xyz = r1.xyz * detailSettings.yyy;
	r3.xyz = BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw;
	r0.y = asint(-(r3.z) + 1);
	r0.y = (asfloat(r0.y) < r3.x) ? -1 : 0;
	r0.y = r0.y & 1065353216;
	r3.xw = -(r3.zy) + r3.xy;
	r0.yz = asint(asfloat(r0.yy) * r3.xw + r3.zy);
	r0.yz = asint(asfloat(r0.yz) * float2(2, 2) + float2(-1, -1));
	r0.yz = asint(asfloat(r0.yz) * bumpiness);
	r1.w = dot(asfloat(r0.yz), asfloat(r0.yz));
	r1.w = -(r1.w) + 1;
	r1.w = max(r1.w, 0);
	r1.w = sqrt(r1.w);
	r3.xyz = asfloat(r0.yyy) * i.texcoord4.xyz;
	r3.xyz = r1.www * i.texcoord1.xyz + r3.xyz;
	r3.xyz = asfloat(r0.zzz) * i.texcoord5.xyz + r3.xyz;
	r3.xyz = r3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.y = asint(dot(r3.xyz, r3.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r4 = asfloat(r0.yyy) * r3.xyz;
	r3.xyz = r3.xyz * asfloat(r0.yyy) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.xyz = r1.xyz * i.texcoord2.www + r4.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.y = asint(dot(r1.xyz, r1.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r1.xyz = asfloat(r0.yyy) * r1.xyz;
	o.sv_target1.xyz = r1.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.y = asint(dot(r3.xyz, r3.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r1.xyz = asfloat(r0.yyy) * r3.xyz;
	r3.xyz = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r3.xyz = r3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.y = asint(dot(r3.xyz, r3.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r3.xyz = asfloat(r0.yyy) * r3.xyz;
	r0.y = asint(dot(r3.xyz, r1.xyz));
	r0.y = asint(asfloat(r0.y) * -1.5);
	r0.y = asint(max(asfloat(r0.y), 0));
	r0.y = asint(-(asfloat(r0.y)) + 1);
	r0.y = asint(max(asfloat(r0.y), 0));
	r0.y = asint(asfloat(r0.y) * i.texcoord2.y);
	r0.z = asint(saturate(dot(r2.xyz, specMapIntMask.xyz)));
	r0.z = asint(asfloat(r0.z) * matMaterialColorScale.w);
	r1.x = saturate(asfloat(r0.z) * 5);
	r0.y = asint(asfloat(r0.y) * r1.x);
	r1.x = dot(r2, specMapExpMask);
	r1.y = dot(r2.xyz, specMapReflectMask.xyz);
	r1.x = r1.x * specularFactor;
	r1.x = max(r1.x, 1);
	r1.x = r1.x * matMaterialColorScale.w;
	r1.z = saturate(-(r1.x) * 0.00999999978 + 1);
	r1.x = r1.x * 0.00510204071;
	r1.x = saturate(r1.x);
	r1.x = sqrt(r1.x);
	o.sv_target2.y = sqrt(r1.x);
	r0.y = asint(r1.z * asfloat(r0.y) + asfloat(r0.z));
	o.sv_target2.x = saturate(asfloat(r0.x) * asfloat(r0.y));
	o.sv_target2.w = asfloat(r0.w);
	o.sv_target3.w = asfloat(r0.w);
	r0.x = asint(saturate(gAmbientOcclusionEffect.z));
	r0.x = asint(saturate(asfloat(r0.x) + i.texcoord2.x));
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	r0.xyz = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r0.w = asint(dot(-(asfloat(r0.xyz)), r4.xyz));
	r0.w = asint(asfloat(r0.w) + asfloat(r0.w));
	r1.xzw = r4.xyz * -(asfloat(r0.www)) + -(asfloat(r0.xyz));
	r0.x = asint(saturate(dot(asfloat(r0.xyz), r4.xyz)));
	r0.x = asint(-(asfloat(r0.x)) + 1.00001001);
	r0.yzw = asint(r1.xzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.x = dot(asfloat(r0.yzw), asfloat(r0.yzw));
	r1.x = rsqrt(r1.x);
	r0.yzw = asint(asfloat(r0.wyz) * r1.xxx);
	r0.y = asint(saturate(asfloat(r0.y)));
	r0.y = asint(asfloat(r0.y) + 1);
	r0.y = asint(asfloat(r0.y) + asfloat(r0.y));
	r0.yz = asint(asfloat(r0.zw) / asfloat(r0.yy));
	r0.yz = asint(asfloat(r0.yz) + float2(0.5, 0.5));
	r0.yz = asint(-(asfloat(r0.yz)) + float2(1, 1));
	r0.yzw = asint(EnvironmentSampler_tex.SampleLevel(EnvironmentSampler, asfloat(r0.yz), 0).xyz);
	r0.yzw = asint(asfloat(r0.yzw) * asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r0.yzw) * float3(16, 16, 16));
	r1.x = asfloat(r0.x) * asfloat(r0.x);
	r1.x = r1.x * r1.x;
	r0.x = asint(asfloat(r0.x) * r1.x);
	r1.x = -(fresnelRolloff) + 1;
	r0.x = asint(fresnelRolloff * asfloat(r0.x) + r1.x);
	r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
	r0.w = asint(EnvironmentSampler_tex.Sample(EnvironmentSampler, i.texcoord.xy).w);
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) * reflectivePower);
	r0.xyz = asint(r1.yyy * asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) * ColorCorrectTopAndPedReflectScale.www);
	r0.xyz = asint(asfloat(r0.xyz) * matMaterialColorScale.zzz);
	r0.xyz = asint(saturate(asfloat(r0.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.sv_target3.xyz = sqrt(asfloat(r0.xyz));

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
