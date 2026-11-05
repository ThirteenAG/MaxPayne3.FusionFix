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

SamplerState TextureSampler_layer0 : register(s0);
SamplerState TextureSampler_layer1 : register(s1);
SamplerState TextureSampler_layer2 : register(s2);
SamplerState TextureSampler_layer3 : register(s3);
Texture2D TextureSampler_layer0_tex : register(t0);
Texture2D TextureSampler_layer1_tex : register(t1);
Texture2D TextureSampler_layer2_tex : register(t2);
Texture2D TextureSampler_layer3_tex : register(t3);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
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

	float4 r0;
	float4 r1;
	r0 = TextureSampler_layer1_tex.Sample(TextureSampler_layer1, i.texcoord.zw);
	r0.w = r0.w * i.texcoord5.y;
	r1.xyz = TextureSampler_layer0_tex.Sample(TextureSampler_layer0, i.texcoord.xy).xyz;
	r0.xyz = r0.xyz + -(r1.xyz);
	r0.xyz = r0.www * r0.xyz + r1.xyz;
	r1 = TextureSampler_layer2_tex.Sample(TextureSampler_layer2, i.texcoord1.xy);
	r1.xyz = -(r0.xyz) + r1.xyz;
	r0.w = r1.w * i.texcoord5.z;
	r0.xyz = r0.www * r1.xyz + r0.xyz;
	r1 = TextureSampler_layer3_tex.Sample(TextureSampler_layer3, i.texcoord1.zw);
	r1.xyz = -(r0.xyz) + r1.xyz;
	r0.w = r1.w * i.texcoord5.w;
	r0.xyz = r0.www * r1.xyz + r0.xyz;
	r0.w = saturate(i.texcoord6.w + -1);
	r0.w = r0.w * globalScalars2.z;
	o.sv_target.xyz = r0.xyz * i.texcoord6.xyz + r0.www;
	o.sv_target.w = 0;
	o.sv_target1.xyz = i.texcoord3.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = globalScalars.x;
	o.sv_target2.z = i.texcoord6.w * gAmbientOcclusionEffect.w;
	r0.xy = float2(0, 0.25);
	r0.w = globalScalars.x;
	o.sv_target2.xyw = r0.xyw;
	o.sv_target3 = r0.xxxw;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
