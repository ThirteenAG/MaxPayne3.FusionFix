cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
	float4 TransColor : packoffset(c130);
	float4 TransPos : packoffset(c131);
	float4 TransTex0 : packoffset(c132);
	float4 TransTex1 : packoffset(c133);
	float4 TransTex2 : packoffset(c134);
	float2 BrightnessSetting : packoffset(c135);
	float4 dofProj : packoffset(c136);
};

cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

cbuffer ShadowParam : register(b8)
{
	float4 gShadowParam18192021 : packoffset(c0);
	float4 gShadowParam14151617 : packoffset(c1);
	float4 gShadowParam0123 : packoffset(c2);
	float4 gShadowParam4567 : packoffset(c3);
	float4 gShadowParam891113 : packoffset(c4);
	float4 gCascadeZScales : packoffset(c5);
	float4 gCascadeZOffsets : packoffset(c6);
	float4 gCascadeXMinThresholds : packoffset(c7);
	float4 gCascadeXMaxThresholds : packoffset(c8);
	float4 gCascadeYMinThresholds : packoffset(c9);
	float4 gCascadeYMaxThresholds : packoffset(c10);
	row_major float4x4 gShadowMatrix : packoffset(c11);
};

Texture2DMS<float> gbufferTextureDepth : register(t3);
Texture2DMS<float4> PostFxTexture0a : register(t6);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	int4 r0;
	int4 r1;
	int3 r2;
	float3 dimensions0;
	gbufferTextureDepth.GetDimensions(dimensions0.x, dimensions0.y, dimensions0.z);
	r0.xy = asint(dimensions0.xy);
	r0.xy = asint(asfloat(r0.xy) * i.texcoord.xy);
	r0.xy = (int2)asfloat(r0.xy);
	r0.zw = int2(0, 0);
	r0.x = asint(gbufferTextureDepth.Load(r0.xy, 0).x);
	r0.y = asint(-(dofProj.x) + dofProj.y);
	r0.y = asint(dofProj.y / asfloat(r0.y));
	r0.x = asint(-(asfloat(r0.y)) + asfloat(r0.x));
	r0.y = asint(asfloat(r0.y) * -(dofProj.x));
	r0.x = asint(asfloat(r0.y) / asfloat(r0.x));
	r0.xyz = asint(i.texcoord1.xyz * -(asfloat(r0.xxx)) + gViewInverse[3].xyz);
	r0.yw = asint(asfloat(r0.yy) * gShadowMatrix[1].xy);
	r0.xy = asint(asfloat(r0.xx) * gShadowMatrix[0].xy + asfloat(r0.yw));
	r0.xy = asint(asfloat(r0.zz) * gShadowMatrix[2].xy + asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.xy) + gShadowMatrix[3].xy);
	r0.xy = asint(asfloat(r0.xy) + -(gShadowParam18192021.zw));
	r1.xyz = (asfloat(r0.xxx) >= gCascadeXMaxThresholds.xyy) ? -1 : 0;
	r1.xyz = r1.xyz & int3(1065353216, 1065353216, 1065353216);
	r2 = (gCascadeXMinThresholds.xyz >= asfloat(r0.xxx)) ? -1 : 0;
	r2 = r2.xyz & int3(1065353216, 1065353216, 1065353216);
	r1.xyz = asint(asfloat(r1.xyz) + asfloat(r2.xyz));
	r2 = (asfloat(r0.yyy) >= gCascadeYMaxThresholds.xyz) ? -1 : 0;
	r2 = r2.xyz & int3(1065353216, 1065353216, 1065353216);
	r1.xyz = asint(asfloat(r1.xyz) + asfloat(r2.xyz));
	r2 = (gCascadeYMinThresholds.xyz >= asfloat(r0.yyy)) ? -1 : 0;
	r2 = r2.xyz & int3(1065353216, 1065353216, 1065353216);
	r1.xyz = asint(asfloat(r1.xyz) + asfloat(r2.xyz));
	r1.xyz = asint(min(asfloat(r1.xyz), float3(1, 1, 1)));
	r2.xy = asint(-(asfloat(r1.xy)) + asfloat(r1.zx));
	r2.z = r1.y;
	r1.w = 1065353216;
	r1.xyz = asint(saturate(asfloat(r1.wzz) + asfloat(r2.xyz)));
	r2.x = asint(-(gCascadeXMinThresholds.w));
	r2.y = asint(-(gCascadeXMaxThresholds.w));
	r0.xy = asint(saturate(abs(asfloat(r0.xy)) * float2(4, 4) + asfloat(r2.xy)));
	r0.x = asint(max(asfloat(r0.y), asfloat(r0.x)));
	r0.xyz = asint(asfloat(r0.xxx) + asfloat(r1.xyz));
	r0.xyz = asint(min(asfloat(r0.xyz), float3(1, 1, 1)));
	float3 dimensions1;
	PostFxTexture0a.GetDimensions(dimensions1.x, dimensions1.y, dimensions1.z);
	r1.xy = asint(dimensions1.xy);
	r1.xy = asint(asfloat(r1.xy) * i.texcoord.xy);
	r1.xy = (int2)asfloat(r1.xy);
	r1.zw = int2(0, 0);
	r2 = asint(PostFxTexture0a.Load(r1.xy, 0).xyz);
	r1.xyz = asint(PostFxTexture0a.Load(r1.xy, 1).xyz);
	r1.xyz = asint(asfloat(r1.xyz) + asfloat(r2.xyz));
	r1.xyz = asint(asfloat(r1.xyz) * float3(0.5, 0.5, 0.5));
	o.xyz = asfloat(r0.xyz) * asfloat(r1.xyz);
	o.w = 1;

	return o;
}
