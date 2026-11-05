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
	float4 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 color : COLOR;
};

struct TemporalVertexResult
{
	float4 texcoord8 : TEXCOORD8;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
};
struct VS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_texcoord : TEMPORAL1;
	float4 temporalInput_texcoord1 : TEMPORAL2;
	float4 temporalInput_texcoord2 : TEMPORAL3;
	float3 temporalInput_texcoord3 : TEMPORAL4;
	float3 temporalInput_texcoord4 : TEMPORAL5;
	float4 temporalInput_texcoord5 : TEMPORAL6;
	float3 temporalInput_texcoord6 : TEMPORAL7;
	float3 temporalInput_texcoord7 : TEMPORAL8;
	float3 temporalInput_texcoord9 : TEMPORAL9;
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


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	float4 r4;
	float4 r5;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * gBoneMtx[r0.y / 3][0];
	r1 = gBoneMtx[r0.x / 3][0] * i.blendweight.x + r1;
	r1 = gBoneMtx[r0.z / 3][0] * i.blendweight.z + r1;
	r1 = gBoneMtx[r0.w / 3][0] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz;
	r2.w = 1;
	r3.x = dot(r1, r2);
	r4 = i.blendweight.y * gBoneMtx[r0.y / 3][1];
	r4 = gBoneMtx[r0.x / 3][1] * i.blendweight.x + r4;
	r4 = gBoneMtx[r0.z / 3][1] * i.blendweight.z + r4;
	r4 = gBoneMtx[r0.w / 3][1] * i.blendweight.w + r4;
	r3.y = dot(r4, r2);
	r5 = i.blendweight.y * gBoneMtx[r0.y / 3][2];
	r5 = gBoneMtx[r0.x / 3][2] * i.blendweight.x + r5;
	r5 = gBoneMtx[r0.z / 3][2] * i.blendweight.z + r5;
	r0 = asint(gBoneMtx[r0.w / 3][2] * i.blendweight.w + r5);
	r3.z = dot(asfloat(r0), r2);
	o.texcoord8.xyz = r3.xyz;
	r2.xyz = r3.yyy * gWorld[1].xyz;
	r2.xyz = r3.xxx * gWorld[0].xyz + r2.xyz;
	r2.xyz = r3.zzz * gWorld[2].xyz + r2.xyz;
	r2.xyz = r2.xyz + gWorld[3].xyz;
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord;
	r3.y = dot(r4.xyz, i.normal.xyz);
	r0.w = asint(dot(r4.xyz, i.tangent.xyz));
	r4.xyz = asfloat(r0.www) * gWorld[1].xyz;
	r5.xyz = r3.yyy * gWorld[1].xyz;
	r3.x = dot(r1.xyz, i.normal.xyz);
	r0.w = asint(dot(r1.xyz, i.tangent.xyz));
	r1.xyz = asfloat(r0.www) * gWorld[0].xyz + r4.xyz;
	r4.xyz = r3.xxx * gWorld[0].xyz + r5.xyz;
	r3.z = dot(asfloat(r0.xyz), i.normal.xyz);
	r0.x = asint(dot(asfloat(r0.xyz), i.tangent.xyz));
	r0.xyz = asint(asfloat(r0.xxx) * gWorld[2].xyz + r1.xyz);
	r1.xyz = r3.zzz * gWorld[2].xyz + r4.xyz;
	o.texcoord9 = r3.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord1.w = 1;
	o.texcoord2 = i.color;
	r3 = -(r2.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r2.xyz;
	o.texcoord3 = r3.xyz;
	o.texcoord4 = asfloat(r0.xyz);
	r2.xyz = asfloat(r0.zxy) * r1.yzx;
	r2.xyz = asfloat(r0.yzx) * r1.zxy + -(r2.xyz);
	o.texcoord6.z = dot(r1.xyz, r3.xyz);
	o.texcoord6.x = dot(asfloat(r0.xyz), r3.xyz);
	r0.xyz = asint(r2.xyz * i.tangent.www);
	o.texcoord5.xyz = asfloat(r0.xyz);
	o.texcoord6.y = dot(asfloat(r0.xyz), r3.xyz);
	o.texcoord5.w = i.tangent.w;

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	float4 r4;
	float4 r5;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][0];
	r1 = Temporal_b1_o0_gBoneMtx[r0.x / 3][0] * i.blendweight.x + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.z / 3][0] * i.blendweight.z + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.w / 3][0] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz;
	r2.w = 1;
	r3.x = dot(r1, r2);
	r4 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][1];
	r4 = Temporal_b1_o0_gBoneMtx[r0.x / 3][1] * i.blendweight.x + r4;
	r4 = Temporal_b1_o0_gBoneMtx[r0.z / 3][1] * i.blendweight.z + r4;
	r4 = Temporal_b1_o0_gBoneMtx[r0.w / 3][1] * i.blendweight.w + r4;
	r3.y = dot(r4, r2);
	r5 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][2];
	r5 = Temporal_b1_o0_gBoneMtx[r0.x / 3][2] * i.blendweight.x + r5;
	r5 = Temporal_b1_o0_gBoneMtx[r0.z / 3][2] * i.blendweight.z + r5;
	r0 = asint(Temporal_b1_o0_gBoneMtx[r0.w / 3][2] * i.blendweight.w + r5);
	r3.z = dot(asfloat(r0), r2);
	o.texcoord8.xyz = r3.xyz;
	r2.xyz = r3.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r2.xyz = r3.xxx * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r2.xyz = r3.zzz * Temporal_b0_o0_gWorld[2].xyz + r2.xyz;
	r2.xyz = r2.xyz + Temporal_b0_o0_gWorld[3].xyz;
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord;
	r3.y = dot(r4.xyz, i.normal.xyz);
	r0.w = asint(dot(r4.xyz, i.tangent.xyz));
	r4.xyz = asfloat(r0.www) * Temporal_b0_o0_gWorld[1].xyz;
	r5.xyz = r3.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r3.x = dot(r1.xyz, i.normal.xyz);
	r0.w = asint(dot(r1.xyz, i.tangent.xyz));
	r1.xyz = asfloat(r0.www) * Temporal_b0_o0_gWorld[0].xyz + r4.xyz;
	r4.xyz = r3.xxx * Temporal_b0_o0_gWorld[0].xyz + r5.xyz;
	r3.z = dot(asfloat(r0.xyz), i.normal.xyz);
	r0.x = asint(dot(asfloat(r0.xyz), i.tangent.xyz));
	r0.xyz = asint(asfloat(r0.xxx) * Temporal_b0_o0_gWorld[2].xyz + r1.xyz);
	r1.xyz = r3.zzz * Temporal_b0_o0_gWorld[2].xyz + r4.xyz;
	o.texcoord9 = r3.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord1.w = 1;
	o.texcoord2 = i.color;
	r3 = -(r2.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = r2.xyz;
	o.texcoord3 = r3.xyz;
	o.texcoord4 = asfloat(r0.xyz);
	r2.xyz = asfloat(r0.zxy) * r1.yzx;
	r2.xyz = asfloat(r0.yzx) * r1.zxy + -(r2.xyz);
	o.texcoord6.z = dot(r1.xyz, r3.xyz);
	o.texcoord6.x = dot(asfloat(r0.xyz), r3.xyz);
	r0.xyz = asint(r2.xyz * i.tangent.www);
	o.texcoord5.xyz = asfloat(r0.xyz);
	o.texcoord6.y = dot(asfloat(r0.xyz), r3.xyz);
	o.texcoord5.w = i.tangent.w;

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
    o.texcoord3 = c.texcoord3;
    o.texcoord4 = c.texcoord4;
    o.texcoord5 = c.texcoord5;
    o.texcoord6 = c.texcoord6;
    o.texcoord7 = c.texcoord7;
    o.texcoord9 = c.texcoord9;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord1 = o.texcoord1;
    o.temporalInput_texcoord2 = o.texcoord2;
    o.temporalInput_texcoord3 = o.texcoord3;
    o.temporalInput_texcoord4 = o.texcoord4;
    o.temporalInput_texcoord5 = o.texcoord5;
    o.temporalInput_texcoord6 = o.texcoord6;
    o.temporalInput_texcoord7 = o.texcoord7;
    o.temporalInput_texcoord9 = o.texcoord9;
    [branch] if (TemporalState.x > 0)
    {
        TemporalVertexResult p = TemporalVertexPrevious(i);
        o.temporalInput_texcoord8 = p.texcoord8;
        o.temporalInput_texcoord = p.texcoord;
        o.temporalInput_texcoord1 = p.texcoord1;
        o.temporalInput_texcoord2 = p.texcoord2;
        o.temporalInput_texcoord3 = p.texcoord3;
        o.temporalInput_texcoord4 = p.texcoord4;
        o.temporalInput_texcoord5 = p.texcoord5;
        o.temporalInput_texcoord6 = p.texcoord6;
        o.temporalInput_texcoord7 = p.texcoord7;
        o.temporalInput_texcoord9 = p.texcoord9;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
