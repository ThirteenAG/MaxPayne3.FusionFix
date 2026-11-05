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

cbuffer vehicle_instance : register(b7)
{
	row_major float4x4 matWheelTransform : packoffset(c0);
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
	r0.xyz = asint(i.position.yyy * matWheelTransform[1].xyz);
	r0.xyz = asint(i.position.xxx * matWheelTransform[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.position.zzz * matWheelTransform[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + matWheelTransform[3].xyz);
	r1 = asfloat(r0.y) * gWorldViewProj[1];
	r1 = asfloat(r0.x) * gWorldViewProj[0] + r1;
	r1 = asfloat(r0.z) * gWorldViewProj[2] + r1;
	r1 = r1 + gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord = i.texcoord.xy;
	r1.xyz = i.normal.yyy * matWheelTransform[1].xyz;
	r1.xyz = i.normal.xxx * matWheelTransform[0].xyz + r1.xyz;
	r1.xyz = i.normal.zzz * matWheelTransform[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = asint(dot(r1.xyz, r1.xyz));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r1.xyz = asfloat(r0.www) * r1.xyz;
	o.texcoord1 = r1;
	o.texcoord2 = asfloat(r0.xyz);
	r2 = asfloat(r0.xyz) + gWorld[3].xyz;
	o.texcoord3 = -(r2.xyz) + gViewInverse[3].xyz;
	r2 = i.tangent.yyy * matWheelTransform[1].xyz;
	r2 = i.tangent.xxx * matWheelTransform[0].xyz + r2.xyz;
	r2 = i.tangent.zzz * matWheelTransform[2].xyz + r2.xyz;
	r2 = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = asint(dot(r2.xyz, r2.xyz));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r2 = asfloat(r0.www) * r2.xyz;
	o.texcoord4 = r2.xyz;
	r3 = r1.yzx * r2.zxy;
	r1.xyz = r2.yzx * r1.zxy + -(r3.xyz);
	o.texcoord5.xyz = r1.xyz * i.tangent.www;
	o.texcoord5.w = i.tangent.w;
	o.texcoord6.xyz = i.color.xyz;
	o.texcoord6.w = 1;
	r1.xyz = asfloat(r0.yyy) * gWorld[1].xyz;
	r0.xyw = asint(asfloat(r0.xxx) * gWorld[0].xyz + r1.xyz);
	r0.xyz = asint(asfloat(r0.zzz) * gWorld[2].xyz + asfloat(r0.xyw));
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
