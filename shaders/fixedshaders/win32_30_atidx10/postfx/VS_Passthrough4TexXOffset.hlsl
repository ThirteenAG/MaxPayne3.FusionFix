float4 TexelSize : register(c88);
float4 TransPos : register(c131);
float4 TransTex0 : register(c132);

struct VS_OUT
{
	float4 position : POSITION;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
};

VS_OUT main(float4 position : POSITION)
{
	VS_OUT o;

	float3 r0;
	float2 r1;
	o.position.xy = position.xy * TransPos.xy + TransPos.zw;
	r0 = position.xyy * TransTex0.xyy + TransTex0.zww;
	r1 = TexelSize.xy;
	o.texcoord.z = r1.x * -3.5 + r0.x;
	o.texcoord1.xy = r1.xy * float2(-2.5, 0) + r0.xz;
	o.texcoord1.zw = r1.xy * float2(-1.5, 0) + r0.xz;
	o.texcoord2.xy = r1.xy * float2(1.5, 0) + r0.xz;
	o.texcoord2.zw = r1.xy * float2(2.5, 0) + r0.xz;
	o.texcoord3.xy = r1.xy * float2(3.5, 0) + r0.xz;
	o.position.zw = float2(0.1, 1);
	o.texcoord.xyw = r0.xyz;
	o.texcoord3.zw = r0.xz;

	return o;
}
