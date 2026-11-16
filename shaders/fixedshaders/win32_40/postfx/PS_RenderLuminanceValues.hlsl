cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
	float4 globalScalars2 : packoffset(c1);
	float4 globalScalars3 : packoffset(c2);
	float4 globalScalars4 : packoffset(c3);
	float4 globalFogParams : packoffset(c4);
	float4 globalFogColor : packoffset(c5);
	float4 globalFogOffsetN : packoffset(c6);
	float4 globalFogColorN : packoffset(c7);
	float4 globalScreenSize : packoffset(c8);
};

SamplerState CurLumSampler : register(s0);
SamplerState AdapLumSampler : register(s1);
Texture2D CurLumSampler_tex : register(t0);
Texture2D AdapLumSampler_tex : register(t1);

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

	int4 r0;
	int4 r1;
	float4 r2;
	float3 r3;
	int4 r4;
	r0.xy = asint(globalScreenSize.xy * float2(0.03125, 0.100000001));
	r0.zw = asint(i.texcoord.xy * globalScreenSize.xy);
	r0 = asint(trunc(asfloat(r0)));
	r1.xy = asint(asfloat(r0.zw) * float2(0.03125, 0.100000001));
	r1.xy = asint(trunc(asfloat(r1.xy)));
	r0.xy = asint(asfloat(r1.xy) / asfloat(r0.xy));
	r2 = CurLumSampler_tex.Sample(CurLumSampler, asfloat(r0.xy));
	r0.x = asint(r2.x * 0.100000001);
	r0.x = asint(trunc(asfloat(r0.x)));
	r0.y = asint(-(asfloat(r0.x)) * 10 + r2.x);
	r0.y = asint(trunc(asfloat(r0.y)));
	r0.xy = (int2)asfloat(r0.xy);
	r1.z = asint(frac(r2.x));
	r1.z = asint(asfloat(r1.z) * 10);
	r1.z = asint(trunc(asfloat(r1.z)));
	r1.z = (int)asfloat(r1.z);
	r3.yz = -(asfloat(r1.xy)) * float2(32, 10) + asfloat(r0.zw);
	r0.z = asint(asfloat(r1.y) + asfloat(r1.x));
	r0.z = asint(asfloat(r0.z) * 0.5);
	r0.z = asint(frac(asfloat(r0.z)));
	r0.z = asint(asfloat(r0.z) + asfloat(r0.z));
	r0.w = asint(r3.y * 0.125);
	r0.w = asint(trunc(asfloat(r0.w)));
	r4 = (asfloat(r0.w) == float4(0, 1, 2, 3)) ? -1 : 0;
	r0.w = asint(-(asfloat(r0.w)) * 8 + r3.y);
	r1.x = r1.z & r4.w;
	r1.x = (r4.z != 0) ? 10 : r1.x;
	r0.y = (r4.y != 0) ? r0.y : r1.x;
	r0.x = (r4.x != 0) ? r0.x : r0.y;
	r0.x = asint((float)r0.x);
	r3.x = asfloat(r0.x) * 8 + asfloat(r0.w);
	r0.xy = asint(r3.xz * float2(0.00787401572, 0.0666666701));
	r1 = asint(AdapLumSampler_tex.Sample(AdapLumSampler, asfloat(r0.xy)));
	r0.xyw = asint(r2.xxx * float3(0.5, 0.0500000007, 0.00499999989) + -(asfloat(r1.xxx)));
	r0.xyw = asint(asfloat(r1.yyy) * asfloat(r0.xyw) + asfloat(r1.xxx));
	o.xyz = asfloat(r0.zzz) * -(asfloat(r0.xyw)) + asfloat(r0.xyw);
	o.w = asfloat(r0.z);

	return o;
}
