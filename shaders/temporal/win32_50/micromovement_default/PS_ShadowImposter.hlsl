SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float r0;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).w;
	o = r0.x * i.color.w;

	return o;
}
