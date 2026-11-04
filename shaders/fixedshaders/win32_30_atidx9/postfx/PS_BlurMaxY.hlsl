sampler2D BloomSampler : register(s10);
sampler2D HDRPointSampler : register(s6);

struct PS_IN
{
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float2 texcoord3 : TEXCOORD3;
};

float4 main(PS_IN i) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	r0 = tex2D(BloomSampler, i.texcoord.zw);
	r1 = tex2D(HDRPointSampler, i.texcoord.xy);
	r0.xyz = r0.xyz + -r1.xyz;
	r2.xyz = half3(r0.xyz * 0.001723);
	r0.xyz = half3((r0.xyz >= 0) ? r2.xyz : 0);
	r2 = tex2D(BloomSampler, i.texcoord1.xy);
	r2.xyz = -r1.xyz + r2.xyz;
	r3 = r2.xyz * 0.059106;
	r2.xyz = (r2.xyz >= 0) ? r3.xyz : 0;
	r0.xyz = half3(r0.xyz + r2.xyz);
	r2 = tex2D(BloomSampler, i.texcoord1.zw);
	r2.xyz = -r1.xyz + r2.xyz;
	r3 = r2.xyz * 0.493069;
	r2.xyz = (r2.xyz >= 0) ? r3.xyz : 0;
	r0.xyz = half3(r0.xyz + r2.xyz);
	r2 = tex2D(BloomSampler, i.texcoord2.xy);
	r2.xyz = -r1.xyz + r2.xyz;
	r3 = r2.xyz * 0.493069;
	r2.xyz = (r2.xyz >= 0) ? r3.xyz : 0;
	r0.xyz = half3(r0.xyz + r2.xyz);
	r2 = tex2D(BloomSampler, i.texcoord2.zw);
	r2.xyz = -r1.xyz + r2.xyz;
	r3 = r2.xyz * 0.059106;
	r2.xyz = (r2.xyz >= 0) ? r3.xyz : 0;
	r0.xyz = half3(r0.xyz + r2.xyz);
	r2 = tex2D(BloomSampler, i.texcoord3.xy);
	r1.xyz = -r1.xyz + r2.xyz;
	r2.xyz = r1.xyz * 0.001723;
	r1.xyz = (r1.xyz >= 0) ? r2.xyz : 0;
	r0.xyz = half3(r0.xyz + r1.xyz);
	r1 = tex2D(BloomSampler, i.texcoord.xy);
	o.xyz = r0.xyz * 0.47442922 + r1.xyz;
	o.w = 1;

	return o;
}
