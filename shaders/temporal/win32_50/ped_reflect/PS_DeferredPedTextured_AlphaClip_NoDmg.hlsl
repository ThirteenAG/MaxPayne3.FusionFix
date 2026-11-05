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

cbuffer AlphaTest : register(b11)
{
	float g_AlphaRef : packoffset(c0);
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

	float4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float3 r5;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.w = r0.w * i.texcoord2.w;
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
	r2.w = saturate(dot(r2.xyz, specMapIntMask.xyz));
	r1.w = asint(max(asfloat(r1.w), 1));
	r3.xyz = asfloat(r1.xxx) * i.texcoord4.xyz;
	r3.xyz = asfloat(r1.zzz) * i.texcoord1.xyz + r3.xyz;
	r1.xyz = asint(asfloat(r1.yyy) * i.texcoord5.xyz + r3.xyz);
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r3.x = dot(asfloat(r1.xyz), asfloat(r1.xyz));
	r3.x = rsqrt(r3.x);
	r3.yzw = asfloat(r1.xyz) * r3.xxx;
	r4.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r4.w = dot(r4.xyz, r4.xyz);
	r4.w = rsqrt(r4.w);
	r4.xyz = r4.www * r4.xyz;
	r4.w = dot(-(r4.xyz), r3.yzw);
	r4.w = r4.w + r4.w;
	r5 = r3.yzw * -(r4.www) + -(r4.xyz);
	r5 = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r4.w = dot(r5.xyz, r5.xyz);
	r4.w = rsqrt(r4.w);
	r5 = r4.www * r5.zxy;
	r5.x = saturate(r5.x);
	r4.w = r5.x + 1;
	r4.w = r4.w + r4.w;
	r5.xy = r5.yz / r4.ww;
	r5.xy = r5.xy + float2(0.5, 0.5);
	r5.xy = -(r5.xy) + float2(1, 1);
	r5 = EnvironmentSampler_tex.SampleLevel(EnvironmentSampler, r5.xy, 0).xyz;
	r5 = r5.xyz * r5.xyz;
	r5 = r5.xyz * float3(16, 16, 16);
	r4.x = saturate(dot(r4.xyz, r3.yzw));
	r4.y = -(fresnelRolloff) + 1;
	r4.x = -(r4.x) + 1.00001001;
	r4.z = r4.x * r4.x;
	r4.z = r4.z * r4.z;
	r4.x = r4.z * r4.x;
	r4.x = fresnelRolloff * r4.x + r4.y;
	r4.xyz = r4.xxx * r5.xyz;
	r4.w = EnvironmentSampler_tex.Sample(EnvironmentSampler, i.texcoord.xy).w;
	r4.xyz = r4.www * r4.xyz;
	r4.xyz = r4.xyz * reflectivePower;
	r2.x = dot(r2.xyz, specMapReflectMask.xyz);
	r4.xyz = r2.xxx * r4.xyz;
	r4.xyz = r4.xyz * ColorCorrectTopAndPedReflectScale.www;
	r0.xyz = r0.xyz * matMaterialColorScale.xxx;
	r4.xyz = r4.xyz * matMaterialColorScale.zzz;
	r2.x = r2.w * matMaterialColorScale.w;
	r1.w = asint(asfloat(r1.w) * matMaterialColorScale.w);
	r5 = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r5 = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.y = dot(r5.xyz, r5.xyz);
	r2.y = rsqrt(r2.y);
	r5 = r2.yyy * r5.xyz;
	r1.xyz = asint(asfloat(r1.xyz) * r3.xxx + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.y = dot(asfloat(r1.xyz), asfloat(r1.xyz));
	r2.y = rsqrt(r2.y);
	r1.xyz = asint(asfloat(r1.xyz) * r2.yyy);
	r1.x = asint(dot(r5.xyz, asfloat(r1.xyz)));
	r1.x = asint(asfloat(r1.x) * -1.5);
	r1.x = asint(max(asfloat(r1.x), 0));
	r1.x = asint(-(asfloat(r1.x)) + 1);
	r1.x = asint(max(asfloat(r1.x), 0));
	r1.x = asint(asfloat(r1.x) * i.texcoord2.y);
	r1.y = asint(saturate(r2.x * 5));
	r1.x = asint(asfloat(r1.y) * asfloat(r1.x));
	r3.x = asfloat(r1.w) * 0.00510204071;
	r1.y = asint(saturate(-(asfloat(r1.w)) * 0.00999999978 + 1));
	r1.x = asint(asfloat(r1.y) * asfloat(r1.x) + r2.x);
	r1.y = asint(r2.z * 16);
	r1.y = asint(trunc(asfloat(r1.y)));
	r2.xy = i.texcoord.xy * detailSettings.zw;
	r1.y = asint(asfloat(r1.y) + 0.5);
	r2.z = asfloat(r1.y) * 0.0625;
	r1.yzw = asint(VolumeSampler_tex.Sample(VolumeSampler, r2.xyz).xyz);
	r1.yzw = asint(asfloat(r1.zwy) * float3(2, 2, 2) + float3(-1, -1, -1));
	r2.x = i.texcoord2.w * detailSettings.x;
	r1.w = asint(asfloat(r1.w) * r2.x + 1);
	o.sv_target.xyz = r0.xyz * asfloat(r1.www);
	r0.xyz = asfloat(r1.zzz) * i.texcoord5.xyz;
	r0.xyz = i.texcoord4.xyz * asfloat(r1.yyy) + r0.xyz;
	r0.xyz = r0.xyz * detailSettings.yyy;
	r0.xyz = r0.xyz * i.texcoord2.www + r3.yzw;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.y = asint(dot(r0.xyz, r0.xyz));
	r1.y = asint(rsqrt(asfloat(r1.y)));
	r0.xyz = r0.xyz * asfloat(r1.yyy);
	o.sv_target2.x = saturate(asfloat(r1.w) * asfloat(r1.x));
	r1.x = asint(saturate(gAmbientOcclusionEffect.z));
	r1.x = asint(saturate(asfloat(r1.x) + i.texcoord2.x));
	o.sv_target1.xyz = r0.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r3.x = saturate(r3.x);
	r0.x = sqrt(r3.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.z = asfloat(r1.x) * gAmbientOcclusionEffect.w;
	r0.xyz = saturate(r4.xyz * float3(0.0625, 0.0625, 0.0625));
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
