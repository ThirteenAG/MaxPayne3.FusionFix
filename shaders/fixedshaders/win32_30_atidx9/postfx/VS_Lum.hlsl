float4 main(float4 position : POSITION) : POSITION
{
	float4 o;

	o = position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);

	return o;
}
