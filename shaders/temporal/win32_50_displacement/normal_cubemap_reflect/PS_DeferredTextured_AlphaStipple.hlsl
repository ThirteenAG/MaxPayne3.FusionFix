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

cbuffer stipplingPattern : register(b3)
{
	float4 stipplePattern : packoffset(c0);
};

cbuffer CacheMegaVariables : register(b4)
{
	float bumpiness : packoffset(c0);
	float reflectivePower : packoffset(c0.y);
};

static const float4 icb[4] =
{
	float4(1, 0, 0, 0),
	float4(0, 1, 0, 0),
	float4(0, 0, 1, 0),
	float4(0, 0, 0, 1),
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState EnvironmentSampler : register(s2);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpTex : register(t1);
TextureCube EnvironmentSampler_tex : register(t2);

struct PS_IN
{
	noperspective float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
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

	float4 r0;
	int4 r1;
	float3 r2;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.w = r0.w * i.color.w;
	r0.w = r0.w * globalScalars.x;
	r1.xy = asint(i.sv_position.xy * float2(0.5, 0.5));
	r1.zw = (asfloat(r1.xy) >= -(asfloat(r1.xy))) ? -1 : 0;
	r1.xy = asint(frac(abs(asfloat(r1.xy))));
	r1.xy = (r1.zw != 0) ? r1.xy : asint(-(asfloat(r1.xy)));
	r1.xy = asint(asfloat(r1.xy) + asfloat(r1.xy));
	r1.xy = asint(floor(asfloat(r1.xy)));
	r1.x = asint(asfloat(r1.y) * 2 + asfloat(r1.x));
	r1.x = (uint)asfloat(r1.x);
	r1.x = asint(dot(stipplePattern, icb[r1.x]));
	r1.x = (asfloat(r1.x) >= r0.w) ? -1 : 0;
	if (r1.x != 0) discard;
	r1.xyz = asint(BumpTex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r1.w = asint(-(asfloat(r1.z)) + 1);
	r1.w = (asfloat(r1.w) < asfloat(r1.x)) ? -1 : 0;
	r1.w = r1.w & 1065353216;
	r2.xy = -(asfloat(r1.zy)) + asfloat(r1.xy);
	r1.xy = asint(asfloat(r1.ww) * r2.xy + asfloat(r1.zy));
	r1.xy = asint(asfloat(r1.xy) * float2(2, 2) + float2(-1, -1));
	r1.xy = asint(asfloat(r1.xy) * bumpiness);
	r1.z = asint(dot(asfloat(r1.xy), asfloat(r1.xy)));
	r1.z = asint(-(asfloat(r1.z)) + 1);
	r1.z = asint(max(asfloat(r1.z), 0));
	r1.z = asint(sqrt(asfloat(r1.z)));
	r2 = asfloat(r1.xxx) * i.texcoord4.xyz;
	r1.xzw = asint(asfloat(r1.zzz) * i.texcoord1.xyz + r2.xyz);
	r1.xyz = asint(asfloat(r1.yyy) * i.texcoord5.xyz + asfloat(r1.xzw));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r2 = i.texcoord3.xzy + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r2.xyz, r2.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2 = asfloat(r1.www) * r2.xyz;
	r1.w = asint(dot(-(r2.xzy), asfloat(r1.xyz)));
	r1.w = asint(asfloat(r1.w) + asfloat(r1.w));
	r2 = asfloat(r1.xzy) * -(asfloat(r1.www)) + -(r2.xyz);
	r2 = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r2.xyz, r2.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2 = asfloat(r1.www) * r2.xyz;
	r2 = EnvironmentSampler_tex.Sample(EnvironmentSampler, r2.xyz).xyz;
	r2 = r2.xyz * reflectivePower;
	r2 = r2.xyz * globalScalars.www;
	r1.w = asint(saturate(i.color.x + -1));
	o.sv_target.xyz = asfloat(r1.www) * globalScalars2.zzz + r0.xyz;
	o.sv_target1.xyz = asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target2.z = i.color.x * gAmbientOcclusionEffect.w;
	r0.xyz = saturate(r2.xyz * float3(0.0625, 0.0625, 0.0625));
	o.sv_target3.xyz = sqrt(r0.xyz);
	o.sv_target.w = r0.w;
	o.sv_target1.w = r0.w;
	o.sv_target2.xy = float2(0, 0.25);
	o.sv_target2.w = r0.w;
	o.sv_target3.w = r0.w;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
