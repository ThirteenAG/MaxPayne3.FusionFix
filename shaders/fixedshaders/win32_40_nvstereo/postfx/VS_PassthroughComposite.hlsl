cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
	float4 TransColor : packoffset(c130);
	float4 TransPos : packoffset(c131);
	float4 TransTex0 : packoffset(c132);
	float4 TransTex1 : packoffset(c133);
	float4 TransTex2 : packoffset(c134);
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord1 : TEXCOORD1;
	float2 texcoord2 : TEXCOORD2;
};

VS_OUT main(float2 position : POSITION)
{
	VS_OUT o;

	o.sv_position.xy = position.xy * TransPos.xy + TransPos.zw;
	o.sv_position.zw = float2(0.100000001, 1);
	o.texcoord = position.xy * TransTex0.xy + TransTex0.zw;
	o.texcoord1 = position.xy * TransTex1.xy + TransTex1.zw;
	o.texcoord2 = position.xy * TransTex2.xy + TransTex2.zw;

	return o;
}
