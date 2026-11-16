cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
	float4 globalScalars2 : packoffset(c1);
	float4 globalScalars3 : packoffset(c2);
	float4 globalScalars4 : packoffset(c3);
	float4 globalFogParams : packoffset(c4);
	float4 globalFogColor : packoffset(c5);
	float4 globalFogOffsetN : packoffset(c6);
	float4 globalFogColorN : packoffset(c7);
	float4 globalScreenSize : packoffset(c8);
	float4 globalDayNightEffects : packoffset(c9);
	float4 ColorCorrectTopAndPedReflectScale : packoffset(c10);
	float4 ColorCorrectBottomOffset : packoffset(c11);
	float4 ColorShift : packoffset(c12);
	float4 deSatContrastGamma : packoffset(c13);
	float4 deSatContrastGammaIFX : packoffset(c14);
	float4 colorize : packoffset(c15);
	float4 globalUmScalars : packoffset(c16);
	float4 gToneMapScalers : packoffset(c17);
	float4 gAmbientOcclusionEffect : packoffset(c18);
	float4 gWaterGlobals : packoffset(c19);
	float4 ColorCorrectTopScreenEdge : packoffset(c20);
	float4 ColorCorrectBottomOffsetScreenEdge : packoffset(c21);
	float4 gScreenSpaceTessFactors : packoffset(c22);
	float4 gTessFactors : packoffset(c23);
	float4 gFrustumPlaneEquation_Left : packoffset(c24);
	float4 gFrustumPlaneEquation_Right : packoffset(c25);
	float4 gFrustumPlaneEquation_Top : packoffset(c26);
	float4 gFrustumPlaneEquation_Bottom : packoffset(c27);
	float4 gTessParameters : packoffset(c28);
};

struct HS_IN
{
	float4 texcoord8 : TEXCOORD8;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float2 temporalInput_texcoord : TEMPORAL1;
	float4 temporalInput_texcoord1 : TEMPORAL2;
	float4 temporalInput_texcoord2 : TEMPORAL3;
	float3 temporalInput_texcoord3 : TEMPORAL4;
	float3 temporalInput_texcoord4 : TEMPORAL5;
	float4 temporalInput_texcoord5 : TEMPORAL6;
	float3 temporalInput_texcoord7 : TEMPORAL7;
	float3 temporalInput_texcoord9 : TEMPORAL8;
};

struct HS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float2 temporalInput_texcoord : TEMPORAL1;
	float4 temporalInput_texcoord1 : TEMPORAL2;
	float4 temporalInput_texcoord2 : TEMPORAL3;
	float3 temporalInput_texcoord3 : TEMPORAL4;
	float3 temporalInput_texcoord4 : TEMPORAL5;
	float4 temporalInput_texcoord5 : TEMPORAL6;
	float3 temporalInput_texcoord7 : TEMPORAL7;
	float3 temporalInput_texcoord9 : TEMPORAL8;
};

