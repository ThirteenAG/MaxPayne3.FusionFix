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
	float3 specular2Color : packoffset(c5);
	float bumpiness : packoffset(c5.w);
	float reflectivePower : packoffset(c6);
	float fresnelRolloff : packoffset(c6.y);
	float3 specMapReflectMask : packoffset(c7);
};

SamplerState DiffuseSampler : register(s0);
SamplerState DirtSampler : register(s2);
SamplerState BumpSampler : register(s3);
SamplerState SpecSampler : register(s4);
SamplerState DynamicEnvironmentSampler : register(s13);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D DirtSampler_tex : register(t2);
Texture2D BumpSampler_tex : register(t3);
Texture2D SpecSampler_tex : register(t4);
Texture2D DynamicEnvironmentSampler_tex : register(t13);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
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
	int4 r4;
	float4 r5;
	float4 r6;
	r0.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = -(asfloat(r0.zy)) + asfloat(r0.xy);
	r0.xy = asint(asfloat(r0.ww) * r1.xy + asfloat(r0.zy));
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(max(asfloat(r0.z), 0));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.w = asint(dot(r2, specMapExpMask));
	r0.w = asint(asfloat(r0.w) * specularFactor);
	r2.w = dot(r2.xyz, specMapIntMask.xyz);
	r2.w = r2.w * specularColorFactor;
	r0.w = asint(max(asfloat(r0.w), 1));
	r3.xyz = asint(asfloat(r0.xxx) * i.texcoord4.xyz);
	r3.xyz = asint(asfloat(r0.zzz) * i.texcoord1.xyz + asfloat(r3.xyz));
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r3.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r3.x = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r3.x = asint(rsqrt(asfloat(r3.x)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r3.xxx));
	r3.x = (0 < reflectivePower) ? -1 : 0;
	if (r3.x != 0) {
		r3.xyz = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r3.w = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
		r3.w = asint(rsqrt(asfloat(r3.w)));
		r3.xyz = asint(asfloat(r3.www) * asfloat(r3.xyz));
		r3.w = asint(dot(-(asfloat(r3.xyz)), asfloat(r0.xyz)));
		r3.w = asint(asfloat(r3.w) + asfloat(r3.w));
		r4.xyz = asint(asfloat(r0.xyz) * -(asfloat(r3.www)) + -(asfloat(r3.xyz)));
		r4.xyz = asint(asfloat(r4.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r3.w = asint(dot(asfloat(r4.xyz), asfloat(r4.xyz)));
		r3.w = asint(rsqrt(asfloat(r3.w)));
		r4.xyz = asint(asfloat(r3.www) * asfloat(r4.zxy));
		r4.x = asint(saturate(asfloat(r4.x)));
		r3.w = asint(asfloat(r4.x) + 1);
		r3.w = asint(asfloat(r3.w) + asfloat(r3.w));
		r4.xy = asint(asfloat(r4.yz) / asfloat(r3.ww));
		r4.xy = asint(asfloat(r4.xy) + float2(0.5, 0.5));
		r4.xy = asint(-(asfloat(r4.xy)) + float2(1, 1));
		r4.xyz = asint(DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, asfloat(r4.xy), 0).xyz);
		r4.xyz = asint(asfloat(r4.xyz) * asfloat(r4.xyz));
		r4.xyz = asint(asfloat(r4.xyz) * float3(16, 16, 16));
		r3.x = asint(saturate(dot(asfloat(r3.xyz), asfloat(r0.xyz))));
		r3.y = asint(-(fresnelRolloff) + 1);
		r3.x = asint(-(asfloat(r3.x)) + 1.00001001);
		r3.z = asint(asfloat(r3.x) * asfloat(r3.x));
		r3.z = asint(asfloat(r3.z) * asfloat(r3.z));
		r3.x = asint(asfloat(r3.z) * asfloat(r3.x));
		r3.x = asint(fresnelRolloff * asfloat(r3.x) + asfloat(r3.y));
		r3.xyz = asint(asfloat(r3.xxx) * asfloat(r4.xyz));
	} else {
		r3.xyz = int3(0, 0, 0);
	}
	r3.xyz = asint(asfloat(r3.xyz) * reflectivePower);
	r2.x = dot(r2.xyz, specMapReflectMask.xyz);
	r2.xyz = r2.xxx * asfloat(r3.xyz);
	r2.xyz = r2.xyz * globalFogColorN.www;
	r1.xyz = r1.xyz * matDiffuseColor.xyz;
	r1 = r1 * i.texcoord2;
	r3.x = asint(dot(i.texcoord2.xyz, float3(0.212500006, 0.715399981, 0.0720999986)));
	r3.y = asint(globalScalars.z * gAmbientOcclusionEffect.y);
	r3.z = asint(asfloat(r3.y) * asfloat(r3.x));
	r3.w = (0 < dirtLevel) ? -1 : 0;
	if (r3.w != 0) {
		r3.w = asint(DirtSampler_tex.Sample(DirtSampler, i.texcoord.xy).x);
		r4.x = (0 < asfloat(r3.w)) ? -1 : 0;
		r4.y = asint(asfloat(r3.w) * dirtLevel);
		r5.x = -(asfloat(r3.w)) * dirtLevel + 1;
		r4.yzw = asint(asfloat(r4.yyy) * dirtColor.xyz);
		r5.yzw = r1.xyz * r5.xxx + asfloat(r4.yzw);
		r6.x = 1;
		r6.yzw = r1.xyz;
		r4 = asint((r4.x != 0) ? r5 : r6);
		r1.xyz = asfloat(r4.yzw);
	} else {
		r4.x = 1065353216;
	}
	r3.w = asint(r2.w * asfloat(r4.x));
	r4.y = (0 < specular2ColorIntensity) ? -1 : 0;
	r4.z = asint(asfloat(r0.w) / specularFactor);
	r2.w = r2.w / specularColorFactor;
	r4.w = asint(specular2ColorIntensity * specular2ColorIntensity);
	r2.w = r2.w * asfloat(r4.w);
	r5.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r4.w = asint(dot(r5.xyz, r5.xyz));
	r4.w = asint(rsqrt(asfloat(r4.w)));
	r5.xyz = asfloat(r4.www) * r5.xyz;
	r6.xyz = r2.www * specular2Color.xyz;
	r2.w = dot(-(r5.xyz), asfloat(r0.xyz));
	r2.w = r2.w + r2.w;
	r5.xyz = asfloat(r0.xyz) * -(r2.www) + -(r5.xyz);
	r2.w = dot(asfloat(r0.xyz), -(gDirectionalLight.xyz));
	r2.w = max(r2.w, 0);
	r4.w = asint(saturate(dot(-(gDirectionalLight.xyz), r5.xyz)));
	r4.w = asint(asfloat(r4.w) + 0.00000999999975);
	r4.z = asint(specular2Factor * asfloat(r4.z) + 0.00000999999975);
	r4.w = asint(log2(asfloat(r4.w)));
	r4.z = asint(asfloat(r4.w) * asfloat(r4.z));
	r4.z = asint(exp2(asfloat(r4.z)));
	r2.w = saturate(r2.w * 2 + -0.5);
	r2.w = r2.w * asfloat(r4.z);
	r5.xyz = r2.www * r6.xyz;
	r5.xyz = r1.xyz * r5.xyz;
	r4.xzw = asint(r5.xyz * asfloat(r4.xxx) + r2.xyz);
	r2.xyz = (r4.yyy != 0) ? asfloat(r4.xzw) : r2.xyz;
	o.sv_target2.x = asfloat(r3.w) * matDiffuseColor2.w;
	r0.w = asint(asfloat(r0.w) * matDiffuseColor2.w);
	r2.xyz = r2.xyz * matDiffuseColor2.www;
	r2.w = saturate(asfloat(r3.x) * asfloat(r3.y) + -1);
	o.sv_target.xyz = r2.www * globalScalars2.zzz + r1.xyz;
	o.sv_target1.xyz = asfloat(r0.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = asint(saturate(asfloat(r0.w) * 0.00510204071));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	o.sv_target2.z = asfloat(r3.z) * gAmbientOcclusionEffect.w;
	r0.x = asint(r1.w * globalScalars.x);
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
