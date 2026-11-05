cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
};

cbuffer Droop : register(b4)
{
	float3 droopParams : packoffset(c0);
	float2 gravityDroop : packoffset(c1);
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
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float3 texcoord9 : TEXCOORD9;
};
struct VS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float3 texcoord9 : TEXCOORD9;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float2 temporalInput_texcoord : TEMPORAL1;
	float4 temporalInput_texcoord1 : TEMPORAL2;
	float4 temporalInput_texcoord2 : TEMPORAL3;
	float3 temporalInput_texcoord4 : TEMPORAL4;
	float4 temporalInput_texcoord5 : TEMPORAL5;
	float4 temporalInput_texcoord6 : TEMPORAL6;
	float3 temporalInput_texcoord9 : TEMPORAL7;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	float3 Temporal_b4_o0_droopParams : packoffset(c13);
	float2 Temporal_b4_o16_gravityDroop : packoffset(c14);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	float4 r0;
	float3 r1;
	r0.xy = i.position.xy;
	r0.w = dot(i.position.xy, i.position.xy);
	r1.x = r0.w * droopParams.x;
	r0.w = r0.w * gravityDroop.x;
	r1.x = r1.x * gravityDroop.x;
	r0.z = -(r1.x) * 0.00999999978 + i.position.z;
	r1 = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = dot(r1.xyz, r1.xyz);
	r0.x = rsqrt(r0.x);
	r1 = r0.xxx * r1.xyz;
	r0.x = dot(r1.xzy, float3(0.707106769, 0.707106769, 0.00000707099707));
	r0.x = r0.x + gravityDroop.y;
	r0.x = r0.x * droopParams.z;
	r0.x = sin(r0.x);
	r0.y = droopParams.y * 0.00999999978;
	r0.y = r0.y * r0.w;
	r0.x = -(r0.y) * r0.x + r0.z;
	o.texcoord8.z = r0.x;
	o.texcoord8.xy = i.position.xy;
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord.xy;
	r0.y = i.position.y * gWorldViewProj[1].w;
	r0.y = i.position.x * gWorldViewProj[0].w + r0.y;
	r0.y = r0.x * gWorldViewProj[2].w + r0.y;
	o.texcoord1.w = r0.y + gWorldViewProj[3].w;
	r0.yzw = i.normal.yyy * gWorld[1].xyz;
	r0.yzw = i.normal.xxx * gWorld[0].xyz + r0.yzw;
	r0.yzw = i.normal.zzz * gWorld[2].xyz + r0.yzw;
	r0.yzw = r0.yzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = dot(r0.yzw, r0.yzw);
	r1.x = rsqrt(r1.x);
	o.texcoord1.xyz = r0.yzw * r1.xxx;
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r0.yzw = i.tangent.yyy * gWorld[1].xyz;
	r0.yzw = i.tangent.xxx * gWorld[0].xyz + r0.yzw;
	r0.yzw = i.tangent.zzz * gWorld[2].xyz + r0.yzw;
	r0.yzw = r0.yzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = dot(r0.yzw, r0.yzw);
	r1.x = rsqrt(r1.x);
	o.texcoord4 = r0.yzw * r1.xxx;
	o.texcoord5 = i.tangent.w;
	r0.yzw = i.position.yyy * gWorld[1].xyz;
	r0.yzw = i.position.xxx * gWorld[0].xyz + r0.yzw;
	r0.xyz = r0.xxx * gWorld[2].xyz + r0.yzw;
	o.texcoord6.xyz = r0.xyz + gWorld[3].xyz;
	o.texcoord6.w = 1;
	o.texcoord9 = i.normal.xyz;

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	float4 r0;
	float3 r1;
	r0.xy = i.position.xy;
	r0.w = dot(i.position.xy, i.position.xy);
	r1.x = r0.w * Temporal_b4_o0_droopParams.x;
	r0.w = r0.w * Temporal_b4_o16_gravityDroop.x;
	r1.x = r1.x * Temporal_b4_o16_gravityDroop.x;
	r0.z = -(r1.x) * 0.00999999978 + i.position.z;
	r1 = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = dot(r1.xyz, r1.xyz);
	r0.x = rsqrt(r0.x);
	r1 = r0.xxx * r1.xyz;
	r0.x = dot(r1.xzy, float3(0.707106769, 0.707106769, 0.00000707099707));
	r0.x = r0.x + Temporal_b4_o16_gravityDroop.y;
	r0.x = r0.x * Temporal_b4_o0_droopParams.z;
	r0.x = sin(r0.x);
	r0.y = Temporal_b4_o0_droopParams.y * 0.00999999978;
	r0.y = r0.y * r0.w;
	r0.x = -(r0.y) * r0.x + r0.z;
	o.texcoord8.z = r0.x;
	o.texcoord8.xy = i.position.xy;
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord.xy;
	r0.y = i.position.y * Temporal_b0_o128_gWorldViewProj[1].w;
	r0.y = i.position.x * Temporal_b0_o128_gWorldViewProj[0].w + r0.y;
	r0.y = r0.x * Temporal_b0_o128_gWorldViewProj[2].w + r0.y;
	o.texcoord1.w = r0.y + Temporal_b0_o128_gWorldViewProj[3].w;
	r0.yzw = i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.yzw = i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.yzw;
	r0.yzw = i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.yzw;
	r0.yzw = r0.yzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = dot(r0.yzw, r0.yzw);
	r1.x = rsqrt(r1.x);
	o.texcoord1.xyz = r0.yzw * r1.xxx;
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r0.yzw = i.tangent.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.yzw = i.tangent.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.yzw;
	r0.yzw = i.tangent.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.yzw;
	r0.yzw = r0.yzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = dot(r0.yzw, r0.yzw);
	r1.x = rsqrt(r1.x);
	o.texcoord4 = r0.yzw * r1.xxx;
	o.texcoord5 = i.tangent.w;
	r0.yzw = i.position.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.yzw = i.position.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.yzw;
	r0.xyz = r0.xxx * Temporal_b0_o0_gWorld[2].xyz + r0.yzw;
	o.texcoord6.xyz = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;
	o.texcoord6.w = 1;
	o.texcoord9 = i.normal.xyz;

	return o;
}

VS_OUT main(VS_IN i)
{
    TemporalVertexResult c = TemporalCurrent(i);
    VS_OUT o;
    o.texcoord8 = c.texcoord8;
    o.texcoord = c.texcoord;
    o.texcoord1 = c.texcoord1;
    o.texcoord2 = c.texcoord2;
    o.texcoord4 = c.texcoord4;
    o.texcoord5 = c.texcoord5;
    o.texcoord6 = c.texcoord6;
    o.texcoord9 = c.texcoord9;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord1 = o.texcoord1;
    o.temporalInput_texcoord2 = o.texcoord2;
    o.temporalInput_texcoord4 = o.texcoord4;
    o.temporalInput_texcoord5 = o.texcoord5;
    o.temporalInput_texcoord6 = o.texcoord6;
    o.temporalInput_texcoord9 = o.texcoord9;
    [branch] if (TemporalState.x > 0)
    {
        TemporalVertexResult p = TemporalVertexPrevious(i);
        o.temporalInput_texcoord8 = p.texcoord8;
        o.temporalInput_texcoord = p.texcoord;
        o.temporalInput_texcoord1 = p.texcoord1;
        o.temporalInput_texcoord2 = p.texcoord2;
        o.temporalInput_texcoord4 = p.texcoord4;
        o.temporalInput_texcoord5 = p.texcoord5;
        o.temporalInput_texcoord6 = p.texcoord6;
        o.temporalInput_texcoord9 = p.texcoord9;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
