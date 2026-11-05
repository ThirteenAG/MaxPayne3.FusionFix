struct PS_IN
{
	float4 sv_position : SV_Position;
	float3 texcoord : TEXCOORD;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int2 r0;
	r0 = asint(i.texcoord.yz * float2(100, 100));
	r0.x = asint(sin(asfloat(r0.x)));
	r0.y = asint(cos(asfloat(r0.y)));
	r0.x = asint(asfloat(r0.y) + asfloat(r0.x));
	r0.y = (0.501960814 >= asfloat(r0.x)) ? -1 : 0;
	if (r0.y != 0) discard;
	o.xyz = i.texcoord.xxx;
	o.w = asfloat(r0.x);

	return o;
}
