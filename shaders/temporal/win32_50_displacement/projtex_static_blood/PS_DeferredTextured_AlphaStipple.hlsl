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
	float specularColorFactor : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
	float reflectivePower : packoffset(c0.w);
	float fresnelRolloff : packoffset(c1);
	float HardAlphaBlend : packoffset(c1.y);
};

static const float4 icb[4] =
{
	float4(1, 0, 0, 0),
	float4(0, 1, 0, 0),
	float4(0, 0, 1, 0),
	float4(0, 0, 0, 1),
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s2);
SamplerState DynamicEnvironmentSampler : register(s13);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpTex : register(t2);
Texture2D DynamicEnvironmentSampler_tex : register(t13);

struct PS_IN
{
	noperspective float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float2 texcoord7 : TEXCOORD7;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float4 texcoord2 : TEXCOORD2;
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
	int4 r3;
	r0.xy = asint(max(i.texcoord.xy, i.texcoord2.xz));
	r0.xy = asint(min(asfloat(r0.xy), i.texcoord2.yw));
	r0.zw = asint(saturate(asfloat(r0.xy)));
	r1.xyz = BumpTex.Sample(BumpSampler, asfloat(r0.xy)).xyw;
	r0.x = asint(-(r1.z) + 1);
	r0.x = (asfloat(r0.x) < r1.x) ? -1 : 0;
	r0.x = r0.x & 1065353216;
	r1.xw = -(r1.zy) + r1.xy;
	r0.xy = asint(asfloat(r0.xx) * r1.xw + r1.zy);
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, asfloat(r0.zw));
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(max(asfloat(r0.z), 0));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r0.w = asint(max(specularFactor, 1));
	r2.xyz = asint(asfloat(r0.xxx) * i.texcoord4.xyz);
	r2.xyz = asint(asfloat(r0.zzz) * i.texcoord1.xyz + asfloat(r2.xyz));
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r2.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.x = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r2.x = asint(rsqrt(asfloat(r2.x)));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r2.xxx));
	r2.x = (0 < reflectivePower) ? -1 : 0;
	if (r2.x != 0) {
		r2.x = asint(asfloat(r0.w) * 0.015625);
		r2.x = asint(min(asfloat(r2.x), 1));
		r2.x = asint(-(asfloat(r2.x)) * 4 + 4);
		r2.yzw = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r3.x = asint(dot(asfloat(r2.yzw), asfloat(r2.yzw)));
		r3.x = asint(rsqrt(asfloat(r3.x)));
		r2.yzw = asint(asfloat(r2.yzw) * asfloat(r3.xxx));
		r3.x = asint(dot(-(asfloat(r2.yzw)), asfloat(r0.xyz)));
		r3.x = asint(asfloat(r3.x) + asfloat(r3.x));
		r3.xyz = asint(asfloat(r0.xyz) * -(asfloat(r3.xxx)) + -(asfloat(r2.yzw)));
		r3.xyz = asint(asfloat(r3.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r3.w = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
		r3.w = asint(rsqrt(asfloat(r3.w)));
		r3.xyz = asint(asfloat(r3.www) * asfloat(r3.zxy));
		r3.x = asint(saturate(asfloat(r3.x)));
		r3.x = asint(asfloat(r3.x) + 1);
		r3.x = asint(asfloat(r3.x) + asfloat(r3.x));
		r3.xy = asint(asfloat(r3.yz) / asfloat(r3.xx));
		r3.xy = asint(asfloat(r3.xy) + float2(0.5, 0.5));
		r3.xy = asint(-(asfloat(r3.xy)) + float2(1, 1));
		r3.xyz = asint(DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, asfloat(r3.xy), asfloat(r2.x)).xyz);
		r3.xyz = asint(asfloat(r3.xyz) * asfloat(r3.xyz));
		r3.xyz = asint(asfloat(r3.xyz) * float3(16, 16, 16));
		r2.x = asint(saturate(dot(asfloat(r2.yzw), asfloat(r0.xyz))));
		r2.y = asint(-(fresnelRolloff) + 1);
		r2.x = asint(-(asfloat(r2.x)) + 1.00001001);
		r2.z = asint(asfloat(r2.x) * asfloat(r2.x));
		r2.z = asint(asfloat(r2.z) * asfloat(r2.z));
		r2.x = asint(asfloat(r2.z) * asfloat(r2.x));
		r2.x = asint(fresnelRolloff * asfloat(r2.x) + asfloat(r2.y));
		r2.xyz = asint(asfloat(r2.xxx) * asfloat(r3.xyz));
	} else {
		r2.xyz = int3(0, 0, 0);
	}
	r2.w = asint(r1.w + -0.00999999978);
	r2.w = (asfloat(r2.w) < 0) ? -1 : 0;
	if (r2.w != 0) discard;
	r1.w = r1.w * i.color.w;
	r1.w = r1.w * globalScalars.x;
	r3.xy = asint(i.sv_position.xy * float2(0.5, 0.5));
	r3.zw = (asfloat(r3.xy) >= -(asfloat(r3.xy))) ? -1 : 0;
	r3.xy = asint(frac(abs(asfloat(r3.xy))));
	r3.xy = (r3.zw != 0) ? r3.xy : asint(-(asfloat(r3.xy)));
	r3.xy = asint(asfloat(r3.xy) + asfloat(r3.xy));
	r3.xy = asint(floor(asfloat(r3.xy)));
	r2.w = asint(asfloat(r3.y) * 2 + asfloat(r3.x));
	r2.w = (uint)asfloat(r2.w);
	r2.w = asint(dot(stipplePattern, icb[r2.w]));
	r2.w = (asfloat(r2.w) >= r1.w) ? -1 : 0;
	if (r2.w != 0) discard;
	r2.xyz = asint(asfloat(r2.xyz) * reflectivePower);
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
	o.sv_target2.x = specularColorFactor;
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
