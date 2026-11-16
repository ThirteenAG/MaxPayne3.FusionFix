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

cbuffer UserClipPlanes : register(b6)
{
	float4 g_vUserClipPlanes[8] : packoffset(c0);
};

struct VS_IN
{
	float3 position : POSITION;
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
	float3 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float sv_clipdistance : SV_ClipDistance;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float r3;
	r0.xyz = asint(i.position.xyz);
	r0.w = 1065353216;
	r1.x = asint(i.blendindices.x * 255.001953);
	r1.x = (int)asfloat(r1.x);
	r1.x = r1.x * 3;
	r1.y = asint(dot(gBoneMtx[r1.x / 3][1], asfloat(r0)));
	r2 = asfloat(r1.y) * gWorldViewProj[1];
	r1.yzw = asint(asfloat(r1.yyy) * gWorld[1].xyz);
	r3 = dot(gBoneMtx[r1.x / 3][0], asfloat(r0));
	r0.x = asint(dot(gBoneMtx[r1.x / 3][2], asfloat(r0)));
	r2 = r3.x * gWorldViewProj[0] + r2;
	r0.yzw = asint(r3.xxx * gWorld[0].xyz + asfloat(r1.yzw));
	r0.yzw = asint(asfloat(r0.xxx) * gWorld[2].xyz + asfloat(r0.yzw));
	r2 = asfloat(r0.x) * gWorldViewProj[2] + r2;
	r2 = r2 + gWorldViewProj[3];
	r0.xyz = asint(asfloat(r0.yzw) + gWorld[3].xyz);
	o.sv_position = r2;
	o.texcoord1.w = r2.w;
	o.texcoord = i.texcoord.xy;
	r2.x = dot(gBoneMtx[r1.x / 3][1].xyz, i.normal.xyz);
	r1.yzw = asint(r2.xxx * gWorld[1].xyz);
	r2.z = dot(gBoneMtx[r1.x / 3][0].xyz, i.normal.xyz);
	r1.yzw = asint(r2.zzz * gWorld[0].xyz + asfloat(r1.yzw));
	r2.y = dot(gBoneMtx[r1.x / 3][2].xyz, i.normal.xyz);
	o.texcoord1.xyz = r2.yyy * gWorld[2].xyz + asfloat(r1.yzw);
	o.texcoord2 = asfloat(r0.xyz);
	o.texcoord3 = -(asfloat(r0.xyz)) + gViewInverse[3].xyz;
	r0.x = asint(dot(gBoneMtx[r1.x / 3][0].xyz, i.tangent.xyz));
	r0.y = asint(dot(gBoneMtx[r1.x / 3][1].xyz, i.tangent.xyz));
	r0.z = asint(dot(gBoneMtx[r1.x / 3][2].xyz, i.tangent.xyz));
	o.texcoord4 = asfloat(r0.xyz);
	r1.xyz = asint(r2.xyz * asfloat(r0.zxy));
	r0.xyz = asint(asfloat(r0.yzx) * r2.yzx + -(asfloat(r1.xyz)));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
	o.texcoord5.w = i.tangent.w;
	o.texcoord6.xyz = i.color.xyz;
	o.texcoord6.w = 1;
	r0.xyz = asint(i.position.yyy * gWorld[1].xyz);
	r0.xyz = asint(i.position.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.position.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + gWorld[3].xyz);
	r0.w = 1065353216;
	r0.x = asint(dot(asfloat(r0), g_vUserClipPlanes[0]));
	r0.y = asint(g_vUserClipPlanes[0].y + g_vUserClipPlanes[0].x);
	r0.y = asint(asfloat(r0.y) + g_vUserClipPlanes[0].z);
	r0.y = asint(asfloat(r0.y) + g_vUserClipPlanes[0].w);
	r0.y = (asfloat(r0.y) != 0) ? -1 : 0;
	o.sv_clipdistance = (r0.y != 0) ? asfloat(r0.x) : 1;

	return o;
}
