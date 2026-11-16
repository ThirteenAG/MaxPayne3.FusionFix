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
	float4 matDiffuseColor2 : packoffset(c1);
	float emissiveMultiplier : packoffset(c2);
};

cbuffer VehicleMaterial : register(b9)
{
	float dirtLevel : packoffset(c0);
	float3 dirtColor : packoffset(c0.y);
	float specularFactor : packoffset(c1);
	float specularColorFactor : packoffset(c1.y);
	float3 specMapIntMask : packoffset(c2);
	float4 specMapExpMask : packoffset(c3);
	float reflectivePower : packoffset(c4);
	float fresnelRolloff : packoffset(c4.y);
};

SamplerState DiffuseSampler : register(s0);
SamplerState DirtSampler : register(s2);
SamplerState SpecSampler : register(s3);
SamplerState EnvironmentSampler : register(s4);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D DirtSampler_tex : register(t2);
Texture2D SpecSampler_tex : register(t3);
Texture2D EnvironmentSampler_tex : register(t4);
Texture2D ShadowZTextureDir : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord7 : TEXCOORD7;
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
	int4 r3;
	float4 r4;
	float4 r5;
	int4 r6;
	int4 r7;
	float3 r8;
	r0 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).wxyz);
	r1.xyz = asint(i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r2 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r1.w = asint(dot(asfloat(r2), specMapExpMask));
	r1.w = asint(asfloat(r1.w) * specularFactor);
	r2.x = asint(dot(asfloat(r2.xyz), specMapIntMask.xyz));
	r2.x = asint(saturate(asfloat(r2.x) * specularColorFactor));
	r1.w = asint(max(asfloat(r1.w), 1));
	r2.yzw = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r3.x = asint(dot(asfloat(r2.yzw), asfloat(r2.yzw)));
	r3.x = asint(rsqrt(asfloat(r3.x)));
	r2.yzw = asint(asfloat(r2.yzw) * asfloat(r3.xxx));
	r3.x = asint(dot(-(asfloat(r2.yzw)), asfloat(r1.xyz)));
	r3.x = asint(asfloat(r3.x) + asfloat(r3.x));
	r3.xyz = asint(asfloat(r1.xyz) * -(asfloat(r3.xxx)) + -(asfloat(r2.yzw)));
	r4.xyz = asfloat(r3.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r3.w = asint(dot(r4.xyz, r4.xyz));
	r3.w = asint(rsqrt(asfloat(r3.w)));
	r4.xyz = asfloat(r3.www) * r4.zxy;
	r4.x = saturate(r4.x);
	r3.w = asint(r4.x + 1);
	r3.w = asint(asfloat(r3.w) + asfloat(r3.w));
	r4.xy = r4.yz / asfloat(r3.ww);
	r4.xy = r4.xy + float2(0.5, 0.5);
	r4.xy = -(r4.xy) + float2(1, 1);
	r4.xyz = EnvironmentSampler_tex.SampleLevel(EnvironmentSampler, r4.xy, 0).xyz;
	r4.xyz = r4.xyz * r4.xyz;
	r4.xyz = r4.xyz * float3(16, 16, 16);
	r2.y = asint(saturate(dot(asfloat(r2.yzw), asfloat(r1.xyz))));
	r2.z = asint(-(fresnelRolloff) + 1);
	r2.y = asint(-(asfloat(r2.y)) + 1.00001001);
	r2.w = asint(asfloat(r2.y) * asfloat(r2.y));
	r2.w = asint(asfloat(r2.w) * asfloat(r2.w));
	r2.y = asint(asfloat(r2.w) * asfloat(r2.y));
	r2.y = asint(fresnelRolloff * asfloat(r2.y) + asfloat(r2.z));
	r4.xyz = asfloat(r2.yyy) * r4.xyz;
	r4.xyz = r4.xyz * reflectivePower;
	r4.xyz = r4.xyz * globalFogColorN.www;
	r5.xyz = asfloat(r0.yzw) * asfloat(r0.yzw);
	r0.yzw = asint(r5.xyz * matDiffuseColor.xyz);
	r5 = asfloat(r0.yzwx) * i.texcoord6;
	r2.z = asint(globalScalars.z * gAmbientOcclusionEffect.y);
	r2.w = (0 < dirtLevel) ? -1 : 0;
	if (r2.w != 0) {
		r2.w = asint(DirtSampler_tex.Sample(DirtSampler, i.texcoord7).x);
		r3.w = (0 < asfloat(r2.w)) ? -1 : 0;
		r4.w = asfloat(r2.w) * dirtLevel;
		r6.x = asint(-(asfloat(r2.w)) * dirtLevel + 1);
		r7.xyz = asint(r4.www * dirtColor.xyz);
		r6.yzw = asint(asfloat(r0.yzw) * asfloat(r6.xxx) + asfloat(r7.xyz));
		r0.x = 1065353216;
		r0 = (r3.w != 0) ? r6 : r0;
	} else {
		r0.x = 1065353216;
	}
	r0.x = asint(asfloat(r0.x) * asfloat(r2.x));
	r2.x = asint(saturate(asfloat(r1.z) * -0.5 + 0.5));
	r6.xyz = asint(-(gLightAmbient0.xyz) + gLightAmbient1.xyz);
	r6.xyz = asint(asfloat(r2.xxx) * asfloat(r6.xyz) + gLightAmbient0.xyz);
	r6.xyz = asint(asfloat(r6.xyz) * gAmbientOcclusionEffect.yyy);
	r2.xzw = asint(asfloat(r2.zzz) * asfloat(r6.xyz));
	r2.xzw = asint(asfloat(r2.xzw) / gAmbientOcclusionEffect.yyy);
	r1.x = asint(dot(asfloat(r1.xyz), -(gDirectionalLight.xyz)));
	r1.y = asint(saturate(asfloat(r1.x) + -0.25));
	r1.y = asint(asfloat(r1.y) * 1.33333337);
	r1.z = asint(saturate(dot(-(gDirectionalLight.xyz), asfloat(r3.xyz))));
	r1.z = asint(asfloat(r1.z) + 0.00000999999975);
	r1.w = asint(asfloat(r1.w) + 0.00000999999975);
	r1.z = asint(log2(asfloat(r1.z)));
	r1.z = asint(asfloat(r1.z) * asfloat(r1.w));
	r1.z = asint(exp2(asfloat(r1.z)));
	r1.x = asint(saturate(asfloat(r1.x) * 2 + -0.5));
	r1.x = asint(asfloat(r1.x) * asfloat(r1.z));
	r3.xyz = asint(i.texcoord2.yyy * gShadowMatrix[1].xyz);
	r3.xyz = asint(i.texcoord2.xxx * gShadowMatrix[0].xyz + asfloat(r3.xyz));
	r3.xyz = asint(i.texcoord2.zzz * gShadowMatrix[2].xyz + asfloat(r3.xyz));
	r3.xyz = asint(asfloat(r3.xyz) + gShadowMatrix[3].xyz);
	r1.zw = asint(asfloat(r3.xy) + -(gShadowParam18192021.zw));
	r6.xy = (asfloat(r1.zz) >= gCascadeXMaxThresholds.xy) ? -1 : 0;
	r6.zw = (gCascadeXMinThresholds.xy >= asfloat(r1.zz)) ? -1 : 0;
	r6 = r6 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r7.xy = (asfloat(r1.ww) >= gCascadeYMaxThresholds.xy) ? -1 : 0;
	r7.zw = (gCascadeYMinThresholds.xy >= asfloat(r1.ww)) ? -1 : 0;
	r7 = r7 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r6.xy = asint(asfloat(r6.zw) + asfloat(r6.xy));
	r6.xy = asint(asfloat(r7.xy) + asfloat(r6.xy));
	r6.xy = asint(asfloat(r7.zw) + asfloat(r6.xy));
	r6.yz = asint(min(asfloat(r6.xy), float2(1, 1)));
	r6.x = 1065353216;
	r7.x = asint(dot(asfloat(r6.xyz), gShadowParam0123.xyz));
	r7.y = asint(dot(asfloat(r6.xyz), gShadowParam4567.xyz));
	r7.z = asint(dot(asfloat(r6.xyz), gCascadeZScales.xyz));
	r8.x = dot(asfloat(r6.xyz), gShadowParam891113.xyz);
	r8.y = dot(asfloat(r6.xyz), gShadowParam14151617.xyz);
	r8.z = dot(asfloat(r6.xyz), gCascadeZOffsets.xyz);
	r3.xyz = asint(asfloat(r3.zxy) * asfloat(r7.zxy) + r8.zxy);
	r3.x = asint(saturate(asfloat(r3.x)));
	r6.x = asint(-(gCascadeXMinThresholds.w));
	r6.y = asint(-(gCascadeXMaxThresholds.w));
	r1.zw = asint(saturate(abs(asfloat(r1.zw)) * float2(4, 4) + asfloat(r6.xy)));
	r1.z = asint(max(asfloat(r1.w), asfloat(r1.z)));
	r1.w = asint(-(asfloat(r3.x)) + 1);
	r1.w = asint(ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, asfloat(r3.yz), asfloat(r1.w)));
	r1.z = asint(asfloat(r1.z) + asfloat(r1.w));
	r1.z = asint(min(asfloat(r1.z), 1));
	r3.xyz = asint(asfloat(r1.zzz) * gDirectionalColour.xyz);
	r1.xzw = asint(asfloat(r1.xxx) * asfloat(r3.xyz));
	r1.xzw = asint(asfloat(r1.xzw) * gDirectionalLight.www);
	r2.xzw = asint(asfloat(r3.xyz) * asfloat(r1.yyy) + asfloat(r2.xzw));
	r2.y = asint(saturate(asfloat(r2.y)));
	r3.xyz = asint(asfloat(r2.yyy) * r4.xyz);
	r1.y = asint(dot(asfloat(r2.xzw), float3(0.333333343, 0.333333343, 0.333333343)));
	r1.y = asint(asfloat(r1.y) + 0.0149999997);
	r3.xyz = asint(asfloat(r1.yyy) * asfloat(r3.xyz));
	r1.xyz = asint(asfloat(r1.xzw) * asfloat(r0.xxx) + asfloat(r3.xyz));
	r0.xyz = asint(asfloat(r0.yzw) * asfloat(r2.xzw) + asfloat(r1.xyz));
	r0.xyz = asint(r5.xyz * emissiveMultiplier + asfloat(r0.xyz));
	o.w = r5.w * globalScalars.x;
	r1.xyz = asint(i.texcoord2.xyz + -(gViewInverse[3].xyz));
	r0.w = asint(saturate(-(i.texcoord1.w) * gDepthFxParams.z + gDepthFxParams.w));
	r1.w = asint(-(asfloat(r0.w)) + 1);
	r0.w = asint(asfloat(r1.w) * gDepthFxParams.y + asfloat(r0.w));
	r1.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r1.w = asint(asfloat(r1.w) + 0.00000999999975);
	r1.w = asint(abs(asfloat(r1.w)) + 0.00000999999975);
	r0.w = asint(asfloat(r0.w) + -0.999989986);
	r1.w = asint(log2(asfloat(r1.w)));
	r0.w = asint(asfloat(r0.w) * asfloat(r1.w));
	r0.w = asint(exp2(asfloat(r0.w)));
	r1.w = asint(asfloat(r1.z) * globalFogParams.x);
	r1.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.x = asint(sqrt(asfloat(r1.x)));
	r1.x = asint(asfloat(r1.x) * globalFogParams.z);
	r1.y = (0.0000999999975 < abs(asfloat(r1.w))) ? -1 : 0;
	r1.z = asint(asfloat(r1.w) * -1.44269502);
	r1.z = asint(exp2(asfloat(r1.z)));
	r1.z = asint(-(asfloat(r1.z)) + 1);
	r1.z = asint(asfloat(r1.z) / asfloat(r1.w));
	r1.z = asint(asfloat(r1.z) * asfloat(r1.x));
	r1.x = (r1.y != 0) ? r1.z : r1.x;
	r1.x = asint(asfloat(r1.x) * -(globalFogParams.y));
	r1.x = asint(asfloat(r1.x) * 1.44269502);
	r1.x = asint(exp2(asfloat(r1.x)));
	r1.x = asint(min(asfloat(r1.x), 1));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r0.www) + -(globalFogColorN.xyz));
	r0.xyz = asint(asfloat(r1.xxx) * asfloat(r0.xyz) + globalFogColorN.xyz);
	r0.w = asint(gAdrenoFXVars.x * deSatContrastGamma.x);
	r1.x = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.xyz = asint(asfloat(r0.xyz) + -(asfloat(r1.xxx)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz) + asfloat(r1.xxx));
	r0.xyz = asint(saturate(asfloat(r0.xyz) * float3(0.000624999986, 0.000624999986, 0.000624999986)));
	o.xyz = sqrt(asfloat(r0.xyz));

	return o;
}
