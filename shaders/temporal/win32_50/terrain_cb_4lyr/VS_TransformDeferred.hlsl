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
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float4 color1 : COLOR1;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 color : COLOR;
	float3 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
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
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float3 r1;
	float3 r2;
	r0 = i.position.y * gWorldViewProj[1];
	r0 = i.position.x * gWorldViewProj[0] + r0;
	r0 = i.position.z * gWorldViewProj[2] + r0;
	o.sv_position = r0 + gWorldViewProj[3];
	o.texcoord = i.texcoord.xy;
	o.color = i.color1;
	r0.xyz = i.normal.yyy * gWorld[1].xyz;
	r0.xyz = i.normal.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord2 = r0.xyz;
	r0.w = dot(i.color.xy, globalDayNightEffects.zw);
	r0.w = r0.w * globalScalars.z + -1;
	r0.w = gAmbientOcclusionEffect.x * r0.w + 1;
	o.texcoord3.w = r0.w * gAmbientOcclusionEffect.y;
	o.texcoord3.xyz = float3(1, 1, 1);
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

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float3 r1;
	float3 r2;
	r0 = i.position.y * Temporal_b0_o128_gWorldViewProj[1];
	r0 = i.position.x * Temporal_b0_o128_gWorldViewProj[0] + r0;
	r0 = i.position.z * Temporal_b0_o128_gWorldViewProj[2] + r0;
	o.sv_position = r0 + Temporal_b0_o128_gWorldViewProj[3];
	o.texcoord = i.texcoord.xy;
	o.color = i.color1;
	r0.xyz = i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord2 = r0.xyz;
	r0.w = dot(i.color.xy, Temporal_b5_o144_globalDayNightEffects.zw);
	r0.w = r0.w * Temporal_b5_o0_globalScalars.z + -1;
	r0.w = Temporal_b5_o288_gAmbientOcclusionEffect.x * r0.w + 1;
	o.texcoord3.w = r0.w * Temporal_b5_o288_gAmbientOcclusionEffect.y;
	o.texcoord3.xyz = float3(1, 1, 1);
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
