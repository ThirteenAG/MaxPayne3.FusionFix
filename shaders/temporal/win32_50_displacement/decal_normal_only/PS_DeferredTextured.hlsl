cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
};

cbuffer CacheMegaVariables : register(b4)
{
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
};

SamplerState BumpSampler : register(s1);
Texture2D BumpTex : register(t1);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
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
	int3 r1;
	o.sv_target = float4(0, 0, 0, 0);
	r0 = BumpTex.Sample(BumpSampler, i.texcoord.xy);
	r1.x = asint(-(r0.w) + 1);
	r1.x = (asfloat(r1.x) < r0.x) ? -1 : 0;
	r1.x = r1.x & 1065353216;
	r1.yz = asint(-(r0.wy) + r0.xy);
	r0.xy = asfloat(r1.xx) * asfloat(r1.yz) + r0.wy;
	r0.z = r0.z * i.color.w;
	o.sv_target1.w = r0.z * globalScalars.x;
	r0.xy = r0.xy * float2(2, 2) + float2(-1, -1);
	r0.xy = r0.xy * bumpiness;
	r0.z = dot(r0.xy, r0.xy);
	r0.z = -(r0.z) + 1;
	r0.z = max(r0.z, 0);
	r0.z = sqrt(r0.z);
	r1 = asint(r0.xxx * i.texcoord4.xyz);
	r0.xzw = r0.zzz * i.texcoord1.xyz + asfloat(r1.xyz);
	r0.xyz = r0.yyy * i.texcoord5.xyz + r0.xzw;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.sv_target1.xyz = r0.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target2 = float4(0, 0, 0, 0);
	o.sv_target3 = float4(0, 0, 0, 0);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
