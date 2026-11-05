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

cbuffer CacheZShiftandParallax : register(b4)
{
	float zShiftScale : packoffset(c0);
	float parallaxScaleBias : packoffset(c0.y);
};

SamplerState BumpSampler : register(s2);
Texture2D BumpTex : register(t2);

struct DS_IN
{
	float4 texcoord8 : TEXCOORD8;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float4 texcoord7 : TEXCOORD7;

	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_color : TEMPORAL1;
	float2 temporalInput_texcoord : TEMPORAL2;
	float4 temporalInput_texcoord1 : TEMPORAL3;
	float3 temporalInput_texcoord4 : TEMPORAL4;
	float3 temporalInput_texcoord5 : TEMPORAL5;
	float4 temporalInput_texcoord6 : TEMPORAL6;
	float4 temporalInput_texcoord7 : TEMPORAL7;
};

struct DS_CONST
{
	float edges[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

struct DS_OUT
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float4 texcoord7 : TEXCOORD7;
	float3 temporalPrevious : TEXCOORD15;
};


cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	row_major float4x4 Temporal_b0_o192_gViewInverse : packoffset(c13);
	float4 Temporal_b5_o0_globalScalars : packoffset(c17);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c18);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c19);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c20);
	float4 Temporal_b5_o64_globalFogParams : packoffset(c21);
	float4 Temporal_b5_o80_globalFogColor : packoffset(c22);
	float4 Temporal_b5_o96_globalFogOffsetN : packoffset(c23);
	float4 Temporal_b5_o112_globalFogColorN : packoffset(c24);
	float4 Temporal_b5_o128_globalScreenSize : packoffset(c25);
	float4 Temporal_b5_o144_globalDayNightEffects : packoffset(c26);
	float4 Temporal_b5_o160_ColorCorrectTopAndPedReflectScale : packoffset(c27);
	float4 Temporal_b5_o176_ColorCorrectBottomOffset : packoffset(c28);
	float4 Temporal_b5_o192_ColorShift : packoffset(c29);
	float4 Temporal_b5_o208_deSatContrastGamma : packoffset(c30);
	float4 Temporal_b5_o224_deSatContrastGammaIFX : packoffset(c31);
	float4 Temporal_b5_o240_colorize : packoffset(c32);
	float4 Temporal_b5_o256_globalUmScalars : packoffset(c33);
	float4 Temporal_b5_o272_gToneMapScalers : packoffset(c34);
	float4 Temporal_b5_o288_gAmbientOcclusionEffect : packoffset(c35);
	float4 Temporal_b5_o304_gWaterGlobals : packoffset(c36);
	float4 Temporal_b5_o320_ColorCorrectTopScreenEdge : packoffset(c37);
	float4 Temporal_b5_o336_ColorCorrectBottomOffsetScreenEdge : packoffset(c38);
	float4 Temporal_b5_o352_gScreenSpaceTessFactors : packoffset(c39);
	float4 Temporal_b5_o368_gTessFactors : packoffset(c40);
	float4 Temporal_b5_o384_gFrustumPlaneEquation_Left : packoffset(c41);
	float4 Temporal_b5_o400_gFrustumPlaneEquation_Right : packoffset(c42);
	float4 Temporal_b5_o416_gFrustumPlaneEquation_Top : packoffset(c43);
	float4 Temporal_b5_o432_gFrustumPlaneEquation_Bottom : packoffset(c44);
	float4 Temporal_b5_o448_gTessParameters : packoffset(c45);
	float Temporal_b4_o0_zShiftScale : packoffset(c46);
	float Temporal_b4_o4_parallaxScaleBias : packoffset(c47);
};
Texture2D TemporalResource_t2_BumpTex : register(t127);
DS_OUT TemporalDomainCurrent(DS_CONST constants, float3 sv_domainlocation : SV_DomainLocation, const OutputPatch<DS_IN, 3> patch)
{
	DS_OUT o;

	float3 t0 = patch[0].texcoord1.xyz * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord1.xyz + patch[2].texcoord1.xyz * sv_domainlocation.y + 0.00000999999975;
	float3 t1 = patch[0].texcoord8.xyz * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord8.xyz + patch[2].texcoord8.xyz * sv_domainlocation.y;
	float2 t2 = patch[0].texcoord * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord;
	float2 t3 = patch[2].texcoord * sv_domainlocation.y;
	float t4 = BumpTex.SampleLevel(BumpSampler, t3 + t2, 0).z;
	float t5 = (t4 - 0.5) * gTessParameters.w - 0.5 * gTessParameters.w;
	float3 t6 = normalize(mul((float3x3)gWorld, gViewInverse[3].xyz - gWorld[3].xyz) - t1 + 0.00000999999975);
	float3 t7 = t6 * zShiftScale + t1 + normalize(t0) * t5;
	o.sv_position = mul(float4(t7, 1), gWorldViewProj);
	o.color = patch[0].color * sv_domainlocation.z + sv_domainlocation.x * patch[1].color + patch[2].color * sv_domainlocation.y;
	o.texcoord = t2 + t3;
	o.texcoord1 = float4(normalize(t0), 0);
	o.texcoord4 = normalize(patch[0].texcoord4 * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord4 + patch[2].texcoord4 * sv_domainlocation.y + 0.00000999999975);
	o.texcoord5 = normalize(patch[0].texcoord5 * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord5 + patch[2].texcoord5 * sv_domainlocation.y + 0.00000999999975);
	o.texcoord6 = patch[0].texcoord6 * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord6 + patch[2].texcoord6 * sv_domainlocation.y;
	o.texcoord7 = patch[0].texcoord7 * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord7 + patch[2].texcoord7 * sv_domainlocation.y;

	return o;
}

