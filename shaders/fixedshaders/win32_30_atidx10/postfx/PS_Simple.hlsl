sampler2D AdapLumSampler : register(s1);
float2 BrightnessSetting : register(c135);
float2 Exposures : register(c142);
sampler2D HDRSampler : register(s5);
float4 ToneMapParams : register(c144);
float4 deSatContrastGamma : register(c46);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float r2;
	r0 = tex2D(AdapLumSampler, 0);
	r0.x = 1 / r0.x;
	r0.x = r0.x * ToneMapParams.y;
	r1 = tex2D(HDRSampler, texcoord.xy);
	r0.yzw = r1.xyz * Exposures.xxx;
	r0.xyz = r0.xxx * r0.yzw;
	r0.w = saturate(dot(r0.xyz, float3(0.2125, 0.7154, 0.0721)));
	r0.w = r0.w + 1.01E-05;
	r1.y = -0.99999;
	r1.x = r1.y + deSatContrastGamma.z;
	r2 = pow(r0.w, r1.x);
	r0.w = min(r2.x, 65000);
	r0.xyz = r0.www * r0.xyz;
	r0.xyz = r0.xyz * BrightnessSetting.xxx + BrightnessSetting.yyy;
	r1.xyz = saturate(r0.xyz);
	o.xyz = r0.xyz;
	o.w = dot(r1.xyz, 0.299);

	return o;
}
