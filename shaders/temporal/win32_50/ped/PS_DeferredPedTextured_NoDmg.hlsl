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
SamplerState BumpSampler : register(s4);
SamplerState SpecSampler : register(s5);
SamplerState VolumeSampler : register(s6);
SamplerState DynamicEnvironmentSampler : register(s13);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t4);
Texture2D SpecSampler_tex : register(t5);
Texture3D VolumeSampler_tex : register(t6);
Texture2D DynamicEnvironmentSampler_tex : register(t13);

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
	int4 r4;
	float4 r5;
	r0.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = -(asfloat(r0.zy)) + asfloat(r0.xy);
	r0.xy = asint(asfloat(r0.ww) * r1.xy + asfloat(r0.zy));
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(max(asfloat(r0.z), 0));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.w = asint(dot(r2, specMapExpMask));
	r0.w = asint(asfloat(r0.w) * specularFactor);
	r2.w = dot(r2.xyz, specMapIntMask.xyz);
	r0.w = asint(max(asfloat(r0.w), 1));
	r3.xyz = asfloat(r0.xxx) * i.texcoord4.xyz;
	r3.xyz = asfloat(r0.zzz) * i.texcoord1.xyz + r3.xyz;
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + r3.xyz);
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r3.x = dot(asfloat(r0.xyz), asfloat(r0.xyz));
	r3.x = rsqrt(r3.x);
	r3.yzw = asfloat(r0.xyz) * r3.xxx;
	r4.x = (0 < reflectivePower) ? -1 : 0;
	if (r4.x != 0) {
		r4.x = asint(asfloat(r0.w) * 0.015625);
		r4.x = asint(min(asfloat(r4.x), 1));
		r4.x = asint(-(asfloat(r4.x)) * 4 + 4);
		r4.yzw = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r5.x = dot(asfloat(r4.yzw), asfloat(r4.yzw));
		r5.x = rsqrt(r5.x);
		r4.yzw = asint(asfloat(r4.yzw) * r5.xxx);
		r5.x = dot(-(asfloat(r4.yzw)), r3.yzw);
		r5.x = r5.x + r5.x;
		r5.xyz = r3.yzw * -(r5.xxx) + -(asfloat(r4.yzw));
		r5.xyz = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r5.w = dot(r5.xyz, r5.xyz);
		r5.w = rsqrt(r5.w);
		r5.xyz = r5.www * r5.zxy;
		r5.x = saturate(r5.x);
		r5.x = r5.x + 1;
		r5.x = r5.x + r5.x;
		r5.xy = r5.yz / r5.xx;
		r5.xy = r5.xy + float2(0.5, 0.5);
		r5.xy = -(r5.xy) + float2(1, 1);
		r5.xyz = DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, r5.xy, asfloat(r4.x)).xyz;
		r5.xyz = r5.xyz * r5.xyz;
		r5.xyz = r5.xyz * float3(16, 16, 16);
		r4.x = asint(saturate(dot(asfloat(r4.yzw), r3.yzw)));
		r4.y = asint(-(fresnelRolloff) + 1);
		r4.x = asint(-(asfloat(r4.x)) + 1.00001001);
		r4.z = asint(asfloat(r4.x) * asfloat(r4.x));
		r4.z = asint(asfloat(r4.z) * asfloat(r4.z));
		r4.x = asint(asfloat(r4.z) * asfloat(r4.x));
		r4.x = asint(fresnelRolloff * asfloat(r4.x) + asfloat(r4.y));
		r4.xyz = asint(asfloat(r4.xxx) * r5.xyz);
	} else {
		r4.xyz = int3(0, 0, 0);
	}
	r4.xyz = asint(asfloat(r4.xyz) * reflectivePower);
	r2.x = dot(r2.xyz, specMapReflectMask.xyz);
	r4.xyz = asint(r2.xxx * asfloat(r4.xyz));
	r4.xyz = asint(asfloat(r4.xyz) * ColorCorrectTopAndPedReflectScale.www);
	r1.w = r1.w * i.texcoord2.w;
	r1.xyz = r1.xyz * matMaterialColorScale.xxx;
	r4.xyz = asint(asfloat(r4.xyz) * matMaterialColorScale.zzz);
	r2.x = r2.w * matMaterialColorScale.w;
	r0.w = asint(asfloat(r0.w) * matMaterialColorScale.w);
	r5.xyz = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r5.xyz = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.y = dot(r5.xyz, r5.xyz);
	r2.y = rsqrt(r2.y);
	r5.xyz = r2.yyy * r5.xyz;
	r0.xyz = asint(asfloat(r0.xyz) * r3.xxx + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.y = dot(asfloat(r0.xyz), asfloat(r0.xyz));
	r2.y = rsqrt(r2.y);
	r0.xyz = asint(asfloat(r0.xyz) * r2.yyy);
	r0.x = asint(dot(r5.xyz, asfloat(r0.xyz)));
	r0.x = asint(asfloat(r0.x) * -1.5);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(asfloat(r0.x) * i.texcoord2.y);
	r0.y = asint(saturate(r2.x * 5));
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x));
	r3.x = asfloat(r0.w) * 0.00510204071;
	r0.y = asint(saturate(-(asfloat(r0.w)) * 0.00999999978 + 1));
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x) + r2.x);
	r0.y = asint(r2.z * 16);
	r0.y = asint(trunc(asfloat(r0.y)));
	r2.xy = i.texcoord.xy * detailSettings.zw;
	r0.y = asint(asfloat(r0.y) + 0.5);
	r2.z = asfloat(r0.y) * 0.0625;
	r0.yzw = asint(VolumeSampler_tex.Sample(VolumeSampler, r2.xyz).xyz);
	r0.yzw = asint(asfloat(r0.zwy) * float3(2, 2, 2) + float3(-1, -1, -1));
	r2.x = i.texcoord2.w * detailSettings.x;
	r0.w = asint(asfloat(r0.w) * r2.x + 1);
	o.sv_target.xyz = asfloat(r0.www) * r1.xyz;
	r1.xyz = asfloat(r0.zzz) * i.texcoord5.xyz;
	r1.xyz = i.texcoord4.xyz * asfloat(r0.yyy) + r1.xyz;
	r1.xyz = r1.xyz * detailSettings.yyy;
	r1.xyz = r1.xyz * i.texcoord2.www + r3.yzw;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.y = asint(dot(r1.xyz, r1.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r1.xyz = asfloat(r0.yyy) * r1.xyz;
	o.sv_target2.x = saturate(asfloat(r0.w) * asfloat(r0.x));
	r0.x = asint(saturate(gAmbientOcclusionEffect.z));
	r0.x = asint(saturate(asfloat(r0.x) + i.texcoord2.x));
	o.sv_target1.xyz = r1.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r3.x = saturate(r3.x);
	r0.y = asint(sqrt(r3.x));
	o.sv_target2.y = sqrt(asfloat(r0.y));
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	r0.x = asint(r1.w * globalScalars.x);
	r0.yzw = asint(saturate(asfloat(r4.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.sv_target3.xyz = sqrt(asfloat(r0.yzw));
	o.sv_target.w = asfloat(r0.x);
	o.sv_target1.w = asfloat(r0.x);
	o.sv_target2.w = asfloat(r0.x);
	o.sv_target3.w = asfloat(r0.x);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
