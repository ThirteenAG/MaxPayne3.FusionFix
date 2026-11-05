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

struct VS_IN
{
	float3 position : POSITION;
	float4 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord : TEXCOORD;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float r2;
	float4 r3;
	r0.x = (gShadowParam14151617.x == 0) ? -1 : 0;
	r0.yzw = asint(i.position.yyy * gWorld[1].xyz);
	r0.yzw = asint(i.position.xxx * gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(i.position.zzz * gWorld[2].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r0.yzw) + gWorld[3].xyz);
	r1.xyz = asfloat(r0.zzz) * gShadowMatrix[1].xyz;
	r1.xyz = asfloat(r0.yyy) * gShadowMatrix[0].xyz + r1.xyz;
	r1.xyz = asfloat(r0.www) * gShadowMatrix[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + gShadowMatrix[3].xyz;
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = sqrt(r1.w);
	r2 = -(r1.z) + r1.w;
	r3.xy = r1.xy / r2.xx;
	r3.zw = r1.wz * -(gShadowParam0123.ww);
	r1 = asfloat(r0.z) * gShadowMatrix[1];
	r1 = asfloat(r0.y) * gShadowMatrix[0] + r1;
	r1 = asfloat(r0.w) * gShadowMatrix[2] + r1;
	o.texcoord1.xyz = asfloat(r0.yzw);
	r1 = r1 + gShadowMatrix[3];
	r0 = asint((r0.x != 0) ? r3 : r1);
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	o.texcoord = i.texcoord;

	return o;
}
