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

cbuffer CachePedParam : register(b4)
{
	float ArmourStrength : packoffset(c0);
	float displacementScale : packoffset(c0.y);
	float4 matMaterialColorScale : packoffset(c1);
	float4 gBloodData : packoffset(c2);
};

cbuffer PedPalette : register(b7)
{
	float paletteSelector : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BloodSampler : register(s2);
SamplerState TextureSamplerDiffPal : register(s4);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BloodSampler_tex : register(t2);
Texture2D TextureSamplerDiffPal_tex : register(t4);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
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
	r0 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r1.x = asint(asfloat(r0.w) * 255.009995);
	r1.x = asint(floor(asfloat(r1.x)));
	r1.y = (asfloat(r1.x) >= 32) ? -1 : 0;
	r1.z = (160 >= asfloat(r1.x)) ? -1 : 0;
	r1.y = r1.z & r1.y;
	r1.x = asint(asfloat(r1.x) + -32);
	r2.x = asfloat(r1.x) * 0.0078125;
	r2.y = paletteSelector;
	r2 = TextureSamplerDiffPal_tex.Sample(TextureSamplerDiffPal, r2.xy);
	if (r1.y != 0) {
		r1.x = asint(-(r2.w) + 1);
		r1.xyz = asint(asfloat(r0.xyz) * asfloat(r1.xxx));
		r0.xyz = asint(r2.xyz * r2.www + asfloat(r1.xyz));
		r0.w = 1065353216;
	}
	r1.x = (0 < gBloodData.w) ? -1 : 0;
	if (r1.x != 0) {
		r1.xyw = asint(BloodSampler_tex.Sample(BloodSampler, i.texcoord.zw).xyw);
		r1.z = asint(min(asfloat(r1.y), asfloat(r1.x)));
		r1.w = asint(saturate(asfloat(r1.x) * 0.5 + asfloat(r1.w)));
		r1.xyz = asint(-(asfloat(r0.xyz)) + asfloat(r1.xyz));
		r0.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz) + asfloat(r0.xyz));
	}
	r0.w = asint(asfloat(r0.w) * i.texcoord2.w);
	r1.w = asint(asfloat(r0.w) * globalScalars.x);
	r0.w = (g_AlphaRef >= asfloat(r1.w)) ? -1 : 0;
	if (r0.w != 0) discard;
	r2.xyz = i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = asint(dot(r2.xyz, r2.xyz));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r2.xyz = asfloat(r0.www) * r2.xyz;
	o.sv_target.xyz = asfloat(r0.xyz) * matMaterialColorScale.xxx;
	r0.x = asint(saturate(gAmbientOcclusionEffect.z));
	r0.x = asint(saturate(asfloat(r0.x) + i.texcoord2.x));
	o.sv_target1.xyz = r2.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	o.sv_target.w = asfloat(r1.w);
	o.sv_target1.w = asfloat(r1.w);
	r1.xy = int2(0, 1048576000);
	o.sv_target2.xyw = asfloat(r1.xyw);
	o.sv_target3 = asfloat(r1.xxxw);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
