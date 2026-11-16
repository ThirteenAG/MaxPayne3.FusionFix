sampler2D HDRSampler : register(s5);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	float4 r0;
	r0 = tex2D(HDRSampler, texcoord.xy);
	o.xyz = min(r0.xyz, 8);
	o.w = 1;

	return o;
}
