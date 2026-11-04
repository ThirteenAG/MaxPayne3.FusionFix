sampler2D AdapLumSampler : register(s1);
sampler2D BloomSampler : register(s10);
sampler2D BlurSampler : register(s7);
float2 BrightnessSetting : register(c130);
float BurnoutLimit : register(c142);
float4 ColorFringeParams1 : register(c182);
float4 ColorFringeParams2 : register(c183);
sampler2D DeathSampler : register(s15);
float2 Exposures : register(c137);
sampler2D HDRPointSampler : register(s6);
float4 NoiseParams : register(c143);
sampler2D RadialBlurSampler : register(s14);
float4 ToneMapParams : register(c139);
float blurIntensity : register(c197);
float4 deSatContrastGamma : register(c46);
float4 deSatContrastGammaIFX : register(c75);
float deathIntensity : register(c198);
float4 globalScreenSize : register(c41);
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
	float4 r3;
	float3 r4;
	r0 = tex2D(HDRPointSampler, i.texcoord.xy);
	r1.xz = float2(-1, 1);
	r0.w = r1.x + radialBlurScale.x;
	r1.xy = radialBlurTextureStep.xy + i.texcoord.xy;
	r2 = tex2D(RadialBlurSampler, r1.xy);
	r1.xyw = r0.xyz * radialBlurScale.xxx + r2.xyz;
	r0.xyz = (-abs(r0.www) >= 0) ? r0.xyz : r1.xyw;
	if (blurIntensity.x != -blurIntensity.x) {
		r2 = tex2D(BlurSampler, i.texcoord.xy);
		r1.xyw = lerp(r0.xyz, r2.xyz, blurIntensity.xxx);
		r0.xyz = r1.xyw;
	}
	r2 = tex2D(DeathSampler, i.texcoord1.xy);
	r0.w = abs(deathIntensity.x);
	r1.xyw = (-r0.www >= 0) ? r2.xzw : 0;
	r0.w = 1 / globalScreenSize.x;
	r2.xy = ColorFringeParams1.ww * -r0.ww + i.texcoord.xy;
	r0.w = -r1.w + 1;
	r3.xyz = r0.www * ColorFringeParams1.xyz;
	r2 = tex2D(HDRPointSampler, r2.xy);
	r4 = lerp(r0.xyz, r2.xyz, r3.xyz);
	r1.w = ColorFringeParams2.w;
	r2.xy = r1.ww * -globalScreenSize.zz + i.texcoord.xy;
	r3.xyz = r0.www * ColorFringeParams2.xyz;
	r2 = tex2D(HDRPointSampler, r2.xy);
	r0.xyz = -r0.xyz + r2.xyz;
	r0.xyz = r0.xyz * r3.xyz + r4.xyz;
	r2.xy = float2(3.2, 1.8);
	r2.xy = i.texcoord.xy * r2.xy + NoiseParams.xy;
	r2.xy = frac(r2.xy);
	r2 = tex2D(BlurSampler, r2.xy);
	r0.w = r2.z + -0.5;
	r0.xyz = r0.www * NoiseParams.zzz + r0.xyz;
	r2.xyz = max(r0.xyz, 0);
	r0 = tex2D(AdapLumSampler, 0);
	r0.x = r0.x + 1E-06;
	r0.x = 1 / r0.x;
	r0.x = r0.x * ToneMapParams.y;
	r3 = tex2D(BloomSampler, i.texcoord.xy);
	r0.y = lerp(ToneMapParams.z, ToneMapParams.w, r1.x);
	r0.yzw = r0.yyy * r3.xyz;
	r0.yzw = r0.yzw * 0.25 + r2.xyz;
	r2.x = lerp(Exposures.x, Exposures.y, r1.x);
	r0.yzw = r0.yzw * r2.xxx;
	r1.x = dot(r0.yzw, float3(0.2125, 0.7154, 0.0721));
	r1.w = r0.x * r1.x;
	r2.x = BurnoutLimit.x * BurnoutLimit.x;
	r2.x = 1 / r2.x;
	r2.x = r1.w * r2.x + 1;
	r1.w = r1.w * r2.x;
	r0.x = r1.x * r0.x + 1;
	r0.x = 1 / r0.x;
	r0.x = r0.x * r1.w;
	r0.xyz = r0.xxx * r0.yzw;
	r0.w = saturate(dot(r0.xyz, float3(0.2125, 0.7154, 0.0721)));
	r0.w = r0.w + 1.01E-05;
	r2.z = deSatContrastGamma.z;
	r1.x = -r2.z + deSatContrastGammaIFX.z;
	r1.x = r1.y * r1.x + deSatContrastGamma.z;
	r1.x = r1.x + -0.99999;
	r2.x = pow(r0.w, r1.x);
	r0.xyz = r0.xyz * r2.xxx;
	if (deathIntensity.x != -deathIntensity.x) {
		r0.w = r1.z + -deathIntensity.x;
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
