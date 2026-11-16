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

cbuffer UserClipPlanes : register(b6)
{
	float4 g_vUserClipPlanes[8] : packoffset(c0);
};

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
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float4 texcoord6 : TEXCOORD6;
	float4 texcoord9 : TEXCOORD9;
	float sv_clipdistance : SV_ClipDistance;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	r0 = asint(i.position.y * gWorldViewProj[1]);
	r0 = asint(i.position.x * gWorldViewProj[0] + asfloat(r0));
	r0 = asint(i.position.z * gWorldViewProj[2] + asfloat(r0));
	r0 = asint(asfloat(r0) + gWorldViewProj[3]);
	o.sv_position = asfloat(r0);
	r0.x = asint(dot(i.color.xy, globalDayNightEffects.zw));
	r0.x = asint(asfloat(r0.x) * globalScalars.z + -1);
	r0.x = asint(gAmbientOcclusionEffect.x * asfloat(r0.x) + 1);
	o.color.xy = asfloat(r0.xx) * gAmbientOcclusionEffect.yy;
	o.color.zw = i.color.zw;
	o.texcoord = i.texcoord.xy;
	r0.xyz = asint(i.normal.yyy * gWorld[1].xyz);
	r0.xyz = asint(i.normal.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.normal.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.x = dot(asfloat(r0.xyz), asfloat(r0.xyz));
	r1.x = rsqrt(r1.x);
	o.texcoord1.xyz = asfloat(r0.xyz) * r1.xxx;
	o.texcoord1.w = asfloat(r0.w);
	r0.x = asint(saturate(-(asfloat(r0.w)) * gDepthFxParams.z + gDepthFxParams.w));
	r0.yzw = asint(i.position.yyy * gWorld[1].xyz);
	r0.yzw = asint(i.position.xxx * gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(i.position.zzz * gWorld[2].xyz + asfloat(r0.yzw));
	r1.xyz = asfloat(r0.yzw) + gWorld[3].xyz;
	o.texcoord3 = -(r1.xyz) + gViewInverse[3].xyz;
	r1.w = 1;
	o.texcoord6 = r1;
	r0.y = asint(dot(r1, g_vUserClipPlanes[0]));
	r1.xyz = r1.xyz + -(gViewInverse[3].xyz);
	r0.z = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(asfloat(r0.z) * gDepthFxParams.y + asfloat(r0.x));
	o.texcoord9.y = asfloat(r0.x) + -1;
	r0.x = asint(r1.z * globalFogParams.x);
	r0.z = asint(dot(r1.xyz, r1.xyz));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r0.z = asint(asfloat(r0.z) * globalFogParams.z);
	r0.w = asint(asfloat(r0.x) * -1.44269502);
	r0.w = asint(exp2(asfloat(r0.w)));
	r0.w = asint(-(asfloat(r0.w)) + 1);
	r0.w = asint(asfloat(r0.w) / asfloat(r0.x));
	r0.x = (0.0000999999975 < abs(asfloat(r0.x))) ? -1 : 0;
	r0.w = asint(asfloat(r0.w) * asfloat(r0.z));
	r0.x = (r0.x != 0) ? r0.w : r0.z;
	r0.x = asint(asfloat(r0.x) * -(globalFogParams.y));
	r0.x = asint(asfloat(r0.x) * 1.44269502);
	r0.x = asint(exp2(asfloat(r0.x)));
	o.texcoord9.x = -(asfloat(r0.x)) + 1;
	o.texcoord9.zw = float2(0, 0);
	r0.x = asint(g_vUserClipPlanes[0].y + g_vUserClipPlanes[0].x);
	r0.x = asint(asfloat(r0.x) + g_vUserClipPlanes[0].z);
	r0.x = asint(asfloat(r0.x) + g_vUserClipPlanes[0].w);
	r0.x = (asfloat(r0.x) != 0) ? -1 : 0;
	o.sv_clipdistance = (r0.x != 0) ? asfloat(r0.y) : 1;

	return o;
}
