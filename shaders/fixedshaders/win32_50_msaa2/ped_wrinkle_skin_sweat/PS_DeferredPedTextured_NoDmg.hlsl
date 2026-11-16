cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

cbuffer direction_light : register(b10)
{
	float4 gDepthFxParams : packoffset(c0);
	float4 gDirectionalLight : packoffset(c1);
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

cbuffer CacheSubSurface : register(b4)
{
	float4 SubColor : packoffset(c0);
	float SubScatWrap : packoffset(c1);
	float SubScatWidth : packoffset(c1.y);
};

cbuffer CachePedParam : register(b7)
{
	float ArmourStrength : packoffset(c0);
	float bumpiness : packoffset(c0.y);
	float displacementScale : packoffset(c0.z);
	float specularFactor : packoffset(c0.w);
	float3 specMapIntMask : packoffset(c1);
	float4 specMapExpMask : packoffset(c2);
	float4 matMaterialColorScale : packoffset(c3);
};

cbuffer Details : register(b9)
{
	float4 detailSettings : packoffset(c0);
};

cbuffer Wrinkles : register(b12)
{
	float4 wrinkleMaskStrengths0 : packoffset(c0);
	float4 wrinkleMaskStrengths1 : packoffset(c1);
	float4 wrinkleMaskStrengths2 : packoffset(c2);
	float4 wrinkleMaskStrengths3 : packoffset(c3);
};

cbuffer SweatDetail : register(b13)
{
	float4 vNoiseParams : packoffset(c0);
	float4 SkinParams : packoffset(c1);
	float4 vSkinSweat : packoffset(c2);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s4);
SamplerState SpecSampler : register(s5);
SamplerState VolumeSampler : register(s6);
SamplerState WrinkleMaskSampler_0 : register(s7);
SamplerState WrinkleMaskSampler_1 : register(s8);
SamplerState WrinkleSampler_A : register(s9);
SamplerState WrinkleSampler_B : register(s10);
SamplerState SweatMapSampler : register(s11);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t4);
Texture2D SpecSampler_tex : register(t5);
Texture3D VolumeSampler_tex : register(t6);
Texture2D WrinkleMaskSampler_0_tex : register(t7);
Texture2D WrinkleMaskSampler_1_tex : register(t8);
Texture2D WrinkleSampler_A_tex : register(t9);
Texture2D WrinkleSampler_B_tex : register(t10);
Texture2D SweatMapSampler_tex : register(t11);

struct PS_IN
{
	noperspective centroid float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
};

struct PS_OUT
{
	float4 sv_target : SV_Target;
	float4 sv_target1 : SV_Target1;
	float4 sv_target2 : SV_Target2;
	float4 sv_target3 : SV_Target3;
};

