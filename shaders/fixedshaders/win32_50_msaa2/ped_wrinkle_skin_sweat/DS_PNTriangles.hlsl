cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
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

struct DS_IN
{
	float4 texcoord8 : TEXCOORD8;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
};

struct DS_CONST
{
	float edges[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

struct DS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord8 : TEXCOORD8;
};

[domain("tri")]
DS_OUT main(DS_CONST constants, float3 sv_domainlocation : SV_DomainLocation, const OutputPatch<DS_IN, 3> patch)
{
	DS_OUT o;

	float3 t0 = patch[0].texcoord8.xyz * sv_domainlocation.x + sv_domainlocation.y * patch[1].texcoord8.xyz + patch[2].texcoord8.xyz * sv_domainlocation.z;
	float t1 = dot(t0, patch[0].texcoord9) - dot(patch[0].texcoord8.xyz, patch[0].texcoord9);
	float t2 = dot(t0, patch[1].texcoord9) - dot(patch[1].texcoord8.xyz, patch[1].texcoord9);
	float t3 = dot(t0, patch[2].texcoord9) - dot(patch[2].texcoord8.xyz, patch[2].texcoord9);
	float3 t4 = gTessParameters.z * ((-patch[0].texcoord9 * t1 + t0) * sv_domainlocation.x + (-patch[1].texcoord9 * t2 + t0) * sv_domainlocation.y + (-patch[2].texcoord9 * t3 + t0) * sv_domainlocation.z) + t0 * (1 - gTessParameters.z);
	float3 t5 = patch[0].texcoord1.xyz * sv_domainlocation.x + sv_domainlocation.y * patch[1].texcoord1.xyz + patch[2].texcoord1.xyz * sv_domainlocation.z + 0.00000999999975;
	float3 t6 = patch[0].texcoord4 * sv_domainlocation.x + sv_domainlocation.y * patch[1].texcoord4 + patch[2].texcoord4 * sv_domainlocation.z + 0.00000999999975;
	o.sv_position = mul(float4(t4, 1), gWorldViewProj);
	o.texcoord = patch[0].texcoord * sv_domainlocation.x + sv_domainlocation.y * patch[1].texcoord + patch[2].texcoord * sv_domainlocation.z;
	o.texcoord1 = float4(normalize(t5), dot(float4(gWorldViewProj[0].w, gWorldViewProj[1].w, gWorldViewProj[2].w, gWorldViewProj[3].w), float4(t4, 1)));
	o.texcoord2 = patch[0].texcoord2 * sv_domainlocation.x + sv_domainlocation.y * patch[1].texcoord2 + patch[2].texcoord2 * sv_domainlocation.z;
	o.texcoord4 = normalize(t6);
	o.texcoord5 = float4(cross(normalize(t6), normalize(t5)) * patch[0].texcoord5.www, patch[0].texcoord5.w);
	o.texcoord6 = patch[0].texcoord6;
	o.texcoord7 = patch[0].texcoord7 * sv_domainlocation.x + sv_domainlocation.y * patch[1].texcoord7 + patch[2].texcoord7 * sv_domainlocation.z;
	o.texcoord8 = 0;

	return o;
}
