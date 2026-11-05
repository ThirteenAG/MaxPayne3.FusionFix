cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gWorld : packoffset(c0);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
};

struct TemporalVertexResult
{
	float4 texcoord8 : TEXCOORD8;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord6 : TEXCOORD6;
};
struct VS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord6 : TEXCOORD6;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_color : TEMPORAL1;
	float2 temporalInput_texcoord : TEMPORAL2;
	float4 temporalInput_texcoord6 : TEMPORAL3;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c1);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c5);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	float3 r0;
	o.texcoord8.xyz = i.position.xyz;
	o.texcoord8.w = 1;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0 = i.position.yyy * gWorld[1].xyz;
	r0 = i.position.xxx * gWorld[0].xyz + r0.xyz;
	r0 = i.position.zzz * gWorld[2].xyz + r0.xyz;
	o.texcoord6.xyz = r0.xyz + gWorld[3].xyz;
	o.texcoord6.w = 1;

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	float3 r0;
	o.texcoord8.xyz = i.position.xyz;
	o.texcoord8.w = 1;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0 = i.position.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0 = i.position.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0 = i.position.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	o.texcoord6.xyz = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;
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
    o.texcoord6 = c.texcoord6;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_color = o.color;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord6 = o.texcoord6;
    [branch] if (TemporalState.x > 0)
    {
        TemporalVertexResult p = TemporalVertexPrevious(i);
        o.temporalInput_texcoord8 = p.texcoord8;
        o.temporalInput_color = p.color;
        o.temporalInput_texcoord = p.texcoord;
        o.temporalInput_texcoord6 = p.texcoord6;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
