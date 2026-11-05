cbuffer rage_bonemtx : register(b1)
{
	row_major float3x4 gBoneMtx[40] : packoffset(c0);
};

cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gWorld : packoffset(c0);
};

cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
	float4 globalScalars2 : packoffset(c1);
	float4 globalScalars3 : packoffset(c2);
	float4 globalScalars4 : packoffset(c3);
};

cbuffer PedWind : register(b4)
{
	float4 gWindParams : packoffset(c0);
	float4 AirResist : packoffset(c1);
	float WindStr : packoffset(c2);
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
	float4 color1 : COLOR1;
};

struct TemporalVertexResult
{
	float4 texcoord8 : TEXCOORD8;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord7 : TEXCOORD7;
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
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float2 temporalInput_texcoord : TEMPORAL1;
	float4 temporalInput_texcoord1 : TEMPORAL2;
	float4 temporalInput_texcoord2 : TEMPORAL3;
	float3 temporalInput_texcoord4 : TEMPORAL4;
	float4 temporalInput_texcoord5 : TEMPORAL5;
	float3 temporalInput_texcoord7 : TEMPORAL6;
	float3 temporalInput_texcoord9 : TEMPORAL7;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float3x4 Temporal_b1_o0_gBoneMtx[40] : packoffset(c1);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c121);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c125);
	float4 Temporal_b5_o0_globalScalars : packoffset(c129);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c130);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c131);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c132);
	float4 Temporal_b4_o0_gWindParams : packoffset(c133);
	float4 Temporal_b4_o16_AirResist : packoffset(c134);
	float Temporal_b4_o32_WindStr : packoffset(c135);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	float3 r6;
	float4 r7;
	r0.x = asint(globalScalars3.z + 0.00000999999975);
	r0.y = asint(globalScalars4.z + 0.00000999999975);
	r0.z = 925353388;
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r0.x = asint(dot(asfloat(r0.xyz), i.normal.xyz));
	r0.x = asint(max(asfloat(r0.x), 0.25));
	r0.x = asint(min(asfloat(r0.x), 1));
	r0.y = asint(i.color1.z * AirResist.w);
	r0.y = asint(asfloat(r0.y) * 5);
	r1.z = asint(-(asfloat(r0.y)));
	r1.xy = asint(-(i.color1.xx));
	r0.yzw = asint(asfloat(r1.xyz) * i.normal.xyz);
	r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * gBoneMtx[r1.y / 3][0];
	r2 = gBoneMtx[r1.x / 3][0] * i.blendweight.x + r2;
	r2 = gBoneMtx[r1.z / 3][0] * i.blendweight.z + r2;
	r2 = gBoneMtx[r1.w / 3][0] * i.blendweight.w + r2;
	r3.xyz = i.position.xyz;
	r3.w = 1;
	r4.x = dot(r2, r3);
	r5 = i.blendweight.y * gBoneMtx[r1.y / 3][2];
	r5 = gBoneMtx[r1.x / 3][2] * i.blendweight.x + r5;
	r5 = gBoneMtx[r1.z / 3][2] * i.blendweight.z + r5;
	r5 = gBoneMtx[r1.w / 3][2] * i.blendweight.w + r5;
	r4.z = dot(r5, r3);
	r6 = r4.xxz * float3(6, 10, 10);
	r0.w = asint(r6.z + r6.y);
	r7 = i.blendweight.y * gBoneMtx[r1.y / 3][1];
	r7 = gBoneMtx[r1.x / 3][1] * i.blendweight.x + r7;
	r7 = gBoneMtx[r1.z / 3][1] * i.blendweight.z + r7;
	r1 = asint(gBoneMtx[r1.w / 3][1] * i.blendweight.w + r7);
	r4.y = dot(asfloat(r1), r3);
	r0.w = asint(r4.y * 10 + asfloat(r0.w));
	r1.w = asint(AirResist.w * 0.00999999978 + 1);
	r2.w = asfloat(r1.w) * globalScalars3.y;
	r1.w = asint(globalScalars3.y * asfloat(r1.w) + r6.x);
	r1.w = asint(sin(asfloat(r1.w)));
	r0.w = asint(r2.w * gWindParams.z + asfloat(r0.w));
	r0.w = asint(sin(asfloat(r0.w)));
	r3.x = saturate(WindStr);
	r1.w = asint(abs(asfloat(r1.w)) * r3.x);
	r0.w = asint(abs(asfloat(r0.w)) * asfloat(r1.w));
	r1.w = asint(r4.y * 4);
	r1.w = asint(r2.w * gWindParams.w + asfloat(r1.w));
	r1.w = asint(sin(asfloat(r1.w)));
	r0.w = asint(asfloat(r0.w) * abs(asfloat(r1.w)));
	o.texcoord8.xyz = asfloat(r0.xyz) * asfloat(r0.www) + r4.xyz;
	r0.xyz = asint(r4.yyy * gWorld[1].xyz);
	r0.xyz = asint(r4.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(r4.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	o.texcoord7 = asfloat(r0.xyz) + gWorld[3].xyz;
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord.xy;
	r0.y = asint(dot(asfloat(r1.xyz), i.normal.xyz));
	r0.w = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.www) * gWorld[1].xyz);
	r3.xyz = asfloat(r0.yyy) * gWorld[1].xyz;
	r0.x = asint(dot(r2.xyz, i.normal.xyz));
	r0.w = asint(dot(r2.xyz, i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.www) * gWorld[0].xyz + asfloat(r1.xyz));
	r2.xyz = asfloat(r0.xxx) * gWorld[0].xyz + r3.xyz;
	r0.z = asint(dot(r5.xyz, i.normal.xyz));
	r0.w = asint(dot(r5.xyz, i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.www) * gWorld[2].xyz + asfloat(r1.xyz));
	r2.xyz = asfloat(r0.zzz) * gWorld[2].xyz + r2.xyz;
	o.texcoord9 = asfloat(r0.xyz);
	r0.x = asint(-(r2.z) + 1);
	r0.x = asint(asfloat(r0.x) * asfloat(r0.x));
	r0.x = asint(-(asfloat(r0.x)) * 0.0199999996 + 1);
	r2.w = max(asfloat(r0.x), r2.z);
	r0.xyz = asint(r2.xyw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord1.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord1.w = 1;
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	o.texcoord4 = asfloat(r1.xyz);
	r0.xyz = asint(asfloat(r1.zxy) * r2.yzx);
	r0.xyz = asint(asfloat(r1.yzx) * r2.zxy + -(asfloat(r0.xyz)));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
	o.texcoord5.w = i.tangent.w;

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	float3 r6;
	float4 r7;
	r0.x = asint(Temporal_b5_o32_globalScalars3.z + 0.00000999999975);
	r0.y = asint(Temporal_b5_o48_globalScalars4.z + 0.00000999999975);
	r0.z = 925353388;
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r0.x = asint(dot(asfloat(r0.xyz), i.normal.xyz));
	r0.x = asint(max(asfloat(r0.x), 0.25));
	r0.x = asint(min(asfloat(r0.x), 1));
	r0.y = asint(i.color1.z * Temporal_b4_o16_AirResist.w);
	r0.y = asint(asfloat(r0.y) * 5);
	r1.z = asint(-(asfloat(r0.y)));
	r1.xy = asint(-(i.color1.xx));
	r0.yzw = asint(asfloat(r1.xyz) * i.normal.xyz);
	r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][0];
	r2 = Temporal_b1_o0_gBoneMtx[r1.x / 3][0] * i.blendweight.x + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.z / 3][0] * i.blendweight.z + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.w / 3][0] * i.blendweight.w + r2;
	r3.xyz = i.position.xyz;
	r3.w = 1;
	r4.x = dot(r2, r3);
	r5 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][2];
	r5 = Temporal_b1_o0_gBoneMtx[r1.x / 3][2] * i.blendweight.x + r5;
	r5 = Temporal_b1_o0_gBoneMtx[r1.z / 3][2] * i.blendweight.z + r5;
	r5 = Temporal_b1_o0_gBoneMtx[r1.w / 3][2] * i.blendweight.w + r5;
	r4.z = dot(r5, r3);
	r6 = r4.xxz * float3(6, 10, 10);
	r0.w = asint(r6.z + r6.y);
	r7 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][1];
	r7 = Temporal_b1_o0_gBoneMtx[r1.x / 3][1] * i.blendweight.x + r7;
	r7 = Temporal_b1_o0_gBoneMtx[r1.z / 3][1] * i.blendweight.z + r7;
	r1 = asint(Temporal_b1_o0_gBoneMtx[r1.w / 3][1] * i.blendweight.w + r7);
	r4.y = dot(asfloat(r1), r3);
	r0.w = asint(r4.y * 10 + asfloat(r0.w));
	r1.w = asint(Temporal_b4_o16_AirResist.w * 0.00999999978 + 1);
	r2.w = asfloat(r1.w) * Temporal_b5_o32_globalScalars3.y;
	r1.w = asint(Temporal_b5_o32_globalScalars3.y * asfloat(r1.w) + r6.x);
	r1.w = asint(sin(asfloat(r1.w)));
	r0.w = asint(r2.w * Temporal_b4_o0_gWindParams.z + asfloat(r0.w));
	r0.w = asint(sin(asfloat(r0.w)));
	r3.x = saturate(Temporal_b4_o32_WindStr);
	r1.w = asint(abs(asfloat(r1.w)) * r3.x);
	r0.w = asint(abs(asfloat(r0.w)) * asfloat(r1.w));
	r1.w = asint(r4.y * 4);
	r1.w = asint(r2.w * Temporal_b4_o0_gWindParams.w + asfloat(r1.w));
	r1.w = asint(sin(asfloat(r1.w)));
	r0.w = asint(asfloat(r0.w) * abs(asfloat(r1.w)));
	o.texcoord8.xyz = asfloat(r0.xyz) * asfloat(r0.www) + r4.xyz;
	r0.xyz = asint(r4.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(r4.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(r4.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	o.texcoord7 = asfloat(r0.xyz) + Temporal_b0_o0_gWorld[3].xyz;
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord.xy;
	r0.y = asint(dot(asfloat(r1.xyz), i.normal.xyz));
	r0.w = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.www) * Temporal_b0_o0_gWorld[1].xyz);
	r3.xyz = asfloat(r0.yyy) * Temporal_b0_o0_gWorld[1].xyz;
	r0.x = asint(dot(r2.xyz, i.normal.xyz));
	r0.w = asint(dot(r2.xyz, i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.www) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r1.xyz));
	r2.xyz = asfloat(r0.xxx) * Temporal_b0_o0_gWorld[0].xyz + r3.xyz;
	r0.z = asint(dot(r5.xyz, i.normal.xyz));
	r0.w = asint(dot(r5.xyz, i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.www) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r1.xyz));
	r2.xyz = asfloat(r0.zzz) * Temporal_b0_o0_gWorld[2].xyz + r2.xyz;
	o.texcoord9 = asfloat(r0.xyz);
	r0.x = asint(-(r2.z) + 1);
	r0.x = asint(asfloat(r0.x) * asfloat(r0.x));
	r0.x = asint(-(asfloat(r0.x)) * 0.0199999996 + 1);
	r2.w = max(asfloat(r0.x), r2.z);
	r0.xyz = asint(r2.xyw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord1.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord1.w = 1;
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	o.texcoord4 = asfloat(r1.xyz);
	r0.xyz = asint(asfloat(r1.zxy) * r2.yzx);
	r0.xyz = asint(asfloat(r1.yzx) * r2.zxy + -(asfloat(r0.xyz)));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
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
    o.texcoord4 = c.texcoord4;
    o.texcoord5 = c.texcoord5;
    o.texcoord7 = c.texcoord7;
    o.texcoord9 = c.texcoord9;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord1 = o.texcoord1;
    o.temporalInput_texcoord2 = o.texcoord2;
    o.temporalInput_texcoord4 = o.texcoord4;
    o.temporalInput_texcoord5 = o.texcoord5;
    o.temporalInput_texcoord7 = o.texcoord7;
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
        o.temporalInput_texcoord7 = p.texcoord7;
        o.temporalInput_texcoord9 = p.texcoord9;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
