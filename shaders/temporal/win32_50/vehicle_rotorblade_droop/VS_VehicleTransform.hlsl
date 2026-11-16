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

cbuffer Droop : register(b4)
{
	float3 droopParams : packoffset(c0);
	float2 gravityDroop : packoffset(c1);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
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
	float4 r1;
	float3 r2;
	float3 r3;
	r0.xy = asint(i.position.xy);
	r0.w = asint(dot(i.position.xy, i.position.xy));
	r1.x = asfloat(r0.w) * droopParams.x;
	r0.w = asint(asfloat(r0.w) * gravityDroop.x);
	r1.x = r1.x * gravityDroop.x;
	r0.z = asint(-(r1.x) * 0.00999999978 + i.position.z);
	r1.xyz = asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = asint(dot(r1.xyz, r1.xyz));
	r0.x = asint(rsqrt(asfloat(r0.x)));
	r1.xyz = asfloat(r0.xxx) * r1.xyz;
	r0.x = asint(dot(r1.xzy, float3(0.707106769, 0.707106769, 0.00000707099707)));
	r0.x = asint(asfloat(r0.x) + gravityDroop.y);
	r0.x = asint(asfloat(r0.x) * droopParams.z);
	r0.x = asint(sin(asfloat(r0.x)));
	r0.y = asint(droopParams.y * 0.00999999978);
	r0.y = asint(asfloat(r0.y) * asfloat(r0.w));
	r0.x = asint(-(asfloat(r0.y)) * asfloat(r0.x) + asfloat(r0.z));
	r1 = i.position.y * gWorldViewProj[1];
	r1 = i.position.x * gWorldViewProj[0] + r1;
	r1 = asfloat(r0.x) * gWorldViewProj[2] + r1;
	r1 = r1 + gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord = i.texcoord.xy;
	r0.yzw = asint(i.normal.yyy * gWorld[1].xyz);
	r0.yzw = asint(i.normal.xxx * gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(i.normal.zzz * gWorld[2].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r0.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.x = dot(asfloat(r0.yzw), asfloat(r0.yzw));
	r1.x = rsqrt(r1.x);
	r0.yzw = asint(asfloat(r0.yzw) * r1.xxx);
	o.texcoord1.xyz = asfloat(r0.yzw);
	r1.xyz = i.position.yyy * gWorld[1].xyz;
	r1.xyz = i.position.xxx * gWorld[0].xyz + r1.xyz;
	r1.xyz = asfloat(r0.xxx) * gWorld[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + gWorld[3].xyz;
	o.texcoord2 = r1.xyz;
	r2 = r1.xyz + gWorld[3].xyz;
	o.texcoord3 = -(r2.xyz) + gViewInverse[3].xyz;
	r2 = i.tangent.yyy * gWorld[1].xyz;
	r2 = i.tangent.xxx * gWorld[0].xyz + r2.xyz;
	r2 = i.tangent.zzz * gWorld[2].xyz + r2.xyz;
	r2 = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = asint(dot(r2.xyz, r2.xyz));
	r0.x = asint(rsqrt(asfloat(r0.x)));
	r2 = asfloat(r0.xxx) * r2.xyz;
	o.texcoord4 = r2.xyz;
	r3 = asfloat(r0.zwy) * r2.zxy;
	r0.xyz = asint(r2.yzx * asfloat(r0.wyz) + -(r3.xyz));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
	o.texcoord5.w = i.tangent.w;
	o.texcoord6.xyz = i.color.xyz;
	o.texcoord6.w = 1;
	r1.w = 1;
	r0.x = asint(dot(r1, g_vUserClipPlanes[0]));
	r0.y = asint(g_vUserClipPlanes[0].y + g_vUserClipPlanes[0].x);
	r0.y = asint(asfloat(r0.y) + g_vUserClipPlanes[0].z);
	r0.y = asint(asfloat(r0.y) + g_vUserClipPlanes[0].w);
	r0.y = (asfloat(r0.y) != 0) ? -1 : 0;
	o.sv_clipdistance = (r0.y != 0) ? asfloat(r0.x) : 1;

	return o;
}
