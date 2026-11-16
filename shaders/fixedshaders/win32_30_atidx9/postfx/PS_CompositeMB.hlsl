sampler2D AdapLumSampler : register(s1);
sampler2D BloomSampler : register(s10);
sampler2D BlurSampler : register(s7);
float2 BrightnessSetting : register(c130);
float BurnoutLimit : register(c142);
sampler2D DOFSampler : register(s9);
sampler2D DeathSampler : register(s15);
float DirectionalMotionBlurLength : register(c149);
float2 Exposures : register(c137);
sampler2D GBufferTextureSamplerDepth : register(s3);
sampler2D HDRPointSampler : register(s6);
sampler2D RadialBlurSampler : register(s14);
sampler2D StencilCopySampler : register(s8);
float4 ToneMapParams : register(c139);
float blurIntensity : register(c197);
float4 deSatContrastGamma : register(c46);
float4 deSatContrastGammaIFX : register(c75);
float deathIntensity : register(c198);
float4 dofProj : register(c132);
float4 globalScreenSize : register(c41);
row_major float4x4 motionBlurMatrix : register(c150);
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
	float4 r4;
	float4 r5;
	r0 = tex2D(GBufferTextureSamplerDepth, i.texcoord.xy);
	r0.y = -dofProj.x + dofProj.y;
	r0.y = 1 / r0.y;
	r0.z = r0.y * dofProj.y;
	r0.z = r0.z * -dofProj.x;
	r0.x = dofProj.y * -r0.y + r0.x;
	r0.x = 1 / r0.x;
	r0.x = r0.x * r0.z;
	r1 = tex2D(HDRPointSampler, i.texcoord.xy);
	r2.x = -1;
	r0.y = r2.x + radialBlurScale.x;
	r0.zw = radialBlurTextureStep.xy + i.texcoord.xy;
	r3 = tex2D(RadialBlurSampler, r0.zw);
	r2.yzw = r1.xyz * radialBlurScale.xxx + r3.xyz;
	r0.yzw = (-abs(r0.yyy) >= 0) ? r1.xyz : r2.yzw;
	if (blurIntensity.x != -blurIntensity.x) {
		r1 = tex2D(BlurSampler, i.texcoord.xy);
		r2.yzw = lerp(r0.yzw, r1.xyz, blurIntensity.xxx);
		r0.yzw = r2.yzw;
	}
	r1 = tex2D(DeathSampler, i.texcoord1.xy);
	r1.y = abs(deathIntensity.x);
	r1.xy = (-r1.yy >= 0) ? r1.xz : 0;
	r1.zw = i.texcoord.xy * 2 + -1;
	r2.y = r1.z * dofProj.z;
	r2.z = -r1.w * dofProj.w;
	r2.yz = r0.xx * r2.yz;
	r3.xyz = r2.zzz * motionBlurMatrix[1].xyz;
	r2.yzw = r2.yyy * motionBlurMatrix[0].xyz + r3.xyz;
	r2.yzw = -r0.xxx * motionBlurMatrix[2].xyz + r2.yzw;
	r2.yzw = r2.yzw + motionBlurMatrix[3].xyz;
	r0.x = -r2.w * dofProj.z;
	r0.x = 1 / r0.x;
	r3.x = r0.x * r2.y;
	r0.x = r2.w * dofProj.w;
	r0.x = 1 / r0.x;
	r3.y = r0.x * r2.z;
	r2.yz = -r1.zw + r3.xy;
	r2.yz = r2.yz * DirectionalMotionBlurLength.xx;
	r3.xy = r2.yz * 0.16666667;
	r4 = tex2D(StencilCopySampler, i.texcoord.xy);
	r0.x = -r4.w + 0.5015686;
	r4.xyz = r0.yzw;
	r2.w = 1;
	for (int i0 = 0; i0 < 5; i0++) {
		r3.zw = r3.xy * r2.ww + i.texcoord.xy;
		r5 = tex2D(DOFSampler, r3.zw);
		r4.xyz = r4.xyz + r5.xyz;
		r2.w = r2.w + 1;
	}
	r2.yz = r2.yz * globalScreenSize.xy;
	r2.y = dot(r2.yz, r2.yz) + 0;
	r2.y = rsqrt(r2.y);
	r2.y = 1 / r2.y;
	r2.y = saturate(r2.y * 0.5);
	// Normalize the center sample plus five motion-blur samples.
	r3.xyz = r4.xyz * 0.166666667 + -r0.yzw;
	r2.yzw = r2.yyy * r3.xyz;
	r2.yzw = (r0.xxx >= 0) ? r2.yzw : 0;
	r0.xyz = r0.yzw + r2.yzw;
	r3 = tex2D(AdapLumSampler, 0);
	r0.w = r3.x + 1E-06;
	r0.w = 1 / r0.w;
	r0.w = r0.w * ToneMapParams.y;
	r3 = tex2D(BloomSampler, i.texcoord.xy);
	r2.y = lerp(ToneMapParams.z, ToneMapParams.w, r1.x);
	r2.yzw = r2.yyy * r3.xyz;
	r0.xyz = r2.yzw * 0.25 + r0.xyz;
	r2.y = lerp(Exposures.x, Exposures.y, r1.x);
	r0.xyz = r0.xyz * r2.yyy;
	r1.x = dot(r0.xyz, float3(0.2125, 0.7154, 0.0721));
	r2.y = r0.w * r1.x;
	r2.z = BurnoutLimit.x * BurnoutLimit.x;
	r2.z = 1 / r2.z;
	r2.z = r2.y * r2.z + 1;
	r2.y = r2.z * r2.y;
	r0.w = r1.x * r0.w + 1;
	r0.w = 1 / r0.w;
	r0.w = r0.w * r2.y;
	r0.xyz = r0.www * r0.xyz;
	r0.w = saturate(dot(r0.xyz, float3(0.2125, 0.7154, 0.0721)));
	r0.w = r0.w + 1.01E-05;
	r2.z = deSatContrastGamma.z;
	r1.x = -r2.z + deSatContrastGammaIFX.z;
	r1.x = r1.y * r1.x + deSatContrastGamma.z;
	r1.x = r1.x + -0.99999;
	r2.y = pow(r0.w, r1.x);
	r0.xyz = r0.xyz * r2.yyy;
	if (deathIntensity.x != -deathIntensity.x) {
		r0.w = -r2.x + -deathIntensity.x;
		r1.x = r0.w * 1.4142135;
		r2 = tex2D(DeathSampler, i.texcoord.xy);
		r1.x = dot(r1.zw, r1.zw) + -r1.x;
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
