cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
};

struct DS_IN
{
	float4 texcoord8 : TEXCOORD8;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord6 : TEXCOORD6;

	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_color : TEMPORAL1;
	float2 temporalInput_texcoord : TEMPORAL2;
	float4 temporalInput_texcoord1 : TEMPORAL3;
	float4 temporalInput_texcoord6 : TEMPORAL4;
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
	float4 texcoord6 : TEXCOORD6;
	float3 temporalPrevious : TEXCOORD15;
};


cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
};

DS_OUT TemporalDomainCurrent(DS_CONST constants, float3 sv_domainlocation : SV_DomainLocation, const OutputPatch<DS_IN, 3> patch)
{
	DS_OUT o;

	float3 t0 = patch[0].texcoord8.xyz * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord8.xyz + patch[2].texcoord8.xyz * sv_domainlocation.y;
	o.sv_position = mul(float4(t0, 1), gWorldViewProj);
	o.color = patch[0].color * sv_domainlocation.z + sv_domainlocation.x * patch[1].color + patch[2].color * sv_domainlocation.y;
	o.texcoord = patch[0].texcoord * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord + patch[2].texcoord * sv_domainlocation.y;
	o.texcoord1 = 0;
	o.texcoord6 = patch[0].texcoord6 * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord6 + patch[2].texcoord6 * sv_domainlocation.y;

	return o;
}

DS_OUT TemporalDomainPrevious(DS_CONST constants, float3 sv_domainlocation : SV_DomainLocation, const OutputPatch<DS_IN, 3> patch)
{
	DS_OUT o;

	float3 t0 = patch[0].temporalInput_texcoord8.xyz * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord8.xyz + patch[2].temporalInput_texcoord8.xyz * sv_domainlocation.y;
	o.sv_position = mul(float4(t0, 1), Temporal_b0_o128_gWorldViewProj);
	o.color = patch[0].temporalInput_color * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_color + patch[2].temporalInput_color * sv_domainlocation.y;
	o.texcoord = patch[0].temporalInput_texcoord * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord + patch[2].temporalInput_texcoord * sv_domainlocation.y;
	o.texcoord1 = 0;
	o.texcoord6 = patch[0].temporalInput_texcoord6 * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord6 + patch[2].temporalInput_texcoord6 * sv_domainlocation.y;

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
