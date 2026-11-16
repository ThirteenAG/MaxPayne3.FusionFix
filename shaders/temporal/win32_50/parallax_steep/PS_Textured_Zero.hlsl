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
	float specularColorFactor : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerComparisonState gShadowZSamplerDir : register(s15);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
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

	float4 r0;
	float4 r1;
	int4 r2;
	int4 r3;
	int4 r4;
	int4 r5;
	float3 r6;
	r0.xyz = BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw;
	r1.xyz = i.texcoord7.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xy = r0.ww * r1.xy;
	r1.xy = -(r1.xy) * parallaxScaleBias;
	r1.zw = i.texcoord.xy;
	r0.w = 1;
	r2.xyz = asint(r0.xyz);
	r2.w = 0;
	while (true) {
		r3.x = (r2.w >= 8) ? -1 : 0;
		if (r3.x != 0) break;
		r3.x = (asfloat(r2.z) < r0.w) ? -1 : 0;
		r3.yz = asint(r1.xy * float2(0.125, 0.125) + r1.zw);
		r4.xyz = asint(BumpSampler_tex.Sample(BumpSampler, asfloat(r3.yz)).xyw);
		if (r3.x != 0) {
			r0.w = r0.w + -0.125;
			r1.zw = asfloat(r3.yz);
			r2.xyz = r4.xyz;
		}
		r2.w = r2.w + 1;
	}
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, r1.zw);
	r1.xy = asfloat(r2.xy) * float2(2, 2) + float2(-1, -1);
	r1.xy = r1.xy * bumpiness;
	r1.z = dot(r1.xy, r1.xy);
	r1.z = -(r1.z) + 1;
	r1.z = max(r1.z, 0);
	r1.z = sqrt(r1.z);
	r1.w = max(specularFactor, 1);
	r3.xyz = asint(r1.xxx * i.texcoord4.xyz);
	r3.xyz = asint(r1.zzz * i.texcoord1.xyz + asfloat(r3.xyz));
	r1.xyz = r1.yyy * i.texcoord5.xyz + asfloat(r3.xyz);
	r1 = r1 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.z = asint(dot(r1.xyz, r1.xyz));
	r2.z = asint(rsqrt(asfloat(r2.z)));
	r1.xyz = r1.xyz * asfloat(r2.zzz);
	r2.x = asint(dot(asfloat(r2.xy), asfloat(r2.xy)));
	r2.x = (asfloat(r2.x) >= 0.00200000009) ? -1 : 0;
	r2.x = r2.x & 1065353216;
	r0.xyz = r0.xyz * asfloat(r2.xxx);
	r2.y = asint(asfloat(r2.x) * i.color.x);
	r2.x = asint(asfloat(r2.x) * specularColorFactor);
	r0.xyz = r0.xyz * r0.xyz;
	r0.w = r0.w * i.color.w;
	r3.xyz = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.z = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
	r2.z = asint(rsqrt(asfloat(r2.z)));
	r3.xyz = asint(asfloat(r2.zzz) * asfloat(r3.xyz));
	r2.z = asint(saturate(r1.z * -0.5 + 0.5));
	r4.xyz = asint(-(gLightAmbient0.xyz) + gLightAmbient1.xyz);
	r4.xyz = asint(asfloat(r2.zzz) * asfloat(r4.xyz) + gLightAmbient0.xyz);
	r4.xyz = asint(asfloat(r4.xyz) * gAmbientOcclusionEffect.yyy);
	r2.yzw = asint(asfloat(r2.yyy) * asfloat(r4.xyz));
	r2.yzw = asint(asfloat(r2.yzw) / gAmbientOcclusionEffect.yyy);
	r3.w = asint(dot(-(asfloat(r3.xyz)), r1.xyz));
	r3.w = asint(asfloat(r3.w) + asfloat(r3.w));
	r3.xyz = asint(r1.xyz * -(asfloat(r3.www)) + -(asfloat(r3.xyz)));
	r1.x = dot(r1.xyz, -(gDirectionalLight.xyz));
	r1.y = saturate(r1.x + -0.25);
	r1.y = r1.y * 1.33333337;
	r1.z = saturate(dot(-(gDirectionalLight.xyz), asfloat(r3.xyz)));
	r1.z = r1.z + 0.00000999999975;
	r1.z = log2(r1.z);
	r1.z = r1.z * r1.w;
	r1.z = exp2(r1.z);
	r1.x = saturate(r1.x * 2 + -0.5);
	r1.x = r1.x * r1.z;
	r3.xyz = asint(i.texcoord6.yyy * gShadowMatrix[1].xyz);
	r3.xyz = asint(i.texcoord6.xxx * gShadowMatrix[0].xyz + asfloat(r3.xyz));
	r3.xyz = asint(i.texcoord6.zzz * gShadowMatrix[2].xyz + asfloat(r3.xyz));
	r3.xyz = asint(asfloat(r3.xyz) + gShadowMatrix[3].xyz);
	r1.zw = asfloat(r3.xy) + -(gShadowParam18192021.zw);
	r4.xy = (r1.zz >= gCascadeXMaxThresholds.xy) ? -1 : 0;
	r4.zw = (gCascadeXMinThresholds.xy >= r1.zz) ? -1 : 0;
	r4 = r4 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r5.xy = (r1.ww >= gCascadeYMaxThresholds.xy) ? -1 : 0;
	r5.zw = (gCascadeYMinThresholds.xy >= r1.ww) ? -1 : 0;
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
	r3.xyz = asint(asfloat(r3.zxy) * asfloat(r5.zxy) + r6.zxy);
	r3.x = asint(saturate(asfloat(r3.x)));
	r4.x = asint(-(gCascadeXMinThresholds.w));
	r4.y = asint(-(gCascadeXMaxThresholds.w));
	r1.zw = saturate(abs(r1.zw) * float2(4, 4) + asfloat(r4.xy));
	r1.z = max(r1.w, r1.z);
	r1.w = -(asfloat(r3.x)) + 1;
	r1.w = ShadowZTextureDir.SampleCmpLevelZero(gShadowZSamplerDir, asfloat(r3.yz), r1.w);
	r1.z = r1.z + r1.w;
	r1.z = min(r1.z, 1);
	r3.xyz = asint(r1.zzz * gDirectionalColour.xyz);
	r1.xzw = r1.xxx * asfloat(r3.xyz);
	r1.xzw = r1.xzw * gDirectionalLight.www;
	r2.yzw = asint(asfloat(r3.xyz) * r1.yyy + asfloat(r2.yzw));
	r1.xyz = asfloat(r2.xxx) * r1.xzw;
	r0.xyz = r0.xyz * asfloat(r2.yzw) + r1.xyz;
	r1.w = r0.w * globalScalars.x;
	r0.w = dot(r0.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r0.w = r0.w + 0.00000999999975;
	r0.w = abs(r0.w) + 0.00000999999975;
	r2.x = asint(i.texcoord9.y + 0.00000999999975);
	r0.w = log2(r0.w);
	r0.w = r0.w * asfloat(r2.x);
	r0.w = exp2(r0.w);
	r2.xyz = asint(r0.www * r0.xyz);
	r0.xyz = -(r0.xyz) * r0.www + globalFogColorN.xyz;
	r0.xyz = i.texcoord9.xxx * r0.xyz + asfloat(r2.xyz);
	r0.w = dot(r0.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r2.x = asint(gAdrenoFXVars.x * deSatContrastGamma.x);
	r0.xyz = -(r0.www) + r0.xyz;
	r1.xyz = asfloat(r2.xxx) * r0.xyz + r0.www;
	o = min(r1, float4(8, 8, 8, 1));

	return o;
}
