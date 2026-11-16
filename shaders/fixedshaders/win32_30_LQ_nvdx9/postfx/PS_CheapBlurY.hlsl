sampler2D HDRSampler : register(s5);
float4 TexelSize : register(c88);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	r0.xyz = float3(0, -2.5, -1.5);
	r1 = TexelSize.xyxy * r0.xyxz + texcoord.xyxy;
	r2 = tex2D(HDRSampler, r1.zw);
	r1 = tex2D(HDRSampler, r1.xy);
	r2.xyz = r2.xyz * 0.53;
	r1.xyz = r1.xyz * 0.248 + r2.xyz;
	r2.xy = TexelSize.xy;
	r2 = r2.xyxy * float4(0, -0.5, 0, 0.5) + texcoord.xyxy;
	r3 = tex2D(HDRSampler, r2.xy);
	r2 = tex2D(HDRSampler, r2.zw);
	r1.xyz = r3.xyz * 0.57 + r1.xyz;
	r1.xyz = r2.xyz * 0.57 + r1.xyz;
	r0 = TexelSize.xyxy * abs(r0.xzxy) + texcoord.xyxy;
	r2 = tex2D(HDRSampler, r0.xy);
	r0 = tex2D(HDRSampler, r0.zw);
	r1.xyz = r2.xyz * 0.53 + r1.xyz;
	r0.xyz = r0.xyz * 0.248 + r1.xyz;
	o.xyz = r0.xyz * 0.37091988;
	o.w = 0;

	return o;
}
