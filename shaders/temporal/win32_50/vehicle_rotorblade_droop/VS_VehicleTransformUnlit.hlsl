cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
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

	float4 r0;
	float4 r1;
	r0.xy = i.position.xy;
	r0.w = dot(i.position.xy, i.position.xy);
	r1.x = r0.w * droopParams.x;
	r0.w = r0.w * gravityDroop.x;
	r1.x = r1.x * gravityDroop.x;
	r0.z = -(r1.x) * 0.00999999978 + i.position.z;
	r1.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.x = dot(r1.xyz, r1.xyz);
	r0.x = rsqrt(r0.x);
	r1.xyz = r0.xxx * r1.xyz;
	r0.x = dot(r1.xzy, float3(0.707106769, 0.707106769, 0.00000707099707));
	r0.x = r0.x + gravityDroop.y;
	r0.x = r0.x * droopParams.z;
	r0.x = sin(r0.x);
	r0.y = droopParams.y * 0.00999999978;
	r0.y = r0.y * r0.w;
	r0.x = -(r0.y) * r0.x + r0.z;
	r1 = i.position.y * gWorldViewProj[1];
	r1 = i.position.x * gWorldViewProj[0] + r1;
	r0 = r0.x * gWorldViewProj[2] + r1;
	o.sv_position = r0 + gWorldViewProj[3];
	o.texcoord = i.texcoord.xy;
	o.texcoord2 = i.color;

	return o;
}
