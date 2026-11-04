float4 TransPos : register(c131);
float4 TransTex0 : register(c132);
float4 TransTex1 : register(c133);
float4 TransTex2 : register(c134);

struct VS_OUT
{
	float4 position : POSITION;
	float2 texcoord : TEXCOORD;
	float2 texcoord1 : TEXCOORD1;
	float2 texcoord2 : TEXCOORD2;
};

VS_OUT main(float4 position : POSITION)
{
	VS_OUT o;

	o.position.xy = position.xy * TransPos.xy + TransPos.zw;
	o.texcoord = position.xy * TransTex0.xy + TransTex0.zw;
	o.texcoord1 = position.xy * TransTex1.xy + TransTex1.zw;
	o.texcoord2 = position.xy * TransTex2.xy + TransTex2.zw;
	o.position.zw = float2(0.1, 1);

	return o;
}
