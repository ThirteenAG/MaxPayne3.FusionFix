sampler2D GBufferTextureSamplerDepth : register(s3);
sampler2D HDRSampler : register(s5);
float4 dofProj : register(c132);
float4 gDepthFxParams : register(c18);
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
	r0.x = -dofProj.x + dofProj.y;
	r0.x = 1 / r0.x;
	r0.y = r0.x * dofProj.y;
	r0.y = r0.y * -dofProj.x;
	r1 = tex2D(GBufferTextureSamplerDepth, i.texcoord.xy);
	r0.x = dofProj.y * -r0.x + r1.x;
	r0.z = r1.x + -1;
	r0.z = (r0.z >= 0) ? 1 : 0;
	r0.x = 1 / r0.x;
	r0.x = r0.x * r0.y;
	r1.xyz = -r0.xxx * i.texcoord1.xyz;
	r0.x = saturate(-r0.x * gDepthFxParams.z + gDepthFxParams.w);
	r0.x = saturate(r0.z + r0.x);
	r0.y = r1.z * globalFogParams.x;
	r0.z = dot(r1.xyz, r1.xyz);
	r0.z = rsqrt(r0.z);
	r0.z = 1 / r0.z;
	r0.z = r0.z * globalFogParams.z;
	r0.w = r0.y * -1.442695;
	r0.w = exp2(r0.w);
	r1.x = r0.w + -65504;
	r0.w = -r0.w + 1;
	r0.w = (r1.x >= 0) ? -65503 : r0.w;
	r1.x = 1 / r0.y;
	r0.y = -abs(r0.y) + 0.0001;
	r0.w = r0.w * r1.x;
	r0.w = r0.w * r0.z;
	r0.y = (r0.y >= 0) ? r0.z : r0.w;
	r0.y = r0.y * -globalFogParams.y;
	r0.y = r0.y * 1.442695;
	r0.y = saturate(exp2(r0.y));
	r0.z = -r0.x + 1;
	r0.xz = r0.zz * gDepthFxParams.xy + r0.xx;
	r1 = tex2D(HDRSampler, i.texcoord.xy);
	r0.w = dot(r1.xyz, float3(0.2125, 0.7154, 0.0721));
	r2 = lerp(r0.www, r1.xyz, r0.xxx);
	r0.x = r0.z + -0.99999;
	r0.z = r0.w + 1E-05;
	r0.z = abs(r0.z) + 1E-05;
	r1.w = pow(r0.z, r0.x);
	r0.xzw = r2.xyz * r1.www + -globalFogColorN.xyz;
	r0.xyz = r0.yyy * r0.xzw + globalFogColorN.xyz;
	r0.xyz = -r1.xyz + r0.xyz;
	o.xyz = r0.xyz * 0.5 + 0.5;
	o.w = 1;

	return o;
}
