cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gWorld : packoffset(c0);
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
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
};
struct VS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_color : TEMPORAL1;
	float2 temporalInput_texcoord : TEMPORAL2;
	float4 temporalInput_texcoord1 : TEMPORAL3;
	float3 temporalInput_texcoord4 : TEMPORAL4;
	float3 temporalInput_texcoord5 : TEMPORAL5;
	float4 temporalInput_texcoord6 : TEMPORAL6;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c1);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c5);
	float4 Temporal_b5_o0_globalScalars : packoffset(c9);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c10);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c11);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c12);
	float4 Temporal_b5_o64_globalFogParams : packoffset(c13);
	float4 Temporal_b5_o80_globalFogColor : packoffset(c14);
	float4 Temporal_b5_o96_globalFogOffsetN : packoffset(c15);
	float4 Temporal_b5_o112_globalFogColorN : packoffset(c16);
	float4 Temporal_b5_o128_globalScreenSize : packoffset(c17);
	float4 Temporal_b5_o144_globalDayNightEffects : packoffset(c18);
	float4 Temporal_b5_o160_ColorCorrectTopAndPedReflectScale : packoffset(c19);
	float4 Temporal_b5_o176_ColorCorrectBottomOffset : packoffset(c20);
	float4 Temporal_b5_o192_ColorShift : packoffset(c21);
	float4 Temporal_b5_o208_deSatContrastGamma : packoffset(c22);
	float4 Temporal_b5_o224_deSatContrastGammaIFX : packoffset(c23);
	float4 Temporal_b5_o240_colorize : packoffset(c24);
	float4 Temporal_b5_o256_globalUmScalars : packoffset(c25);
	float4 Temporal_b5_o272_gToneMapScalers : packoffset(c26);
	float4 Temporal_b5_o288_gAmbientOcclusionEffect : packoffset(c27);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	float4 r0;
	float3 r1;
	float3 r2;
	o.texcoord8.xyz = i.position.xyz;
	o.texcoord8.w = 1;
	r0.x = dot(i.color.xy, globalDayNightEffects.zw);
	r0.x = r0.x * globalScalars.z + -1;
	r0.x = gAmbientOcclusionEffect.x * r0.x + 1;
	o.color.xy = r0.xx * gAmbientOcclusionEffect.yy;
	o.color.zw = i.color.zw;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * gWorld[1].xyz;
	r0.xyz = i.normal.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord1.xyz = r0.xyz;
	o.texcoord1.w = 1;
	r1 = i.tangent.yyy * gWorld[1].xyz;
	r1 = i.tangent.xxx * gWorld[0].xyz + r1.xyz;
	r1 = i.tangent.zzz * gWorld[2].xyz + r1.xyz;
	r1 = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1 = r0.www * r1.xyz;
	o.texcoord4 = r1.xyz;
	r2 = r0.yzx * r1.zxy;
	r0.xyz = r1.yzx * r0.zxy + -(r2.xyz);
	o.texcoord5 = r0.xyz * i.tangent.www;
	r0.xyz = i.position.yyy * gWorld[1].xyz;
	r0.xyz = i.position.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.position.zzz * gWorld[2].xyz + r0.xyz;
	o.texcoord6.xyz = r0.xyz + gWorld[3].xyz;
	o.texcoord6.w = 1;

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	float4 r0;
	float3 r1;
	float3 r2;
	o.texcoord8.xyz = i.position.xyz;
	o.texcoord8.w = 1;
	r0.x = dot(i.color.xy, Temporal_b5_o144_globalDayNightEffects.zw);
	r0.x = r0.x * Temporal_b5_o0_globalScalars.z + -1;
	r0.x = Temporal_b5_o288_gAmbientOcclusionEffect.x * r0.x + 1;
	o.color.xy = r0.xx * Temporal_b5_o288_gAmbientOcclusionEffect.yy;
	o.color.zw = i.color.zw;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord1.xyz = r0.xyz;
	o.texcoord1.w = 1;
	r1 = i.tangent.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r1 = i.tangent.xxx * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	r1 = i.tangent.zzz * Temporal_b0_o0_gWorld[2].xyz + r1.xyz;
	r1 = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1 = r0.www * r1.xyz;
	o.texcoord4 = r1.xyz;
	r2 = r0.yzx * r1.zxy;
	r0.xyz = r1.yzx * r0.zxy + -(r2.xyz);
	o.texcoord5 = r0.xyz * i.tangent.www;
	r0.xyz = i.position.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = i.position.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0.xyz = i.position.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	o.texcoord6.xyz = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;
	o.texcoord6.w = 1;

	return o;
}

VS_OUT main(VS_IN i)
{
    TemporalVertexResult c = TemporalCurrent(i);
    VS_OUT o;
    o.texcoord8 = c.texcoord8;
    o.color = c.color;
    o.texcoord = c.texcoord;
    o.texcoord1 = c.texcoord1;
    o.texcoord4 = c.texcoord4;
    o.texcoord5 = c.texcoord5;
    o.texcoord6 = c.texcoord6;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_color = o.color;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord1 = o.texcoord1;
    o.temporalInput_texcoord4 = o.texcoord4;
    o.temporalInput_texcoord5 = o.texcoord5;
    o.temporalInput_texcoord6 = o.texcoord6;
    [branch] if (TemporalState.x > 0)
    {
        TemporalVertexResult p = TemporalVertexPrevious(i);
        o.temporalInput_texcoord8 = p.texcoord8;
        o.temporalInput_color = p.color;
        o.temporalInput_texcoord = p.texcoord;
        o.temporalInput_texcoord1 = p.texcoord1;
        o.temporalInput_texcoord4 = p.texcoord4;
        o.temporalInput_texcoord5 = p.texcoord5;
        o.temporalInput_texcoord6 = p.texcoord6;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
