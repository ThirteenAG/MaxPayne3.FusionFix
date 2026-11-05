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
	float4 gBloodData : packoffset(c4);
};

cbuffer Details : register(b7)
{
	float4 detailSettings : packoffset(c0);
};

cbuffer Wrinkles : register(b9)
{
	float4 wrinkleMaskStrengths0 : packoffset(c0);
	float4 wrinkleMaskStrengths1 : packoffset(c1);
	float4 wrinkleMaskStrengths2 : packoffset(c2);
	float4 wrinkleMaskStrengths3 : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BloodSampler : register(s2);
SamplerState BumpSampler : register(s4);
SamplerState SpecSampler : register(s5);
SamplerState VolumeSampler : register(s6);
SamplerState WrinkleMaskSampler_0 : register(s7);
SamplerState WrinkleMaskSampler_1 : register(s8);
SamplerState WrinkleSampler_A : register(s9);
SamplerState WrinkleSampler_B : register(s10);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BloodSampler_tex : register(t2);
Texture2D BumpSampler_tex : register(t4);
Texture2D SpecSampler_tex : register(t5);
Texture3D VolumeSampler_tex : register(t6);
Texture2D WrinkleMaskSampler_0_tex : register(t7);
Texture2D WrinkleMaskSampler_1_tex : register(t8);
Texture2D WrinkleSampler_A_tex : register(t9);
Texture2D WrinkleSampler_B_tex : register(t10);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
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
	int4 r2;
	int4 r3;
	float3 r4;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r1.x = (0 < gBloodData.w) ? -1 : 0;
	if (r1.x != 0) {
		r1.xyw = asint(BloodSampler_tex.Sample(BloodSampler, i.texcoord.zw).xyw);
		r1.z = asint(min(asfloat(r1.y), asfloat(r1.x)));
		r1.w = asint(saturate(asfloat(r1.x) * 0.5 + asfloat(r1.w)));
		r1.xyz = asint(-(r0.xyz) + asfloat(r1.xyz));
		r0.xyz = asfloat(r1.www) * asfloat(r1.xyz) + r0.xyz;
	}
	r0.w = r0.w * i.texcoord2.w;
	r0.w = r0.w * globalScalars.x;
	r1.x = (g_AlphaRef >= r0.w) ? -1 : 0;
	if (r1.x != 0) discard;
	r1 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r1.w = asint(dot(asfloat(r1), specMapExpMask));
	r1.w = asint(asfloat(r1.w) * specularFactor);
	r1.x = asint(dot(asfloat(r1.xyz), specMapIntMask.xyz));
	r1.y = asint(max(asfloat(r1.w), 1));
	r2 = asint(WrinkleMaskSampler_0_tex.Sample(WrinkleMaskSampler_0, i.texcoord.xy));
	r3 = asint(WrinkleMaskSampler_1_tex.Sample(WrinkleMaskSampler_1, i.texcoord.xy));
	r1.w = asint(dot(wrinkleMaskStrengths0, asfloat(r2)));
	r4.x = dot(wrinkleMaskStrengths1, asfloat(r3));
	r1.w = asint(asfloat(r1.w) + r4.x);
	r2.x = asint(dot(wrinkleMaskStrengths2, asfloat(r2)));
	r2.y = asint(dot(wrinkleMaskStrengths3, asfloat(r3)));
	r2.x = asint(asfloat(r2.y) + asfloat(r2.x));
	r2.yzw = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r3.x = asint(-(asfloat(r2.w)) + 1);
	r3.x = (asfloat(r3.x) < asfloat(r2.y)) ? -1 : 0;
	r3.x = r3.x & 1065353216;
	r3.yz = asint(-(asfloat(r2.wz)) + asfloat(r2.yz));
	r2.yz = asint(asfloat(r3.xx) * asfloat(r3.yz) + asfloat(r2.wz));
	r2.yz = asint(asfloat(r2.yz) + float2(-0.5, -0.5));
	r2.yz = asint(asfloat(r2.yz) * bumpiness);
	r2.yz = asint(asfloat(r2.yz) + asfloat(r2.yz));
	r3.xyz = asint(WrinkleSampler_A_tex.Sample(WrinkleSampler_A, i.texcoord.xy).xyw);
	r2.w = asint(-(asfloat(r3.z)) + 1);
	r2.w = (asfloat(r2.w) < asfloat(r3.x)) ? -1 : 0;
	r2.w = r2.w & 1065353216;
	r3.xw = asint(-(asfloat(r3.zy)) + asfloat(r3.xy));
	r3.xy = asint(asfloat(r2.ww) * asfloat(r3.xw) + asfloat(r3.zy));
	r4 = WrinkleSampler_B_tex.Sample(WrinkleSampler_B, i.texcoord.xy).xyw;
	r2.w = asint(-(r4.z) + 1);
	r2.w = (asfloat(r2.w) < r4.x) ? -1 : 0;
	r2.w = r2.w & 1065353216;
	r3.zw = asint(-(r4.zy) + r4.xy);
	r3.zw = asint(asfloat(r2.ww) * asfloat(r3.zw) + r4.zy);
	r3 = asint(asfloat(r3) + float4(-0.5, -0.5, -0.5, -0.5));
	r3.xy = asint(asfloat(r3.xy) * float2(2, 2) + -(asfloat(r2.yz)));
	r2.yz = asint(asfloat(r1.ww) * asfloat(r3.xy) + asfloat(r2.yz));
	r3.xy = asint(asfloat(r3.zw) * float2(2, 2) + -(asfloat(r2.yz)));
	r2.xy = asint(asfloat(r2.xx) * asfloat(r3.xy) + asfloat(r2.yz));
	r1.w = asint(dot(asfloat(r2.xy), asfloat(r2.xy)));
	r1.w = asint(-(asfloat(r1.w)) + 1);
	r1.w = asint(max(asfloat(r1.w), 0));
	r2.z = asint(sqrt(asfloat(r1.w)));
	r2.xyz = asint(asfloat(r2.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asint(asfloat(r1.www) * asfloat(r2.xyz));
	r3.xyz = asint(asfloat(r2.xxx) * i.texcoord4.xyz);
	r2.xzw = asint(i.texcoord1.xyz * asfloat(r2.zzz) + asfloat(r3.xyz));
	r2.xyz = asint(i.texcoord5.xyz * asfloat(r2.yyy) + asfloat(r2.xzw));
	r2.xyz = asint(asfloat(r2.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asint(asfloat(r2.xyz) * asfloat(r1.www) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r3.xyz = asint(asfloat(r1.www) * asfloat(r2.xyz));
	r0.xyz = r0.xyz * matMaterialColorScale.xxx;
	r1.xy = asint(asfloat(r1.xy) * matMaterialColorScale.ww);
	r4 = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r4 = r4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.w = asint(dot(r4.xyz, r4.xyz));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r4 = asfloat(r2.www) * r4.xyz;
	r2.xyz = asint(asfloat(r2.xyz) * asfloat(r1.www) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asint(asfloat(r1.www) * asfloat(r2.xyz));
	r1.w = asint(dot(r4.xyz, asfloat(r2.xyz)));
	r1.w = asint(asfloat(r1.w) * -1.5);
	r1.w = asint(max(asfloat(r1.w), 0));
	r1.w = asint(-(asfloat(r1.w)) + 1);
	r1.w = asint(max(asfloat(r1.w), 0));
	r1.w = asint(asfloat(r1.w) * i.texcoord2.y);
	r2.x = asint(saturate(asfloat(r1.x) * 5));
	r1.w = asint(asfloat(r1.w) * asfloat(r2.x));
	r2.x = asint(asfloat(r1.y) * 0.00510204071);
	r1.y = asint(saturate(-(asfloat(r1.y)) * 0.00999999978 + 1));
	r1.x = asint(asfloat(r1.y) * asfloat(r1.w) + asfloat(r1.x));
	r1.y = asint(asfloat(r1.z) * 16);
	r1.y = asint(trunc(asfloat(r1.y)));
	r4.xy = i.texcoord.xy * detailSettings.zw;
	r1.y = asint(asfloat(r1.y) + 0.5);
	r4.z = asfloat(r1.y) * 0.0625;
	r1.yzw = asint(VolumeSampler_tex.Sample(VolumeSampler, r4.xyz).xyz);
	r1.yzw = asint(asfloat(r1.zwy) * float3(2, 2, 2) + float3(-1, -1, -1));
	r2.y = asint(i.texcoord2.w * detailSettings.x);
	r1.w = asint(asfloat(r1.w) * asfloat(r2.y) + 1);
	o.sv_target.xyz = r0.xyz * asfloat(r1.www);
	r0.xyz = asfloat(r1.zzz) * i.texcoord5.xyz;
	r0.xyz = i.texcoord4.xyz * asfloat(r1.yyy) + r0.xyz;
	r0.xyz = r0.xyz * detailSettings.yyy;
	r0.xyz = r0.xyz * i.texcoord2.www + asfloat(r3.xyz);
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.y = asint(dot(r0.xyz, r0.xyz));
	r1.y = asint(rsqrt(asfloat(r1.y)));
	r0.xyz = r0.xyz * asfloat(r1.yyy);
	o.sv_target2.x = saturate(asfloat(r1.w) * asfloat(r1.x));
	r1.x = asint(saturate(gAmbientOcclusionEffect.z));
	r1.x = asint(saturate(asfloat(r1.x) + i.texcoord2.x));
	o.sv_target1.xyz = r0.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r2.x = asint(saturate(asfloat(r2.x)));
	r0.x = sqrt(asfloat(r2.x));
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.z = asfloat(r1.x) * gAmbientOcclusionEffect.w;
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
