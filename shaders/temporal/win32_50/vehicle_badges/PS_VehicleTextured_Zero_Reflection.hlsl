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
};

cbuffer VehicleMaterial : register(b9)
{
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float3 specMapIntMask : packoffset(c1);
	float4 specMapExpMask : packoffset(c2);
	float bumpiness : packoffset(c3);
	float reflectivePower : packoffset(c3.y);
	float fresnelRolloff : packoffset(c3.z);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s2);
SamplerState SpecSampler : register(s3);
SamplerState EnvironmentSampler : register(s4);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t2);
Texture2D SpecSampler_tex : register(t3);
Texture2D EnvironmentSampler_tex : register(t4);
Texture2D ShadowZTextureDir : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float sv_clipdistance : SV_ClipDistance;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	float4 r1;
	float4 r2;
	int4 r3;
	int3 r4;
	float3 r5;
	float3 r6;
	r0.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = -(asfloat(r0.zy)) + asfloat(r0.xy);
	r0.xy = asint(asfloat(r0.ww) * r1.xy + asfloat(r0.zy));
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(max(asfloat(r0.z), 0));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r1.xyz = asfloat(r0.xxx) * i.texcoord4.xyz;
	r0.xzw = asint(asfloat(r0.zzz) * i.texcoord1.xyz + r1.xyz);
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r0.xzw));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r1.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = asint(dot(r1.xyz, r1.xyz));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r1.xyz = asfloat(r0.www) * r1.xyz;
	r0.w = asint(dot(-(r1.xyz), asfloat(r0.xyz)));
	r0.w = asint(asfloat(r0.w) + asfloat(r0.w));
	r2.xyz = asfloat(r0.xyz) * -(asfloat(r0.www)) + -(r1.xyz);
	r0.w = asint(saturate(dot(r1.xyz, asfloat(r0.xyz))));
	r0.w = asint(-(asfloat(r0.w)) + 1.00001001);
	r1.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = saturate(dot(-(gDirectionalLight.xyz), r2.xyz));
	r1.w = r1.w + 0.00000999999975;
	r1.w = log2(r1.w);
	r2.x = dot(r1.xyz, r1.xyz);
	r2.x = rsqrt(r2.x);
	r1.xyz = r1.zxy * r2.xxx;
	r1.x = saturate(r1.x);
	r1.x = r1.x + 1;
	r1.x = r1.x + r1.x;
	r1.xy = r1.yz / r1.xx;
	r1.xy = r1.xy + float2(0.5, 0.5);
	r1.xy = -(r1.xy) + float2(1, 1);
	r1.xyz = EnvironmentSampler_tex.SampleLevel(EnvironmentSampler, r1.xy, 0).xyz;
	r1.xyz = r1.xyz * r1.xyz;
	r1.xyz = r1.xyz * float3(16, 16, 16);
	r2.x = asfloat(r0.w) * asfloat(r0.w);
	r2.x = r2.x * r2.x;
	r0.w = asint(asfloat(r0.w) * r2.x);
	r2.x = -(fresnelRolloff) + 1;
	r0.w = asint(fresnelRolloff * asfloat(r0.w) + r2.x);
	r1.xyz = asfloat(r0.www) * r1.xyz;
	r0.w = asint(saturate(asfloat(r0.w)));
	r1.xyz = r1.xyz * reflectivePower;
	r1.xyz = r1.xyz * globalFogColorN.www;
	r1.xyz = asfloat(r0.www) * r1.xyz;
	r0.w = asint(saturate(asfloat(r0.z) * -0.5 + 0.5));
	r0.x = asint(dot(asfloat(r0.xyz), -(gDirectionalLight.xyz)));
	r2.xyz = -(gLightAmbient0.xyz) + gLightAmbient1.xyz;
	r0.yzw = asint(asfloat(r0.www) * r2.xyz + gLightAmbient0.xyz);
	r0.yzw = asint(asfloat(r0.yzw) * gAmbientOcclusionEffect.yyy);
	r2.x = dot(i.texcoord6.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r2.y = globalScalars.z * gAmbientOcclusionEffect.y;
	r2.x = r2.y * r2.x;
	r0.yzw = asint(asfloat(r0.yzw) * r2.xxx);
	r0.yzw = asint(asfloat(r0.yzw) / gAmbientOcclusionEffect.yyy);
	r2.xyz = i.texcoord2.yyy * gShadowMatrix[1].xyz;
	r2.xyz = i.texcoord2.xxx * gShadowMatrix[0].xyz + r2.xyz;
	r2.xyz = i.texcoord2.zzz * gShadowMatrix[2].xyz + r2.xyz;
	r2.xyz = r2.xyz + gShadowMatrix[3].xyz;
	r3.xy = asint(r2.xy + -(gShadowParam18192021.zw));
	r3.zw = (asfloat(r3.xx) >= gCascadeXMaxThresholds.xy) ? -1 : 0;
	r3.zw = r3.zw & int2(1065353216, 1065353216);
	r4.xy = (gCascadeXMinThresholds.xy >= asfloat(r3.xx)) ? -1 : 0;
	r4.xy = r4.xy & int2(1065353216, 1065353216);
	r3.zw = asint(asfloat(r3.zw) + asfloat(r4.xy));
	r4.xy = (asfloat(r3.yy) >= gCascadeYMaxThresholds.xy) ? -1 : 0;
	r4.xy = r4.xy & int2(1065353216, 1065353216);
	r3.zw = asint(asfloat(r3.zw) + asfloat(r4.xy));
	r4.xy = (gCascadeYMinThresholds.xy >= asfloat(r3.yy)) ? -1 : 0;
	r4.xy = r4.xy & int2(1065353216, 1065353216);
	r3.zw = asint(asfloat(r3.zw) + asfloat(r4.xy));
	r4.yz = asint(min(asfloat(r3.zw), float2(1, 1)));
	r4.x = 1065353216;
	r5.x = dot(asfloat(r4.xyz), gShadowParam0123.xyz);
	r5.y = dot(asfloat(r4.xyz), gShadowParam4567.xyz);
	r5.z = dot(asfloat(r4.xyz), gCascadeZScales.xyz);
	r6.x = dot(asfloat(r4.xyz), gShadowParam891113.xyz);
	r6.y = dot(asfloat(r4.xyz), gShadowParam14151617.xyz);
	r6.z = dot(asfloat(r4.xyz), gCascadeZOffsets.xyz);
	r2.xyz = r2.zxy * r5.zxy + r6.zxy;
	r2.x = saturate(r2.x);
	r2.x = -(r2.x) + 1;
	r2.x = ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, r2.yz, r2.x);
	r4.x = asint(-(gCascadeXMinThresholds.w));
	r4.y = asint(-(gCascadeXMaxThresholds.w));
	r2.yz = saturate(abs(asfloat(r3.xy)) * float2(4, 4) + asfloat(r4.xy));
	r2.y = max(r2.z, r2.y);
	r2.x = r2.y + r2.x;
	r2.x = min(r2.x, 1);
	r2.xyz = r2.xxx * gDirectionalColour.xyz;
	r2.w = saturate(asfloat(r0.x) + -0.25);
	r0.x = asint(saturate(asfloat(r0.x) * 2 + -0.5));
	r2.w = r2.w * 1.33333337;
	r0.yzw = asint(r2.xyz * r2.www + asfloat(r0.yzw));
	r2.w = dot(asfloat(r0.yzw), float3(0.333333343, 0.333333343, 0.333333343));
	r2.w = r2.w + 0.0149999997;
	r1.xyz = r1.xyz * r2.www;
	r3 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r2.w = dot(asfloat(r3), specMapExpMask);
	r3.x = asint(dot(asfloat(r3.xyz), specMapIntMask.xyz));
	r3.x = asint(saturate(asfloat(r3.x) * specularColorFactor));
	r2.w = r2.w * specularFactor;
	r2.w = max(r2.w, 1);
	r2.w = r2.w + 0.00000999999975;
	r1.w = r1.w * r2.w;
	r1.w = exp2(r1.w);
	r0.x = asint(asfloat(r0.x) * r1.w);
	r2.xyz = asfloat(r0.xxx) * r2.xyz;
	r2.xyz = r2.xyz * gDirectionalLight.www;
	r1.xyz = r2.xyz * asfloat(r3.xxx) + r1.xyz;
	r2 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r3.xyz = asint(r2.xyz * r2.xyz);
	r2.xyz = asfloat(r3.xyz) * matDiffuseColor.xyz;
	r2 = r2 * i.texcoord6;
	r0.xyz = asint(r2.xyz * asfloat(r0.yzw) + r1.xyz);
	o.w = r2.w * globalScalars.x;
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.w = asint(asfloat(r0.w) + 0.00000999999975);
	r0.w = asint(abs(asfloat(r0.w)) + 0.00000999999975);
	r0.w = asint(log2(asfloat(r0.w)));
	r1.x = saturate(-(i.texcoord1.w) * gDepthFxParams.z + gDepthFxParams.w);
	r1.y = -(r1.x) + 1;
	r1.x = r1.y * gDepthFxParams.y + r1.x;
	r1.x = r1.x + -0.999989986;
	r0.w = asint(asfloat(r0.w) * r1.x);
	r0.w = asint(exp2(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r0.www) + -(globalFogColorN.xyz));
	r1.xyz = i.texcoord2.xyz + -(gViewInverse[3].xyz);
	r0.w = asint(r1.z * globalFogParams.x);
	r1.x = dot(r1.xyz, r1.xyz);
	r1.x = sqrt(r1.x);
	r1.x = r1.x * globalFogParams.z;
	r1.y = asfloat(r0.w) * -1.44269502;
	r1.y = exp2(r1.y);
	r1.y = -(r1.y) + 1;
	r1.y = r1.y / asfloat(r0.w);
	r0.w = (0.0000999999975 < abs(asfloat(r0.w))) ? -1 : 0;
	r1.y = r1.y * r1.x;
	r0.w = asint((r0.w != 0) ? r1.y : r1.x);
	r0.w = asint(asfloat(r0.w) * -(globalFogParams.y));
	r0.w = asint(asfloat(r0.w) * 1.44269502);
	r0.w = asint(exp2(asfloat(r0.w)));
	r0.w = asint(min(asfloat(r0.w), 1));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz) + globalFogColorN.xyz);
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.xyz = asint(-(asfloat(r0.www)) + asfloat(r0.xyz));
	r1.x = gAdrenoFXVars.x * deSatContrastGamma.x;
	r0.xyz = asint(r1.xxx * asfloat(r0.xyz) + asfloat(r0.www));
	r0.xyz = asint(saturate(asfloat(r0.xyz) * float3(0.000624999986, 0.000624999986, 0.000624999986)));
	o.xyz = sqrt(asfloat(r0.xyz));

	return o;
}