struct HS_CONST
{
	float edges[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

HS_CONST constants(InputPatch<HS_IN, 3> patch)
{
	HS_CONST o;

	float3 t0 = normalize(patch[1].texcoord7 - patch[0].texcoord7 + 0.00000999999975);
	float3 t1 = normalize(patch[2].texcoord7 - patch[0].texcoord7 + 0.00000999999975);
	float3 t2 = cross(t0, t1) + 0.00000999999975;
	float t3 = dot(float4(gWorldViewProj[0].w, gWorldViewProj[1].w, gWorldViewProj[2].w, gWorldViewProj[3].w), float4(patch[0].texcoord8.xyz, 1));
	float t4 = 0.5 * (dot(float4(gWorldViewProj[0].x, gWorldViewProj[1].x, gWorldViewProj[2].x, gWorldViewProj[3].x), float4(patch[0].texcoord8.xyz, 1)) / t3 + 1) * globalScreenSize.x;
	float t5 = dot(float4(gWorldViewProj[0].w, gWorldViewProj[1].w, gWorldViewProj[2].w, gWorldViewProj[3].w), float4(patch[2].texcoord8.xyz, 1));
	float t6 = (dot(float4(gWorldViewProj[0].x, gWorldViewProj[1].x, gWorldViewProj[2].x, gWorldViewProj[3].x), float4(patch[2].texcoord8.xyz, 1)) / t5 + 1) * globalScreenSize.x;
	float t7 = dot(float4(gWorldViewProj[0].w, gWorldViewProj[1].w, gWorldViewProj[2].w, gWorldViewProj[3].w), float4(patch[1].texcoord8.xyz, 1));
	float t8 = (dot(float4(gWorldViewProj[0].x, gWorldViewProj[1].x, gWorldViewProj[2].x, gWorldViewProj[3].x), float4(patch[1].texcoord8.xyz, 1)) / t7 + 1) * globalScreenSize.x;
	float t9 = -gTessParameters.x;
	float t10 = -globalScreenSize.y;
	float t11 = 0.5 * (dot(float4(gWorldViewProj[0].y, gWorldViewProj[1].y, gWorldViewProj[2].y, gWorldViewProj[3].y), float4(patch[0].texcoord8.xyz, 1)) / t3 + 1) * t10;
	float t12 = (dot(float4(gWorldViewProj[0].y, gWorldViewProj[1].y, gWorldViewProj[2].y, gWorldViewProj[3].y), float4(patch[2].texcoord8.xyz, 1)) / t5 + 1) * t10;
	float t13 = clamp(length(float2(0.5 * t6 - t4, 0.5 * t12 - t11)) * gScreenSpaceTessFactors.w, 1, gScreenSpaceTessFactors.x);
	float t14 = (dot(float4(gWorldViewProj[0].y, gWorldViewProj[1].y, gWorldViewProj[2].y, gWorldViewProj[3].y), float4(patch[1].texcoord8.xyz, 1)) / t7 + 1) * t10;
	float2 t15 = clamp(float2(length(float2(0.5 * t6 - 0.5 * t8, 0.5 * t12 - 0.5 * t14)), length(float2(-0.5 * t8 + t4, -0.5 * t14 + t11))) * gScreenSpaceTessFactors.w, 1, gScreenSpaceTessFactors.x);
	float3 t16 = normalize(gViewInverse[3].xyz - patch[0].texcoord7 + 0.00000999999975);
	bool t17 = dot(normalize(t2), t16) >= -gTessParameters.y && ((t9 < dot(gFrustumPlaneEquation_Right, float4(patch[0].texcoord7, 1)) ? 1.0 : 0) + (t9 < dot(gFrustumPlaneEquation_Right, float4(patch[1].texcoord7, 1)) ? 1.0 : 0) + (t9 < dot(gFrustumPlaneEquation_Right, float4(patch[2].texcoord7, 1)) ? 1.0 : 0)) * ((t9 < dot(gFrustumPlaneEquation_Bottom, float4(patch[0].texcoord7, 1)) ? 1.0 : 0) + (t9 < dot(gFrustumPlaneEquation_Bottom, float4(patch[1].texcoord7, 1)) ? 1.0 : 0) + (t9 < dot(gFrustumPlaneEquation_Bottom, float4(patch[2].texcoord7, 1)) ? 1.0 : 0)) * (((t9 < dot(gFrustumPlaneEquation_Left, float4(patch[0].texcoord7, 1)) ? 1.0 : 0) + (t9 < dot(gFrustumPlaneEquation_Left, float4(patch[1].texcoord7, 1)) ? 1.0 : 0) + (t9 < dot(gFrustumPlaneEquation_Left, float4(patch[2].texcoord7, 1)) ? 1.0 : 0)) * ((t9 < dot(gFrustumPlaneEquation_Top, float4(patch[0].texcoord7, 1)) ? 1.0 : 0) + (t9 < dot(gFrustumPlaneEquation_Top, float4(patch[1].texcoord7, 1)) ? 1.0 : 0) + (t9 < dot(gFrustumPlaneEquation_Top, float4(patch[2].texcoord7, 1)) ? 1.0 : 0))) != 0;
	o.edges[0] = min(t17 ? t15.x : 0, 7);
	o.edges[1] = min(t17 ? t13 : 0, 7);
	o.edges[2] = min(t17 ? t15.y : 0, 7);
	o.inside = min(t17 ? 0.333333343 * (t13 + t15.x + t15.y) : 0, 7);

	return o;
}

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("constants")]
HS_OUT main(InputPatch<HS_IN, 3> patch, uint sv_outputcontrolpointid : SV_OutputControlPointID)
{
	HS_OUT o;

	o.texcoord8 = patch[sv_outputcontrolpointid].texcoord8;
	o.temporalPrevious = patch[sv_outputcontrolpointid].temporalPrevious;
	o.temporalInput_texcoord8 = patch[sv_outputcontrolpointid].temporalInput_texcoord8;
	o.temporalInput_texcoord = patch[sv_outputcontrolpointid].temporalInput_texcoord;
	o.temporalInput_texcoord1 = patch[sv_outputcontrolpointid].temporalInput_texcoord1;
	o.temporalInput_texcoord2 = patch[sv_outputcontrolpointid].temporalInput_texcoord2;
	o.temporalInput_texcoord3 = patch[sv_outputcontrolpointid].temporalInput_texcoord3;
	o.temporalInput_texcoord4 = patch[sv_outputcontrolpointid].temporalInput_texcoord4;
	o.temporalInput_texcoord5 = patch[sv_outputcontrolpointid].temporalInput_texcoord5;
	o.temporalInput_texcoord7 = patch[sv_outputcontrolpointid].temporalInput_texcoord7;
	o.temporalInput_texcoord9 = patch[sv_outputcontrolpointid].temporalInput_texcoord9;
	o.texcoord = patch[sv_outputcontrolpointid].texcoord;
	o.texcoord1 = patch[sv_outputcontrolpointid].texcoord1;
	o.texcoord2 = patch[sv_outputcontrolpointid].texcoord2;
	o.texcoord3 = patch[sv_outputcontrolpointid].texcoord3;
	o.texcoord4 = patch[sv_outputcontrolpointid].texcoord4;
	o.texcoord5 = patch[sv_outputcontrolpointid].texcoord5;
	o.texcoord7 = patch[sv_outputcontrolpointid].texcoord7;
	o.texcoord9 = patch[sv_outputcontrolpointid].texcoord9;

	return o;
}
