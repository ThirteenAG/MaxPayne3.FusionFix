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
	float dirtLevel : packoffset(c0);
	float3 dirtColor : packoffset(c0.y);
	float specularFactor : packoffset(c1);
	float specularColorFactor : packoffset(c1.y);
	float3 specMapIntMask : packoffset(c2);
	float4 specMapExpMask : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState DirtSampler : register(s2);
SamplerState BumpSampler : register(s3);
SamplerState SpecSampler : register(s4);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D DirtSampler_tex : register(t2);
Texture2D BumpSampler_tex : register(t3);
Texture2D SpecSampler_tex : register(t4);

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

	int4 r0;
	float4 r1;
	float4 r2;
	int4 r3;
	float4 r4;
	float4 r5;
	r0.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = -(asfloat(r0.zy)) + asfloat(r0.xy);
	r0.xy = asint(asfloat(r0.ww) * r1.xy + asfloat(r0.zy));
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * float2(5, 5));
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(max(asfloat(r0.z), 0));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.w = asint(dot(r2, specMapExpMask));
	r0.w = asint(asfloat(r0.w) * specularFactor);
	r2.x = dot(r2.xyz, specMapIntMask.xyz);
	r2.x = r2.x * specularColorFactor;
	r0.w = asint(max(asfloat(r0.w), 1));
	r2.yzw = asfloat(r0.xxx) * i.texcoord4.xyz;
	r2.yzw = asfloat(r0.zzz) * i.texcoord1.xyz + r2.yzw;
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + r2.yzw);
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.y = dot(asfloat(r0.xyz), asfloat(r0.xyz));
	r2.y = rsqrt(r2.y);
	r0.xyz = asint(asfloat(r0.xyz) * r2.yyy);
	r1.xyz = r1.xyz * matDiffuseColor.xyz;
	r1 = r1 * i.texcoord2;
	r2.y = dot(i.texcoord2.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r2.z = globalScalars.z * gAmbientOcclusionEffect.y;
	r2.w = r2.z * r2.y;
	r3.x = (0 < dirtLevel) ? -1 : 0;
	if (r3.x != 0) {
		r3.x = asint(DirtSampler_tex.Sample(DirtSampler, i.texcoord.xy).x);
		r3.y = (0 < asfloat(r3.x)) ? -1 : 0;
		r3.z = asint(asfloat(r3.x) * dirtLevel);
		r4.x = -(asfloat(r3.x)) * dirtLevel + 1;
		r3.xzw = asint(asfloat(r3.zzz) * dirtColor.xyz);
		r4.yzw = r1.xyz * r4.xxx + asfloat(r3.xzw);
		r5.x = 1;
		r5.yzw = r1.xyz;
		r3 = asint((r3.y != 0) ? r4 : r5);
		r1.xyz = asfloat(r3.yzw);
	} else {
		r3.x = 1065353216;
	}
	r2.x = r2.x * asfloat(r3.x);
	o.sv_target2.x = r2.x * matDiffuseColor2.w;
	r0.w = asint(asfloat(r0.w) * matDiffuseColor2.w);
	r2.x = saturate(r2.y * r2.z + -1);
	o.sv_target.xyz = r2.xxx * globalScalars2.zzz + r1.xyz;
	o.sv_target1.xyz = asfloat(r0.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = asint(saturate(asfloat(r0.w) * 0.00510204071));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	o.sv_target2.z = r2.w * gAmbientOcclusionEffect.w;
	r0.x = asint(r1.w * globalScalars.x);
	o.sv_target.w = asfloat(r0.x);
	o.sv_target1.w = asfloat(r0.x);
	o.sv_target2.w = asfloat(r0.x);
	o.sv_target3.xyz = float3(0, 0, 0);
	o.sv_target3.w = asfloat(r0.x);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
