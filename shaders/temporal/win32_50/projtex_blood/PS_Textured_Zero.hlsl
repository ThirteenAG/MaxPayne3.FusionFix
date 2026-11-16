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
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
	float reflectivePower : packoffset(c0.w);
	float fresnelRolloff : packoffset(c1);
};

cbuffer EnvBlood : register(b7)
{
	float4 EnvBloodData : packoffset(c0);
};

SamplerState EnvBloodSampler : register(s2);
SamplerState DynamicEnvironmentSampler : register(s13);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D EnvBloodSampler_tex : register(t2);
Texture2D DynamicEnvironmentSampler_tex : register(t13);
Texture2D ShadowZTextureDir : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float2 texcoord7 : TEXCOORD7;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float4 texcoord9 : TEXCOORD9;
	float sv_clipdistance : SV_ClipDistance;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float4 r0;
	int4 r1;
	float4 r2;
	int4 r3;
	float4 r4;
	int4 r5;
	int4 r6;
	int3 r7;
	float3 r8;
	r0.xyz = i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r1.x = (0 < EnvBloodData.w) ? -1 : 0;
	if (r1.x != 0) {
		r1.yzw = asint(EnvBloodSampler_tex.Sample(EnvBloodSampler, float2(0, 0)).wxy);
		r2.xyz = asfloat(r1.zww);
	} else {
		r2.xyz = float3(0, 0, 0);
		r1.y = 0;
	}
	r0.xyz = r0.xyz * r0.www + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r3.xyz = asint(r0.www * r0.xyz);
	r2.w = max(specularFactor, 1);
	r3.w = (0 < reflectivePower) ? -1 : 0;
	if (r3.w != 0) {
		r3.w = asint(r2.w * 0.015625);
		r3.w = asint(min(asfloat(r3.w), 1));
		r3.w = asint(-(asfloat(r3.w)) * 4 + 4);
		r4.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r4.w = dot(r4.xyz, r4.xyz);
		r4.w = rsqrt(r4.w);
		r4.xyz = r4.www * r4.xyz;
		r4.w = dot(-(r4.xyz), asfloat(r3.xyz));
		r4.w = r4.w + r4.w;
		r5.xyz = asint(asfloat(r3.xyz) * -(r4.www) + -(r4.xyz));
		r5.xyz = asint(asfloat(r5.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r4.w = dot(asfloat(r5.xyz), asfloat(r5.xyz));
		r4.w = rsqrt(r4.w);
		r5.xyz = asint(r4.www * asfloat(r5.zxy));
		r5.x = asint(saturate(asfloat(r5.x)));
		r4.w = asfloat(r5.x) + 1;
		r4.w = r4.w + r4.w;
		r5.xy = asint(asfloat(r5.yz) / r4.ww);
		r5.xy = asint(asfloat(r5.xy) + float2(0.5, 0.5));
		r5.xy = asint(-(asfloat(r5.xy)) + float2(1, 1));
		r5.xyz = asint(DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, asfloat(r5.xy), asfloat(r3.w)).xyz);
		r5.xyz = asint(asfloat(r5.xyz) * asfloat(r5.xyz));
		r5.xyz = asint(asfloat(r5.xyz) * float3(16, 16, 16));
		r3.x = asint(saturate(dot(r4.xyz, asfloat(r3.xyz))));
		r3.y = asint(-(fresnelRolloff) + 1);
		r3.x = asint(-(asfloat(r3.x)) + 1.00001001);
		r3.z = asint(asfloat(r3.x) * asfloat(r3.x));
		r3.z = asint(asfloat(r3.z) * asfloat(r3.z));
		r3.x = asint(asfloat(r3.z) * asfloat(r3.x));
		r3.x = asint(fresnelRolloff * asfloat(r3.x) + asfloat(r3.y));
		r3.xyz = asint(asfloat(r3.xxx) * asfloat(r5.xyz));
	} else {
		r3.xyz = int3(0, 0, 0);
	}
	r3.xyz = asint(asfloat(r3.xyz) * reflectivePower);
	r3.xyz = asint(asfloat(r3.xyz) * globalScalars.www);
	if (r1.x != 0) {
		r4.xyz = EnvBloodSampler_tex.Sample(EnvBloodSampler, i.texcoord7).xyw;
		r5.xy = asint(saturate(i.texcoord7.xy));
		r1.x = asint(asfloat(r5.y) + asfloat(r5.x));
		r1.x = asint(asfloat(r1.x) + -(i.texcoord7.x));
		r1.x = asint(asfloat(r1.x) + -(i.texcoord7.y));
		r1.x = (0.00100000005 >= abs(asfloat(r1.x))) ? -1 : 0;
		r1.x = r1.x & 1065353216;
		r1.yzw = asint(asfloat(r1.xxx) * r4.zxy);
		r1.x = asint(asfloat(r1.z) * 0.00100000005);
		r4.xyz = asfloat(r1.zww);
	} else {
		r4.xyz = r2.xyz * r2.xyz;
		r1.x = 0;
	}
	r1.x = asint(asfloat(r1.x) + specularColorFactor);
	r0.xyz = r0.xyz * r0.www + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r0.w = asfloat(r1.y) * i.color.w;
	r1.yzw = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.x = dot(asfloat(r1.yzw), asfloat(r1.yzw));
	r2.x = rsqrt(r2.x);
	r1.yzw = asint(asfloat(r1.yzw) * r2.xxx);
	r2.x = saturate(r0.z * -0.5 + 0.5);
	r5.xyz = asint(-(gLightAmbient0.xyz) + gLightAmbient1.xyz);
	r2.xyz = r2.xxx * asfloat(r5.xyz) + gLightAmbient0.xyz;
	r2.xyz = r2.xyz * gAmbientOcclusionEffect.yyy;
	r2.xyz = r2.xyz * i.color.xxx;
	r2.xyz = r2.xyz / gAmbientOcclusionEffect.yyy;
	r3.w = asint(dot(-(asfloat(r1.yzw)), r0.xyz));
	r3.w = asint(asfloat(r3.w) + asfloat(r3.w));
	r1.yzw = asint(r0.xyz * -(asfloat(r3.www)) + -(asfloat(r1.yzw)));
	r0.x = dot(r0.xyz, -(gDirectionalLight.xyz));
	r0.y = saturate(r0.x + -0.25);
	r0.y = r0.y * 1.33333337;
	r0.z = saturate(dot(-(gDirectionalLight.xyz), asfloat(r1.yzw)));
	r0.z = r0.z + 0.00000999999975;
	r1.y = asint(r2.w + 0.00000999999975);
	r0.z = log2(r0.z);
	r0.z = r0.z * asfloat(r1.y);
	r0.z = exp2(r0.z);
	r0.x = saturate(r0.x * 2 + -0.5);
	r0.x = r0.x * r0.z;
	r1.yzw = asint(i.texcoord6.yyy * gShadowMatrix[1].xyz);
	r1.yzw = asint(i.texcoord6.xxx * gShadowMatrix[0].xyz + asfloat(r1.yzw));
	r1.yzw = asint(i.texcoord6.zzz * gShadowMatrix[2].xyz + asfloat(r1.yzw));
	r1.yzw = asint(asfloat(r1.yzw) + gShadowMatrix[3].xyz);
	r5.xy = asint(asfloat(r1.yz) + -(gShadowParam18192021.zw));
	r5.zw = (asfloat(r5.xx) >= gCascadeXMaxThresholds.xy) ? -1 : 0;
	r5.zw = r5.zw & int2(1065353216, 1065353216);
	r6.xy = (gCascadeXMinThresholds.xy >= asfloat(r5.xx)) ? -1 : 0;
	r6.zw = (asfloat(r5.yy) >= gCascadeYMaxThresholds.xy) ? -1 : 0;
	r6 = r6 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r7.xy = (gCascadeYMinThresholds.xy >= asfloat(r5.yy)) ? -1 : 0;
	r7.xy = r7.xy & int2(1065353216, 1065353216);
	r5.zw = asint(asfloat(r5.zw) + asfloat(r6.xy));
	r5.zw = asint(asfloat(r6.zw) + asfloat(r5.zw));
	r5.zw = asint(asfloat(r7.xy) + asfloat(r5.zw));
	r6.yz = asint(min(asfloat(r5.zw), float2(1, 1)));
	r6.x = 1065353216;
	r7.x = asint(dot(asfloat(r6.xyz), gShadowParam0123.xyz));
	r7.y = asint(dot(asfloat(r6.xyz), gShadowParam4567.xyz));
	r7.z = asint(dot(asfloat(r6.xyz), gCascadeZScales.xyz));
	r8.x = dot(asfloat(r6.xyz), gShadowParam891113.xyz);
	r8.y = dot(asfloat(r6.xyz), gShadowParam14151617.xyz);
	r8.z = dot(asfloat(r6.xyz), gCascadeZOffsets.xyz);
	r1.yzw = asint(asfloat(r1.wyz) * asfloat(r7.zxy) + r8.zxy);
	r1.y = asint(saturate(asfloat(r1.y)));
	r6.x = asint(-(gCascadeXMinThresholds.w));
	r6.y = asint(-(gCascadeXMaxThresholds.w));
	r5.xy = asint(saturate(abs(asfloat(r5.xy)) * float2(4, 4) + asfloat(r6.xy)));
	r0.z = max(asfloat(r5.y), asfloat(r5.x));
	r1.y = asint(-(asfloat(r1.y)) + 1);
	r1.y = asint(ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, asfloat(r1.zw), asfloat(r1.y)));
	r0.z = r0.z + asfloat(r1.y);
	r0.z = min(r0.z, 1);
	r1.yzw = asint(r0.zzz * gDirectionalColour.xyz);
	r5.xyz = asint(r0.xxx * asfloat(r1.yzw));
	r5.xyz = asint(asfloat(r5.xyz) * gDirectionalLight.www);
	r0.xyz = asfloat(r1.yzw) * r0.yyy + r2.xyz;
	r1.y = asint(max(r0.w, 0.00999999978));
	r1.y = asint(1 / asfloat(r1.y));
	r1.yzw = asint(asfloat(r1.yyy) * asfloat(r3.xyz));
	r2.x = dot(r0.xyz, float3(0.333333343, 0.333333343, 0.333333343));
	r2.x = r2.x + 0.0149999997;
	r1.yzw = asint(asfloat(r1.yzw) * r2.xxx);
	r1.xyz = asint(asfloat(r5.xyz) * asfloat(r1.xxx) + asfloat(r1.yzw));
	r0.xyz = r4.xyz * r0.xyz + asfloat(r1.xyz);
	r1.w = asint(r0.w * globalScalars.x);
	r0.w = dot(r0.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r0.w = r0.w + 0.00000999999975;
	r0.w = abs(r0.w) + 0.00000999999975;
	r2.x = i.texcoord9.y + 0.00000999999975;
	r0.w = log2(r0.w);
	r0.w = r0.w * r2.x;
	r0.w = exp2(r0.w);
	r2.xyz = r0.www * r0.xyz;
	r0.xyz = -(r0.xyz) * r0.www + globalFogColorN.xyz;
	r0.xyz = i.texcoord9.xxx * r0.xyz + r2.xyz;
	r0.w = dot(r0.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r2.x = gAdrenoFXVars.x * deSatContrastGamma.x;
	r0.xyz = -(r0.www) + r0.xyz;
	r1.xyz = asint(r2.xxx * r0.xyz + r0.www);
	o = min(asfloat(r1), float4(8, 8, 8, 1));

	return o;
}
