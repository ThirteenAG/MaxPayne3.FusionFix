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
	float4 gBloodData : packoffset(c6);
};

cbuffer Details : register(b7)
{
	float4 detailSettings : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BloodSampler : register(s2);
SamplerState BumpSampler : register(s4);
SamplerState SpecSampler : register(s5);
SamplerState VolumeSampler : register(s6);
SamplerState DynamicEnvironmentSampler : register(s13);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BloodSampler_tex : register(t2);
Texture2D BumpTex : register(t4);
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
	int4 r1;
	int4 r2;
	float4 r3;
	float4 r4;
	float3 r5;
	float4 r6;
	float3 r7;
	r0.xyz = asint(BumpTex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = asint(-(asfloat(r0.zy)) + asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.ww) * asfloat(r1.xy) + asfloat(r0.zy));
	r1 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r2.xyz = asint(i.texcoord2.xyz);
	r2.w = 1065353216;
	r3 = asfloat(r1) * asfloat(r2);
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(max(asfloat(r0.z), 0));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r4 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.w = asint(dot(r4, specMapExpMask));
	r0.w = asint(asfloat(r0.w) * specularFactor);
	r0.w = asint(max(asfloat(r0.w), 1));
	r5 = asfloat(r0.xxx) * i.texcoord4.xyz;
	r5 = asfloat(r0.zzz) * i.texcoord1.xyz + r5.xyz;
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + r5.xyz);
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r5 = asfloat(r0.xyz) * asfloat(r1.www);
	r2.w = (0 < reflectivePower) ? -1 : 0;
	if (r2.w != 0) {
		r2.w = asint(asfloat(r0.w) * 0.015625);
		r2.w = asint(min(asfloat(r2.w), 1));
		r2.w = asint(-(asfloat(r2.w)) * 4 + 4);
		r6.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r4.w = dot(r6.xyz, r6.xyz);
		r4.w = rsqrt(r4.w);
		r6.xyz = r4.www * r6.xyz;
		r4.w = dot(-(r6.xyz), r5.xyz);
		r4.w = r4.w + r4.w;
		r7 = r5.xyz * -(r4.www) + -(r6.xyz);
		r7 = r7.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r4.w = dot(r7.xyz, r7.xyz);
		r4.w = rsqrt(r4.w);
		r7 = r4.www * r7.zxy;
		r7.x = saturate(r7.x);
		r4.w = r7.x + 1;
		r4.w = r4.w + r4.w;
		r7.xy = r7.yz / r4.ww;
		r7.xy = r7.xy + float2(0.5, 0.5);
		r7.xy = -(r7.xy) + float2(1, 1);
		r7 = DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, r7.xy, asfloat(r2.w)).xyz;
		r7 = r7.xyz * r7.xyz;
		r7 = r7.xyz * float3(16, 16, 16);
		r2.w = asint(saturate(dot(r6.xyz, r5.xyz)));
		r4.w = -(fresnelRolloff) + 1;
		r2.w = asint(-(asfloat(r2.w)) + 1.00001001);
		r5.x = asfloat(r2.w) * asfloat(r2.w);
		r5.x = r5.x * r5.x;
		r2.w = asint(asfloat(r2.w) * r5.x);
		r2.w = asint(fresnelRolloff * asfloat(r2.w) + r4.w);
		r5 = asfloat(r2.www) * r7.xyz;
	} else {
		r5 = float3(0, 0, 0);
	}
	r2.w = (0 < gBloodData.w) ? -1 : 0;
	if (r2.w != 0) {
		r6.xyw = BloodSampler_tex.Sample(BloodSampler, i.texcoord.zw).xyw;
		r6.z = min(r6.y, r6.x);
		r2.w = asint(saturate(r6.x * 0.5 + r6.w));
		r1.xyz = asint(-(asfloat(r2.xyz)) * asfloat(r1.xyz) + r6.xyz);
		r3.xyz = asfloat(r2.www) * asfloat(r1.xyz) + r3.xyz;
	}
	r1.x = asint(r3.w * i.texcoord2.w);
	r1.x = asint(asfloat(r1.x) * globalScalars.x);
	r1.y = (g_AlphaRef >= asfloat(r1.x)) ? -1 : 0;
	if (r1.y != 0) discard;
	r1.y = asint(dot(i.texcoord2.xyz, float3(0.300000012, 0.600000024, 0.100000001)));
	r1.z = asint(dot(r4.xyz, specMapIntMask.xyz));
	r2.xyz = asint(r5.xyz * reflectivePower);
	r2.w = asint(dot(r4.xyz, specMapReflectMask.xyz));
	r2.xyz = asint(asfloat(r2.www) * asfloat(r2.xyz));
	r2.xyz = asint(asfloat(r2.xyz) * ColorCorrectTopAndPedReflectScale.www);
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r1.www) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r4.xyw = asfloat(r0.xyz) * asfloat(r1.www);
	r1.y = asint(asfloat(r1.y) * globalScalars.z + -1);
	r1.y = asint(gAmbientOcclusionEffect.x * asfloat(r1.y) + 1);
	r3.xyz = r3.xyz * matMaterialColorScale.xxx;
	r2.xyz = asint(asfloat(r2.xyz) * matMaterialColorScale.zzz);
	r1.z = asint(asfloat(r1.z) * matMaterialColorScale.w);
	r0.w = asint(asfloat(r0.w) * matMaterialColorScale.w);
	r5 = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r5 = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.w = asint(dot(r5.xyz, r5.xyz));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r5 = asfloat(r2.www) * r5.xyz;
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r1.www) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r1.www));
	r0.x = asint(dot(r5.xyz, asfloat(r0.xyz)));
	r0.x = asint(asfloat(r0.x) * -1.5);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(asfloat(r0.x) * i.texcoord2.y);
	r0.y = asint(saturate(asfloat(r1.z) * 5));
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x));
	r5.x = asfloat(r0.w) * 0.00510204071;
	r0.y = asint(saturate(-(asfloat(r0.w)) * 0.00999999978 + 1));
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x) + asfloat(r1.z));
	r0.y = asint(r4.z * 16);
	r0.y = asint(trunc(asfloat(r0.y)));
	r6.xy = i.texcoord.xy * detailSettings.zw;
	r0.y = asint(asfloat(r0.y) + 0.5);
	r6.z = asfloat(r0.y) * 0.0625;
	r0.yzw = asint(VolumeSampler_tex.Sample(VolumeSampler, r6.xyz).xyz);
	r0.yzw = asint(asfloat(r0.zwy) * float3(2, 2, 2) + float3(-1, -1, -1));
	r1.z = asint(i.texcoord2.w * detailSettings.x);
	r0.w = asint(asfloat(r0.w) * asfloat(r1.z) + 1);
	o.sv_target.xyz = asfloat(r0.www) * r3.xyz;
	r3.xyz = asfloat(r0.zzz) * i.texcoord5.xyz;
	r3.xyz = i.texcoord4.xyz * asfloat(r0.yyy) + r3.xyz;
	r3.xyz = r3.xyz * detailSettings.yyy;
	r3.xyz = r3.xyz * i.texcoord2.www + r4.xyw;
	r3.xyz = r3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.y = asint(dot(r3.xyz, r3.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r3.xyz = asfloat(r0.yyy) * r3.xyz;
	o.sv_target2.x = saturate(asfloat(r0.w) * asfloat(r0.x));
	r0.x = asint(saturate(gAmbientOcclusionEffect.z));
	r0.x = asint(saturate(asfloat(r0.x) + asfloat(r1.y)));
	o.sv_target1.xyz = r3.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r5.x = saturate(r5.x);
	r0.y = asint(sqrt(r5.x));
	o.sv_target2.y = sqrt(asfloat(r0.y));
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	r0.xyz = asint(saturate(asfloat(r2.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.sv_target3.xyz = sqrt(asfloat(r0.xyz));
	o.sv_target.w = asfloat(r1.x);
	o.sv_target1.w = asfloat(r1.x);
	o.sv_target2.w = asfloat(r1.x);
	o.sv_target3.w = asfloat(r1.x);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
