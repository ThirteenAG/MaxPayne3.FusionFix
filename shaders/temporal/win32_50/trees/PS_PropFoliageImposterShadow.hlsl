SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int2 r0;
	r0.x = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy).w);
	r0.y = (asfloat(r0.x) < 0.5) ? -1 : 0;
	if (r0.y != 0) discard;
	o = asfloat(r0.x) + asfloat(r0.x);

	return o;
}
