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

cbuffer AlphaTest : register(b11)
{
	float g_AlphaRef : packoffset(c0);
};

cbuffer CacheVehicleParams : register(b4)
{
	float3 matDiffuseColor : packoffset(c0);
	float4 matDiffuseColor2 : packoffset(c1);
	float HardAlphaBlend : packoffset(c2);
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
	noperspective float4 sv_position : SV_Position;
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

	int4 r0;
	int4 r1;
	r0.x = asint(i.sv_position.y + i.sv_position.x);
	r0.x = (uint)asfloat(r0.x);
	r0.x = r0.x & 1;
	r0.x = (r0.x == 0) ? -1 : 0;
	r0.y = asint(-(g_AlphaRef) + 1);
	r0.y = asint(asfloat(r0.y) * 0.100000001);
	r1 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r1.xyz = asint(asfloat(r1.xyz) * matDiffuseColor.xyz);
	r1 = asint(asfloat(r1) * i.texcoord2);
	r0.z = asint(asfloat(r1.w) * globalScalars.x + -(g_AlphaRef));
	r0.y = asint(asfloat(r0.z) / asfloat(r0.y));
	r0.y = asint(-(asfloat(r1.w)) * globalScalars.x + asfloat(r0.y));
	r0.z = asint(asfloat(r1.w) * globalScalars.x);
	r0.y = asint(HardAlphaBlend * asfloat(r0.y) + asfloat(r0.z));
	r0.w = (asfloat(r0.y) < 1) ? -1 : 0;
	r0.y = (0.00392156886 >= asfloat(r0.y)) ? -1 : 0;
	r0.x = r0.x & r0.w;
	r0.x = r0.y | r0.x;
	if (r0.x != 0) discard;
	r0.x = asint(dot(i.texcoord2.xyz, float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.y = asint(globalScalars.z * gAmbientOcclusionEffect.y);
	r0.w = asint(saturate(asfloat(r0.x) * asfloat(r0.y) + -1));
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x));
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	o.sv_target.xyz = asfloat(r0.www) * globalScalars2.zzz + asfloat(r1.xyz);
	o.sv_target.w = asfloat(r0.z);
	r0.xyw = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r1.x = asint(-(asfloat(r0.w)) + 1);
	r1.x = (asfloat(r1.x) < asfloat(r0.x)) ? -1 : 0;
	r1.x = r1.x & 1065353216;
	r1.yz = asint(-(asfloat(r0.wy)) + asfloat(r0.xy));
	r0.xy = asint(asfloat(r1.xx) * asfloat(r1.yz) + asfloat(r0.wy));
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.w = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.w = asint(-(asfloat(r0.w)) + 1);
	r0.w = asint(max(asfloat(r0.w), 0));
	r0.w = asint(sqrt(asfloat(r0.w)));
	r1.xyz = asint(asfloat(r0.xxx) * i.texcoord4.xyz);
	r1.xyz = asint(asfloat(r0.www) * i.texcoord1.xyz + asfloat(r1.xyz));
	r0.xyw = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r1.xyz));
	r0.xyw = asint(asfloat(r0.xyw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.x = asint(dot(asfloat(r0.xyw), asfloat(r0.xyw)));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.xyw = asint(asfloat(r0.xyw) * asfloat(r1.xxx));
	o.sv_target1.xyz = asfloat(r0.xyw) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = asfloat(r0.z);
	o.sv_target2.w = asfloat(r0.z);
	o.sv_target3.w = asfloat(r0.z);
	r0 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r0.w = asint(dot(asfloat(r0), specMapExpMask));
	r0.x = asint(dot(asfloat(r0.xyz), specMapIntMask.xyz));
	r0.x = asint(asfloat(r0.x) * specularColorFactor);
	o.sv_target2.x = asfloat(r0.x) * matDiffuseColor2.w;
	r0.x = asint(asfloat(r0.w) * specularFactor);
	r0.x = asint(max(asfloat(r0.x), 1));
	r0.x = asint(asfloat(r0.x) * matDiffuseColor2.w);
	r0.x = asint(saturate(asfloat(r0.x) * 0.00510204071));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	o.sv_target3.xyz = float3(0, 0, 0);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
