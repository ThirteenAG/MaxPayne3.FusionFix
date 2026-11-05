cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

cbuffer UserClipPlanes : register(b6)
{
	float4 g_vUserClipPlanes[8] : packoffset(c0);
};

cbuffer vehicle_switchon : register(b13)
{
	bool switchOn : packoffset(c0);
};

cbuffer CacheVehicleRadius : register(b4)
{
	float BoundRadius : packoffset(c0);
};

cbuffer Droop : register(b9)
{
	float alphaAdjust : packoffset(c0);
	float3 droopParams : packoffset(c0.y);
	float2 gravityDroop : packoffset(c1);
};

SamplerState DamageSampler : register(s1);
Texture2D DamageSampler_tex : register(t1);

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float sv_clipdistance : SV_ClipDistance;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	int4 r2;
	float4 r3;
	float4 r4;
	float4 r5;
	int4 r6;
	float4 r7;
	float3 r8;
	float3 r9;
	r0.x = asint(dot(i.position.xy, i.position.xy));
	r0.y = asint(asfloat(r0.x) * droopParams.x);
	r0.y = asint(asfloat(r0.y) * gravityDroop.x);
	r1.z = asint(-(asfloat(r0.y)) * 0.00999999978 + i.position.z);
	r1.xy = asint(i.position.xy);
	r0.yzw = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.x = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.yzw = asint(asfloat(r0.yzw) * asfloat(r1.xxx));
	r0.y = asint(dot(asfloat(r0.ywz), float3(0.707106769, 0.707106769, 0.00000707099707)));
	r0.z = asint(droopParams.y * 0.00999999978);
	r0.x = asint(asfloat(r0.x) * gravityDroop.x);
	r0.x = asint(asfloat(r0.z) * asfloat(r0.x));
	r0.y = asint(asfloat(r0.y) + gravityDroop.y);
	r0.y = asint(asfloat(r0.y) * droopParams.z);
	r0.y = asint(sin(asfloat(r0.y)));
	r0.z = asint(-(asfloat(r0.x)) * asfloat(r0.y) + asfloat(r1.z));
	if (switchOn != 0) {
		r0.xy = asint(i.position.xy);
		r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
		r0.w = asint(sqrt(asfloat(r0.w)));
		r1.xyz = asint(asfloat(r0.xyz) / asfloat(r0.www));
		r1.z = asint(-(asfloat(r1.z)) + 1);
		r1.z = asint(asfloat(r1.z) * 0.5);
		r1.xy = asint(asfloat(r1.xy) + float2(0.00000999999975, 0.00000999999975));
		r1.w = asint(dot(asfloat(r1.xy), asfloat(r1.xy)));
		r1.w = asint(rsqrt(asfloat(r1.w)));
		r1.xy = asint(asfloat(r1.ww) * asfloat(r1.xy));
		r1.xy = asint(asfloat(r1.zz) * asfloat(r1.xy));
		r1.xy = asint(asfloat(r1.xy) * float2(0.5, 0.5) + float2(0.5, 0.5));
		r1.zw = asint(asfloat(r1.xy) * float2(126.732674, 126.732674));
		r2.xy = (asfloat(r1.zw) >= -(asfloat(r1.zw))) ? -1 : 0;
		r1.zw = asint(frac(abs(asfloat(r1.zw))));
		r1.zw = (r2.xy != 0) ? r1.zw : asint(-(asfloat(r1.zw)));
		r2.x = asint(DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r1.xy), 0).x);
		r1.xy = asint(-(asfloat(r1.zw)) * float2(0.00789062493, 0.00789062493) + asfloat(r1.xy));
		r3 = asfloat(r1.xyxy) + float4(0.00789062493, 0, 0, 0.00789062493);
		r2.y = asint(DamageSampler_tex.SampleLevel(DamageSampler, r3.xy, 0).x);
		r2.z = asint(DamageSampler_tex.SampleLevel(DamageSampler, r3.zw, 0).x);
		r3.xy = asfloat(r1.xy) + float2(0.00789062493, 0.00789062493);
		r2.w = asint(DamageSampler_tex.SampleLevel(DamageSampler, r3.xy, 0).x);
		r3.x = asfloat(r2.x) * 0.0000152587891;
		r3.z = trunc(r3.x);
		r2.x = asint(-(r3.z) * 65536 + asfloat(r2.x));
		r3.w = asfloat(r2.x) * 0.00390625;
		r3.y = trunc(r3.w);
		r3.x = -(r3.y) * 256 + asfloat(r2.x);
		r2.x = asint(asfloat(r2.y) * 0.0000152587891);
		r4.z = trunc(asfloat(r2.x));
		r2.x = asint(-(r4.z) * 65536 + asfloat(r2.y));
		r2.y = asint(asfloat(r2.x) * 0.00390625);
		r4.y = trunc(asfloat(r2.y));
		r4.x = -(r4.y) * 256 + asfloat(r2.x);
		r2.x = asint(asfloat(r2.z) * 0.0000152587891);
		r5.z = trunc(asfloat(r2.x));
		r2.x = asint(-(r5.z) * 65536 + asfloat(r2.z));
		r2.y = asint(asfloat(r2.x) * 0.00390625);
		r5.y = trunc(asfloat(r2.y));
		r5.x = -(r5.y) * 256 + asfloat(r2.x);
		r2.x = asint(asfloat(r2.w) * 0.0000152587891);
		r2.z = asint(trunc(asfloat(r2.x)));
		r2.w = asint(-(asfloat(r2.z)) * 65536 + asfloat(r2.w));
		r3.w = asfloat(r2.w) * 0.00390625;
		r2.y = asint(trunc(r3.w));
		r2.x = asint(-(asfloat(r2.y)) * 256 + asfloat(r2.w));
		r6.xy = asint(-(asfloat(r1.zw)) + float2(1, 1));
		r7.xyz = r3.xyz * asfloat(r6.xxx);
		r8 = asfloat(r1.zzz) * r4.xyz;
		r8 = asfloat(r6.yyy) * r8.xyz;
		r6.yzw = asint(r7.xyz * asfloat(r6.yyy) + r8.xyz);
		r7.xyz = r5.xyz * asfloat(r6.xxx);
		r6.xyz = asint(r7.xyz * asfloat(r1.www) + asfloat(r6.yzw));
		r2.xyz = asint(asfloat(r1.zzz) * asfloat(r2.xyz));
		r2.xyz = asint(asfloat(r2.xyz) * asfloat(r1.www) + asfloat(r6.xyz));
		r2.xyz = asint(asfloat(r2.xyz) + float3(-128, -128, -128));
		r2.xyz = asint(asfloat(r2.xyz) * float3(0.0078125, 0.0078125, 0.0078125));
		r0.w = asint(asfloat(r0.w) / BoundRadius);
		r0.w = asint(min(asfloat(r0.w), 1));
		r2.xyz = asint(asfloat(r0.www) * asfloat(r2.xyz));
		r2.xyz = asint(asfloat(r2.xyz) * float3(0.5, 0.5, 0.5) + asfloat(r0.xyz));
		r6.xyz = (i.normal.xyz == float3(1, 1, 1)) ? -1 : 0;
		r1.z = r6.y & r6.x;
		r1.z = r6.z & r1.z;
		if (r1.z != 0) {
			r6.xyz = int3(0, 0, 1065353216);
		} else {
			r7 = asfloat(r1.xyxy) + float4(-0.5, -0.5, -0.492109388, -0.5);
			r7 = r7 + r7;
			r1.z = asint(dot(r7.xy, r7.xy));
			r1.w = (0 < asfloat(r1.z)) ? -1 : 0;
			r1.z = asint(sqrt(asfloat(r1.z)));
			r1.z = r1.z & r1.w;
			r1.w = asint(-(asfloat(r1.z)) * 2 + 1);
			r8.z = max(asfloat(r1.w), -1);
			r1.w = (r8.z < 1) ? -1 : 0;
			r2.w = (-1 < r8.z) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = (0 < asfloat(r1.z)) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = asint(-(r8.z) * r8.z + 1);
			r2.w = asint(sqrt(asfloat(r2.w)));
			r1.z = asint(asfloat(r2.w) / asfloat(r1.z));
			r1.z = r1.z & r1.w;
			r8.xy = asfloat(r1.zz) * r7.xy;
			r3.xyz = r3.xyz + float3(-128, -128, -128);
			r3.xyz = asfloat(r0.www) * r3.xyz;
			r3.xyz = r3.xyz * float3(0.00390625, 0.00390625, 0.00390625);
			r1.z = asint(dot(r7.zw, r7.zw));
			r1.w = (0 < asfloat(r1.z)) ? -1 : 0;
			r1.z = asint(sqrt(asfloat(r1.z)));
			r1.z = r1.z & r1.w;
			r1.w = asint(-(asfloat(r1.z)) * 2 + 1);
			r9.z = max(asfloat(r1.w), -1);
			r1.w = (r9.z < 1) ? -1 : 0;
			r2.w = (-1 < r9.z) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = (0 < asfloat(r1.z)) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = asint(-(r9.z) * r9.z + 1);
			r2.w = asint(sqrt(asfloat(r2.w)));
			r1.z = asint(asfloat(r2.w) / asfloat(r1.z));
			r1.z = r1.z & r1.w;
			r9.xy = asfloat(r1.zz) * r7.zw;
			r7.xyz = r9.xyz + float3(0.00000000999999994, 0.00000000999999994, 0.00000000999999994);
			r4.xyz = r4.xyz + float3(-128, -128, -128);
			r4.xyz = asfloat(r0.www) * r4.xyz;
			r7.xyz = -(r8.xyz) + r7.xyz;
			r4.xyz = r4.xyz * float3(0.00390625, 0.00390625, 0.00390625) + -(r3.xyz);
			r1.z = asint(dot(r4.xyz, i.normal.xyz));
			r1.w = asint(dot(r7.xyz, r7.xyz));
			r2.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r1.z = asint(-(asfloat(r1.z)) / asfloat(r1.w));
			r4.xyz = r7.xyz * asfloat(r1.zzz) + i.normal.xyz;
			r4.xyz = (r2.www != 0) ? r4.xyz : i.normal.xyz;
			r1.xy = asint(asfloat(r1.xy) + float2(-0.5, -0.492109388));
			r1.xy = asint(asfloat(r1.xy) + asfloat(r1.xy));
			r1.z = asint(dot(asfloat(r1.xy), asfloat(r1.xy)));
			r1.w = (0 < asfloat(r1.z)) ? -1 : 0;
			r1.z = asint(sqrt(asfloat(r1.z)));
			r1.z = r1.z & r1.w;
			r1.w = asint(-(asfloat(r1.z)) * 2 + 1);
			r7.z = max(asfloat(r1.w), -1);
			r1.w = (r7.z < 1) ? -1 : 0;
			r2.w = (-1 < r7.z) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = (0 < asfloat(r1.z)) ? -1 : 0;
			r1.w = r1.w & r2.w;
			r2.w = asint(-(r7.z) * r7.z + 1);
			r2.w = asint(sqrt(asfloat(r2.w)));
			r1.z = asint(asfloat(r2.w) / asfloat(r1.z));
			r1.z = r1.z & r1.w;
			r7.xy = asfloat(r1.zz) * asfloat(r1.xy);
			r1.xyz = asint(r5.xyz + float3(-128, -128, -128));
			r1.xyz = asint(asfloat(r0.www) * asfloat(r1.xyz));
			r5.xyz = -(r8.xyz) + r7.xyz;
			r1.xyz = asint(asfloat(r1.xyz) * float3(0.00390625, 0.00390625, 0.00390625) + -(r3.xyz));
			r0.w = asint(dot(asfloat(r1.xyz), i.normal.xyz));
			r1.x = asint(dot(r5.xyz, r5.xyz));
			r1.y = (0 < asfloat(r1.x)) ? -1 : 0;
			r0.w = asint(-(asfloat(r0.w)) / asfloat(r1.x));
			r1.xzw = asint(r5.xyz * asfloat(r0.www) + r4.xyz);
			r1.xyz = (r1.yyy != 0) ? r1.xzw : asint(r4.xyz);
			r0.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
			r0.w = asint(sqrt(asfloat(r0.w)));
			r6.xyz = asint(asfloat(r1.xyz) / asfloat(r0.www));
		}
	} else {
		r2.xy = asint(i.position.xy);
		r2.z = r0.z;
		r6.xyz = asint(i.normal.xyz);
	}
	r0.xy = asint(i.position.xy);
	r0.xyz = asint(-(asfloat(r2.xyz)) + asfloat(r0.xyz));
	r0.x = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.x = asint(sqrt(asfloat(r0.x)));
	r0.yzw = asint(asfloat(r2.yyy) * gWorld[1].xyz);
	r0.yzw = asint(asfloat(r2.xxx) * gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r2.zzz) * gWorld[2].xyz + asfloat(r0.yzw));
	r1.xyz = asint(asfloat(r0.yzw) + gWorld[3].xyz);
	r0.yzw = asint(asfloat(r1.xyz) + gWorld[3].xyz);
	o.texcoord3 = -(asfloat(r0.yzw)) + gViewInverse[3].xyz;
	r0.yzw = asint(asfloat(r6.yyy) * gWorld[1].xyz);
	r0.yzw = asint(asfloat(r6.xxx) * gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r6.zzz) * gWorld[2].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r0.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.w = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r0.yzw = asint(asfloat(r0.yzw) * asfloat(r2.www));
	r3.xyz = i.tangent.yyy * gWorld[1].xyz;
	r3.xyz = i.tangent.xxx * gWorld[0].xyz + r3.xyz;
	r3.xyz = i.tangent.zzz * gWorld[2].xyz + r3.xyz;
	r3.xyz = r3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.w = asint(dot(r3.xyz, r3.xyz));
	r2.w = asint(rsqrt(asfloat(r2.w)));
	r3.xyz = asfloat(r2.www) * r3.xyz;
	r4.xyz = asfloat(r0.zwy) * r3.zxy;
	r4.xyz = r3.yzx * asfloat(r0.wyz) + -(r4.xyz);
	o.texcoord5.xyz = r4.xyz * i.tangent.www;
	r0.x = asint(min(asfloat(r0.x), 0.0399999991));
	r4.xyz = i.color.xyz;
	r4.w = 1;
	r4 = asfloat(r0.x) * float4(6, 6, 6, 6) + r4;
	r5 = asfloat(r2.y) * gWorldViewProj[1];
	r5 = asfloat(r2.x) * gWorldViewProj[0] + r5;
	r2 = asint(asfloat(r2.z) * gWorldViewProj[2] + r5);
	r2 = asint(asfloat(r2) + gWorldViewProj[3]);
	o.texcoord6.w = r4.w * alphaAdjust;
	r0.x = asint(g_vUserClipPlanes[0].y + g_vUserClipPlanes[0].x);
	r0.x = asint(asfloat(r0.x) + g_vUserClipPlanes[0].z);
	r0.x = asint(asfloat(r0.x) + g_vUserClipPlanes[0].w);
	r0.x = (asfloat(r0.x) != 0) ? -1 : 0;
	r1.w = 1065353216;
	r1.w = asint(dot(asfloat(r1), g_vUserClipPlanes[0]));
	o.sv_clipdistance = (r0.x != 0) ? asfloat(r1.w) : 1;
	o.sv_position = asfloat(r2);
	o.texcoord1.w = asfloat(r2.w);
	o.texcoord1.xyz = asfloat(r0.yzw);
	o.texcoord5.w = i.tangent.w;
	o.texcoord6.xyz = r4.xyz;
	o.texcoord2 = asfloat(r1.xyz);
	o.texcoord4 = r3.xyz;
	o.texcoord = i.texcoord.xy;

	return o;
}
