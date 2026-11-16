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

	float4 r0;
	float2 r1;
	o.position.xy = position.xy * TransPos.xy + TransPos.zw;
	r0.xy = position.xy * TransTex0.xy + TransTex0.zw;
	r1 = TexelSize.xy;
	o.texcoord1.xy = r1.xy * float2(0, -2.5) + r0.xy;
	o.texcoord1.zw = r1.xy * float2(0, -1.5) + r0.xy;
	o.texcoord2.xy = r1.xy * float2(0, 1.5) + r0.xy;
	o.texcoord2.zw = r1.xy * float2(0, 2.5) + r0.xy;
	o.texcoord3.y = r1.y * 3.5 + r0.y;
	o.position.zw = float2(0.1, 1);
	r0.w = r1.y * -3.5 + r0.y;
	o.texcoord = r0.xyxw;
	o.texcoord3.xzw = r0.xxy;

	return o;
}
