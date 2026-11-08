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

struct VS_IN
{
	float3 position : POSITION;
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float4 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 color : COLOR;
	float3 position1 : POSITION1;
	float3 normal1 : NORMAL1;
	float4 tangent1 : TANGENT1;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	float4 r6;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * gBoneMtx[r0.y / 3][1];
	r1 = gBoneMtx[r0.x / 3][1] * i.blendweight.x + r1;
	r1 = gBoneMtx[r0.z / 3][1] * i.blendweight.z + r1;
	r1 = gBoneMtx[r0.w / 3][1] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz + i.position1.xyz;
	r2.w = 1;
	r1.w = dot(r1, r2);
	r3 = r1.w * gWorldViewProj[1];
	r4 = r1.www * gWorld[1].xyz;
	r5 = i.blendweight.y * gBoneMtx[r0.y / 3][0];
	r5 = gBoneMtx[r0.x / 3][0] * i.blendweight.x + r5;
	r5 = gBoneMtx[r0.z / 3][0] * i.blendweight.z + r5;
	r5 = gBoneMtx[r0.w / 3][0] * i.blendweight.w + r5;
	r1.w = dot(r5, r2);
	r3 = r1.w * gWorldViewProj[0] + r3;
	r4 = r1.www * gWorld[0].xyz + r4.xyz;
	r6 = i.blendweight.y * gBoneMtx[r0.y / 3][2];
	r6 = gBoneMtx[r0.x / 3][2] * i.blendweight.x + r6;
	r6 = gBoneMtx[r0.z / 3][2] * i.blendweight.z + r6;
	r0 = asint(gBoneMtx[r0.w / 3][2] * i.blendweight.w + r6);
	r0.w = asint(dot(asfloat(r0), r2));
	r2 = asfloat(r0.w) * gWorldViewProj[2] + r3;
	r3.xyz = asfloat(r0.www) * gWorld[2].xyz + r4.xyz;
	r3.xyz = r3.xyz + gWorld[3].xyz;
	r2 = r2 + gWorldViewProj[3];
	o.sv_position = r2;
	o.texcoord.xy = i.texcoord.xy;
	o.texcoord.zw = float2(0, 0);
	r2.xyz = i.normal.xyz + i.normal1.xyz;
	r0.w = asint(dot(r1.xyz, r2.xyz));
	r4 = asfloat(r0.www) * gWorld[1].xyz;
	r0.w = asint(dot(r5.xyz, r2.xyz));
	r1.w = dot(asfloat(r0.xyz), r2.xyz);
	r2.xyz = asfloat(r0.www) * gWorld[0].xyz + r4.xyz;
	r2.xyz = r1.www * gWorld[2].xyz + r2.xyz;
	o.texcoord1 = r2;
	r0.w = asint(i.color.x * globalScalars.z + -1);
	r0.w = asint(gAmbientOcclusionEffect.y * asfloat(r0.w) + 1);
	r1.w = 1 / gAmbientOcclusionEffect.y;
	r0.w = asint(asfloat(r0.w) * r1.w);
	o.texcoord2.x = min(asfloat(r0.w), 1);
	o.texcoord2.z = -(i.color.y) * i.color.x + 1;
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.w = i.color.w;
	r4 = -(r3.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r3.xyz;
	o.texcoord3 = r4.xyz;
	r3 = i.tangent + i.tangent1;
	r0.w = asint(dot(r1.xyz, r3.xyz));
	r1.xyz = asfloat(r0.www) * gWorld[1].xyz;
	r0.w = asint(dot(r5.xyz, r3.xyz));
	r1.xyz = asfloat(r0.www) * gWorld[0].xyz + r1.xyz;
	r0.x = asint(dot(asfloat(r0.xyz), r3.xyz));
	r0.xyz = asint(asfloat(r0.xxx) * gWorld[2].xyz + r1.xyz);
	o.texcoord4 = asfloat(r0.xyz);
	r1.xyz = r2.yzx * asfloat(r0.zxy);
	r1.xyz = asfloat(r0.yzx) * r2.zxy + -(r1.xyz);
	o.texcoord6.z = dot(r2.xyz, r4.xyz);
	o.texcoord6.x = dot(asfloat(r0.xyz), r4.xyz);
	r0.xyz = asint(r3.www * r1.xyz);
	o.texcoord5.w = r3.w;
	o.texcoord5.xyz = asfloat(r0.xyz);
	o.texcoord6.y = dot(asfloat(r0.xyz), r4.xyz);

	return o;
}
