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
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;

	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_color : TEMPORAL1;
	float2 temporalInput_texcoord : TEMPORAL2;
	float4 temporalInput_texcoord1 : TEMPORAL3;
	float3 temporalInput_texcoord3 : TEMPORAL4;
	float3 temporalInput_texcoord4 : TEMPORAL5;
	float3 temporalInput_texcoord5 : TEMPORAL6;
	float4 temporalInput_texcoord6 : TEMPORAL7;
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
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
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
	float3 t1 = patch[0].texcoord1.xyz * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord1.xyz + patch[2].texcoord1.xyz * sv_domainlocation.y + 0.00000999999975;
	float3 t2 = patch[0].texcoord4 * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord4 + patch[2].texcoord4 * sv_domainlocation.y + 0.00000999999975;
	o.sv_position = mul(float4(t0, 1), gWorldViewProj);
	o.color = patch[0].color * sv_domainlocation.z + sv_domainlocation.x * patch[1].color + patch[2].color * sv_domainlocation.y;
	o.texcoord = patch[0].texcoord * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord + patch[2].texcoord * sv_domainlocation.y;
	o.texcoord1 = float4(normalize(t1), dot(float4(gWorldViewProj[0].w, gWorldViewProj[1].w, gWorldViewProj[2].w, gWorldViewProj[3].w), float4(t0, 1)));
	o.texcoord3 = patch[0].texcoord3 * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord3 + patch[2].texcoord3 * sv_domainlocation.y;
	o.texcoord4 = normalize(t2);
	o.texcoord5 = cross(normalize(t2), normalize(t1));
	o.texcoord6 = patch[0].texcoord6 * sv_domainlocation.z + sv_domainlocation.x * patch[1].texcoord6 + patch[2].texcoord6 * sv_domainlocation.y;

	return o;
}

DS_OUT TemporalDomainPrevious(DS_CONST constants, float3 sv_domainlocation : SV_DomainLocation, const OutputPatch<DS_IN, 3> patch)
{
	DS_OUT o;

	float3 t0 = patch[0].temporalInput_texcoord8.xyz * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord8.xyz + patch[2].temporalInput_texcoord8.xyz * sv_domainlocation.y;
	float3 t1 = patch[0].temporalInput_texcoord1.xyz * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord1.xyz + patch[2].temporalInput_texcoord1.xyz * sv_domainlocation.y + 0.00000999999975;
	float3 t2 = patch[0].temporalInput_texcoord4 * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord4 + patch[2].temporalInput_texcoord4 * sv_domainlocation.y + 0.00000999999975;
	o.sv_position = mul(float4(t0, 1), Temporal_b0_o128_gWorldViewProj);
	o.color = patch[0].temporalInput_color * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_color + patch[2].temporalInput_color * sv_domainlocation.y;
	o.texcoord = patch[0].temporalInput_texcoord * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord + patch[2].temporalInput_texcoord * sv_domainlocation.y;
	o.texcoord1 = float4(normalize(t1), dot(float4(Temporal_b0_o128_gWorldViewProj[0].w, Temporal_b0_o128_gWorldViewProj[1].w, Temporal_b0_o128_gWorldViewProj[2].w, Temporal_b0_o128_gWorldViewProj[3].w), float4(t0, 1)));
	o.texcoord3 = patch[0].temporalInput_texcoord3 * sv_domainlocation.z + sv_domainlocation.x * patch[1].temporalInput_texcoord3 + patch[2].temporalInput_texcoord3 * sv_domainlocation.y;
	o.texcoord4 = normalize(t2);
	o.texcoord5 = cross(normalize(t2), normalize(t1));
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
