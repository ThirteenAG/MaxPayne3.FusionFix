sampler2D GBufferTextureSamplerDepth : register(s3);
sampler2D HDRSampler : register(s5);
sampler2D HeatHazeSampler : register(s12);
float4 HeightFogParams : register(c190);
float4 dofProj : register(c132);
float4 gDepthFxParams : register(c18);
row_major float4x4 gViewInverse : register(c12);
float4 globalFogColor : register(c38);
float4 globalFogColorN : register(c50);
float4 globalFogOffsetE : register(c39);
float4 globalFogOffsetN : register(c40);
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
	float4 r2;
	float4 r3;
	float4 r4;
	float4 r5;
	r0 = tex2D(HDRSampler, i.texcoord.xy);
	r1 = tex2D(GBufferTextureSamplerDepth, i.texcoord.xy);
	r0.w = -dofProj.x + dofProj.y;
	r0.w = 1 / r0.w;
	r1.y = r0.w * dofProj.y;
	r1.y = r1.y * -dofProj.x;
	r0.w = dofProj.y * -r0.w + r1.x;
	r0.w = 1 / r0.w;
	r1.z = r0.w * r1.y;
	r1.x = r1.x + -1;
	r1.w = (r1.x >= 0) ? 1 : 0;
	r2.xyz = 1E-05 + i.texcoord1.xyz;
	r2.y = dot(r2.xyz, r2.xyz);
	r2.y = rsqrt(r2.y);
	r2.x = r2.y * r2.x;
	r2.x = saturate(r2.x * -0.5 + 0.5);
	r2.yzw = -r1.zzz * i.texcoord1.xyz;
	r3.xyz = i.texcoord1.xyz * -r1.zzz + gViewInverse[3].xyz;
	r3.z = r3.z + -HeightFogParams.z;
	r3.w = -r3.z + HeightFogParams.y;
	r4.x = max(r3.w, abs(r2.w));
	r2.w = 1 / r4.x;
	r2.w = r2.w * r3.w;
	r2.yz = r2.ww * r2.yz;
	r2.w = -r3.w + 0.01;
	r4.x = 1 / r3.w;
	r2.w = (r2.w >= 0) ? 100 : r4.x;
	r2.w = saturate(r2.w * r3.z);
	r2.w = -r2.w + 1;
	r4.xy = 0;
	for (int i0 = 0; i0 < 3; i0++) {
		r3.z = r4.y * 0.33333334;
		r4.zw = r2.yz * -r3.zz + r3.xy;
		r4.zw = r4.zw * 0.00013;
		r5 = tex2D(HeatHazeSampler, r4.zw);
		r3.z = r2.w * r5.x;
		r4.z = -r4.y + 4;
		r4.x = r3.z * r4.z + r4.x;
		r4.y = r4.y + 1;
	}
	r2.y = r3.w * HeightFogParams.x;
	r3.y = 1;
	r2.z = r3.y + -HeightFogParams.w;
	r2.z = r4.x * HeightFogParams.w + r2.z;
	r2.y = saturate(r2.z * r2.y);
	r2.z = saturate(-r1.z * gDepthFxParams.z + gDepthFxParams.w);
	r2.z = saturate(r1.w + r2.z);
	r2.w = -r2.z + 1;
	r2.zw = r2.ww * gDepthFxParams.xy + r2.zz;
	r3.x = dot(r0.xyz, float3(0.2125, 0.7154, 0.0721));
	r4.xyz = lerp(r3.xxx, r0.xyz, r2.zzz);
	r2.z = r3.x + 1E-05;
	r2.z = abs(r2.z) + 1E-05;
	r2.w = r2.w + -0.99999;
	r3.x = pow(r2.z, r2.w);
	r3.yzw = r3.xxx * r4.xyz;
	r2.z = 1 / globalFogParams.x;
	r1.z = saturate(r1.z * r2.z);
	r0.w = r1.y * r0.w + -globalFogParams.x;
	r1.y = -globalFogParams.x + globalFogParams.y;
	r1.y = 1 / r1.y;
	r0.w = saturate(r0.w * r1.y);
	r2.z = lerp(r0.w, r1.z, globalFogParams.w);
	r1.y = r2.z + globalFogParams.z;
	r5.xyz = globalFogOffsetE.xyz;
	r2.xzw = r2.xxx * r5.xyz + -globalFogOffsetN.xyz;
	r1.x = (r1.x >= 0) ? 0 : r1.y;
	r1.x = saturate(r1.x + r2.y);
	r1.y = r1.w * globalFogColor.w;
	r4.xyz = r4.xyz * -r3.xxx + globalFogColorN.xyz;
	r1.yzw = r1.yyy * r4.xyz + r3.yzw;
	r2.xyz = r2.xzw * r0.www + globalFogColorN.xyz;
	r3.xyz = lerp(r1.yzw, r2.xyz, r1.xxx);
	r0.xyz = -r0.xyz + r3.xyz;
	o.xyz = r0.xyz * 0.5 + 0.5;
	o.w = 1;

	return o;
}
