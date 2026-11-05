cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
SamplerState imposterSampler : register(s1);
SamplerState blitSampler : register(s2);
Texture2D imposterSampler_tex : register(t1);
Texture2D blitSampler_tex : register(t2);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
	float4 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
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
	float4 r1;
	float4 r2;
	float3 r3;
	r0 = asint(imposterSampler_tex.Sample(imposterSampler, i.texcoord.xy));
	r1 = asfloat(r0) * float4(15.9377499, 15.9377499, 15.9377499, 15.9377499);
	r1 = frac(r1);
	r1 = r1 * float4(16, 16, 16, 16);
	r0 = asint(asfloat(r0) * float4(255.003998, 255.003998, 255.003998, 255.003998) + -(r1));
	r0 = asint(asfloat(r0) * float4(0.0625, 0.0625, 0.0625, 0.0625));
	r2.x = dot(r1, i.texcoord1);
	r2.y = dot(asfloat(r0), i.texcoord2);
	r2.x = r2.y + r2.x;
	r1.x = dot(r1, i.texcoord3);
	r0.x = asint(dot(asfloat(r0), i.texcoord4));
	r0.x = asint(asfloat(r0.x) + r1.x);
	r0.y = asint(saturate(r2.x));
	r0.z = asint(saturate(asfloat(r0.x)));
	r0.z = asint(asfloat(r0.z) * i.texcoord.w);
	r0.y = asint(asfloat(r0.y) * i.texcoord.z + asfloat(r0.z));
	r0.y = asint(asfloat(r0.y) * i.color.w);
	r0.z = (asfloat(r0.y) < 0.5) ? -1 : 0;
	if (r0.z != 0) discard;
	r1.xyz = imposterSampler_tex.Sample(imposterSampler, float2(0.9921875, 0.0078125)).xyz;
	r0.z = asint(floor(r2.x));
	r2.x = asfloat(r0.z) * 0.0625;
	r2.yw = float2(0.5, 0.5);
	r3 = blitSampler_tex.Sample(blitSampler, r2.xy).xyz;
	r3 = r3.xyz * float3(2, 2, 2) + float3(-1, -1, -1);
	r0.x = asint(floor(asfloat(r0.x)));
	r2.z = asfloat(r0.x) * 0.0625;
	r0.xzw = asint(blitSampler_tex.Sample(blitSampler, r2.zw).xyz);
	r0.xzw = asint(asfloat(r0.xzw) * float3(2, 2, 2) + float3(-1, -1, -1));
	r0.xzw = asint(asfloat(r0.xzw) * i.texcoord.www);
	r0.xzw = asint(r3.xyz * i.texcoord.zzz + asfloat(r0.xzw));
	r0.xzw = asint(asfloat(r0.xzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = dot(asfloat(r0.xzw), asfloat(r0.xzw));
	r1.w = rsqrt(r1.w);
	r0.xzw = asint(asfloat(r0.xzw) * r1.www);
	r2.xyz = asfloat(r0.zzz) * i.texcoord6.xyz;
	r2.xyz = i.texcoord5.xyz * asfloat(r0.xxx) + r2.xyz;
	r0.xzw = asint(i.texcoord7.xyz * asfloat(r0.www) + r2.xyz);
	o.sv_target1.xyz = asfloat(r0.xzw) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target.xyz = r1.xyz;
	o.sv_target.w = asfloat(r0.y);
	o.sv_target1.w = 0;
	o.sv_target2 = float4(0, 0.5, 0.5, 0);
	o.sv_target3.xyz = float3(0, 0, 0);
	o.sv_target3.w = asfloat(r0.y);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
