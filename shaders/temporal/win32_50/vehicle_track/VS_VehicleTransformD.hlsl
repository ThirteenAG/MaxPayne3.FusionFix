cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
};

cbuffer VehicleUVAnim : register(b4)
{
	float4 TrackAnimUV : packoffset(c0);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float3 temporalPrevious : TEXCOORD15;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	float4 Temporal_b4_o0_TrackAnimUV : packoffset(c13);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	r0 = asint(i.position.y * gWorldViewProj[1]);
	r0 = asint(i.position.x * gWorldViewProj[0] + asfloat(r0));
	r0 = asint(i.position.z * gWorldViewProj[2] + asfloat(r0));
	r0 = asint(asfloat(r0) + gWorldViewProj[3]);
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	r0.x = (0 < i.position.x) ? -1 : 0;
	r0.x = r0.x & 1065353216;
	r0.yz = asint(i.texcoord.xx + TrackAnimUV.xy);
	r0.y = asint(-(asfloat(r0.z)) + asfloat(r0.y));
	o.texcoord.x = asfloat(r0.x) * asfloat(r0.y) + asfloat(r0.z);
	o.texcoord.y = i.texcoord.y;
	r0.xyz = asint(i.normal.yyy * gWorld[1].xyz);
	r0.xyz = asint(i.normal.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.normal.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord1.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r0.xyz = asint(i.tangent.yyy * gWorld[1].xyz);
	r0.xyz = asint(i.tangent.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.tangent.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord4 = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord5 = i.tangent.w;
	r0.xyz = asint(i.position.yyy * gWorld[1].xyz);
	r0.xyz = asint(i.position.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.position.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	o.texcoord6.xyz = asfloat(r0.xyz) + gWorld[3].xyz;
	o.texcoord6.w = 1;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	r0 = asint(i.position.y * Temporal_b0_o128_gWorldViewProj[1]);
	r0 = asint(i.position.x * Temporal_b0_o128_gWorldViewProj[0] + asfloat(r0));
	r0 = asint(i.position.z * Temporal_b0_o128_gWorldViewProj[2] + asfloat(r0));
	r0 = asint(asfloat(r0) + Temporal_b0_o128_gWorldViewProj[3]);
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	r0.x = (0 < i.position.x) ? -1 : 0;
	r0.x = r0.x & 1065353216;
	r0.yz = asint(i.texcoord.xx + Temporal_b4_o0_TrackAnimUV.xy);
	r0.y = asint(-(asfloat(r0.z)) + asfloat(r0.y));
	o.texcoord.x = asfloat(r0.x) * asfloat(r0.y) + asfloat(r0.z);
	o.texcoord.y = i.texcoord.y;
	r0.xyz = asint(i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord1.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r0.xyz = asint(i.tangent.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(i.tangent.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.tangent.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord4 = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord5 = i.tangent.w;
	r0.xyz = asint(i.position.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(i.position.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.position.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	o.texcoord6.xyz = asfloat(r0.xyz) + Temporal_b0_o0_gWorld[3].xyz;
	o.texcoord6.w = 1;

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
