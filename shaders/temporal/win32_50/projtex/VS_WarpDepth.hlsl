cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
};

cbuffer ShadowParam : register(b8)
{
	float4 gShadowParam18192021 : packoffset(c0);
	float4 gShadowParam14151617 : packoffset(c1);
	float4 gShadowParam0123 : packoffset(c2);
	float4 gShadowParam4567 : packoffset(c3);
	float4 gShadowParam891113 : packoffset(c4);
	float4 gCascadeZScales : packoffset(c5);
	float4 gCascadeZOffsets : packoffset(c6);
	float4 gCascadeXMinThresholds : packoffset(c7);
	float4 gCascadeXMaxThresholds : packoffset(c8);
	float4 gCascadeYMinThresholds : packoffset(c9);
	float4 gCascadeYMaxThresholds : packoffset(c10);
	row_major float4x4 gShadowMatrix : packoffset(c11);
};

cbuffer vehicle_switchon : register(b13)
{
	bool switchOn : packoffset(c0);
};

cbuffer CacheVehicleRadius : register(b4)
{
	float BoundRadius : packoffset(c0);
};

SamplerState DamageSampler : register(s1);
Texture2D DamageSampler_tex : register(t1);

struct VS_IN
{
	float3 position : POSITION;
	float4 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord : TEXCOORD;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float3 r5;
	if (switchOn != 0) {
		r0.x = dot(i.position.xyz, i.position.xyz);
		r0.x = sqrt(r0.x);
		r0.yzw = i.position.xyz / r0.xxx;
		r0.w = -(r0.w) + 1;
		r0.w = r0.w * 0.5;
		r0.yz = r0.yz + float2(0.00000999999975, 0.00000999999975);
		r1.x = asint(dot(r0.yz, r0.yz));
		r1.x = asint(rsqrt(asfloat(r1.x)));
		r0.yz = r0.yz * asfloat(r1.xx);
		r0.yz = r0.ww * r0.yz;
		r0.yz = r0.yz * float2(0.5, 0.5) + float2(0.5, 0.5);
		r1.xy = asint(r0.yz * float2(126.732674, 126.732674));
		r1.zw = (asfloat(r1.xy) >= -(asfloat(r1.xy))) ? -1 : 0;
		r1.xy = asint(frac(abs(asfloat(r1.xy))));
		r1.xy = (r1.zw != 0) ? r1.xy : asint(-(asfloat(r1.xy)));
		r0.w = DamageSampler_tex.SampleLevel(DamageSampler, r0.yz, 0).x;
		r0.yz = -(asfloat(r1.xy)) * float2(0.00789062493, 0.00789062493) + r0.yz;
		r2 = r0.yzyz + float4(0.00789062493, 0, 0, 0.00789062493);
		r1.z = asint(DamageSampler_tex.SampleLevel(DamageSampler, r2.xy, 0).x);
		r1.w = asint(DamageSampler_tex.SampleLevel(DamageSampler, r2.zw, 0).x);
		r0.yz = r0.yz + float2(0.00789062493, 0.00789062493);
		r0.y = DamageSampler_tex.SampleLevel(DamageSampler, r0.yz, 0).x;
		r0.z = r0.w * 0.0000152587891;
		r2.z = trunc(r0.z);
		r0.z = -(r2.z) * 65536 + r0.w;
		r0.w = r0.z * 0.00390625;
		r2.y = trunc(r0.w);
		r2.x = -(r2.y) * 256 + r0.z;
		r0.z = asfloat(r1.z) * 0.0000152587891;
		r3.z = trunc(r0.z);
		r0.z = -(r3.z) * 65536 + asfloat(r1.z);
		r0.w = r0.z * 0.00390625;
		r3.y = trunc(r0.w);
		r3.x = -(r3.y) * 256 + r0.z;
		r0.z = asfloat(r1.w) * 0.0000152587891;
		r4.z = trunc(r0.z);
		r0.z = -(r4.z) * 65536 + asfloat(r1.w);
		r0.w = r0.z * 0.00390625;
		r4.y = trunc(r0.w);
		r4.x = -(r4.y) * 256 + r0.z;
		r0.z = r0.y * 0.0000152587891;
		r5.z = trunc(r0.z);
		r0.y = -(r5.z) * 65536 + r0.y;
		r0.z = r0.y * 0.00390625;
		r5.y = trunc(r0.z);
		r5.x = -(r5.y) * 256 + r0.y;
		r0.yz = -(asfloat(r1.xy)) + float2(1, 1);
		r2.xyz = r0.yyy * r2.xyz;
		r3.xyz = asfloat(r1.xxx) * r3.xyz;
		r3.xyz = r0.zzz * r3.xyz;
		r2.xyz = r2.xyz * r0.zzz + r3.xyz;
		r0.yzw = r0.yyy * r4.xyz;
		r0.yzw = r0.yzw * asfloat(r1.yyy) + r2.xyz;
		r1.xzw = asint(asfloat(r1.xxx) * r5.xyz);
		r0.yzw = asfloat(r1.xzw) * asfloat(r1.yyy) + r0.yzw;
		r0.yzw = r0.yzw + float3(-128, -128, -128);
		r0.yzw = r0.yzw * float3(0.0078125, 0.0078125, 0.0078125);
		r0.x = r0.x / BoundRadius;
		r0.x = min(r0.x, 1);
		r0.xyz = r0.xxx * r0.yzw;
		r0.xyz = r0.xyz * float3(0.5, 0.5, 0.5) + i.position.xyz;
	} else {
		r0.xyz = i.position.xyz;
	}
	r1.xyz = asint(r0.yyy * gWorld[1].xyz);
	r0.xyw = r0.xxx * gWorld[0].xyz + asfloat(r1.xyz);
	r0.xyz = r0.zzz * gWorld[2].xyz + r0.xyw;
	r0.xyz = r0.xyz + gWorld[3].xyz;
	r1.xy = (gShadowParam14151617.xx == float2(0, 1)) ? -1 : 0;
	r2.xyz = r0.yyy * gShadowMatrix[1].xyz;
	r2.xyz = r0.xxx * gShadowMatrix[0].xyz + r2.xyz;
	r2.xyz = r0.zzz * gShadowMatrix[2].xyz + r2.xyz;
	r2.xyz = r2.xyz + gShadowMatrix[3].xyz;
	r0.w = dot(r2.xyz, r2.xyz);
	r0.w = sqrt(r0.w);
	r1.z = asint(-(r2.z) + r0.w);
	r3.xy = r2.xy / asfloat(r1.zz);
	r3.w = r2.z * -(gShadowParam0123.w);
	r3.z = r0.w * -(gShadowParam0123.w);
	r2 = r0.y * gShadowMatrix[1];
	r2 = r0.x * gShadowMatrix[0] + r2;
	r2 = r0.z * gShadowMatrix[2] + r2;
	r2 = r2 + gShadowMatrix[3];
	r2 = (r1.x != 0) ? r3 : r2;
	r0.w = r2.w * -(gShadowParam0123.w);
	r3.z = (r1.y != 0) ? r0.w : r2.w;
	r4.x = 1;
	r4.yz = r2.wz;
	r3.x = r4.y;
	r3.y = r0.z;
	r1.xyz = asint((r1.xxx != 0) ? r4.xyz : r3.xyz);
	o.sv_position.xyz = r2.xyz;
	o.sv_position.w = asfloat(r1.x);
	o.texcoord1.xy = r0.xy;
	o.texcoord1.zw = asfloat(r1.yz);
	o.texcoord = i.texcoord;

	return o;
}
