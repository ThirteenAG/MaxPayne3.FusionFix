SamplerState BloomSampler : register(s10);
Texture2D BloomSampler_tex : register(t10);

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
	float4 r1;
	float4 r2;
	r0 = BloomSampler_tex.Sample(BloomSampler, i.texcoord1.zw);
	r1 = BloomSampler_tex.Sample(BloomSampler, i.texcoord.xy);
	r0.xyz = r0.xyz + -(r1.xyz);
	r0.xyz = max(r0.xyz, float3(0, 0, 0));
	r0.xyz = r0.xyz * float3(0.330000013, 0.330000013, 0.330000013);
	r2 = BloomSampler_tex.Sample(BloomSampler, i.texcoord.zw);
	r2.xyz = -(r1.xyz) + r2.xyz;
	r2.xyz = max(r2.xyz, float3(0, 0, 0));
	r0.xyz = r2.xyz * float3(0.0500000007, 0.0500000007, 0.0500000007) + r0.xyz;
	r2 = BloomSampler_tex.Sample(BloomSampler, i.texcoord2.xy);
	r2.xyz = -(r1.xyz) + r2.xyz;
	r2.xyz = max(r2.xyz, float3(0, 0, 0));
	r0.xyz = r2.xyz * float3(0.330000013, 0.330000013, 0.330000013) + r0.xyz;
	r2 = BloomSampler_tex.Sample(BloomSampler, i.texcoord3.xy);
	r2.xyz = -(r1.xyz) + r2.xyz;
	r2.xyz = max(r2.xyz, float3(0, 0, 0));
	r0.xyz = r2.xyz * float3(0.0500000007, 0.0500000007, 0.0500000007) + r0.xyz;
	r2 = BloomSampler_tex.Sample(BloomSampler, i.texcoord1.xy);
	r2.xyz = -(r1.xyz) + r2.xyz;
	r2.xyz = max(r2.xyz, float3(0, 0, 0));
	r0.xyz = r2.xyz * float3(0.119999997, 0.119999997, 0.119999997) + r0.xyz;
	r2 = BloomSampler_tex.Sample(BloomSampler, i.texcoord2.zw);
	r2.xyz = -(r1.xyz) + r2.xyz;
	r2.xyz = max(r2.xyz, float3(0, 0, 0));
	r0.xyz = r2.xyz * float3(0.119999997, 0.119999997, 0.119999997) + r0.xyz;
	o.xyz = r0.xyz * float3(0.5, 0.5, 0.5) + r1.xyz;
	o.w = 1;

	return o;
}
