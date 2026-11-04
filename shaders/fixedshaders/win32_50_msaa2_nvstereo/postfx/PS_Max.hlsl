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
	float3 r2;
	r0 = TexelSize.xyxy * float4(-0.5, -0.5, -0.5, 0.5) + i.texcoord.xyxy;
	r1.xyz = HDRSampler_tex.Sample(HDRSampler, r0.xy).xyz;
	r0.xyz = HDRSampler_tex.Sample(HDRSampler, r0.zw).xyz;
	r0.xyz = max(r0.xyz, r1.xyz);
	r1 = TexelSize.xyxy * float4(0.5, 0.5, 0.5, -0.5) + i.texcoord.xyxy;
	r2 = HDRSampler_tex.Sample(HDRSampler, r1.xy).xyz;
	r1.xyz = HDRSampler_tex.Sample(HDRSampler, r1.zw).xyz;
	r1.xyz = max(r1.xyz, r2.xyz);
	r0.xyz = max(r0.xyz, r1.xyz);
	o.xyz = r0.xyz * float3(0.25, 0.25, 0.25);
	o.w = 1;

	return o;
}
