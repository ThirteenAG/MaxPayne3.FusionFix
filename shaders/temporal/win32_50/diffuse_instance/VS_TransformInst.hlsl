cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
};

cbuffer InstanceWorld : register(b1)
{
	row_major float4x4 gWorldInstanceMatrix : packoffset(c0);
	row_major float4x4 gWorldInstanceInverseTranspose : packoffset(c4);
};

struct VS_IN
{
	float3 position : POSITION;
	float3 normal : NORMAL;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 temporalPrevious : TEXCOORD15;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	row_major float4x4 Temporal_b1_o0_gWorldInstanceMatrix : packoffset(c13);
	row_major float4x4 Temporal_b1_o64_gWorldInstanceInverseTranspose : packoffset(c17);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	r0.xyz = i.position.yyy * gWorldInstanceMatrix[1].xyz;
	r0.xyz = i.position.xxx * gWorldInstanceMatrix[0].xyz + r0.xyz;
	r0.xyz = i.position.zzz * gWorldInstanceMatrix[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + gWorldInstanceMatrix[3].xyz;
	r1 = r0.y * gWorldViewProj[1];
	r1 = r0.x * gWorldViewProj[0] + r1;
	r1 = r0.z * gWorldViewProj[2] + r1;
	o.texcoord1 = r0.xyz;
	r0 = r1 + gWorldViewProj[3];
	o.sv_position = r0;
	o.texcoord2.w = r0.w;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * gWorldInstanceInverseTranspose[1].xyz;
	r0.xyz = i.normal.xxx * gWorldInstanceInverseTranspose[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * gWorldInstanceInverseTranspose[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	o.texcoord2.xyz = r0.www * r0.xyz;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	r0.xyz = i.position.yyy * Temporal_b1_o0_gWorldInstanceMatrix[1].xyz;
	r0.xyz = i.position.xxx * Temporal_b1_o0_gWorldInstanceMatrix[0].xyz + r0.xyz;
	r0.xyz = i.position.zzz * Temporal_b1_o0_gWorldInstanceMatrix[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + Temporal_b1_o0_gWorldInstanceMatrix[3].xyz;
	r1 = r0.y * Temporal_b0_o128_gWorldViewProj[1];
	r1 = r0.x * Temporal_b0_o128_gWorldViewProj[0] + r1;
	r1 = r0.z * Temporal_b0_o128_gWorldViewProj[2] + r1;
	o.texcoord1 = r0.xyz;
	r0 = r1 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r0;
	o.texcoord2.w = r0.w;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * Temporal_b1_o64_gWorldInstanceInverseTranspose[1].xyz;
	r0.xyz = i.normal.xxx * Temporal_b1_o64_gWorldInstanceInverseTranspose[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * Temporal_b1_o64_gWorldInstanceInverseTranspose[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	o.texcoord2.xyz = r0.www * r0.xyz;

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
