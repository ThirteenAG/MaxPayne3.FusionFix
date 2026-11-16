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

cbuffer CacheMegaVariables : register(b4)
{
	float emissiveMultiplier : packoffset(c0);
	float emissiveReflectMultiplier : packoffset(c0.y);
	float specularFactor : packoffset(c0.z);
};

cbuffer AmbientLight : register(b7)
{
	float3 AmbientLightingParams : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	float4 r1;
	float4 r2;
	r0.x = asint(-(i.texcoord3.z) + -512);
	r0.x = (asfloat(r0.x) < 0) ? -1 : 0;
	if (r0.x != 0) discard;
	r0.x = asint(saturate(-(AmbientLightingParams.x) * 0.150000006 + 1));
	r0.x = asint(asfloat(r0.x) + 0.200000003);
	r0.x = asint(min(asfloat(r0.x), 1));
	r0.x = asint(asfloat(r0.x) * AmbientLightingParams.y);
	r0.x = asint(globalScalars.z * asfloat(r0.x) + -(globalScalars.z));
	r0.x = asint(gAmbientOcclusionEffect.x * asfloat(r0.x) + globalScalars.z);
	r0.yzw = asint(i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.x = dot(asfloat(r0.yzw), asfloat(r0.yzw));
	r1.x = rsqrt(r1.x);
	r0.yzw = asint(asfloat(r0.yzw) * r1.xxx);
	r1.x = dot(gLightAmbientDir1.xyz, asfloat(r0.yzw));
	r1.x = saturate(r1.x + gLightAmbientDir0.w);
	r1.xyz = r1.xxx * gLightAmbient1.xyz;
	r1.w = dot(gLightAmbientDir0.xyz, asfloat(r0.yzw));
	r0.y = asint(dot(asfloat(r0.yzw), -(gDirectionalLight.xyz)));
	r0.y = asint(saturate(asfloat(r0.y) + -0.25));
	r0.y = asint(asfloat(r0.y) * 1.33333337);
	r0.yzw = asint(asfloat(r0.yyy) * gDirectionalColour.xyz);
	r1.w = saturate(r1.w + gLightAmbientDir0.w);
	r1.xyz = r1.www * gLightAmbient0.xyz + r1.xyz;
	r0.xyz = asint(r1.xyz * asfloat(r0.xxx) + asfloat(r0.yzw));
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r1 = abs(r1) + float4(0.00000999999975, 0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1 = log2(r1);
	r1 = r1 * float4(2.20001006, 2.20001006, 2.20001006, 2.20001006);
	r1 = exp2(r1);
	r2 = r1 * i.color;
	r2.xyz = r2.xyz * emissiveMultiplier;
	r0.w = asint(r2.w * globalScalars.x);
	r2.xyz = r2.xyz * globalDayNightEffects.www;
	r0.xyz = asint(r1.xyz * asfloat(r0.xyz) + r2.xyz);
	r0.xyz = asint(saturate(asfloat(r0.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.xyz = sqrt(asfloat(r0.xyz));
	r0.x = asint(-(i.texcoord1.w) + 64);
	r0.x = asint(saturate(asfloat(r0.x) * 0.25));
	o.w = asfloat(r0.x) * asfloat(r0.w);

	return o;
}
