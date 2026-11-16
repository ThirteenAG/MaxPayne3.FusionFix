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
	float3 specMapIntMask : packoffset(c0.y);
	float4 specMapExpMask : packoffset(c1);
	float bumpiness : packoffset(c2);
};

cbuffer Wet : register(b7)
{
	float4 WetDarken : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState PuddleMaskSampler : register(s2);
SamplerState SpecSampler : register(s3);
SamplerState WaterRainRippleNormalSampler : register(s14);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D PuddleMaskSampler_tex : register(t2);
Texture2D SpecSampler_tex : register(t3);
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
	float4 texcoord9 : TEXCOORD9;
	float sv_clipdistance : SV_ClipDistance;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	float4 r1;
	int4 r2;
	float4 r3;
	int4 r4;
	int4 r5;
	float3 r6;
	r0.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = -(asfloat(r0.zy)) + asfloat(r0.xy);
	r0.xy = asint(asfloat(r0.ww) * r1.xy + asfloat(r0.zy));
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.w = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.w = asint(-(asfloat(r0.w)) + 1);
	r0.w = asint(max(asfloat(r0.w), 0));
	r0.z = asint(sqrt(asfloat(r0.w)));
	r2 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r0.w = asint(dot(asfloat(r2), specMapExpMask));
	r0.w = asint(asfloat(r0.w) * specularFactor);
	r2.x = asint(dot(asfloat(r2.xyz), specMapIntMask));
	r0.w = asint(max(asfloat(r0.w), 1));
	r2.y = (0 < i.color.y) ? -1 : 0;
	r2.zw = asint(i.texcoord6.xy * WetDarken.ww);
	r2.z = asint(PuddleMaskSampler_tex.Sample(PuddleMaskSampler, asfloat(r2.zw)).x);
	r3.xy = i.texcoord6.xy * float2(0.300000012, 0.300000012);
	r3.xyz = WaterRainRippleNormalSampler_tex.Sample(WaterRainRippleNormalSampler, r3.xy).xyz;
	if (r2.y != 0) {
		r2.y = asint(asfloat(r2.z) + gWaterGlobals.y);
		r2.y = asint(saturate(asfloat(r2.y) + -(i.color.y)));
		r2.z = (0 < asfloat(r2.y)) ? -1 : 0;
		if (r2.z != 0) {
			r1.xyz = r1.xyz * WetDarken.xyz;
			r2.z = asint(-(asfloat(r2.x)) + gWaterGlobals.z);
			r2.x = asint(asfloat(r2.y) * asfloat(r2.z) + asfloat(r2.x));
			r2.z = asint(-(asfloat(r0.w)) + gWaterGlobals.w);
			r0.w = asint(asfloat(r2.y) * asfloat(r2.z) + asfloat(r0.w));
			r3.xyz = r3.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
			r3.xyz = r3.xyz * i.texcoord1.zzz + -(asfloat(r0.xyz));
			r2.yzw = asint(asfloat(r2.yyy) * r3.xyz + asfloat(r0.xyz));
			r2.yzw = asint(asfloat(r2.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
			r3.x = dot(asfloat(r2.yzw), asfloat(r2.yzw));
			r3.x = rsqrt(r3.x);
			r0.xyz = asint(asfloat(r2.yzw) * r3.xxx);
		} else {
			r2.y = asint(saturate(gWaterGlobals.y));
			r3.xyz = r1.xyz * WetDarken.xyz + -(r1.xyz);
			r1.xyz = asfloat(r2.yyy) * r3.xyz + r1.xyz;
		}
	}
	r2.yzw = asint(asfloat(r0.xxx) * i.texcoord4.xyz);
	r2.yzw = asint(asfloat(r0.zzz) * i.texcoord1.xyz + asfloat(r2.yzw));
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r2.yzw));
	r0 = asint(asfloat(r0) + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.y = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r2.y = asint(rsqrt(asfloat(r2.y)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r2.yyy));
	r1.xyz = r1.xyz * r1.xyz;
	r1.w = r1.w * i.color.w;
	r2.yzw = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r3.x = dot(asfloat(r2.yzw), asfloat(r2.yzw));
	r3.x = rsqrt(r3.x);
	r2.yzw = asint(asfloat(r2.yzw) * r3.xxx);
	r3.x = saturate(asfloat(r0.z) * -0.5 + 0.5);
	r3.yzw = -(gLightAmbient0.xyz) + gLightAmbient1.xyz;
	r3.xyz = r3.xxx * r3.yzw + gLightAmbient0.xyz;
	r3.xyz = r3.xyz * gAmbientOcclusionEffect.yyy;
	r3.xyz = r3.xyz * i.color.xxx;
	r3.xyz = r3.xyz / gAmbientOcclusionEffect.yyy;
	r3.w = dot(-(asfloat(r2.yzw)), asfloat(r0.xyz));
	r3.w = r3.w + r3.w;
	r2.yzw = asint(asfloat(r0.xyz) * -(r3.www) + -(asfloat(r2.yzw)));
	r0.x = asint(dot(asfloat(r0.xyz), -(gDirectionalLight.xyz)));
	r0.y = asint(saturate(asfloat(r0.x) + -0.25));
	r0.y = asint(asfloat(r0.y) * 1.33333337);
	r0.z = asint(saturate(dot(-(gDirectionalLight.xyz), asfloat(r2.yzw))));
	r0.z = asint(asfloat(r0.z) + 0.00000999999975);
	r0.z = asint(log2(asfloat(r0.z)));
	r0.z = asint(asfloat(r0.z) * asfloat(r0.w));
	r0.z = asint(exp2(asfloat(r0.z)));
	r0.x = asint(saturate(asfloat(r0.x) * 2 + -0.5));
	r0.x = asint(asfloat(r0.x) * asfloat(r0.z));
	r2.yzw = asint(i.texcoord6.yyy * gShadowMatrix[1].xyz);
	r2.yzw = asint(i.texcoord6.xxx * gShadowMatrix[0].xyz + asfloat(r2.yzw));
	r2.yzw = asint(i.texcoord6.zzz * gShadowMatrix[2].xyz + asfloat(r2.yzw));
	r2.yzw = asint(asfloat(r2.yzw) + gShadowMatrix[3].xyz);
	r0.zw = asint(asfloat(r2.yz) + -(gShadowParam18192021.zw));
	r4.xy = (asfloat(r0.zz) >= gCascadeXMaxThresholds.xy) ? -1 : 0;
	r4.zw = (gCascadeXMinThresholds.xy >= asfloat(r0.zz)) ? -1 : 0;
	r4 = r4 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r5.xy = (asfloat(r0.ww) >= gCascadeYMaxThresholds.xy) ? -1 : 0;
	r5.zw = (gCascadeYMinThresholds.xy >= asfloat(r0.ww)) ? -1 : 0;
	r5 = r5 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r4.xy = asint(asfloat(r4.zw) + asfloat(r4.xy));
	r4.xy = asint(asfloat(r5.xy) + asfloat(r4.xy));
	r4.xy = asint(asfloat(r5.zw) + asfloat(r4.xy));
	r4.yz = asint(min(asfloat(r4.xy), float2(1, 1)));
	r4.x = 1065353216;
	r5.x = asint(dot(asfloat(r4.xyz), gShadowParam0123.xyz));
	r5.y = asint(dot(asfloat(r4.xyz), gShadowParam4567.xyz));
	r5.z = asint(dot(asfloat(r4.xyz), gCascadeZScales.xyz));
	r6.x = dot(asfloat(r4.xyz), gShadowParam891113.xyz);
	r6.y = dot(asfloat(r4.xyz), gShadowParam14151617.xyz);
	r6.z = dot(asfloat(r4.xyz), gCascadeZOffsets.xyz);
	r2.yzw = asint(asfloat(r2.wyz) * asfloat(r5.zxy) + r6.zxy);
	r2.y = asint(saturate(asfloat(r2.y)));
	r4.x = asint(-(gCascadeXMinThresholds.w));
	r4.y = asint(-(gCascadeXMaxThresholds.w));
	r0.zw = asint(saturate(abs(asfloat(r0.zw)) * float2(4, 4) + asfloat(r4.xy)));
	r0.z = asint(max(asfloat(r0.w), asfloat(r0.z)));
	r0.w = asint(-(asfloat(r2.y)) + 1);
	r0.w = asint(ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, asfloat(r2.zw), asfloat(r0.w)));
	r0.z = asint(asfloat(r0.z) + asfloat(r0.w));
	r0.z = asint(min(asfloat(r0.z), 1));
	r2.yzw = asint(asfloat(r0.zzz) * gDirectionalColour.xyz);
	r0.xzw = asint(asfloat(r0.xxx) * asfloat(r2.yzw));
	r0.xzw = asint(asfloat(r0.xzw) * gDirectionalLight.www);
	r2.yzw = asint(asfloat(r2.yzw) * asfloat(r0.yyy) + r3.xyz);
	r0.xyz = asint(asfloat(r2.xxx) * asfloat(r0.xzw));
	r0.xyz = asint(r1.xyz * asfloat(r2.yzw) + asfloat(r0.xyz));
	r1.w = r1.w * globalScalars.x;
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.w = asint(asfloat(r0.w) + 0.00000999999975);
	r0.w = asint(abs(asfloat(r0.w)) + 0.00000999999975);
	r2.x = asint(i.texcoord9.y + 0.00000999999975);
	r0.w = asint(log2(asfloat(r0.w)));
	r0.w = asint(asfloat(r0.w) * asfloat(r2.x));
	r0.w = asint(exp2(asfloat(r0.w)));
	r2.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r0.xyz = asint(-(asfloat(r0.xyz)) * asfloat(r0.www) + globalFogColorN.xyz);
	r0.xyz = asint(i.texcoord9.xxx * asfloat(r0.xyz) + asfloat(r2.xyz));
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r2.x = asint(gAdrenoFXVars.x * deSatContrastGamma.x);
	r0.xyz = asint(-(asfloat(r0.www)) + asfloat(r0.xyz));
	r1.xyz = asfloat(r2.xxx) * asfloat(r0.xyz) + asfloat(r0.www);
	o = min(r1, float4(8, 8, 8, 1));

	return o;
}
