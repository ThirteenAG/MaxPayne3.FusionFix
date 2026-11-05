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
	float4 texcoord : TEXCOORD;
	float4 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float4 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
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
	float4 Temporal_b4_o0_gWindParams : packoffset(c36);
	float4 Temporal_b4_o16_AirResist : packoffset(c37);
	float Temporal_b4_o32_WindStr : packoffset(c38);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float3 r2;
	float3 r3;
	r0.x = asint(saturate(WindStr));
	r0.yz = asint(i.position.xy * float2(6, 4));
	r1.xy = AirResist.ww * float2(4, 1.5) + float2(1, 1);
	r0.y = asint(globalScalars3.y * r1.y + asfloat(r0.y));
	r0.y = asint(sin(asfloat(r0.y)));
	r0.x = asint(abs(asfloat(r0.y)) * asfloat(r0.x));
	r0.y = asint(dot(i.position.xzy, float3(10, 10, 10)));
	r0.w = asint(r1.y * globalScalars3.y);
	r1.xyz = r1.xxx * i.color1.xxz;
	r1.xyz = -(r1.xyz) * i.normal.xyz;
	r0.y = asint(asfloat(r0.w) * gWindParams.z + asfloat(r0.y));
	r0.z = asint(asfloat(r0.w) * gWindParams.w + asfloat(r0.z));
	r0.yz = asint(sin(asfloat(r0.yz)));
	r0.x = asint(abs(asfloat(r0.y)) * asfloat(r0.x));
	r0.x = asint(abs(asfloat(r0.z)) * asfloat(r0.x));
	r2.x = globalScalars3.z + 0.00000999999975;
	r2.y = globalScalars4.z + 0.00000999999975;
	r2.z = 0.00000999999975;
	r0.y = asint(dot(r2.xyz, r2.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r0.yzw = asint(asfloat(r0.yyy) * r2.xyz);
	r0.y = asint(dot(asfloat(r0.yzw), i.normal.xyz));
	r0.y = asint(max(asfloat(r0.y), 0.25));
	r0.y = asint(min(asfloat(r0.y), 1));
	r2 = i.normal.yyy * gWorld[1].xyz;
	r2 = i.normal.xxx * gWorld[0].xyz + r2.xyz;
	r2 = i.normal.zzz * gWorld[2].xyz + r2.xyz;
	r2 = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = asint(dot(r2.xyz, r2.xyz));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r2 = asfloat(r0.zzz) * r2.xyz;
	r0.z = asint(saturate(dot(AirResist.xzy, r2.xyz)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(-(asfloat(r0.z)) * AirResist.w + 1);
	r0.w = (0.800000012 < asfloat(r0.z)) ? -1 : 0;
	r0.z = (r0.w != 0) ? 1065353216 : r0.z;
	r1.xyz = asfloat(r0.zzz) * r1.xyz;
	r0.yzw = asint(asfloat(r0.yyy) * r1.xyz);
	r0.xyz = asint(asfloat(r0.yzw) * asfloat(r0.xxx) + i.position.xyz);
	r1 = asfloat(r0.y) * gWorldViewProj[1];
	r1 = asfloat(r0.x) * gWorldViewProj[0] + r1;
	r0 = asint(asfloat(r0.z) * gWorldViewProj[2] + r1);
	r0 = asint(asfloat(r0) + gWorldViewProj[3]);
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	o.texcoord = i.texcoord;
	o.texcoord1.xyz = r2.xyz;
	r0.x = asint(i.color.x * globalScalars.z + -1);
	r0.x = asint(gAmbientOcclusionEffect.y * asfloat(r0.x) + 1);
	r0.y = asint(1 / gAmbientOcclusionEffect.y);
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x));
	o.texcoord2.x = min(asfloat(r0.x), 1);
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	r0.xyz = asint(i.position.yyy * gWorld[1].xyz);
	r0.xyz = asint(i.position.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.position.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + gWorld[3].xyz);
	r1.xyz = -(asfloat(r0.xyz)) + gViewInverse[3].xyz;
	o.texcoord7 = asfloat(r0.xyz);
	o.texcoord3 = r1.xyz;
	r0.xyz = asint(i.tangent.yyy * gWorld[1].xyz);
	r0.xyz = asint(i.tangent.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.tangent.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	o.texcoord4.xyz = asfloat(r0.xyz);
	o.texcoord4.w = i.position.z;
	r3 = r2.yzx * asfloat(r0.zxy);
	r3 = asfloat(r0.yzx) * r2.zxy + -(r3.xyz);
	o.texcoord6.z = dot(r2.xyz, r1.xyz);
	o.texcoord6.x = dot(asfloat(r0.xyz), r1.xyz);
	r0.xyz = asint(r3.xyz * i.tangent.www);
	o.texcoord5.xyz = asfloat(r0.xyz);
	o.texcoord6.y = dot(asfloat(r0.xyz), r1.xyz);
	o.texcoord5.w = i.tangent.w;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float3 r2;
	float3 r3;
	r0.x = asint(saturate(Temporal_b4_o32_WindStr));
	r0.yz = asint(i.position.xy * float2(6, 4));
	r1.xy = Temporal_b4_o16_AirResist.ww * float2(4, 1.5) + float2(1, 1);
	r0.y = asint(Temporal_b5_o32_globalScalars3.y * r1.y + asfloat(r0.y));
	r0.y = asint(sin(asfloat(r0.y)));
	r0.x = asint(abs(asfloat(r0.y)) * asfloat(r0.x));
	r0.y = asint(dot(i.position.xzy, float3(10, 10, 10)));
	r0.w = asint(r1.y * Temporal_b5_o32_globalScalars3.y);
	r1.xyz = r1.xxx * i.color1.xxz;
	r1.xyz = -(r1.xyz) * i.normal.xyz;
	r0.y = asint(asfloat(r0.w) * Temporal_b4_o0_gWindParams.z + asfloat(r0.y));
	r0.z = asint(asfloat(r0.w) * Temporal_b4_o0_gWindParams.w + asfloat(r0.z));
	r0.yz = asint(sin(asfloat(r0.yz)));
	r0.x = asint(abs(asfloat(r0.y)) * asfloat(r0.x));
	r0.x = asint(abs(asfloat(r0.z)) * asfloat(r0.x));
	r2.x = Temporal_b5_o32_globalScalars3.z + 0.00000999999975;
	r2.y = Temporal_b5_o48_globalScalars4.z + 0.00000999999975;
	r2.z = 0.00000999999975;
	r0.y = asint(dot(r2.xyz, r2.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r0.yzw = asint(asfloat(r0.yyy) * r2.xyz);
	r0.y = asint(dot(asfloat(r0.yzw), i.normal.xyz));
	r0.y = asint(max(asfloat(r0.y), 0.25));
	r0.y = asint(min(asfloat(r0.y), 1));
	r2 = i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r2 = i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r2 = i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + r2.xyz;
	r2 = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = asint(dot(r2.xyz, r2.xyz));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r2 = asfloat(r0.zzz) * r2.xyz;
	r0.z = asint(saturate(dot(Temporal_b4_o16_AirResist.xzy, r2.xyz)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(-(asfloat(r0.z)) * Temporal_b4_o16_AirResist.w + 1);
	r0.w = (0.800000012 < asfloat(r0.z)) ? -1 : 0;
	r0.z = (r0.w != 0) ? 1065353216 : r0.z;
	r1.xyz = asfloat(r0.zzz) * r1.xyz;
	r0.yzw = asint(asfloat(r0.yyy) * r1.xyz);
	r0.xyz = asint(asfloat(r0.yzw) * asfloat(r0.xxx) + i.position.xyz);
	r1 = asfloat(r0.y) * Temporal_b0_o128_gWorldViewProj[1];
	r1 = asfloat(r0.x) * Temporal_b0_o128_gWorldViewProj[0] + r1;
	r0 = asint(asfloat(r0.z) * Temporal_b0_o128_gWorldViewProj[2] + r1);
	r0 = asint(asfloat(r0) + Temporal_b0_o128_gWorldViewProj[3]);
	o.sv_position = asfloat(r0);
	o.texcoord1.w = asfloat(r0.w);
	o.texcoord = i.texcoord;
	o.texcoord1.xyz = r2.xyz;
	r0.x = asint(i.color.x * Temporal_b5_o0_globalScalars.z + -1);
	r0.x = asint(Temporal_b5_o288_gAmbientOcclusionEffect.y * asfloat(r0.x) + 1);
	r0.y = asint(1 / Temporal_b5_o288_gAmbientOcclusionEffect.y);
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x));
	o.texcoord2.x = min(asfloat(r0.x), 1);
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	r0.xyz = asint(i.position.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(i.position.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.position.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + Temporal_b0_o0_gWorld[3].xyz);
	r1.xyz = -(asfloat(r0.xyz)) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = asfloat(r0.xyz);
	o.texcoord3 = r1.xyz;
	r0.xyz = asint(i.tangent.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(i.tangent.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.tangent.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	o.texcoord4.xyz = asfloat(r0.xyz);
	o.texcoord4.w = i.position.z;
	r3 = r2.yzx * asfloat(r0.zxy);
	r3 = asfloat(r0.yzx) * r2.zxy + -(r3.xyz);
	o.texcoord6.z = dot(r2.xyz, r1.xyz);
	o.texcoord6.x = dot(asfloat(r0.xyz), r1.xyz);
	r0.xyz = asint(r3.xyz * i.tangent.www);
	o.texcoord5.xyz = asfloat(r0.xyz);
	o.texcoord6.y = dot(asfloat(r0.xyz), r1.xyz);
	o.texcoord5.w = i.tangent.w;

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
