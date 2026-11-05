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
	float4 gWaterGlobals : packoffset(c19);
};

cbuffer CacheZShiftandParallax : register(b4)
{
	float parallaxScaleBias : packoffset(c0);
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

cbuffer CacheMegaVariables : register(b7)
{
	float specularFactor : packoffset(c0);
	float3 specMapIntMask : packoffset(c0.y);
	float4 specMapExpMask : packoffset(c1);
	float bumpiness : packoffset(c2);
	float reflectivePower : packoffset(c2.y);
	float fresnelRolloff : packoffset(c2.z);
	float3 specMapReflectMask : packoffset(c3);
};

cbuffer Wet : register(b9)
{
	float4 WetDarken : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState PuddleMaskSampler : register(s2);
SamplerState SpecSampler : register(s3);
SamplerState DynamicEnvironmentSampler : register(s13);
SamplerState WaterRainRippleNormalSampler : register(s14);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D PuddleMaskSampler_tex : register(t2);
Texture2D SpecSampler_tex : register(t3);
Texture2D DynamicEnvironmentSampler_tex : register(t13);
Texture2D WaterRainRippleNormalSampler_tex : register(t14);
Texture2D ShadowZTextureDir : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float4 texcoord7 : TEXCOORD7;
	float4 texcoord9 : TEXCOORD9;
	float sv_clipdistance : SV_ClipDistance;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	float4 r1;
	int4 r2;
	int4 r3;
	int4 r4;
	float3 r5;
	int4 r6;
	int3 r7;
	float3 r8;
	r0.x = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).w);
	r0.yzw = asint(i.texcoord7.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.yz = asint(asfloat(r0.ww) * asfloat(r0.yz));
	r0.w = asint(parallaxScaleBias * 0.5);
	r0.x = asint(asfloat(r0.x) * parallaxScaleBias + -(asfloat(r0.w)));
	r0.xy = asint(asfloat(r0.xx) * asfloat(r0.yz) + i.texcoord.xy);
	r0.zw = asint(BumpSampler_tex.Sample(BumpSampler, asfloat(r0.xy)).xy);
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.zw) * float2(2, 2) + float2(-1, -1));
	r2.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.x = asint(dot(asfloat(r2.xy), asfloat(r2.xy)));
	r0.x = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(max(asfloat(r0.x), 0));
	r2.z = asint(sqrt(asfloat(r0.x)));
	r3 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r0.x = asint(dot(asfloat(r3), specMapExpMask));
	r0.x = asint(asfloat(r0.x) * specularFactor);
	r0.y = asint(dot(asfloat(r3.xyz), specMapIntMask));
	r0.x = asint(max(asfloat(r0.x), 1));
	r2.w = (0 < i.color.y) ? -1 : 0;
	r4.xy = asint(i.texcoord6.xy * WetDarken.ww);
	r3.w = asint(PuddleMaskSampler_tex.Sample(PuddleMaskSampler, asfloat(r4.xy)).x);
	r4.xy = asint(i.texcoord6.xy * float2(0.300000012, 0.300000012));
	r4.xyz = asint(WaterRainRippleNormalSampler_tex.Sample(WaterRainRippleNormalSampler, asfloat(r4.xy)).xyz);
	if (r2.w != 0) {
		r2.w = asint(asfloat(r3.w) + gWaterGlobals.y);
		r2.w = asint(saturate(asfloat(r2.w) + -(i.color.y)));
		r3.w = (0 < asfloat(r2.w)) ? -1 : 0;
		if (r3.w != 0) {
			r1.xyz = r1.xyz * WetDarken.xyz;
			r3.w = asint(-(asfloat(r0.y)) + gWaterGlobals.z);
			r0.y = asint(asfloat(r2.w) * asfloat(r3.w) + asfloat(r0.y));
			r3.w = asint(-(asfloat(r0.x)) + gWaterGlobals.w);
			r0.x = asint(asfloat(r2.w) * asfloat(r3.w) + asfloat(r0.x));
			r4.xyz = asint(asfloat(r4.xyz) * float3(2, 2, 2) + float3(-1, -1, -1));
			r4.xyz = asint(asfloat(r4.xyz) * i.texcoord1.zzz + -(asfloat(r2.xyz)));
			r4.xyz = asint(asfloat(r2.www) * asfloat(r4.xyz) + asfloat(r2.xyz));
			r4.xyz = asint(asfloat(r4.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
			r2.w = asint(dot(asfloat(r4.xyz), asfloat(r4.xyz)));
			r2.w = asint(rsqrt(asfloat(r2.w)));
			r2.xyz = asint(asfloat(r2.www) * asfloat(r4.xyz));
		} else {
			r2.w = asint(saturate(gWaterGlobals.y));
			r4.xyz = asint(r1.xyz * WetDarken.xyz + -(r1.xyz));
			r1.xyz = asfloat(r2.www) * asfloat(r4.xyz) + r1.xyz;
		}
	}
	r4.xyz = asint(asfloat(r2.xxx) * i.texcoord4.xyz);
	r2.xzw = asint(asfloat(r2.zzz) * i.texcoord1.xyz + asfloat(r4.xyz));
	r2.xyz = asint(asfloat(r2.yyy) * i.texcoord5.xyz + asfloat(r2.xzw));
	r2.xyz = asint(asfloat(r2.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r2.xyz = asint(asfloat(r2.www) * asfloat(r2.xyz));
	r2.w = (0 < reflectivePower) ? -1 : 0;
	if (r2.w != 0) {
		r2.w = asint(saturate(asfloat(r0.x) * 0.015625));
		r2.w = asint(-(asfloat(r2.w)) * 4 + 4);
		r4.xyz = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r3.w = asint(dot(asfloat(r4.xyz), asfloat(r4.xyz)));
		r3.w = asint(rsqrt(asfloat(r3.w)));
		r4.xyz = asint(asfloat(r3.www) * asfloat(r4.xyz));
		r3.w = asint(dot(-(asfloat(r4.xyz)), asfloat(r2.xyz)));
		r3.w = asint(asfloat(r3.w) + asfloat(r3.w));
		r5 = asfloat(r2.xyz) * -(asfloat(r3.www)) + -(asfloat(r4.xyz));
		r5 = r5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r3.w = asint(dot(r5.xyz, r5.xyz));
		r3.w = asint(rsqrt(asfloat(r3.w)));
		r5 = asfloat(r3.www) * r5.zxy;
		r5.x = saturate(r5.x);
		r3.w = asint(r5.x + 1);
		r3.w = asint(asfloat(r3.w) + asfloat(r3.w));
		r5.xy = r5.yz / asfloat(r3.ww);
		r5.xy = r5.xy + float2(0.5, 0.5);
		r5.xy = -(r5.xy) + float2(1, 1);
		r5 = DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, r5.xy, asfloat(r2.w)).xyz;
		r5 = r5.xyz * r5.xyz;
		r5 = r5.xyz * float3(16, 16, 16);
		r2.w = asint(saturate(dot(asfloat(r4.xyz), asfloat(r2.xyz))));
		r3.w = asint(-(fresnelRolloff) + 1);
		r2.w = asint(-(asfloat(r2.w)) + 1.00001001);
		r4.x = asint(asfloat(r2.w) * asfloat(r2.w));
		r4.x = asint(asfloat(r4.x) * asfloat(r4.x));
		r2.w = asint(asfloat(r2.w) * asfloat(r4.x));
		r2.w = asint(fresnelRolloff * asfloat(r2.w) + asfloat(r3.w));
		r4.xyz = asint(asfloat(r2.www) * r5.xyz);
	} else {
		r4.xyz = int3(0, 0, 0);
	}
	r4.xyz = asint(asfloat(r4.xyz) * reflectivePower);
	r2.w = asint(dot(asfloat(r3.xyz), specMapReflectMask.xyz));
	r3.xyz = asint(asfloat(r2.www) * asfloat(r4.xyz));
	r3.xyz = asint(asfloat(r3.xyz) * globalScalars.www);
	r0.z = asint(dot(asfloat(r0.zw), asfloat(r0.zw)));
	r0.z = (asfloat(r0.z) >= 0.00200000009) ? -1 : 0;
	r0.z = r0.z & 1065353216;
	r1.xyz = asfloat(r0.zzz) * r1.xyz;
	r0.w = asint(asfloat(r0.z) * i.color.x);
	r0.y = asint(asfloat(r0.z) * asfloat(r0.y));
	r1.xyz = r1.xyz * r1.xyz;
	r0.z = asint(r1.w * i.color.w);
	r4.xyz = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = dot(asfloat(r4.xyz), asfloat(r4.xyz));
	r1.w = rsqrt(r1.w);
	r4.xyz = asint(r1.www * asfloat(r4.xyz));
	r1.w = saturate(asfloat(r2.z) * -0.5 + 0.5);
	r5 = -(gLightAmbient0.xyz) + gLightAmbient1.xyz;
	r5 = r1.www * r5.xyz + gLightAmbient0.xyz;
	r5 = r5.xyz * gAmbientOcclusionEffect.yyy;
	r5 = asfloat(r0.www) * r5.xyz;
	r5 = r5.xyz / gAmbientOcclusionEffect.yyy;
	r0.w = asint(dot(-(asfloat(r4.xyz)), asfloat(r2.xyz)));
	r0.w = asint(asfloat(r0.w) + asfloat(r0.w));
	r4.xyz = asint(asfloat(r2.xyz) * -(asfloat(r0.www)) + -(asfloat(r4.xyz)));
	r0.w = asint(dot(asfloat(r2.xyz), -(gDirectionalLight.xyz)));
	r1.w = saturate(asfloat(r0.w) + -0.25);
	r1.w = r1.w * 1.33333337;
	r2.x = asint(saturate(dot(-(gDirectionalLight.xyz), asfloat(r4.xyz))));
	r2.x = asint(asfloat(r2.x) + 0.00000999999975);
	r0.x = asint(asfloat(r0.x) + 0.00000999999975);
	r2.x = asint(log2(asfloat(r2.x)));
	r0.x = asint(asfloat(r0.x) * asfloat(r2.x));
	r0.x = asint(exp2(asfloat(r0.x)));
	r0.w = asint(saturate(asfloat(r0.w) * 2 + -0.5));
	r0.x = asint(asfloat(r0.w) * asfloat(r0.x));
	r2.xyz = asint(i.texcoord6.yyy * gShadowMatrix[1].xyz);
	r2.xyz = asint(i.texcoord6.xxx * gShadowMatrix[0].xyz + asfloat(r2.xyz));
	r2.xyz = asint(i.texcoord6.zzz * gShadowMatrix[2].xyz + asfloat(r2.xyz));
	r2.xyz = asint(asfloat(r2.xyz) + gShadowMatrix[3].xyz);
	r4.xy = asint(asfloat(r2.xy) + -(gShadowParam18192021.zw));
	r4.zw = (asfloat(r4.xx) >= gCascadeXMaxThresholds.xy) ? -1 : 0;
	r4.zw = r4.zw & int2(1065353216, 1065353216);
	r6.xy = (gCascadeXMinThresholds.xy >= asfloat(r4.xx)) ? -1 : 0;
	r6.zw = (asfloat(r4.yy) >= gCascadeYMaxThresholds.xy) ? -1 : 0;
	r6 = r6 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r7.xy = (gCascadeYMinThresholds.xy >= asfloat(r4.yy)) ? -1 : 0;
	r7.xy = r7.xy & int2(1065353216, 1065353216);
	r4.zw = asint(asfloat(r4.zw) + asfloat(r6.xy));
	r4.zw = asint(asfloat(r6.zw) + asfloat(r4.zw));
	r4.zw = asint(asfloat(r7.xy) + asfloat(r4.zw));
	r6.yz = asint(min(asfloat(r4.zw), float2(1, 1)));
	r6.x = 1065353216;
	r7.x = asint(dot(asfloat(r6.xyz), gShadowParam0123.xyz));
	r7.y = asint(dot(asfloat(r6.xyz), gShadowParam4567.xyz));
	r7.z = asint(dot(asfloat(r6.xyz), gCascadeZScales.xyz));
	r8.x = dot(asfloat(r6.xyz), gShadowParam891113.xyz);
	r8.y = dot(asfloat(r6.xyz), gShadowParam14151617.xyz);
	r8.z = dot(asfloat(r6.xyz), gCascadeZOffsets.xyz);
	r2.xyz = asint(asfloat(r2.zxy) * asfloat(r7.zxy) + r8.zxy);
	r2.x = asint(saturate(asfloat(r2.x)));
	r6.x = asint(-(gCascadeXMinThresholds.w));
	r6.y = asint(-(gCascadeXMaxThresholds.w));
	r4.xy = asint(saturate(abs(asfloat(r4.xy)) * float2(4, 4) + asfloat(r6.xy)));
	r0.w = asint(max(asfloat(r4.y), asfloat(r4.x)));
	r2.x = asint(-(asfloat(r2.x)) + 1);
	r2.x = asint(ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, asfloat(r2.yz), asfloat(r2.x)));
	r0.w = asint(asfloat(r0.w) + asfloat(r2.x));
	r0.w = asint(min(asfloat(r0.w), 1));
	r2.xyz = asint(asfloat(r0.www) * gDirectionalColour.xyz);
	r4.xyz = asint(asfloat(r0.xxx) * asfloat(r2.xyz));
	r4.xyz = asint(asfloat(r4.xyz) * gDirectionalLight.www);
	r2.xyz = asint(asfloat(r2.xyz) * r1.www + r5.xyz);
	r0.x = asint(max(asfloat(r0.z), 0.00999999978));
	r0.x = asint(1 / asfloat(r0.x));
	r3.xyz = asint(asfloat(r0.xxx) * asfloat(r3.xyz));
	r0.x = asint(dot(asfloat(r2.xyz), float3(0.333333343, 0.333333343, 0.333333343)));
	r0.x = asint(asfloat(r0.x) + 0.0149999997);
	r3.xyz = asint(asfloat(r0.xxx) * asfloat(r3.xyz));
	r0.xyw = asint(asfloat(r4.xyz) * asfloat(r0.yyy) + asfloat(r3.xyz));
	r0.xyw = asint(r1.xyz * asfloat(r2.xyz) + asfloat(r0.xyw));
	r1.w = asfloat(r0.z) * globalScalars.x;
	r0.z = asint(dot(asfloat(r0.xyw), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.z = asint(asfloat(r0.z) + 0.00000999999975);
	r0.z = asint(abs(asfloat(r0.z)) + 0.00000999999975);
	r2.x = asint(i.texcoord9.y + 0.00000999999975);
	r0.z = asint(log2(asfloat(r0.z)));
	r0.z = asint(asfloat(r0.z) * asfloat(r2.x));
	r0.z = asint(exp2(asfloat(r0.z)));
	r2.xyz = asint(asfloat(r0.zzz) * asfloat(r0.xyw));
	r0.xyz = asint(-(asfloat(r0.xyw)) * asfloat(r0.zzz) + globalFogColorN.xyz);
	r0.xyz = asint(i.texcoord9.xxx * asfloat(r0.xyz) + asfloat(r2.xyz));
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r2.x = asint(gAdrenoFXVars.x * deSatContrastGamma.x);
	r0.xyz = asint(-(asfloat(r0.www)) + asfloat(r0.xyz));
	r1.xyz = asfloat(r2.xxx) * asfloat(r0.xyz) + asfloat(r0.www);
	o = min(r1, float4(8, 8, 8, 1));

	return o;
}
