float3 radialBlurCenter : register(c194);

struct VS_OUT
{
	float4 position : POSITION;
	float2 texcoord : TEXCOORD;
	float3 texcoord1 : TEXCOORD1;
};

VS_OUT main(float4 position : POSITION)
{
	VS_OUT o;

	float4 r0;
	o.texcoord = position.xy * float2(0.5, -0.5) + 0.5;
	r0.zw = float2(1, 0);
	o.texcoord1 = position.xyx * r0.zzw + -radialBlurCenter.xyz;
	o.position = position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);

	return o;
}
