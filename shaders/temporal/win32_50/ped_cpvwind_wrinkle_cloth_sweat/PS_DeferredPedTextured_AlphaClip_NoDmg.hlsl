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

cbuffer Wrinkles : register(b9)
{
	float4 wrinkleMaskStrengths0 : packoffset(c0);
	float4 wrinkleMaskStrengths1 : packoffset(c1);
	float4 wrinkleMaskStrengths2 : packoffset(c2);
	float4 wrinkleMaskStrengths3 : packoffset(c3);
};

cbuffer ClothSweat : register(b12)
{
	float4 vSweatParams : packoffset(c0);
	float4 ClothDarken : packoffset(c1);
	float4 ClothSweatSpec : packoffset(c2);
	float4 ClothDarkenColor : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s4);
SamplerState SpecSampler : register(s5);
SamplerState VolumeSampler : register(s6);
SamplerState WrinkleMaskSampler_0 : register(s7);
SamplerState WrinkleMaskSampler_1 : register(s8);
SamplerState WrinkleSampler_A : register(s9);
SamplerState WrinkleSampler_B : register(s10);
SamplerState ClothSweatMapSampler : register(s11);
SamplerState DynamicEnvironmentSampler : register(s13);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t4);
Texture2D SpecSampler_tex : register(t5);
Texture3D VolumeSampler_tex : register(t6);
Texture2D WrinkleMaskSampler_0_tex : register(t7);
Texture2D WrinkleMaskSampler_1_tex : register(t8);
Texture2D WrinkleSampler_A_tex : register(t9);
Texture2D WrinkleSampler_B_tex : register(t10);
Texture2D ClothSweatMapSampler_tex : register(t11);
Texture2D DynamicEnvironmentSampler_tex : register(t13);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float4 texcoord4 : TEXCOORD4;
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
	float4 r2;
	int4 r3;
	int4 r4;
	float4 r5;
	r0.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = asint(-(asfloat(r0.zy)) + asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.ww) * asfloat(r1.xy) + asfloat(r0.zy));
	r1 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.z = asint(dot(r2, specMapExpMask));
	r0.z = asint(asfloat(r0.z) * specularFactor);
	r0.z = asint(max(asfloat(r0.z), 1));
	r0.w = (0 < reflectivePower) ? -1 : 0;
	if (r0.w != 0) {
		r3.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
		r3.xy = asint(asfloat(r3.xy) * bumpiness);
		r0.w = asint(dot(asfloat(r3.xy), asfloat(r3.xy)));
		r0.w = asint(-(asfloat(r0.w)) + 1);
		r0.w = asint(max(asfloat(r0.w), 0));
		r0.w = asint(sqrt(asfloat(r0.w)));
		r3.xzw = asint(asfloat(r3.xxx) * i.texcoord4.xyz);
		r3.xzw = asint(asfloat(r0.www) * i.texcoord1.xyz + asfloat(r3.xzw));
		r3.xyz = asint(asfloat(r3.yyy) * i.texcoord5.xyz + asfloat(r3.xzw));
		r3.xyz = asint(asfloat(r3.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r0.w = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r3.xyz = asint(asfloat(r0.www) * asfloat(r3.xyz));
		r0.w = asint(asfloat(r0.z) * 0.015625);
		r0.w = asint(min(asfloat(r0.w), 1));
		r0.w = asint(-(asfloat(r0.w)) * 4 + 4);
		r4.xyz = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r2.w = dot(asfloat(r4.xyz), asfloat(r4.xyz));
		r2.w = rsqrt(r2.w);
		r4.xyz = asint(r2.www * asfloat(r4.xyz));
		r2.w = dot(-(asfloat(r4.xyz)), asfloat(r3.xyz));
		r2.w = r2.w + r2.w;
		r5.xyz = asfloat(r3.xyz) * -(r2.www) + -(asfloat(r4.xyz));
		r5.xyz = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r2.w = dot(r5.xyz, r5.xyz);
		r2.w = rsqrt(r2.w);
		r5.xyz = r2.www * r5.zxy;
		r5.x = saturate(r5.x);
		r2.w = r5.x + 1;
		r2.w = r2.w + r2.w;
		r5.xy = r5.yz / r2.ww;
		r5.xy = r5.xy + float2(0.5, 0.5);
		r5.xy = -(r5.xy) + float2(1, 1);
		r5.xyz = DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, r5.xy, asfloat(r0.w)).xyz;
		r5.xyz = r5.xyz * r5.xyz;
		r5.xyz = r5.xyz * float3(16, 16, 16);
		r0.w = asint(saturate(dot(asfloat(r4.xyz), asfloat(r3.xyz))));
		r2.w = -(fresnelRolloff) + 1;
		r0.w = asint(-(asfloat(r0.w)) + 1.00001001);
		r3.x = asint(asfloat(r0.w) * asfloat(r0.w));
		r3.x = asint(asfloat(r3.x) * asfloat(r3.x));
		r0.w = asint(asfloat(r0.w) * asfloat(r3.x));
		r0.w = asint(fresnelRolloff * asfloat(r0.w) + r2.w);
		r3.xyz = asint(asfloat(r0.www) * r5.xyz);
	} else {
		r3.xyz = int3(0, 0, 0);
	}
	r0.w = asint(asfloat(r1.w) * i.texcoord2.w);
	r0.w = asint(asfloat(r0.w) * globalScalars.x);
	r1.w = (g_AlphaRef >= asfloat(r0.w)) ? -1 : 0;
	if (r1.w != 0) discard;
	r1.w = asint(dot(r2.xyz, specMapIntMask.xyz));
	r3.xyz = asint(asfloat(r3.xyz) * reflectivePower);
	r2.x = dot(r2.xyz, specMapReflectMask.xyz);
	r2.xyw = r2.xxx * asfloat(r3.xyz);
	r2.xyw = r2.xyw * ColorCorrectTopAndPedReflectScale.www;
	r3 = asint(WrinkleMaskSampler_0_tex.Sample(WrinkleMaskSampler_0, i.texcoord.xy));
	r4 = asint(WrinkleMaskSampler_1_tex.Sample(WrinkleMaskSampler_1, i.texcoord.xy));
	r5.x = dot(wrinkleMaskStrengths0, asfloat(r3));
	r5.y = dot(wrinkleMaskStrengths1, asfloat(r4));
	r5.x = r5.y + r5.x;
	r3.x = asint(dot(wrinkleMaskStrengths2, asfloat(r3)));
	r3.y = asint(dot(wrinkleMaskStrengths3, asfloat(r4)));
	r3.x = asint(asfloat(r3.y) + asfloat(r3.x));
	r0.xy = asint(asfloat(r0.xy) + float2(-0.5, -0.5));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.xy = asint(asfloat(r0.xy) + asfloat(r0.xy));
	r3.yzw = asint(WrinkleSampler_A_tex.Sample(WrinkleSampler_A, i.texcoord.xy).xyw);
	r4.x = asint(-(asfloat(r3.w)) + 1);
	r4.x = (asfloat(r4.x) < asfloat(r3.y)) ? -1 : 0;
	r4.x = r4.x & 1065353216;
	r4.yz = asint(-(asfloat(r3.wz)) + asfloat(r3.yz));
	r3.yz = asint(asfloat(r4.xx) * asfloat(r4.yz) + asfloat(r3.wz));
	r3.yz = asint(asfloat(r3.yz) + float2(-0.5, -0.5));
	r4.xyz = asint(WrinkleSampler_B_tex.Sample(WrinkleSampler_B, i.texcoord.xy).xyw);
	r3.w = asint(-(asfloat(r4.z)) + 1);
	r3.w = (asfloat(r3.w) < asfloat(r4.x)) ? -1 : 0;
	r3.w = r3.w & 1065353216;
	r4.xw = asint(-(asfloat(r4.zy)) + asfloat(r4.xy));
	r4.xy = asint(asfloat(r3.ww) * asfloat(r4.xw) + asfloat(r4.zy));
	r4.xy = asint(asfloat(r4.xy) + float2(-0.5, -0.5));
	r3.yz = asint(asfloat(r3.yz) * float2(2, 2) + -(asfloat(r0.xy)));
	r0.xy = asint(r5.xx * asfloat(r3.yz) + asfloat(r0.xy));
	r3.yz = asint(asfloat(r4.xy) * float2(2, 2) + -(asfloat(r0.xy)));
	r3.xy = asint(asfloat(r3.xx) * asfloat(r3.yz) + asfloat(r0.xy));
	r0.x = asint(dot(asfloat(r3.xy), asfloat(r3.xy)));
	r0.x = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(max(asfloat(r0.x), 0));
	r3.z = asint(sqrt(asfloat(r0.x)));
	r3.xyz = asint(asfloat(r3.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.x = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
	r0.x = asint(rsqrt(asfloat(r0.x)));
	r3.xyz = asint(asfloat(r0.xxx) * asfloat(r3.xyz));
	r4.xyz = asint(asfloat(r3.xxx) * i.texcoord4.xyz);
	r3.xzw = asint(i.texcoord1.xyz * asfloat(r3.zzz) + asfloat(r4.xyz));
	r3.xyz = asint(i.texcoord5.xyz * asfloat(r3.yyy) + asfloat(r3.xzw));
	r3.xyz = asint(asfloat(r3.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.x = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
	r0.x = asint(rsqrt(asfloat(r0.x)));
	r4.xyz = asint(asfloat(r0.xxx) * asfloat(r3.xyz));
	r5.xy = ClothSweatMapSampler_tex.Sample(ClothSweatMapSampler, i.texcoord.xy).xy;
	r0.y = asint(-(r5.y) + vSweatParams.x);
	r3.w = (vSweatParams.z < i.texcoord4.w) ? -1 : 0;
	r4.w = asint(-(i.texcoord4.w) + vSweatParams.z);
	r4.w = asint(saturate(asfloat(r4.w) / vSweatParams.w));
	r4.w = asint(asfloat(r4.w) * vSweatParams.y);
	r3.w = (r3.w != 0) ? 0 : r4.w;
	r0.y = asint(saturate(max(asfloat(r0.y), asfloat(r3.w))));
	r3.w = (ClothDarken.w < asfloat(r0.y)) ? -1 : 0;
	r4.w = asint(-(asfloat(r0.y)) + ClothDarken.w);
	r4.w = asint(asfloat(r4.w) / ClothDarken.w);
	r5.yzw = -(ClothDarken.xyz) + float3(1, 1, 1);
	r5.yzw = asfloat(r4.www) * r5.yzw + ClothDarken.xyz;
	r5.yzw = (r3.www != 0) ? ClothDarken.xyz : r5.yzw;
	r1.xyz = asint(asfloat(r1.xyz) + -(ClothDarkenColor.xyz));
	r1.xyz = asint(r5.yzw * asfloat(r1.xyz) + ClothDarkenColor.xyz);
	r3.w = asint(r5.x * ClothSweatSpec.x + -(asfloat(r1.w)));
	r1.w = asint(asfloat(r0.y) * asfloat(r3.w) + asfloat(r1.w));
	r3.w = asint(-(asfloat(r0.z)) + ClothSweatSpec.y);
	r0.y = asint(asfloat(r0.y) * asfloat(r3.w) + asfloat(r0.z));
	r1.xyz = asint(asfloat(r1.xyz) * matMaterialColorScale.xxx);
	r2.xyw = r2.xyw * matMaterialColorScale.zzz;
	r0.z = asint(asfloat(r1.w) * matMaterialColorScale.w);
	r0.y = asint(asfloat(r0.y) * matMaterialColorScale.w);
	r5.xyz = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r5.xyz = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r5.xyz, r5.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r5.xyz = asfloat(r1.www) * r5.xyz;
	r3.xyz = asint(asfloat(r3.xyz) * asfloat(r0.xxx) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.x = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
	r0.x = asint(rsqrt(asfloat(r0.x)));
	r3.xyz = asint(asfloat(r0.xxx) * asfloat(r3.xyz));
	r0.x = asint(dot(r5.xyz, asfloat(r3.xyz)));
	r0.x = asint(asfloat(r0.x) * -1.5);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(asfloat(r0.x) * i.texcoord2.y);
	r1.w = asint(saturate(asfloat(r0.z) * 5));
	r0.x = asint(asfloat(r0.x) * asfloat(r1.w));
	r3.x = asint(asfloat(r0.y) * 0.00510204071);
	r0.y = asint(saturate(-(asfloat(r0.y)) * 0.00999999978 + 1));
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x) + asfloat(r0.z));
	r0.y = asint(r2.z * 16);
	r0.y = asint(trunc(asfloat(r0.y)));
	r5.xy = i.texcoord.xy * detailSettings.zw;
	r0.y = asint(asfloat(r0.y) + 0.5);
	r5.z = asfloat(r0.y) * 0.0625;
	r3.yzw = asint(VolumeSampler_tex.Sample(VolumeSampler, r5.xyz).xyz);
	r3.yzw = asint(asfloat(r3.zwy) * float3(2, 2, 2) + float3(-1, -1, -1));
	r0.y = asint(i.texcoord2.w * detailSettings.x);
	r0.y = asint(asfloat(r3.w) * asfloat(r0.y) + 1);
	o.sv_target.xyz = asfloat(r0.yyy) * asfloat(r1.xyz);
	r1.xyz = asint(asfloat(r3.zzz) * i.texcoord5.xyz);
	r1.xyz = asint(i.texcoord4.xyz * asfloat(r3.yyy) + asfloat(r1.xyz));
	r1.xyz = asint(asfloat(r1.xyz) * detailSettings.yyy);
	r1.xyz = asint(asfloat(r1.xyz) * i.texcoord2.www + asfloat(r4.xyz));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.z = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r1.xyz = asint(asfloat(r0.zzz) * asfloat(r1.xyz));
	o.sv_target2.x = saturate(asfloat(r0.y) * asfloat(r0.x));
	r0.x = asint(saturate(gAmbientOcclusionEffect.z));
	r0.x = asint(saturate(asfloat(r0.x) + i.texcoord2.x));
	o.sv_target1.xyz = asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r3.x = asint(saturate(asfloat(r3.x)));
	r0.y = asint(sqrt(asfloat(r3.x)));
	o.sv_target2.y = sqrt(asfloat(r0.y));
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	r0.xyz = asint(saturate(r2.xyw * float3(0.0625, 0.0625, 0.0625)));
	o.sv_target3.xyz = sqrt(asfloat(r0.xyz));
	o.sv_target.w = asfloat(r0.w);
	o.sv_target1.w = asfloat(r0.w);
	o.sv_target2.w = asfloat(r0.w);
	o.sv_target3.w = asfloat(r0.w);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