DS_OUT TemporalDomainPrevious(DS_CONST constants, float3 sv_domainlocation : SV_DomainLocation, const OutputPatch<DS_IN, 3> patch)
{
	DS_OUT o;

	float3 t0 = patch[0].temporalInput_texcoord1.xyz * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord1.xyz + patch[2].temporalInput_texcoord1.xyz * sv_domainlocation.y + 0.00000999999975;
	float3 t1 = patch[0].temporalInput_texcoord8.xyz * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord8.xyz + patch[2].temporalInput_texcoord8.xyz * sv_domainlocation.y;
	float2 t2 = patch[0].temporalInput_texcoord * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord;
	float2 t3 = patch[2].temporalInput_texcoord * sv_domainlocation.y;
	float t4 = TemporalResource_t2_BumpTex.SampleLevel(BumpSampler, t3 + t2, 0).z;
	float t5 = (t4 - 0.5) * Temporal_b5_o448_gTessParameters.w - 0.5 * Temporal_b5_o448_gTessParameters.w;
	float3 t6 = normalize(mul((float3x3)Temporal_b0_o0_gWorld, Temporal_b0_o192_gViewInverse[3].xyz - Temporal_b0_o0_gWorld[3].xyz) - t1 + 0.00000999999975);
	float3 t7 = t6 * Temporal_b4_o0_zShiftScale + t1 + normalize(t0) * t5;
	o.sv_position = mul(float4(t7, 1), Temporal_b0_o128_gWorldViewProj);
	o.color = patch[0].temporalInput_color * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_color + patch[2].temporalInput_color * sv_domainlocation.y;
	o.texcoord = t2 + t3;
	o.texcoord1 = float4(normalize(t0), 0);
	o.texcoord4 = normalize(patch[0].temporalInput_texcoord4 * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord4 + patch[2].temporalInput_texcoord4 * sv_domainlocation.y + 0.00000999999975);
	o.texcoord5 = normalize(patch[0].temporalInput_texcoord5 * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord5 + patch[2].temporalInput_texcoord5 * sv_domainlocation.y + 0.00000999999975);
	o.texcoord6 = patch[0].temporalInput_texcoord6 * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord6 + patch[2].temporalInput_texcoord6 * sv_domainlocation.y;
	o.texcoord7 = patch[0].temporalInput_texcoord7 * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord7 + patch[2].temporalInput_texcoord7 * sv_domainlocation.y;

	return o;
}

[domain("tri")]
DS_OUT main(DS_CONST constants, float3 sv_domainlocation : SV_DomainLocation, const OutputPatch<DS_IN, 3> patch)
{
    DS_OUT o = TemporalDomainCurrent(constants, sv_domainlocation, patch);
    o.temporalPrevious = float3(0, 0, -1);
    [branch] if (TemporalState.x > 0 && patch[0].temporalPrevious.z > 0)
        o.temporalPrevious = TemporalDomainPrevious(constants, sv_domainlocation, patch).sv_position.xyw;
    return o;
}
