cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float3 texcoord : TEXCOORD;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int2 r0;
	r0.x = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.yz).w);
	r0.x = asint(asfloat(r0.x) * globalScalars.x);
	r0.y = (0.501960814 >= asfloat(r0.x)) ? -1 : 0;
	if (r0.y != 0) discard;
	o.xyz = i.texcoord.xxx;
	o.w = asfloat(r0.x);

	return o;
}
