cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
	float4 TransColor : packoffset(c130);
	float4 TransPos : packoffset(c131);
};

float4 main(float2 position : POSITION) : SV_Position
{
	float4 o;

	o.xy = position.xy * TransPos.xy + TransPos.zw;
	o.zw = float2(0.100000001, 1);

	return o;
}
