cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
Texture2D DiffuseSampler_tex : register(t0);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float4 r0;
	float3 r1;
	r0.x = i.texcoord1.w;
	r0.y = i.texcoord2.w;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, r0.xy);
	r1 = -(i.texcoord.xyz) * r0.xyz + i.texcoord3.xyz;
	r0 = r0 * i.texcoord;
	r0.xyz = i.texcoord3.www * r1.xyz + r0.xyz;
	o.w = r0.w;
	o.xyz = r0.xyz * globalScalars.yyy;

	return o;
}
