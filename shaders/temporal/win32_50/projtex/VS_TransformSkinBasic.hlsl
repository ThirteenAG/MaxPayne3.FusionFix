cbuffer rage_bonemtx : register(b1)
{
	row_major float3x4 gBoneMtx[40] : packoffset(c0);
};

cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

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
	float4 globalDayNightEffects : packoffset(c9);
	float4 ColorCorrectTopAndPedReflectScale : packoffset(c10);
	float4 ColorCorrectBottomOffset : packoffset(c11);
	float4 ColorShift : packoffset(c12);
	float4 deSatContrastGamma : packoffset(c13);
	float4 deSatContrastGammaIFX : packoffset(c14);
	float4 colorize : packoffset(c15);
	float4 globalUmScalars : packoffset(c16);
	float4 gToneMapScalers : packoffset(c17);
	float4 gAmbientOcclusionEffect : packoffset(c18);
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

SamplerState DamageSampler : register(s1);
Texture2D DamageSampler_tex : register(t1);

struct VS_IN
{
	float3 position : POSITION;
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 color : COLOR;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float sv_clipdistance : SV_ClipDistance;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	int4 r2;
	int4 r3;
	float4 r4;
	float4 r5;
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
		r3.z = asint(trunc(asfloat(r2.y)));
		r0.w = asint(-(asfloat(r3.z)) * 65536 + asfloat(r0.w));
		r2.y = asint(asfloat(r0.w) * 0.00390625);
		r3.y = asint(trunc(asfloat(r2.y)));
		r3.x = asint(-(asfloat(r3.y)) * 256 + asfloat(r0.w));
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
		r2.xyz = asint(asfloat(r1.zzz) * asfloat(r3.xyz));
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
			r2.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r0.w = asint(sqrt(asfloat(r0.w)));
			r0.w = r0.w & r2.w;
			r2.w = asint(-(asfloat(r0.w)) * 2 + 1);
			r7.z = max(asfloat(r2.w), -1);
			r2.w = (r7.z < 1) ? -1 : 0;
			r3.w = (-1 < r7.z) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = asint(-(r7.z) * r7.z + 1);
			r3.w = asint(sqrt(asfloat(r3.w)));
			r0.w = asint(asfloat(r3.w) / asfloat(r0.w));
			r0.w = r0.w & r2.w;
			r7.xy = asfloat(r0.ww) * r6.xy;
			r3.xyz = asint(asfloat(r3.xyz) + float3(-128, -128, -128));
			r3.xyz = asint(asfloat(r0.xxx) * asfloat(r3.xyz));
			r3.xyz = asint(asfloat(r3.xyz) * float3(0.00390625, 0.00390625, 0.00390625));
			r0.w = asint(dot(r6.zw, r6.zw));
			r2.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r0.w = asint(sqrt(asfloat(r0.w)));
			r0.w = r0.w & r2.w;
			r2.w = asint(-(asfloat(r0.w)) * 2 + 1);
			r8.z = max(asfloat(r2.w), -1);
			r2.w = (r8.z < 1) ? -1 : 0;
			r3.w = (-1 < r8.z) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = asint(-(r8.z) * r8.z + 1);
			r3.w = asint(sqrt(asfloat(r3.w)));
			r0.w = asint(asfloat(r3.w) / asfloat(r0.w));
			r0.w = r0.w & r2.w;
			r8.xy = asfloat(r0.ww) * r6.zw;
			r6.xyz = r8.xyz + float3(0.00000000999999994, 0.00000000999999994, 0.00000000999999994);
			r4.xyz = r4.xyz + float3(-128, -128, -128);
			r4.xyz = asfloat(r0.xxx) * r4.xyz;
			r6.xyz = -(r7.xyz) + r6.xyz;
			r4.xyz = r4.xyz * float3(0.00390625, 0.00390625, 0.00390625) + -(asfloat(r3.xyz));
			r0.w = asint(dot(r4.xyz, i.normal.xyz));
			r2.w = asint(dot(r6.xyz, r6.xyz));
			r3.w = (0 < asfloat(r2.w)) ? -1 : 0;
			r0.w = asint(-(asfloat(r0.w)) / asfloat(r2.w));
			r4.xyz = r6.xyz * asfloat(r0.www) + i.normal.xyz;
			r4.xyz = (r3.www != 0) ? r4.xyz : i.normal.xyz;
			r0.yz = asint(asfloat(r0.yz) + float2(-0.5, -0.492109388));
			r0.yz = asint(asfloat(r0.yz) + asfloat(r0.yz));
			r0.w = asint(dot(asfloat(r0.yz), asfloat(r0.yz)));
			r2.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r0.w = asint(sqrt(asfloat(r0.w)));
			r0.w = r0.w & r2.w;
			r2.w = asint(-(asfloat(r0.w)) * 2 + 1);
			r6.z = max(asfloat(r2.w), -1);
			r2.w = (r6.z < 1) ? -1 : 0;
			r3.w = (-1 < r6.z) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = (0 < asfloat(r0.w)) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = asint(-(r6.z) * r6.z + 1);
			r3.w = asint(sqrt(asfloat(r3.w)));
			r0.w = asint(asfloat(r3.w) / asfloat(r0.w));
			r0.w = r0.w & r2.w;
			r6.xy = asfloat(r0.ww) * asfloat(r0.yz);
			r0.yzw = asint(r5.xyz + float3(-128, -128, -128));
			r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
			r5.xyz = -(r7.xyz) + r6.xyz;
			r0.xyz = asint(asfloat(r0.xyz) * float3(0.00390625, 0.00390625, 0.00390625) + -(asfloat(r3.xyz)));
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
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r3 = asint(i.blendweight.y * gBoneMtx[r0.y / 3][0]);
	r4 = i.blendweight.y * gBoneMtx[r0.y / 3][1];
	r5 = i.blendweight.y * gBoneMtx[r0.y / 3][2];
	r3 = asint(gBoneMtx[r0.x / 3][0] * i.blendweight.x + asfloat(r3));
	r4 = gBoneMtx[r0.x / 3][1] * i.blendweight.x + r4;
	r5 = gBoneMtx[r0.x / 3][2] * i.blendweight.x + r5;
	r3 = asint(gBoneMtx[r0.z / 3][0] * i.blendweight.z + asfloat(r3));
	r4 = gBoneMtx[r0.z / 3][1] * i.blendweight.z + r4;
	r5 = gBoneMtx[r0.z / 3][2] * i.blendweight.z + r5;
	r3 = asint(gBoneMtx[r0.w / 3][0] * i.blendweight.w + asfloat(r3));
	r4 = gBoneMtx[r0.w / 3][1] * i.blendweight.w + r4;
	r0 = asint(gBoneMtx[r0.w / 3][2] * i.blendweight.w + r5);
	r1.w = 1065353216;
	r2.w = asint(dot(asfloat(r3), asfloat(r1)));
	r3.w = asint(dot(r4, asfloat(r1)));
	r0.w = asint(dot(asfloat(r0), asfloat(r1)));
	r1.xyz = asint(asfloat(r3.www) * gWorld[1].xyz);
	r1.xyz = asint(asfloat(r2.www) * gWorld[0].xyz + asfloat(r1.xyz));
	r1.xyz = asint(asfloat(r0.www) * gWorld[2].xyz + asfloat(r1.xyz));
	r1.xyz = asint(asfloat(r1.xyz) + gWorld[3].xyz);
	o.texcoord3 = -(asfloat(r1.xyz)) + gViewInverse[3].xyz;
	r3.x = asint(dot(asfloat(r3.xyz), asfloat(r2.xyz)));
	r3.y = asint(dot(r4.xyz, asfloat(r2.xyz)));
	r0.x = asint(dot(asfloat(r0.xyz), asfloat(r2.xyz)));
	r2.xyz = asint(asfloat(r3.yyy) * gWorld[1].xyz);
	r2.xyz = asint(asfloat(r3.xxx) * gWorld[0].xyz + asfloat(r2.xyz));
	o.texcoord1.xyz = asfloat(r0.xxx) * gWorld[2].xyz + asfloat(r2.xyz);
	r3 = asint(asfloat(r3.w) * gWorldViewProj[1]);
	r2 = asint(asfloat(r2.w) * gWorldViewProj[0] + asfloat(r3));
	r0 = asint(asfloat(r0.w) * gWorldViewProj[2] + asfloat(r2));
	r0 = asint(asfloat(r0) + gWorldViewProj[3]);
	r2.x = asint(g_vUserClipPlanes[0].y + g_vUserClipPlanes[0].x);
	r2.x = asint(asfloat(r2.x) + g_vUserClipPlanes[0].z);
	r2.x = asint(asfloat(r2.x) + g_vUserClipPlanes[0].w);
	r2.x = (asfloat(r2.x) != 0) ? -1 : 0;
	r1.w = 1065353216;
	r1.x = asint(dot(asfloat(r1), g_vUserClipPlanes[0]));
	o.sv_clipdistance = (r2.x != 0) ? asfloat(r1.x) : 1;
	r1.x = asint(dot(i.color.xy, globalDayNightEffects.zw));
	r1.x = asint(asfloat(r1.x) * globalScalars.z + -1);
	r1.x = asint(gAmbientOcclusionEffect.x * asfloat(r1.x) + 1);
	o.color.xy = asfloat(r1.xx) * gAmbientOcclusionEffect.yy;
	o.sv_position = asfloat(r0);
	o.color.zw = i.color.zw;
	o.texcoord1.w = asfloat(r0.w);
	o.texcoord = i.texcoord.xy;

	return o;
}
