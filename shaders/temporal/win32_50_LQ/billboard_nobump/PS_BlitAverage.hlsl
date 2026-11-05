SamplerState blitSampler : register(s2);
Texture2D blitSampler_tex : register(t2);

float4 main(float4 sv_position : SV_Position) : SV_Target
{
	float4 o;

	float4 r0;
	int4 r1;
	int4 r2;
	float3 r3;
	float3 r4;
	float3 r5;
	r0.xyz = blitSampler_tex.Sample(blitSampler, float2(0.5, 0.5)).xyz;
	r1.x = asint(dot(r0.xyz, float3(1, 1, 1)));
	r2.xyz = asint(blitSampler_tex.Sample(blitSampler, float2(0.5, 1.5)).xyz);
	r1.y = asint(dot(asfloat(r2.xyz), float3(1, 1, 1)));
	r3 = blitSampler_tex.Sample(blitSampler, float2(0.5, 2.5)).xyz;
	r1.z = asint(dot(r3.xyz, float3(1, 1, 1)));
	r4 = blitSampler_tex.Sample(blitSampler, float2(0.5, 3.5)).xyz;
	r1.w = asint(dot(r4.xyz, float3(1, 1, 1)));
	r1 = (asfloat(r1) >= float4(0.5, 0.5, 0.5, 0.5)) ? -1 : 0;
	r1 = r1 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r2.xyz = asint(asfloat(r1.yyy) * asfloat(r2.xyz));
	r0.xyz = r0.xyz * asfloat(r1.xxx) + asfloat(r2.xyz);
	r0.xyz = r3.xyz * asfloat(r1.zzz) + r0.xyz;
	r0.xyz = r4.xyz * asfloat(r1.www) + r0.xyz;
	r0.w = dot(asfloat(r1), float4(1, 1, 1, 1));
	r1.xyz = asint(blitSampler_tex.Sample(blitSampler, float2(0.5, 4.5)).xyz);
	r2.x = asint(dot(asfloat(r1.xyz), float3(1, 1, 1)));
	r3 = blitSampler_tex.Sample(blitSampler, float2(0.5, 5.5)).xyz;
	r2.y = asint(dot(r3.xyz, float3(1, 1, 1)));
	r4 = blitSampler_tex.Sample(blitSampler, float2(0.5, 6.5)).xyz;
	r2.z = asint(dot(r4.xyz, float3(1, 1, 1)));
	r5 = blitSampler_tex.Sample(blitSampler, float2(0.5, 7.5)).xyz;
	r2.w = asint(dot(r5.xyz, float3(1, 1, 1)));
	r2 = (asfloat(r2) >= float4(0.5, 0.5, 0.5, 0.5)) ? -1 : 0;
	r2 = r2 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r0.xyz = asfloat(r1.xyz) * asfloat(r2.xxx) + r0.xyz;
	r0.xyz = r3.xyz * asfloat(r2.yyy) + r0.xyz;
	r0.xyz = r4.xyz * asfloat(r2.zzz) + r0.xyz;
	r0.xyz = r5.xyz * asfloat(r2.www) + r0.xyz;
	r1.x = asint(dot(asfloat(r2), float4(1, 1, 1, 1)));
	r0.w = r0.w + asfloat(r1.x);
	o.xyz = r0.xyz / r0.www;
	o.w = 1;

	return o;
}
