float4 dofProj : register(c132);
row_major float4x4 gViewInverse : register(c12);

struct VS_IN
{
	float4 position : POSITION;
	float4 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 position : POSITION;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	r0.xy = dofProj.zw * i.position.xy;
	r0.yzw = -r0.yyy * gViewInverse[1].xyz;
	r0.xyz = -r0.xxx * gViewInverse[0].xyz + r0.yzw;
	o.texcoord1.xyz = r0.xyz + gViewInverse[2].xyz;
	o.position = i.position.xyzx * float4(1, 1, 1, 0) + float4(0, 0, 0, 1);
	o.texcoord = i.texcoord.xy;
	o.texcoord1.w = 1;

	return o;
}
