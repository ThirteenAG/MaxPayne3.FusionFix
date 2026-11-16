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
	r0.zw = TexelSize.yy * float2(-3.20000005, 3.20000005) + r0.yy;
	o.texcoord = r0.xyxz;
	o.texcoord3 = r0.xwxy;
	o.texcoord1 = TexelSize.xyxy * float4(0, -2.5, 0, -1.5) + r0.xyxy;
	o.texcoord2 = TexelSize.xyxy * float4(0, 1.5, 0, 2.5) + r0.xyxy;

	return o;
}
