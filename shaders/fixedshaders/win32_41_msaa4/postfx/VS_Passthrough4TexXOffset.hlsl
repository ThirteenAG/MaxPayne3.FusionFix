cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
	float4 TransColor : packoffset(c130);
	float4 TransPos : packoffset(c131);
	float4 TransTex0 : packoffset(c132);
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
};

VS_OUT main(float2 position : POSITION)
{
	VS_OUT o;

	float3 r0;
	o.sv_position.xy = position.xy * TransPos.xy + TransPos.zw;
	o.sv_position.zw = float2(0.100000001, 1);
	r0 = position.xyy * TransTex0.xyy + TransTex0.zww;
	o.texcoord.z = TexelSize.x * -3.5 + r0.x;
	o.texcoord.xyw = r0.xyz;
	o.texcoord1.xy = TexelSize.xy * float2(-2.5, 0) + r0.xz;
	o.texcoord1.zw = TexelSize.xy * float2(-1.5, 0) + r0.xz;
	o.texcoord2.xy = TexelSize.xy * float2(1.5, 0) + r0.xz;
	o.texcoord2.zw = TexelSize.xy * float2(2.5, 0) + r0.xz;
	o.texcoord3.xy = TexelSize.xy * float2(3.5, 0) + r0.xz;
	o.texcoord3.zw = r0.xz;

	return o;
}
