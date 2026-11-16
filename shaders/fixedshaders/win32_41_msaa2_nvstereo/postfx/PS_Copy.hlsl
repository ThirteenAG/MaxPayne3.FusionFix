SamplerState HDRPointSampler : register(s6);
Texture2D HDRPointSampler_tex : register(t6);

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

	o = HDRPointSampler_tex.Sample(HDRPointSampler, i.texcoord.xy);

	return o;
}
