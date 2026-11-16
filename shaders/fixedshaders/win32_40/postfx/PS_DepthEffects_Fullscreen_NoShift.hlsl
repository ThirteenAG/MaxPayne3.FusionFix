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
	float lowLum : packoffset(c166);
	float highLum : packoffset(c167);
	float topLum : packoffset(c168);
	float scalerLum : packoffset(c169);
	float offsetLum : packoffset(c170);
	float offsetLowLum : packoffset(c171);
	float offsetHighLum : packoffset(c172);
	float noiseLum : packoffset(c173);
	float noiseLowLum : packoffset(c174);
	float noiseHighLum : packoffset(c175);
	float bloomLum : packoffset(c176);
	float4 colorLum : packoffset(c177);
	float4 colorLowLum : packoffset(c178);
	float4 colorHighLum : packoffset(c179);
	float3 scanlineParameters : packoffset(c180);
	float2 highlightParameters : packoffset(c181);
	float4 HeatHazeParams : packoffset(c182);
	float4 HeatHazeTex1Params : packoffset(c183);
	float4 HeatHazeTex2Params : packoffset(c184);
	float4 HeatHazeOffsetParams : packoffset(c185);
	float PlayerBrightness : packoffset(c186);
	float PedBrightness : packoffset(c187);
};

cbuffer direction_light : register(b10)
{
	float4 gDepthFxParams : packoffset(c0);
};

