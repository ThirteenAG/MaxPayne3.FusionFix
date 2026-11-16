cbuffer CacheTerrainCB : register(b1)
{
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
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
};

SamplerState TextureSampler_layer0 : register(s0);
SamplerState BumpSampler_layer0 : register(s1);
SamplerState TextureSampler_layer1 : register(s2);
SamplerState BumpSampler_layer1 : register(s3);
SamplerState TextureSampler_layer2 : register(s4);
SamplerState BumpSampler_layer2 : register(s5);
SamplerState TextureSampler_layer3 : register(s6);
SamplerState BumpSampler_layer3 : register(s7);
SamplerState lookupSampler : register(s8);
Texture2D TextureSampler_layer0_tex : register(t0);
Texture2D BumpSampler_layer0_tex : register(t1);
Texture2D TextureSampler_layer1_tex : register(t2);
Texture2D BumpSampler_layer1_tex : register(t3);
Texture2D TextureSampler_layer2_tex : register(t4);
Texture2D BumpSampler_layer2_tex : register(t5);
Texture2D TextureSampler_layer3_tex : register(t6);
Texture2D BumpSampler_layer3_tex : register(t7);
Texture2D lookupSampler_tex : register(t8);

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
	float4 r3;
	float3 r4;
	r0 = asint(i.texcoord4.zxyz + float4(-512, 0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.x = (asfloat(r0.x) < 0) ? -1 : 0;
	if (r0.x != 0) discard;
	r0.x = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r0.x = asint(rsqrt(asfloat(r0.x)));
	r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
	r1.xyz = BumpSampler_layer3_tex.Sample(BumpSampler_layer3, i.texcoord.xy).xyw;
	r0.w = asint(-(r1.z) + 1);
	r0.w = (asfloat(r0.w) < r1.x) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xw = -(r1.zy) + r1.xy;
	r1.xy = asfloat(r0.ww) * r1.xw + r1.zy;
	r2.xyz = BumpSampler_layer2_tex.Sample(BumpSampler_layer2, i.texcoord.xy).xyw;
	r0.w = asint(-(r2.z) + 1);
	r0.w = (asfloat(r0.w) < r2.x) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.zw = -(r2.zy) + r2.xy;
	r1.zw = asfloat(r0.ww) * r1.zw + r2.zy;
	r2.xyz = BumpSampler_layer0_tex.Sample(BumpSampler_layer0, i.texcoord.xy).xyw;
	r0.w = asint(-(r2.z) + 1);
	r0.w = (asfloat(r0.w) < r2.x) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r2.xw = -(r2.zy) + r2.xy;
	r2.xy = asfloat(r0.ww) * r2.xw + r2.zy;
	r3.xyz = BumpSampler_layer1_tex.Sample(BumpSampler_layer1, i.texcoord.xy).xyw;
	r0.w = asint(-(r3.z) + 1);
	r0.w = (asfloat(r0.w) < r3.x) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r2.zw = -(r3.zy) + r3.xy;
	r2.zw = asfloat(r0.ww) * r2.zw + r3.zy;
	r3.xyz = lookupSampler_tex.Sample(lookupSampler, i.texcoord.zw).xyz;
	r4 = -(r3.xyz) + float3(1, 1, 1);
	r0.w = asint(r4.y * r4.x);
	r3.x = r3.z * asfloat(r0.w);
	r0.w = asint(r4.z * asfloat(r0.w));
	r2.zw = r2.zw * r3.xx;
	r2.xy = r2.xy * asfloat(r0.ww) + r2.zw;
	r2.z = r3.y * r4.x;
	r2.w = r3.z * r2.z;
	r2.z = r4.z * r2.z;
	r1.zw = r1.zw * r2.zz + r2.xy;
	r1.xy = r1.xy * r2.ww + r1.zw;
	r1.xy = r1.xy + float2(-0.5, -0.5);
	r1.xy = r1.xy * bumpiness;
	r1.xy = r1.xy + r1.xy;
	r1.z = dot(r1.xy, r1.xy);
	r1.z = -(r1.z) + 1;
	r1.z = max(r1.z, 0);
	r1.z = sqrt(r1.z);
	r3.yzw = r1.xxx * i.texcoord5.xyz;
	r1.xzw = i.texcoord2.xyz * r1.zzz + r3.yzw;
	r1.xyz = r1.yyy * i.texcoord6.xyz + r1.xzw;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = rsqrt(r1.w);
	r1.xyz = r1.www * r1.xyz;
	r1.w = dot(asfloat(r0.xyz), r1.xyz);
	r1.w = r1.w + r1.w;
	r0.xyz = asint(r1.xyz * -(r1.www) + asfloat(r0.xyz));
	r0.x = asint(saturate(dot(-(gDirectionalLight.xyz), asfloat(r0.xyz))));
	r0.x = asint(asfloat(r0.x) + 0.00000999999975);
	r0.x = asint(log2(asfloat(r0.x)));
	r0.y = asint(specularFactor + 0.00000999999975);
	r0.x = asint(asfloat(r0.x) * asfloat(r0.y));
	r0.x = asint(exp2(asfloat(r0.x)));
	r0.xyz = asint(asfloat(r0.xxx) * gDirectionalColour.xyz);
	r0.xyz = asint(asfloat(r0.xyz) * gDirectionalLight.www);
	r0.xyz = asint(asfloat(r0.xyz) * specularColorFactor);
	r1.w = dot(gLightAmbientDir1.xyz, r1.xyz);
	r1.w = saturate(r1.w + gLightAmbientDir0.w);
	r3.yzw = r1.www * gLightAmbient1.xyz;
	r1.w = dot(gLightAmbientDir0.xyz, r1.xyz);
	r1.x = dot(r1.xyz, -(gDirectionalLight.xyz));
	r1.x = r1.x + -0.25;
	r1.x = saturate(r1.x * 1.33333337);
	r1.xyz = r1.xxx * gDirectionalColour.xyz;
	r1.w = saturate(r1.w + gLightAmbientDir0.w);
	r3.yzw = r1.www * gLightAmbient0.xyz + r3.yzw;
	r1.xyz = r3.yzw * i.texcoord3.xxx + r1.xyz;
	r3.yzw = TextureSampler_layer1_tex.SampleBias(TextureSampler_layer1, i.texcoord.xy, -1.29999995).xyz;
	r3.xyz = r3.xxx * r3.yzw;
	r4 = TextureSampler_layer0_tex.SampleBias(TextureSampler_layer0, i.texcoord.xy, -1.29999995).xyz;
	r3.xyz = r4.xyz * asfloat(r0.www) + r3.xyz;
	r4 = TextureSampler_layer2_tex.SampleBias(TextureSampler_layer2, i.texcoord.xy, -1.29999995).xyz;
	r2.xyz = r4.xyz * r2.zzz + r3.xyz;
	r3.xyz = TextureSampler_layer3_tex.SampleBias(TextureSampler_layer3, i.texcoord.xy, -1.29999995).xyz;
	r2.xyz = r3.xyz * r2.www + r2.xyz;
	r0.xyz = asint(r2.xyz * r1.xyz + asfloat(r0.xyz));
	r1.xyz = -(asfloat(r0.xyz)) + globalFogColor.xyz;
	r0.w = asint(i.texcoord2.w + -(globalFogParams.x));
	r1.w = -(globalFogParams.x) + globalFogParams.y;
	r0.w = asint(saturate(asfloat(r0.w) / r1.w));
	r0.xyz = asint(asfloat(r0.www) * r1.xyz + asfloat(r0.xyz));
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.xyz = asint(-(asfloat(r0.www)) + asfloat(r0.xyz));
	r1.x = gAdrenoFXVars.x * deSatContrastGamma.x;
	r0.xyz = asint(r1.xxx * asfloat(r0.xyz) + asfloat(r0.www));
	r0.xyz = asint(saturate(asfloat(r0.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.xyz = sqrt(asfloat(r0.xyz));
	r0.x = asint(globalScalars.x * globalScalars.x);
	r0.x = asint(asfloat(r0.x) * i.texcoord3.w);
	r0.y = asint(-(i.texcoord2.w) + 64);
	r0.y = asint(saturate(asfloat(r0.y) * 0.25));
	o.w = asfloat(r0.y) * asfloat(r0.x);

	return o;
}