PS_OUT main(PS_IN i)
{
	PS_OUT o;

	int4 r0;
	int4 r1;
	int4 r2;
	int4 r3;
	float4 r4;
	r0.xyz = asint(WrinkleSampler_B_tex.Sample(WrinkleSampler_B, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = asint(-(asfloat(r0.zy)) + asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.ww) * asfloat(r1.xy) + asfloat(r0.zy));
	r1.xyz = asint(WrinkleSampler_A_tex.Sample(WrinkleSampler_A, i.texcoord.xy).xyw);
	r0.z = asint(-(asfloat(r1.z)) + 1);
	r0.z = (asfloat(r0.z) < asfloat(r1.x)) ? -1 : 0;
	r0.z = r0.z & 1065353216;
	r1.xw = asint(-(asfloat(r1.zy)) + asfloat(r1.xy));
	r0.zw = asint(asfloat(r0.zz) * asfloat(r1.xw) + asfloat(r1.zy));
	r0 = asint(asfloat(r0) + float4(-0.5, -0.5, -0.5, -0.5));
	r1.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r1.w = asint(-(asfloat(r1.z)) + 1);
	r1.w = (asfloat(r1.w) < asfloat(r1.x)) ? -1 : 0;
	r1.w = r1.w & 1065353216;
	r2.xy = asint(-(asfloat(r1.zy)) + asfloat(r1.xy));
	r1.xy = asint(asfloat(r1.ww) * asfloat(r2.xy) + asfloat(r1.zy));
	r1.xy = asint(asfloat(r1.xy) + float2(-0.5, -0.5));
	r1.xy = asint(asfloat(r1.xy) * bumpiness);
	r1.xy = asint(asfloat(r1.xy) + asfloat(r1.xy));
	r0.zw = asint(asfloat(r0.zw) * float2(2, 2) + -(asfloat(r1.xy)));
	r2 = asint(WrinkleMaskSampler_0_tex.Sample(WrinkleMaskSampler_0, i.texcoord.xy));
	r1.z = asint(dot(wrinkleMaskStrengths0, asfloat(r2)));
	r1.w = asint(dot(wrinkleMaskStrengths2, asfloat(r2)));
	r2 = asint(WrinkleMaskSampler_1_tex.Sample(WrinkleMaskSampler_1, i.texcoord.xy));
	r3.x = asint(dot(wrinkleMaskStrengths1, asfloat(r2)));
	r2.x = asint(dot(wrinkleMaskStrengths3, asfloat(r2)));
	r1.w = asint(asfloat(r1.w) + asfloat(r2.x));
	r1.z = asint(asfloat(r1.z) + asfloat(r3.x));
	r0.zw = asint(asfloat(r1.zz) * asfloat(r0.zw) + asfloat(r1.xy));
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + -(asfloat(r0.zw)));
	r0.xy = asint(asfloat(r1.ww) * asfloat(r0.xy) + asfloat(r0.zw));
	r0.w = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.w = asint(-(asfloat(r0.w)) + 1);
	r0.w = asint(max(asfloat(r0.w), 0));
	r0.z = asint(sqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r1.xyz = asint(asfloat(r0.xxx) * i.texcoord4.xyz);
	r0.xzw = asint(i.texcoord1.xyz * asfloat(r0.zzz) + asfloat(r1.xyz));
	r0.xyz = asint(i.texcoord5.xyz * asfloat(r0.yyy) + asfloat(r0.xzw));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r1.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r0.www) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(gDirectionalLight.xyz, asfloat(r1.xyz)));
	r0.w = asint(asfloat(r0.w) + SubScatWrap);
	r1.w = asint(SubScatWrap + 1);
	r0.w = asint(asfloat(r0.w) / asfloat(r1.w));
	r0.w = asint(max(asfloat(r0.w), 0));
	r1.w = asint(-(SubScatWidth) * 2 + asfloat(r0.w));
	r2.x = asint(1 / -(SubScatWidth));
	r1.w = asint(saturate(asfloat(r1.w) * asfloat(r2.x)));
	r2.x = asint(asfloat(r1.w) * -2 + 3);
	r1.w = asint(asfloat(r1.w) * asfloat(r1.w));
	r1.w = asint(asfloat(r1.w) * asfloat(r2.x));
	r2.x = asint(1 / SubScatWidth);
	r0.w = asint(saturate(asfloat(r0.w) * asfloat(r2.x)));
	r2.x = asint(asfloat(r0.w) * -2 + 3);
	r0.w = asint(asfloat(r0.w) * asfloat(r0.w));
	r0.w = asint(asfloat(r0.w) * asfloat(r2.x));
	r0.w = asint(asfloat(r1.w) * asfloat(r0.w));
	r2.xyz = asint(asfloat(r0.www) * SubColor.xyz);
	r3 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r2.xyz = asint(asfloat(r2.xyz) * asfloat(r3.www));
	r2.xyz = asint(asfloat(r2.xyz) * float3(0.5, 0.5, 0.5) + asfloat(r3.xyz));
	r2.xyz = asint(asfloat(r2.xyz) * matMaterialColorScale.xxx);
	r0.w = asint(i.texcoord2.w * detailSettings.x);
	r3.xy = asint(i.texcoord.xy * detailSettings.zw);
	r4 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r1.w = asint(r4.z * 16);
	r1.w = asint(trunc(asfloat(r1.w)));
	r1.w = asint(asfloat(r1.w) + 0.5);
	r3.z = asint(asfloat(r1.w) * 0.0625);
	r3.xyz = asint(VolumeSampler_tex.Sample(VolumeSampler, asfloat(r3.xyz)).xyz);
	r3.xyz = asint(asfloat(r3.yzx) * float3(2, 2, 2) + float3(-1, -1, -1));
	r0.w = asint(asfloat(r3.z) * asfloat(r0.w) + 1);
	o.sv_target.xyz = asfloat(r0.www) * asfloat(r2.xyz);
	r1.w = asint(i.texcoord2.w * globalScalars.x);
	o.sv_target.w = asfloat(r1.w);
	r2.xyz = asint(asfloat(r3.yyy) * i.texcoord5.xyz);
	r2.xyz = asint(i.texcoord4.xyz * asfloat(r3.xxx) + asfloat(r2.xyz));
	r2.xyz = asint(asfloat(r2.xyz) * detailSettings.yyy);
	r1.xyz = asint(asfloat(r2.xyz) * i.texcoord2.www + asfloat(r1.xyz));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r2.x = asint(rsqrt(asfloat(r2.x)));
	r1.xyz = asint(asfloat(r1.xyz) * asfloat(r2.xxx));
	r2.xyz = asint(SweatMapSampler_tex.Sample(SweatMapSampler, i.texcoord.xy).xyz);
	r2.xy = asint(asfloat(r2.xy) + float2(-0.5, -0.5));
	r2.xy = asint(asfloat(r2.xy) * SkinParams.zz);
	r2.xy = asint(asfloat(r2.xy) + asfloat(r2.xy));
	r2.w = asint(dot(asfloat(r2.xy), asfloat(r2.xy)));
	r2.w = asint(-(asfloat(r2.w)) + 1);
	r2.w = asint(max(asfloat(r2.w), 0));
	r2.w = asint(sqrt(asfloat(r2.w)));
	r3.xyz = asint(asfloat(r2.xxx) * i.texcoord4.xyz);
	r3.xyz = asint(i.texcoord1.xyz * asfloat(r2.www) + asfloat(r3.xyz));
	r2.xyw = asint(asfloat(r2.yyy) * i.texcoord5.xyz + asfloat(r3.xyz));
	r2.xyw = asint(asfloat(r2.xyw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r3.x = asint(dot(asfloat(r2.xyw), asfloat(r2.xyw)));
	r3.x = asint(rsqrt(asfloat(r3.x)));
	r2.xyw = asint(asfloat(r2.xyw) * asfloat(r3.xxx) + -(asfloat(r1.xyz)));
	r3.x = asint(asfloat(r2.z) + -(vSkinSweat.y));
	r3.x = asint(saturate(asfloat(r3.x) / vSkinSweat.w));
	r2.xyw = asint(asfloat(r3.xxx) * asfloat(r2.xyw) + asfloat(r1.xyz));
	r2.xyw = asint(asfloat(r2.xyw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r3.y = asint(dot(asfloat(r2.xyw), asfloat(r2.xyw)));
	r3.y = asint(rsqrt(asfloat(r3.y)));
	r2.xyw = asint(asfloat(r2.xyw) * asfloat(r3.yyy));
	r3.y = (vSkinSweat.y < asfloat(r2.z)) ? -1 : 0;
	r2.z = (asfloat(r2.z) < vSkinSweat.z) ? -1 : 0;
	r2.z = r2.z & r3.y;
	r1.xyz = (r2.zzz != 0) ? r2.xyw : r1.xyz;
	o.sv_target1.xyz = asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = asfloat(r1.w);
	r1.x = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r1.xxx));
	r1.xyz = asint(i.texcoord7.xyz + -(gViewInverse[3].xyz));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r2.x = asint(rsqrt(asfloat(r2.x)));
	r1.xyz = asint(asfloat(r1.xyz) * asfloat(r2.xxx));
	r0.x = asint(dot(asfloat(r1.xyz), asfloat(r0.xyz)));
	r0.x = asint(asfloat(r0.x) * -1.5);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(asfloat(r0.x) * i.texcoord2.y);
	r0.y = asint(dot(r4.xyz, specMapIntMask.xyz));
	r0.z = asint(dot(r4, specMapExpMask));
	r0.z = asint(asfloat(r0.z) * specularFactor);
	r0.z = asint(max(asfloat(r0.z), 1));
	r0.yz = asint(asfloat(r0.yz) * matMaterialColorScale.ww);
	r1.x = asint(saturate(asfloat(r0.y) * 5));
	r0.x = asint(asfloat(r0.x) * asfloat(r1.x));
	r1.x = asint(saturate(-(asfloat(r0.z)) * 0.00999999978 + 1));
	r2.y = asint(SkinParams.y * vSkinSweat.x + asfloat(r0.z));
	r0.x = asint(asfloat(r1.x) * asfloat(r0.x) + asfloat(r0.y));
	r0.x = asint(saturate(asfloat(r0.w) * asfloat(r0.x)));
	r0.x = asint(SkinParams.x * vSkinSweat.x + asfloat(r0.x));
	r0.yz = asint(vNoiseParams.zw * vSkinSweat.xx);
	r0.y = asint(asfloat(r0.w) * asfloat(r0.y) + asfloat(r0.z));
	r2.x = asint(asfloat(r0.y) + asfloat(r0.x));
	r0.xy = asint(-(asfloat(r2.xy)) + vNoiseParams.xy);
	r0.xy = asint(asfloat(r3.xx) * asfloat(r0.xy) + asfloat(r2.xy));
	r0.xy = (r2.zz != 0) ? r0.xy : r2.xy;
	o.sv_target2.x = asfloat(r0.x);
	r0.x = asint(saturate(asfloat(r0.y) * 0.00510204071));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	o.sv_target2.w = dot(abs(frac(i.sv_position.xy) - 0.5), float2(1000, 1000));
	o.sv_target3.w = asfloat(r1.w);
	r0.x = asint(saturate(gAmbientOcclusionEffect.z));
	r0.x = asint(saturate(asfloat(r0.x) + i.texcoord2.x));
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	o.sv_target3.xyz = float3(0, 0, 0);

	return o;
}
