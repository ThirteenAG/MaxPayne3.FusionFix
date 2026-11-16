sampler2D APlaneSamplerInGame : register(s3);
float GrayScaleValue : register(c104);
sampler2D YPlaneSamplerInGame : register(s0);
row_major float4x4 YUVtoRGB : register(c100);
sampler2D cBPlaneSamplerInGame : register(s2);
sampler2D cRPlaneSamplerInGame : register(s1);

struct PS_IN
{
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
};

float4 main(PS_IN i) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	r0 = tex2D(YPlaneSamplerInGame, i.texcoord.xy);
	r1 = tex2D(cRPlaneSamplerInGame, i.texcoord.xy);
	r0.y = r1.x;
	r1 = tex2D(cBPlaneSamplerInGame, i.texcoord.xy);
	r0.z = r1.x;
	r0.w = YUVtoRGB[3].x;
	r1.x = dot(YUVtoRGB[0], r0);
	r1.y = dot(YUVtoRGB[1], r0);
	r1.z = dot(YUVtoRGB[2], r0);
	r2.xyz = lerp(r1.xyz, r0.xxx, GrayScaleValue.xxx);
	r0 = tex2D(APlaneSamplerInGame, i.texcoord.xy);
	r2.w = r0.x * YUVtoRGB[3].w;
	o = r2 * i.color;

	return o;
}
