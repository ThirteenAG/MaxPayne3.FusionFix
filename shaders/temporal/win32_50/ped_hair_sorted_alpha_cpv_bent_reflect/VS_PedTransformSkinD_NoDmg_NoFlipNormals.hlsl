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
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord7 : TEXCOORD7;
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
	float4 Temporal_b5_o0_globalScalars : packoffset(c137);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c138);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c139);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c140);
	float4 Temporal_b4_o0_gWindParams : packoffset(c141);
	float4 Temporal_b4_o16_AirResist : packoffset(c142);
	float Temporal_b4_o32_WindStr : packoffset(c143);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
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
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r0.www) + r4.xyz);
	r3.xyz = r4.yyy * gWorld[1].xyz;
	r3.xyz = r4.xxx * gWorld[0].xyz + r3.xyz;
	r3.xyz = r4.zzz * gWorld[2].xyz + r3.xyz;
	r3.xyz = r3.xyz + gWorld[3].xyz;
	r4 = asfloat(r0.y) * gWorldViewProj[1];
	r4 = asfloat(r0.x) * gWorldViewProj[0] + r4;
	r0 = asint(asfloat(r0.z) * gWorldViewProj[2] + r4);
	r0 = asint(asfloat(r0) + gWorldViewProj[3]);
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	o.texcoord = i.texcoord.xy;
	r0.x = asint(dot(asfloat(r1.xyz), i.normal.xyz));
	r0.y = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r0.yzw = asint(asfloat(r0.yyy) * gWorld[1].xyz);
	r1.xyz = asint(asfloat(r0.xxx) * gWorld[1].xyz);
	r0.x = asint(dot(r2.xyz, i.normal.xyz));
	r1.w = asint(dot(r2.xyz, i.tangent.xyz));
	r0.yzw = asint(asfloat(r1.www) * gWorld[0].xyz + asfloat(r0.yzw));
	r1.xyz = asint(asfloat(r0.xxx) * gWorld[0].xyz + asfloat(r1.xyz));
	r0.x = asint(dot(r5.xyz, i.normal.xyz));
	r1.w = asint(dot(r5.xyz, i.tangent.xyz));
	r0.yzw = asint(asfloat(r1.www) * gWorld[2].xyz + asfloat(r0.yzw));
	r1.xyz = asint(asfloat(r0.xxx) * gWorld[2].xyz + asfloat(r1.xyz));
	r0.x = asint(-(asfloat(r1.z)) + 1);
	r0.x = asint(asfloat(r0.x) * asfloat(r0.x));
	r0.x = asint(-(asfloat(r0.x)) * 0.0199999996 + 1);
	r1.w = asint(max(asfloat(r0.x), asfloat(r1.z)));
	r2.xyz = asfloat(r1.xyw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = asint(dot(r2.xyz, r2.xyz));
	r0.x = asint(rsqrt(asfloat(r0.x)));
	o.texcoord1.xyz = asfloat(r0.xxx) * r2.xyz;
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	o.texcoord3 = -(r3.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r3.xyz;
	o.texcoord4 = asfloat(r0.yzw);
	r2.xyz = asfloat(r0.wyz) * asfloat(r1.yzx);
	r0.xyz = asint(asfloat(r0.zwy) * asfloat(r1.zxy) + -(r2.xyz));
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
	float4 r4;
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
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r0.www) + r4.xyz);
	r3.xyz = r4.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r3.xyz = r4.xxx * Temporal_b0_o0_gWorld[0].xyz + r3.xyz;
	r3.xyz = r4.zzz * Temporal_b0_o0_gWorld[2].xyz + r3.xyz;
	r3.xyz = r3.xyz + Temporal_b0_o0_gWorld[3].xyz;
	r4 = asfloat(r0.y) * Temporal_b0_o128_gWorldViewProj[1];
	r4 = asfloat(r0.x) * Temporal_b0_o128_gWorldViewProj[0] + r4;
	r0 = asint(asfloat(r0.z) * Temporal_b0_o128_gWorldViewProj[2] + r4);
	r0 = asint(asfloat(r0) + Temporal_b0_o128_gWorldViewProj[3]);
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	o.texcoord = i.texcoord.xy;
	r0.x = asint(dot(asfloat(r1.xyz), i.normal.xyz));
	r0.y = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r0.yzw = asint(asfloat(r0.yyy) * Temporal_b0_o0_gWorld[1].xyz);
	r1.xyz = asint(asfloat(r0.xxx) * Temporal_b0_o0_gWorld[1].xyz);
	r0.x = asint(dot(r2.xyz, i.normal.xyz));
	r1.w = asint(dot(r2.xyz, i.tangent.xyz));
	r0.yzw = asint(asfloat(r1.www) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.yzw));
	r1.xyz = asint(asfloat(r0.xxx) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r1.xyz));
	r0.x = asint(dot(r5.xyz, i.normal.xyz));
	r1.w = asint(dot(r5.xyz, i.tangent.xyz));
	r0.yzw = asint(asfloat(r1.www) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.yzw));
	r1.xyz = asint(asfloat(r0.xxx) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r1.xyz));
	r0.x = asint(-(asfloat(r1.z)) + 1);
	r0.x = asint(asfloat(r0.x) * asfloat(r0.x));
	r0.x = asint(-(asfloat(r0.x)) * 0.0199999996 + 1);
	r1.w = asint(max(asfloat(r0.x), asfloat(r1.z)));
	r2.xyz = asfloat(r1.xyw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = asint(dot(r2.xyz, r2.xyz));
	r0.x = asint(rsqrt(asfloat(r0.x)));
	o.texcoord1.xyz = asfloat(r0.xxx) * r2.xyz;
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	o.texcoord3 = -(r3.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = r3.xyz;
	o.texcoord4 = asfloat(r0.yzw);
	r2.xyz = asfloat(r0.wyz) * asfloat(r1.yzx);
	r0.xyz = asint(asfloat(r0.zwy) * asfloat(r1.zxy) + -(r2.xyz));
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
