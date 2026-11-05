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
	float specularColorFactor : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
};

cbuffer Wet : register(b7)
{
	float4 WetDarken : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState PuddleMaskSampler : register(s2);
SamplerState WaterRainRippleNormalSampler : register(s14);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpTex : register(t1);
Texture2D PuddleMaskSampler_tex : register(t2);
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
	int4 r1;
	int4 r2;
	float4 r3;
	float4 r4;
	int4 r5;
	int4 r6;
	int4 r7;
	float4 r8;
	float4 r9;
	r0.xyz = asint(BumpTex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = asint(-(asfloat(r0.zy)) + asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.ww) * asfloat(r1.xy) + asfloat(r0.zy));
	r1.xyz = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).xyz);
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.w = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.w = asint(-(asfloat(r0.w)) + 1);
	r0.w = asint(max(asfloat(r0.w), 0));
	r0.z = asint(sqrt(asfloat(r0.w)));
	r0.w = asint(max(specularFactor, 1));
	r1.w = (0 < i.color.y) ? -1 : 0;
	r2.xy = asint(i.texcoord6.xy * WetDarken.ww);
	r2.x = asint(PuddleMaskSampler_tex.Sample(PuddleMaskSampler, asfloat(r2.xy)).x);
	r2.yz = asint(i.texcoord6.xy * float2(0.300000012, 0.300000012));
	r2.yzw = asint(WaterRainRippleNormalSampler_tex.Sample(WaterRainRippleNormalSampler, asfloat(r2.yz)).xyz);
	if (r1.w != 0) {
		r1.w = asint(asfloat(r2.x) + gWaterGlobals.y);
		r1.w = asint(saturate(asfloat(r1.w) + -(i.color.y)));
		r2.x = (0 < asfloat(r1.w)) ? -1 : 0;
		if (r2.x != 0) {
			r1.xyz = asint(asfloat(r1.xyz) * WetDarken.xyz);
			r2.x = asint(gWaterGlobals.z + -(specularColorFactor));
			r2.x = asint(asfloat(r1.w) * asfloat(r2.x) + specularColorFactor);
			r3.x = -(asfloat(r0.w)) + gWaterGlobals.w;
			r0.w = asint(asfloat(r1.w) * r3.x + asfloat(r0.w));
			r2.yzw = asint(asfloat(r2.yzw) * float3(2, 2, 2) + float3(-1, -1, -1));
			r2.yzw = asint(asfloat(r2.yzw) * i.texcoord1.zzz + -(asfloat(r0.xyz)));
			r2.yzw = asint(asfloat(r1.www) * asfloat(r2.yzw) + asfloat(r0.xyz));
			r2.yzw = asint(asfloat(r2.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
			r1.w = asint(dot(asfloat(r2.yzw), asfloat(r2.yzw)));
			r1.w = asint(rsqrt(asfloat(r1.w)));
			r0.xyz = asint(asfloat(r1.www) * asfloat(r2.yzw));
		} else {
			r1.w = asint(saturate(gWaterGlobals.y));
			r2.yzw = asint(asfloat(r1.xyz) * WetDarken.xyz + -(asfloat(r1.xyz)));
			r1.xyz = asint(asfloat(r1.www) * asfloat(r2.yzw) + asfloat(r1.xyz));
			r2.x = asint(specularColorFactor);
		}
	} else {
		r2.x = asint(specularColorFactor);
	}
	r2.yzw = asint(asfloat(r0.xxx) * i.texcoord4.xyz);
	r2.yzw = asint(asfloat(r0.zzz) * i.texcoord1.xyz + asfloat(r2.yzw));
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r2.yzw));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r1.www));
	r1.xyz = asint(asfloat(r1.xyz) * asfloat(r1.xyz));
	r2.yzw = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r2.yzw), asfloat(r2.yzw)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.yzw = asint(asfloat(r1.www) * asfloat(r2.yzw));
	r1.w = asint(saturate(asfloat(r0.z) * -0.5 + 0.5));
	r3.xyz = -(gLightAmbient0.xyz) + gLightAmbient1.xyz;
	r3.xyz = asfloat(r1.www) * r3.xyz + gLightAmbient0.xyz;
	r3.xyz = r3.xyz * gAmbientOcclusionEffect.yyy;
	r3.xyz = r3.xyz * i.color.xxx;
	r3.xyz = r3.xyz / gAmbientOcclusionEffect.yyy;
	r1.w = asint(dot(-(asfloat(r2.yzw)), asfloat(r0.xyz)));
	r1.w = asint(asfloat(r1.w) + asfloat(r1.w));
	r2.yzw = asint(asfloat(r0.xyz) * -(asfloat(r1.www)) + -(asfloat(r2.yzw)));
	r1.w = asint(dot(asfloat(r0.xyz), -(gDirectionalLight.xyz)));
	r3.w = saturate(asfloat(r1.w) + -0.25);
	r3.w = r3.w * 1.33333337;
	r4.x = saturate(dot(-(gDirectionalLight.xyz), asfloat(r2.yzw)));
	r4.x = r4.x + 0.00000999999975;
	r4.y = asfloat(r0.w) + 0.00000999999975;
	r4.x = log2(r4.x);
	r4.x = r4.x * r4.y;
	r4.x = exp2(r4.x);
	r1.w = asint(saturate(asfloat(r1.w) * 2 + -0.5));
	r1.w = asint(asfloat(r1.w) * r4.x);
	r4.xyz = i.texcoord6.yyy * gShadowMatrix[1].xyz;
	r4.xyz = i.texcoord6.xxx * gShadowMatrix[0].xyz + r4.xyz;
	r4.xyz = i.texcoord6.zzz * gShadowMatrix[2].xyz + r4.xyz;
	r4.xyz = r4.xyz + gShadowMatrix[3].xyz;
	r5.xy = asint(r4.xy + -(gShadowParam18192021.zw));
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
	r4.xyz = r4.zxy * asfloat(r7.zxy) + r8.zxy;
	r4.x = saturate(r4.x);
	r6.x = asint(-(gCascadeXMinThresholds.w));
	r6.y = asint(-(gCascadeXMaxThresholds.w));
	r5.xy = asint(saturate(abs(asfloat(r5.xy)) * float2(4, 4) + asfloat(r6.xy)));
	r4.w = max(asfloat(r5.y), asfloat(r5.x));
	r4.x = -(r4.x) + 1;
	r4.x = ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, r4.yz, r4.x);
	r4.x = r4.w + r4.x;
	r4.x = min(r4.x, 1);
	r4.xyz = r4.xxx * gDirectionalColour.xyz;
	r5.xyz = asint(asfloat(r1.www) * r4.xyz);
	r3.xyz = r4.xyz * r3.www + r3.xyz;
	r4 = -(i.texcoord6.x) + gLightPosX;
	r6 = asint(-(i.texcoord6.y) + gLightPosY);
	r7 = asint(-(i.texcoord6.z) + gLightPosZ);
	r8 = r4 * r4;
	r8 = asfloat(r6) * asfloat(r6) + r8;
	r8 = asfloat(r7) * asfloat(r7) + r8;
	r9 = r8 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r9 = rsqrt(r9);
	r4 = r4 * r9;
	r6 = asint(asfloat(r6) * r9);
	r7 = asint(asfloat(r7) * r9);
	r8 = saturate(-(r8) * gLightFallOff + float4(1, 1, 1, 1));
	r8 = r8 * r8;
	r8 = r8 * r8 + float4(-0.100000001, -0.100000001, -0.100000001, -0.100000001);
	r8 = max(r8, float4(0, 0, 0, 0));
	r8 = r8 * float4(1.11111116, 1.11111116, 1.11111116, 1.11111116);
	r9 = asfloat(r0.x) * r4;
	r9 = asfloat(r6) * asfloat(r0.y) + r9;
	r9 = asfloat(r7) * asfloat(r0.z) + r9;
	r8 = saturate(r8 * r9);
	r9 = r4 * -(gLightDirX);
	r9 = asfloat(r6) * -(gLightDirY) + r9;
	r9 = asfloat(r7) * -(gLightDirZ) + r9;
	r9 = saturate(r9 * gLightConeScale + gLightConeOffset);
	r8 = r8 * r9;
	r4 = asfloat(r2.y) * r4;
	r4 = asfloat(r2.z) * asfloat(r6) + r4;
	r4 = saturate(asfloat(r2.w) * asfloat(r7) + r4);
	r4 = r4 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = asint(asfloat(r0.w) * 0.25 + 0.00000999999975);
	r4 = log2(r4);
	r0 = asint(asfloat(r0.x) * r4);
	r0 = asint(exp2(asfloat(r0)));
	r0 = asint(r8 * asfloat(r0));
	r4.x = dot(gLightColR, r8);
	r4.y = dot(gLightColG, r8);
	r4.z = dot(gLightColB, r8);
	r6.x = asint(dot(gLightColR, asfloat(r0)));
	r6.y = asint(dot(gLightColG, asfloat(r0)));
	r6.z = asint(dot(gLightColB, asfloat(r0)));
	r0.xyz = asint(r3.xyz + r4.xyz);
	r2.yzw = asint(asfloat(r5.xyz) * gDirectionalLight.www + asfloat(r6.xyz));
	r2.xyz = asint(asfloat(r2.xxx) * asfloat(r2.yzw));
	r0.xyz = asint(asfloat(r1.xyz) * asfloat(r0.xyz) + asfloat(r2.xyz));
	r1.w = asint(i.color.w * globalScalars.x);
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
	r1.xyz = asint(asfloat(r2.xxx) * asfloat(r0.xyz) + asfloat(r0.www));
	o = min(asfloat(r1), float4(8, 8, 8, 1));

	return o;
}
