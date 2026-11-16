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
	float4 blendindices : BLENDINDICES;
	float2 texcoord : TEXCOORD;
	float4 color : COLOR;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord2 : TEXCOORD2;
};

VS_OUT main(VS_IN i)
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
	r0.y = asint(dot(gBoneMtx[r0.x / 3][0], r1));
	r0.x = asint(dot(gBoneMtx[r0.x / 3][2], r1));
	r1 = asfloat(r0.y) * gWorldViewProj[0] + r2;
	r0 = asint(asfloat(r0.x) * gWorldViewProj[2] + r1);
	o.sv_position = asfloat(r0) + gWorldViewProj[3];
	o.texcoord = i.texcoord.xy;
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;

	return o;
}
