cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
	float4 TransColor : packoffset(c130);
	float4 TransPos : packoffset(c131);
	float4 TransTex0 : packoffset(c132);
	float4 TransTex1 : packoffset(c133);
	float4 TransTex2 : packoffset(c134);
	float2 BrightnessSetting : packoffset(c135);
	float4 dofProj : packoffset(c136);
	float4 dofDist : packoffset(c137);
	float dofInten : packoffset(c138);
	float4 dofBlur : packoffset(c139);
	float dofNoBlurRadius : packoffset(c140);
	float dofNoBlurBlendRingSize : packoffset(c141);
	float2 Exposures : packoffset(c142);
	float4 SharpenFilterParams : packoffset(c143);
	float4 ToneMapParams : packoffset(c144);
	float AdaptedLumMin : packoffset(c145);
	float AdaptedLumMax : packoffset(c146);
	float BurnoutLimit : packoffset(c147);
	float4 NoiseParams : packoffset(c148);
	float4 NoiseFilterArea : packoffset(c149);
	float4 KillFlashUVOff : packoffset(c150);
	float4 KillFlashCol : packoffset(c151);
	float4 InterlaceMask : packoffset(c152);
	float4 ImageFXParams : packoffset(c153);
	float ZoomBlurMaskSize : packoffset(c154);
	float ChromaticEntire : packoffset(c155);
	float DirectionalMotionBlurLength : packoffset(c156);
	row_major float4x4 motionBlurMatrix : packoffset(c157);
	float MaskTex : packoffset(c161);
	float4 MP_BulletTimeParams : packoffset(c162);
	float4 TearGasParams : packoffset(c163);
	float ElapsedTime : packoffset(c164);
	float AdaptTime : packoffset(c165);
};

SamplerState CurLumSampler : register(s0);
SamplerState AdapLumSampler : register(s1);
Texture2D CurLumSampler_tex : register(t0);
Texture2D AdapLumSampler_tex : register(t1);

float4 main(float4 sv_position : SV_Position) : SV_Target
{
	float4 o;

	int4 r0;
	float4 r1;
	r0 = asint(CurLumSampler_tex.Sample(CurLumSampler, float2(0, 0)));
	r0.y = (AdaptTime >= 1) ? -1 : 0;
	if (r0.y != 0) {
		r1 = AdapLumSampler_tex.Sample(AdapLumSampler, float2(0, 0));
		r0.y = asint(asfloat(r0.x) + -(r1.x));
		r0.z = asint(AdaptTime + AdaptTime);
		r0.z = asint(sqrt(asfloat(r0.z)));
		r0.z = asint(ElapsedTime / asfloat(r0.z));
		r0.z = asint(min(asfloat(r0.z), 1));
		r0.y = asint(asfloat(r0.y) * asfloat(r0.z) + r1.x);
		r0.y = asint(max(asfloat(r0.y), AdaptedLumMin));
		o = min(asfloat(r0.y), AdaptedLumMax);
		return o;
	} else {
		r0.x = asint(max(asfloat(r0.x), AdaptedLumMin));
		o = min(asfloat(r0.x), AdaptedLumMax);
		return o;
	}

	return o;
}
