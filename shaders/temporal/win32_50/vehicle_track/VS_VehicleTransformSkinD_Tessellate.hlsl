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
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 color : COLOR;
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
	row_major float3x4 Temporal_b1_o0_gBoneMtx[40] : packoffset(c1);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c121);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c125);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c129);
	float4 Temporal_b4_o0_TrackAnimUV : packoffset(c133);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	float4 r2;
	o.texcoord8.w = 1;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * gBoneMtx[r0.y / 3][0];
	r1 = gBoneMtx[r0.x / 3][0] * i.blendweight.x + r1;
	r1 = gBoneMtx[r0.z / 3][0] * i.blendweight.z + r1;
	r1 = gBoneMtx[r0.w / 3][0] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz;
	r2.w = 1;
	o.texcoord8.x = dot(r1, r2);
	r1 = i.blendweight.y * gBoneMtx[r0.y / 3][1];
	r1 = gBoneMtx[r0.x / 3][1] * i.blendweight.x + r1;
	r1 = gBoneMtx[r0.z / 3][1] * i.blendweight.z + r1;
	r1 = gBoneMtx[r0.w / 3][1] * i.blendweight.w + r1;
	o.texcoord8.y = dot(r1, r2);
	r1 = i.blendweight.y * gBoneMtx[r0.y / 3][2];
	r1 = gBoneMtx[r0.x / 3][2] * i.blendweight.x + r1;
	r1 = gBoneMtx[r0.z / 3][2] * i.blendweight.z + r1;
	r0 = asint(gBoneMtx[r0.w / 3][2] * i.blendweight.w + r1);
	o.texcoord8.z = dot(asfloat(r0), r2);
	r0.x = (0 < i.position.x) ? -1 : 0;
	r0.x = r0.x & 1065353216;
	r0.yz = asint(i.texcoord.xx + TrackAnimUV.xy);
	r0.y = asint(-(asfloat(r0.z)) + asfloat(r0.y));
	o.texcoord.x = asfloat(r0.x) * asfloat(r0.y) + asfloat(r0.z);
	o.texcoord.y = i.texcoord.y;
	r0.x = asint(i.blendindices.x * 255.001953);
	r0.x = (int)asfloat(r0.x);
	r0.x = r0.x * 3;
	r0.y = asint(dot(gBoneMtx[r0.x / 3][1], r2));
	r0.z = asint(asfloat(r0.y) * gWorldViewProj[1].w);
	r1 = asfloat(r0.y) * gWorld[1];
	r0.y = asint(dot(gBoneMtx[r0.x / 3][0], r2));
	r0.w = asint(dot(gBoneMtx[r0.x / 3][2], r2));
	r0.z = asint(asfloat(r0.y) * gWorldViewProj[0].w + asfloat(r0.z));
	r1 = asfloat(r0.y) * gWorld[0] + r1;
	r1 = asfloat(r0.w) * gWorld[2] + r1;
	r0.y = asint(asfloat(r0.w) * gWorldViewProj[2].w + asfloat(r0.z));
	o.texcoord1.w = asfloat(r0.y) + gWorldViewProj[3].w;
	o.texcoord6 = r1 + gWorld[3];
	r1.x = dot(gBoneMtx[r0.x / 3][1].xyz, i.normal.xyz);
	r0.yzw = asint(r1.xxx * gWorld[1].xyz);
	r1.z = dot(gBoneMtx[r0.x / 3][0].xyz, i.normal.xyz);
	r0.yzw = asint(r1.zzz * gWorld[0].xyz + asfloat(r0.yzw));
	r1.y = dot(gBoneMtx[r0.x / 3][2].xyz, i.normal.xyz);
	o.texcoord1.xyz = r1.yyy * gWorld[2].xyz + asfloat(r0.yzw);
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r2.x = dot(gBoneMtx[r0.x / 3][0].xyz, i.tangent.xyz);
	r2.y = dot(gBoneMtx[r0.x / 3][1].xyz, i.tangent.xyz);
	r2.z = dot(gBoneMtx[r0.x / 3][2].xyz, i.tangent.xyz);
	o.texcoord4 = r2.xyz;
	r0.xyz = asint(r1.xyz * r2.zxy);
	r0.xyz = asint(r2.yzx * r1.yzx + -(asfloat(r0.xyz)));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
	o.texcoord5.w = i.tangent.w;
	o.texcoord9 = i.normal.xyz;

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	float4 r2;
	o.texcoord8.w = 1;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][0];
	r1 = Temporal_b1_o0_gBoneMtx[r0.x / 3][0] * i.blendweight.x + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.z / 3][0] * i.blendweight.z + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.w / 3][0] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz;
	r2.w = 1;
	o.texcoord8.x = dot(r1, r2);
	r1 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][1];
	r1 = Temporal_b1_o0_gBoneMtx[r0.x / 3][1] * i.blendweight.x + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.z / 3][1] * i.blendweight.z + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.w / 3][1] * i.blendweight.w + r1;
	o.texcoord8.y = dot(r1, r2);
	r1 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][2];
	r1 = Temporal_b1_o0_gBoneMtx[r0.x / 3][2] * i.blendweight.x + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.z / 3][2] * i.blendweight.z + r1;
	r0 = asint(Temporal_b1_o0_gBoneMtx[r0.w / 3][2] * i.blendweight.w + r1);
	o.texcoord8.z = dot(asfloat(r0), r2);
	r0.x = (0 < i.position.x) ? -1 : 0;
	r0.x = r0.x & 1065353216;
	r0.yz = asint(i.texcoord.xx + Temporal_b4_o0_TrackAnimUV.xy);
	r0.y = asint(-(asfloat(r0.z)) + asfloat(r0.y));
	o.texcoord.x = asfloat(r0.x) * asfloat(r0.y) + asfloat(r0.z);
	o.texcoord.y = i.texcoord.y;
	r0.x = asint(i.blendindices.x * 255.001953);
	r0.x = (int)asfloat(r0.x);
	r0.x = r0.x * 3;
	r0.y = asint(dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][1], r2));
	r0.z = asint(asfloat(r0.y) * Temporal_b0_o128_gWorldViewProj[1].w);
	r1 = asfloat(r0.y) * Temporal_b0_o0_gWorld[1];
	r0.y = asint(dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][0], r2));
	r0.w = asint(dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][2], r2));
	r0.z = asint(asfloat(r0.y) * Temporal_b0_o128_gWorldViewProj[0].w + asfloat(r0.z));
	r1 = asfloat(r0.y) * Temporal_b0_o0_gWorld[0] + r1;
	r1 = asfloat(r0.w) * Temporal_b0_o0_gWorld[2] + r1;
	r0.y = asint(asfloat(r0.w) * Temporal_b0_o128_gWorldViewProj[2].w + asfloat(r0.z));
	o.texcoord1.w = asfloat(r0.y) + Temporal_b0_o128_gWorldViewProj[3].w;
	o.texcoord6 = r1 + Temporal_b0_o0_gWorld[3];
	r1.x = dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][1].xyz, i.normal.xyz);
	r0.yzw = asint(r1.xxx * Temporal_b0_o0_gWorld[1].xyz);
	r1.z = dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][0].xyz, i.normal.xyz);
	r0.yzw = asint(r1.zzz * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.yzw));
	r1.y = dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][2].xyz, i.normal.xyz);
	o.texcoord1.xyz = r1.yyy * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.yzw);
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r2.x = dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][0].xyz, i.tangent.xyz);
	r2.y = dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][1].xyz, i.tangent.xyz);
	r2.z = dot(Temporal_b1_o0_gBoneMtx[r0.x / 3][2].xyz, i.tangent.xyz);
	o.texcoord4 = r2.xyz;
	r0.xyz = asint(r1.xyz * r2.zxy);
	r0.xyz = asint(r2.yzx * r1.yzx + -(asfloat(r0.xyz)));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
	o.texcoord5.w = i.tangent.w;
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
