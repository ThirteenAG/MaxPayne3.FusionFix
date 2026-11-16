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
};

SamplerState TextureSampler_layer0 : register(s0);
SamplerState TextureSampler_layer1 : register(s2);
SamplerState TextureSampler_layer2 : register(s4);
SamplerState TextureSampler_layer3 : register(s6);
SamplerState TextureSampler_layer4 : register(s8);
SamplerState TextureSampler_layer5 : register(s10);
SamplerState TextureSampler_layer6 : register(s12);
SamplerState lookupSampler : register(s14);
Texture2D TextureSampler_layer0_tex : register(t0);
Texture2D TextureSampler_layer1_tex : register(t2);
Texture2D TextureSampler_layer2_tex : register(t4);
Texture2D TextureSampler_layer3_tex : register(t6);
Texture2D TextureSampler_layer4_tex : register(t8);
Texture2D TextureSampler_layer5_tex : register(t10);
Texture2D TextureSampler_layer6_tex : register(t12);
Texture2D lookupSampler_tex : register(t14);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float3 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	float3 r4;
	r0.xyz = asint(TextureSampler_layer2_tex.SampleBias(TextureSampler_layer2, i.texcoord.xy, -1.29999995).xyz);
	r1.xyz = TextureSampler_layer0_tex.SampleBias(TextureSampler_layer0, i.texcoord.xy, -1.29999995).xyz;
	r2.xyz = TextureSampler_layer1_tex.SampleBias(TextureSampler_layer1, i.texcoord.xy, -1.29999995).xyz;
	r3 = lookupSampler_tex.Sample(lookupSampler, i.texcoord.zw).xyz;
	r4 = -(r3.xyz) + float3(1, 1, 1);
	r0.w = asint(r4.y * r4.x);
	r1.w = r3.z * asfloat(r0.w);
	r0.w = asint(r4.z * asfloat(r0.w));
	r2.xyz = r1.www * r2.xyz;
	r1.xyz = r1.xyz * asfloat(r0.www) + r2.xyz;
	r2.xy = r3.yx * r4.xy;
	r2.zw = r4.zz * r2.xy;
	r2.xy = r3.zz * r2.yx;
	r0.w = asint(r3.y * r3.x);
	r0.w = asint(r4.z * asfloat(r0.w));
	r0.xyz = asint(asfloat(r0.xyz) * r2.zzz + r1.xyz);
	r1.xyz = TextureSampler_layer3_tex.SampleBias(TextureSampler_layer3, i.texcoord.xy, -1.29999995).xyz;
	r0.xyz = asint(r1.xyz * r2.yyy + asfloat(r0.xyz));
	r1.xyz = TextureSampler_layer4_tex.SampleBias(TextureSampler_layer4, i.texcoord.xy, -1.29999995).xyz;
	r0.xyz = asint(r1.xyz * r2.www + asfloat(r0.xyz));
	r1.xyz = TextureSampler_layer5_tex.SampleBias(TextureSampler_layer5, i.texcoord.xy, -1.29999995).xyz;
	r0.xyz = asint(r1.xyz * r2.xxx + asfloat(r0.xyz));
	r1.xyz = TextureSampler_layer6_tex.SampleBias(TextureSampler_layer6, i.texcoord.xy, -1.29999995).xyz;
	r0.xyz = asint(r1.xyz * asfloat(r0.www) + asfloat(r0.xyz));
	r1.w = i.texcoord3.w * globalScalars.x;
	r1.xyz = i.texcoord3.xyz;
	r0.w = 1065353216;
	r0 = asint(asfloat(r0) * r1);
	r1.x = dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986));
	r1.x = r1.x + 0.00000999999975;
	r1.x = abs(r1.x) + 0.00000999999975;
	r1.x = log2(r1.x);
	r1.y = saturate(-(i.texcoord2.w) * gDepthFxParams.z + gDepthFxParams.w);
	r1.z = -(r1.y) + 1;
	r1.y = r1.z * gDepthFxParams.y + r1.y;
	r1.y = r1.y + -0.999989986;
	r1.x = r1.x * r1.y;
	r1.x = exp2(r1.x);
	r0.xyz = asint(asfloat(r0.xyz) * r1.xxx + -(globalFogColorN.xyz));
	o.w = asfloat(r0.w);
	r1.xyz = i.texcoord1.xyz + -(gViewInverse[3].xyz);
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
	o.xyz = r1.xxx * asfloat(r0.xyz) + asfloat(r0.www);

	return o;
}
