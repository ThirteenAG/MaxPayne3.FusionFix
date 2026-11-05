float4 main(float3 position : POSITION) : SV_Position
{
	float4 o;

	o.xyz = position.xyz;
	o.w = 1;

	return o;
}
