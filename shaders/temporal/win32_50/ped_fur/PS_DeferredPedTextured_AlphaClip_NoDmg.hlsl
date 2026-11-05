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
	float bumpiness : packoffset(c0.y);
	float displacementScale : packoffset(c0.z);
	float specularFactor : packoffset(c0.w);
	float3 specMapIntMask : packoffset(c1);
	float4 specMapExpMask : packoffset(c2);
	float4 matMaterialColorScale : packoffset(c3);
};

cbuffer Details : register(b7)
{
	float4 detailSettings : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState SpecSampler : register(s2);
SamplerState VolumeSampler : register(s3);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D SpecSampler_tex : register(t2);
Texture3D VolumeSampler_tex : register(t3);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord3 : TEXCOORD3;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
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
	float3 r3;
	float2 r4;
	float3 r5;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.w = r0.w * i.texcoord2.w;
	r0.w = saturate(r0.w * 1.70000005);
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
	r2.x = dot(r2.xyz, specMapIntMask.xyz);
	r1.w = asint(max(asfloat(r1.w), 1));
	r3 = asfloat(r1.xxx) * i.texcoord4.xyz;
	r3 = asfloat(r1.zzz) * i.texcoord1.xyz + r3.xyz;
	r1.xyz = asint(asfloat(r1.yyy) * i.texcoord5.xyz + r3.xyz);
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.y = dot(asfloat(r1.xyz), asfloat(r1.xyz));
	r2.y = rsqrt(r2.y);
	r3 = asfloat(r1.xyz) * r2.yyy;
	r0.xyz = r0.xyz * i.texcoord3.xxx;
	r0.xyz = r0.xyz * matMaterialColorScale.xxx;
	r2.x = r2.x * matMaterialColorScale.w;
	r4.y = asfloat(r1.w) * matMaterialColorScale.w;
	r5 = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r5 = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r5.xyz, r5.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r5 = asfloat(r1.www) * r5.xyz;
	r1.xyz = asint(asfloat(r1.xyz) * r2.yyy + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r1.x = asint(dot(r5.xyz, asfloat(r1.xyz)));
	r1.x = asint(asfloat(r1.x) * -1.5);
	r1.x = asint(max(asfloat(r1.x), 0));
	r1.x = asint(-(asfloat(r1.x)) + 1);
	r1.x = asint(max(asfloat(r1.x), 0));
	r1.x = asint(asfloat(r1.x) * i.texcoord2.y);
	r1.y = asint(saturate(r2.x * 5));
	r1.x = asint(asfloat(r1.y) * asfloat(r1.x));
	r1.y = asint(saturate(-(r4.y) * 0.00999999978 + 1));
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
	r0.xyz = r0.xyz * i.texcoord2.www + r3.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.y = asint(dot(r0.xyz, r0.xyz));
	r1.y = asint(rsqrt(asfloat(r1.y)));
	r0.xyz = r0.xyz * asfloat(r1.yyy);
	o.sv_target2.x = saturate(asfloat(r1.w) * asfloat(r1.x));
	r1.xyz = asint(-(i.texcoord7.xyz) + gViewInverse[3].xyz);
	r2.xyz = i.texcoord4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r2.xyz, r2.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asfloat(r1.www) * r2.xyz;
	r3 = i.texcoord5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r3.xyz, r3.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r3 = asfloat(r1.www) * r3.xyz;
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r1.w = asint(dot(asfloat(r1.xyz), r2.xyz));
	r1.x = asint(dot(asfloat(r1.xyz), r3.xyz));
	r2.xy = asfloat(r1.wx) * asfloat(r1.wx);
	r4.x = 1;
	r1.x = asint(dot(r2.xy, r4.xy));
	r1.x = asint(max(asfloat(r1.x), 1));
	r1.y = asint(saturate(gAmbientOcclusionEffect.z));
	r1.y = asint(saturate(asfloat(r1.y) + i.texcoord2.x));
	o.sv_target1.xyz = r0.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = asfloat(r1.x) * 0.00510204071;
	r0.x = min(r0.x, 1);
	r0.x = sqrt(r0.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.z = asfloat(r1.y) * gAmbientOcclusionEffect.w;
	o.sv_target.w = r0.w;
	o.sv_target1.w = r0.w;
	o.sv_target2.w = r0.w;
	o.sv_target3.xyz = float3(0, 0, 0);
	o.sv_target3.w = r0.w;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
