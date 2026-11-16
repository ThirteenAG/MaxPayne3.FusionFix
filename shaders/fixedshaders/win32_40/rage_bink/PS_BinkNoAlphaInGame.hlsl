cbuffer _Globals : register(b4)
{
	row_major float4x4 YUVtoRGB : packoffset(c100);
	float GrayScaleValue : packoffset(c104);
	float2 BrightnessSetting : packoffset(c105);
};

SamplerState YPlaneSamplerInGame : register(s0);
SamplerState cRPlaneSamplerInGame : register(s1);
SamplerState cBPlaneSamplerInGame : register(s2);
Texture2D YPlaneSamplerInGame_tex : register(t0);
Texture2D cRPlaneSamplerInGame_tex : register(t1);
Texture2D cBPlaneSamplerInGame_tex : register(t2);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float4 r0;
	float4 r1;
	r0 = YPlaneSamplerInGame_tex.Sample(YPlaneSamplerInGame, i.texcoord.xy);
	r1 = cRPlaneSamplerInGame_tex.Sample(cRPlaneSamplerInGame, i.texcoord.xy);
	r0.y = r1.x;
	r1 = cBPlaneSamplerInGame_tex.Sample(cBPlaneSamplerInGame, i.texcoord.xy);
	r0.z = r1.x;
	r0.w = YUVtoRGB[3].x;
	r1.x = dot(YUVtoRGB[0], r0);
	r1.y = dot(YUVtoRGB[1], r0);
	r1.z = dot(YUVtoRGB[2], r0);
	r0.xyz = r0.xxx + -(r1.xyz);
	r0.xyz = GrayScaleValue * r0.xyz + r1.xyz;
	r0.xyz = r0.xyz * i.color.xyz;
	r0.w = i.color.w * YUVtoRGB[3].w;
	o = r0 * BrightnessSetting.x + BrightnessSetting.y;

	return o;
}
