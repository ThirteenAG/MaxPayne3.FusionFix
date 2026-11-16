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

SamplerState TextureSampler_layer0 : register(s0);
SamplerState TextureSampler_layer1 : register(s1);
SamplerState TextureSampler_layer2 : register(s2);
Texture2D TextureSampler_layer0_tex : register(t0);
Texture2D TextureSampler_layer1_tex : register(t1);
Texture2D TextureSampler_layer2_tex : register(t2);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float4 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float4 r5;
	float4 r6;
	r0.x = asint(saturate(i.texcoord4.z * -0.5 + 0.5));
	r0.yzw = asint(-(gLightAmbient0.xyz) + gLightAmbient1.xyz);
	r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw) + gLightAmbient0.xyz);
	r0.xyz = asint(asfloat(r0.xyz) * gAmbientOcclusionEffect.yyy);
	r0.xyz = asint(asfloat(r0.xyz) / gAmbientOcclusionEffect.yyy);
	r0.w = asint(dot(i.texcoord4.xyz, -(gDirectionalLight.xyz)));
	r0.w = asint(saturate(asfloat(r0.w) + -0.25));
	r0.w = asint(asfloat(r0.w) * 1.33333337);
	r0.xyz = asint(gDirectionalColour.xyz * asfloat(r0.www) + asfloat(r0.xyz));
	r1 = -(i.texcoord3.x) + gLightPosX;
	r2 = r1 * r1;
	r3 = -(i.texcoord3.y) + gLightPosY;
	r2 = r3 * r3 + r2;
	r4 = -(i.texcoord3.z) + gLightPosZ;
	r2 = r4 * r4 + r2;
	r5 = -(r2) * gLightFallOff + float4(1, 1, 1, 1);
	r2 = r2 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2 = rsqrt(r2);
	r5 = max(r5, float4(0, 0, 0, 0));
	r5 = r5 * r5;
	r5 = r5 * r5 + float4(-0.100000001, -0.100000001, -0.100000001, -0.100000001);
	r5 = max(r5, float4(0, 0, 0, 0));
	r5 = r5 * float4(1.11111116, 1.11111116, 1.11111116, 1.11111116);
	r6 = r1 * i.texcoord4.x;
	r1 = r1 * -(gLightDirX);
	r1 = r3 * -(gLightDirY) + r1;
	r3 = r3 * i.texcoord4.y + r6;
	r3 = r4 * i.texcoord4.z + r3;
	r1 = r4 * -(gLightDirZ) + r1;
	r1 = r2 * r1;
	r1 = saturate(r1 * gLightConeScale + gLightConeOffset);
	r3 = r5 * r3;
	r2 = saturate(r2 * r3);
	r1 = r1 * r2;
	r2.x = dot(gLightColR, r1);
	r2.y = dot(gLightColG, r1);
	r2.z = dot(gLightColB, r1);
	r0.xyz = asint(asfloat(r0.xyz) + r2.xyz);
	r1 = -(i.texcoord3.x) + gLightPointPosX;
	r2 = r1 * r1;
	r3 = -(i.texcoord3.y) + gLightPointPosY;
	r2 = r3 * r3 + r2;
	r4 = -(i.texcoord3.z) + gLightPointPosZ;
	r2 = r4 * r4 + r2;
	r5 = -(r2) * gLightPointFallOff + float4(1, 1, 1, 1);
	r2 = r2 + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2 = rsqrt(r2);
	r5 = max(r5, float4(0, 0, 0, 0));
	r5 = r5 * r5;
	r5 = r5 * r5 + float4(-0.100000001, -0.100000001, -0.100000001, -0.100000001);
	r5 = max(r5, float4(0, 0, 0, 0));
	r5 = r5 * float4(1.11111116, 1.11111116, 1.11111116, 1.11111116);
	r6 = r1 * i.texcoord4.x;
	r1 = r1 * -(gLightDir2X);
	r1 = r3 * -(gLightDir2Y) + r1;
	r3 = r3 * i.texcoord4.y + r6;
	r3 = r4 * i.texcoord4.z + r3;
	r1 = r4 * -(gLightDir2Z) + r1;
	r1 = r2 * r1;
	r1 = saturate(r1 * gLightConeScale2 + gLightConeOffset2);
	r3 = r5 * r3;
	r2 = saturate(r2 * r3);
	r1 = r1 * r2;
	r2.x = dot(gLightPointColR, r1);
	r2.y = dot(gLightPointColG, r1);
	r2.z = dot(gLightPointColB, r1);
	r0.xyz = asint(asfloat(r0.xyz) + r2.xyz);
	r0.xyz = asint(asfloat(r0.xyz) * i.texcoord6.xyz);
	r1 = TextureSampler_layer1_tex.Sample(TextureSampler_layer1, i.texcoord.zw);
	r1.w = r1.w * i.texcoord5.y;
	r2.xyz = TextureSampler_layer0_tex.Sample(TextureSampler_layer0, i.texcoord.xy).xyz;
	r1.xyz = r1.xyz + -(r2.xyz);
	r1.xyz = r1.www * r1.xyz + r2.xyz;
	r2 = TextureSampler_layer2_tex.Sample(TextureSampler_layer2, i.texcoord1.xy);
	r2.xyz = -(r1.xyz) + r2.xyz;
	r1.w = r2.w * i.texcoord5.z;
	r1.xyz = r1.www * r2.xyz + r1.xyz;
	r0.w = asint(i.texcoord6.w * globalScalars.x);
	r1.w = 1;
	r0 = asint(asfloat(r0) * r1);
	r1.x = dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986));
	r1.x = r1.x + 0.00000999999975;
	r1.x = abs(r1.x) + 0.00000999999975;
	r1.x = log2(r1.x);
	r1.y = saturate(-(i.texcoord4.w) * gDepthFxParams.z + gDepthFxParams.w);
	r1.z = -(r1.y) + 1;
	r1.y = r1.z * gDepthFxParams.y + r1.y;
	r1.y = r1.y + -0.999989986;
	r1.x = r1.x * r1.y;
	r1.x = exp2(r1.x);
	r0.xyz = asint(asfloat(r0.xyz) * r1.xxx + -(globalFogColorN.xyz));
	o.w = asfloat(r0.w);
	r1.xyz = i.texcoord3.xyz + -(gViewInverse[3].xyz);
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
	o.xyz = asfloat(r0.xyz) * globalScalars.yyy;

	return o;
}
