sampler2D HDRSampler : register(s5);
float radialBlurSampleScale : register(c195);
float radialBlurScale : register(c193);
float2 radialBlurTextureStep : register(c196);

struct PS_IN
{
	float2 texcoord : TEXCOORD;
	float3 texcoord1 : TEXCOORD1;
};

float4 main(PS_IN i) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	float4 r4;
	r0 = tex2D(HDRSampler, i.texcoord.xy);
	r1.xy = float2(-1, 1);
	r1.xy = r1.xy * radialBlurTextureStep.xy;
	r2.xyz = 1E-05 + i.texcoord1.xyz;
	r0.w = dot(r2.xyz, r2.xyz);
	r0.w = rsqrt(r0.w);
	r1.zw = r0.ww * r2.xy;
	r2.xyz = 0;
	r0.w = 1;
	for (int i0 = 0; i0 < 7; i0++) {
		r2.w = r0.w * 4;
		r3.x = r0.w * 4 + 1E-05;
		r3.x = r3.x * -0.0739854;
		r3.x = exp2(r3.x);
		r3.yz = r1.zw * r2.ww;
		r3.yz = r3.yz * r1.xy + i.texcoord.xy;
		r4 = tex2D(HDRSampler, r3.yz);
		r2.xyz = r3.xxx * r4.xyz + r2.xyz;
		r0.w = r0.w + 1;
	}
	r0.xyz = radialBlurSampleScale.xxx * r0.xyz + r2.xyz;
	o.xyz = r0.xyz * radialBlurScale.xxx;
	o.w = 1;

	return o;
}
