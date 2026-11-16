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
	o.texcoord.z = r0.x * -3.5 + i.texcoord.x;
	o.texcoord1.xy = r0.xy * float2(-2.5, 0) + i.texcoord.xy;
	o.texcoord1.zw = r0.xy * float2(-1.5, 0) + i.texcoord.xy;
	o.texcoord2.xy = r0.xy * float2(1.5, 0) + i.texcoord.xy;
	o.texcoord2.zw = r0.xy * float2(2.5, 0) + i.texcoord.xy;
	o.texcoord3.xy = r0.xy * float2(3.5, 0) + i.texcoord.xy;
	o.position = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
	o.texcoord.xyw = i.texcoord.xyy;
	o.texcoord3.zw = i.texcoord.xy;

	return o;
}
