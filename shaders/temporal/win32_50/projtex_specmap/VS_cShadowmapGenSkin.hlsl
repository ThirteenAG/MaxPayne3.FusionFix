cbuffer rage_bonemtx : register(b1)
{
	row_major float3x4 gBoneMtx[40] : packoffset(c0);
};

cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
};

cbuffer ShadowParam : register(b8)
{
	float4 gShadowParam18192021 : packoffset(c0);
	float4 gShadowParam14151617 : packoffset(c1);
	float4 gShadowParam0123 : packoffset(c2);
	float4 gShadowParam4567 : packoffset(c3);
	float4 gShadowParam891113 : packoffset(c4);
	float4 gCascadeZScales : packoffset(c5);
	float4 gCascadeZOffsets : packoffset(c6);
	float4 gCascadeXMinThresholds : packoffset(c7);
	float4 gCascadeXMaxThresholds : packoffset(c8);
	float4 gCascadeYMinThresholds : packoffset(c9);
	float4 gCascadeYMaxThresholds : packoffset(c10);
	row_major float4x4 gShadowMatrix : packoffset(c11);
};

Buffer<float4> clothVertexTexture : register(t2);

struct VS_IN
{
	float3 position : POSITION;
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float4 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float3 texcoord : TEXCOORD;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float3 r5;
	float3 r6;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r1.x = (254 < r0.x) ? -1 : 0;
	if (r1.x != 0) {
		r1.xyz = asint(clothVertexTexture.Load(r0.y).xyz);
		r2.xyz = clothVertexTexture.Load(r0.z).xyz;
		r3.xyz = clothVertexTexture.Load(r0.w).xyz;
		r4.x = dot(gWorld[0].xyz, asfloat(r1.xyz));
		r4.y = dot(gWorld[1].xyz, asfloat(r1.xyz));
		r4.z = dot(gWorld[2].xyz, asfloat(r1.xyz));
		r1.x = asint(dot(gWorld[0].xyz, r2.xyz));
		r1.y = asint(dot(gWorld[1].xyz, r2.xyz));
		r1.z = asint(dot(gWorld[2].xyz, r2.xyz));
		r2.x = dot(gWorld[0].xyz, r3.xyz);
		r2.y = dot(gWorld[1].xyz, r3.xyz);
		r2.z = dot(gWorld[2].xyz, r3.xyz);
		r3.xyz = -(asfloat(r1.zxy)) + r4.zxy;
		r5 = -(asfloat(r1.yzx)) + r2.yzx;
		r6 = r3.xyz * r5.xyz;
		r3.xyz = r3.zxy * r5.yzx + -(r6.xyz);
		r1.w = asint(dot(r3.xyz, r3.xyz));
		r1.w = asint(rsqrt(asfloat(r1.w)));
		r3.xyz = asfloat(r1.www) * r3.xyz;
		r1.xyz = asint(asfloat(r1.xyz) * i.blendweight.yyy);
		r1.xyz = asint(i.blendweight.zzz * r4.xyz + asfloat(r1.xyz));
		r1.xyz = asint(i.blendweight.xxx * r2.xyz + asfloat(r1.xyz));
		r1.w = asint(i.blendweight.w + -0.5);
		r1.w = asint(asfloat(r1.w) * 0.100000001);
		r1.xyz = asint(asfloat(r1.www) * r3.xyz + asfloat(r1.xyz));
	} else {
		r0 = r0 * int4(3, 3, 3, 3);
		r2 = i.blendweight.y * gBoneMtx[r0.y / 3][0];
		r3 = i.blendweight.y * gBoneMtx[r0.y / 3][1];
		r4 = i.blendweight.y * gBoneMtx[r0.y / 3][2];
		r2 = gBoneMtx[r0.x / 3][0] * i.blendweight.x + r2;
		r3 = gBoneMtx[r0.x / 3][1] * i.blendweight.x + r3;
		r4 = gBoneMtx[r0.x / 3][2] * i.blendweight.x + r4;
		r2 = gBoneMtx[r0.z / 3][0] * i.blendweight.z + r2;
		r3 = gBoneMtx[r0.z / 3][1] * i.blendweight.z + r3;
		r4 = gBoneMtx[r0.z / 3][2] * i.blendweight.z + r4;
		r2 = gBoneMtx[r0.w / 3][0] * i.blendweight.w + r2;
		r3 = gBoneMtx[r0.w / 3][1] * i.blendweight.w + r3;
		r0 = asint(gBoneMtx[r0.w / 3][2] * i.blendweight.w + r4);
		r4.xyz = i.position.xyz;
		r4.w = 1;
		r1.x = asint(dot(r2, r4));
		r1.y = asint(dot(r3, r4));
		r1.z = asint(dot(asfloat(r0), r4));
	}
	r0.xyz = asint(asfloat(r1.yyy) * gWorld[1].xyz);
	r0.xyz = asint(asfloat(r1.xxx) * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r1.zzz) * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + gWorld[3].xyz);
	r1.xyz = asint(asfloat(r0.yyy) * gShadowMatrix[1].xyz);
	r0.xyw = asint(asfloat(r0.xxx) * gShadowMatrix[0].xyz + asfloat(r1.xyz));
	r0.xyz = asint(asfloat(r0.zzz) * gShadowMatrix[2].xyz + asfloat(r0.xyw));
	r0.xyz = asint(asfloat(r0.xyz) + gShadowMatrix[3].xyz);
	o.sv_position.z = max(asfloat(r0.z), 0);
	o.sv_position.xy = asfloat(r0.xy);
	o.sv_position.w = 1;
	o.texcoord.x = 1;
	o.texcoord.yz = i.texcoord.xy;

	return o;
}
