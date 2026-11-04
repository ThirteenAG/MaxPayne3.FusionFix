float4 TransPos : register(c131);
float3 radialBlurCenter : register(c200);

struct VS_OUT
{
	float4 position : POSITION;
	float2 texcoord : TEXCOORD;
	float3 texcoord1 : TEXCOORD1;
};

VS_OUT main(float4 position : POSITION)
{
	VS_OUT o;

	float3 r0;
	r0.xy = position.xy * TransPos.xy + TransPos.zw;
	o.texcoord = r0.xy * float2(0.5, -0.5) + 0.5;
	r0.z = 0;
	o.texcoord1 = r0.xyz + -radialBlurCenter.xyz;
	o.position.xy = r0.xy;
	o.position.zw = float2(0.1, 1);

	return o;
}
