cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
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
};

cbuffer Movement : register(b4)
{
	float4 umGlobalParams : packoffset(c0);
	float4 WindGlobalParams : packoffset(c1);
};

struct VS_IN
{
	float3 position : POSITION;
	float3 normal : NORMAL;
	float4 color : COLOR;
	float4 color1 : COLOR1;
	float2 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord6 : TEXCOORD6;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	r0.x = i.color1.y * 6.28318548;
	r0.yzw = globalUmScalars.zzw * umGlobalParams.zzw;
	r0.xyz = globalScalars2.yyy * r0.yzw + r0.xxx;
	r0.xyz = sin(r0.xyz);
	r0.w = i.color1.x * globalUmScalars.x;
	r1.xy = r0.ww * umGlobalParams.xx;
	r0.w = -(i.color1.z) + 1;
	r1.w = r0.w * globalUmScalars.y;
	r0.w = r0.w * WindGlobalParams.x;
	r1.z = r1.w * umGlobalParams.y;
	r0.xyz = r0.xyz * r1.xyz + i.position.xyz;
	r1.x = r0.z * deSatContrastGamma.w;
	r0.xy = r1.xx * r0.ww + r0.xy;
	r1 = r0.y * gWorldViewProj[1];
	r1 = r0.x * gWorldViewProj[0] + r1;
	r0 = r0.z * gWorldViewProj[2] + r1;
	r0 = r0 + gWorldViewProj[3];
	o.sv_position = r0;
	o.texcoord1.w = r0.w;
	o.color = i.color;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * gWorld[1].xyz;
	r0.xyz = i.normal.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	o.texcoord1.xyz = r0.www * r0.xyz;
	r0 = i.position.y * gWorld[1];
	r0 = i.position.x * gWorld[0] + r0;
	r0 = i.position.z * gWorld[2] + r0;
	o.texcoord6 = r0 + gWorld[3];

	return o;
}
