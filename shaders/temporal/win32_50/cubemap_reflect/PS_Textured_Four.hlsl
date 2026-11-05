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
	float4 gLightAmbientDir0 : packoffset(c14);
	float4 gLightAmbientDir1 : packoffset(c15);
	float4 gLightPointColR : packoffset(c16);
	float4 gLightPointColG : packoffset(c17);
	float4 gLightPointColB : packoffset(c18);
	float4 gLightPointPosX : packoffset(c19);
	float4 gLightPointPosY : packoffset(c20);
	float4 gLightPointPosZ : packoffset(c21);
	float4 gLightDir2X : packoffset(c22);
	float4 gLightDir2Y : packoffset(c23);
	float4 gLightDir2Z : packoffset(c24);
	float4 gLightConeScale2 : packoffset(c25);
	float4 gLightConeOffset2 : packoffset(c26);
	float4 gLightPointFallOff : packoffset(c27);
	float4 gDistFadeParams : packoffset(c28);
	float4 gAdrenoFXVars : packoffset(c29);
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

cbuffer CacheMegaVariables : register(b4)
{
	float reflectivePower : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState EnvironmentSampler : register(s1);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
TextureCube EnvironmentSampler_tex : register(t1);
Texture2D ShadowZTextureDir : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float4 texcoord6 : TEXCOORD6;
	float4 texcoord9 : TEXCOORD9;
	float sv_clipdistance : SV_ClipDistance;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float4 r0;
	int4 r1;
	int4 r2;
	float4 r3;
	float4 r4;
	float4 r5;
	float4 r6;
	r0.xyz = i.texcoord6.yyy * gShadowMatrix[1].xyz;
	r0.xyz = i.texcoord6.xxx * gShadowMatrix[0].xyz + r0.xyz;
	r0.xyz = i.texcoord6.zzz * gShadowMatrix[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + gShadowMatrix[3].xyz;
	r1.xy = asint(r0.xy + -(gShadowParam18192021.zw));
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
	r0.xyz = r0.zxy * r3.zxy + r4.zxy;
	r0.x = saturate(r0.x);
	r0.x = -(r0.x) + 1;
	r0.x = ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, r0.yz, r0.x);
	r2.x = asint(-(gCascadeXMinThresholds.w));
	r2.y = asint(-(gCascadeXMaxThresholds.w));
	r0.yz = saturate(abs(asfloat(r1.xy)) * float2(4, 4) + asfloat(r2.xy));
	r0.y = max(r0.z, r0.y);
	r0.x = r0.y + r0.x;
	r0.x = min(r0.x, 1);
	r0.xyz = r0.xxx * gDirectionalColour.xyz;
	r1.xyz = asint(-(gLightAmbient0.xyz) + gLightAmbient1.xyz);
	r2.xyz = asint(i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = dot(asfloat(r2.xyz), asfloat(r2.xyz));
	r0.w = rsqrt(r0.w);
	r2.xyz = asint(r0.www * asfloat(r2.xyz));
	r0.w = saturate(asfloat(r2.z) * -0.5 + 0.5);
	r1.xyz = asint(r0.www * asfloat(r1.xyz) + gLightAmbient0.xyz);
	r1.xyz = asint(asfloat(r1.xyz) * gAmbientOcclusionEffect.yyy);
	r1.xyz = asint(asfloat(r1.xyz) * i.color.xxx);
	r1.xyz = asint(asfloat(r1.xyz) / gAmbientOcclusionEffect.yyy);
	r0.w = dot(asfloat(r2.xyz), -(gDirectionalLight.xyz));
	r0.w = saturate(r0.w + -0.25);
	r0.w = r0.w * 1.33333337;
	r0.xyz = r0.xyz * r0.www + asfloat(r1.xyz);
	r1 = asint(-(i.texcoord6.x) + gLightPosX);
	r3 = asfloat(r2.x) * asfloat(r1);
	r4 = -(i.texcoord6.y) + gLightPosY;
	r3 = r4 * asfloat(r2.y) + r3;
	r5 = -(i.texcoord6.z) + gLightPosZ;
	r3 = r5 * asfloat(r2.z) + r3;
	r6 = asfloat(r1) * asfloat(r1);
	r1 = asint(asfloat(r1) * -(gLightDirX));
	r1 = asint(r4 * -(gLightDirY) + asfloat(r1));
	r4 = r4 * r4 + r6;
	r4 = r5 * r5 + r4;
	r1 = asint(r5 * -(gLightDirZ) + asfloat(r1));
	r5 = -(r4) * gLightFallOff + float4(1, 1, 1, 1);
	r4 = r4 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r4 = rsqrt(r4);
	r5 = max(r5, float4(0, 0, 0, 0));
	r5 = r5 * r5;
	r5 = r5 * r5 + float4(-0.100000001, -0.100000001, -0.100000001, -0.100000001);
	r5 = max(r5, float4(0, 0, 0, 0));
	r5 = r5 * float4(1.11111116, 1.11111116, 1.11111116, 1.11111116);
	r3 = r3 * r5;
	r3 = saturate(r4 * r3);
	r1 = asint(asfloat(r1) * r4);
	r1 = asint(saturate(asfloat(r1) * gLightConeScale + gLightConeOffset));
	r1 = asint(r3 * asfloat(r1));
	r3.x = dot(gLightColR, asfloat(r1));
	r3.y = dot(gLightColG, asfloat(r1));
	r3.z = dot(gLightColB, asfloat(r1));
	r0.xyz = r0.xyz + r3.xyz;
	r0.w = dot(r0.xyz, float3(0.333333343, 0.333333343, 0.333333343));
	r0.w = r0.w + 0.0149999997;
	r1.xyz = asint(i.texcoord3.xzy + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r1.w = asint(dot(-(asfloat(r1.xzy)), asfloat(r2.xyz)));
	r1.w = asint(asfloat(r1.w) + asfloat(r1.w));
	r1.xyz = asint(asfloat(r2.xzy) * -(asfloat(r1.www)) + -(asfloat(r1.xyz)));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r1.xyz = asint(EnvironmentSampler_tex.Sample(EnvironmentSampler, asfloat(r1.xyz)).xyz);
	r1.xyz = asint(asfloat(r1.xyz) * reflectivePower);
	r1.xyz = asint(asfloat(r1.xyz) * globalScalars.www);
	r2 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r1.w = asint(asfloat(r2.w) * i.color.w);
	r2.xyz = asint(asfloat(r2.xyz) * asfloat(r2.xyz));
	r2.w = asint(max(asfloat(r1.w), 0.00999999978));
	r3.w = asfloat(r1.w) * globalScalars.x;
	r1.w = asint(1 / asfloat(r2.w));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r1.xyz = asint(r0.www * asfloat(r1.xyz));
	r0.xyz = asfloat(r2.xyz) * r0.xyz + asfloat(r1.xyz);
	r0.w = dot(r0.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r0.w = r0.w + 0.00000999999975;
	r0.w = abs(r0.w) + 0.00000999999975;
	r0.w = log2(r0.w);
	r1.x = asint(i.texcoord9.y + 0.00000999999975);
	r0.w = r0.w * asfloat(r1.x);
	r0.w = exp2(r0.w);
	r1.xyz = asint(r0.www * r0.xyz);
	r0.xyz = -(r0.xyz) * r0.www + globalFogColorN.xyz;
	r0.xyz = i.texcoord9.xxx * r0.xyz + asfloat(r1.xyz);
	r0.w = dot(r0.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r0.xyz = -(r0.www) + r0.xyz;
	r1.x = asint(gAdrenoFXVars.x * deSatContrastGamma.x);
	r3.xyz = asfloat(r1.xxx) * r0.xyz + r0.www;
	o = min(r3, float4(8, 8, 8, 1));

	return o;
}
