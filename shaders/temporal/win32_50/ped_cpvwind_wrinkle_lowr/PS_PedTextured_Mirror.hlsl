cbuffer direction_light : register(b10)
{
	float4 gDepthFxParams : packoffset(c0);
	float4 gDirectionalLight : packoffset(c1);
	float4 gDirectionalColour : packoffset(c2);
};

cbuffer omni_light : register(b2)
{
	float4 gLightPosX : packoffset(c0);
	float4 gLightPosY : packoffset(c1);
	float4 gLightPosZ : packoffset(c2);
	float4 gLightDirX : packoffset(c3);
	float4 gLightDirY : packoffset(c4);
	float4 gLightDirZ : packoffset(c5);
	float4 gLightFallOff : packoffset(c6);
	float4 gLightConeScale : packoffset(c7);
	float4 gLightConeOffset : packoffset(c8);
	float4 gLightColR : packoffset(c9);
	float4 gLightColG : packoffset(c10);
	float4 gLightColB : packoffset(c11);
	float4 gLightAmbient0 : packoffset(c12);
	float4 gLightAmbient1 : packoffset(c13);
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

cbuffer ShadowParam : register(b8)
{
	float4 gShadowParam18192021 : packoffset(c0);
	float4 gShadowParam14151617 : packoffset(c1);
	float4 gShadowParam0123 : packoffset(c2);
	float4 gShadowParam4567 : packoffset(c3);
	float4 gShadowParam891113 : packoffset(c4);
	float4 gCascadeZScales : packoffset(c5);
	float4 gCascadeZOffsets : packoffset(c6);
	float4 gCascadeXMinThresholds : packoffset(c7);
	float4 gCascadeXMaxThresholds : packoffset(c8);
	float4 gCascadeYMinThresholds : packoffset(c9);
	float4 gCascadeYMaxThresholds : packoffset(c10);
	row_major float4x4 gShadowMatrix : packoffset(c11);
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

cbuffer AmbientLight : register(b7)
{
	float3 AmbientLightingParams : packoffset(c0);
};

cbuffer Wrinkles : register(b9)
{
	float4 wrinkleMaskStrengths0 : packoffset(c0);
	float4 wrinkleMaskStrengths1 : packoffset(c1);
	float4 wrinkleMaskStrengths2 : packoffset(c2);
	float4 wrinkleMaskStrengths3 : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s4);
SamplerState SpecSampler : register(s5);
SamplerState WrinkleMaskSampler_0 : register(s7);
SamplerState WrinkleMaskSampler_1 : register(s8);
SamplerState WrinkleSampler_A : register(s9);
SamplerState WrinkleSampler_B : register(s10);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t4);
Texture2D SpecSampler_tex : register(t5);
Texture2D WrinkleMaskSampler_0_tex : register(t7);
Texture2D WrinkleMaskSampler_1_tex : register(t8);
Texture2D WrinkleSampler_A_tex : register(t9);
Texture2D WrinkleSampler_B_tex : register(t10);
Texture2D ShadowZTextureDir : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord7 : TEXCOORD7;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	int4 r1;
	int4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	float4 r6;
	float4 r7;
	float4 r8;
	float4 r9;
	float4 r10;
	r0.xyz = asint(i.texcoord2.yyy * gShadowMatrix[1].xyz);
	r0.xyz = asint(i.texcoord2.xxx * gShadowMatrix[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.texcoord2.zzz * gShadowMatrix[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + gShadowMatrix[3].xyz);
	r1.xy = asint(asfloat(r0.xy) + -(gShadowParam18192021.zw));
	r1.zw = (asfloat(r1.xx) >= gCascadeXMaxThresholds.xy) ? -1 : 0;
	r1.zw = r1.zw & int2(1065353216, 1065353216);
	r2.xy = (gCascadeXMinThresholds.xy >= asfloat(r1.xx)) ? -1 : 0;
	r2.xy = r2.xy & int2(1065353216, 1065353216);
	r1.zw = asint(asfloat(r1.zw) + asfloat(r2.xy));
	r2.xy = (asfloat(r1.yy) >= gCascadeYMaxThresholds.xy) ? -1 : 0;
	r2.xy = r2.xy & int2(1065353216, 1065353216);
	r1.zw = asint(asfloat(r1.zw) + asfloat(r2.xy));
	r2.xy = (gCascadeYMinThresholds.xy >= asfloat(r1.yy)) ? -1 : 0;
	r2.xy = r2.xy & int2(1065353216, 1065353216);
	r1.zw = asint(asfloat(r1.zw) + asfloat(r2.xy));
	r2.yz = asint(min(asfloat(r1.zw), float2(1, 1)));
	r2.x = 1065353216;
	r3.x = dot(asfloat(r2.xyz), gShadowParam0123.xyz);
	r3.y = dot(asfloat(r2.xyz), gShadowParam4567.xyz);
	r3.z = dot(asfloat(r2.xyz), gCascadeZScales.xyz);
	r4.x = dot(asfloat(r2.xyz), gShadowParam891113.xyz);
	r4.y = dot(asfloat(r2.xyz), gShadowParam14151617.xyz);
	r4.z = dot(asfloat(r2.xyz), gCascadeZOffsets.xyz);
	r0.xyz = asint(asfloat(r0.zxy) * r3.zxy + r4.zxy);
	r0.x = asint(saturate(asfloat(r0.x)));
	r0.x = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, asfloat(r0.yz), asfloat(r0.x)));
	r2.x = asint(-(gCascadeXMinThresholds.w));
	r2.y = asint(-(gCascadeXMaxThresholds.w));
	r0.yz = asint(saturate(abs(asfloat(r1.xy)) * float2(4, 4) + asfloat(r2.xy)));
	r0.y = asint(max(asfloat(r0.z), asfloat(r0.y)));
	r0.x = asint(asfloat(r0.y) + asfloat(r0.x));
	r0.x = asint(min(asfloat(r0.x), 1));
	r0.xyz = asint(asfloat(r0.xxx) * gDirectionalColour.xyz);
	r1.xyz = asint(WrinkleSampler_B_tex.Sample(WrinkleSampler_B, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r1.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r1.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xw = asint(-(asfloat(r1.zy)) + asfloat(r1.xy));
	r1.xy = asint(asfloat(r0.ww) * asfloat(r1.xw) + asfloat(r1.zy));
	r2.xyz = asint(WrinkleSampler_A_tex.Sample(WrinkleSampler_A, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r2.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r2.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.zw = asint(-(asfloat(r2.zy)) + asfloat(r2.xy));
	r1.zw = asint(asfloat(r0.ww) * asfloat(r1.zw) + asfloat(r2.zy));
	r1 = asint(asfloat(r1) + float4(-0.5, -0.5, -0.5, -0.5));
	r2.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r2.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r2.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r2.xw = asint(-(asfloat(r2.zy)) + asfloat(r2.xy));
	r2.xy = asint(asfloat(r0.ww) * asfloat(r2.xw) + asfloat(r2.zy));
	r2.xy = asint(asfloat(r2.xy) + float2(-0.5, -0.5));
	r2.xy = asint(asfloat(r2.xy) * bumpiness);
	r2.xy = asint(asfloat(r2.xy) + asfloat(r2.xy));
	r1.zw = asint(asfloat(r1.zw) * float2(2, 2) + -(asfloat(r2.xy)));
	r3 = WrinkleMaskSampler_0_tex.Sample(WrinkleMaskSampler_0, i.texcoord.xy);
	r0.w = asint(dot(wrinkleMaskStrengths0, r3));
	r2.z = asint(dot(wrinkleMaskStrengths2, r3));
	r3 = WrinkleMaskSampler_1_tex.Sample(WrinkleMaskSampler_1, i.texcoord.xy);
	r2.w = asint(dot(wrinkleMaskStrengths1, r3));
	r3.x = dot(wrinkleMaskStrengths3, r3);
	r2.z = asint(asfloat(r2.z) + r3.x);
	r0.w = asint(asfloat(r0.w) + asfloat(r2.w));
	r1.zw = asint(asfloat(r0.ww) * asfloat(r1.zw) + asfloat(r2.xy));
	r1.xy = asint(asfloat(r1.xy) * float2(2, 2) + -(asfloat(r1.zw)));
	r1.xy = asint(asfloat(r2.zz) * asfloat(r1.xy) + asfloat(r1.zw));
	r0.w = asint(dot(asfloat(r1.xy), asfloat(r1.xy)));
	r0.w = asint(-(asfloat(r0.w)) + 1);
	r0.w = asint(max(asfloat(r0.w), 0));
	r1.z = asint(sqrt(asfloat(r0.w)));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r1.xyz = asint(asfloat(r0.www) * asfloat(r1.xyz));
	r2.xyz = asint(asfloat(r1.xxx) * i.texcoord4.xyz);
	r1.xzw = asint(i.texcoord1.xyz * asfloat(r1.zzz) + asfloat(r2.xyz));
	r1.xyz = asint(i.texcoord5.xyz * asfloat(r1.yyy) + asfloat(r1.xzw));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r1.xyz = asint(asfloat(r0.www) * asfloat(r1.xyz));
	r0.w = asint(dot(asfloat(r1.xyz), -(gDirectionalLight.xyz)));
	r1.w = asint(saturate(asfloat(r0.w) * 2 + -0.5));
	r0.w = asint(saturate(asfloat(r0.w) + -0.25));
	r0.w = asint(asfloat(r0.w) * 1.33333337);
	r2.xyz = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r2.xyz = asint(asfloat(r2.www) * asfloat(r2.xyz));
	r2.w = asint(dot(-(asfloat(r2.xyz)), asfloat(r1.xyz)));
	r2.w = asint(asfloat(r2.w) + asfloat(r2.w));
	r2.xyz = asint(asfloat(r1.xyz) * -(asfloat(r2.www)) + -(asfloat(r2.xyz)));
	r2.w = asint(saturate(dot(-(gDirectionalLight.xyz), asfloat(r2.xyz))));
	r2.w = asint(asfloat(r2.w) + 0.00000999999975);
	r2.w = asint(log2(asfloat(r2.w)));
	r3 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r3.w = dot(r3, specMapExpMask);
	r3.x = dot(r3.xyz, specMapIntMask.xyz);
	r3.y = r3.w * specularFactor;
	r3.y = max(r3.y, 1);
	r3.z = r3.y + 0.00000999999975;
	r3.y = r3.y * 0.25 + 0.00000999999975;
	r2.w = asint(asfloat(r2.w) * r3.z);
	r2.w = asint(exp2(asfloat(r2.w)));
	r1.w = asint(asfloat(r1.w) * asfloat(r2.w));
	r4 = asfloat(r0.xyz) * asfloat(r1.www);
	r5 = -(i.texcoord2.x) + gLightPosX;
	r6 = r5 * r5;
	r7 = -(i.texcoord2.y) + gLightPosY;
	r6 = r7 * r7 + r6;
	r8 = -(i.texcoord2.z) + gLightPosZ;
	r6 = r8 * r8 + r6;
	r9 = r6 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r6 = saturate(-(r6) * gLightFallOff + float4(1, 1, 1, 1));
	r6 = r6 * r6;
	r6 = r6 * r6 + float4(-0.100000001, -0.100000001, -0.100000001, -0.100000001);
	r6 = max(r6, float4(0, 0, 0, 0));
	r6 = r6 * float4(1.11111116, 1.11111116, 1.11111116, 1.11111116);
	r9 = rsqrt(r9);
	r5 = r5 * r9;
	r10 = asfloat(r1.x) * r5;
	r7 = r7 * r9;
	r8 = r8 * r9;
	r9 = r7 * asfloat(r1.y) + r10;
	r9 = r8 * asfloat(r1.z) + r9;
	r1.x = asint(saturate(asfloat(r1.z) * -0.5 + 0.5));
	r6 = saturate(r6 * r9);
	r9 = r5 * -(gLightDirX);
	r5 = asfloat(r2.x) * r5;
	r5 = asfloat(r2.y) * r7 + r5;
	r2 = asint(saturate(asfloat(r2.z) * r8 + r5));
	r2 = asint(asfloat(r2) + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2 = asint(log2(asfloat(r2)));
	r2 = asint(asfloat(r2) * r3.y);
	r2 = asint(exp2(asfloat(r2)));
	r5 = r7 * -(gLightDirY) + r9;
	r5 = r8 * -(gLightDirZ) + r5;
	r5 = saturate(r5 * gLightConeScale + gLightConeOffset);
	r5 = r6 * r5;
	r2 = asint(asfloat(r2) * r5);
	r6.x = dot(gLightColR, asfloat(r2));
	r6.y = dot(gLightColG, asfloat(r2));
	r6.z = dot(gLightColB, asfloat(r2));
	r1.yzw = asint(r4.xyz * gDirectionalLight.www + r6.xyz);
	r1.yzw = asint(r3.xxx * asfloat(r1.yzw));
	r2.xyz = asint(-(gLightAmbient0.xyz) + gLightAmbient1.xyz);
	r2.xyz = asint(asfloat(r1.xxx) * asfloat(r2.xyz) + gLightAmbient0.xyz);
	r2.xyz = asint(asfloat(r2.xyz) * gAmbientOcclusionEffect.yyy);
	r1.x = asint(saturate(-(AmbientLightingParams.x) * 0.150000006 + 1));
	r1.x = asint(asfloat(r1.x) + 0.200000003);
	r1.x = asint(min(asfloat(r1.x), 1));
	r1.x = asint(asfloat(r1.x) * AmbientLightingParams.y);
	r1.x = asint(i.texcoord7.x * asfloat(r1.x) + -(i.texcoord7.x));
	r1.x = asint(gAmbientOcclusionEffect.x * asfloat(r1.x) + i.texcoord7.x);
	r2.xyz = asint(asfloat(r1.xxx) * asfloat(r2.xyz));
	r2.xyz = asint(asfloat(r2.xyz) / gAmbientOcclusionEffect.yyy);
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r0.www) + asfloat(r2.xyz));
	r2.x = asint(dot(gLightColR, r5));
	r2.y = asint(dot(gLightColG, r5));
	r2.z = asint(dot(gLightColB, r5));
	r0.xyz = asint(asfloat(r0.xyz) + asfloat(r2.xyz));
	r2 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r2.xyz = asint(asfloat(r2.xyz) * asfloat(r2.xyz));
	r0.w = asint(asfloat(r2.w) * i.texcoord7.w);
	o.w = asfloat(r0.w) * globalScalars.x;
	r0.xyz = asint(asfloat(r2.xyz) * asfloat(r0.xyz) + asfloat(r1.yzw));
	r0.xyz = asint(asfloat(r0.xyz) * matMaterialColorScale.xxx);
	r0.xyz = asint(saturate(asfloat(r0.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.xyz = sqrt(asfloat(r0.xyz));

	return o;
}
