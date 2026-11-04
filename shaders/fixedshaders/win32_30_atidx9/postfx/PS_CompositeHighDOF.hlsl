sampler2D AdapLumSampler : register(s1);
sampler2D BloomSampler : register(s10);
sampler2D BlurSampler : register(s7);
float2 BrightnessSetting : register(c130);
float BurnoutLimit : register(c142);
sampler2D DeathSampler : register(s15);
float2 Exposures : register(c137);
sampler2D HDRPointSampler : register(s6);
sampler2D RadialBlurSampler : register(s14);
float4 ToneMapParams : register(c139);
float blurIntensity : register(c197);
float4 deSatContrastGamma : register(c46);
float4 deSatContrastGammaIFX : register(c75);
float deathIntensity : register(c198);
float radialBlurScale : register(c193);
float2 radialBlurTextureStep : register(c196);

struct PS_IN
{
	float2 texcoord : TEXCOORD;
	float2 texcoord1 : TEXCOORD1;
};

float4 main(PS_IN i) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	r0 = tex2D(HDRPointSampler, i.texcoord.xy);
	r1.x = -1;
	r0.w = r1.x + radialBlurScale.x;
	r1.yz = radialBlurTextureStep.xy + i.texcoord.xy;
	r2 = tex2D(RadialBlurSampler, r1.yz);
	r1.yzw = r0.xyz * radialBlurScale.xxx + r2.xyz;
	r0.xyz = (-abs(r0.www) >= 0) ? r0.xyz : r1.yzw;
	if (blurIntensity.x != -blurIntensity.x) {
		r2 = tex2D(BlurSampler, i.texcoord.xy);
		r1.yzw = lerp(r0.xyz, r2.xyz, blurIntensity.xxx);
		r0.xyz = r1.yzw;
	}
	r2 = tex2D(DeathSampler, i.texcoord1.xy);
	r0.w = abs(deathIntensity.x);
	r1.yz = (-r0.ww >= 0) ? r2.xz : 0;
	r2 = tex2D(AdapLumSampler, 0);
	r0.w = r2.x + 1E-06;
	r0.w = 1 / r0.w;
	r0.w = r0.w * ToneMapParams.y;
	r2 = tex2D(BloomSampler, i.texcoord.xy);
	r2.w = lerp(ToneMapParams.z, ToneMapParams.w, r1.y);
	r2.xyz = r2.www * r2.xyz;
	r0.xyz = r2.xyz * 0.25 + r0.xyz;
	r2.x = lerp(Exposures.x, Exposures.y, r1.y);
	r0.xyz = r0.xyz * r2.xxx;
	r1.y = dot(r0.xyz, float3(0.2125, 0.7154, 0.0721));
	r1.w = r0.w * r1.y;
	r2.x = BurnoutLimit.x * BurnoutLimit.x;
	r2.x = 1 / r2.x;
	r2.x = r1.w * r2.x + 1;
	r1.w = r1.w * r2.x;
	r0.w = r1.y * r0.w + 1;
	r0.w = 1 / r0.w;
	r0.w = r0.w * r1.w;
	r0.xyz = r0.www * r0.xyz;
	r0.w = saturate(dot(r0.xyz, float3(0.2125, 0.7154, 0.0721)));
	r0.w = r0.w + 1.01E-05;
	r2.z = deSatContrastGamma.z;
	r1.y = -r2.z + deSatContrastGammaIFX.z;
	r1.y = r1.z * r1.y + deSatContrastGamma.z;
	r1.y = r1.y + -0.99999;
	r2.x = pow(r0.w, r1.y);
	r0.xyz = r0.xyz * r2.xxx;
	if (deathIntensity.x != -deathIntensity.x) {
		r0.w = -r1.x + -deathIntensity.x;
		r1.x = r0.w * 1.4142135;
		r1.yz = i.texcoord.xy * 2 + -1;
		r2 = tex2D(DeathSampler, i.texcoord.xy);
		r1.x = dot(r1.yz, r1.yz) + -r1.x;
		r0.w = r0.w * -1.4142135 + 1.4142135;
		r0.w = 1 / r0.w;
		r0.w = saturate(r0.w * r1.x);
		r1.xyz = r0.xyz * r2.xyz + -r0.xyz;
		r0.xyz = r0.www * r1.xyz + r0.xyz;
	}
	r0.xyz = r0.xyz * BrightnessSetting.xxx + BrightnessSetting.yyy;
	r1.xyz = saturate(r0.xyz);
	o.w = dot(r1.xyz, float3(0.299, 0.587, 0.114));
	o.xyz = r0.xyz;

	return o;
}
