cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer CacheTerrainCB : register(b1)
{
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float specularFactor1 : packoffset(c0.z);
	float specularColorFactor1 : packoffset(c0.w);
	float specularFactor2 : packoffset(c1);
	float specularColorFactor2 : packoffset(c1.y);
	float specularFactor3 : packoffset(c1.z);
	float specularColorFactor3 : packoffset(c1.w);
	float bumpiness : packoffset(c2);
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
SamplerState TextureSampler_layer2 : register(s5);
SamplerState BumpSampler_layer2 : register(s6);
SamplerState SpecSampler_layer23 : register(s7);
SamplerState TextureSampler_layer3 : register(s8);
SamplerState BumpSampler_layer3 : register(s9);
Texture2D TextureSampler_layer0_tex : register(t0);
Texture2D BumpSampler_layer0_tex : register(t1);
Texture2D SpecSampler_layer01_tex : register(t2);
Texture2D TextureSampler_layer1_tex : register(t3);
Texture2D BumpSampler_layer1_tex : register(t4);
Texture2D TextureSampler_layer2_tex : register(t5);
Texture2D BumpSampler_layer2_tex : register(t6);
Texture2D SpecSampler_layer23_tex : register(t7);
Texture2D TextureSampler_layer3_tex : register(t8);
Texture2D BumpSampler_layer3_tex : register(t9);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 color : COLOR;
	float3 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
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
	float3 r3;
	float3 r4;
	r0.x = asint(saturate(i.texcoord3.w + -1));
	r0.x = asint(asfloat(r0.x) * globalScalars2.z);
	r0.yzw = asint(TextureSampler_layer3_tex.SampleBias(TextureSampler_layer3, i.texcoord.xy, -1.29999995).xyz);
	r1.xyz = TextureSampler_layer2_tex.SampleBias(TextureSampler_layer2, i.texcoord.xy, -1.29999995).xyz;
	r2.xyz = TextureSampler_layer0_tex.SampleBias(TextureSampler_layer0, i.texcoord.xy, -1.29999995).xyz;
	r3 = TextureSampler_layer1_tex.SampleBias(TextureSampler_layer1, i.texcoord.xy, -1.29999995).xyz;
	r4 = -(i.color.xyz) + float3(1, 1, 1);
	r1.w = r4.y * r4.x;
	r2.w = r1.w * i.color.z;
	r1.w = r4.z * r1.w;
	r3 = r2.www * r3.xyz;
	r2.xyz = r2.xyz * r1.www + r3.xyz;
	r3.x = r4.x * i.color.y;
	r3.y = r4.z * r3.x;
	r3.x = r3.x * i.color.z;
	r1.xyz = r1.xyz * r3.yyy + r2.xyz;
	r0.yzw = asint(asfloat(r0.yzw) * r3.xxx + r1.xyz);
	o.sv_target.xyz = asfloat(r0.yzw) * i.texcoord3.xyz + asfloat(r0.xxx);
	o.sv_target.w = 0;
	r0.xyz = asint(BumpSampler_layer1_tex.Sample(BumpSampler_layer1, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = -(asfloat(r0.zy)) + asfloat(r0.xy);
	r0.xy = asint(asfloat(r0.ww) * r1.xy + asfloat(r0.zy));
	r0.xy = asint(r2.ww * asfloat(r0.xy));
	r1.xyz = BumpSampler_layer0_tex.Sample(BumpSampler_layer0, i.texcoord.xy).xyw;
	r0.z = asint(-(r1.z) + 1);
	r0.z = (asfloat(r0.z) < r1.x) ? -1 : 0;
	r0.z = r0.z & 1065353216;
	r2.xy = -(r1.zy) + r1.xy;
	r0.zw = asint(asfloat(r0.zz) * r2.xy + r1.zy);
	r0.xy = asint(asfloat(r0.zw) * r1.ww + asfloat(r0.xy));
	r1.xyz = BumpSampler_layer2_tex.Sample(BumpSampler_layer2, i.texcoord.xy).xyw;
	r0.z = asint(-(r1.z) + 1);
	r0.z = (asfloat(r0.z) < r1.x) ? -1 : 0;
	r0.z = r0.z & 1065353216;
	r2.xy = -(r1.zy) + r1.xy;
	r0.zw = asint(asfloat(r0.zz) * r2.xy + r1.zy);
	r0.xy = asint(asfloat(r0.zw) * r3.yy + asfloat(r0.xy));
	r1.xyz = BumpSampler_layer3_tex.Sample(BumpSampler_layer3, i.texcoord.xy).xyw;
	r0.z = asint(-(r1.z) + 1);
	r0.z = (asfloat(r0.z) < r1.x) ? -1 : 0;
	r0.z = r0.z & 1065353216;
	r2.xy = -(r1.zy) + r1.xy;
	r0.zw = asint(asfloat(r0.zz) * r2.xy + r1.zy);
	r0.xy = asint(asfloat(r0.zw) * r3.xx + asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.xy) + float2(-0.5, -0.5));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.xy = asint(asfloat(r0.xy) + asfloat(r0.xy));
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(max(asfloat(r0.z), 0));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r1.xyz = asfloat(r0.xxx) * i.texcoord4.xyz;
	r0.xzw = asint(i.texcoord2.xyz * asfloat(r0.zzz) + r1.xyz);
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r0.xzw));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	o.sv_target1.xyz = asfloat(r0.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = globalScalars.x;
	r0 = asint(SpecSampler_layer01_tex.Sample(SpecSampler_layer01, i.texcoord.xy));
	r0 = asint(asfloat(r0) * float4(specularFactor, specularColorFactor, specularFactor1, specularColorFactor1));
	r0.zw = asint(r2.ww * asfloat(r0.zw));
	r0.xy = asint(asfloat(r0.xy) * r1.ww + asfloat(r0.zw));
	r1 = SpecSampler_layer23_tex.Sample(SpecSampler_layer23, i.texcoord.xy);
	r1 = r1 * float4(specularFactor2, specularColorFactor2, specularFactor3, specularColorFactor3);
	r0.xy = asint(r1.xy * r3.yy + asfloat(r0.xy));
	r0.xy = asint(r1.zw * r3.xx + asfloat(r0.xy));
	o.sv_target2.x = asfloat(r0.y);
	r0.x = asint(saturate(asfloat(r0.x) * 0.00510204071));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	o.sv_target2.z = i.texcoord3.w * gAmbientOcclusionEffect.w;
	o.sv_target2.w = globalScalars.x;
	o.sv_target3.xyz = float3(0, 0, 0);
	o.sv_target3.w = globalScalars.x;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
