cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
};

cbuffer AlphaTest : register(b11)
{
	float g_AlphaRef : packoffset(c0);
};

cbuffer CacheMegaVariables : register(b4)
{
	float3 dirtDecalMask : packoffset(c0);
	float specularFactor : packoffset(c0.w);
	float specularColorFactor : packoffset(c1);
};

SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
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
	r0.xyz = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).xyz);
	r0.x = asint(dot(asfloat(r0.xyz), dirtDecalMask.xyz));
	r0.x = asint(asfloat(r0.x) * i.color.w);
	r0.w = asint(asfloat(r0.x) * globalScalars.x);
	r0.x = (g_AlphaRef >= asfloat(r0.w)) ? -1 : 0;
	if (r0.x != 0) discard;
	r0.x = asint(max(specularFactor, 1));
	r0.x = asint(asfloat(r0.x) * 0.00510204071);
	r0.x = asint(min(asfloat(r0.x), 1));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	o.sv_target.xyz = i.color.xyz;
	o.sv_target.w = asfloat(r0.w);
	o.sv_target1 = float4(0, 0, 0, 0);
	o.sv_target2.x = specularColorFactor;
	r0.z = 0;
	o.sv_target2.zw = asfloat(r0.zw);
	o.sv_target3 = asfloat(r0.zzzw);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
