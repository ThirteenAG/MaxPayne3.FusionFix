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

cbuffer vehicle_instance : register(b7)
{
	row_major float4x4 matWheelTransform : packoffset(c0);
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord1 : TEXCOORD1;
};

VS_OUT main(float3 position : POSITION)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	int4 r2;
	float4 r3;
	float3 r4;
	r0.xyz = position.yyy * matWheelTransform[1].xyz;
	r0.xyz = position.xxx * matWheelTransform[0].xyz + r0.xyz;
	r0.xyz = position.zzz * matWheelTransform[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + matWheelTransform[3].xyz;
	r1.xyz = r0.yyy * gWorld[1].xyz;
	r0.xyw = r0.xxx * gWorld[0].xyz + r1.xyz;
	r0.xyz = r0.zzz * gWorld[2].xyz + r0.xyw;
	r0.xyz = r0.xyz + gWorld[3].xyz;
	r1 = r0.y * gShadowMatrix[1];
	r1 = r0.x * gShadowMatrix[0] + r1;
	r1 = r0.z * gShadowMatrix[2] + r1;
	r1 = r1 + gShadowMatrix[3];
	r2.xyz = asint(r0.yyy * gShadowMatrix[1].xyz);
	r2.xyz = asint(r0.xxx * gShadowMatrix[0].xyz + asfloat(r2.xyz));
	r2.xyz = asint(r0.zzz * gShadowMatrix[2].xyz + asfloat(r2.xyz));
	r2.xyz = asint(asfloat(r2.xyz) + gShadowMatrix[3].xyz);
	r0.w = dot(asfloat(r2.xyz), asfloat(r2.xyz));
	r0.w = sqrt(r0.w);
	r2.w = asint(-(asfloat(r2.z)) + r0.w);
	r3.z = r0.w * -(gShadowParam0123.w);
	r3.xy = asfloat(r2.xy) / asfloat(r2.ww);
	r3.w = asfloat(r2.z) * -(gShadowParam0123.w);
	r2.xy = (gShadowParam14151617.xx == float2(0, 1)) ? -1 : 0;
	r1 = (r2.x != 0) ? r3 : r1;
	r0.w = r1.w * -(gShadowParam0123.w);
	r3.z = (r2.y != 0) ? r0.w : r1.w;
	r4.yz = r1.wz;
	o.sv_position.xyz = r1.xyz;
	r3.x = r4.y;
	r4.x = 1;
	r3.y = r0.z;
	o.texcoord1.xy = r0.xy;
	r0.xyz = (r2.xxx != 0) ? r4.xyz : r3.xyz;
	o.sv_position.w = r0.x;
	o.texcoord1.zw = r0.yz;

	return o;
}
