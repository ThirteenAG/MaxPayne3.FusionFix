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
	float ColorShiftScalar : packoffset(c188);
	float4 ColorFringeParams1 : packoffset(c189);
	float4 ColorFringeParams2 : packoffset(c190);
	float4 lightrayParams : packoffset(c191);
	float4 SunRaysParams : packoffset(c192);
	float AdrenoEffectStrength : packoffset(c193);
	float ZoomFocusDistance : packoffset(c194);
	float ZoomFocusWidth : packoffset(c195);
	float TotalElapsedTime : packoffset(c196);
	float4 DruggedEffectColorShift : packoffset(c197);
	float4 DruggedEffectParams : packoffset(c198);
	float radialBlurScale : packoffset(c199);
	float3 radialBlurCenter : packoffset(c200);
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float3 texcoord1 : TEXCOORD1;
};

VS_OUT main(float2 position : POSITION)
{
	VS_OUT o;

	float3 r0;
	o.sv_position.zw = float2(0.100000001, 1);
	r0.xy = position.xy * TransPos.xy + TransPos.zw;
	o.sv_position.xy = r0.xy;
	o.texcoord = r0.xy * float2(0.5, -0.5) + float2(0.5, 0.5);
	r0.z = 0;
	o.texcoord1 = r0.xyz + -(radialBlurCenter.xyz);

	return o;
}
