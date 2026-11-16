cbuffer rage_bonemtx : register(b1)
{
	row_major float3x4 gBoneMtx[40] : packoffset(c0);
};

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
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float4 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 color : COLOR;
	float4 color1 : COLOR1;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
	float3 temporalPrevious : TEXCOORD15;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float3x4 Temporal_b1_o0_gBoneMtx[40] : packoffset(c1);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c121);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c125);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c129);
	row_major float4x4 Temporal_b0_o192_gViewInverse : packoffset(c133);
	float4 Temporal_b5_o0_globalScalars : packoffset(c137);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c138);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c139);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c140);
	float4 Temporal_b5_o64_globalFogParams : packoffset(c141);
	float4 Temporal_b5_o80_globalFogColor : packoffset(c142);
	float4 Temporal_b5_o96_globalFogOffsetN : packoffset(c143);
	float4 Temporal_b5_o112_globalFogColorN : packoffset(c144);
	float4 Temporal_b5_o128_globalScreenSize : packoffset(c145);
	float4 Temporal_b5_o144_globalDayNightEffects : packoffset(c146);
	float4 Temporal_b5_o160_ColorCorrectTopAndPedReflectScale : packoffset(c147);
	float4 Temporal_b5_o176_ColorCorrectBottomOffset : packoffset(c148);
	float4 Temporal_b5_o192_ColorShift : packoffset(c149);
	float4 Temporal_b5_o208_deSatContrastGamma : packoffset(c150);
	float4 Temporal_b5_o224_deSatContrastGammaIFX : packoffset(c151);
	float4 Temporal_b5_o240_colorize : packoffset(c152);
	float4 Temporal_b5_o256_globalUmScalars : packoffset(c153);
	float4 Temporal_b5_o272_gToneMapScalers : packoffset(c154);
	float4 Temporal_b5_o288_gAmbientOcclusionEffect : packoffset(c155);
	float4 Temporal_b4_o0_gWindParams : packoffset(c156);
	float4 Temporal_b4_o16_AirResist : packoffset(c157);
	float Temporal_b4_o32_WindStr : packoffset(c158);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	int4 r4;
	float4 r5;
	float3 r6;
	r0.x = globalScalars3.z + 0.00000999999975;
	r0.y = globalScalars4.z + 0.00000999999975;
	r0.z = 0.00000999999975;
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r0.x = dot(r0.xyz, i.normal.xyz);
	r0.x = max(r0.x, 0.25);
	r0.x = min(r0.x, 1);
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * gBoneMtx[r1.y / 3][1];
	r2 = gBoneMtx[r1.x / 3][1] * i.blendweight.x + r2;
	r2 = gBoneMtx[r1.z / 3][1] * i.blendweight.z + r2;
	r2 = gBoneMtx[r1.w / 3][1] * i.blendweight.w + r2;
	r0.y = dot(r2.xyz, i.normal.xyz);
	r0.yzw = r0.yyy * gWorld[1].xyz;
	r3 = i.blendweight.y * gBoneMtx[r1.y / 3][0];
	r3 = gBoneMtx[r1.x / 3][0] * i.blendweight.x + r3;
	r3 = gBoneMtx[r1.z / 3][0] * i.blendweight.z + r3;
	r3 = gBoneMtx[r1.w / 3][0] * i.blendweight.w + r3;
	r4.x = asint(dot(r3.xyz, i.normal.xyz));
	r0.yzw = asfloat(r4.xxx) * gWorld[0].xyz + r0.yzw;
	r4 = asint(i.blendweight.y * gBoneMtx[r1.y / 3][2]);
	r4 = asint(gBoneMtx[r1.x / 3][2] * i.blendweight.x + asfloat(r4));
	r4 = asint(gBoneMtx[r1.z / 3][2] * i.blendweight.z + asfloat(r4));
	r1 = asint(gBoneMtx[r1.w / 3][2] * i.blendweight.w + asfloat(r4));
	r4.x = asint(dot(asfloat(r1.xyz), i.normal.xyz));
	r0.yzw = asfloat(r4.xxx) * gWorld[2].xyz + r0.yzw;
	r4.x = asint(saturate(dot(AirResist.xyz, r0.yzw)));
	r4.x = asint(-(asfloat(r4.x)) + 1);
	r4.x = asint(-(asfloat(r4.x)) * AirResist.w + 1);
	r4.y = (0.800000012 < asfloat(r4.x)) ? -1 : 0;
	r4.x = (r4.y != 0) ? 1065353216 : r4.x;
	r4.yz = asint(AirResist.ww * float2(4, 1.5) + float2(1, 1));
	r5.xyz = asfloat(r4.yyy) * i.color1.xxz;
	r5.xyz = -(r5.xyz) * i.normal.xyz;
	r4.xyw = asint(asfloat(r4.xxx) * r5.xyz);
	r4.xyw = asint(r0.xxx * asfloat(r4.xyw));
	r5.xyz = i.position.xyz;
	r5.w = 1;
	r6.x = dot(r3, r5);
	r0.x = dot(r3.xyz, i.tangent.xyz);
	r6.z = dot(asfloat(r1), r5);
	r1.x = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r6.y = dot(r2, r5);
	r1.y = asint(dot(r2.xyz, i.tangent.xyz));
	r1.yzw = asint(asfloat(r1.yyy) * gWorld[1].xyz);
	r1.yzw = asint(r0.xxx * gWorld[0].xyz + asfloat(r1.yzw));
	r1.xyz = asint(asfloat(r1.xxx) * gWorld[2].xyz + asfloat(r1.yzw));
	r2.xyz = r6.xxz * float3(6, 10, 10);
	r0.x = r2.z + r2.y;
	r1.w = asint(globalScalars3.y * asfloat(r4.z) + r2.x);
	r2.x = asfloat(r4.z) * globalScalars3.y;
	r1.w = asint(sin(asfloat(r1.w)));
	r0.x = r6.y * 10 + r0.x;
	r0.x = r2.x * gWindParams.z + r0.x;
	r0.x = sin(r0.x);
	r2.y = saturate(WindStr);
	r1.w = asint(abs(asfloat(r1.w)) * r2.y);
	r0.x = abs(r0.x) * asfloat(r1.w);
	r1.w = asint(r6.y * 4);
	r1.w = asint(r2.x * gWindParams.w + asfloat(r1.w));
	r1.w = asint(sin(asfloat(r1.w)));
	r0.x = r0.x * abs(asfloat(r1.w));
	r2.xyz = asfloat(r4.xyw) * r0.xxx + r6.xyz;
	r3.xyz = r6.yyy * gWorld[1].xyz;
	r3.xyz = r6.xxx * gWorld[0].xyz + r3.xyz;
	r3.xyz = r6.zzz * gWorld[2].xyz + r3.xyz;
	r3.xyz = r3.xyz + gWorld[3].xyz;
	r4 = asint(r2.y * gWorldViewProj[1]);
	r4 = asint(r2.x * gWorldViewProj[0] + asfloat(r4));
	r2 = r2.z * gWorldViewProj[2] + asfloat(r4);
	r2 = r2 + gWorldViewProj[3];
	o.sv_position = r2;
	o.texcoord1.w = r2.w;
	o.texcoord = i.texcoord;
	o.texcoord1.xyz = r0.yzw;
	r0.x = i.color.x * globalScalars.z + -1;
	r0.x = gAmbientOcclusionEffect.y * r0.x + 1;
	r1.w = asint(1 / gAmbientOcclusionEffect.y);
	r0.x = r0.x * asfloat(r1.w);
	o.texcoord2.x = min(r0.x, 1);
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	r2.xyz = -(r3.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r3.xyz;
	o.texcoord3 = r2.xyz;
	o.texcoord4 = asfloat(r1.xyz);
	r3.xyz = r0.zwy * asfloat(r1.zxy);
	r3.xyz = asfloat(r1.yzx) * r0.wyz + -(r3.xyz);
	o.texcoord6.z = dot(r0.yzw, r2.xyz);
	o.texcoord6.x = dot(asfloat(r1.xyz), r2.xyz);
	r0.xyz = r3.xyz * i.tangent.www;
	o.texcoord5.xyz = r0.xyz;
	o.texcoord6.y = dot(r0.xyz, r2.xyz);
	o.texcoord5.w = i.tangent.w;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	int4 r4;
	float4 r5;
	float3 r6;
	r0.x = Temporal_b5_o32_globalScalars3.z + 0.00000999999975;
	r0.y = Temporal_b5_o48_globalScalars4.z + 0.00000999999975;
	r0.z = 0.00000999999975;
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r0.x = dot(r0.xyz, i.normal.xyz);
	r0.x = max(r0.x, 0.25);
	r0.x = min(r0.x, 1);
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][1];
	r2 = Temporal_b1_o0_gBoneMtx[r1.x / 3][1] * i.blendweight.x + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.z / 3][1] * i.blendweight.z + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.w / 3][1] * i.blendweight.w + r2;
	r0.y = dot(r2.xyz, i.normal.xyz);
	r0.yzw = r0.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r3 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][0];
	r3 = Temporal_b1_o0_gBoneMtx[r1.x / 3][0] * i.blendweight.x + r3;
	r3 = Temporal_b1_o0_gBoneMtx[r1.z / 3][0] * i.blendweight.z + r3;
	r3 = Temporal_b1_o0_gBoneMtx[r1.w / 3][0] * i.blendweight.w + r3;
	r4.x = asint(dot(r3.xyz, i.normal.xyz));
	r0.yzw = asfloat(r4.xxx) * Temporal_b0_o0_gWorld[0].xyz + r0.yzw;
	r4 = asint(i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][2]);
	r4 = asint(Temporal_b1_o0_gBoneMtx[r1.x / 3][2] * i.blendweight.x + asfloat(r4));
	r4 = asint(Temporal_b1_o0_gBoneMtx[r1.z / 3][2] * i.blendweight.z + asfloat(r4));
	r1 = asint(Temporal_b1_o0_gBoneMtx[r1.w / 3][2] * i.blendweight.w + asfloat(r4));
	r4.x = asint(dot(asfloat(r1.xyz), i.normal.xyz));
	r0.yzw = asfloat(r4.xxx) * Temporal_b0_o0_gWorld[2].xyz + r0.yzw;
	r4.x = asint(saturate(dot(Temporal_b4_o16_AirResist.xyz, r0.yzw)));
	r4.x = asint(-(asfloat(r4.x)) + 1);
	r4.x = asint(-(asfloat(r4.x)) * Temporal_b4_o16_AirResist.w + 1);
	r4.y = (0.800000012 < asfloat(r4.x)) ? -1 : 0;
	r4.x = (r4.y != 0) ? 1065353216 : r4.x;
	r4.yz = asint(Temporal_b4_o16_AirResist.ww * float2(4, 1.5) + float2(1, 1));
	r5.xyz = asfloat(r4.yyy) * i.color1.xxz;
	r5.xyz = -(r5.xyz) * i.normal.xyz;
	r4.xyw = asint(asfloat(r4.xxx) * r5.xyz);
	r4.xyw = asint(r0.xxx * asfloat(r4.xyw));
	r5.xyz = i.position.xyz;
	r5.w = 1;
	r6.x = dot(r3, r5);
	r0.x = dot(r3.xyz, i.tangent.xyz);
	r6.z = dot(asfloat(r1), r5);
	r1.x = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r6.y = dot(r2, r5);
	r1.y = asint(dot(r2.xyz, i.tangent.xyz));
	r1.yzw = asint(asfloat(r1.yyy) * Temporal_b0_o0_gWorld[1].xyz);
	r1.yzw = asint(r0.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r1.yzw));
	r1.xyz = asint(asfloat(r1.xxx) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r1.yzw));
	r2.xyz = r6.xxz * float3(6, 10, 10);
	r0.x = r2.z + r2.y;
	r1.w = asint(Temporal_b5_o32_globalScalars3.y * asfloat(r4.z) + r2.x);
	r2.x = asfloat(r4.z) * Temporal_b5_o32_globalScalars3.y;
	r1.w = asint(sin(asfloat(r1.w)));
	r0.x = r6.y * 10 + r0.x;
	r0.x = r2.x * Temporal_b4_o0_gWindParams.z + r0.x;
	r0.x = sin(r0.x);
	r2.y = saturate(Temporal_b4_o32_WindStr);
	r1.w = asint(abs(asfloat(r1.w)) * r2.y);
	r0.x = abs(r0.x) * asfloat(r1.w);
	r1.w = asint(r6.y * 4);
	r1.w = asint(r2.x * Temporal_b4_o0_gWindParams.w + asfloat(r1.w));
	r1.w = asint(sin(asfloat(r1.w)));
	r0.x = r0.x * abs(asfloat(r1.w));
	r2.xyz = asfloat(r4.xyw) * r0.xxx + r6.xyz;
	r3.xyz = r6.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r3.xyz = r6.xxx * Temporal_b0_o0_gWorld[0].xyz + r3.xyz;
	r3.xyz = r6.zzz * Temporal_b0_o0_gWorld[2].xyz + r3.xyz;
	r3.xyz = r3.xyz + Temporal_b0_o0_gWorld[3].xyz;
	r4 = asint(r2.y * Temporal_b0_o128_gWorldViewProj[1]);
	r4 = asint(r2.x * Temporal_b0_o128_gWorldViewProj[0] + asfloat(r4));
	r2 = r2.z * Temporal_b0_o128_gWorldViewProj[2] + asfloat(r4);
	r2 = r2 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r2;
	o.texcoord1.w = r2.w;
	o.texcoord = i.texcoord;
	o.texcoord1.xyz = r0.yzw;
	r0.x = i.color.x * Temporal_b5_o0_globalScalars.z + -1;
	r0.x = Temporal_b5_o288_gAmbientOcclusionEffect.y * r0.x + 1;
	r1.w = asint(1 / Temporal_b5_o288_gAmbientOcclusionEffect.y);
	r0.x = r0.x * asfloat(r1.w);
	o.texcoord2.x = min(r0.x, 1);
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	r2.xyz = -(r3.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = r3.xyz;
	o.texcoord3 = r2.xyz;
	o.texcoord4 = asfloat(r1.xyz);
	r3.xyz = r0.zwy * asfloat(r1.zxy);
	r3.xyz = asfloat(r1.yzx) * r0.wyz + -(r3.xyz);
	o.texcoord6.z = dot(r0.yzw, r2.xyz);
	o.texcoord6.x = dot(asfloat(r1.xyz), r2.xyz);
	r0.xyz = r3.xyz * i.tangent.www;
	o.texcoord5.xyz = r0.xyz;
	o.texcoord6.y = dot(r0.xyz, r2.xyz);
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
