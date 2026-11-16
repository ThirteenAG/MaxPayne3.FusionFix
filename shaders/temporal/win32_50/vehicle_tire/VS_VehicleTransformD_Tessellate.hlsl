cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
};

cbuffer vehicle_instance : register(b7)
{
	row_major float4x4 matWheelTransform : packoffset(c0);
	float4 tyreDeformParams : packoffset(c4);
	float4 tyreDeformParams2 : packoffset(c5);
};

cbuffer vehicle_tiredeform : register(b3)
{
	bool tyreDeformSwitchOn : packoffset(c0);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct TemporalVertexResult
{
	float4 texcoord8 : TEXCOORD8;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float3 texcoord9 : TEXCOORD9;
};
struct VS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float3 texcoord9 : TEXCOORD9;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float2 temporalInput_texcoord : TEMPORAL1;
	float4 temporalInput_texcoord1 : TEMPORAL2;
	float4 temporalInput_texcoord2 : TEMPORAL3;
	float3 temporalInput_texcoord4 : TEMPORAL4;
	float4 temporalInput_texcoord5 : TEMPORAL5;
	float4 temporalInput_texcoord6 : TEMPORAL6;
	float3 temporalInput_texcoord9 : TEMPORAL7;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	row_major float4x4 Temporal_b7_o0_matWheelTransform : packoffset(c13);
	float4 Temporal_b7_o64_tyreDeformParams : packoffset(c17);
	float4 Temporal_b7_o80_tyreDeformParams2 : packoffset(c18);
	bool Temporal_b3_o0_tyreDeformSwitchOn : packoffset(c19);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	int3 r1;
	float3 r2;
	float3 r3;
	o.texcoord8.w = 1;
	r0.xyz = asint(i.position.yyy * matWheelTransform[1].xyz);
	r0.xyz = asint(i.position.xxx * matWheelTransform[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.position.zzz * matWheelTransform[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + matWheelTransform[3].xyz);
	o.texcoord8.xyz = asfloat(r0.xyz);
	o.texcoord = i.texcoord.xy;
	r0.w = asint(i.position.x * tyreDeformParams.x);
	r1.x = asint(tyreDeformParams2.y + 0.0299999993);
	r1.y = asint(-(asfloat(r0.z)) + asfloat(r1.x));
	r1.x = (asfloat(r0.z) < asfloat(r1.x)) ? -1 : 0;
	r1.y = asint(asfloat(r1.y) * tyreDeformParams2.z);
	r1.y = asint(min(asfloat(r1.y), 1));
	r2 = i.position.xyz * tyreDeformParams2.www;
	r1.z = asint(-(tyreDeformParams.w) * asfloat(r1.y) + r2.x);
	r3.x = asfloat(r0.w) * asfloat(r1.y) + asfloat(r1.z);
	r0.w = asint(-(asfloat(r0.z)) + tyreDeformParams2.y);
	o.texcoord6.xyz = asfloat(r0.xyz);
	r0.x = asint(max(asfloat(r0.w), 0));
	r3.yz = tyreDeformParams.yz * asfloat(r0.xx) + r2.yz;
	r0.xyz = asint((r1.xxx != 0) ? r3.xyz : r2.xyz);
	r0.w = asint(tyreDeformParams2.x * 1.10000002);
	r0.w = asint(asfloat(r0.w) * asfloat(r0.w));
	r1.x = asint(dot(i.position.yz, i.position.yz));
	r1.y = asint(asfloat(r1.x) * tyreDeformParams2.w);
	r0.w = (asfloat(r0.w) < asfloat(r1.y)) ? -1 : 0;
	r0.xyz = (r0.www != 0) ? r0.xyz : asint(r2.xyz);
	r0.w = asint(tyreDeformParams2.x * tyreDeformParams2.x);
	r0.w = (asfloat(r0.w) < asfloat(r1.x)) ? -1 : 0;
	r0.xyz = (r0.www != 0) ? r0.xyz : asint(i.position.xyz);
	r0.xyz = (tyreDeformSwitchOn != 0) ? r0.xyz : asint(i.position.xyz);
	r1 = asint(asfloat(r0.yyy) * matWheelTransform[1].xyz);
	r0.xyw = asint(asfloat(r0.xxx) * matWheelTransform[0].xyz + asfloat(r1.xyz));
	r0.xyz = asint(asfloat(r0.zzz) * matWheelTransform[2].xyz + asfloat(r0.xyw));
	r0.xyz = asint(asfloat(r0.xyz) + matWheelTransform[3].xyz);
	r0.y = asint(asfloat(r0.y) * gWorldViewProj[1].w);
	r0.x = asint(asfloat(r0.x) * gWorldViewProj[0].w + asfloat(r0.y));
	r0.x = asint(asfloat(r0.z) * gWorldViewProj[2].w + asfloat(r0.x));
	o.texcoord1.w = asfloat(r0.x) + gWorldViewProj[3].w;
	r0.xyz = asint(i.normal.yyy * matWheelTransform[1].xyz);
	r0.xyz = asint(i.normal.xxx * matWheelTransform[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.normal.zzz * matWheelTransform[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord1.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r0.xyz = asint(i.tangent.yyy * matWheelTransform[1].xyz);
	r0.xyz = asint(i.tangent.xxx * matWheelTransform[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.tangent.zzz * matWheelTransform[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord4 = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord5 = i.tangent.w;
	o.texcoord6.w = 1;
	o.texcoord9 = i.normal.xyz;

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	int3 r1;
	float3 r2;
	float3 r3;
	o.texcoord8.w = 1;
	r0.xyz = asint(i.position.yyy * Temporal_b7_o0_matWheelTransform[1].xyz);
	r0.xyz = asint(i.position.xxx * Temporal_b7_o0_matWheelTransform[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.position.zzz * Temporal_b7_o0_matWheelTransform[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + Temporal_b7_o0_matWheelTransform[3].xyz);
	o.texcoord8.xyz = asfloat(r0.xyz);
	o.texcoord = i.texcoord.xy;
	r0.w = asint(i.position.x * Temporal_b7_o64_tyreDeformParams.x);
	r1.x = asint(Temporal_b7_o80_tyreDeformParams2.y + 0.0299999993);
	r1.y = asint(-(asfloat(r0.z)) + asfloat(r1.x));
	r1.x = (asfloat(r0.z) < asfloat(r1.x)) ? -1 : 0;
	r1.y = asint(asfloat(r1.y) * Temporal_b7_o80_tyreDeformParams2.z);
	r1.y = asint(min(asfloat(r1.y), 1));
	r2 = i.position.xyz * Temporal_b7_o80_tyreDeformParams2.www;
	r1.z = asint(-(Temporal_b7_o64_tyreDeformParams.w) * asfloat(r1.y) + r2.x);
	r3.x = asfloat(r0.w) * asfloat(r1.y) + asfloat(r1.z);
	r0.w = asint(-(asfloat(r0.z)) + Temporal_b7_o80_tyreDeformParams2.y);
	o.texcoord6.xyz = asfloat(r0.xyz);
	r0.x = asint(max(asfloat(r0.w), 0));
	r3.yz = Temporal_b7_o64_tyreDeformParams.yz * asfloat(r0.xx) + r2.yz;
	r0.xyz = asint((r1.xxx != 0) ? r3.xyz : r2.xyz);
	r0.w = asint(Temporal_b7_o80_tyreDeformParams2.x * 1.10000002);
	r0.w = asint(asfloat(r0.w) * asfloat(r0.w));
	r1.x = asint(dot(i.position.yz, i.position.yz));
	r1.y = asint(asfloat(r1.x) * Temporal_b7_o80_tyreDeformParams2.w);
	r0.w = (asfloat(r0.w) < asfloat(r1.y)) ? -1 : 0;
	r0.xyz = (r0.www != 0) ? r0.xyz : asint(r2.xyz);
	r0.w = asint(Temporal_b7_o80_tyreDeformParams2.x * Temporal_b7_o80_tyreDeformParams2.x);
	r0.w = (asfloat(r0.w) < asfloat(r1.x)) ? -1 : 0;
	r0.xyz = (r0.www != 0) ? r0.xyz : asint(i.position.xyz);
	r0.xyz = (Temporal_b3_o0_tyreDeformSwitchOn != 0) ? r0.xyz : asint(i.position.xyz);
	r1 = asint(asfloat(r0.yyy) * Temporal_b7_o0_matWheelTransform[1].xyz);
	r0.xyw = asint(asfloat(r0.xxx) * Temporal_b7_o0_matWheelTransform[0].xyz + asfloat(r1.xyz));
	r0.xyz = asint(asfloat(r0.zzz) * Temporal_b7_o0_matWheelTransform[2].xyz + asfloat(r0.xyw));
	r0.xyz = asint(asfloat(r0.xyz) + Temporal_b7_o0_matWheelTransform[3].xyz);
	r0.y = asint(asfloat(r0.y) * Temporal_b0_o128_gWorldViewProj[1].w);
	r0.x = asint(asfloat(r0.x) * Temporal_b0_o128_gWorldViewProj[0].w + asfloat(r0.y));
	r0.x = asint(asfloat(r0.z) * Temporal_b0_o128_gWorldViewProj[2].w + asfloat(r0.x));
	o.texcoord1.w = asfloat(r0.x) + Temporal_b0_o128_gWorldViewProj[3].w;
	r0.xyz = asint(i.normal.yyy * Temporal_b7_o0_matWheelTransform[1].xyz);
	r0.xyz = asint(i.normal.xxx * Temporal_b7_o0_matWheelTransform[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.normal.zzz * Temporal_b7_o0_matWheelTransform[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord1.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord2.xyz = i.color.xyz;
	o.texcoord2.w = 1;
	r0.xyz = asint(i.tangent.yyy * Temporal_b7_o0_matWheelTransform[1].xyz);
	r0.xyz = asint(i.tangent.xxx * Temporal_b7_o0_matWheelTransform[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.tangent.zzz * Temporal_b7_o0_matWheelTransform[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord4 = asfloat(r0.www) * asfloat(r0.xyz);
	o.texcoord5 = i.tangent.w;
	o.texcoord6.w = 1;
	o.texcoord9 = i.normal.xyz;

	return o;
}

VS_OUT main(VS_IN i)
{
    TemporalVertexResult c = TemporalCurrent(i);
    VS_OUT o;
    o.texcoord8 = c.texcoord8;
    o.texcoord = c.texcoord;
    o.texcoord1 = c.texcoord1;
    o.texcoord2 = c.texcoord2;
    o.texcoord4 = c.texcoord4;
    o.texcoord5 = c.texcoord5;
    o.texcoord6 = c.texcoord6;
    o.texcoord9 = c.texcoord9;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord1 = o.texcoord1;
    o.temporalInput_texcoord2 = o.texcoord2;
    o.temporalInput_texcoord4 = o.texcoord4;
    o.temporalInput_texcoord5 = o.texcoord5;
    o.temporalInput_texcoord6 = o.texcoord6;
    o.temporalInput_texcoord9 = o.texcoord9;
    [branch] if (TemporalState.x > 0)
    {
        TemporalVertexResult p = TemporalVertexPrevious(i);
        o.temporalInput_texcoord8 = p.texcoord8;
        o.temporalInput_texcoord = p.texcoord;
        o.temporalInput_texcoord1 = p.texcoord1;
        o.temporalInput_texcoord2 = p.texcoord2;
        o.temporalInput_texcoord4 = p.texcoord4;
        o.temporalInput_texcoord5 = p.texcoord5;
        o.temporalInput_texcoord6 = p.texcoord6;
        o.temporalInput_texcoord9 = p.texcoord9;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
