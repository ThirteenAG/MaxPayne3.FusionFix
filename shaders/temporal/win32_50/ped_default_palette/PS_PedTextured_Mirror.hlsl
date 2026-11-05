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
	float displacementScale : packoffset(c0.y);
	float4 matMaterialColorScale : packoffset(c1);
};

cbuffer PedPalette : register(b7)
{
	float paletteSelector : packoffset(c0);
};

cbuffer AmbientLight : register(b9)
{
	float3 AmbientLightingParams : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState TextureSamplerDiffPal : register(s4);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D TextureSamplerDiffPal_tex : register(t4);
Texture2D ShadowZTextureDir : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord2 : TEXCOORD2;
	float4 texcoord7 : TEXCOORD7;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float4 r0;
	float4 r1;
	int4 r2;
	float4 r3;
	int4 r4;
	int4 r5;
	int4 r6;
	float4 r7;
	float4 r8;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).wxyz;
	r1.xyz = i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = rsqrt(r1.w);
	r1.xyz = r1.www * r1.xyz;
	r0.yzw = r0.yzw * r0.yzw;
	r1.w = r0.x * 255.009995;
	r1.w = floor(r1.w);
	r2.x = (r1.w >= 32) ? -1 : 0;
	r2.y = (160 >= r1.w) ? -1 : 0;
	r2.x = r2.y & r2.x;
	r1.w = r1.w + -32;
	r3.x = r1.w * 0.0078125;
	r3.y = paletteSelector;
	r3 = TextureSamplerDiffPal_tex.Sample(TextureSamplerDiffPal, r3.xy);
	if (r2.x != 0) {
		r1.w = -(r3.w) + 1;
		r2.xyz = asint(r0.yzw * r1.www);
		r0.yzw = r3.xyz * r3.www + asfloat(r2.xyz);
		r0.x = 1;
	}
	r0.x = r0.x * i.texcoord7.w;
	r1.w = saturate(-(AmbientLightingParams.x) * 0.150000006 + 1);
	r1.w = r1.w + 0.200000003;
	r1.w = min(r1.w, 1);
	r1.w = r1.w * AmbientLightingParams.y;
	r1.w = i.texcoord7.x * r1.w + -(i.texcoord7.x);
	r1.w = gAmbientOcclusionEffect.x * r1.w + i.texcoord7.x;
	r2.x = asint(saturate(r1.z * -0.5 + 0.5));
	r2.yzw = asint(-(gLightAmbient0.xyz) + gLightAmbient1.xyz);
	r2.xyz = asint(asfloat(r2.xxx) * asfloat(r2.yzw) + gLightAmbient0.xyz);
	r2.xyz = asint(asfloat(r2.xyz) * gAmbientOcclusionEffect.yyy);
	r2.xyz = asint(r1.www * asfloat(r2.xyz));
	r2.xyz = asint(asfloat(r2.xyz) / gAmbientOcclusionEffect.yyy);
	r1.w = dot(r1.xyz, -(gDirectionalLight.xyz));
	r1.w = saturate(r1.w + -0.25);
	r1.w = r1.w * 1.33333337;
	r3.xyz = i.texcoord2.yyy * gShadowMatrix[1].xyz;
	r3.xyz = i.texcoord2.xxx * gShadowMatrix[0].xyz + r3.xyz;
	r3.xyz = i.texcoord2.zzz * gShadowMatrix[2].xyz + r3.xyz;
	r3.xyz = r3.xyz + gShadowMatrix[3].xyz;
	r4.xy = asint(r3.xy + -(gShadowParam18192021.zw));
	r4.zw = (asfloat(r4.xx) >= gCascadeXMaxThresholds.xy) ? -1 : 0;
	r4.zw = r4.zw & int2(1065353216, 1065353216);
	r5.xy = (gCascadeXMinThresholds.xy >= asfloat(r4.xx)) ? -1 : 0;
	r5.zw = (asfloat(r4.yy) >= gCascadeYMaxThresholds.xy) ? -1 : 0;
	r5 = r5 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r6.xy = (gCascadeYMinThresholds.xy >= asfloat(r4.yy)) ? -1 : 0;
	r6.xy = r6.xy & int2(1065353216, 1065353216);
	r4.zw = asint(asfloat(r4.zw) + asfloat(r5.xy));
	r4.zw = asint(asfloat(r5.zw) + asfloat(r4.zw));
	r4.zw = asint(asfloat(r6.xy) + asfloat(r4.zw));
	r5.yz = asint(min(asfloat(r4.zw), float2(1, 1)));
	r5.x = 1065353216;
	r6.x = asint(dot(asfloat(r5.xyz), gShadowParam0123.xyz));
	r6.y = asint(dot(asfloat(r5.xyz), gShadowParam4567.xyz));
	r6.z = asint(dot(asfloat(r5.xyz), gCascadeZScales.xyz));
	r7.x = dot(asfloat(r5.xyz), gShadowParam891113.xyz);
	r7.y = dot(asfloat(r5.xyz), gShadowParam14151617.xyz);
	r7.z = dot(asfloat(r5.xyz), gCascadeZOffsets.xyz);
	r3.xyz = r3.zxy * asfloat(r6.zxy) + r7.zxy;
	r3.x = saturate(r3.x);
	r5.x = asint(-(gCascadeXMinThresholds.w));
	r5.y = asint(-(gCascadeXMaxThresholds.w));
	r4.xy = asint(saturate(abs(asfloat(r4.xy)) * float2(4, 4) + asfloat(r5.xy)));
	r2.w = asint(max(asfloat(r4.y), asfloat(r4.x)));
	r3.x = -(r3.x) + 1;
	r3.x = ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, r3.yz, r3.x);
	r2.w = asint(asfloat(r2.w) + r3.x);
	r2.w = asint(min(asfloat(r2.w), 1));
	r3.xyz = asfloat(r2.www) * gDirectionalColour.xyz;
	r2.xyz = asint(r3.xyz * r1.www + asfloat(r2.xyz));
	r3 = -(i.texcoord2.x) + gLightPosX;
	r4 = asint(-(i.texcoord2.y) + gLightPosY);
	r5 = asint(-(i.texcoord2.z) + gLightPosZ);
	r6 = asint(r3 * r3);
	r6 = asint(asfloat(r4) * asfloat(r4) + asfloat(r6));
	r6 = asint(asfloat(r5) * asfloat(r5) + asfloat(r6));
	r7 = asfloat(r6) + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r7 = rsqrt(r7);
	r6 = asint(-(asfloat(r6)) * gLightFallOff + float4(1, 1, 1, 1));
	r6 = asint(max(asfloat(r6), float4(0, 0, 0, 0)));
	r6 = asint(asfloat(r6) * asfloat(r6));
	r6 = asint(asfloat(r6) * asfloat(r6) + float4(-0.100000001, -0.100000001, -0.100000001, -0.100000001));
	r6 = asint(max(asfloat(r6), float4(0, 0, 0, 0)));
	r6 = asint(asfloat(r6) * float4(1.11111116, 1.11111116, 1.11111116, 1.11111116));
	r8 = r1.x * r3;
	r8 = asfloat(r4) * r1.y + r8;
	r1 = asfloat(r5) * r1.z + r8;
	r1 = asfloat(r6) * r1;
	r1 = saturate(r7 * r1);
	r3 = r3 * -(gLightDirX);
	r3 = asfloat(r4) * -(gLightDirY) + r3;
	r3 = asfloat(r5) * -(gLightDirZ) + r3;
	r3 = r7 * r3;
	r3 = saturate(r3 * gLightConeScale + gLightConeOffset);
	r1 = r1 * r3;
	r3.x = dot(gLightColR, r1);
	r3.y = dot(gLightColG, r1);
	r3.z = dot(gLightColB, r1);
	r1.xyz = asfloat(r2.xyz) + r3.xyz;
	r0.yzw = r0.yzw * r1.xyz;
	o.w = r0.x * globalScalars.x;
	r0.xyz = r0.yzw * matMaterialColorScale.xxx;
	r0.xyz = saturate(r0.xyz * float3(0.0625, 0.0625, 0.0625));
	o.xyz = sqrt(r0.xyz);

	return o;
}
