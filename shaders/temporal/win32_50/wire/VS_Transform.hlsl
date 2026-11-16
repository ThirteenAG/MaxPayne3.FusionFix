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
	float4 r1;
	float4 r2;
	float4 r3;
	r0.xyz = asint(i.position.xyz + i.normal.xyz);
	r0.yw = asint(asfloat(r0.yy) * gWorldViewProj[1].xy);
	r0.xy = asint(asfloat(r0.xx) * gWorldViewProj[0].xy + asfloat(r0.yw));
	r0.xy = asint(asfloat(r0.zz) * gWorldViewProj[2].xy + asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.xy) + gWorldViewProj[3].xy);
	r1 = i.position.y * gWorldViewProj[1];
	r1 = i.position.x * gWorldViewProj[0] + r1;
	r1 = i.position.z * gWorldViewProj[2] + r1;
	r1 = r1 + gWorldViewProj[3];
	r0.xy = asint(-(asfloat(r0.xy)) + r1.xy);
	r0.xy = asint(asfloat(r0.xy) * float2(-0.00200000009, -0.00200000009));
	r2.xyz = i.position.yyy * gWorld[1].xyz;
	r2.xyz = i.position.xxx * gWorld[0].xyz + r2.xyz;
	r2.xyz = i.position.zzz * gWorld[2].xyz + r2.xyz;
	r2.xyz = r2.xyz + gWorld[3].xyz;
	r3.xyz = r2.xyz + -(gViewInverse[3].xyz);
	r0.z = asint(dot(r3.xyz, r3.xyz));
	r0.w = asint(r3.z * globalFogParams.x);
	r0.z = asint(sqrt(asfloat(r0.z)));
	r3.xy = asfloat(r0.xy) * asfloat(r0.zz) + r1.xy;
	r0.x = asint(asfloat(r0.z) * globalFogParams.z);
	r3.zw = r1.zw;
	o.sv_position = r3;
	o.texcoord8 = r3;
	o.texcoord1.w = r3.w;
	r0.y = asint(dot(i.color.xy, globalDayNightEffects.zw));
	r0.y = asint(asfloat(r0.y) * globalScalars.z + -1);
	r0.y = asint(gAmbientOcclusionEffect.x * asfloat(r0.y) + 1);
	o.color.xy = asfloat(r0.yy) * gAmbientOcclusionEffect.yy;
	o.color.zw = i.color.zw;
	r3.xy = i.texcoord.xy;
	r3.z = 1;
	o.texcoord.x = dot(globalAnimUV0.xyz, r3.xyz);
	o.texcoord.y = dot(globalAnimUV1.xyz, r3.xyz);
	r3.xyz = i.normal.yyy * gWorld[1].xyz;
	r3.xyz = i.normal.xxx * gWorld[0].xyz + r3.xyz;
	r3.xyz = i.normal.zzz * gWorld[2].xyz + r3.xyz;
	r3.xyz = r3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.y = asint(dot(r3.xyz, r3.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	o.texcoord1.xyz = asfloat(r0.yyy) * r3.xyz;
	r2.w = 1;
	o.texcoord6 = r2;
	r0.y = asint(dot(r2, g_vUserClipPlanes[0]));
	r0.z = asint(asfloat(r0.w) * -1.44269502);
	r0.z = asint(exp2(asfloat(r0.z)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(asfloat(r0.z) / asfloat(r0.w));
	r0.w = (0.0000999999975 < abs(asfloat(r0.w))) ? -1 : 0;
	r0.z = asint(asfloat(r0.z) * asfloat(r0.x));
	r0.x = (r0.w != 0) ? r0.z : r0.x;
	r0.x = asint(asfloat(r0.x) * -(globalFogParams.y));
	r0.x = asint(asfloat(r0.x) * 1.44269502);
	r0.x = asint(exp2(asfloat(r0.x)));
	o.texcoord9.x = -(asfloat(r0.x)) + 1;
	r0.x = asint(saturate(-(r1.w) * gDepthFxParams.z + gDepthFxParams.w));
	r0.z = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(asfloat(r0.z) * gDepthFxParams.y + asfloat(r0.x));
	o.texcoord9.y = asfloat(r0.x) + -1;
	o.texcoord9.zw = float2(0, 0);
	r0.xzw = asint(gViewInverse[0].xyz * float3(0.0700000003, 0.0700000003, 0.0700000003));
	r2.x = dot(asfloat(r0.xzw), gWorld[0].xyz);
	r2.y = dot(asfloat(r0.xzw), gWorld[1].xyz);
	r2.z = dot(asfloat(r0.xzw), gWorld[2].xyz);
	r0.xzw = asint(r2.xyz + i.position.xyz);
	r2.xy = asfloat(r0.zz) * gWorldViewProj[1].xw;
	r0.xz = asint(asfloat(r0.xx) * gWorldViewProj[0].xw + r2.xy);
	r0.xz = asint(asfloat(r0.ww) * gWorldViewProj[2].xw + asfloat(r0.xz));
	r0.xz = asint(asfloat(r0.xz) + gWorldViewProj[3].xw);
	r0.x = asint(asfloat(r0.x) / asfloat(r0.z));
	r0.z = asint(r1.x / r3.w);
	o.texcoord7.xyw = r1.xyw;
	r0.x = asint(-(asfloat(r0.z)) + asfloat(r0.x));
	r0.x = asint(asfloat(r0.x) * globalScreenSize.y);
	o.texcoord7.z = saturate(asfloat(r0.x) * 0.5);
	r0.x = asint(g_vUserClipPlanes[0].y + g_vUserClipPlanes[0].x);
	r0.x = asint(asfloat(r0.x) + g_vUserClipPlanes[0].z);
	r0.x = asint(asfloat(r0.x) + g_vUserClipPlanes[0].w);
	r0.x = (asfloat(r0.x) != 0) ? -1 : 0;
	o.sv_clipdistance = (r0.x != 0) ? asfloat(r0.y) : 1;

	return o;
}
