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

cbuffer Wrinkles : register(b7)
{
	float4 wrinkleMaskStrengths0 : packoffset(c0);
	float4 wrinkleMaskStrengths1 : packoffset(c1);
	float4 wrinkleMaskStrengths2 : packoffset(c2);
	float4 wrinkleMaskStrengths3 : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s4);
SamplerState SpecSampler : register(s5);
SamplerState WrinkleMaskSampler_0 : register(s7);
SamplerState WrinkleMaskSampler_1 : register(s8);
SamplerState WrinkleSampler_A : register(s9);
SamplerState WrinkleSampler_B : register(s10);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t4);
Texture2D SpecSampler_tex : register(t5);
Texture2D WrinkleMaskSampler_0_tex : register(t7);
Texture2D WrinkleMaskSampler_1_tex : register(t8);
Texture2D WrinkleSampler_A_tex : register(t9);
Texture2D WrinkleSampler_B_tex : register(t10);
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

struct PS_OUT
{
	float4 sv_target : SV_Target;
	uint sv_coverage : SV_Coverage;
};

PS_OUT main(PS_IN i)
{
	PS_OUT o;

	float4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	int4 r5;
	int4 r6;
	int4 r7;
	float4 r8;
	float4 r9;
	r0.xyz = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).xyz;
	r1 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r0.w = dot(asfloat(r1), specMapExpMask);
	r0.w = r0.w * specularFactor;
	r1.x = asint(dot(asfloat(r1.xyz), specMapIntMask.xyz));
	r0.w = max(r0.w, 1);
	r2 = WrinkleMaskSampler_0_tex.Sample(WrinkleMaskSampler_0, i.texcoord.xy);
	r3 = WrinkleMaskSampler_1_tex.Sample(WrinkleMaskSampler_1, i.texcoord.xy);
	r1.y = asint(dot(wrinkleMaskStrengths0, r2));
	r1.z = asint(dot(wrinkleMaskStrengths1, r3));
	r1.y = asint(asfloat(r1.z) + asfloat(r1.y));
	r1.z = asint(dot(wrinkleMaskStrengths2, r2));
	r1.w = asint(dot(wrinkleMaskStrengths3, r3));
	r1.z = asint(asfloat(r1.w) + asfloat(r1.z));
	r2.xyz = BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw;
	r1.w = asint(-(r2.z) + 1);
	r1.w = (asfloat(r1.w) < r2.x) ? -1 : 0;
	r1.w = r1.w & 1065353216;
	r2.xw = -(r2.zy) + r2.xy;
	r2.xy = asfloat(r1.ww) * r2.xw + r2.zy;
	r2.xy = r2.xy + float2(-0.5, -0.5);
	r2.xy = r2.xy * bumpiness;
	r2.xy = r2.xy + r2.xy;
	r3.xyz = WrinkleSampler_A_tex.Sample(WrinkleSampler_A, i.texcoord.xy).xyw;
	r1.w = asint(-(r3.z) + 1);
	r1.w = (asfloat(r1.w) < r3.x) ? -1 : 0;
	r1.w = r1.w & 1065353216;
	r2.zw = -(r3.zy) + r3.xy;
	r2.zw = asfloat(r1.ww) * r2.zw + r3.zy;
	r2.zw = r2.zw + float2(-0.5, -0.5);
	r3.xyz = WrinkleSampler_B_tex.Sample(WrinkleSampler_B, i.texcoord.xy).xyw;
	r1.w = asint(-(r3.z) + 1);
	r1.w = (asfloat(r1.w) < r3.x) ? -1 : 0;
	r1.w = r1.w & 1065353216;
	r3.xw = -(r3.zy) + r3.xy;
	r3.xy = asfloat(r1.ww) * r3.xw + r3.zy;
	r3.xy = r3.xy + float2(-0.5, -0.5);
	r2.zw = r2.zw * float2(2, 2) + -(r2.xy);
	r1.yw = asint(asfloat(r1.yy) * r2.zw + r2.xy);
	r2.xy = r3.xy * float2(2, 2) + -(asfloat(r1.yw));
	r2.xy = asfloat(r1.zz) * r2.xy + asfloat(r1.yw);
	r1.y = asint(dot(r2.xy, r2.xy));
	r1.y = asint(-(asfloat(r1.y)) + 1);
	r1.y = asint(max(asfloat(r1.y), 0));
	r2.z = sqrt(asfloat(r1.y));
	r1.yzw = asint(r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.x = dot(asfloat(r1.yzw), asfloat(r1.yzw));
	r2.x = rsqrt(r2.x);
	r1.yzw = asint(asfloat(r1.yzw) * r2.xxx);
	r2.xyz = asfloat(r1.yyy) * i.texcoord4.xyz;
	r2.xyz = i.texcoord1.xyz * asfloat(r1.www) + r2.xyz;
	r1.yzw = asint(i.texcoord5.xyz * asfloat(r1.zzz) + r2.xyz);
	r1.yzw = asint(asfloat(r1.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.x = dot(asfloat(r1.yzw), asfloat(r1.yzw));
	r2.x = rsqrt(r2.x);
	r1.yzw = asint(asfloat(r1.yzw) * r2.xxx);
	r0.xyz = r0.xyz * r0.xyz;
	r2.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.w = dot(r2.xyz, r2.xyz);
	r2.w = rsqrt(r2.w);
	r2.xyz = r2.www * r2.xyz;
	r2.w = saturate(asfloat(r1.w) * -0.5 + 0.5);
	r3.xyz = -(gLightAmbient0.xyz) + gLightAmbient1.xyz;
	r3.xyz = r2.www * r3.xyz + gLightAmbient0.xyz;
	r3.xyz = r3.xyz * gAmbientOcclusionEffect.yyy;
	r3.xyz = r3.xyz * i.texcoord7.xxx;
	r3.xyz = r3.xyz / gAmbientOcclusionEffect.yyy;
	r2.w = dot(-(r2.xyz), asfloat(r1.yzw));
	r2.w = r2.w + r2.w;
	r2.xyz = asfloat(r1.yzw) * -(r2.www) + -(r2.xyz);
	r2.w = dot(asfloat(r1.yzw), -(gDirectionalLight.xyz));
	r3.w = saturate(r2.w + -0.25);
	r3.w = r3.w * 1.33333337;
	r4.x = saturate(dot(-(gDirectionalLight.xyz), r2.xyz));
	r4.x = r4.x + 0.00000999999975;
	r4.y = r0.w + 0.00000999999975;
	r4.x = log2(r4.x);
	r4.x = r4.x * r4.y;
	r4.x = exp2(r4.x);
	r2.w = saturate(r2.w * 2 + -0.5);
	r2.w = r2.w * r4.x;
	r4.xyz = i.texcoord2.yyy * gShadowMatrix[1].xyz;
	r4.xyz = i.texcoord2.xxx * gShadowMatrix[0].xyz + r4.xyz;
	r4.xyz = i.texcoord2.zzz * gShadowMatrix[2].xyz + r4.xyz;
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
	r4.x = -(r4.x) + 0.999999523;
	r5.xy = int2(0, -1);
	while (true) {
		r5.z = (r5.y >= 2) ? -1 : 0;
		if (r5.z != 0) break;
		r5.z = asint((float)r5.y);
		r6.x = asint(asfloat(r5.z) * gShadowParam18192021.x);
		r5.z = r5.x;
		r5.w = -1;
		while (true) {
			r6.z = (r5.w >= 2) ? -1 : 0;
			if (r6.z != 0) break;
			r6.z = asint((float)r5.w);
			r6.y = asint(asfloat(r6.z) * gShadowParam18192021.y);
			r6.yz = asint(r4.yz + asfloat(r6.xy));
			r6.y = asint(ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, asfloat(r6.yz), r4.x));
			r5.z = asint(asfloat(r5.z) + asfloat(r6.y));
			r5.w = r5.w + 1;
		}
		r5.x = r5.z;
		r5.y = r5.y + 1;
	}
	r4.x = asfloat(r5.x) * 0.111111112 + r4.w;
	r4.x = r4.x * 1.25;
	r4.x = min(r4.x, 1);
	r4.y = r4.x * -2 + 3;
	r4.x = r4.x * r4.x;
	r4.x = r4.x * r4.y;
	r4.xyz = r4.xxx * gDirectionalColour.xyz;
	r5.xyz = asint(r2.www * r4.xyz);
	r3.xyz = r4.xyz * r3.www + r3.xyz;
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
	r9 = asfloat(r1.y) * r4;
	r9 = asfloat(r6) * asfloat(r1.z) + r9;
	r9 = asfloat(r7) * asfloat(r1.w) + r9;
	r8 = saturate(r8 * r9);
	r9 = r4 * -(gLightDirX);
	r9 = asfloat(r6) * -(gLightDirY) + r9;
	r9 = asfloat(r7) * -(gLightDirZ) + r9;
	r9 = saturate(r9 * gLightConeScale + gLightConeOffset);
	r8 = r8 * r9;
	r4 = r2.x * r4;
	r4 = r2.y * asfloat(r6) + r4;
	r2 = saturate(r2.z * asfloat(r7) + r4);
	r2 = r2 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = r0.w * 0.25 + 0.00000999999975;
	r2 = log2(r2);
	r2 = r0.w * r2;
	r2 = exp2(r2);
	r2 = r8 * r2;
	r4.x = dot(gLightColR, r8);
	r4.y = dot(gLightColG, r8);
	r4.z = dot(gLightColB, r8);
	r6.x = asint(dot(gLightColR, r2));
	r6.y = asint(dot(gLightColG, r2));
	r6.z = asint(dot(gLightColB, r2));
	r1.yzw = asint(r3.xyz + r4.xyz);
	r2.xyz = asfloat(r5.xyz) * gDirectionalLight.www + asfloat(r6.xyz);
	r2.xyz = asfloat(r1.xxx) * r2.xyz;
	r0.xyz = r0.xyz * asfloat(r1.yzw) + r2.xyz;
	o.sv_target.w = i.texcoord7.w * globalScalars.x;
	r1.xyz = asint(i.texcoord2.xyz + -(gViewInverse[3].xyz));
	r0.w = saturate(-(i.texcoord1.w) * gDepthFxParams.z + gDepthFxParams.w);
	r1.w = asint(-(r0.w) + 1);
	r0.w = asfloat(r1.w) * gDepthFxParams.y + r0.w;
	r1.w = asint(dot(r0.xyz, float3(0.212500006, 0.715399981, 0.0720999986)));
	r1.w = asint(asfloat(r1.w) + 0.00000999999975);
	r1.w = asint(abs(asfloat(r1.w)) + 0.00000999999975);
	r0.w = r0.w + -0.999989986;
	r1.w = asint(log2(asfloat(r1.w)));
	r0.w = r0.w * asfloat(r1.w);
	r0.w = exp2(r0.w);
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
	r0.xyz = r0.xyz * r0.www + -(globalFogColorN.xyz);
	r0.xyz = asfloat(r1.xxx) * r0.xyz + globalFogColorN.xyz;
	r0.w = gAdrenoFXVars.x * deSatContrastGamma.x;
	r1.x = asint(dot(r0.xyz, float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.xyz = r0.xyz + -(asfloat(r1.xxx));
	r0.xyz = r0.www * r0.xyz + asfloat(r1.xxx);
	o.sv_target.xyz = r0.xyz * matMaterialColorScale.xxx;
	o.sv_coverage = 255;

	return o;
}
