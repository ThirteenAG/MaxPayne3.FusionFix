sampler2D AdapLumSampler : register(s1);
sampler2D BloomSampler : register(s10);
sampler2D BlurSampler : register(s7);
float2 BrightnessSetting : register(c135);
float BurnoutLimit : register(c147);
float4 ColorCorrectBottomOffset : register(c44);
float4 ColorCorrectTopAndPedReflectScale : register(c43);
float4 ColorFringeParams1 : register(c189);
float4 ColorFringeParams2 : register(c190);
sampler2D DeathSampler : register(s15);
float2 Exposures : register(c142);
sampler2D HDRPointSampler : register(s6);
sampler2D RadialBlurSampler : register(s14);
float4 ToneMapParams : register(c144);
float blurIntensity : register(c203);
float4 deSatContrastGamma : register(c46);
float4 deSatContrastGammaIFX : register(c75);
float4 globalScreenSize : register(c41);
float radialBlurScale : register(c199);
float2 radialBlurTextureStep : register(c202);

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
	r1.x = -1;
	r0.w = r1.x + radialBlurScale.x;
	r1.xy = radialBlurTextureStep.xy + i.texcoord.xy;
	r1 = tex2D(RadialBlurSampler, r1.xy);
	r1.xyz = r0.xyz * radialBlurScale.xxx + r1.xyz;
	r0.xyz = (-abs(r0.www) >= 0) ? r0.xyz : r1.xyz;
	if (blurIntensity.x != -blurIntensity.x) {
		r1 = tex2D(BlurSampler, i.texcoord.xy);
		r2.xyz = lerp(r0.xyz, r1.xyz, blurIntensity.xxx);
		r0.xyz = r2.xyz;
	}
	r1 = tex2D(DeathSampler, i.texcoord1.xy);
	r0.w = 1 / globalScreenSize.x;
	r2.xy = ColorFringeParams1.ww * -r0.ww + i.texcoord.xy;
	r0.w = -r1.w + 1;
	r3.xyz = r0.www * ColorFringeParams1.xyz;
	r2 = tex2D(HDRPointSampler, r2.xy);
	r4 = lerp(r0.xyz, r2.xyz, r3.xyz);
	r1.w = ColorFringeParams2.w;
	r1.yw = r1.ww * -globalScreenSize.zz + i.texcoord.xy;
	r2.xyz = r0.www * ColorFringeParams2.xyz;
	r3 = tex2D(HDRPointSampler, r1.yw);
	r0.xyz = -r0.xyz + r3.xyz;
	r0.xyz = r0.xyz * r2.xyz + r4.xyz;
	r2 = tex2D(AdapLumSampler, 0);
	r0.w = r2.x + 1E-06;
	r0.w = 1 / r0.w;
	r0.w = r0.w * ToneMapParams.y;
	r2 = tex2D(BloomSampler, i.texcoord.xy);
	r2.w = lerp(ToneMapParams.z, ToneMapParams.w, r1.x);
	r2.xyz = r2.www * r2.xyz;
	r0.xyz = r2.xyz * 0.25 + r0.xyz;
	r2.xyz = ColorCorrectBottomOffset.xyz;
	r2.xyz = i.texcoord.yyy * r2.xyz + ColorCorrectTopAndPedReflectScale.xyz;
	r0.xyz = r0.xyz * r2.xyz;
	r2.x = lerp(Exposures.x, Exposures.y, r1.x);
	r0.xyz = r0.xyz * r2.xxx;
	r1.x = dot(r0.xyz, float3(0.2125, 0.7154, 0.0721));
	r1.y = r0.w * r1.x;
	r1.w = BurnoutLimit.x * BurnoutLimit.x;
	r1.w = 1 / r1.w;
	r1.w = r1.y * r1.w + 1;
	r1.y = r1.w * r1.y;
	r0.w = r1.x * r0.w + 1;
	r0.w = 1 / r0.w;
	r0.w = r0.w * r1.y;
	r0.xyz = r0.www * r0.xyz;
	r0.w = saturate(dot(r0.xyz, float3(0.2125, 0.7154, 0.0721)));
	r0.w = r0.w + 1.01E-05;
	r2.z = deSatContrastGamma.z;
	r1.x = -r2.z + deSatContrastGammaIFX.z;
	r1.x = r1.z * r1.x + deSatContrastGamma.z;
	r1.x = r1.x + -0.99999;
	r2.x = pow(r0.w, r1.x);
	r0.w = min(r2.x, 65000);
	r0.xyz = r0.www * r0.xyz;
	r0.xyz = r0.xyz * BrightnessSetting.xxx + BrightnessSetting.yyy;
	r1.xyz = saturate(r0.xyz);
	o.w = dot(r1.xyz, float3(0.299, 0.587, 0.114));
	o.xyz = r0.xyz;

	return o;
}
