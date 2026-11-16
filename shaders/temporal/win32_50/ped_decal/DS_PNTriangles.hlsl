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

struct DS_CONST
{
	float edges[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

struct DS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord7 : TEXCOORD7;
	float3 temporalPrevious : TEXCOORD15;
};


cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	float4 Temporal_b5_o0_globalScalars : packoffset(c13);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c14);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c15);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c16);
	float4 Temporal_b5_o64_globalFogParams : packoffset(c17);
	float4 Temporal_b5_o80_globalFogColor : packoffset(c18);
	float4 Temporal_b5_o96_globalFogOffsetN : packoffset(c19);
	float4 Temporal_b5_o112_globalFogColorN : packoffset(c20);
	float4 Temporal_b5_o128_globalScreenSize : packoffset(c21);
	float4 Temporal_b5_o144_globalDayNightEffects : packoffset(c22);
	float4 Temporal_b5_o160_ColorCorrectTopAndPedReflectScale : packoffset(c23);
	float4 Temporal_b5_o176_ColorCorrectBottomOffset : packoffset(c24);
	float4 Temporal_b5_o192_ColorShift : packoffset(c25);
	float4 Temporal_b5_o208_deSatContrastGamma : packoffset(c26);
	float4 Temporal_b5_o224_deSatContrastGammaIFX : packoffset(c27);
	float4 Temporal_b5_o240_colorize : packoffset(c28);
	float4 Temporal_b5_o256_globalUmScalars : packoffset(c29);
	float4 Temporal_b5_o272_gToneMapScalers : packoffset(c30);
	float4 Temporal_b5_o288_gAmbientOcclusionEffect : packoffset(c31);
	float4 Temporal_b5_o304_gWaterGlobals : packoffset(c32);
	float4 Temporal_b5_o320_ColorCorrectTopScreenEdge : packoffset(c33);
	float4 Temporal_b5_o336_ColorCorrectBottomOffsetScreenEdge : packoffset(c34);
	float4 Temporal_b5_o352_gScreenSpaceTessFactors : packoffset(c35);
	float4 Temporal_b5_o368_gTessFactors : packoffset(c36);
	float4 Temporal_b5_o384_gFrustumPlaneEquation_Left : packoffset(c37);
	float4 Temporal_b5_o400_gFrustumPlaneEquation_Right : packoffset(c38);
	float4 Temporal_b5_o416_gFrustumPlaneEquation_Top : packoffset(c39);
	float4 Temporal_b5_o432_gFrustumPlaneEquation_Bottom : packoffset(c40);
	float4 Temporal_b5_o448_gTessParameters : packoffset(c41);
};

DS_OUT TemporalDomainCurrent(DS_CONST constants, float3 sv_domainlocation : SV_DomainLocation, const OutputPatch<DS_IN, 3> patch)
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
	o.texcoord3 = patch[0].texcoord3 * sv_domainlocation.x + sv_domainlocation.y * patch[1].texcoord3 + patch[2].texcoord3 * sv_domainlocation.z;
	o.texcoord4 = normalize(t6);
	o.texcoord5 = float4(cross(normalize(t6), normalize(t5)) * patch[0].texcoord5.www, patch[0].texcoord5.w);
	o.texcoord7 = patch[0].texcoord7 * sv_domainlocation.x + sv_domainlocation.y * patch[1].texcoord7 + patch[2].texcoord7 * sv_domainlocation.z;
	

	return o;
}

DS_OUT TemporalDomainPrevious(DS_CONST constants, float3 sv_domainlocation : SV_DomainLocation, const OutputPatch<DS_IN, 3> patch)
{
	DS_OUT o;

	float3 t0 = patch[0].temporalInput_texcoord8.xyz * sv_domainlocation.x + sv_domainlocation.y * patch[1].temporalInput_texcoord8.xyz + patch[2].temporalInput_texcoord8.xyz * sv_domainlocation.z;
	float t1 = dot(t0, patch[0].temporalInput_texcoord9) - dot(patch[0].temporalInput_texcoord8.xyz, patch[0].temporalInput_texcoord9);
	float t2 = dot(t0, patch[1].temporalInput_texcoord9) - dot(patch[1].temporalInput_texcoord8.xyz, patch[1].temporalInput_texcoord9);
	float t3 = dot(t0, patch[2].temporalInput_texcoord9) - dot(patch[2].temporalInput_texcoord8.xyz, patch[2].temporalInput_texcoord9);
	float3 t4 = Temporal_b5_o448_gTessParameters.z * ((-patch[0].temporalInput_texcoord9 * t1 + t0) * sv_domainlocation.x + (-patch[1].temporalInput_texcoord9 * t2 + t0) * sv_domainlocation.y + (-patch[2].temporalInput_texcoord9 * t3 + t0) * sv_domainlocation.z) + t0 * (1 - Temporal_b5_o448_gTessParameters.z);
	float3 t5 = patch[0].temporalInput_texcoord1.xyz * sv_domainlocation.x + sv_domainlocation.y * patch[1].temporalInput_texcoord1.xyz + patch[2].temporalInput_texcoord1.xyz * sv_domainlocation.z + 0.00000999999975;
	float3 t6 = patch[0].temporalInput_texcoord4 * sv_domainlocation.x + sv_domainlocation.y * patch[1].temporalInput_texcoord4 + patch[2].temporalInput_texcoord4 * sv_domainlocation.z + 0.00000999999975;
	o.sv_position = mul(float4(t4, 1), Temporal_b0_o128_gWorldViewProj);
	o.texcoord = patch[0].temporalInput_texcoord * sv_domainlocation.x + sv_domainlocation.y * patch[1].temporalInput_texcoord + patch[2].temporalInput_texcoord * sv_domainlocation.z;
	o.texcoord1 = float4(normalize(t5), dot(float4(Temporal_b0_o128_gWorldViewProj[0].w, Temporal_b0_o128_gWorldViewProj[1].w, Temporal_b0_o128_gWorldViewProj[2].w, Temporal_b0_o128_gWorldViewProj[3].w), float4(t4, 1)));
	o.texcoord2 = patch[0].temporalInput_texcoord2 * sv_domainlocation.x + sv_domainlocation.y * patch[1].temporalInput_texcoord2 + patch[2].temporalInput_texcoord2 * sv_domainlocation.z;
	o.texcoord3 = patch[0].temporalInput_texcoord3 * sv_domainlocation.x + sv_domainlocation.y * patch[1].temporalInput_texcoord3 + patch[2].temporalInput_texcoord3 * sv_domainlocation.z;
	o.texcoord4 = normalize(t6);
	o.texcoord5 = float4(cross(normalize(t6), normalize(t5)) * patch[0].temporalInput_texcoord5.www, patch[0].temporalInput_texcoord5.w);
	o.texcoord7 = patch[0].temporalInput_texcoord7 * sv_domainlocation.x + sv_domainlocation.y * patch[1].temporalInput_texcoord7 + patch[2].temporalInput_texcoord7 * sv_domainlocation.z;
	

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
