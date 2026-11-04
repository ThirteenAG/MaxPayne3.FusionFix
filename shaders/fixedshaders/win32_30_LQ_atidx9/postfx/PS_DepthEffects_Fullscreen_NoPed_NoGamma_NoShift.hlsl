sampler2D GBufferTextureSamplerDepth : register(s3);
sampler2D HDRSampler : register(s5);
float4 deSatContrastGamma : register(c46);
float4 dofProj : register(c136);
float4 gAdrenoFXVars : register(c68);
float4 globalFogColorN : register(c50);
float4 globalFogParams : register(c37);

struct PS_IN
{
	float2 texcoord : TEXCOORD;
	float3 texcoord1 : TEXCOORD1;
};

float4 main(PS_IN i) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float3 r2;
	r0 = tex2D(GBufferTextureSamplerDepth, i.texcoord.xy);
	r0.y = -dofProj.x + dofProj.y;
	r0.y = 1 / r0.y;
	r0.x = dofProj.y * -r0.y + r0.x;
	r0.y = r0.y * dofProj.y;
	r0.y = r0.y * -dofProj.x;
	r0.x = 1 / r0.x;
	r0.x = r0.x * r0.y;
	r0.xyz = -r0.xxx * i.texcoord1.xyz;
	r0.w = r0.z * globalFogParams.x;
	r0.x = dot(r0.xyz, r0.xyz);
	r0.x = rsqrt(r0.x);
	r0.x = 1 / r0.x;
	r0.x = r0.x * globalFogParams.z;
	r0.y = r0.w * -1.442695;
	r0.y = exp2(r0.y);
	r0.z = r0.y + -65504;
	r0.y = -r0.y + 1;
	r0.y = (r0.z >= 0) ? -65503 : r0.y;
	r0.z = 1 / r0.w;
	r0.w = -abs(r0.w) + 0.0001;
	r0.y = r0.z * r0.y;
	r0.y = r0.y * r0.x;
	r0.x = (r0.w >= 0) ? r0.x : r0.y;
	r0.x = r0.x * -globalFogParams.y;
	r0.x = r0.x * 1.442695;
	r0.x = saturate(exp2(r0.x));
	r1 = tex2D(HDRSampler, i.texcoord.xy);
	r2 = lerp(globalFogColorN.xyz, r1.xyz, r0.xxx);
	o.w = r1.w;
	r0.x = dot(r2.xyz, float3(0.2125, 0.7154, 0.0721));
	r0.yzw = -r0.xxx + r2.xyz;
	r1.x = gAdrenoFXVars.x;
	r1.x = r1.x * deSatContrastGamma.x;
	o.xyz = r1.xxx * r0.yzw + r0.xxx;

	return o;
}
