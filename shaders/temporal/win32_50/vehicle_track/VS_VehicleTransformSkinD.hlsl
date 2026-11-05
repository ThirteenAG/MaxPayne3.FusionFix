cbuffer rage_bonemtx : register(b1)
{
	row_major float3x4 gBoneMtx[40] : packoffset(c0);
};

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
	float4 blendindices : BLENDINDICES;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 color : COLOR;
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
	row_major float3x4 Temporal_b1_o0_gBoneMtx[40] : packoffset(c1);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c121);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c125);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c129);
	float4 Temporal_b4_o0_TrackAnimUV : packoffset(c133);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	r0.xyz = asint(i.position.xyz);
	r0.w = 1065353216;
	r1.x = asint(i.blendindices.x * 255.001953);
	r1.x = (int)asfloat(r1.x);
	r1.x = r1.x * 3;
	r1.y = asint(dot(gBoneMtx[r1.x / 3][1], asfloat(r0)));
	r2 = asfloat(r1.y) * gWorldViewProj[1];
	r3 = asfloat(r1.y) * gWorld[1];
	r1.y = asint(dot(gBoneMtx[r1.x / 3][0], asfloat(r0)));
	r0.x = asint(dot(gBoneMtx[r1.x / 3][2], asfloat(r0)));
	r2 = asfloat(r1.y) * gWorldViewProj[0] + r2;
	r3 = asfloat(r1.y) * gWorld[0] + r3;
	r3 = asfloat(r0.x) * gWorld[2] + r3;
	r0 = asint(asfloat(r0.x) * gWorldViewProj[2] + r2);
	r0 = asint(asfloat(r0) + gWorldViewProj[3]);
	o.texcoord6 = r3 + gWorld[3];
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	r0.x = (0 < i.position.x) ? -1 : 0;
	r0.x = r0.x & 1065353216;
	r0.yz = asint(i.texcoord.xx + TrackAnimUV.xy);
	r0.y = asint(-(asfloat(r0.z)) + asfloat(r0.y));
	o.texcoord.x = asfloat(r0.x) * asfloat(r0.y) + asfloat(r0.z);
	o.texcoord.y = i.texcoord.y;
	r0.x = asint(dot(gBoneMtx[r1.x / 3][1].xyz, i.normal.xyz));
	r1.yzw = asint(asfloat(r0.xxx) * gWorld[1].xyz);
	r0.z = asint(dot(gBoneMtx[r1.x / 3][0].xyz, i.normal.xyz));
	r1.yzw = asint(asfloat(r0.zzz) * gWorld[0].xyz + asfloat(r1.yzw));
	r0.y = asint(dot(gBoneMtx[r1.x / 3][2].xyz, i.normal.xyz));
	o.texcoord1.xyz = asfloat(r0.yyy) * gWorld[2].xyz + asfloat(r1.yzw);
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r2.x = dot(gBoneMtx[r1.x / 3][0].xyz, i.tangent.xyz);
	r2.y = dot(gBoneMtx[r1.x / 3][1].xyz, i.tangent.xyz);
	r2.z = dot(gBoneMtx[r1.x / 3][2].xyz, i.tangent.xyz);
	o.texcoord4 = r2.xyz;
	r1.xyz = asint(asfloat(r0.xyz) * r2.zxy);
	r0.xyz = asint(r2.yzx * asfloat(r0.yzx) + -(asfloat(r1.xyz)));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
	o.texcoord5.w = i.tangent.w;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	r0.xyz = asint(i.position.xyz);
	r0.w = 1065353216;
	r1.x = asint(i.blendindices.x * 255.001953);
	r1.x = (int)asfloat(r1.x);
	r1.x = r1.x * 3;
	r1.y = asint(dot(Temporal_b1_o0_gBoneMtx[r1.x / 3][1], asfloat(r0)));
	r2 = asfloat(r1.y) * Temporal_b0_o128_gWorldViewProj[1];
	r3 = asfloat(r1.y) * Temporal_b0_o0_gWorld[1];
	r1.y = asint(dot(Temporal_b1_o0_gBoneMtx[r1.x / 3][0], asfloat(r0)));
	r0.x = asint(dot(Temporal_b1_o0_gBoneMtx[r1.x / 3][2], asfloat(r0)));
	r2 = asfloat(r1.y) * Temporal_b0_o128_gWorldViewProj[0] + r2;
	r3 = asfloat(r1.y) * Temporal_b0_o0_gWorld[0] + r3;
	r3 = asfloat(r0.x) * Temporal_b0_o0_gWorld[2] + r3;
	r0 = asint(asfloat(r0.x) * Temporal_b0_o128_gWorldViewProj[2] + r2);
	r0 = asint(asfloat(r0) + Temporal_b0_o128_gWorldViewProj[3]);
	o.texcoord6 = r3 + Temporal_b0_o0_gWorld[3];
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	r0.x = (0 < i.position.x) ? -1 : 0;
	r0.x = r0.x & 1065353216;
	r0.yz = asint(i.texcoord.xx + Temporal_b4_o0_TrackAnimUV.xy);
	r0.y = asint(-(asfloat(r0.z)) + asfloat(r0.y));
	o.texcoord.x = asfloat(r0.x) * asfloat(r0.y) + asfloat(r0.z);
	o.texcoord.y = i.texcoord.y;
	r0.x = asint(dot(Temporal_b1_o0_gBoneMtx[r1.x / 3][1].xyz, i.normal.xyz));
	r1.yzw = asint(asfloat(r0.xxx) * Temporal_b0_o0_gWorld[1].xyz);
	r0.z = asint(dot(Temporal_b1_o0_gBoneMtx[r1.x / 3][0].xyz, i.normal.xyz));
	r1.yzw = asint(asfloat(r0.zzz) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r1.yzw));
	r0.y = asint(dot(Temporal_b1_o0_gBoneMtx[r1.x / 3][2].xyz, i.normal.xyz));
	o.texcoord1.xyz = asfloat(r0.yyy) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r1.yzw);
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r2.x = dot(Temporal_b1_o0_gBoneMtx[r1.x / 3][0].xyz, i.tangent.xyz);
	r2.y = dot(Temporal_b1_o0_gBoneMtx[r1.x / 3][1].xyz, i.tangent.xyz);
	r2.z = dot(Temporal_b1_o0_gBoneMtx[r1.x / 3][2].xyz, i.tangent.xyz);
	o.texcoord4 = r2.xyz;
	r1.xyz = asint(asfloat(r0.xyz) * r2.zxy);
	r0.xyz = asint(r2.yzx * asfloat(r0.yzx) + -(asfloat(r1.xyz)));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
	o.texcoord5.w = i.tangent.w;

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
