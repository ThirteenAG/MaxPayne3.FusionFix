cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
	float4 TransColor : packoffset(c130);
	float4 TransPos : packoffset(c131);
	float4 TransTex0 : packoffset(c132);
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
};

VS_OUT main(float2 position : POSITION)
{
	VS_OUT o;

	float4 r0;
	o.sv_position.xy = position.xy * TransPos.xy + TransPos.zw;
	o.sv_position.zw = float2(0.100000001, 1);
	r0.xy = position.xy * TransTex0.xy + TransTex0.zw;
	r0.w = TexelSize.y * -3.5 + r0.y;
	o.texcoord = r0.xyxw;
	o.texcoord1.xy = TexelSize.xy * float2(0, -2.5) + r0.xy;
	o.texcoord1.zw = TexelSize.xy * float2(0, -1.5) + r0.xy;
	o.texcoord2.xy = TexelSize.xy * float2(0, 1.5) + r0.xy;
	o.texcoord2.zw = TexelSize.xy * float2(0, 2.5) + r0.xy;
	o.texcoord3.y = TexelSize.y * 3.5 + r0.y;
	o.texcoord3.xzw = r0.xxy;

	return o;
}
