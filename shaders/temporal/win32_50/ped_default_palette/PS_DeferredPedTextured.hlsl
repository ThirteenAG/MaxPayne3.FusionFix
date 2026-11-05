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

	float4 r0;
	int4 r1;
	int4 r2;
	float4 r3;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r1.xyz = asint(i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r1.w = asint(r0.w * 255.009995);
	r1.w = asint(floor(asfloat(r1.w)));
	r2.x = (asfloat(r1.w) >= 32) ? -1 : 0;
	r2.y = (160 >= asfloat(r1.w)) ? -1 : 0;
	r2.x = r2.y & r2.x;
	r1.w = asint(asfloat(r1.w) + -32);
	r3.x = asfloat(r1.w) * 0.0078125;
	r3.y = paletteSelector;
	r3 = TextureSamplerDiffPal_tex.Sample(TextureSamplerDiffPal, r3.xy);
	if (r2.x != 0) {
		r1.w = asint(-(r3.w) + 1);
		r2.xyz = asint(r0.xyz * asfloat(r1.www));
		r0.xyz = r3.xyz * r3.www + asfloat(r2.xyz);
		r0.w = 1;
	}
	r1.w = (0 < gBloodData.w) ? -1 : 0;
	if (r1.w != 0) {
		r2.xyw = asint(BloodSampler_tex.Sample(BloodSampler, i.texcoord.zw).xyw);
		r2.z = asint(min(asfloat(r2.y), asfloat(r2.x)));
		r1.w = asint(saturate(asfloat(r2.x) * 0.5 + asfloat(r2.w)));
		r2.xyz = asint(-(r0.xyz) + asfloat(r2.xyz));
		r0.xyz = asfloat(r1.www) * asfloat(r2.xyz) + r0.xyz;
	}
	r0.w = r0.w * i.texcoord2.w;
	o.sv_target.xyz = r0.xyz * matMaterialColorScale.xxx;
	r0.x = saturate(gAmbientOcclusionEffect.z);
	r0.x = saturate(r0.x + i.texcoord2.x);
	o.sv_target1.xyz = asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target2.z = r0.x * gAmbientOcclusionEffect.w;
	r0.w = r0.w * globalScalars.x;
	o.sv_target.w = r0.w;
	o.sv_target1.w = r0.w;
	r0.xy = float2(0, 0.25);
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
