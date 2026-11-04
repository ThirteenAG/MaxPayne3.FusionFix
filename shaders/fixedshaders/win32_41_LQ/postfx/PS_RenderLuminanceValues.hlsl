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
	float3 r2;
	int4 r3;
	r0.xy = asint(globalScreenSize.xy * float2(0.03125, 0.100000001));
	r0.zw = asint(i.texcoord.xy * globalScreenSize.xy);
	r0 = asint(trunc(asfloat(r0)));
	r1.xy = asint(asfloat(r0.zw) * float2(0.03125, 0.100000001));
	r1.xy = asint(trunc(asfloat(r1.xy)));
	r0.xy = asint(asfloat(r1.xy) / asfloat(r0.xy));
	r0.x = asint(CurLumSampler_tex.Sample(CurLumSampler, asfloat(r0.xy)).x);
	r0.y = asint(asfloat(r0.x) * 0.100000001);
	r0.y = asint(trunc(asfloat(r0.y)));
	r1.z = asint(-(asfloat(r0.y)) * 10 + asfloat(r0.x));
	r0.y = (int)asfloat(r0.y);
	r1.z = asint(trunc(asfloat(r1.z)));
	r1.w = asint(frac(asfloat(r0.x)));
	r1.w = asint(asfloat(r1.w) * 10);
	r1.w = asint(trunc(asfloat(r1.w)));
	r1.zw = (int2)asfloat(r1.zw);
	r2.yz = -(asfloat(r1.xy)) * float2(32, 10) + asfloat(r0.zw);
	r0.z = asint(asfloat(r1.y) + asfloat(r1.x));
	r0.z = asint(asfloat(r0.z) * 0.5);
	r0.z = asint(frac(asfloat(r0.z)));
	r0.z = asint(asfloat(r0.z) + asfloat(r0.z));
	r0.w = asint(r2.y * 0.125);
	r0.w = asint(trunc(asfloat(r0.w)));
	r3 = (asfloat(r0.w) == float4(0, 1, 2, 3)) ? -1 : 0;
	r0.w = asint(-(asfloat(r0.w)) * 8 + r2.y);
	r1.x = r1.w & r3.w;
	r1.x = (r3.z != 0) ? 10 : r1.x;
	r1.x = (r3.y != 0) ? r1.z : r1.x;
	r0.y = (r3.x != 0) ? r0.y : r1.x;
	r0.y = asint((float)r0.y);
	r2.x = asfloat(r0.y) * 8 + asfloat(r0.w);
	r0.yw = asint(r2.xz * float2(0.00787401572, 0.0666666701));
	r0.yw = asint(AdapLumSampler_tex.Sample(AdapLumSampler, asfloat(r0.yw)).xy);
	r1.xyz = asint(asfloat(r0.xxx) * float3(0.5, 0.0500000007, 0.00499999989) + -(asfloat(r0.yyy)));
	r0.xyw = asint(asfloat(r0.www) * asfloat(r1.xyz) + asfloat(r0.yyy));
	o.xyz = asfloat(r0.zzz) * -(asfloat(r0.xyw)) + asfloat(r0.xyw);
	o.w = asfloat(r0.z);

	return o;
}
