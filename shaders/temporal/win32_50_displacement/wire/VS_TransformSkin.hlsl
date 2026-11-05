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

cbuffer direction_light : register(b10)
{
	float4 gDepthFxParams : packoffset(c0);
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

cbuffer UV_Anim : register(b4)
{
	float3 globalAnimUV0 : packoffset(c0);
	float3 globalAnimUV1 : packoffset(c1);
};

cbuffer UserClipPlanes : register(b6)
{
	float4 g_vUserClipPlanes[8] : packoffset(c0);
};

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
	float4 texcoord6 : TEXCOORD6;
	float4 texcoord9 : TEXCOORD9;
	float4 texcoord7 : TEXCOORD7;
	float4 texcoord8 : TEXCOORD8;
	float sv_clipdistance : SV_ClipDistance;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float3 r5;
	float4 r6;
	r0.xyz = asint(i.position.xyz + i.normal.xyz);
	r0.yw = asint(asfloat(r0.yy) * gWorldViewProj[1].xy);
	r0.xy = asint(asfloat(r0.xx) * gWorldViewProj[0].xy + asfloat(r0.yw));
	r0.xy = asint(asfloat(r0.zz) * gWorldViewProj[2].xy + asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.xy) + gWorldViewProj[3].xy);
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * gBoneMtx[r1.y / 3][1];
	r2 = gBoneMtx[r1.x / 3][1] * i.blendweight.x + r2;
	r2 = gBoneMtx[r1.z / 3][1] * i.blendweight.z + r2;
	r2 = gBoneMtx[r1.w / 3][1] * i.blendweight.w + r2;
	r3.xyz = i.position.xyz;
	r3.w = 1;
	r0.z = asint(dot(r2, r3));
	r0.w = asint(dot(r2.xyz, i.normal.xyz));
	r2.xyz = asfloat(r0.www) * gWorld[1].xyz;
	r4 = asfloat(r0.z) * gWorldViewProj[1];
	r5 = asfloat(r0.zzz) * gWorld[1].xyz;
	r6 = i.blendweight.y * gBoneMtx[r1.y / 3][0];
	r6 = gBoneMtx[r1.x / 3][0] * i.blendweight.x + r6;
	r6 = gBoneMtx[r1.z / 3][0] * i.blendweight.z + r6;
	r6 = gBoneMtx[r1.w / 3][0] * i.blendweight.w + r6;
	r0.z = asint(dot(r6, r3));
	r0.w = asint(dot(r6.xyz, i.normal.xyz));
	r2.xyz = asfloat(r0.www) * gWorld[0].xyz + r2.xyz;
	r4 = asfloat(r0.z) * gWorldViewProj[0] + r4;
	r5 = asfloat(r0.zzz) * gWorld[0].xyz + r5.xyz;
	r6 = i.blendweight.y * gBoneMtx[r1.y / 3][2];
	r6 = gBoneMtx[r1.x / 3][2] * i.blendweight.x + r6;
	r6 = gBoneMtx[r1.z / 3][2] * i.blendweight.z + r6;
	r1 = asint(gBoneMtx[r1.w / 3][2] * i.blendweight.w + r6);
	r0.z = asint(dot(asfloat(r1), r3));
	r0.w = asint(dot(asfloat(r1.xyz), i.normal.xyz));
	o.texcoord1.xyz = asfloat(r0.www) * gWorld[2].xyz + r2.xyz;
	r1 = asint(asfloat(r0.z) * gWorldViewProj[2] + r4);
	r2.xyz = asfloat(r0.zzz) * gWorld[2].xyz + r5.xyz;
	r2.xyz = r2.xyz + gWorld[3].xyz;
	r1 = asint(asfloat(r1) + gWorldViewProj[3]);
	r0.xy = asint(-(asfloat(r0.xy)) + asfloat(r1.xy));
	r0.xy = asint(asfloat(r0.xy) * float2(-0.00200000009, -0.00200000009));
	r3.xyz = r2.xyz + -(gViewInverse[3].xyz);
	o.texcoord6.xyz = r2.xyz;
	r0.z = asint(dot(r3.xyz, r3.xyz));
	r0.w = asint(r3.z * globalFogParams.x);
	r0.z = asint(sqrt(asfloat(r0.z)));
	o.sv_position.xy = asfloat(r0.xy) * asfloat(r0.zz) + asfloat(r1.xy);
	r0.x = asint(asfloat(r0.z) * globalFogParams.z);
	r0.yz = r1.zw;
	r1.x = asint(saturate(-(asfloat(r1.w)) * gDepthFxParams.z + gDepthFxParams.w));
	o.sv_position.zw = asfloat(r0.yz);
	o.texcoord1.w = asfloat(r0.z);
	r0.y = asint(dot(i.color.xy, globalDayNightEffects.zw));
	r0.y = asint(asfloat(r0.y) * globalScalars.z + -1);
	r0.y = asint(gAmbientOcclusionEffect.x * asfloat(r0.y) + 1);
	o.color.xy = asfloat(r0.yy) * gAmbientOcclusionEffect.yy;
	o.color.zw = i.color.zw;
	r2.xy = i.texcoord.xy;
	r2.z = 1;
	o.texcoord.x = dot(globalAnimUV0.xyz, r2.xyz);
	o.texcoord.y = dot(globalAnimUV1.xyz, r2.xyz);
	o.texcoord6.w = 1;
	r0.y = asint(asfloat(r0.w) * -1.44269502);
	r0.y = asint(exp2(asfloat(r0.y)));
	r0.y = asint(-(asfloat(r0.y)) + 1);
	r0.y = asint(asfloat(r0.y) / asfloat(r0.w));
	r0.z = (0.0000999999975 < abs(asfloat(r0.w))) ? -1 : 0;
	r0.y = asint(asfloat(r0.y) * asfloat(r0.x));
	r0.x = (r0.z != 0) ? r0.y : r0.x;
	r0.x = asint(asfloat(r0.x) * -(globalFogParams.y));
	r0.x = asint(asfloat(r0.x) * 1.44269502);
	r0.x = asint(exp2(asfloat(r0.x)));
	o.texcoord9.x = -(asfloat(r0.x)) + 1;
	r0.x = asint(-(asfloat(r1.x)) + 1);
	r0.x = asint(asfloat(r0.x) * gDepthFxParams.y + asfloat(r1.x));
	o.texcoord9.y = asfloat(r0.x) + -1;
	o.texcoord9.zw = float2(0, 0);
	o.texcoord7 = float4(0, 0, 0, 0);
	o.texcoord8 = float4(0, 0, 0, 0);
	r0.xyz = asint(i.position.yyy * gWorld[1].xyz);
	r0.xyz = asint(i.position.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.position.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + gWorld[3].xyz);
	r0.w = 1065353216;
	r0.x = asint(dot(asfloat(r0), g_vUserClipPlanes[0]));
	r0.y = asint(g_vUserClipPlanes[0].y + g_vUserClipPlanes[0].x);
	r0.y = asint(asfloat(r0.y) + g_vUserClipPlanes[0].z);
	r0.y = asint(asfloat(r0.y) + g_vUserClipPlanes[0].w);
	r0.y = (asfloat(r0.y) != 0) ? -1 : 0;
	o.sv_clipdistance = (r0.y != 0) ? asfloat(r0.x) : 1;

	return o;
}
