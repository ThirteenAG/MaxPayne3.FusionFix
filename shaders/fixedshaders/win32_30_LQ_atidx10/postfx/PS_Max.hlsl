sampler2D HDRSampler : register(s5);
float4 TexelSize : register(c88);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	r0.xy = float2(-0.5, 0.5);
	r1 = TexelSize.xyxy * r0.xxxy + texcoord.xyxy;
	r2 = tex2D(HDRSampler, r1.xy);
	r1 = tex2D(HDRSampler, r1.zw);
	r3 = max(r2.xyz, r1.xyz);
	r0 = TexelSize.xyxy * r0.yyyx + texcoord.xyxy;
	r1 = tex2D(HDRSampler, r0.xy);
	r0 = tex2D(HDRSampler, r0.zw);
	r2.xyz = max(r1.xyz, r0.xyz);
	o.xyz = max(r3.xyz, r2.xyz);
	o.w = 1;

	return o;
}
