cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
};

SamplerState GBufferTextureSampler2 : register(s2);
SamplerState HDRPointSampler : register(s6);
Texture2D GBufferTextureSampler2_tex : register(t2);
Texture2D HDRPointSampler_tex : register(t6);

struct PS_IN
{
	noperspective float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float4 r0;
	int4 r1;
	float4 r2;
	r0 = HDRPointSampler_tex.Sample(HDRPointSampler, i.texcoord.xy);
	r1.x = asint(GBufferTextureSampler2_tex.Sample(GBufferTextureSampler2, i.texcoord.xy).w);
	r1.y = (asfloat(r1.x) != 0) ? -1 : 0;
	r1.zw = asint(TexelSize.xy * float2(1, 0) + i.texcoord.xy);
	r2 = HDRPointSampler_tex.Sample(HDRPointSampler, asfloat(r1.zw));
	if (r1.y != 0) {
		r1.y = (asfloat(r1.x) == 0) ? -1 : 0;
		r1.x = (r1.y != 0) ? 1065353216 : r1.x;
		r1.y = asint(i.sv_position.y + i.sv_position.x);
		r1.y = (uint)asfloat(r1.y);
		r1.y = r1.y & 1;
		r1.z = asint(-(asfloat(r1.x)) + 1);
		r1.x = (r1.y != 0) ? r1.z : r1.x;
		r2 = -(r0) + r2;
		o = asfloat(r1.x) * r2 + r0;
	} else {
		o = r0;
	}

	return o;
}