cbuffer omni_light : register(b2)
{
	float4 gLightPosX : packoffset(c0);
	float4 gLightPosY : packoffset(c1);
	float4 gLightPosZ : packoffset(c2);
	float4 gLightDirX : packoffset(c3);
	float4 gLightDirY : packoffset(c4);
	float4 gLightDirZ : packoffset(c5);
	float4 gLightFallOff : packoffset(c6);
	float4 gLightConeScale : packoffset(c7);
	float4 gLightConeOffset : packoffset(c8);
	float4 gLightColR : packoffset(c9);
	float4 gLightColG : packoffset(c10);
	float4 gLightColB : packoffset(c11);
	float4 gLightAmbient0 : packoffset(c12);
	float4 gLightAmbient1 : packoffset(c13);
	float4 gLightAmbientDir0 : packoffset(c14);
	float4 gLightAmbientDir1 : packoffset(c15);
	float4 gLightPointColR : packoffset(c16);
	float4 gLightPointColG : packoffset(c17);
	float4 gLightPointColB : packoffset(c18);
	float4 gLightPointPosX : packoffset(c19);
	float4 gLightPointPosY : packoffset(c20);
	float4 gLightPointPosZ : packoffset(c21);
	float4 gLightDir2X : packoffset(c22);
	float4 gLightDir2Y : packoffset(c23);
	float4 gLightDir2Z : packoffset(c24);
	float4 gLightConeScale2 : packoffset(c25);
	float4 gLightConeOffset2 : packoffset(c26);
	float4 gLightPointFallOff : packoffset(c27);
	float4 gDistFadeParams : packoffset(c28);
	float4 gAdrenoFXVars : packoffset(c29);
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

SamplerState HDRSampler : register(s5);
Texture2D<float> gbufferTextureDepth : register(t3);
Texture2D HDRSampler_tex : register(t5);
Texture2D<uint4> StencilCopyTexture : register(t8);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	int4 r1;
	int4 r2;
	float4 dimensions0 = 0;
	gbufferTextureDepth.GetDimensions(0, dimensions0.x, dimensions0.y, dimensions0.w);
	r0 = asint(dimensions0);
	r0.xy = asint(asfloat(r0.xy) * i.texcoord.xy);
	r0.xy = (int2)asfloat(r0.xy);
	r0.zw = int2(0, 0);
	r0.x = asint(gbufferTextureDepth.Load(r0.xyz));
	r0.yzw = asint(float3(0, 0, 1));
	r0.y = asint(-(dofProj.x) + dofProj.y);
	r0.y = asint(dofProj.y / asfloat(r0.y));
	r0.z = asint(-(asfloat(r0.y)) + asfloat(r0.x));
	r0.x = (asfloat(r0.x) >= 1) ? -1 : 0;
	r0.x = r0.x & 1065353216;
	r0.y = asint(asfloat(r0.y) * -(dofProj.x));
	r0.y = asint(asfloat(r0.y) / asfloat(r0.z));
	r1.xyz = asint(-(asfloat(r0.yyy)) * i.texcoord1.xyz);
	r0.y = asint(saturate(-(asfloat(r0.y)) * gDepthFxParams.z + gDepthFxParams.w));
	r0.x = asint(asfloat(r0.x) + asfloat(r0.y));
	r0.y = asint(asfloat(r1.z) * globalFogParams.x);
	r0.z = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r0.z = asint(asfloat(r0.z) * globalFogParams.z);
	r0.w = asint(asfloat(r0.y) * -1.44269502);
	r0.w = asint(exp2(asfloat(r0.w)));
	r0.w = asint(-(asfloat(r0.w)) + 1);
	r0.w = asint(asfloat(r0.w) / asfloat(r0.y));
	r0.y = (0.0000999999975 < abs(asfloat(r0.y))) ? -1 : 0;
	r0.w = asint(asfloat(r0.w) * asfloat(r0.z));
	r0.y = (r0.y != 0) ? r0.w : r0.z;
	r0.y = asint(asfloat(r0.y) * -(globalFogParams.y));
	r0.y = asint(asfloat(r0.y) * 1.44269502);
	r0.y = asint(exp2(asfloat(r0.y)));
	r0.xy = asint(min(asfloat(r0.xy), float2(1, 1)));
	r0.z = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(asfloat(r0.z) * gDepthFxParams.y + asfloat(r0.x));
	float4 dimensions1 = 0;
	StencilCopyTexture.GetDimensions(0, dimensions1.x, dimensions1.y, dimensions1.w);
	r1 = asint(dimensions1);
	r0.zw = asint(asfloat(r1.xy) * i.texcoord.xy);
	r1.xy = (int2)asfloat(r0.zw);
	r1.zw = int2(0, 0);
	r1 = StencilCopyTexture.Load(r1.xyz);
	r1 = r1.y & int4(7, 7, 128, 64);
	r1 = (r1 == int4(5, 1, 128, 64)) ? -1 : 0;
	r0.z = (r1.z == 0) ? -1 : 0;
	r0.z = r1.y & r0.z;
	r1.yz = r1.yy & r1.zw;
	r0.w = (r1.z == 0) ? -1 : 0;
	r0.w = r0.w & r0.z;
	r2.z = r0.z & 1065353216;
	r0.z = (r0.w != 0) ? asint(PedBrightness) : 1065353216;
	r0.w = r1.z | r1.y;
	r2.yw = r1.xy & int2(1065353216, 1065353216);
	r0.w = (r0.w != 0) ? asint(PlayerBrightness) : 1065353216;
	r0.z = asint(asfloat(r0.z) * asfloat(r0.w));
	r1 = asint(HDRSampler_tex.Sample(HDRSampler, i.texcoord.xy));
	r0.w = (0 != asfloat(r1.w)) ? -1 : 0;
	r0.z = (r0.w != 0) ? r0.z : 1065353216;
	r1.xyz = asint(asfloat(r0.zzz) * asfloat(r1.xyz));
	o.w = asfloat(r1.w);
	r0.z = asint(dot(asfloat(r1.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.xz = asint(asfloat(r0.xz) + float2(-0.999989986, 0.00000999999975));
	r0.z = asint(abs(asfloat(r0.z)) + 0.00000999999975);
	r0.z = asint(log2(asfloat(r0.z)));
	r0.x = asint(asfloat(r0.z) * asfloat(r0.x));
	r0.x = asint(exp2(asfloat(r0.x)));
	r0.xzw = asint(asfloat(r1.xyz) * asfloat(r0.xxx) + -(globalFogColorN.xyz));
	r0.xyz = asint(asfloat(r0.yyy) * asfloat(r0.xzw) + globalFogColorN.xyz);
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.212500006, 0.715399981, 0.0720999986)));
	r0.xyz = asint(-(asfloat(r0.www)) + asfloat(r0.xyz));
	r1.x = asint(dot(asfloat(r2.yzw), float3(1, 1, 1)));
	r1.x = asint(min(asfloat(r1.x), 1));
	r2.x = asint(-(asfloat(r1.x)) + 1);
	r1.x = asint(dot(asfloat(r2), gAdrenoFXVars));
	r1.x = asint(asfloat(r1.x) * deSatContrastGamma.x);
	o.xyz = asfloat(r1.xxx) * asfloat(r0.xyz) + asfloat(r0.www);

	return o;
}
