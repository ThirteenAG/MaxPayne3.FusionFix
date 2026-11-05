cbuffer ShadowParam : register(b8)
{
	float4 gShadowParam18192021 : packoffset(c0);
	float4 gShadowParam14151617 : packoffset(c1);
};

struct PS_IN
{
	float4 sv_position : SV_Position;
	float4 texcoord1 : TEXCOORD1;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int2 r0;
	r0.x = (gShadowParam14151617.x == 0) ? -1 : 0;
	r0.x = r0.x & 1065353216;
	r0.y = asint(-(i.texcoord1.z) + 0.00999999978);
	r0.x = asint(asfloat(r0.x) * asfloat(r0.y));
	r0.x = (asfloat(r0.x) < 0) ? -1 : 0;
	if (r0.x != 0) discard;
	o = i.texcoord1.w;

	return o;
}
