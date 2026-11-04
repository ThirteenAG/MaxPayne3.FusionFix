float4 TransPos : register(c131);
float4 TransTex0 : register(c132);
float4 dofProj : register(c136);
row_major float4x4 gViewInverse : register(c12);

struct VS_OUT
{
	float4 position : POSITION;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
};

VS_OUT main(float4 position : POSITION)
{
	VS_OUT o;

	float4 r0;
	o.texcoord = position.xy * TransTex0.xy + TransTex0.zw;
	r0.xy = position.xy * TransPos.xy + TransPos.zw;
	r0.zw = r0.xy * dofProj.zw;
	o.position.xy = r0.xy;
	r0.xyw = -r0.www * gViewInverse[1].xyz;
	r0.xyz = -r0.zzz * gViewInverse[0].xyz + r0.xyw;
	o.texcoord1.xyz = r0.xyz + gViewInverse[2].xyz;
	o.position.zw = float2(0.1, 1);
	o.texcoord1.w = 1;

	return o;
}
