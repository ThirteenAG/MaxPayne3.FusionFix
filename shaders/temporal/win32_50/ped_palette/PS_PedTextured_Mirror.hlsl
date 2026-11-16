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

cbuffer PedPalette : register(b7)
{
	float paletteSelector : packoffset(c0);
};

cbuffer AmbientLight : register(b9)
{
	float3 AmbientLightingParams : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s4);
SamplerState SpecSampler : register(s5);
SamplerState TextureSamplerDiffPal : register(s6);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t4);
Texture2D SpecSampler_tex : register(t5);
Texture2D TextureSamplerDiffPal_tex : register(t6);
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
	float4 r1;
	int4 r2;
	float4 r3;
	float4 r4;
	int4 r5;
	int4 r6;
	int4 r7;
	float4 r8;
	float4 r9;
	r0.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = -(asfloat(r0.zy)) + asfloat(r0.xy);
	r0.xy = asint(asfloat(r0.ww) * r1.xy + asfloat(r0.zy));
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).wxyz;
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(max(asfloat(r0.z), 0));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r2 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r0.w = asint(dot(asfloat(r2), specMapExpMask));
	r0.w = asint(asfloat(r0.w) * specularFactor);
	r2.x = asint(dot(asfloat(r2.xyz), specMapIntMask.xyz));
	r0.w = asint(max(asfloat(r0.w), 1));
	r2.yzw = asint(asfloat(r0.xxx) * i.texcoord4.xyz);
	r2.yzw = asint(asfloat(r0.zzz) * i.texcoord1.xyz + asfloat(r2.yzw));
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r2.yzw));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.y = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r2.y = asint(rsqrt(asfloat(r2.y)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r2.yyy));
	r1.yzw = r1.yzw * r1.yzw;
	r2.y = asint(r1.x * 255.009995);
	r2.y = asint(floor(asfloat(r2.y)));
	r2.z = (asfloat(r2.y) >= 32) ? -1 : 0;
	r2.w = (160 >= asfloat(r2.y)) ? -1 : 0;
	r2.z = r2.w & r2.z;
	r2.y = asint(asfloat(r2.y) + -32);
	r3.x = asfloat(r2.y) * 0.0078125;
	r3.y = paletteSelector;
	r3 = TextureSamplerDiffPal_tex.Sample(TextureSamplerDiffPal, r3.xy);
	if (r2.z != 0) {
		r2.y = asint(-(r3.w) + 1);
		r2.yzw = asint(r1.yzw * asfloat(r2.yyy));
		r1.yzw = r3.xyz * r3.www + asfloat(r2.yzw);
		r1.x = 1;
	}
	r1.x = r1.x * i.texcoord7.w;
	r2.y = asint(saturate(-(AmbientLightingParams.x) * 0.150000006 + 1));
	r2.y = asint(asfloat(r2.y) + 0.200000003);
	r2.y = asint(min(asfloat(r2.y), 1));
	r2.y = asint(asfloat(r2.y) * AmbientLightingParams.y);
	r2.y = asint(i.texcoord7.x * asfloat(r2.y) + -(i.texcoord7.x));
	r2.y = asint(gAmbientOcclusionEffect.x * asfloat(r2.y) + i.texcoord7.x);
	r3.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.z = asint(dot(r3.xyz, r3.xyz));
	r2.z = asint(rsqrt(asfloat(r2.z)));
	r3.xyz = asfloat(r2.zzz) * r3.xyz;
	r2.z = asint(saturate(asfloat(r0.z) * -0.5 + 0.5));
	r4.xyz = -(gLightAmbient0.xyz) + gLightAmbient1.xyz;
	r4.xyz = asfloat(r2.zzz) * r4.xyz + gLightAmbient0.xyz;
	r4.xyz = r4.xyz * gAmbientOcclusionEffect.yyy;
	r2.yzw = asint(asfloat(r2.yyy) * r4.xyz);
	r2.yzw = asint(asfloat(r2.yzw) / gAmbientOcclusionEffect.yyy);
	r3.w = dot(-(r3.xyz), asfloat(r0.xyz));
	r3.w = r3.w + r3.w;
	r3.xyz = asfloat(r0.xyz) * -(r3.www) + -(r3.xyz);
	r3.w = dot(asfloat(r0.xyz), -(gDirectionalLight.xyz));
	r4.x = saturate(r3.w + -0.25);
	r4.x = r4.x * 1.33333337;
	r4.y = saturate(dot(-(gDirectionalLight.xyz), r3.xyz));
	r4.y = r4.y + 0.00000999999975;
	r4.z = asfloat(r0.w) + 0.00000999999975;
	r4.y = log2(r4.y);
	r4.y = r4.y * r4.z;
	r4.y = exp2(r4.y);
	r3.w = saturate(r3.w * 2 + -0.5);
	r3.w = r3.w * r4.y;
	r4.yzw = i.texcoord2.yyy * gShadowMatrix[1].xyz;
	r4.yzw = i.texcoord2.xxx * gShadowMatrix[0].xyz + r4.yzw;
	r4.yzw = i.texcoord2.zzz * gShadowMatrix[2].xyz + r4.yzw;
	r4.yzw = r4.yzw + gShadowMatrix[3].xyz;
	r5.xy = asint(r4.yz + -(gShadowParam18192021.zw));
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
	r4.yzw = r4.wyz * asfloat(r7.zxy) + r8.zxy;
	r4.y = saturate(r4.y);
	r6.x = asint(-(gCascadeXMinThresholds.w));
	r6.y = asint(-(gCascadeXMaxThresholds.w));
	r5.xy = asint(saturate(abs(asfloat(r5.xy)) * float2(4, 4) + asfloat(r6.xy)));
	r5.x = asint(max(asfloat(r5.y), asfloat(r5.x)));
	r4.y = -(r4.y) + 1;
	r4.y = ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, r4.zw, r4.y);
	r4.y = asfloat(r5.x) + r4.y;
	r4.y = min(r4.y, 1);
	r4.yzw = r4.yyy * gDirectionalColour.xyz;
	r5.xyz = asint(r3.www * r4.yzw);
	r2.yzw = asint(r4.yzw * r4.xxx + asfloat(r2.yzw));
	r4 = -(i.texcoord2.x) + gLightPosX;
	r6 = asint(-(i.texcoord2.y) + gLightPosY);
	r7 = asint(-(i.texcoord2.z) + gLightPosZ);
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
	r4 = r3.x * r4;
	r4 = r3.y * asfloat(r6) + r4;
	r3 = saturate(r3.z * asfloat(r7) + r4);
	r3 = r3 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = asint(asfloat(r0.w) * 0.25 + 0.00000999999975);
	r3 = log2(r3);
	r0 = asint(asfloat(r0.x) * r3);
	r0 = asint(exp2(asfloat(r0)));
	r0 = asint(r8 * asfloat(r0));
	r3.x = dot(gLightColR, r8);
	r3.y = dot(gLightColG, r8);
	r3.z = dot(gLightColB, r8);
	r4.x = dot(gLightColR, asfloat(r0));
	r4.y = dot(gLightColG, asfloat(r0));
	r4.z = dot(gLightColB, asfloat(r0));
	r0.xyz = asint(asfloat(r2.yzw) + r3.xyz);
	r2.yzw = asint(asfloat(r5.xyz) * gDirectionalLight.www + r4.xyz);
	r2.xyz = asint(asfloat(r2.xxx) * asfloat(r2.yzw));
	r0.xyz = asint(r1.yzw * asfloat(r0.xyz) + asfloat(r2.xyz));
	o.w = r1.x * globalScalars.x;
	r0.xyz = asint(asfloat(r0.xyz) * matMaterialColorScale.xxx);
	r0.xyz = asint(saturate(asfloat(r0.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.xyz = sqrt(asfloat(r0.xyz));

	return o;
}
