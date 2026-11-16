sampler2D GBufferTextureSamplerDepth : register(s3);
sampler2D HDRSampler : register(s5);
float4 dofProj : register(c132);
float4 gCascadeXMaxThresholds : register(c95);
float4 gCascadeXMinThresholds : register(c94);
float4 gCascadeYMaxThresholds : register(c100);
float4 gCascadeYMinThresholds : register(c99);
row_major float4x4 gShadowMatrix : register(c57);
float4 gShadowParam18192021 : register(c49);
row_major float4x4 gViewInverse : register(c12);

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
	float2 r3;
	r0 = tex2D(GBufferTextureSamplerDepth, i.texcoord.xy);
	r0.y = -dofProj.x + dofProj.y;
	r0.y = 1 / r0.y;
	r0.x = dofProj.y * -r0.y + r0.x;
	r0.y = r0.y * dofProj.y;
	r0.y = r0.y * -dofProj.x;
	r0.x = 1 / r0.x;
	r0.x = r0.x * r0.y;
	r0.xyz = i.texcoord1.xyz * -r0.xxx + gViewInverse[3].xyz;
	r0.yw = r0.yy * gShadowMatrix[1].xy;
	r0.xy = r0.xx * gShadowMatrix[0].xy + r0.yw;
	r0.xy = r0.zz * gShadowMatrix[2].xy + r0.xy;
	r0.xy = r0.xy + gShadowMatrix[3].xy;
	r0.xy = r0.xy + -gShadowParam18192021.zw;
	r1.xyz = r0.xxx + -gCascadeXMaxThresholds.xyz;
	r1.xyz = (r1.xyz >= 0) ? 1 : 0;
	r2 = -r0.xxx + gCascadeXMinThresholds.xyz;
	r2 = (r2.xyz >= 0) ? 1 : 0;
	r1.xyz = r1.xyz + r2.xyz;
	r2 = r0.yyy + -gCascadeYMaxThresholds.xyz;
	r2 = (r2.xyz >= 0) ? 1 : 0;
	r1.xyz = r1.xyz + r2.xyz;
	r2 = -r0.yyy + gCascadeYMinThresholds.xyz;
	r2 = (r2.xyz >= 0) ? 1 : 0;
	r1.xyz = saturate(r1.xyz + r2.xyz);
	r2.xy = -r1.xy + r1.zx;
	r2.z = r1.y;
	r1.w = 1;
	r1.xyz = saturate(r1.wzz + r2.xyz);
	r2.x = abs(gCascadeXMinThresholds.w);
	r2.y = abs(gCascadeYMinThresholds.w);
	r3.x = abs(gCascadeXMaxThresholds.w);
	r3.y = abs(gCascadeYMaxThresholds.w);
	r0.zw = max(r2.xy, r3.xy);
	r2.xy = r0.zw + -0.25;
	r0.zw = r0.zw + -r2.xy;
	r0.xy = abs(r0.xy) + -r2.xy;
	r2.x = 1 / r0.z;
	r2.y = 1 / r0.w;
	r0.xy = saturate(r0.xy * r2.xy);
	r0.zw = r0.xy * -2 + 3;
	r0.xy = r0.xy * r0.xy;
	r0.xy = r0.xy * r0.zw;
	r1.w = max(r0.x, r0.y);
	r0.xyz = saturate(r1.www + r1.xyz);
	r1 = tex2D(HDRSampler, i.texcoord.xy);
	o.xyz = r0.xyz * r1.xyz;
	o.w = 1;

	return o;
}
