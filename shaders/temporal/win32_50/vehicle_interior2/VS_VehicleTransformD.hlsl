cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
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
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord6 : TEXCOORD6;
	float3 temporalPrevious : TEXCOORD15;
};

cbuffer TemporalPrevious : register(b12)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	bool Temporal_b13_o0_switchOn : packoffset(c13);
	float Temporal_b4_o0_BoundRadius : packoffset(c14);
};
Texture2D TemporalResource_t1_DamageSampler_tex : register(t127);

VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	int4 r2;
	float3 r3;
	float3 r4;
	float3 r5;
	float4 r6;
	float3 r7;
	float3 r8;
	if (switchOn != 0) {
		r0.x = asint(dot(i.position.xyz, i.position.xyz));
		r0.x = asint(sqrt(asfloat(r0.x)));
		r0.yzw = asint(i.position.xyz / asfloat(r0.xxx));
		r0.w = asint(-(asfloat(r0.w)) + 1);
		r0.w = asint(asfloat(r0.w) * 0.5);
		r0.yz = asint(asfloat(r0.yz) + float2(0.00000999999975, 0.00000999999975));
		r1.x = asint(dot(asfloat(r0.yz), asfloat(r0.yz)));
		r1.x = asint(rsqrt(asfloat(r1.x)));
		r0.yz = asint(asfloat(r0.yz) * asfloat(r1.xx));
		r0.yz = asint(asfloat(r0.ww) * asfloat(r0.yz));
		r0.yz = asint(asfloat(r0.yz) * float2(0.5, 0.5) + float2(0.5, 0.5));
		r1.xy = asint(asfloat(r0.yz) * float2(126.732674, 126.732674));
		r1.zw = (asfloat(r1.xy) >= -(asfloat(r1.xy))) ? -1 : 0;
		r1.xy = asint(frac(abs(asfloat(r1.xy))));
		r1.xy = (r1.zw != 0) ? r1.xy : asint(-(asfloat(r1.xy)));
		r0.w = asint(DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r0.yz), 0).x);
		r0.yz = asint(-(asfloat(r1.xy)) * float2(0.00789062493, 0.00789062493) + asfloat(r0.yz));
		r2 = asint(asfloat(r0.yzyz) + float4(0.00789062493, 0, 0, 0.00789062493));
		r1.z = asint(DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.xy), 0).x);
		r1.w = asint(DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.zw), 0).x);
		r2.xy = asint(asfloat(r0.yz) + float2(0.00789062493, 0.00789062493));
		r2.x = asint(DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.xy), 0).x);
		r2.y = asint(asfloat(r0.w) * 0.0000152587891);
		r3.z = trunc(asfloat(r2.y));
		r0.w = asint(-(r3.z) * 65536 + asfloat(r0.w));
		r2.y = asint(asfloat(r0.w) * 0.00390625);
		r3.y = trunc(asfloat(r2.y));
		r3.x = -(r3.y) * 256 + asfloat(r0.w);
		r0.w = asint(asfloat(r1.z) * 0.0000152587891);
		r4.z = trunc(asfloat(r0.w));
		r0.w = asint(-(r4.z) * 65536 + asfloat(r1.z));
		r1.z = asint(asfloat(r0.w) * 0.00390625);
		r4.y = trunc(asfloat(r1.z));
		r4.x = -(r4.y) * 256 + asfloat(r0.w);
		r0.w = asint(asfloat(r1.w) * 0.0000152587891);
		r5.z = trunc(asfloat(r0.w));
		r0.w = asint(-(r5.z) * 65536 + asfloat(r1.w));
		r1.z = asint(asfloat(r0.w) * 0.00390625);
		r5.y = trunc(asfloat(r1.z));
		r5.x = -(r5.y) * 256 + asfloat(r0.w);
		r0.w = asint(asfloat(r2.x) * 0.0000152587891);
		r6.z = trunc(asfloat(r0.w));
		r0.w = asint(-(r6.z) * 65536 + asfloat(r2.x));
		r1.z = asint(asfloat(r0.w) * 0.00390625);
		r6.y = trunc(asfloat(r1.z));
		r6.x = -(r6.y) * 256 + asfloat(r0.w);
		r1.zw = asint(-(asfloat(r1.xy)) + float2(1, 1));
		r2.xyz = asint(asfloat(r1.zzz) * r3.xyz);
		r7 = asfloat(r1.xxx) * r4.xyz;
		r7 = asfloat(r1.www) * r7.xyz;
		r2.xyz = asint(asfloat(r2.xyz) * asfloat(r1.www) + r7.xyz);
		r7 = asfloat(r1.zzz) * r5.xyz;
		r2.xyz = asint(r7.xyz * asfloat(r1.yyy) + asfloat(r2.xyz));
		r1.xzw = asint(asfloat(r1.xxx) * r6.xyz);
		r1.xyz = asint(asfloat(r1.xzw) * asfloat(r1.yyy) + asfloat(r2.xyz));
		r1.xyz = asint(asfloat(r1.xyz) + float3(-128, -128, -128));
		r1.xyz = asint(asfloat(r1.xyz) * float3(0.0078125, 0.0078125, 0.0078125));
		r0.x = asint(asfloat(r0.x) / BoundRadius);
		r0.x = asint(min(asfloat(r0.x), 1));
		r1.xyz = asint(asfloat(r0.xxx) * asfloat(r1.xyz));
		r1.xyz = asint(asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + i.position.xyz);
		r2.xyz = (i.normal.xyz == float3(1, 1, 1)) ? -1 : 0;
		r0.w = r2.y & r2.x;
		r0.w = r2.z & r0.w;
		if (r0.w != 0) {
			r2.xyz = int3(0, 0, 1065353216);
		} else {
			r6 = asfloat(r0.yzyz) + float4(-0.5, -0.5, -0.492109388, -0.5);
			r6 = r6 + r6;
			r0.w = asint(dot(r6.xy, r6.xy));
			r1.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r0.w = asint(sqrt(asfloat(r0.w)));
			r0.w = r0.w & r1.w;
			r1.w = asint(-(asfloat(r0.w)) * 2 + 1);
			r7.z = max(asfloat(r1.w), -1);
			r1.w = (r7.z < 1) ? -1 : 0;
			r2.w = (-1 < r7.z) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = asint(-(r7.z) * r7.z + 1);
			r2.w = asint(sqrt(asfloat(r2.w)));
			r0.w = asint(asfloat(r2.w) / asfloat(r0.w));
			r0.w = r0.w & r1.w;
			r7.xy = asfloat(r0.ww) * r6.xy;
			r3 = r3.xyz + float3(-128, -128, -128);
			r3 = asfloat(r0.xxx) * r3.xyz;
			r3 = r3.xyz * float3(0.00390625, 0.00390625, 0.00390625);
			r0.w = asint(dot(r6.zw, r6.zw));
			r1.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r0.w = asint(sqrt(asfloat(r0.w)));
			r0.w = r0.w & r1.w;
			r1.w = asint(-(asfloat(r0.w)) * 2 + 1);
			r8.z = max(asfloat(r1.w), -1);
			r1.w = (r8.z < 1) ? -1 : 0;
			r2.w = (-1 < r8.z) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = asint(-(r8.z) * r8.z + 1);
			r2.w = asint(sqrt(asfloat(r2.w)));
			r0.w = asint(asfloat(r2.w) / asfloat(r0.w));
			r0.w = r0.w & r1.w;
			r8.xy = asfloat(r0.ww) * r6.zw;
			r6.xyz = r8.xyz + float3(0.00000000999999994, 0.00000000999999994, 0.00000000999999994);
			r4 = r4.xyz + float3(-128, -128, -128);
			r4 = asfloat(r0.xxx) * r4.xyz;
			r6.xyz = -(r7.xyz) + r6.xyz;
			r4 = r4.xyz * float3(0.00390625, 0.00390625, 0.00390625) + -(r3.xyz);
			r0.w = asint(dot(r4.xyz, i.normal.xyz));
			r1.w = asint(dot(r6.xyz, r6.xyz));
			r2.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r0.w = asint(-(asfloat(r0.w)) / asfloat(r1.w));
			r4 = r6.xyz * asfloat(r0.www) + i.normal.xyz;
			r4 = (r2.www != 0) ? r4.xyz : i.normal.xyz;
			r0.yz = asint(asfloat(r0.yz) + float2(-0.5, -0.492109388));
			r0.yz = asint(asfloat(r0.yz) + asfloat(r0.yz));
			r0.w = asint(dot(asfloat(r0.yz), asfloat(r0.yz)));
			r1.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r0.w = asint(sqrt(asfloat(r0.w)));
			r0.w = r0.w & r1.w;
			r1.w = asint(-(asfloat(r0.w)) * 2 + 1);
			r6.z = max(asfloat(r1.w), -1);
			r1.w = (r6.z < 1) ? -1 : 0;
			r2.w = (-1 < r6.z) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = asint(-(r6.z) * r6.z + 1);
			r2.w = asint(sqrt(asfloat(r2.w)));
			r0.w = asint(asfloat(r2.w) / asfloat(r0.w));
			r0.w = r0.w & r1.w;
			r6.xy = asfloat(r0.ww) * asfloat(r0.yz);
			r0.yzw = asint(r5.xyz + float3(-128, -128, -128));
			r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
			r5 = -(r7.xyz) + r6.xyz;
			r0.xyz = asint(asfloat(r0.xyz) * float3(0.00390625, 0.00390625, 0.00390625) + -(r3.xyz));
			r0.x = asint(dot(asfloat(r0.xyz), i.normal.xyz));
			r0.y = asint(dot(r5.xyz, r5.xyz));
			r0.z = (0 < asfloat(r0.y)) ? -1 : 0;
			r0.x = asint(-(asfloat(r0.x)) / asfloat(r0.y));
			r0.xyw = asint(r5.xyz * asfloat(r0.xxx) + r4.xyz);
			r0.xyz = (r0.zzz != 0) ? r0.xyw : asint(r4.xyz);
			r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
			r0.w = asint(sqrt(asfloat(r0.w)));
			r2.xyz = asint(asfloat(r0.xyz) / asfloat(r0.www));
		}
	} else {
		r1.xyz = asint(i.position.xyz);
		r2.xyz = asint(i.normal.xyz);
	}
	r0.xyz = asint(-(asfloat(r1.xyz)) + i.position.xyz);
	r0.x = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.x = asint(sqrt(asfloat(r0.x)));
	r0.yzw = asint(asfloat(r1.yyy) * gWorld[1].xyz);
	r0.yzw = asint(asfloat(r1.xxx) * gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r1.zzz) * gWorld[2].xyz + asfloat(r0.yzw));
	o.texcoord6.xyz = asfloat(r0.yzw) + gWorld[3].xyz;
	r0.yzw = asint(asfloat(r2.yyy) * gWorld[1].xyz);
	r0.yzw = asint(asfloat(r2.xxx) * gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r2.zzz) * gWorld[2].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r0.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	o.texcoord1.xyz = asfloat(r0.yzw) * asfloat(r1.www);
	r0.x = asint(min(asfloat(r0.x), 0.0399999991));
	r2.xyz = asint(i.color.xyz);
	r2.w = 1065353216;
	o.texcoord2 = asfloat(r0.x) * float4(6, 6, 6, 6) + asfloat(r2);
	r0 = asint(asfloat(r1.y) * gWorldViewProj[1]);
	r0 = asint(asfloat(r1.x) * gWorldViewProj[0] + asfloat(r0));
	r0 = asint(asfloat(r1.z) * gWorldViewProj[2] + asfloat(r0));
	r0 = asint(asfloat(r0) + gWorldViewProj[3]);
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	o.texcoord6.w = 1;
	o.texcoord = i.texcoord.xy;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	int4 r2;
	float3 r3;
	float3 r4;
	float3 r5;
	float4 r6;
	float3 r7;
	float3 r8;
	if (Temporal_b13_o0_switchOn != 0) {
		r0.x = asint(dot(i.position.xyz, i.position.xyz));
		r0.x = asint(sqrt(asfloat(r0.x)));
		r0.yzw = asint(i.position.xyz / asfloat(r0.xxx));
		r0.w = asint(-(asfloat(r0.w)) + 1);
		r0.w = asint(asfloat(r0.w) * 0.5);
		r0.yz = asint(asfloat(r0.yz) + float2(0.00000999999975, 0.00000999999975));
		r1.x = asint(dot(asfloat(r0.yz), asfloat(r0.yz)));
		r1.x = asint(rsqrt(asfloat(r1.x)));
		r0.yz = asint(asfloat(r0.yz) * asfloat(r1.xx));
		r0.yz = asint(asfloat(r0.ww) * asfloat(r0.yz));
		r0.yz = asint(asfloat(r0.yz) * float2(0.5, 0.5) + float2(0.5, 0.5));
		r1.xy = asint(asfloat(r0.yz) * float2(126.732674, 126.732674));
		r1.zw = (asfloat(r1.xy) >= -(asfloat(r1.xy))) ? -1 : 0;
		r1.xy = asint(frac(abs(asfloat(r1.xy))));
		r1.xy = (r1.zw != 0) ? r1.xy : asint(-(asfloat(r1.xy)));
		r0.w = asint(TemporalResource_t1_DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r0.yz), 0).x);
		r0.yz = asint(-(asfloat(r1.xy)) * float2(0.00789062493, 0.00789062493) + asfloat(r0.yz));
		r2 = asint(asfloat(r0.yzyz) + float4(0.00789062493, 0, 0, 0.00789062493));
		r1.z = asint(TemporalResource_t1_DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.xy), 0).x);
		r1.w = asint(TemporalResource_t1_DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.zw), 0).x);
		r2.xy = asint(asfloat(r0.yz) + float2(0.00789062493, 0.00789062493));
		r2.x = asint(TemporalResource_t1_DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.xy), 0).x);
		r2.y = asint(asfloat(r0.w) * 0.0000152587891);
		r3.z = trunc(asfloat(r2.y));
		r0.w = asint(-(r3.z) * 65536 + asfloat(r0.w));
		r2.y = asint(asfloat(r0.w) * 0.00390625);
		r3.y = trunc(asfloat(r2.y));
		r3.x = -(r3.y) * 256 + asfloat(r0.w);
		r0.w = asint(asfloat(r1.z) * 0.0000152587891);
		r4.z = trunc(asfloat(r0.w));
		r0.w = asint(-(r4.z) * 65536 + asfloat(r1.z));
		r1.z = asint(asfloat(r0.w) * 0.00390625);
		r4.y = trunc(asfloat(r1.z));
		r4.x = -(r4.y) * 256 + asfloat(r0.w);
		r0.w = asint(asfloat(r1.w) * 0.0000152587891);
		r5.z = trunc(asfloat(r0.w));
		r0.w = asint(-(r5.z) * 65536 + asfloat(r1.w));
		r1.z = asint(asfloat(r0.w) * 0.00390625);
		r5.y = trunc(asfloat(r1.z));
		r5.x = -(r5.y) * 256 + asfloat(r0.w);
		r0.w = asint(asfloat(r2.x) * 0.0000152587891);
		r6.z = trunc(asfloat(r0.w));
		r0.w = asint(-(r6.z) * 65536 + asfloat(r2.x));
		r1.z = asint(asfloat(r0.w) * 0.00390625);
		r6.y = trunc(asfloat(r1.z));
		r6.x = -(r6.y) * 256 + asfloat(r0.w);
		r1.zw = asint(-(asfloat(r1.xy)) + float2(1, 1));
		r2.xyz = asint(asfloat(r1.zzz) * r3.xyz);
		r7 = asfloat(r1.xxx) * r4.xyz;
		r7 = asfloat(r1.www) * r7.xyz;
		r2.xyz = asint(asfloat(r2.xyz) * asfloat(r1.www) + r7.xyz);
		r7 = asfloat(r1.zzz) * r5.xyz;
		r2.xyz = asint(r7.xyz * asfloat(r1.yyy) + asfloat(r2.xyz));
		r1.xzw = asint(asfloat(r1.xxx) * r6.xyz);
		r1.xyz = asint(asfloat(r1.xzw) * asfloat(r1.yyy) + asfloat(r2.xyz));
		r1.xyz = asint(asfloat(r1.xyz) + float3(-128, -128, -128));
		r1.xyz = asint(asfloat(r1.xyz) * float3(0.0078125, 0.0078125, 0.0078125));
		r0.x = asint(asfloat(r0.x) / Temporal_b4_o0_BoundRadius);
		r0.x = asint(min(asfloat(r0.x), 1));
		r1.xyz = asint(asfloat(r0.xxx) * asfloat(r1.xyz));
		r1.xyz = asint(asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + i.position.xyz);
		r2.xyz = (i.normal.xyz == float3(1, 1, 1)) ? -1 : 0;
		r0.w = r2.y & r2.x;
		r0.w = r2.z & r0.w;
		if (r0.w != 0) {
			r2.xyz = int3(0, 0, 1065353216);
		} else {
			r6 = asfloat(r0.yzyz) + float4(-0.5, -0.5, -0.492109388, -0.5);
			r6 = r6 + r6;
			r0.w = asint(dot(r6.xy, r6.xy));
			r1.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r0.w = asint(sqrt(asfloat(r0.w)));
			r0.w = r0.w & r1.w;
			r1.w = asint(-(asfloat(r0.w)) * 2 + 1);
			r7.z = max(asfloat(r1.w), -1);
			r1.w = (r7.z < 1) ? -1 : 0;
			r2.w = (-1 < r7.z) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = asint(-(r7.z) * r7.z + 1);
			r2.w = asint(sqrt(asfloat(r2.w)));
			r0.w = asint(asfloat(r2.w) / asfloat(r0.w));
			r0.w = r0.w & r1.w;
			r7.xy = asfloat(r0.ww) * r6.xy;
			r3 = r3.xyz + float3(-128, -128, -128);
			r3 = asfloat(r0.xxx) * r3.xyz;
			r3 = r3.xyz * float3(0.00390625, 0.00390625, 0.00390625);
			r0.w = asint(dot(r6.zw, r6.zw));
			r1.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r0.w = asint(sqrt(asfloat(r0.w)));
			r0.w = r0.w & r1.w;
			r1.w = asint(-(asfloat(r0.w)) * 2 + 1);
			r8.z = max(asfloat(r1.w), -1);
			r1.w = (r8.z < 1) ? -1 : 0;
			r2.w = (-1 < r8.z) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = asint(-(r8.z) * r8.z + 1);
			r2.w = asint(sqrt(asfloat(r2.w)));
			r0.w = asint(asfloat(r2.w) / asfloat(r0.w));
			r0.w = r0.w & r1.w;
			r8.xy = asfloat(r0.ww) * r6.zw;
			r6.xyz = r8.xyz + float3(0.00000000999999994, 0.00000000999999994, 0.00000000999999994);
			r4 = r4.xyz + float3(-128, -128, -128);
			r4 = asfloat(r0.xxx) * r4.xyz;
			r6.xyz = -(r7.xyz) + r6.xyz;
			r4 = r4.xyz * float3(0.00390625, 0.00390625, 0.00390625) + -(r3.xyz);
			r0.w = asint(dot(r4.xyz, i.normal.xyz));
			r1.w = asint(dot(r6.xyz, r6.xyz));
			r2.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r0.w = asint(-(asfloat(r0.w)) / asfloat(r1.w));
			r4 = r6.xyz * asfloat(r0.www) + i.normal.xyz;
			r4 = (r2.www != 0) ? r4.xyz : i.normal.xyz;
			r0.yz = asint(asfloat(r0.yz) + float2(-0.5, -0.492109388));
			r0.yz = asint(asfloat(r0.yz) + asfloat(r0.yz));
			r0.w = asint(dot(asfloat(r0.yz), asfloat(r0.yz)));
			r1.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r0.w = asint(sqrt(asfloat(r0.w)));
			r0.w = r0.w & r1.w;
			r1.w = asint(-(asfloat(r0.w)) * 2 + 1);
			r6.z = max(asfloat(r1.w), -1);
			r1.w = (r6.z < 1) ? -1 : 0;
			r2.w = (-1 < r6.z) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = asint(-(r6.z) * r6.z + 1);
			r2.w = asint(sqrt(asfloat(r2.w)));
			r0.w = asint(asfloat(r2.w) / asfloat(r0.w));
			r0.w = r0.w & r1.w;
			r6.xy = asfloat(r0.ww) * asfloat(r0.yz);
			r0.yzw = asint(r5.xyz + float3(-128, -128, -128));
			r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
			r5 = -(r7.xyz) + r6.xyz;
			r0.xyz = asint(asfloat(r0.xyz) * float3(0.00390625, 0.00390625, 0.00390625) + -(r3.xyz));
			r0.x = asint(dot(asfloat(r0.xyz), i.normal.xyz));
			r0.y = asint(dot(r5.xyz, r5.xyz));
			r0.z = (0 < asfloat(r0.y)) ? -1 : 0;
			r0.x = asint(-(asfloat(r0.x)) / asfloat(r0.y));
			r0.xyw = asint(r5.xyz * asfloat(r0.xxx) + r4.xyz);
			r0.xyz = (r0.zzz != 0) ? r0.xyw : asint(r4.xyz);
			r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
			r0.w = asint(sqrt(asfloat(r0.w)));
			r2.xyz = asint(asfloat(r0.xyz) / asfloat(r0.www));
		}
	} else {
		r1.xyz = asint(i.position.xyz);
		r2.xyz = asint(i.normal.xyz);
	}
	r0.xyz = asint(-(asfloat(r1.xyz)) + i.position.xyz);
	r0.x = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.x = asint(sqrt(asfloat(r0.x)));
	r0.yzw = asint(asfloat(r1.yyy) * Temporal_b0_o0_gWorld[1].xyz);
	r0.yzw = asint(asfloat(r1.xxx) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r1.zzz) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.yzw));
	o.texcoord6.xyz = asfloat(r0.yzw) + Temporal_b0_o0_gWorld[3].xyz;
	r0.yzw = asint(asfloat(r2.yyy) * Temporal_b0_o0_gWorld[1].xyz);
	r0.yzw = asint(asfloat(r2.xxx) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r2.zzz) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r0.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	o.texcoord1.xyz = asfloat(r0.yzw) * asfloat(r1.www);
	r0.x = asint(min(asfloat(r0.x), 0.0399999991));
	r2.xyz = asint(i.color.xyz);
	r2.w = 1065353216;
	o.texcoord2 = asfloat(r0.x) * float4(6, 6, 6, 6) + asfloat(r2);
	r0 = asint(asfloat(r1.y) * Temporal_b0_o128_gWorldViewProj[1]);
	r0 = asint(asfloat(r1.x) * Temporal_b0_o128_gWorldViewProj[0] + asfloat(r0));
	r0 = asint(asfloat(r1.z) * Temporal_b0_o128_gWorldViewProj[2] + asfloat(r0));
	r0 = asint(asfloat(r0) + Temporal_b0_o128_gWorldViewProj[3]);
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	o.texcoord6.w = 1;
	o.texcoord = i.texcoord.xy;

	return o;
}

VS_OUT main(VS_IN i)
{
    VS_OUT o = TemporalCurrent(i);
    o.temporalPrevious = float3(0, 0, -1);

    [branch] if (TemporalState.x > 0)
    {
        o.temporalPrevious = TemporalVertexPrevious(i).sv_position.xyw;
    }
    return o;
}
