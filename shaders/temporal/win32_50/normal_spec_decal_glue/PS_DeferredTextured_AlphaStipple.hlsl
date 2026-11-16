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
	float specularFactor : packoffset(c0);
	float3 specMapIntMask : packoffset(c0.y);
	float4 specMapExpMask : packoffset(c1);
	float bumpiness : packoffset(c2);
	float reflectivePower : packoffset(c2.y);
	float fresnelRolloff : packoffset(c2.z);
	float3 specMapReflectMask : packoffset(c3);
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
SamplerState SpecSampler : register(s2);
SamplerState DynamicEnvironmentSampler : register(s13);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D SpecSampler_tex : register(t2);
Texture2D DynamicEnvironmentSampler_tex : register(t13);

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

	int4 r0;
	float4 r1;
	int4 r2;
	float4 r3;
	int4 r4;
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
	r2 = asint(SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy));
	r0.w = asint(dot(asfloat(r2), specMapExpMask));
	r0.w = asint(asfloat(r0.w) * specularFactor);
	r0.w = asint(max(asfloat(r0.w), 1));
	r3.xyz = asfloat(r0.xxx) * i.texcoord4.xyz;
	r3.xyz = asfloat(r0.zzz) * i.texcoord1.xyz + r3.xyz;
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + r3.xyz);
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r2.www));
	r2.w = (0 < reflectivePower) ? -1 : 0;
	if (r2.w != 0) {
		r2.w = asint(asfloat(r0.w) * 0.015625);
		r2.w = asint(min(asfloat(r2.w), 1));
		r2.w = asint(-(asfloat(r2.w)) * 4 + 4);
		r3.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r3.w = dot(r3.xyz, r3.xyz);
		r3.w = rsqrt(r3.w);
		r3.xyz = r3.www * r3.xyz;
		r3.w = dot(-(r3.xyz), asfloat(r0.xyz));
		r3.w = r3.w + r3.w;
		r4.xyz = asint(asfloat(r0.xyz) * -(r3.www) + -(r3.xyz));
		r4.xyz = asint(asfloat(r4.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r3.w = dot(asfloat(r4.xyz), asfloat(r4.xyz));
		r3.w = rsqrt(r3.w);
		r4.xyz = asint(r3.www * asfloat(r4.zxy));
		r4.x = asint(saturate(asfloat(r4.x)));
		r3.w = asfloat(r4.x) + 1;
		r3.w = r3.w + r3.w;
		r4.xy = asint(asfloat(r4.yz) / r3.ww);
		r4.xy = asint(asfloat(r4.xy) + float2(0.5, 0.5));
		r4.xy = asint(-(asfloat(r4.xy)) + float2(1, 1));
		r4.xyz = asint(DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, asfloat(r4.xy), asfloat(r2.w)).xyz);
		r4.xyz = asint(asfloat(r4.xyz) * asfloat(r4.xyz));
		r4.xyz = asint(asfloat(r4.xyz) * float3(16, 16, 16));
		r2.w = asint(saturate(dot(r3.xyz, asfloat(r0.xyz))));
		r3.x = -(fresnelRolloff) + 1;
		r2.w = asint(-(asfloat(r2.w)) + 1.00001001);
		r3.y = asfloat(r2.w) * asfloat(r2.w);
		r3.y = r3.y * r3.y;
		r2.w = asint(asfloat(r2.w) * r3.y);
		r2.w = asint(fresnelRolloff * asfloat(r2.w) + r3.x);
		r3.xyz = asfloat(r2.www) * asfloat(r4.xyz);
	} else {
		r3.xyz = float3(0, 0, 0);
	}
	r1.w = r1.w * i.color.w;
	r1.w = r1.w * globalScalars.x;
	r4.xy = asint(i.sv_position.xy * float2(0.5, 0.5));
	r4.zw = (asfloat(r4.xy) >= -(asfloat(r4.xy))) ? -1 : 0;
	r4.xy = asint(frac(abs(asfloat(r4.xy))));
	r4.xy = (r4.zw != 0) ? r4.xy : asint(-(asfloat(r4.xy)));
	r4.xy = asint(asfloat(r4.xy) + asfloat(r4.xy));
	r4.xy = asint(floor(asfloat(r4.xy)));
	r2.w = asint(asfloat(r4.y) * 2 + asfloat(r4.x));
	r2.w = (uint)asfloat(r2.w);
	r2.w = asint(dot(stipplePattern, icb[r2.w]));
	r2.w = (asfloat(r2.w) >= r1.w) ? -1 : 0;
	if (r2.w != 0) discard;
	o.sv_target2.x = dot(asfloat(r2.xyz), specMapIntMask);
	r3.xyz = r3.xyz * reflectivePower;
	r2.x = asint(dot(asfloat(r2.xyz), specMapReflectMask.xyz));
	r2.xyz = asint(asfloat(r2.xxx) * r3.xyz);
	r2.xyz = asint(asfloat(r2.xyz) * globalScalars.www);
	r2.w = asint(saturate(i.color.x + -1));
	o.sv_target.xyz = asfloat(r2.www) * globalScalars2.zzz + r1.xyz;
	o.sv_target1.xyz = asfloat(r0.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r0.x = asint(asfloat(r0.w) * 0.00510204071);
	r0.x = asint(min(asfloat(r0.x), 1));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	o.sv_target2.z = i.color.x * gAmbientOcclusionEffect.w;
	r0.xyz = asint(saturate(asfloat(r2.xyz) * float3(0.0625, 0.0625, 0.0625)));
	o.sv_target3.xyz = sqrt(asfloat(r0.xyz));
	o.sv_target.w = r1.w;
	o.sv_target1.w = r1.w;
	o.sv_target2.w = r1.w;
	o.sv_target3.w = r1.w;

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
