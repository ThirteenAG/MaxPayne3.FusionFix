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
};

cbuffer VehicleMaterial : register(b9)
{
	float dirtLevel : packoffset(c0);
	float3 dirtColor : packoffset(c0.y);
	float specularFactor : packoffset(c1);
	float specularColorFactor : packoffset(c1.y);
	float3 specMapIntMask : packoffset(c2);
	float4 specMapExpMask : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState DiffuseSampler2 : register(s2);
SamplerState DirtSampler : register(s3);
SamplerState SpecSampler : register(s4);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D DiffuseSampler2_tex : register(t2);
Texture2D DirtSampler_tex : register(t3);
Texture2D SpecSampler_tex : register(t4);
Texture2D ShadowZTextureDir : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
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
	float4 r2;
	float4 r3;
	int4 r4;
	int4 r5;
	float3 r6;
	r0 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r1 = asint(DiffuseSampler2_tex.Sample(DiffuseSampler2, i.texcoord.zw));
	r2.xyz = i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.w = dot(r2.xyz, r2.xyz);
	r2.w = rsqrt(r2.w);
	r2.xyz = r2.www * r2.xyz;
	r3 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.zw);
	r2.w = dot(r3, specMapExpMask);
	r2.w = r2.w * specularFactor;
	r3.x = dot(r3.xyz, specMapIntMask.xyz);
	r3.x = r3.x * specularColorFactor;
	r2.w = max(r2.w, 1);
	r3.yzw = asfloat(r0.xyz) * asfloat(r0.xyz);
	r3.yzw = r3.yzw * matDiffuseColor.xyz;
	r1.w = asint(asfloat(r1.w) * matDiffuseColor2.w);
	r1.xyz = asint(asfloat(r1.xyz) * matDiffuseColor2.xyz + -(r3.yzw));
	r0.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz) + r3.yzw);
	r0 = asint(asfloat(r0) * i.texcoord6);
	r1.x = asint(dot(i.texcoord6.xyz, float3(0.212500006, 0.715399981, 0.0720999986)));
	r1.y = asint(globalScalars.z * gAmbientOcclusionEffect.y);
	r1.x = asint(asfloat(r1.y) * asfloat(r1.x));
	r1.y = (0 < dirtLevel) ? -1 : 0;
	if (r1.y != 0) {
		r1.y = asint(DirtSampler_tex.Sample(DirtSampler, i.texcoord.xy).x);
		r1.z = (0 < asfloat(r1.y)) ? -1 : 0;
		r1.w = asint(asfloat(r1.y) * dirtLevel);
		r4.x = asint(-(asfloat(r1.y)) * dirtLevel + 1);
		r3.yzw = asfloat(r1.www) * dirtColor.xyz;
		r4.yzw = asint(asfloat(r0.xyz) * asfloat(r4.xxx) + r3.yzw);
		r5.x = 1065353216;
		r5.yzw = r0.xyz;
		r4 = (r1.z != 0) ? r4 : r5;
		r0.xyz = r4.yzw;
	} else {
		r4.x = 1065353216;
	}
	r1.y = asint(r3.x * asfloat(r4.x));
	r3.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.z = asint(dot(r3.xyz, r3.xyz));
	r1.z = asint(rsqrt(asfloat(r1.z)));
	r3.xyz = asfloat(r1.zzz) * r3.xyz;
	r1.z = asint(saturate(r2.z * -0.5 + 0.5));
	r4.xyz = asint(-(gLightAmbient0.xyz) + gLightAmbient1.xyz);
	r4.xyz = asint(asfloat(r1.zzz) * asfloat(r4.xyz) + gLightAmbient0.xyz);
	r4.xyz = asint(asfloat(r4.xyz) * gAmbientOcclusionEffect.yyy);
	r1.xzw = asint(asfloat(r1.xxx) * asfloat(r4.xyz));
	r1.xzw = asint(asfloat(r1.xzw) / gAmbientOcclusionEffect.yyy);
	r3.w = dot(-(r3.xyz), r2.xyz);
	r3.w = r3.w + r3.w;
	r3.xyz = r2.xyz * -(r3.www) + -(r3.xyz);
	r2.x = dot(r2.xyz, -(gDirectionalLight.xyz));
	r2.y = saturate(r2.x + -0.25);
	r2.y = r2.y * 1.33333337;
	r2.z = saturate(dot(-(gDirectionalLight.xyz), r3.xyz));
	r2.z = r2.z + 0.00000999999975;
	r2.w = r2.w + 0.00000999999975;
	r2.z = log2(r2.z);
	r2.z = r2.z * r2.w;
	r2.z = exp2(r2.z);
	r2.x = saturate(r2.x * 2 + -0.5);
	r2.x = r2.x * r2.z;
	r3.xyz = i.texcoord2.yyy * gShadowMatrix[1].xyz;
	r3.xyz = i.texcoord2.xxx * gShadowMatrix[0].xyz + r3.xyz;
	r3.xyz = i.texcoord2.zzz * gShadowMatrix[2].xyz + r3.xyz;
	r3.xyz = r3.xyz + gShadowMatrix[3].xyz;
	r2.zw = r3.xy + -(gShadowParam18192021.zw);
	r4.xy = (r2.zz >= gCascadeXMaxThresholds.xy) ? -1 : 0;
	r4.zw = (gCascadeXMinThresholds.xy >= r2.zz) ? -1 : 0;
	r4 = r4 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r5.xy = (r2.ww >= gCascadeYMaxThresholds.xy) ? -1 : 0;
	r5.zw = (gCascadeYMinThresholds.xy >= r2.ww) ? -1 : 0;
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
	r3.xyz = r3.zxy * asfloat(r5.zxy) + r6.zxy;
	r3.x = saturate(r3.x);
	r4.x = asint(-(gCascadeXMinThresholds.w));
	r4.y = asint(-(gCascadeXMaxThresholds.w));
	r2.zw = saturate(abs(r2.zw) * float2(4, 4) + asfloat(r4.xy));
	r2.z = max(r2.w, r2.z);
	r2.w = -(r3.x) + 1;
	r2.w = ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, r3.yz, r2.w);
	r2.z = r2.z + r2.w;
	r2.z = min(r2.z, 1);
	r3.xyz = r2.zzz * gDirectionalColour.xyz;
	r2.xzw = r2.xxx * r3.xyz;
	r2.xzw = r2.xzw * gDirectionalLight.www;
	r1.xzw = asint(r3.xyz * r2.yyy + asfloat(r1.xzw));
	r2.xyz = asfloat(r1.yyy) * r2.xzw;
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r1.xzw) + r2.xyz);
	o.w = asfloat(r0.w) * globalScalars.x;
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
