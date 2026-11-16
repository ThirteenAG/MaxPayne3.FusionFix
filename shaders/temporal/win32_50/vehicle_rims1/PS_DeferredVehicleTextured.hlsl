cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer direction_light : register(b10)
{
	float4 gDepthFxParams : packoffset(c0);
	float4 gDirectionalLight : packoffset(c1);
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
	float specular2Factor : packoffset(c4);
	float specular2ColorIntensity : packoffset(c4.y);
};

SamplerState DiffuseSampler : register(s0);
SamplerState DirtSampler : register(s1);
SamplerState SpecSampler : register(s2);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D DirtSampler_tex : register(t1);
Texture2D SpecSampler_tex : register(t2);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord7 : TEXCOORD7;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float4 texcoord6 : TEXCOORD6;
	float3 temporalPrevious : TEXCOORD15;
};

struct PS_OUT
{
	float4 sv_target : SV_Target;
	float4 sv_target1 : SV_Target1;
	float4 sv_target2 : SV_Target2;
	float4 sv_target3 : SV_Target3;
	float2 temporalVelocity : SV_Target4;
};

PS_OUT main(PS_IN i)
{
	PS_OUT o;

	float4 r0;
	float4 r1;
	float4 r2;
	int4 r3;
	float4 r4;
	float4 r5;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r1.xyz = i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = rsqrt(r1.w);
	r1.xyz = r1.www * r1.xyz;
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r1.w = dot(r2, specMapExpMask);
	r1.w = r1.w * specularFactor;
	r2.x = dot(r2.xyz, specMapIntMask.xyz);
	r2.x = r2.x * specularColorFactor;
	r1.w = max(r1.w, 1);
	r0.xyz = r0.xyz * matDiffuseColor.xyz;
	r0 = r0 * i.texcoord2;
	r2.y = dot(i.texcoord2.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r2.z = globalScalars.z * gAmbientOcclusionEffect.y;
	r2.w = r2.z * r2.y;
	r3.x = (0 < dirtLevel) ? -1 : 0;
	if (r3.x != 0) {
		r3.x = asint(DirtSampler_tex.Sample(DirtSampler, i.texcoord7).x);
		r3.y = (0 < asfloat(r3.x)) ? -1 : 0;
		r3.z = asint(asfloat(r3.x) * dirtLevel);
		r4.x = -(asfloat(r3.x)) * dirtLevel + 1;
		r3.xzw = asint(asfloat(r3.zzz) * dirtColor.xyz);
		r4.yzw = r0.xyz * r4.xxx + asfloat(r3.xzw);
		r5.x = 1;
		r5.yzw = r0.xyz;
		r3 = asint((r3.y != 0) ? r4 : r5);
		r0.xyz = asfloat(r3.yzw);
	} else {
		r3.x = 1065353216;
	}
	r3.y = asint(r2.x * asfloat(r3.x));
	r3.z = (0 < specular2ColorIntensity) ? -1 : 0;
	r3.w = asint(r1.w / specularFactor);
	r2.x = r2.x / specularColorFactor;
	r4.x = specular2ColorIntensity * specular2ColorIntensity;
	r2.x = r2.x * r4.x;
	r4.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r4.w = dot(r4.xyz, r4.xyz);
	r4.w = rsqrt(r4.w);
	r4.xyz = r4.www * r4.xyz;
	r4.w = dot(-(r4.xyz), r1.xyz);
	r4.w = r4.w + r4.w;
	r4.xyz = r1.xyz * -(r4.www) + -(r4.xyz);
	r4.w = dot(r1.xyz, -(gDirectionalLight.xyz));
	r4.w = max(r4.w, 0);
	r4.x = saturate(dot(-(gDirectionalLight.xyz), r4.xyz));
	r4.x = r4.x + 0.00000999999975;
	r3.w = asint(specular2Factor * asfloat(r3.w) + 0.00000999999975);
	r4.x = log2(r4.x);
	r3.w = asint(asfloat(r3.w) * r4.x);
	r3.w = asint(exp2(asfloat(r3.w)));
	r4.x = saturate(r4.w * 2 + -0.5);
	r3.w = asint(asfloat(r3.w) * r4.x);
	r2.x = r2.x * asfloat(r3.w);
	r4.xyz = r0.xyz * r2.xxx;
	r4.xyz = r4.xyz * asfloat(r3.xxx) + r0.xyz;
	r0.xyz = (r3.zzz != 0) ? r4.xyz : r0.xyz;
	o.sv_target2.x = asfloat(r3.y) * matDiffuseColor2.w;
	r1.w = r1.w * matDiffuseColor2.w;
	r2.x = saturate(r2.y * r2.z + -1);
	o.sv_target.xyz = r2.xxx * globalScalars2.zzz + r0.xyz;
	o.sv_target1.xyz = r1.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = saturate(r1.w * 0.00510204071);
	r0.x = sqrt(r0.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.z = r2.w * gAmbientOcclusionEffect.w;
	r0.x = r0.w * globalScalars.x;
	o.sv_target.w = r0.x;
	o.sv_target1.w = r0.x;
	o.sv_target2.w = r0.x;
	o.sv_target3.xyz = float3(0, 0, 0);
	o.sv_target3.w = r0.x;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
