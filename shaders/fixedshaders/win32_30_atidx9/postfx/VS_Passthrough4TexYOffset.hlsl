float4 TexelSize : register(c88);

struct VS_IN
{
	float4 position : POSITION;
	float4 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 position : POSITION;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	float2 r0;
	r0 = TexelSize.xy;
	o.texcoord.w = r0.y * -3.5 + i.texcoord.y;
	o.texcoord1.xy = r0.xy * float2(0, -2.5) + i.texcoord.xy;
	o.texcoord1.zw = r0.xy * float2(0, -1.5) + i.texcoord.xy;
	o.texcoord2.xy = r0.xy * float2(0, 1.5) + i.texcoord.xy;
	o.texcoord2.zw = r0.xy * float2(0, 2.5) + i.texcoord.xy;
	o.texcoord3.y = r0.y * 3.5 + i.texcoord.y;
	o.position = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
	o.texcoord.xyz = i.texcoord.xyx;
	o.texcoord3.xzw = i.texcoord.xxy;

	return o;
}
