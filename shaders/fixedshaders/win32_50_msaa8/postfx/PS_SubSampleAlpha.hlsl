Texture2DMS<float4> gbufferTexture2 : register(t2);
Texture2DMS<float4> PostFxTexture0a : register(t6);

struct PS_IN
{
	noperspective float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	nointerpolation uint sv_sampleindex : SV_SampleIndex;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	int4 r1;
	float4 r2;
	r0.xy = asint(floor(i.sv_position.xy));
	r0.x = asint(asfloat(r0.y) + asfloat(r0.x));
	r0.x = asint(asfloat(r0.x) + 1);
	r0.x = (uint)asfloat(r0.x);
	r0.x = r0.x & 1;
	float3 dimensions0;
	gbufferTexture2.GetDimensions(dimensions0.x, dimensions0.y, dimensions0.z);
	r0.yz = asint(dimensions0.xy);
	r0.yz = asint(asfloat(r0.yz) * i.texcoord.xy);
	r1.xy = (int2)asfloat(r0.yz);
	r1.zw = int2(0, 0);
	r0.y = asint(gbufferTexture2.Load(r1.xy, i.sv_sampleindex).w);
	r0.z = (asfloat(r0.y) == 0) ? -1 : 0;
	r0.z = (r0.z != 0) ? 1065353216 : r0.y;
	r0.y = (asfloat(r0.y) != 0) ? -1 : 0;
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.x = (r0.x != 0) ? r0.w : r0.z;
	r2 = PostFxTexture0a.Load(r1.xy, i.sv_sampleindex, int2(1, 0));
	r1 = asint(PostFxTexture0a.Load(r1.xy, i.sv_sampleindex));
	r2 = -(asfloat(r1)) + r2;
	r2 = asfloat(r0.x) * r2 + asfloat(r1);
	o = (r0.y != 0) ? r2 : asfloat(r1);

	return o;
}
