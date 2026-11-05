SamplerState imposterSampler : register(s1);
SamplerState blitSampler : register(s2);
Texture2D imposterSampler_tex : register(t1);
Texture2D blitSampler_tex : register(t2);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	r0.xy = asint(i.texcoord.zz * i.texcoord.xy);
	r0.x = asint(blitSampler_tex.Sample(blitSampler, asfloat(r0.xy)).w);
	r0.xy = asint(asfloat(r0.xx) * i.texcoord.ww + i.texcoord.xy);
	r0 = asint(imposterSampler_tex.Sample(imposterSampler, asfloat(r0.xy)));
	r0.x = asint(dot(asfloat(r0), float4(1, 1, 1, 1)));
	r0.x = (asfloat(r0.x) == 0) ? -1 : 0;
	if (r0.x != 0) discard;
	o = float4(1, 1, 1, 1);

	return o;
}
