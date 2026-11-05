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

cbuffer CacheVehicleParams : register(b4)
{
	float3 matDiffuseColor : packoffset(c0);
};

cbuffer VehicleMaterial : register(b9)
{
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float3 specMapIntMask : packoffset(c1);
	float4 specMapExpMask : packoffset(c2);
};

SamplerState DiffuseSampler : register(s0);
SamplerState SpecSampler : register(s2);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D SpecSampler_tex : register(t2);
Texture2D ShadowZTextureDir : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float4 texcoord6 : TEXCOORD6;
	float sv_clipdistance : SV_ClipDistance;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	int4 r1;
	int4 r2;
	float3 r3;
	float3 r4;
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
	r1.xyz = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r1.xyz = asint(asfloat(r0.www) * asfloat(r1.xyz));
	r2.xyz = asint(i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r2.xyz = asint(asfloat(r0.www) * asfloat(r2.xyz));
	r0.w = asint(dot(-(asfloat(r1.xyz)), asfloat(r2.xyz)));
	r0.w = asint(asfloat(r0.w) + asfloat(r0.w));
	r1.xyz = asint(asfloat(r2.xyz) * -(asfloat(r0.www)) + -(asfloat(r1.xyz)));
	r0.w = asint(saturate(dot(-(gDirectionalLight.xyz), asfloat(r1.xyz))));
	r0.w = asint(asfloat(r0.w) + 0.00000999999975);
	r0.w = asint(log2(asfloat(r0.w)));
	r1 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r1.w = asint(dot(asfloat(r1), specMapExpMask));
	r1.x = asint(dot(asfloat(r1.xyz), specMapIntMask.xyz));
	r1.xy = asint(asfloat(r1.xw) * float2(specularColorFactor, specularFactor));
	r1.y = asint(max(asfloat(r1.y), 1));
	r1.y = asint(asfloat(r1.y) + 0.00000999999975);
	r0.w = asint(asfloat(r0.w) * asfloat(r1.y));
	r0.w = asint(exp2(asfloat(r0.w)));
	r1.y = asint(dot(asfloat(r2.xyz), -(gDirectionalLight.xyz)));
	r1.z = asint(saturate(asfloat(r2.z) * -0.5 + 0.5));
	r1.w = asint(saturate(asfloat(r1.y) * 2 + -0.5));
	r1.y = asint(saturate(asfloat(r1.y) + -0.25));
	r1.y = asint(asfloat(r1.y) * 1.33333337);
	r0.w = asint(asfloat(r0.w) * asfloat(r1.w));
	r2.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r2.xyz = asint(asfloat(r2.xyz) * gDirectionalLight.www);
	r2.xyz = asint(asfloat(r1.xxx) * asfloat(r2.xyz));
	r3 = -(gLightAmbient0.xyz) + gLightAmbient1.xyz;
	r1.xzw = asint(asfloat(r1.zzz) * r3.xyz + gLightAmbient0.xyz);
	r1.xzw = asint(asfloat(r1.xzw) * gAmbientOcclusionEffect.yyy);
	r0.w = asint(dot(i.texcoord6.xyz, float3(0.212500006, 0.715399981, 0.0720999986)));
	r2.w = asint(globalScalars.z * gAmbientOcclusionEffect.y);
	r0.w = asint(asfloat(r0.w) * asfloat(r2.w));
	r1.xzw = asint(asfloat(r0.www) * asfloat(r1.xzw));
	r1.xzw = asint(asfloat(r1.xzw) / gAmbientOcclusionEffect.yyy);
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r1.yyy) + asfloat(r1.xzw));
	r1 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r3 = asfloat(r1.xyz) * asfloat(r1.xyz);
	r1.xyz = asint(r3.xyz * matDiffuseColor.xyz);
	r1 = asint(asfloat(r1) * i.texcoord6);
	r0.xyz = asint(asfloat(r1.xyz) * asfloat(r0.xyz) + asfloat(r2.xyz));
	o.w = asfloat(r1.w) * globalScalars.x;
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.w = asint(asfloat(r0.w) + 0.00000999999975);
	r0.w = asint(abs(asfloat(r0.w)) + 0.00000999999975);
	r0.w = asint(log2(asfloat(r0.w)));
	r1.x = asint(saturate(-(i.texcoord1.w) * gDepthFxParams.z + gDepthFxParams.w));
	r1.y = asint(-(asfloat(r1.x)) + 1);
	r1.x = asint(asfloat(r1.y) * gDepthFxParams.y + asfloat(r1.x));
	r1.x = asint(asfloat(r1.x) + -0.999989986);
	r0.w = asint(asfloat(r0.w) * asfloat(r1.x));
	r0.w = asint(exp2(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r0.www) + -(globalFogColorN.xyz));
	r1.xyz = asint(i.texcoord2.xyz + -(gViewInverse[3].xyz));
	r0.w = asint(asfloat(r1.z) * globalFogParams.x);
	r1.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.x = asint(sqrt(asfloat(r1.x)));
	r1.x = asint(asfloat(r1.x) * globalFogParams.z);
	r1.y = asint(asfloat(r0.w) * -1.44269502);
	r1.y = asint(exp2(asfloat(r1.y)));
	r1.y = asint(-(asfloat(r1.y)) + 1);
	r1.y = asint(asfloat(r1.y) / asfloat(r0.w));
	r0.w = (0.0000999999975 < abs(asfloat(r0.w))) ? -1 : 0;
	r1.y = asint(asfloat(r1.y) * asfloat(r1.x));
	r0.w = (r0.w != 0) ? r1.y : r1.x;
	r0.w = asint(asfloat(r0.w) * -(globalFogParams.y));
	r0.w = asint(asfloat(r0.w) * 1.44269502);
	r0.w = asint(exp2(asfloat(r0.w)));
	r0.w = asint(min(asfloat(r0.w), 1));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz) + globalFogColorN.xyz);
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.xyz = asint(-(asfloat(r0.www)) + asfloat(r0.xyz));
	r1.x = asint(gAdrenoFXVars.x * deSatContrastGamma.x);
	r0.xyz = asint(asfloat(r1.xxx) * asfloat(r0.xyz) + asfloat(r0.www));
	r0.xyz = asint(saturate(asfloat(r0.xyz) * float3(0.000624999986, 0.000624999986, 0.000624999986)));
	o.xyz = sqrt(asfloat(r0.xyz));

	return o;
}
