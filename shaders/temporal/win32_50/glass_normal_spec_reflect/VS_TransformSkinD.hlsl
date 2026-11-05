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
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 color : COLOR;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
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
	float4 r3;
	float3 r4;
	float4 r5;
	float4 r6;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * gBoneMtx[r0.y / 3][1];
	r1 = gBoneMtx[r0.x / 3][1] * i.blendweight.x + r1;
	r1 = gBoneMtx[r0.z / 3][1] * i.blendweight.z + r1;
	r1 = gBoneMtx[r0.w / 3][1] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz;
	r2.w = 1;
	r1.w = dot(r1, r2);
	r3 = r1.w * gWorldViewProj[1];
	r4 = r1.www * gWorld[1].xyz;
	r5 = i.blendweight.y * gBoneMtx[r0.y / 3][0];
	r5 = gBoneMtx[r0.x / 3][0] * i.blendweight.x + r5;
	r5 = gBoneMtx[r0.z / 3][0] * i.blendweight.z + r5;
	r5 = gBoneMtx[r0.w / 3][0] * i.blendweight.w + r5;
	r1.w = dot(r5, r2);
	r3 = r1.w * gWorldViewProj[0] + r3;
	r4 = r1.www * gWorld[0].xyz + r4.xyz;
	r6 = i.blendweight.y * gBoneMtx[r0.y / 3][2];
	r6 = gBoneMtx[r0.x / 3][2] * i.blendweight.x + r6;
	r6 = gBoneMtx[r0.z / 3][2] * i.blendweight.z + r6;
	r0 = asint(gBoneMtx[r0.w / 3][2] * i.blendweight.w + r6);
	r0.w = asint(dot(asfloat(r0), r2));
	r2 = asfloat(r0.w) * gWorldViewProj[2] + r3;
	r3.xyz = asfloat(r0.www) * gWorld[2].xyz + r4.xyz;
	r3.xyz = r3.xyz + gWorld[3].xyz;
	r2 = r2 + gWorldViewProj[3];
	o.sv_position = r2;
	o.texcoord1.w = r2.w;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0.w = asint(dot(r1.xyz, i.normal.xyz));
	r1.x = dot(r1.xyz, i.tangent.xyz);
	r1.xyz = r1.xxx * gWorld[1].xyz;
	r2.xyz = asfloat(r0.www) * gWorld[1].xyz;
	r0.w = asint(dot(r5.xyz, i.normal.xyz));
	r1.w = dot(r5.xyz, i.tangent.xyz);
	r1.xyz = r1.www * gWorld[0].xyz + r1.xyz;
	r2.xyz = asfloat(r0.www) * gWorld[0].xyz + r2.xyz;
	r0.w = asint(dot(asfloat(r0.xyz), i.normal.xyz));
	r0.x = asint(dot(asfloat(r0.xyz), i.tangent.xyz));
	r0.xyz = asint(asfloat(r0.xxx) * gWorld[2].xyz + r1.xyz);
	r1.xyz = asfloat(r0.www) * gWorld[2].xyz + r2.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord3 = -(r3.xyz) + gViewInverse[3].xyz;
	o.texcoord6.xyz = r3.xyz;
	o.texcoord4 = asfloat(r0.xyz);
	r2.xyz = asfloat(r0.zxy) * r1.yzx;
	r0.xyz = asint(asfloat(r0.yzx) * r1.zxy + -(r2.xyz));
	o.texcoord5 = asfloat(r0.xyz) * i.tangent.www;
	o.texcoord6.w = 1;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	float4 r6;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][1];
	r1 = Temporal_b1_o0_gBoneMtx[r0.x / 3][1] * i.blendweight.x + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.z / 3][1] * i.blendweight.z + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.w / 3][1] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz;
	r2.w = 1;
	r1.w = dot(r1, r2);
	r3 = r1.w * Temporal_b0_o128_gWorldViewProj[1];
	r4 = r1.www * Temporal_b0_o0_gWorld[1].xyz;
	r5 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][0];
	r5 = Temporal_b1_o0_gBoneMtx[r0.x / 3][0] * i.blendweight.x + r5;
	r5 = Temporal_b1_o0_gBoneMtx[r0.z / 3][0] * i.blendweight.z + r5;
	r5 = Temporal_b1_o0_gBoneMtx[r0.w / 3][0] * i.blendweight.w + r5;
	r1.w = dot(r5, r2);
	r3 = r1.w * Temporal_b0_o128_gWorldViewProj[0] + r3;
	r4 = r1.www * Temporal_b0_o0_gWorld[0].xyz + r4.xyz;
	r6 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][2];
	r6 = Temporal_b1_o0_gBoneMtx[r0.x / 3][2] * i.blendweight.x + r6;
	r6 = Temporal_b1_o0_gBoneMtx[r0.z / 3][2] * i.blendweight.z + r6;
	r0 = asint(Temporal_b1_o0_gBoneMtx[r0.w / 3][2] * i.blendweight.w + r6);
	r0.w = asint(dot(asfloat(r0), r2));
	r2 = asfloat(r0.w) * Temporal_b0_o128_gWorldViewProj[2] + r3;
	r3.xyz = asfloat(r0.www) * Temporal_b0_o0_gWorld[2].xyz + r4.xyz;
	r3.xyz = r3.xyz + Temporal_b0_o0_gWorld[3].xyz;
	r2 = r2 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r2;
	o.texcoord1.w = r2.w;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0.w = asint(dot(r1.xyz, i.normal.xyz));
	r1.x = dot(r1.xyz, i.tangent.xyz);
	r1.xyz = r1.xxx * Temporal_b0_o0_gWorld[1].xyz;
	r2.xyz = asfloat(r0.www) * Temporal_b0_o0_gWorld[1].xyz;
	r0.w = asint(dot(r5.xyz, i.normal.xyz));
	r1.w = dot(r5.xyz, i.tangent.xyz);
	r1.xyz = r1.www * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	r2.xyz = asfloat(r0.www) * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r0.w = asint(dot(asfloat(r0.xyz), i.normal.xyz));
	r0.x = asint(dot(asfloat(r0.xyz), i.tangent.xyz));
	r0.xyz = asint(asfloat(r0.xxx) * Temporal_b0_o0_gWorld[2].xyz + r1.xyz);
	r1.xyz = asfloat(r0.www) * Temporal_b0_o0_gWorld[2].xyz + r2.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord3 = -(r3.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord6.xyz = r3.xyz;
	o.texcoord4 = asfloat(r0.xyz);
	r2.xyz = asfloat(r0.zxy) * r1.yzx;
	r0.xyz = asint(asfloat(r0.yzx) * r1.zxy + -(r2.xyz));
	o.texcoord5 = asfloat(r0.xyz) * i.tangent.www;
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
