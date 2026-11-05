cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

cbuffer omni_light : register(b2)
{
	float4 gLightPosX : packoffset(c0);
	float4 gLightPosY : packoffset(c1);
	float4 gLightPosZ : packoffset(c2);
	float4 gLightDirX : packoffset(c3);
	float4 gLightDirY : packoffset(c4);
	float4 gLightDirZ : packoffset(c5);
	float4 gLightFallOff : packoffset(c6);
	float4 gLightConeScale : packoffset(c7);
	float4 gLightConeOffset : packoffset(c8);
	float4 gLightColR : packoffset(c9);
	float4 gLightColG : packoffset(c10);
	float4 gLightColB : packoffset(c11);
	float4 gLightAmbient0 : packoffset(c12);
	float4 gLightAmbient1 : packoffset(c13);
	float4 gLightAmbientDir0 : packoffset(c14);
	float4 gLightAmbientDir1 : packoffset(c15);
	float4 gLightPointColR : packoffset(c16);
	float4 gLightPointColG : packoffset(c17);
	float4 gLightPointColB : packoffset(c18);
	float4 gLightPointPosX : packoffset(c19);
	float4 gLightPointPosY : packoffset(c20);
	float4 gLightPointPosZ : packoffset(c21);
	float4 gLightDir2X : packoffset(c22);
	float4 gLightDir2Y : packoffset(c23);
	float4 gLightDir2Z : packoffset(c24);
	float4 gLightConeScale2 : packoffset(c25);
	float4 gLightConeOffset2 : packoffset(c26);
	float4 gLightPointFallOff : packoffset(c27);
	float4 gDistFadeParams : packoffset(c28);
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

cbuffer stipplingPattern : register(b3)
{
	float4 stipplePattern : packoffset(c0);
};

static const float4 icb[4] =
{
	float4(1, 0, 0, 0),
	float4(0, 1, 0, 0),
	float4(0, 0, 1, 0),
	float4(0, 0, 0, 1),
};

SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	noperspective float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
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
	int4 r2;
	r0 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r0.w = asint(asfloat(r0.w) * i.color.w);
	r1.w = asint(asfloat(r0.w) * globalScalars.x);
	r0.w = (asfloat(r1.w) >= 0.5) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r2.xyz = asint(i.texcoord6.xyz + -(gViewInverse[3].xyz));
	r1.z = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r1.z = asint(sqrt(asfloat(r1.z)));
	r1.z = asint(asfloat(r1.z) + -0.649999976);
	r1.z = asint(max(asfloat(r1.z), 0.25));
	r1.z = asint(min(asfloat(r1.z), 1));
	r1.z = asint(asfloat(r1.z) + -1);
	r1.z = asint(gDistFadeParams.x * asfloat(r1.z) + 1);
	r0.w = asint(asfloat(r0.w) * asfloat(r1.z));
	r2.xy = asint(i.sv_position.xy * float2(0.5, 0.5));
	r2.zw = (asfloat(r2.xy) >= -(asfloat(r2.xy))) ? -1 : 0;
	r2.xy = asint(frac(abs(asfloat(r2.xy))));
	r2.xy = (r2.zw != 0) ? r2.xy : asint(-(asfloat(r2.xy)));
	r2.xy = asint(asfloat(r2.xy) + asfloat(r2.xy));
	r2.xy = asint(floor(asfloat(r2.xy)));
	r1.z = asint(asfloat(r2.y) * 2 + asfloat(r2.x));
	r1.z = (uint)asfloat(r1.z);
	r1.z = asint(dot(stipplePattern, icb[r1.z]));
	r1.z = (asfloat(r1.z) >= asfloat(r0.w)) ? -1 : 0;
	if (r1.z != 0) discard;
	r2.xyz = asint(i.texcoord1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.z = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r1.z = asint(rsqrt(asfloat(r1.z)));
	r2.xyz = asint(asfloat(r1.zzz) * asfloat(r2.xyz));
	r1.z = asint(saturate(i.color.x + -1));
	o.sv_target.xyz = asfloat(r1.zzz) * globalScalars2.zzz + asfloat(r0.xyz);
	o.sv_target1.xyz = asfloat(r2.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target2.z = i.color.x * gAmbientOcclusionEffect.w;
	o.sv_target.w = asfloat(r0.w);
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
