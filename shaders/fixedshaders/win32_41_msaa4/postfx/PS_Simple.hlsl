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
Texture2D AdapLumSampler_tex : register(t1);
Texture2DMS<float4> PostFxTexture0a : register(t6);

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

	int4 r0;
	int4 r1;
	float4 r2;
	float r3;
	float3 dimensions0;
	PostFxTexture0a.GetDimensions(dimensions0.x, dimensions0.y, dimensions0.z);
	r0.xy = asint(dimensions0.xy);
	r0.xy = asint(asfloat(r0.xy) * i.texcoord.xy);
	r0.xy = (int2)asfloat(r0.xy);
	r0.zw = int2(0, 0);
	r1.xyz = asint(PostFxTexture0a.Load(r0.xy, 1).xyz);
	r1.xyz = asint(asfloat(r1.xyz) * Exposures.xxx);
	r1.w = asint(AdapLumSampler_tex.Sample(AdapLumSampler, float2(0, 0)).x);
	r1.w = asint(ToneMapParams.y / asfloat(r1.w));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r2.x = saturate(dot(asfloat(r1.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r2.x = r2.x + 0.0000100999996;
	r2.x = log2(r2.x);
	r2.y = deSatContrastGamma.z + -0.999989986;
	r2.x = r2.x * r2.y;
	r2.x = exp2(r2.x);
	r2.x = min(r2.x, 65000);
	r1.xyz = asint(asfloat(r1.xyz) * r2.xxx);
	r2.xzw = PostFxTexture0a.Load(r0.xy, 0).xyz;
	r2.xzw = r2.xzw * Exposures.xxx;
	r2.xzw = asfloat(r1.www) * r2.xzw;
	r3 = saturate(dot(r2.xzw, float3(0.212500006, 0.715399981, 0.0720999986)));
	r3 = r3.x + 0.0000100999996;
	r3 = log2(r3.x);
	r3 = r2.y * r3.x;
	r3 = exp2(r3.x);
	r3 = min(r3.x, 65000);
	r1.xyz = asint(r2.xzw * r3.xxx + asfloat(r1.xyz));
	r2.xzw = PostFxTexture0a.Load(r0.xy, 2).xyz;
	r0.xyz = asint(PostFxTexture0a.Load(r0.xy, 3).xyz);
	r0.xyz = asint(asfloat(r0.xyz) * Exposures.xxx);
	r0.xyz = asint(asfloat(r1.www) * asfloat(r0.xyz));
	r2.xzw = r2.xzw * Exposures.xxx;
	r2.xzw = asfloat(r1.www) * r2.xzw;
	r0.w = asint(saturate(dot(r2.xzw, float3(0.212500006, 0.715399981, 0.0720999986))));
	r0.w = asint(asfloat(r0.w) + 0.0000100999996);
	r0.w = asint(log2(asfloat(r0.w)));
	r0.w = asint(asfloat(r0.w) * r2.y);
	r0.w = asint(exp2(asfloat(r0.w)));
	r0.w = asint(min(asfloat(r0.w), 65000));
	r1.xyz = asint(r2.xzw * asfloat(r0.www) + asfloat(r1.xyz));
	r0.w = asint(saturate(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986))));
	r0.w = asint(asfloat(r0.w) + 0.0000100999996);
	r0.w = asint(log2(asfloat(r0.w)));
	r0.w = asint(asfloat(r0.w) * r2.y);
	r0.w = asint(exp2(asfloat(r0.w)));
	r0.w = asint(min(asfloat(r0.w), 65000));
	r0.xyz = asint(asfloat(r0.xyz) * asfloat(r0.www) + asfloat(r1.xyz));
	r0.xyz = asint(asfloat(r0.xyz) * BrightnessSetting.xxx);
	r0.xyz = asint(asfloat(r0.xyz) * float3(0.25, 0.25, 0.25) + BrightnessSetting.yyy);
	r1.xyz = asint(saturate(asfloat(r0.xyz)));
	o.xyz = asfloat(r0.xyz);
	o.w = dot(asfloat(r1.xyz), float3(0.298999995, 0.298999995, 0.298999995));

	return o;
}
