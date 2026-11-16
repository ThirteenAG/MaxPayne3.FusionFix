Texture2DMS<float4> PostFxTexture0a : register(t6);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord1 : TEXCOORD1;
	float2 texcoord2 : TEXCOORD2;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	float3 dimensions0;
	PostFxTexture0a.GetDimensions(dimensions0.x, dimensions0.y, dimensions0.z);
	r0.xy = asint(dimensions0.xy);
	r0.xy = asint(asfloat(r0.xy) * i.texcoord.xy);
	r0.xy = (int2)asfloat(r0.xy);
	r0.zw = int2(0, 0);
	r0.xyz = asint(PostFxTexture0a.Load(r0.xy, 0, int2(0, 0)).xyz);
	o.xyz = min(asfloat(r0.xyz), float3(8, 8, 8));
	o.w = 1;

	return o;
}
