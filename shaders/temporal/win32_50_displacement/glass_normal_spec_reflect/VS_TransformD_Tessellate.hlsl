cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct TemporalVertexResult
{
	float4 texcoord8 : TEXCOORD8;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
};
struct VS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_color : TEMPORAL1;
	float2 temporalInput_texcoord : TEMPORAL2;
	float4 temporalInput_texcoord1 : TEMPORAL3;
	float3 temporalInput_texcoord3 : TEMPORAL4;
	float3 temporalInput_texcoord4 : TEMPORAL5;
	float3 temporalInput_texcoord5 : TEMPORAL6;
	float4 temporalInput_texcoord6 : TEMPORAL7;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	row_major float4x4 Temporal_b0_o192_gViewInverse : packoffset(c13);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	float4 r0;
	float3 r1;
	float3 r2;
	o.texcoord8.xyz = i.position.xyz;
	o.texcoord8.w = 1;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * gWorld[1].xyz;
	r0.xyz = i.normal.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord1.xyz = r0.xyz;
	o.texcoord1.w = 1;
	r1 = i.position.yyy * gWorld[1].xyz;
	r1 = i.position.xxx * gWorld[0].xyz + r1.xyz;
	r1 = i.position.zzz * gWorld[2].xyz + r1.xyz;
	r1 = r1.xyz + gWorld[3].xyz;
	o.texcoord3 = -(r1.xyz) + gViewInverse[3].xyz;
	o.texcoord6.xyz = r1.xyz;
	r1 = i.tangent.yyy * gWorld[1].xyz;
	r1 = i.tangent.xxx * gWorld[0].xyz + r1.xyz;
	r1 = i.tangent.zzz * gWorld[2].xyz + r1.xyz;
	r1 = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1 = r0.www * r1.xyz;
	o.texcoord4 = r1.xyz;
	r2 = r0.yzx * r1.zxy;
	r0.xyz = r1.yzx * r0.zxy + -(r2.xyz);
	o.texcoord5 = r0.xyz * i.tangent.www;
	o.texcoord6.w = 1;

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	float4 r0;
	float3 r1;
	float3 r2;
	o.texcoord8.xyz = i.position.xyz;
	o.texcoord8.w = 1;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord1.xyz = r0.xyz;
	o.texcoord1.w = 1;
	r1 = i.position.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r1 = i.position.xxx * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	r1 = i.position.zzz * Temporal_b0_o0_gWorld[2].xyz + r1.xyz;
	r1 = r1.xyz + Temporal_b0_o0_gWorld[3].xyz;
	o.texcoord3 = -(r1.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord6.xyz = r1.xyz;
	r1 = i.tangent.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r1 = i.tangent.xxx * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	r1 = i.tangent.zzz * Temporal_b0_o0_gWorld[2].xyz + r1.xyz;
	r1 = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1 = r0.www * r1.xyz;
	o.texcoord4 = r1.xyz;
	r2 = r0.yzx * r1.zxy;
	r0.xyz = r1.yzx * r0.zxy + -(r2.xyz);
	o.texcoord5 = r0.xyz * i.tangent.www;
	o.texcoord6.w = 1;

	return o;
}

VS_OUT main(VS_IN i)
{
    TemporalVertexResult c = TemporalCurrent(i);
    VS_OUT o;
    o.texcoord8 = c.texcoord8;
    o.color = c.color;
    o.texcoord = c.texcoord;
    o.texcoord1 = c.texcoord1;
    o.texcoord3 = c.texcoord3;
    o.texcoord4 = c.texcoord4;
    o.texcoord5 = c.texcoord5;
    o.texcoord6 = c.texcoord6;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_color = o.color;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord1 = o.texcoord1;
    o.temporalInput_texcoord3 = o.texcoord3;
    o.temporalInput_texcoord4 = o.texcoord4;
    o.temporalInput_texcoord5 = o.texcoord5;
    o.temporalInput_texcoord6 = o.texcoord6;
    [branch] if (TemporalState.x > 0)
    {
        TemporalVertexResult p = TemporalVertexPrevious(i);
        o.temporalInput_texcoord8 = p.texcoord8;
        o.temporalInput_color = p.color;
        o.temporalInput_texcoord = p.texcoord;
        o.temporalInput_texcoord1 = p.texcoord1;
        o.temporalInput_texcoord3 = p.texcoord3;
        o.temporalInput_texcoord4 = p.texcoord4;
        o.temporalInput_texcoord5 = p.texcoord5;
        o.temporalInput_texcoord6 = p.texcoord6;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
