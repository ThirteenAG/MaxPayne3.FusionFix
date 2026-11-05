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

cbuffer PedWind : register(b4)
{
	float4 gWindParams : packoffset(c0);
	float4 AirResist : packoffset(c1);
	float WindStr : packoffset(c2);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float4 color1 : COLOR1;
	float2 texcoord : TEXCOORD;
	float4 normal : NORMAL;
	float4 tangent : TANGENT;
	float3 position1 : POSITION1;
	float3 normal1 : NORMAL1;
	float4 tangent1 : TANGENT1;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
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
	float4 Temporal_b4_o0_gWindParams : packoffset(c32);
	float4 Temporal_b4_o16_AirResist : packoffset(c33);
	float Temporal_b4_o32_WindStr : packoffset(c34);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	r0.x = globalScalars3.z + 0.00000999999975;
	r0.y = globalScalars4.z + 0.00000999999975;
	r0.z = 0.00000999999975;
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r1.xyz = i.normal.xyz + i.normal1.xyz;
	r0.x = dot(r0.xyz, r1.xyz);
	r0.x = max(r0.x, 0.25);
	r0.x = min(r0.x, 1);
	r0.y = i.color1.z * AirResist.w;
	r0.y = r0.y * 5;
	r2.z = -(r0.y);
	r2.xy = -(i.color1.xx);
	r0.yzw = r1.xyz * r2.xyz;
	r0.xyz = r0.xxx * r0.yzw;
	r0.w = saturate(WindStr);
	r1.w = AirResist.w * 0.00999999978 + 1;
	r2.xyz = i.position.xyz + i.position1.xyz;
	r3.xy = r2.xy * float2(6, 4);
	r2.w = globalScalars3.y * r1.w + r3.x;
	r1.w = r1.w * globalScalars3.y;
	r3.x = r1.w * gWindParams.w + r3.y;
	r3.x = sin(r3.x);
	r2.w = sin(r2.w);
	r0.w = r0.w * abs(r2.w);
	r2.w = dot(r2.xzy, float3(10, 10, 10));
	r1.w = r1.w * gWindParams.z + r2.w;
	r1.w = sin(r1.w);
	r0.w = r0.w * abs(r1.w);
	r0.w = abs(r3.x) * r0.w;
	r0.xyz = r0.xyz * r0.www + r2.xyz;
	r3 = r0.y * gWorldViewProj[1];
	r3 = r0.x * gWorldViewProj[0] + r3;
	r0 = r0.z * gWorldViewProj[2] + r3;
	r0 = r0 + gWorldViewProj[3];
	o.sv_position = r0;
	o.texcoord1.w = r0.w;
	o.texcoord = i.texcoord.xy;
	r0.xyz = r1.yyy * gWorld[1].xyz;
	r0.xyz = r1.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = r1.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord1.xyz = r0.xyz;
	r0.w = i.color.x * globalScalars.z + -1;
	r0.w = gAmbientOcclusionEffect.y * r0.w + 1;
	r1.x = 1 / gAmbientOcclusionEffect.y;
	r0.w = r0.w * r1.x;
	o.texcoord2.x = min(r0.w, 1);
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	r1 = i.tangent + i.tangent1;
	r3.xyz = r1.yyy * gWorld[1].xyz;
	r3.xyz = r1.xxx * gWorld[0].xyz + r3.xyz;
	r1.xyz = r1.zzz * gWorld[2].xyz + r3.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord4 = r1.xyz;
	r3.xyz = r0.yzx * r1.zxy;
	r0.xyz = r1.yzx * r0.zxy + -(r3.xyz);
	o.texcoord5.xyz = r1.www * r0.xyz;
	o.texcoord5.w = r1.w;
	r0.xyz = r2.yyy * gWorld[1].xyz;
	r0.xyz = r2.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = r2.zzz * gWorld[2].xyz + r0.xyz;
	o.texcoord7 = r0.xyz + gWorld[3].xyz;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	r0.x = Temporal_b5_o32_globalScalars3.z + 0.00000999999975;
	r0.y = Temporal_b5_o48_globalScalars4.z + 0.00000999999975;
	r0.z = 0.00000999999975;
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r1.xyz = i.normal.xyz + i.normal1.xyz;
	r0.x = dot(r0.xyz, r1.xyz);
	r0.x = max(r0.x, 0.25);
	r0.x = min(r0.x, 1);
	r0.y = i.color1.z * Temporal_b4_o16_AirResist.w;
	r0.y = r0.y * 5;
	r2.z = -(r0.y);
	r2.xy = -(i.color1.xx);
	r0.yzw = r1.xyz * r2.xyz;
	r0.xyz = r0.xxx * r0.yzw;
	r0.w = saturate(Temporal_b4_o32_WindStr);
	r1.w = Temporal_b4_o16_AirResist.w * 0.00999999978 + 1;
	r2.xyz = i.position.xyz + i.position1.xyz;
	r3.xy = r2.xy * float2(6, 4);
	r2.w = Temporal_b5_o32_globalScalars3.y * r1.w + r3.x;
	r1.w = r1.w * Temporal_b5_o32_globalScalars3.y;
	r3.x = r1.w * Temporal_b4_o0_gWindParams.w + r3.y;
	r3.x = sin(r3.x);
	r2.w = sin(r2.w);
	r0.w = r0.w * abs(r2.w);
	r2.w = dot(r2.xzy, float3(10, 10, 10));
	r1.w = r1.w * Temporal_b4_o0_gWindParams.z + r2.w;
	r1.w = sin(r1.w);
	r0.w = r0.w * abs(r1.w);
	r0.w = abs(r3.x) * r0.w;
	r0.xyz = r0.xyz * r0.www + r2.xyz;
	r3 = r0.y * Temporal_b0_o128_gWorldViewProj[1];
	r3 = r0.x * Temporal_b0_o128_gWorldViewProj[0] + r3;
	r0 = r0.z * Temporal_b0_o128_gWorldViewProj[2] + r3;
	r0 = r0 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r0;
	o.texcoord1.w = r0.w;
	o.texcoord = i.texcoord.xy;
	r0.xyz = r1.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = r1.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0.xyz = r1.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord1.xyz = r0.xyz;
	r0.w = i.color.x * Temporal_b5_o0_globalScalars.z + -1;
	r0.w = Temporal_b5_o288_gAmbientOcclusionEffect.y * r0.w + 1;
	r1.x = 1 / Temporal_b5_o288_gAmbientOcclusionEffect.y;
	r0.w = r0.w * r1.x;
	o.texcoord2.x = min(r0.w, 1);
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	r1 = i.tangent + i.tangent1;
	r3.xyz = r1.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r3.xyz = r1.xxx * Temporal_b0_o0_gWorld[0].xyz + r3.xyz;
	r1.xyz = r1.zzz * Temporal_b0_o0_gWorld[2].xyz + r3.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord4 = r1.xyz;
	r3.xyz = r0.yzx * r1.zxy;
	r0.xyz = r1.yzx * r0.zxy + -(r3.xyz);
	o.texcoord5.xyz = r1.www * r0.xyz;
	o.texcoord5.w = r1.w;
	r0.xyz = r2.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = r2.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0.xyz = r2.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	o.texcoord7 = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;

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
