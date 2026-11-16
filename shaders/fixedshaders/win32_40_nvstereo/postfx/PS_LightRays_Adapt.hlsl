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
};

SamplerState CurLumSampler : register(s0);
SamplerState AdapLumSampler : register(s1);
SamplerState GBufferTextureSamplerSSAODepth : register(s4);
SamplerState HDRSampler : register(s5);
SamplerState BloomSampler : register(s10);
SamplerState DeathSampler : register(s15);
Texture2D CurLumSampler_tex : register(t0);
Texture2D AdapLumSampler_tex : register(t1);
Texture2D GBufferTextureSamplerSSAODepth_tex : register(t4);
Texture2D HDRSampler_tex : register(t5);
Texture2D BloomSampler_tex : register(t10);
Texture2D DeathSampler_tex : register(t15);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	r0 = CurLumSampler_tex.Sample(CurLumSampler, i.texcoord.xy);
	r0.x = r0.x * 0.600000024 + 1;
	r0.x = r0.x * r0.x;
	r1 = GBufferTextureSamplerSSAODepth_tex.Sample(GBufferTextureSamplerSSAODepth, i.texcoord.xy);
	r0.y = r1.x * 4;
	r0.x = r0.y / r0.x;
	r1 = HDRSampler_tex.Sample(HDRSampler, i.texcoord.xy);
	r0.y = r1.x * 4;
	r0.yzw = r0.yyy * SunRaysParams.xyz;
	r0.yzw = r0.yzw * float3(4, 4, 4);
	r0.xyz = lightrayParams.xyz * r0.xxx + r0.yzw;
	r1 = DeathSampler_tex.Sample(DeathSampler, i.texcoord.xy);
	r0.w = -(r1.x) + 1;
	r1.x = -(ToneMapParams.z) + ToneMapParams.w;
	r0.w = r0.w * r1.x + ToneMapParams.z;
	r0.xyz = r0.xyz / r0.www;
	r1 = BloomSampler_tex.Sample(BloomSampler, i.texcoord.xy);
	r1.xyz = max(r1.xyz, float3(0, 0, 0));
	r1.xyz = min(r1.xyz, float3(11, 11, 11));
	r2 = AdapLumSampler_tex.Sample(AdapLumSampler, float2(0, 0));
	r0.w = ToneMapParams.y / r2.x;
	r0.w = ToneMapParams.x / r0.w;
	r1.xyz = -(r0.www) + r1.xyz;
	r1.xyz = max(r1.xyz, float3(0, 0, 0));
	o.xyz = r0.xyz + r1.xyz;
	o.w = 1;

	return o;
}
