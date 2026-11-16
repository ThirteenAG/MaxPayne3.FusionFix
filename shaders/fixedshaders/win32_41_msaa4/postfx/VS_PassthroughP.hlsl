cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
	float4 TransColor : packoffset(c130);
	float4 TransPos : packoffset(c131);
	float4 TransTex0 : packoffset(c132);
	float4 TransTex1 : packoffset(c133);
	float4 TransTex2 : packoffset(c134);
	float2 BrightnessSetting : packoffset(c135);
	float4 dofProj : packoffset(c136);
};

cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
};

VS_OUT main(float2 position : POSITION)
{
	VS_OUT o;

	float4 r0;
	o.sv_position.zw = float2(0.100000001, 1);
	r0.xy = position.xy * TransPos.xy + TransPos.zw;
	o.sv_position.xy = r0.xy;
	r0.xy = r0.xy * dofProj.zw;
	o.texcoord = position.xy * TransTex0.xy + TransTex0.zw;
	r0.yzw = -(r0.yyy) * gViewInverse[1].xyz;
	r0.xyz = -(r0.xxx) * gViewInverse[0].xyz + r0.yzw;
	o.texcoord1.xyz = r0.xyz + gViewInverse[2].xyz;
	o.texcoord1.w = 1;

	return o;
}
