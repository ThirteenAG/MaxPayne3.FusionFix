sampler2D AdapLumSampler : register(s1);
float AdaptTime : register(c165);
float AdaptedLumMax : register(c146);
float AdaptedLumMin : register(c145);
sampler2D CurLumSampler : register(s0);
float ElapsedTime : register(c164);

float4 main() : COLOR
{
	float4 o;

	float4 r0;
	float2 r1;
	float4 r2;
	float r3;
	r0.x = AdaptTime.x + AdaptTime.x;
	r0.x = rsqrt(r0.x);
	r0.x = r0.x * ElapsedTime.x;
	r1.x = min(r0.x, 1);
	r0 = tex2D(AdapLumSampler, 0);
	r2 = tex2D(CurLumSampler, 0);
	r3 = lerp(r0.x, r2.x, r1.x);
	r0.x = max(r2.x, AdaptedLumMin.x);
	r1.x = min(AdaptedLumMax.x, r0.x);
	r0.x = max(r3.x, AdaptedLumMin.x);
	r1.y = min(AdaptedLumMax.x, r0.x);
	r0.y = -1;
	r0.x = r0.y + AdaptTime.x;
	o = (r0.x >= 0) ? r1.y : r1.x;

	return o;
}
