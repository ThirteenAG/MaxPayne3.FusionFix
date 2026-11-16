struct VS_IN
{
	float3 position : POSITION;
	float2 texcoord : TEXCOORD;
	float4 color : COLOR;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 color : COLOR;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	o.sv_position.xyz = i.position.xyz;
	o.sv_position.w = 1;
	o.texcoord = i.texcoord.xy;
	o.texcoord1.xy = i.position.xy * float2(0.5, -0.5) + float2(0.5, 0.5);
	o.texcoord1.zw = float2(1, 1);
	o.color = i.color;

	return o;
}
