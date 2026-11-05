cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
};

cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
	float4 globalScalars2 : packoffset(c1);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 normal : NORMAL;
	float4 tangent : TANGENT;
	float3 position1 : POSITION1;
	float3 normal1 : NORMAL1;
	float4 tangent1 : TANGENT1;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord7 : TEXCOORD7;
	float3 temporalPrevious : TEXCOORD15;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	float4 Temporal_b5_o0_globalScalars : packoffset(c13);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c14);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	r0.xyz = i.position.xyz + i.position1.xyz;
	r1 = r0.y * gWorldViewProj[1];
	r1 = r0.x * gWorldViewProj[0] + r1;
	r1 = r0.z * gWorldViewProj[2] + r1;
	r1 = r1 + gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord = i.texcoord.xy;
	r1.xyz = i.normal.xyz + i.normal1.xyz;
	r2.xyz = r1.yyy * gWorld[1].xyz;
	r1.xyw = r1.xxx * gWorld[0].xyz + r2.xyz;
	r1.xyz = r1.zzz * gWorld[2].xyz + r1.xyw;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	r2 = i.tangent + i.tangent1;
	r3 = r2.yyy * gWorld[1].xyz;
	r3 = r2.xxx * gWorld[0].xyz + r3.xyz;
	r2.xyz = r2.zzz * gWorld[2].xyz + r3.xyz;
	r2.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r2.xyz, r2.xyz);
	r0.w = rsqrt(r0.w);
	r2.xyz = r0.www * r2.xyz;
	o.texcoord4 = r2.xyz;
	r3 = r1.yzx * r2.zxy;
	r1.xyz = r2.yzx * r1.zxy + -(r3.xyz);
	o.texcoord5.xyz = r2.www * r1.xyz;
	o.texcoord5.w = r2.w;
	r1.xyz = r0.yyy * gWorld[1].xyz;
	r0.xyw = r0.xxx * gWorld[0].xyz + r1.xyz;
	r0.xyz = r0.zzz * gWorld[2].xyz + r0.xyw;
	o.texcoord7 = r0.xyz + gWorld[3].xyz;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	r0.xyz = i.position.xyz + i.position1.xyz;
	r1 = r0.y * Temporal_b0_o128_gWorldViewProj[1];
	r1 = r0.x * Temporal_b0_o128_gWorldViewProj[0] + r1;
	r1 = r0.z * Temporal_b0_o128_gWorldViewProj[2] + r1;
	r1 = r1 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord = i.texcoord.xy;
	r1.xyz = i.normal.xyz + i.normal1.xyz;
	r2.xyz = r1.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r1.xyw = r1.xxx * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r1.xyz = r1.zzz * Temporal_b0_o0_gWorld[2].xyz + r1.xyw;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	r2 = i.tangent + i.tangent1;
	r3 = r2.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r3 = r2.xxx * Temporal_b0_o0_gWorld[0].xyz + r3.xyz;
	r2.xyz = r2.zzz * Temporal_b0_o0_gWorld[2].xyz + r3.xyz;
	r2.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r2.xyz, r2.xyz);
	r0.w = rsqrt(r0.w);
	r2.xyz = r0.www * r2.xyz;
	o.texcoord4 = r2.xyz;
	r3 = r1.yzx * r2.zxy;
	r1.xyz = r2.yzx * r1.zxy + -(r3.xyz);
	o.texcoord5.xyz = r2.www * r1.xyz;
	o.texcoord5.w = r2.w;
	r1.xyz = r0.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyw = r0.xxx * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	r0.xyz = r0.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyw;
	o.texcoord7 = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;

	return o;
}

VS_OUT main(VS_IN i)
{
    VS_OUT o = TemporalCurrent(i);
    o.temporalPrevious = float3(0, 0, -1);

    [branch] if (TemporalState.x > 0)
    {
        o.temporalPrevious = TemporalVertexPrevious(i).sv_position.xyw;
    }
    return o;
}
