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
	float4 color : COLOR;
	float4 texcoord : TEXCOORD;
	float4 normal : NORMAL;
	float4 tangent : TANGENT;
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

	float4 r0;
	float4 r1;
	float3 r2;
	float3 r3;
	r0.xyz = i.position.xyz + i.position1.xyz;
	r1 = r0.y * gWorldViewProj[1];
	r1 = r0.x * gWorldViewProj[0] + r1;
	r1 = r0.z * gWorldViewProj[2] + r1;
	r1 = r1 + gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord.xy = i.texcoord.xy;
	o.texcoord.zw = float2(0, 0);
	r1.xyz = i.normal.xyz + i.normal1.xyz;
	r2 = r1.yyy * gWorld[1].xyz;
	r1.xyw = r1.xxx * gWorld[0].xyz + r2.xyz;
	r1.xyz = r1.zzz * gWorld[2].xyz + r1.xyw;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord1.xyz = r1.xyz;
	r0.w = i.color.x * globalScalars.z + -1;
	r0.w = gAmbientOcclusionEffect.y * r0.w + 1;
	r1.w = 1 / gAmbientOcclusionEffect.y;
	r0.w = r0.w * r1.w;
	o.texcoord2.x = min(r0.w, 1);
	o.texcoord2.z = -(i.color.y) * i.color.x + 1;
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.w = i.color.w;
	r2 = r0.yyy * gWorld[1].xyz;
	r0.xyw = r0.xxx * gWorld[0].xyz + r2.xyz;
	r0.xyz = r0.zzz * gWorld[2].xyz + r0.xyw;
	r0.xyz = r0.xyz + gWorld[3].xyz;
	r2 = -(r0.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r0.xyz;
	o.texcoord3 = r2.xyz;
	r0 = i.tangent + i.tangent1;
	r3 = r0.yyy * gWorld[1].xyz;
	r3 = r0.xxx * gWorld[0].xyz + r3.xyz;
	r0.xyz = r0.zzz * gWorld[2].xyz + r3.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r0.xyz, r0.xyz);
	r1.w = rsqrt(r1.w);
	r0.xyz = r0.xyz * r1.www;
	o.texcoord4 = r0.xyz;
	r3 = r1.yzx * r0.zxy;
	r3 = r0.yzx * r1.zxy + -(r3.xyz);
	o.texcoord6.z = dot(r1.xyz, r2.xyz);
	o.texcoord6.x = dot(r0.xyz, r2.xyz);
	r0.xyz = r0.www * r3.xyz;
	o.texcoord5 = r0;
	o.texcoord6.y = dot(r0.xyz, r2.xyz);

	return o;
}
