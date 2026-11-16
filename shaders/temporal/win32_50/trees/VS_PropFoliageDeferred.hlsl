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
};

cbuffer Movement : register(b1)
{
	float4 umGlobalParams : packoffset(c0);
	float4 WindGlobalParams : packoffset(c1);
};

struct VS_IN
{
	float3 position : POSITION;
	float3 normal : NORMAL;
	float4 color : COLOR;
	float4 color1 : COLOR1;
	float2 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float3 texcoord : TEXCOORD;
	float3 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
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
	float4 Temporal_b1_o0_umGlobalParams : packoffset(c30);
	float4 Temporal_b1_o16_WindGlobalParams : packoffset(c31);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	r0.x = i.color1.y * 6.28318548;
	r0.yzw = globalUmScalars.zzw * umGlobalParams.zzw;
	r0.xyz = globalScalars2.yyy * r0.yzw + r0.xxx;
	r0.xyz = sin(r0.xyz);
	r0.w = i.color1.x * globalUmScalars.x;
	r1.xy = r0.ww * umGlobalParams.xx;
	r0.w = -(i.color1.z) + 1;
	r1.w = r0.w * globalUmScalars.y;
	r0.w = r0.w * WindGlobalParams.x;
	r1.z = r1.w * umGlobalParams.y;
	r0.xyz = r0.xyz * r1.xyz + i.position.xyz;
	r1.x = r0.z * deSatContrastGamma.w;
	r0.xy = r1.xx * r0.ww + r0.xy;
	r1 = r0.y * gWorldViewProj[1];
	r1 = r0.x * gWorldViewProj[0] + r1;
	r0 = r0.z * gWorldViewProj[2] + r1;
	o.sv_position = r0 + gWorldViewProj[3];
	o.texcoord.xy = i.texcoord.xy;
	o.texcoord.z = i.color.w;
	r0.xyz = i.normal.yyy * gWorld[1].xyz;
	r0.xyz = i.normal.xxx * gWorld[0].xyz + r0.xyz;
	o.texcoord1 = i.normal.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = i.position.yyy * gWorld[1].xyz;
	r0.xyz = i.position.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.position.zzz * gWorld[2].xyz + r0.xyz;
	o.texcoord3 = r0.xyz + gWorld[3].xyz;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	r0.x = i.color1.y * 6.28318548;
	r0.yzw = Temporal_b5_o256_globalUmScalars.zzw * Temporal_b1_o0_umGlobalParams.zzw;
	r0.xyz = Temporal_b5_o16_globalScalars2.yyy * r0.yzw + r0.xxx;
	r0.xyz = sin(r0.xyz);
	r0.w = i.color1.x * Temporal_b5_o256_globalUmScalars.x;
	r1.xy = r0.ww * Temporal_b1_o0_umGlobalParams.xx;
	r0.w = -(i.color1.z) + 1;
	r1.w = r0.w * Temporal_b5_o256_globalUmScalars.y;
	r0.w = r0.w * Temporal_b1_o16_WindGlobalParams.x;
	r1.z = r1.w * Temporal_b1_o0_umGlobalParams.y;
	r0.xyz = r0.xyz * r1.xyz + i.position.xyz;
	r1.x = r0.z * Temporal_b5_o208_deSatContrastGamma.w;
	r0.xy = r1.xx * r0.ww + r0.xy;
	r1 = r0.y * Temporal_b0_o128_gWorldViewProj[1];
	r1 = r0.x * Temporal_b0_o128_gWorldViewProj[0] + r1;
	r0 = r0.z * Temporal_b0_o128_gWorldViewProj[2] + r1;
	o.sv_position = r0 + Temporal_b0_o128_gWorldViewProj[3];
	o.texcoord.xy = i.texcoord.xy;
	o.texcoord.z = i.color.w;
	r0.xyz = i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	o.texcoord1 = i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	r0.xyz = i.position.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = i.position.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0.xyz = i.position.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	o.texcoord3 = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;

	return o;
}

VS_OUT main(VS_IN i)
{
    VS_OUT o = TemporalCurrent(i);
    o.temporalPrevious = float3(0, 0, -1);

    [branch] if (TemporalState.x > 0)
    {
        o.temporalPrevious = TemporalVertexPrevious(i).sv_position.xyw;
    }
    return o;
}
