cbuffer _Globals : register(b4)
{
	row_major float4x4 YUVtoRGB : packoffset(c100);
	float GrayScaleValue : packoffset(c104);
	float2 BrightnessSetting : packoffset(c105);
};

SamplerState YPlaneSampler_s : register(s4);
SamplerState cRPlaneSampler_s : register(s5);
SamplerState cBPlaneSampler_s : register(s6);
Texture2D YPlaneSampler : register(t4);
Texture2D cRPlaneSampler : register(t5);
Texture2D cBPlaneSampler : register(t6);

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
	float3 r1;
	r0.x = YPlaneSampler.Sample(YPlaneSampler_s, i.texcoord.xy).x;
	r1.xy = i.texcoord.xy * float2(1, 0.992647052);
	r0.y = cRPlaneSampler.Sample(cRPlaneSampler_s, r1.xy).x;
	r0.z = cBPlaneSampler.Sample(cBPlaneSampler_s, r1.xy).x;
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
