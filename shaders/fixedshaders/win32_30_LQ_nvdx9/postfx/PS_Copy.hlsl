sampler2D HDRPointSampler : register(s6);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	o = tex2D(HDRPointSampler, texcoord.xy);

	return o;
}
