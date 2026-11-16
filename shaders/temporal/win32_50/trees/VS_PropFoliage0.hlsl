cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
};

struct VS_IN
{
	float3 position : POSITION;
	float2 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	float2 r0;
	r0 = i.position.yy * gWorldViewProj[1].zw;
	r0 = i.position.xx * gWorldViewProj[0].zw + r0.xy;
	r0 = i.position.zz * gWorldViewProj[2].zw + r0.xy;
	o.sv_position.zw = r0.xy + gWorldViewProj[3].zw;
	o.sv_position.xy = float2(0, 0);
	o.texcoord = i.texcoord.xy;

	return o;
}
