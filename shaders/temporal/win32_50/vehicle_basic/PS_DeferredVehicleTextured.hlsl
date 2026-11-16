cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
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
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float3 specMapIntMask : packoffset(c1);
	float4 specMapExpMask : packoffset(c2);
	float bumpiness : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState SpecSampler : register(s2);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D SpecSampler_tex : register(t2);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
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
	int3 r1;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.xyz = r0.xyz * matDiffuseColor.xyz;
	r0 = r0 * i.texcoord2;
	r0.w = r0.w * globalScalars.x;
	o.sv_target.w = r0.w;
	r1.x = asint(dot(i.texcoord2.xyz, float3(0.212500006, 0.715399981, 0.0720999986)));
	r1.y = asint(globalScalars.z * gAmbientOcclusionEffect.y);
	r1.z = asint(saturate(asfloat(r1.x) * asfloat(r1.y) + -1));
	r1.x = asint(asfloat(r1.y) * asfloat(r1.x));
	o.sv_target2.z = asfloat(r1.x) * gAmbientOcclusionEffect.w;
	o.sv_target.xyz = asfloat(r1.zzz) * globalScalars2.zzz + r0.xyz;
	r0.xyz = BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw;
	r1.x = asint(-(r0.z) + 1);
	r1.x = (asfloat(r1.x) < r0.x) ? -1 : 0;
	r1.x = r1.x & 1065353216;
	r1.yz = asint(-(r0.zy) + r0.xy);
	r0.xy = asfloat(r1.xx) * asfloat(r1.yz) + r0.zy;
	r0.xy = r0.xy * float2(2, 2) + float2(-1, -1);
	r0.xy = r0.xy * bumpiness;
	r0.z = dot(r0.xy, r0.xy);
	r0.z = -(r0.z) + 1;
	r0.z = max(r0.z, 0);
	r0.z = sqrt(r0.z);
	r1 = asint(r0.xxx * i.texcoord4.xyz);
	r1 = asint(r0.zzz * i.texcoord1.xyz + asfloat(r1.xyz));
	r0.xyz = r0.yyy * i.texcoord5.xyz + asfloat(r1.xyz);
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = asint(dot(r0.xyz, r0.xyz));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.xyz = r0.xyz * asfloat(r1.xxx);
	o.sv_target1.xyz = r0.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = r0.w;
	o.sv_target2.w = r0.w;
	o.sv_target3.w = r0.w;
	r0 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.w = dot(r0, specMapExpMask);
	r0.x = dot(r0.xyz, specMapIntMask.xyz);
	r0.x = r0.x * specularColorFactor;
	o.sv_target2.x = r0.x * matDiffuseColor2.w;
	r0.x = r0.w * specularFactor;
	r0.x = max(r0.x, 1);
	r0.x = r0.x * matDiffuseColor2.w;
	r0.x = saturate(r0.x * 0.00510204071);
	r0.x = sqrt(r0.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target3.xyz = float3(0, 0, 0);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
