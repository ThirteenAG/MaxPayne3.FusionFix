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
};

Buffer<float4> clothVertexTexture : register(t2);

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
};
Buffer<float4> TemporalResource_t2_clothVertexTexture : register(t127);

VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float3 r5;
	float3 r6;
	float3 r7;
	float4 r8;
	float3 r9;
	float3 r10;
	float3 r11;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r1 = r0 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * gBoneMtx[r1.y / 3][0];
	r3 = i.blendweight.y * gBoneMtx[r1.y / 3][1];
	r4 = i.blendweight.y * gBoneMtx[r1.y / 3][2];
	r2 = gBoneMtx[r1.x / 3][0] * i.blendweight.x + r2;
	r3 = gBoneMtx[r1.x / 3][1] * i.blendweight.x + r3;
	r4 = gBoneMtx[r1.x / 3][2] * i.blendweight.x + r4;
	r2 = gBoneMtx[r1.z / 3][0] * i.blendweight.z + r2;
	r3 = gBoneMtx[r1.z / 3][1] * i.blendweight.z + r3;
	r4 = gBoneMtx[r1.z / 3][2] * i.blendweight.z + r4;
	r2 = gBoneMtx[r1.w / 3][0] * i.blendweight.w + r2;
	r3 = gBoneMtx[r1.w / 3][1] * i.blendweight.w + r3;
	r1 = asint(gBoneMtx[r1.w / 3][2] * i.blendweight.w + r4);
	r0.x = (254 < r0.x) ? -1 : 0;
	r2 = (r0.x != 0) ? gBoneMtx[0][0] : r2;
	r3 = (r0.x != 0) ? gBoneMtx[0][1] : r3;
	r1 = (r0.x != 0) ? asint(gBoneMtx[0][2]) : r1;
	r4.xyz = i.position.xyz;
	r4.w = 1;
	r5.x = dot(r2, r4);
	r5.y = dot(r3, r4);
	r5.z = dot(asfloat(r1), r4);
	r4.xyz = r5.yyy * gWorld[1].xyz;
	r4.xyz = r5.xxx * gWorld[0].xyz + r4.xyz;
	r4.xyz = r5.zzz * gWorld[2].xyz + r4.xyz;
	r4.xyz = r4.xyz + gWorld[3].xyz;
	o.texcoord3 = -(r4.xyz) + gViewInverse[3].xyz;
	r1.w = asint(dot(r2.xyz, -(i.tangent.xyz)));
	r2.w = dot(r3.xyz, -(i.tangent.xyz));
	r3.w = dot(asfloat(r1.xyz), -(i.tangent.xyz));
	r6 = r2.www * gWorld[1].xyz;
	r6 = asfloat(r1.www) * gWorld[0].xyz + r6.xyz;
	r6 = r3.www * gWorld[2].xyz + r6.xyz;
	if (r0.x != 0) {
		r7 = clothVertexTexture.Load(r0.y).xyz;
		r0.xyz = asint(clothVertexTexture.Load(r0.z).xyz);
		r8.xyz = clothVertexTexture.Load(r0.w).xyz;
		r9.x = dot(gWorld[0].xyz, r7.xyz);
		r9.y = dot(gWorld[1].xyz, r7.xyz);
		r9.z = dot(gWorld[2].xyz, r7.xyz);
		r7.x = dot(gWorld[0].xyz, asfloat(r0.xyz));
		r7.y = dot(gWorld[1].xyz, asfloat(r0.xyz));
		r7.z = dot(gWorld[2].xyz, asfloat(r0.xyz));
		r0.x = asint(dot(gWorld[0].xyz, r8.xyz));
		r0.y = asint(dot(gWorld[1].xyz, r8.xyz));
		r0.z = asint(dot(gWorld[2].xyz, r8.xyz));
		r8.xyz = -(r7.zxy) + r9.zxy;
		r10 = -(r7.yzx) + asfloat(r0.yzx);
		r11 = r8.xyz * r10.xyz;
		r8.xyz = r8.zxy * r10.yzx + -(r11.xyz);
		r0.w = asint(dot(r8.xyz, r8.xyz));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r8.xyz = asfloat(r0.www) * r8.xyz;
		r7 = r7.xyz * i.blendweight.yyy;
		r7 = i.blendweight.zzz * r9.xyz + r7.xyz;
		r0.xyz = asint(i.blendweight.xxx * asfloat(r0.xyz) + r7.xyz);
		r0.w = asint(i.blendweight.w + -0.5);
		r0.w = asint(asfloat(r0.w) * 0.100000001);
		r5 = asfloat(r0.www) * r8.xyz + asfloat(r0.xyz);
		r0.xyz = asint(r5.yyy * gWorld[1].xyz);
		r0.xyz = asint(r5.xxx * gWorld[0].xyz + asfloat(r0.xyz));
		r0.xyz = asint(r5.zzz * gWorld[2].xyz + asfloat(r0.xyz));
		o.texcoord7 = asfloat(r0.xyz) + gWorld[3].xyz;
		r0.xyz = asint(-(r8.yyy) * gWorld[1].xyz);
		r0.xyz = asint(-(r8.xxx) * gWorld[0].xyz + asfloat(r0.xyz));
		r0.xyz = asint(-(r8.zzz) * gWorld[2].xyz + asfloat(r0.xyz));
		r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
		r1.w = asint(dot(r6.xyz, r6.xyz));
		r1.w = asint(rsqrt(asfloat(r1.w)));
		r7 = asfloat(r1.www) * r6.xyz;
		r8.xyz = asfloat(r0.yzx) * r7.zxy;
		r8.xyz = r7.yzx * asfloat(r0.zxy) + -(r8.xyz);
		r8.xyz = r8.xyz * -(i.tangent.www);
		o.texcoord4 = r7.xyz;
	} else {
		r1.w = asint(dot(r2.xyz, -(i.normal.xyz)));
		r2.x = dot(r3.xyz, -(i.normal.xyz));
		r1.x = asint(dot(asfloat(r1.xyz), -(i.normal.xyz)));
		r2.xyz = r2.xxx * gWorld[1].xyz;
		r1.yzw = asint(asfloat(r1.www) * gWorld[0].xyz + r2.xyz);
		r0.xyz = asint(asfloat(r1.xxx) * gWorld[2].xyz + asfloat(r1.yzw));
		r1.xyz = asint(asfloat(r0.yzx) * r6.zxy);
		r1.xyz = asint(r6.yzx * asfloat(r0.zxy) + -(asfloat(r1.xyz)));
		r8.xyz = asfloat(r1.xyz) * -(i.tangent.www);
		o.texcoord4 = r6.xyz;
		o.texcoord7 = r4.xyz;
	}
	r1 = asint(r5.y * gWorldViewProj[1]);
	r1 = asint(r5.x * gWorldViewProj[0] + asfloat(r1));
	r1 = asint(r5.z * gWorldViewProj[2] + asfloat(r1));
	r1 = asint(asfloat(r1) + gWorldViewProj[3]);
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.sv_position = asfloat(r1);
	r0.w = r1.w;
	o.texcoord1 = asfloat(r0);
	o.texcoord2.xzw = i.color.xzw;
	r8.w = -(i.tangent.w);
	o.texcoord5 = r8;
	o.texcoord = i.texcoord.xy;

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
	float3 r5;
	float3 r6;
	float3 r7;
	float4 r8;
	float3 r9;
	float3 r10;
	float3 r11;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r1 = r0 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][0];
	r3 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][1];
	r4 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][2];
	r2 = Temporal_b1_o0_gBoneMtx[r1.x / 3][0] * i.blendweight.x + r2;
	r3 = Temporal_b1_o0_gBoneMtx[r1.x / 3][1] * i.blendweight.x + r3;
	r4 = Temporal_b1_o0_gBoneMtx[r1.x / 3][2] * i.blendweight.x + r4;
	r2 = Temporal_b1_o0_gBoneMtx[r1.z / 3][0] * i.blendweight.z + r2;
	r3 = Temporal_b1_o0_gBoneMtx[r1.z / 3][1] * i.blendweight.z + r3;
	r4 = Temporal_b1_o0_gBoneMtx[r1.z / 3][2] * i.blendweight.z + r4;
	r2 = Temporal_b1_o0_gBoneMtx[r1.w / 3][0] * i.blendweight.w + r2;
	r3 = Temporal_b1_o0_gBoneMtx[r1.w / 3][1] * i.blendweight.w + r3;
	r1 = asint(Temporal_b1_o0_gBoneMtx[r1.w / 3][2] * i.blendweight.w + r4);
	r0.x = (254 < r0.x) ? -1 : 0;
	r2 = (r0.x != 0) ? Temporal_b1_o0_gBoneMtx[0][0] : r2;
	r3 = (r0.x != 0) ? Temporal_b1_o0_gBoneMtx[0][1] : r3;
	r1 = (r0.x != 0) ? asint(Temporal_b1_o0_gBoneMtx[0][2]) : r1;
	r4.xyz = i.position.xyz;
	r4.w = 1;
	r5.x = dot(r2, r4);
	r5.y = dot(r3, r4);
	r5.z = dot(asfloat(r1), r4);
	r4.xyz = r5.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r4.xyz = r5.xxx * Temporal_b0_o0_gWorld[0].xyz + r4.xyz;
	r4.xyz = r5.zzz * Temporal_b0_o0_gWorld[2].xyz + r4.xyz;
	r4.xyz = r4.xyz + Temporal_b0_o0_gWorld[3].xyz;
	o.texcoord3 = -(r4.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	r1.w = asint(dot(r2.xyz, -(i.tangent.xyz)));
	r2.w = dot(r3.xyz, -(i.tangent.xyz));
	r3.w = dot(asfloat(r1.xyz), -(i.tangent.xyz));
	r6 = r2.www * Temporal_b0_o0_gWorld[1].xyz;
	r6 = asfloat(r1.www) * Temporal_b0_o0_gWorld[0].xyz + r6.xyz;
	r6 = r3.www * Temporal_b0_o0_gWorld[2].xyz + r6.xyz;
	if (r0.x != 0) {
		r7 = TemporalResource_t2_clothVertexTexture.Load(r0.y).xyz;
		r0.xyz = asint(TemporalResource_t2_clothVertexTexture.Load(r0.z).xyz);
		r8.xyz = TemporalResource_t2_clothVertexTexture.Load(r0.w).xyz;
		r9.x = dot(Temporal_b0_o0_gWorld[0].xyz, r7.xyz);
		r9.y = dot(Temporal_b0_o0_gWorld[1].xyz, r7.xyz);
		r9.z = dot(Temporal_b0_o0_gWorld[2].xyz, r7.xyz);
		r7.x = dot(Temporal_b0_o0_gWorld[0].xyz, asfloat(r0.xyz));
		r7.y = dot(Temporal_b0_o0_gWorld[1].xyz, asfloat(r0.xyz));
		r7.z = dot(Temporal_b0_o0_gWorld[2].xyz, asfloat(r0.xyz));
		r0.x = asint(dot(Temporal_b0_o0_gWorld[0].xyz, r8.xyz));
		r0.y = asint(dot(Temporal_b0_o0_gWorld[1].xyz, r8.xyz));
		r0.z = asint(dot(Temporal_b0_o0_gWorld[2].xyz, r8.xyz));
		r8.xyz = -(r7.zxy) + r9.zxy;
		r10 = -(r7.yzx) + asfloat(r0.yzx);
		r11 = r8.xyz * r10.xyz;
		r8.xyz = r8.zxy * r10.yzx + -(r11.xyz);
		r0.w = asint(dot(r8.xyz, r8.xyz));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r8.xyz = asfloat(r0.www) * r8.xyz;
		r7 = r7.xyz * i.blendweight.yyy;
		r7 = i.blendweight.zzz * r9.xyz + r7.xyz;
		r0.xyz = asint(i.blendweight.xxx * asfloat(r0.xyz) + r7.xyz);
		r0.w = asint(i.blendweight.w + -0.5);
		r0.w = asint(asfloat(r0.w) * 0.100000001);
		r5 = asfloat(r0.www) * r8.xyz + asfloat(r0.xyz);
		r0.xyz = asint(r5.yyy * Temporal_b0_o0_gWorld[1].xyz);
		r0.xyz = asint(r5.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
		r0.xyz = asint(r5.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
		o.texcoord7 = asfloat(r0.xyz) + Temporal_b0_o0_gWorld[3].xyz;
		r0.xyz = asint(-(r8.yyy) * Temporal_b0_o0_gWorld[1].xyz);
		r0.xyz = asint(-(r8.xxx) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
		r0.xyz = asint(-(r8.zzz) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
		r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
		r1.w = asint(dot(r6.xyz, r6.xyz));
		r1.w = asint(rsqrt(asfloat(r1.w)));
		r7 = asfloat(r1.www) * r6.xyz;
		r8.xyz = asfloat(r0.yzx) * r7.zxy;
		r8.xyz = r7.yzx * asfloat(r0.zxy) + -(r8.xyz);
		r8.xyz = r8.xyz * -(i.tangent.www);
		o.texcoord4 = r7.xyz;
	} else {
		r1.w = asint(dot(r2.xyz, -(i.normal.xyz)));
		r2.x = dot(r3.xyz, -(i.normal.xyz));
		r1.x = asint(dot(asfloat(r1.xyz), -(i.normal.xyz)));
		r2.xyz = r2.xxx * Temporal_b0_o0_gWorld[1].xyz;
		r1.yzw = asint(asfloat(r1.www) * Temporal_b0_o0_gWorld[0].xyz + r2.xyz);
		r0.xyz = asint(asfloat(r1.xxx) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r1.yzw));
		r1.xyz = asint(asfloat(r0.yzx) * r6.zxy);
		r1.xyz = asint(r6.yzx * asfloat(r0.zxy) + -(asfloat(r1.xyz)));
		r8.xyz = asfloat(r1.xyz) * -(i.tangent.www);
		o.texcoord4 = r6.xyz;
		o.texcoord7 = r4.xyz;
	}
	r1 = asint(r5.y * Temporal_b0_o128_gWorldViewProj[1]);
	r1 = asint(r5.x * Temporal_b0_o128_gWorldViewProj[0] + asfloat(r1));
	r1 = asint(r5.z * Temporal_b0_o128_gWorldViewProj[2] + asfloat(r1));
	r1 = asint(asfloat(r1) + Temporal_b0_o128_gWorldViewProj[3]);
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.sv_position = asfloat(r1);
	r0.w = r1.w;
	o.texcoord1 = asfloat(r0);
	o.texcoord2.xzw = i.color.xzw;
	r8.w = -(i.tangent.w);
	o.texcoord5 = r8;
	o.texcoord = i.texcoord.xy;

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
