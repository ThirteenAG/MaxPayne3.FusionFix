float4 TransPos : register(c131);

float4 main(float4 position : POSITION) : POSITION
{
	float4 o;

	o.xy = position.xy * TransPos.xy + TransPos.zw;
	o.zw = float2(0.1, 1);

	return o;
}
