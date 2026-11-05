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

cbuffer AmbientLight : register(b7)
{
	float3 AmbientLightingParams : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
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
	int4 r1;
	int4 r2;
	float4 r3;
	float4 r4;
	float4 r5;
	r0.xyz = i.texcoord2.yyy * gShadowMatrix[1].xyz;
	r0.xyz = i.texcoord2.xxx * gShadowMatrix[0].xyz + r0.xyz;
	r0.xyz = i.texcoord2.zzz * gShadowMatrix[2].xyz + r0.xyz;
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
	r0.w = saturate(-(AmbientLightingParams.x) * 0.150000006 + 1);
	r0.w = r0.w + 0.200000003;
	r0.w = min(r0.w, 1);
	r0.w = r0.w * AmbientLightingParams.y;
	r0.w = i.texcoord7.x * r0.w + -(i.texcoord7.x);
	r0.w = gAmbientOcclusionEffect.x * r0.w + i.texcoord7.x;
	r1.xyz = asint(-(gLightAmbient0.xyz) + gLightAmbient1.xyz);
	r2.xyz = asint(i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asint(asfloat(r1.www) * asfloat(r2.xyz));
	r1.w = asint(saturate(asfloat(r2.z) * -0.5 + 0.5));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz) + gLightAmbient0.xyz);
	r1.xyz = asint(asfloat(r1.xyz) * gAmbientOcclusionEffect.yyy);
	r1.xyz = asint(r0.www * asfloat(r1.xyz));
	r1.xyz = asint(asfloat(r1.xyz) / gAmbientOcclusionEffect.yyy);
	r0.w = dot(asfloat(r2.xyz), -(gDirectionalLight.xyz));
	r0.w = saturate(r0.w + -0.25);
	r0.w = r0.w * 1.33333337;
	r0.xyz = r0.xyz * r0.www + asfloat(r1.xyz);
	r1 = asint(-(i.texcoord2.x) + gLightPosX);
	r3 = asfloat(r2.x) * asfloat(r1);
	r4 = -(i.texcoord2.y) + gLightPosY;
	r3 = r4 * asfloat(r2.y) + r3;
	r5 = -(i.texcoord2.z) + gLightPosZ;
	r2 = asint(r5 * asfloat(r2.z) + r3);
	r3 = asfloat(r1) * asfloat(r1);
	r1 = asint(asfloat(r1) * -(gLightDirX));
	r1 = asint(r4 * -(gLightDirY) + asfloat(r1));
	r3 = r4 * r4 + r3;
	r3 = r5 * r5 + r3;
	r1 = asint(r5 * -(gLightDirZ) + asfloat(r1));
	r4 = -(r3) * gLightFallOff + float4(1, 1, 1, 1);
	r3 = r3 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r3 = rsqrt(r3);
	r4 = max(r4, float4(0, 0, 0, 0));
	r4 = r4 * r4;
	r4 = r4 * r4 + float4(-0.100000001, -0.100000001, -0.100000001, -0.100000001);
	r4 = max(r4, float4(0, 0, 0, 0));
	r4 = r4 * float4(1.11111116, 1.11111116, 1.11111116, 1.11111116);
	r2 = asint(asfloat(r2) * r4);
	r2 = asint(saturate(r3 * asfloat(r2)));
	r1 = asint(asfloat(r1) * r3);
	r1 = asint(saturate(asfloat(r1) * gLightConeScale + gLightConeOffset));
	r1 = asint(asfloat(r2) * asfloat(r1));
	r2.x = asint(dot(gLightColR, asfloat(r1)));
	r2.y = asint(dot(gLightColG, asfloat(r1)));
	r2.z = asint(dot(gLightColB, asfloat(r1)));
	r0.xyz = r0.xyz + asfloat(r2.xyz);
	r1 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r1.xyz = asint(asfloat(r1.xyz) * asfloat(r1.xyz));
	r0.w = asfloat(r1.w) * i.texcoord7.w;
	o.w = r0.w * globalScalars.x;
	r0.xyz = r0.xyz * asfloat(r1.xyz);
	r0.xyz = r0.xyz * matMaterialColorScale.xxx;
	r0.xyz = saturate(r0.xyz * float3(0.0625, 0.0625, 0.0625));
	o.xyz = sqrt(r0.xyz);

	return o;
}
