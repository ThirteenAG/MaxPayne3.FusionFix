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
	float3 position1 : POSITION1;
	float3 normal1 : NORMAL1;
	float4 tangent1 : TANGENT1;
};

struct TemporalVertexResult
{
	float4 texcoord8 : TEXCOORD8;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
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
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float2 temporalInput_texcoord : TEMPORAL1;
	float4 temporalInput_texcoord1 : TEMPORAL2;
	float4 temporalInput_texcoord2 : TEMPORAL3;
	float3 temporalInput_texcoord3 : TEMPORAL4;
	float3 temporalInput_texcoord4 : TEMPORAL5;
	float4 temporalInput_texcoord5 : TEMPORAL6;
	float3 temporalInput_texcoord7 : TEMPORAL7;
	float3 temporalInput_texcoord9 : TEMPORAL8;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float3x4 Temporal_b1_o0_gBoneMtx[40] : packoffset(c1);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c121);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c125);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c129);
	row_major float4x4 Temporal_b0_o192_gViewInverse : packoffset(c133);
	float4 Temporal_b5_o0_globalScalars : packoffset(c137);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c138);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c139);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c140);
	float4 Temporal_b4_o0_gWindParams : packoffset(c141);
	float4 Temporal_b4_o16_AirResist : packoffset(c142);
	float Temporal_b4_o32_WindStr : packoffset(c143);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	int4 r2;
	float4 r3;
	float4 r4;
	float3 r5;
	float4 r6;
	float3 r7;
	float4 r8;
	r0.x = asint(globalScalars3.z + 0.00000999999975);
	r0.y = asint(globalScalars4.z + 0.00000999999975);
	r0.z = 925353388;
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r1.xyz = i.normal.xyz + i.normal1.xyz;
	r0.x = asint(dot(asfloat(r0.xyz), r1.xyz));
	r0.x = asint(max(asfloat(r0.x), 0.25));
	r0.x = asint(min(asfloat(r0.x), 1));
	r0.y = asint(i.color1.z * AirResist.w);
	r0.y = asint(asfloat(r0.y) * 5);
	r2.z = asint(-(asfloat(r0.y)));
	r2.xy = asint(-(i.color1.xx));
	r0.yzw = asint(r1.xyz * asfloat(r2.xyz));
	r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
	r2 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r2 = (int4)asfloat(r2);
	r2 = r2 * int4(3, 3, 3, 3);
	r3 = i.blendweight.y * gBoneMtx[r2.y / 3][0];
	r3 = gBoneMtx[r2.x / 3][0] * i.blendweight.x + r3;
	r3 = gBoneMtx[r2.z / 3][0] * i.blendweight.z + r3;
	r3 = gBoneMtx[r2.w / 3][0] * i.blendweight.w + r3;
	r4.xyz = i.position.xyz + i.position1.xyz;
	r4.w = 1;
	r5.x = dot(r3, r4);
	r6 = i.blendweight.y * gBoneMtx[r2.y / 3][2];
	r6 = gBoneMtx[r2.x / 3][2] * i.blendweight.x + r6;
	r6 = gBoneMtx[r2.z / 3][2] * i.blendweight.z + r6;
	r6 = gBoneMtx[r2.w / 3][2] * i.blendweight.w + r6;
	r5.z = dot(r6, r4);
	r7 = r5.xxz * float3(6, 10, 10);
	r0.w = asint(r7.z + r7.y);
	r8 = i.blendweight.y * gBoneMtx[r2.y / 3][1];
	r8 = gBoneMtx[r2.x / 3][1] * i.blendweight.x + r8;
	r8 = gBoneMtx[r2.z / 3][1] * i.blendweight.z + r8;
	r2 = asint(gBoneMtx[r2.w / 3][1] * i.blendweight.w + r8);
	r5.y = dot(asfloat(r2), r4);
	r0.w = asint(r5.y * 10 + asfloat(r0.w));
	r1.w = AirResist.w * 0.00999999978 + 1;
	r2.w = asint(r1.w * globalScalars3.y);
	r1.w = globalScalars3.y * r1.w + r7.x;
	r1.w = sin(r1.w);
	r0.w = asint(asfloat(r2.w) * gWindParams.z + asfloat(r0.w));
	r0.w = asint(sin(asfloat(r0.w)));
	r3.w = saturate(WindStr);
	r1.w = abs(r1.w) * r3.w;
	r0.w = asint(abs(asfloat(r0.w)) * r1.w);
	r1.w = r5.y * 4;
	r1.w = asfloat(r2.w) * gWindParams.w + r1.w;
	r1.w = sin(r1.w);
	r0.w = asint(asfloat(r0.w) * abs(r1.w));
	o.texcoord8.xyz = asfloat(r0.xyz) * asfloat(r0.www) + r5.xyz;
	r0.xyz = asint(r5.yyy * gWorld[1].xyz);
	r0.xyz = asint(r5.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(r5.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + gWorld[3].xyz);
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord.xy;
	r4.y = dot(asfloat(r2.xyz), r1.xyz);
	r5 = r4.yyy * gWorld[1].xyz;
	r4.x = dot(r3.xyz, r1.xyz);
	r4.z = dot(r6.xyz, r1.xyz);
	r1.xyz = r4.xxx * gWorld[0].xyz + r5.xyz;
	o.texcoord9 = r4.xyz;
	r1.xyz = r4.zzz * gWorld[2].xyz + r1.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord1.w = 1;
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	o.texcoord3 = -(asfloat(r0.xyz)) + gViewInverse[3].xyz;
	o.texcoord7 = asfloat(r0.xyz);
	r0 = asint(i.tangent + i.tangent1);
	r1.w = dot(asfloat(r2.xyz), asfloat(r0.xyz));
	r2.xyz = asint(r1.www * gWorld[1].xyz);
	r1.w = dot(r3.xyz, asfloat(r0.xyz));
	r2.xyz = asint(r1.www * gWorld[0].xyz + asfloat(r2.xyz));
	r0.x = asint(dot(r6.xyz, asfloat(r0.xyz)));
	r0.xyz = asint(asfloat(r0.xxx) * gWorld[2].xyz + asfloat(r2.xyz));
	o.texcoord4 = asfloat(r0.xyz);
	r2.xyz = asint(r1.yzx * asfloat(r0.zxy));
	r0.xyz = asint(asfloat(r0.yzx) * r1.zxy + -(asfloat(r2.xyz)));
	o.texcoord5.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord5.w = asfloat(r0.w);

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	int4 r2;
	float4 r3;
	float4 r4;
	float3 r5;
	float4 r6;
	float3 r7;
	float4 r8;
	r0.x = asint(Temporal_b5_o32_globalScalars3.z + 0.00000999999975);
	r0.y = asint(Temporal_b5_o48_globalScalars4.z + 0.00000999999975);
	r0.z = 925353388;
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r1.xyz = i.normal.xyz + i.normal1.xyz;
	r0.x = asint(dot(asfloat(r0.xyz), r1.xyz));
	r0.x = asint(max(asfloat(r0.x), 0.25));
	r0.x = asint(min(asfloat(r0.x), 1));
	r0.y = asint(i.color1.z * Temporal_b4_o16_AirResist.w);
	r0.y = asint(asfloat(r0.y) * 5);
	r2.z = asint(-(asfloat(r0.y)));
	r2.xy = asint(-(i.color1.xx));
	r0.yzw = asint(r1.xyz * asfloat(r2.xyz));
	r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
	r2 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r2 = (int4)asfloat(r2);
	r2 = r2 * int4(3, 3, 3, 3);
	r3 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r2.y / 3][0];
	r3 = Temporal_b1_o0_gBoneMtx[r2.x / 3][0] * i.blendweight.x + r3;
	r3 = Temporal_b1_o0_gBoneMtx[r2.z / 3][0] * i.blendweight.z + r3;
	r3 = Temporal_b1_o0_gBoneMtx[r2.w / 3][0] * i.blendweight.w + r3;
	r4.xyz = i.position.xyz + i.position1.xyz;
	r4.w = 1;
	r5.x = dot(r3, r4);
	r6 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r2.y / 3][2];
	r6 = Temporal_b1_o0_gBoneMtx[r2.x / 3][2] * i.blendweight.x + r6;
	r6 = Temporal_b1_o0_gBoneMtx[r2.z / 3][2] * i.blendweight.z + r6;
	r6 = Temporal_b1_o0_gBoneMtx[r2.w / 3][2] * i.blendweight.w + r6;
	r5.z = dot(r6, r4);
	r7 = r5.xxz * float3(6, 10, 10);
	r0.w = asint(r7.z + r7.y);
	r8 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r2.y / 3][1];
	r8 = Temporal_b1_o0_gBoneMtx[r2.x / 3][1] * i.blendweight.x + r8;
	r8 = Temporal_b1_o0_gBoneMtx[r2.z / 3][1] * i.blendweight.z + r8;
	r2 = asint(Temporal_b1_o0_gBoneMtx[r2.w / 3][1] * i.blendweight.w + r8);
	r5.y = dot(asfloat(r2), r4);
	r0.w = asint(r5.y * 10 + asfloat(r0.w));
	r1.w = Temporal_b4_o16_AirResist.w * 0.00999999978 + 1;
	r2.w = asint(r1.w * Temporal_b5_o32_globalScalars3.y);
	r1.w = Temporal_b5_o32_globalScalars3.y * r1.w + r7.x;
	r1.w = sin(r1.w);
	r0.w = asint(asfloat(r2.w) * Temporal_b4_o0_gWindParams.z + asfloat(r0.w));
	r0.w = asint(sin(asfloat(r0.w)));
	r3.w = saturate(Temporal_b4_o32_WindStr);
	r1.w = abs(r1.w) * r3.w;
	r0.w = asint(abs(asfloat(r0.w)) * r1.w);
	r1.w = r5.y * 4;
	r1.w = asfloat(r2.w) * Temporal_b4_o0_gWindParams.w + r1.w;
	r1.w = sin(r1.w);
	r0.w = asint(asfloat(r0.w) * abs(r1.w));
	o.texcoord8.xyz = asfloat(r0.xyz) * asfloat(r0.www) + r5.xyz;
	r0.xyz = asint(r5.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(r5.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(r5.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + Temporal_b0_o0_gWorld[3].xyz);
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord.xy;
	r4.y = dot(asfloat(r2.xyz), r1.xyz);
	r5 = r4.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r4.x = dot(r3.xyz, r1.xyz);
	r4.z = dot(r6.xyz, r1.xyz);
	r1.xyz = r4.xxx * Temporal_b0_o0_gWorld[0].xyz + r5.xyz;
	o.texcoord9 = r4.xyz;
	r1.xyz = r4.zzz * Temporal_b0_o0_gWorld[2].xyz + r1.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord1.w = 1;
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	o.texcoord3 = -(asfloat(r0.xyz)) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = asfloat(r0.xyz);
	r0 = asint(i.tangent + i.tangent1);
	r1.w = dot(asfloat(r2.xyz), asfloat(r0.xyz));
	r2.xyz = asint(r1.www * Temporal_b0_o0_gWorld[1].xyz);
	r1.w = dot(r3.xyz, asfloat(r0.xyz));
	r2.xyz = asint(r1.www * Temporal_b0_o0_gWorld[0].xyz + asfloat(r2.xyz));
	r0.x = asint(dot(r6.xyz, asfloat(r0.xyz)));
	r0.xyz = asint(asfloat(r0.xxx) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r2.xyz));
	o.texcoord4 = asfloat(r0.xyz);
	r2.xyz = asint(r1.yzx * asfloat(r0.zxy));
	r0.xyz = asint(asfloat(r0.yzx) * r1.zxy + -(asfloat(r2.xyz)));
	o.texcoord5.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord5.w = asfloat(r0.w);

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
        o.temporalInput_texcoord7 = p.texcoord7;
        o.temporalInput_texcoord9 = p.texcoord9;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
