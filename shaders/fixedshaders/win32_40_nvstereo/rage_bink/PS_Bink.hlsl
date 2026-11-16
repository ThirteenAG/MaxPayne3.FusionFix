cbuffer _Globals : register(b4)
{
	row_major float4x4 YUVtoRGB : packoffset(c100);
	float GrayScaleValue : packoffset(c104);
};

SamplerState YPlaneSampler : register(s4);
SamplerState cRPlaneSampler : register(s5);
SamplerState cBPlaneSampler : register(s6);
SamplerState APlaneSampler : register(s7);
Texture2D YPlaneSampler_tex : register(t4);
Texture2D cRPlaneSampler_tex : register(t5);
Texture2D cBPlaneSampler_tex : register(t6);
Texture2D APlaneSampler_tex : register(t7);

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
	r0 = YPlaneSampler_tex.Sample(YPlaneSampler, i.texcoord.xy);
	r1 = cRPlaneSampler_tex.Sample(cRPlaneSampler, i.texcoord.xy);
	r0.y = r1.x;
	r1 = cBPlaneSampler_tex.Sample(cBPlaneSampler, i.texcoord.xy);
	r0.z = r1.x;
	r0.w = YUVtoRGB[3].x;
	r1.x = dot(YUVtoRGB[0], r0);
	r1.y = dot(YUVtoRGB[1], r0);
	r1.z = dot(YUVtoRGB[2], r0);
	r0.xyz = r0.xxx + -(r1.xyz);
	r0.xyz = GrayScaleValue * r0.xyz + r1.xyz;
	r1 = APlaneSampler_tex.Sample(APlaneSampler, i.texcoord.xy);
	r0.w = r1.x * YUVtoRGB[3].w;
	o = r0 * i.color;

	return o;
}
