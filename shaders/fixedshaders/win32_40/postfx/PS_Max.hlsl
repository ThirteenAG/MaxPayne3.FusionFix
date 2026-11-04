cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
};

SamplerState HDRSampler : register(s5);
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
	float4 r1;
	float4 r2;
	r0 = TexelSize.xyxy * float4(-0.5, -0.5, -0.5, 0.5) + i.texcoord.xyxy;
	r1 = HDRSampler_tex.Sample(HDRSampler, r0.xy);
	r0 = HDRSampler_tex.Sample(HDRSampler, r0.zw);
	r0.xyz = max(r0.xyz, r1.xyz);
	r1 = TexelSize.xyxy * float4(0.5, 0.5, 0.5, -0.5) + i.texcoord.xyxy;
	r2 = HDRSampler_tex.Sample(HDRSampler, r1.xy);
	r1 = HDRSampler_tex.Sample(HDRSampler, r1.zw);
	r1.xyz = max(r1.xyz, r2.xyz);
	o.xyz = max(r0.xyz, r1.xyz);
	o.w = 1;

	return o;
}
