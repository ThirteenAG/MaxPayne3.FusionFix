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

cbuffer InstanceWorld : register(b1)
{
	row_major float4x4 gWorldInstanceMatrix : packoffset(c0);
};

struct VS_IN
{
	float3 position : POSITION;
	float2 texcoord : TEXCOORD;
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

	float4 r0;
	float4 r1;
	float4 r2;
	int2 r3;
	float3 r4;
	r0.xyz = i.position.yyy * gWorldInstanceMatrix[1].xyz;
	r0.xyz = i.position.xxx * gWorldInstanceMatrix[0].xyz + r0.xyz;
	r0.xyz = i.position.zzz * gWorldInstanceMatrix[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + gWorldInstanceMatrix[3].xyz;
	r1.xyz = r0.yyy * gShadowMatrix[1].xyz;
	r1.xyz = r0.xxx * gShadowMatrix[0].xyz + r1.xyz;
	r1.xyz = r0.zzz * gShadowMatrix[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + gShadowMatrix[3].xyz;
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = sqrt(r0.w);
	r1.w = -(r1.z) + r0.w;
	r2.z = r0.w * -(gShadowParam0123.w);
	r2.xy = r1.xy / r1.ww;
	r2.w = r1.z * -(gShadowParam0123.w);
	r1 = r0.y * gShadowMatrix[1];
	r1 = r0.x * gShadowMatrix[0] + r1;
	r1 = r0.z * gShadowMatrix[2] + r1;
	r1 = r1 + gShadowMatrix[3];
	r3 = (gShadowParam14151617.xx == float2(0, 1)) ? -1 : 0;
	r1 = (r3.x != 0) ? r2 : r1;
	r0.w = r1.w * -(gShadowParam0123.w);
	r2.z = (r3.y != 0) ? r0.w : r1.w;
	r4.yz = r1.wz;
	o.sv_position.xyz = r1.xyz;
	r2.x = r4.y;
	r4.x = 1;
	r2.y = r0.z;
	o.texcoord1.xy = r0.xy;
	r0.xyz = (r3.xxx != 0) ? r4.xyz : r2.xyz;
	o.sv_position.w = r0.x;
	o.texcoord1.zw = r0.yz;
	o.texcoord.xy = i.texcoord.xy;
	o.texcoord.zw = float2(0, 0);

	return o;
}
