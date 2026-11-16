cbuffer rage_bonemtx : register(b1)
{
	row_major float3x4 gBoneMtx[40] : packoffset(c0);
};

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
	float4 blendindices : BLENDINDICES;
	float4 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 color : COLOR;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord7 : TEXCOORD7;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
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
	row_major float4x4 Temporal_b0_o192_gViewInverse : packoffset(c133);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	r0.x = asint(i.blendindices.x * 255.001953);
	r0.x = (int)asfloat(r0.x);
	r0.x = r0.x * 3;
	r1.xyz = i.position.xyz;
	r1.w = 1;
	r0.y = asint(dot(gBoneMtx[r0.x / 3][1], r1));
	r2 = asfloat(r0.y) * gWorldViewProj[1];
	r0.z = asint(dot(gBoneMtx[r0.x / 3][0], r1));
	r0.w = asint(dot(gBoneMtx[r0.x / 3][2], r1));
	r1 = asfloat(r0.z) * gWorldViewProj[0] + r2;
	r1 = asfloat(r0.w) * gWorldViewProj[2] + r1;
	r1 = r1 + gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord = i.texcoord.xy;
	o.texcoord7 = i.texcoord.zw;
	r1.x = dot(gBoneMtx[r0.x / 3][1].xyz, i.normal.xyz);
	r1.xyz = r1.xxx * gWorld[1].xyz;
	r1.w = dot(gBoneMtx[r0.x / 3][0].xyz, i.normal.xyz);
	r0.x = asint(dot(gBoneMtx[r0.x / 3][2].xyz, i.normal.xyz));
	r1.xyz = r1.www * gWorld[0].xyz + r1.xyz;
	o.texcoord1.xyz = asfloat(r0.xxx) * gWorld[2].xyz + r1.xyz;
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r1.xyz = asfloat(r0.yyy) * gWorld[1].xyz;
	r2 = asfloat(r0.y) * gWorld[1];
	r2 = asfloat(r0.z) * gWorld[0] + r2;
	r0.xyz = asint(asfloat(r0.zzz) * gWorld[0].xyz + r1.xyz);
	r0.xyz = asint(asfloat(r0.www) * gWorld[2].xyz + asfloat(r0.xyz));
	r1 = asfloat(r0.w) * gWorld[2] + r2;
	o.texcoord6 = r1 + gWorld[3];
	r0.xyz = asint(asfloat(r0.xyz) + gWorld[3].xyz);
	o.texcoord3 = -(asfloat(r0.xyz)) + gViewInverse[3].xyz;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	r0.x = asint(i.blendindices.x * 255.001953);
	r0.x = (int)asfloat(r0.x);
	r0.x = r0.x * 3;
	r1.xyz = i.position.xyz;
	r1.w = 1;
	r0.y = asint(dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][1], r1));
	r2 = asfloat(r0.y) * Temporal_b0_o128_gWorldViewProj[1];
	r0.z = asint(dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][0], r1));
	r0.w = asint(dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][2], r1));
	r1 = asfloat(r0.z) * Temporal_b0_o128_gWorldViewProj[0] + r2;
	r1 = asfloat(r0.w) * Temporal_b0_o128_gWorldViewProj[2] + r1;
	r1 = r1 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord = i.texcoord.xy;
	o.texcoord7 = i.texcoord.zw;
	r1.x = dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][1].xyz, i.normal.xyz);
	r1.xyz = r1.xxx * Temporal_b0_o0_gWorld[1].xyz;
	r1.w = dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][0].xyz, i.normal.xyz);
	r0.x = asint(dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][2].xyz, i.normal.xyz));
	r1.xyz = r1.www * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	o.texcoord1.xyz = asfloat(r0.xxx) * Temporal_b0_o0_gWorld[2].xyz + r1.xyz;
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r1.xyz = asfloat(r0.yyy) * Temporal_b0_o0_gWorld[1].xyz;
	r2 = asfloat(r0.y) * Temporal_b0_o0_gWorld[1];
	r2 = asfloat(r0.z) * Temporal_b0_o0_gWorld[0] + r2;
	r0.xyz = asint(asfloat(r0.zzz) * Temporal_b0_o0_gWorld[0].xyz + r1.xyz);
	r0.xyz = asint(asfloat(r0.www) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	r1 = asfloat(r0.w) * Temporal_b0_o0_gWorld[2] + r2;
	o.texcoord6 = r1 + Temporal_b0_o0_gWorld[3];
	r0.xyz = asint(asfloat(r0.xyz) + Temporal_b0_o0_gWorld[3].xyz);
	o.texcoord3 = -(asfloat(r0.xyz)) + Temporal_b0_o192_gViewInverse[3].xyz;

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
