float2 BrightnessSetting : register(c105);
float GrayScaleValue : register(c104);
sampler2D YPlaneSampler : register(s4);
row_major float4x4 YUVtoRGB : register(c100);
sampler2D cBPlaneSampler : register(s6);
sampler2D cRPlaneSampler : register(s5);

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
	r0 = tex2D(YPlaneSampler, i.texcoord.xy);
	r1.xy = float2(1, 0.99264705) * i.texcoord.xy;
	r2 = tex2D(cRPlaneSampler, r1.xy);
	r1 = tex2D(cBPlaneSampler, r1.xy);
	r0.z = r1.x;
	r0.y = r2.x;
	r0.w = YUVtoRGB[3].x;
	r1.x = dot(YUVtoRGB[0], r0);
	r1.y = dot(YUVtoRGB[1], r0);
	r1.z = dot(YUVtoRGB[2], r0);
	r2.xyz = lerp(r1.xyz, r0.xxx, GrayScaleValue.xxx);
	r0.xyz = r2.xyz * i.color.xyz;
	r0.w = YUVtoRGB[3].w * i.color.w;
	o = r0 * BrightnessSetting.x + BrightnessSetting.y;

	return o;
}
