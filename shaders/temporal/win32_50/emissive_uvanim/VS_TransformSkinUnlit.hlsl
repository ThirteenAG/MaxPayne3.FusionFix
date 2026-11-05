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

struct VS_IN
{
	float3 position : POSITION;
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float2 texcoord : TEXCOORD;
	float4 color : COLOR;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * gBoneMtx[r0.y / 3][1];
	r1 = gBoneMtx[r0.x / 3][1] * i.blendweight.x + r1;
	r1 = gBoneMtx[r0.z / 3][1] * i.blendweight.z + r1;
	r1 = gBoneMtx[r0.w / 3][1] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz;
	r2.w = 1;
	r1.x = dot(r1, r2);
	r1 = r1.x * gWorldViewProj[1];
	r3 = i.blendweight.y * gBoneMtx[r0.y / 3][0];
	r3 = gBoneMtx[r0.x / 3][0] * i.blendweight.x + r3;
	r3 = gBoneMtx[r0.z / 3][0] * i.blendweight.z + r3;
	r3 = gBoneMtx[r0.w / 3][0] * i.blendweight.w + r3;
	r3.x = dot(r3, r2);
	r1 = r3.x * gWorldViewProj[0] + r1;
	r3 = i.blendweight.y * gBoneMtx[r0.y / 3][2];
	r3 = gBoneMtx[r0.x / 3][2] * i.blendweight.x + r3;
	r3 = gBoneMtx[r0.z / 3][2] * i.blendweight.z + r3;
	r0 = asint(gBoneMtx[r0.w / 3][2] * i.blendweight.w + r3);
	r0.x = asint(dot(asfloat(r0), r2));
	r0 = asint(asfloat(r0.x) * gWorldViewProj[2] + r1);
	r0 = asint(asfloat(r0) + gWorldViewProj[3]);
	o.sv_position = asfloat(r0) + float4(0, 0, -0.0000999999975, 0);
	o.color = i.color;
	o.texcoord = i.texcoord.xy;

	return o;
}
