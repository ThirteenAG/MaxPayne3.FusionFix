sampler2D AdapLumSampler : register(s1);
sampler2D BloomSampler : register(s10);
sampler2D BlurSampler : register(s7);
float2 BrightnessSetting : register(c135);
float BurnoutLimit : register(c147);
float4 ColorCorrectBottomOffset : register(c44);
float4 ColorCorrectTopAndPedReflectScale : register(c43);
float2 Exposures : register(c142);
sampler2D HDRPointSampler : register(s6);
sampler2D RadialBlurSampler : register(s14);
float4 ToneMapParams : register(c144);
float blurIntensity : register(c203);
float4 deSatContrastGamma : register(c46);
float radialBlurScale : register(c199);
float2 radialBlurTextureStep : register(c202);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float3 r2;
	r0 = tex2D(HDRPointSampler, texcoord.xy);
	r1.x = -1;
	r0.w = r1.x + radialBlurScale.x;
	r1.xy = radialBlurTextureStep.xy + texcoord.xy;
	r1 = tex2D(RadialBlurSampler, r1.xy);
	r1.xyz = r0.xyz * radialBlurScale.xxx + r1.xyz;
	r0.xyz = (-abs(r0.www) >= 0) ? r0.xyz : r1.xyz;
	if (blurIntensity.x != -blurIntensity.x) {
		r1 = tex2D(BlurSampler, texcoord.xy);
		r2 = lerp(r0.xyz, r1.xyz, blurIntensity.xxx);
		r0.xyz = r2.xyz;
	}
	r1 = tex2D(AdapLumSampler, 0);
	r0.w = r1.x + 1E-06;
	r0.w = 1 / r0.w;
	r0.w = r0.w * ToneMapParams.y;
	r1 = tex2D(BloomSampler, texcoord.xy);
	r1.xyz = r1.xyz * ToneMapParams.zzz;
	r0.xyz = r1.xyz * 0.25 + r0.xyz;
	r1.xyz = ColorCorrectBottomOffset.xyz;
	r1.xyz = texcoord.yyy * r1.xyz + ColorCorrectTopAndPedReflectScale.xyz;
	r0.xyz = r0.xyz * r1.xyz;
	r0.xyz = r0.xyz * Exposures.xxx;
	r1.x = dot(r0.xyz, float3(0.2125, 0.7154, 0.0721));
	r1.y = r0.w * r1.x;
	r1.z = BurnoutLimit.x * BurnoutLimit.x;
	r1.z = 1 / r1.z;
	r1.z = r1.y * r1.z + 1;
	r1.y = r1.z * r1.y;
	r0.w = r1.x * r0.w + 1;
	r0.w = 1 / r0.w;
	r0.w = r0.w * r1.y;
	r0.xyz = r0.www * r0.xyz;
	r0.w = saturate(dot(r0.xyz, float3(0.2125, 0.7154, 0.0721)));
	r0.w = r0.w + 1.01E-05;
	r1.x = -0.99999;
	r1.x = r1.x + deSatContrastGamma.z;
	r2.x = pow(r0.w, r1.x);
	r0.w = min(r2.x, 65000);
	r0.xyz = r0.www * r0.xyz;
	r0.xyz = r0.xyz * BrightnessSetting.xxx + BrightnessSetting.yyy;
	r1.xyz = saturate(r0.xyz);
	o.w = dot(r1.xyz, float3(0.299, 0.587, 0.114));
	o.xyz = r0.xyz;

	return o;
}
