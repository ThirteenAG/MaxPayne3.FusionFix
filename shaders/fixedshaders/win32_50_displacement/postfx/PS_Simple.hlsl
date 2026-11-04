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
};

cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
	float4 globalScalars2 : packoffset(c1);
	float4 globalScalars3 : packoffset(c2);
	float4 globalScalars4 : packoffset(c3);
	float4 globalFogParams : packoffset(c4);
	float4 globalFogColor : packoffset(c5);
	float4 globalFogOffsetN : packoffset(c6);
	float4 globalFogColorN : packoffset(c7);
	float4 globalScreenSize : packoffset(c8);
	float4 globalDayNightEffects : packoffset(c9);
	float4 ColorCorrectTopAndPedReflectScale : packoffset(c10);
	float4 ColorCorrectBottomOffset : packoffset(c11);
	float4 ColorShift : packoffset(c12);
	float4 deSatContrastGamma : packoffset(c13);
};

SamplerState AdapLumSampler : register(s1);
SamplerState HDRSampler : register(s5);
Texture2D AdapLumSampler_tex : register(t1);
Texture2D HDRSampler_tex : register(t5);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord1 : TEXCOORD1;
	float2 texcoord2 : TEXCOORD2;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float4 r0;
	float3 r1;
	r0.xyz = HDRSampler_tex.Sample(HDRSampler, i.texcoord.xy).xyz;
	r0.xyz = r0.xyz * Exposures.xxx;
	r0.w = AdapLumSampler_tex.Sample(AdapLumSampler, float2(0, 0)).x;
	r0.w = ToneMapParams.y / r0.w;
	r0.xyz = r0.www * r0.xyz;
	r0.w = saturate(dot(r0.xyz, float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.w = r0.w + 0.0000100999996;
	r0.w = log2(r0.w);
	r1.x = deSatContrastGamma.z + -0.999989986;
	r0.w = r0.w * r1.x;
	r0.w = exp2(r0.w);
	r0.w = min(r0.w, 65000);
	r0.xyz = r0.www * r0.xyz;
	r0.xyz = r0.xyz * BrightnessSetting.xxx + BrightnessSetting.yyy;
	r1 = saturate(r0.xyz);
	o.xyz = r0.xyz;
	o.w = dot(r1.xyz, float3(0.298999995, 0.298999995, 0.298999995));

	return o;
}
