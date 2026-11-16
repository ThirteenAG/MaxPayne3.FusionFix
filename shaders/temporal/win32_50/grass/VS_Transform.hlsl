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

cbuffer PlanetAttributes : register(b4)
{
	row_major float4x4 matGrassTransform : packoffset(c0);
	float4 plantColor : packoffset(c4);
	float4 groundColor : packoffset(c5);
	float3 vecCameraPos : packoffset(c6);
	float3 vecPlayerPos : packoffset(c7);
	float4 _dimensionLOD2 : packoffset(c8);
	float2 _vecCollParams : packoffset(c9);
	float4 _vecVehCollB : packoffset(c10);
	float4 _vecVehCollM : packoffset(c11);
	float4 _vecVehCollR : packoffset(c12);
	float4 fadeAlphaDistUmTimer : packoffset(c13);
	float4 fadeAlphaLOD1Dist : packoffset(c14);
	float4 fadeAlphaLOD2Dist : packoffset(c15);
	float4 uMovementParams : packoffset(c16);
	float4 _fakedGrassNormal : packoffset(c17);
};

cbuffer grasscollide : register(b7)
{
	bool bVehCollEnabled : packoffset(c0);
};

struct VS_IN
{
	float4 position : POSITION;
	float4 color : COLOR;
	float4 color1 : COLOR1;
	float2 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
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
	row_major float4x4 Temporal_b4_o0_matGrassTransform : packoffset(c30);
	float4 Temporal_b4_o64_plantColor : packoffset(c34);
	float4 Temporal_b4_o80_groundColor : packoffset(c35);
	float3 Temporal_b4_o96_vecCameraPos : packoffset(c36);
	float3 Temporal_b4_o112_vecPlayerPos : packoffset(c37);
	float4 Temporal_b4_o128__dimensionLOD2 : packoffset(c38);
	float2 Temporal_b4_o144__vecCollParams : packoffset(c39);
	float4 Temporal_b4_o160__vecVehCollB : packoffset(c40);
	float4 Temporal_b4_o176__vecVehCollM : packoffset(c41);
	float4 Temporal_b4_o192__vecVehCollR : packoffset(c42);
	float4 Temporal_b4_o208_fadeAlphaDistUmTimer : packoffset(c43);
	float4 Temporal_b4_o224_fadeAlphaLOD1Dist : packoffset(c44);
	float4 Temporal_b4_o240_fadeAlphaLOD2Dist : packoffset(c45);
	float4 Temporal_b4_o256_uMovementParams : packoffset(c46);
	float4 Temporal_b4_o272__fakedGrassNormal : packoffset(c47);
	bool Temporal_b7_o0_bVehCollEnabled : packoffset(c48);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	r0.x = asint(i.color.y * 6.28318548);
	r0.yzw = asint(globalUmScalars.zzw * uMovementParams.zzw);
	r0.xyz = asint(fadeAlphaDistUmTimer.zzz * asfloat(r0.yzw) + asfloat(r0.xxx));
	r0.xyz = asint(sin(asfloat(r0.xyz)));
	r0.w = asint(-(i.color.z) + 1);
	r0.w = asint(asfloat(r0.w) * globalUmScalars.y);
	r1.z = asfloat(r0.w) * uMovementParams.y;
	r0.w = asint(i.color.x * globalUmScalars.x);
	r1.xy = asfloat(r0.ww) * uMovementParams.xx;
	r0.xyz = asint(asfloat(r0.xyz) * r1.xyz + i.position.xyz);
	r1.xyz = asfloat(r0.yyy) * matGrassTransform[1].xyz;
	r0.xyw = asint(asfloat(r0.xxx) * matGrassTransform[0].xyz + r1.xyz);
	r0.xyz = asint(asfloat(r0.zzz) * matGrassTransform[2].xyz + asfloat(r0.xyw));
	r0.xyz = asint(asfloat(r0.xyz) + matGrassTransform[3].xyz);
	r1.xyz = asfloat(r0.xyz) + -(vecPlayerPos.xyz);
	r0.w = asint(dot(r1.xyz, r1.xyz));
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = asint(-(asfloat(r0.w)) + _vecCollParams.x);
	r0.w = asint(saturate(asfloat(r0.w) * _vecCollParams.y));
	r0.w = asint(asfloat(r0.w) * 0.5);
	r1.z = dot(r1.xyz, r1.xyz);
	r1.z = rsqrt(r1.z);
	r1.xy = r1.zz * r1.xy;
	r1.xy = asfloat(r0.ww) * r1.xy;
	r1.xy = r1.xy * i.color1.zz + asfloat(r0.xy);
	r2.xy = r1.xy + -(_vecVehCollB.xy);
	r0.w = asint(dot(_vecVehCollM.xy, r2.xy));
	r0.w = asint(saturate(asfloat(r0.w) * _vecVehCollM.w));
	r2.xy = asfloat(r0.ww) * _vecVehCollM.xy + _vecVehCollB.xy;
	r2.xy = r1.xy + -(r2.xy);
	r0.w = asint(dot(r2.xy, r2.xy));
	r2.xy = r2.xy + float2(0.00000999999975, 0.00000999999975);
	r1.w = -(asfloat(r0.w)) + _vecVehCollR.y;
	r1.w = saturate(r1.w * _vecVehCollR.z);
	r2.z = -(asfloat(r0.z)) + _vecVehCollR.w;
	r2.z = r1.w * r2.z + asfloat(r0.z);
	r1.w = r1.w * _vecVehCollR.x;
	r2.w = _vecVehCollR.x * 0.5;
	r2.w = r2.w * r2.w;
	r0.w = (asfloat(r0.w) < r2.w) ? -1 : 0;
	r2.w = _vecVehCollR.w + -0.25;
	r3.z = (r0.w != 0) ? r2.w : r2.z;
	r0.w = asint(dot(r2.xy, r2.xy));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r2.xy = asfloat(r0.ww) * r2.xy;
	r2.xy = r1.ww * r2.xy;
	r3.xy = r2.xy * i.color1.zz + r1.xy;
	r1.z = asfloat(r0.z);
	o.texcoord2.xyz = asfloat(r0.xyz);
	r0.xyz = asint((bVehCollEnabled != 0) ? r3.xyz : r1.xyz);
	r1 = asfloat(r0.y) * gWorldViewProj[1];
	r1 = asfloat(r0.x) * gWorldViewProj[0] + r1;
	r1 = asfloat(r0.z) * gWorldViewProj[2] + r1;
	r0.xy = asint(asfloat(r0.xy) + -(vecCameraPos.xy));
	r0.x = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.x = asint(saturate(asfloat(r0.x) * fadeAlphaDistUmTimer.y + fadeAlphaDistUmTimer.x));
	o.texcoord.w = asfloat(r0.x) * plantColor.w;
	o.sv_position = r1 + gWorldViewProj[3];
	o.texcoord.xyz = plantColor.xyz;
	o.texcoord1.xyz = _fakedGrassNormal.xyz;
	o.texcoord1.w = i.texcoord.x;
	o.texcoord2.w = i.texcoord.y;
	o.texcoord3.xyz = groundColor.xyz;
	o.texcoord3.w = i.color1.x;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	r0.x = asint(i.color.y * 6.28318548);
	r0.yzw = asint(Temporal_b5_o256_globalUmScalars.zzw * Temporal_b4_o256_uMovementParams.zzw);
	r0.xyz = asint(Temporal_b4_o208_fadeAlphaDistUmTimer.zzz * asfloat(r0.yzw) + asfloat(r0.xxx));
	r0.xyz = asint(sin(asfloat(r0.xyz)));
	r0.w = asint(-(i.color.z) + 1);
	r0.w = asint(asfloat(r0.w) * Temporal_b5_o256_globalUmScalars.y);
	r1.z = asfloat(r0.w) * Temporal_b4_o256_uMovementParams.y;
	r0.w = asint(i.color.x * Temporal_b5_o256_globalUmScalars.x);
	r1.xy = asfloat(r0.ww) * Temporal_b4_o256_uMovementParams.xx;
	r0.xyz = asint(asfloat(r0.xyz) * r1.xyz + i.position.xyz);
	r1.xyz = asfloat(r0.yyy) * Temporal_b4_o0_matGrassTransform[1].xyz;
	r0.xyw = asint(asfloat(r0.xxx) * Temporal_b4_o0_matGrassTransform[0].xyz + r1.xyz);
	r0.xyz = asint(asfloat(r0.zzz) * Temporal_b4_o0_matGrassTransform[2].xyz + asfloat(r0.xyw));
	r0.xyz = asint(asfloat(r0.xyz) + Temporal_b4_o0_matGrassTransform[3].xyz);
	r1.xyz = asfloat(r0.xyz) + -(Temporal_b4_o112_vecPlayerPos.xyz);
	r0.w = asint(dot(r1.xyz, r1.xyz));
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = asint(-(asfloat(r0.w)) + Temporal_b4_o144__vecCollParams.x);
	r0.w = asint(saturate(asfloat(r0.w) * Temporal_b4_o144__vecCollParams.y));
	r0.w = asint(asfloat(r0.w) * 0.5);
	r1.z = dot(r1.xyz, r1.xyz);
	r1.z = rsqrt(r1.z);
	r1.xy = r1.zz * r1.xy;
	r1.xy = asfloat(r0.ww) * r1.xy;
	r1.xy = r1.xy * i.color1.zz + asfloat(r0.xy);
	r2.xy = r1.xy + -(Temporal_b4_o160__vecVehCollB.xy);
	r0.w = asint(dot(Temporal_b4_o176__vecVehCollM.xy, r2.xy));
	r0.w = asint(saturate(asfloat(r0.w) * Temporal_b4_o176__vecVehCollM.w));
	r2.xy = asfloat(r0.ww) * Temporal_b4_o176__vecVehCollM.xy + Temporal_b4_o160__vecVehCollB.xy;
	r2.xy = r1.xy + -(r2.xy);
	r0.w = asint(dot(r2.xy, r2.xy));
	r2.xy = r2.xy + float2(0.00000999999975, 0.00000999999975);
	r1.w = -(asfloat(r0.w)) + Temporal_b4_o192__vecVehCollR.y;
	r1.w = saturate(r1.w * Temporal_b4_o192__vecVehCollR.z);
	r2.z = -(asfloat(r0.z)) + Temporal_b4_o192__vecVehCollR.w;
	r2.z = r1.w * r2.z + asfloat(r0.z);
	r1.w = r1.w * Temporal_b4_o192__vecVehCollR.x;
	r2.w = Temporal_b4_o192__vecVehCollR.x * 0.5;
	r2.w = r2.w * r2.w;
	r0.w = (asfloat(r0.w) < r2.w) ? -1 : 0;
	r2.w = Temporal_b4_o192__vecVehCollR.w + -0.25;
	r3.z = (r0.w != 0) ? r2.w : r2.z;
	r0.w = asint(dot(r2.xy, r2.xy));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r2.xy = asfloat(r0.ww) * r2.xy;
	r2.xy = r1.ww * r2.xy;
	r3.xy = r2.xy * i.color1.zz + r1.xy;
	r1.z = asfloat(r0.z);
	o.texcoord2.xyz = asfloat(r0.xyz);
	r0.xyz = asint((Temporal_b7_o0_bVehCollEnabled != 0) ? r3.xyz : r1.xyz);
	r1 = asfloat(r0.y) * Temporal_b0_o128_gWorldViewProj[1];
	r1 = asfloat(r0.x) * Temporal_b0_o128_gWorldViewProj[0] + r1;
	r1 = asfloat(r0.z) * Temporal_b0_o128_gWorldViewProj[2] + r1;
	r0.xy = asint(asfloat(r0.xy) + -(Temporal_b4_o96_vecCameraPos.xy));
	r0.x = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.x = asint(saturate(asfloat(r0.x) * Temporal_b4_o208_fadeAlphaDistUmTimer.y + Temporal_b4_o208_fadeAlphaDistUmTimer.x));
	o.texcoord.w = asfloat(r0.x) * Temporal_b4_o64_plantColor.w;
	o.sv_position = r1 + Temporal_b0_o128_gWorldViewProj[3];
	o.texcoord.xyz = Temporal_b4_o64_plantColor.xyz;
	o.texcoord1.xyz = Temporal_b4_o272__fakedGrassNormal.xyz;
	o.texcoord1.w = i.texcoord.x;
	o.texcoord2.w = i.texcoord.y;
	o.texcoord3.xyz = Temporal_b4_o80_groundColor.xyz;
	o.texcoord3.w = i.color1.x;

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
