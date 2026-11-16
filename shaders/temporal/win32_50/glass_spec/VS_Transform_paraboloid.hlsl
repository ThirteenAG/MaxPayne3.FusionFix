cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float r1;
	r0.xyz = i.position.yyy * gWorldView[1].xyz;
	r0.xyz = i.position.xxx * gWorldView[0].xyz + r0.xyz;
	r0.xyz = i.position.zzz * gWorldView[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + gWorldView[3].xyz;
	r1 = r0.z + 512;
	r0.w = r0.z + 512;
	r0.z = dot(r0.xyw, r0.xyw);
	r0.z = sqrt(r0.z);
	r0.w = r1.x / r0.z;
	r0.w = -(r0.w) + 1;
	r0.w = r0.w * r0.z;
	r0.w = 1 / r0.w;
	o.sv_position.xy = r0.ww * r0.xy;
	o.sv_position.w = 1;
	r0.x = r0.z + 1;
	o.texcoord1.w = r0.z;
	r0.x = 1 / r0.x;
	o.sv_position.z = -(r0.x) + 1;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * gWorld[1].xyz;
	r0.xyz = i.normal.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	o.texcoord1.xyz = r0.www * r0.xyz;
	r0.xyz = i.position.yyy * gWorld[1].xyz;
	r0.xyz = i.position.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.position.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + gWorld[3].xyz;
	o.texcoord3 = -(r0.xyz) + gViewInverse[3].xyz;

	return o;
}
