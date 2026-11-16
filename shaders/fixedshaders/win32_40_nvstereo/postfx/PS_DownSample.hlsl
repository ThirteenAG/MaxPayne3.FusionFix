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
	r0 = HDRSampler_tex.Sample(HDRSampler, i.texcoord.xy);
	o.xyz = min(r0.xyz, float3(8, 8, 8));
	o.w = 1;

	return o;
}
