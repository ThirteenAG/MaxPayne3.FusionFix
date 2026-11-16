cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer CacheTerrainCB : register(b1)
{
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float specularFactor1 : packoffset(c0.z);
	float specularColorFactor1 : packoffset(c0.w);
	float bumpiness : packoffset(c1);
	float reflectivePower : packoffset(c1.y);
	float fresnelRolloff : packoffset(c1.z);
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

SamplerState TextureSampler_layer0 : register(s0);
SamplerState BumpSampler_layer0 : register(s1);
SamplerState SpecSampler_layer01 : register(s2);
SamplerState TextureSampler_layer1 : register(s3);
SamplerState BumpSampler_layer1 : register(s4);
SamplerState DynamicEnvironmentSampler : register(s13);
Texture2D TextureSampler_layer0_tex : register(t0);
Texture2D BumpSampler_layer0_tex : register(t1);
Texture2D SpecSampler_layer01_tex : register(t2);
Texture2D TextureSampler_layer1_tex : register(t3);
Texture2D BumpSampler_layer1_tex : register(t4);
Texture2D DynamicEnvironmentSampler_tex : register(t13);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 color : COLOR;
	float3 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
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
	float4 r2;
	float4 r3;
	float3 r4;
	r0.xyz = asint(-(i.color.xyz) + float3(1, 1, 1));
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x));
	r0.y = asint(asfloat(r0.z) * asfloat(r0.x));
	r0.x = asint(asfloat(r0.x) * i.color.z);
	r1.xyz = asint(TextureSampler_layer0_tex.SampleBias(TextureSampler_layer0, i.texcoord.xy, -1.29999995).xyz);
	r2.xyz = TextureSampler_layer1_tex.SampleBias(TextureSampler_layer1, i.texcoord.xy, -1.29999995).xyz;
	r2.xyz = asfloat(r0.xxx) * r2.xyz;
	r1.xyz = asint(asfloat(r1.xyz) * asfloat(r0.yyy) + r2.xyz);
	r2.xyz = BumpSampler_layer0_tex.Sample(BumpSampler_layer0, i.texcoord.xy).xyw;
	r0.z = asint(-(r2.z) + 1);
	r0.z = (asfloat(r0.z) < r2.x) ? -1 : 0;
	r0.z = r0.z & 1065353216;
	r2.xw = -(r2.zy) + r2.xy;
	r0.zw = asint(asfloat(r0.zz) * r2.xw + r2.zy);
	r2.xyz = BumpSampler_layer1_tex.Sample(BumpSampler_layer1, i.texcoord.xy).xyw;
	r1.w = asint(-(r2.z) + 1);
	r1.w = (asfloat(r1.w) < r2.x) ? -1 : 0;
	r1.w = r1.w & 1065353216;
	r2.xw = -(r2.zy) + r2.xy;
	r2.xy = asfloat(r1.ww) * r2.xw + r2.zy;
	r2.xy = asfloat(r0.xx) * r2.xy;
	r0.zw = asint(asfloat(r0.zw) * asfloat(r0.yy) + r2.xy);
	r0.zw = asint(asfloat(r0.zw) + float2(-0.5, -0.5));
	r0.zw = asint(asfloat(r0.zw) * bumpiness);
	r0.zw = asint(asfloat(r0.zw) + asfloat(r0.zw));
	r1.w = asint(dot(asfloat(r0.zw), asfloat(r0.zw)));
	r1.w = asint(-(asfloat(r1.w)) + 1);
	r1.w = asint(max(asfloat(r1.w), 0));
	r1.w = asint(sqrt(asfloat(r1.w)));
	r2.xyz = asfloat(r0.zzz) * i.texcoord4.xyz;
	r2.xyz = i.texcoord2.xyz * asfloat(r1.www) + r2.xyz;
	r2.xyz = asfloat(r0.www) * i.texcoord5.xyz + r2.xyz;
	r2.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = asint(dot(r2.xyz, r2.xyz));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r2.xyz = asfloat(r0.zzz) * r2.xyz;
	r3 = SpecSampler_layer01_tex.Sample(SpecSampler_layer01, i.texcoord.xy);
	r3 = r3 * float4(specularFactor, specularColorFactor, specularFactor1, specularColorFactor1);
	r0.xz = asint(asfloat(r0.xx) * r3.zw);
	r0.xy = asint(r3.xy * asfloat(r0.yy) + asfloat(r0.xz));
	r0.z = (0 < reflectivePower) ? -1 : 0;
	if (r0.z != 0) {
		r0.z = asint(saturate(asfloat(r0.x) * 0.015625));
		r0.z = asint(-(asfloat(r0.z)) * 4 + 4);
		r3.xyz = i.texcoord6.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r0.w = asint(dot(r3.xyz, r3.xyz));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r3.xyz = asfloat(r0.www) * r3.xyz;
		r0.w = asint(dot(-(r3.xyz), i.texcoord2.xyz));
		r0.w = asint(asfloat(r0.w) + asfloat(r0.w));
		r4 = i.texcoord2.xyz * -(asfloat(r0.www)) + -(r3.xyz);
		r4 = r4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r0.w = asint(dot(r4.xyz, r4.xyz));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r4 = asfloat(r0.www) * r4.zxy;
		r4.x = saturate(r4.x);
		r0.w = asint(r4.x + 1);
		r0.w = asint(asfloat(r0.w) + asfloat(r0.w));
		r4.xy = r4.yz / asfloat(r0.ww);
		r4.xy = r4.xy + float2(0.5, 0.5);
		r4.xy = -(r4.xy) + float2(1, 1);
		r4 = DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, r4.xy, asfloat(r0.z)).xyz;
		r4 = r4.xyz * r4.xyz;
		r4 = r4.xyz * float3(16, 16, 16);
		r0.z = asint(saturate(dot(r3.xyz, i.texcoord2.xyz)));
		r0.w = asint(-(fresnelRolloff) + 1);
		r0.z = asint(-(asfloat(r0.z)) + 1.00001001);
		r1.w = asint(asfloat(r0.z) * asfloat(r0.z));
		r1.w = asint(asfloat(r1.w) * asfloat(r1.w));
		r0.z = asint(asfloat(r0.z) * asfloat(r1.w));
		r0.z = asint(fresnelRolloff * asfloat(r0.z) + asfloat(r0.w));
		r3.xyz = asfloat(r0.zzz) * r4.xyz;
	} else {
		r3.xyz = float3(0, 0, 0);
	}
	r3.xyz = r3.xyz * reflectivePower;
	r0.z = asint(saturate(globalScalars.w));
	r3.xyz = asfloat(r0.zzz) * r3.xyz;
	r0.z = asint(saturate(i.texcoord3.w + -1));
	r0.z = asint(asfloat(r0.z) * globalScalars2.z);
	o.sv_target.xyz = asfloat(r1.xyz) * i.texcoord3.xyz + asfloat(r0.zzz);
	o.sv_target1.xyz = r2.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = asint(saturate(asfloat(r0.x) * 0.00510204071));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	o.sv_target2.z = i.texcoord3.w * gAmbientOcclusionEffect.w;
	r0.xzw = asint(saturate(r3.xyz * float3(0.0625, 0.0625, 0.0625)));
	o.sv_target3.xyz = sqrt(asfloat(r0.xzw));
	o.sv_target.w = 0;
	o.sv_target1.w = globalScalars.x;
	o.sv_target2.x = asfloat(r0.y);
	o.sv_target2.w = globalScalars.x;
	o.sv_target3.w = globalScalars.x;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
