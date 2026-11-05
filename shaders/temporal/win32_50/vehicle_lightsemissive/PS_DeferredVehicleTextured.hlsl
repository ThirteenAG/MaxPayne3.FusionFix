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
};

SamplerState DiffuseSampler : register(s0);
SamplerState DirtSampler : register(s2);
SamplerState SpecSampler : register(s3);
SamplerState EnvironmentSampler : register(s4);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D DirtSampler_tex : register(t2);
Texture2D SpecSampler_tex : register(t3);
Texture2D EnvironmentSampler_tex : register(t4);

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

	int4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	r0 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).wxyz);
	r1.xyz = i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = rsqrt(r1.w);
	r1.xyz = r1.www * r1.xyz;
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r1.w = dot(r2, specMapExpMask);
	r1.w = r1.w * specularFactor;
	r2.x = dot(r2.xyz, specMapIntMask.xyz);
	r2.x = saturate(r2.x * specularColorFactor);
	r1.w = max(r1.w, 1);
	r2.yzw = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r3.x = dot(r2.yzw, r2.yzw);
	r3.x = rsqrt(r3.x);
	r2.yzw = r2.yzw * r3.xxx;
	r3.x = dot(-(r2.yzw), r1.xyz);
	r3.x = r3.x + r3.x;
	r3.xyz = r1.xyz * -(r3.xxx) + -(r2.yzw);
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
	r3.xyz = EnvironmentSampler_tex.SampleLevel(EnvironmentSampler, r3.xy, 0).xyz;
	r3.xyz = r3.xyz * r3.xyz;
	r3.xyz = r3.xyz * float3(16, 16, 16);
	r2.y = saturate(dot(r2.yzw, r1.xyz));
	r2.z = -(fresnelRolloff) + 1;
	r2.y = -(r2.y) + 1.00001001;
	r2.w = r2.y * r2.y;
	r2.w = r2.w * r2.w;
	r2.y = r2.w * r2.y;
	r2.y = fresnelRolloff * r2.y + r2.z;
	r2.yzw = r2.yyy * r3.xyz;
	r2.yzw = r2.yzw * reflectivePower;
	r2.yzw = r2.yzw * globalFogColorN.www;
	r3.yzw = asfloat(r0.yzw) * matDiffuseColor.xyz;
	r0.x = asint(asfloat(r0.x) * i.texcoord2.w);
	r0.y = asint(globalScalars.z * gAmbientOcclusionEffect.y);
	r0.z = (0 < dirtLevel) ? -1 : 0;
	if (r0.z != 0) {
		r0.z = asint(DirtSampler_tex.Sample(DirtSampler, i.texcoord7).x);
		r0.w = (0 < asfloat(r0.z)) ? -1 : 0;
		r4.x = asfloat(r0.z) * dirtLevel;
		r5.x = -(asfloat(r0.z)) * dirtLevel + 1;
		r4 = r4.xxx * dirtColor.xyz;
		r5.yzw = r3.yzw * r5.xxx + r4.xyz;
		r3.x = 1;
		r3 = (r0.w != 0) ? r5 : r3;
	} else {
		r3.x = 1;
	}
	r0.z = asint(r2.x * r3.x);
	o.sv_target2.x = asfloat(r0.z) * matDiffuseColor2.w;
	r0.z = asint(r1.w * matDiffuseColor2.w);
	r2.xyz = r2.yzw * matDiffuseColor2.www;
	r0.w = asint(saturate(globalScalars.z * gAmbientOcclusionEffect.y + -1));
	o.sv_target.xyz = asfloat(r0.www) * globalScalars2.zzz + r3.yzw;
	o.sv_target1.xyz = r1.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.z = asint(saturate(asfloat(r0.z) * 0.00510204071));
	r0.z = asint(sqrt(asfloat(r0.z)));
	o.sv_target2.y = sqrt(asfloat(r0.z));
	o.sv_target2.z = asfloat(r0.y) * gAmbientOcclusionEffect.w;
	r0.x = asint(asfloat(r0.x) * globalScalars.x);
	r0.yzw = asint(saturate(r2.xyz * float3(0.0625, 0.0625, 0.0625)));
	o.sv_target3.xyz = sqrt(asfloat(r0.yzw));
	o.sv_target.w = asfloat(r0.x);
	o.sv_target1.w = asfloat(r0.x);
	o.sv_target2.w = asfloat(r0.x);
	o.sv_target3.w = asfloat(r0.x);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
