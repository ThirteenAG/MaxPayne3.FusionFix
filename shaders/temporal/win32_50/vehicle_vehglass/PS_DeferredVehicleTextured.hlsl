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
	float reflectivePower : packoffset(c4);
	float fresnelRolloff : packoffset(c4.y);
	float crackleIntensity : packoffset(c4.z);
};

SamplerState DiffuseSampler : register(s0);
SamplerState DirtSampler : register(s3);
SamplerState SpecSampler : register(s4);
SamplerState DynamicEnvironmentSampler : register(s13);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D DirtSampler_tex : register(t3);
Texture2D SpecSampler_tex : register(t4);
Texture2D DynamicEnvironmentSampler_tex : register(t13);

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
	int4 r2;
	float4 r3;
	int4 r4;
	float4 r5;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r1.xyz = i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = rsqrt(r1.w);
	r1.xyz = r1.www * r1.xyz;
	r2 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r1.w = dot(asfloat(r2), specMapExpMask);
	r1.w = r1.w * specularFactor;
	r2.x = asint(dot(asfloat(r2.xyz), specMapIntMask.xyz));
	r2.x = asint(asfloat(r2.x) * specularColorFactor);
	r1.w = max(r1.w, 1);
	r2.y = (0 < reflectivePower) ? -1 : 0;
	if (r2.y != 0) {
		r2.yzw = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r3.x = dot(asfloat(r2.yzw), asfloat(r2.yzw));
		r3.x = rsqrt(r3.x);
		r2.yzw = asint(asfloat(r2.yzw) * r3.xxx);
		r3.x = dot(-(asfloat(r2.yzw)), r1.xyz);
		r3.x = r3.x + r3.x;
		r3.xyz = r1.xyz * -(r3.xxx) + -(asfloat(r2.yzw));
		r3.xyz = r3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r3.w = dot(r3.xyz, r3.xyz);
		r3.w = rsqrt(r3.w);
		r3.xyz = r3.www * r3.zxy;
		r3.x = saturate(r3.x);
		r3.x = r3.x + 1;
		r3.x = r3.x + r3.x;
		r3.xy = r3.yz / r3.xx;
		r3.xy = r3.xy + float2(0.5, 0.5);
		r3.xy = -(r3.xy) + float2(1, 1);
		r3.xyz = DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, r3.xy, 0).xyz;
		r3.xyz = r3.xyz * r3.xyz;
		r3.xyz = r3.xyz * float3(16, 16, 16);
		r2.y = asint(saturate(dot(asfloat(r2.yzw), r1.xyz)));
		r2.z = asint(-(fresnelRolloff) + 1);
		r2.y = asint(-(asfloat(r2.y)) + 1.00001001);
		r2.w = asint(asfloat(r2.y) * asfloat(r2.y));
		r2.w = asint(asfloat(r2.w) * asfloat(r2.w));
		r2.y = asint(asfloat(r2.w) * asfloat(r2.y));
		r2.y = asint(fresnelRolloff * asfloat(r2.y) + asfloat(r2.z));
		r2.yzw = asint(asfloat(r2.yyy) * r3.xyz);
	} else {
		r2.yzw = int3(0, 0, 0);
	}
	r2.yzw = asint(asfloat(r2.yzw) * reflectivePower);
	r2.yzw = asint(asfloat(r2.yzw) * globalFogColorN.www);
	r0.xyz = r0.xyz * matDiffuseColor.xyz;
	r3 = r0 * i.texcoord2;
	r0.x = dot(i.texcoord2.xyz, float3(0.212500006, 0.715399981, 0.0720999986));
	r0.y = globalScalars.z * gAmbientOcclusionEffect.y;
	r0.z = r0.y * r0.x;
	r4.x = (0 < dirtLevel) ? -1 : 0;
	if (r4.x != 0) {
		r4.x = asint(DirtSampler_tex.Sample(DirtSampler, i.texcoord7).x);
		r4.y = (0 < asfloat(r4.x)) ? -1 : 0;
		r4.z = asint(asfloat(r4.x) * dirtLevel);
		r4.w = asint(-(asfloat(r4.x)) * dirtLevel + 1);
		r5.xyz = asfloat(r4.zzz) * dirtColor.xyz;
		r5.xyz = r3.xyz * asfloat(r4.www) + r5.xyz;
		r5.w = r0.w * i.texcoord2.w + asfloat(r4.x);
		r3 = (r4.y != 0) ? r5 : r3;
		r0.w = (r4.y != 0) ? asfloat(r4.w) : 1;
	} else {
		r0.w = 1;
	}
	r0.w = r0.w * asfloat(r2.x);
	o.sv_target2.x = r0.w * matDiffuseColor2.w;
	r0.w = r1.w * matDiffuseColor2.w;
	r2.xyz = asint(asfloat(r2.yzw) * matDiffuseColor2.www);
	r0.x = saturate(r0.x * r0.y + -1);
	o.sv_target.xyz = r0.xxx * globalScalars2.zzz + r3.xyz;
	o.sv_target1.xyz = r1.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = saturate(r0.w * 0.00510204071);
	r0.x = sqrt(r0.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.z = r0.z * gAmbientOcclusionEffect.w;
	r0.x = r3.w * globalScalars.x;
	r0.yzw = saturate(asfloat(r2.xyz) * float3(0.0625, 0.0625, 0.0625));
	o.sv_target3.xyz = sqrt(r0.yzw);
	o.sv_target.w = r0.x;
	o.sv_target1.w = r0.x;
	o.sv_target2.w = r0.x;
	o.sv_target3.w = r0.x;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
