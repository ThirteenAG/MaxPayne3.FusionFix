cbuffer rage_bonemtx : register(b1)
{
	row_major float3x4 gBoneMtx[40] : packoffset(c0);
};

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

cbuffer CachePedParam : register(b4)
{
	float ArmourStrength : packoffset(c0);
	float bumpiness : packoffset(c0.y);
	float displacementScale : packoffset(c0.z);
	float specularFactor : packoffset(c0.w);
	float3 specMapIntMask : packoffset(c1);
	float4 specMapExpMask : packoffset(c2);
	float4 matMaterialColorScale : packoffset(c3);
	float orderNumber : packoffset(c4);
	float furNumLayers : packoffset(c4.y);
	float furLayerStep : packoffset(c4.z);
	float4 furGlobalParams : packoffset(c5);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 color : COLOR;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord3 : TEXCOORD3;
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
	row_major float3x4 Temporal_b1_o0_gBoneMtx[40] : packoffset(c1);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c121);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c125);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c129);
	float4 Temporal_b5_o0_globalScalars : packoffset(c133);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c134);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c135);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c136);
	float4 Temporal_b5_o64_globalFogParams : packoffset(c137);
	float4 Temporal_b5_o80_globalFogColor : packoffset(c138);
	float4 Temporal_b5_o96_globalFogOffsetN : packoffset(c139);
	float4 Temporal_b5_o112_globalFogColorN : packoffset(c140);
	float4 Temporal_b5_o128_globalScreenSize : packoffset(c141);
	float4 Temporal_b5_o144_globalDayNightEffects : packoffset(c142);
	float4 Temporal_b5_o160_ColorCorrectTopAndPedReflectScale : packoffset(c143);
	float4 Temporal_b5_o176_ColorCorrectBottomOffset : packoffset(c144);
	float4 Temporal_b5_o192_ColorShift : packoffset(c145);
	float4 Temporal_b5_o208_deSatContrastGamma : packoffset(c146);
	float4 Temporal_b5_o224_deSatContrastGammaIFX : packoffset(c147);
	float4 Temporal_b5_o240_colorize : packoffset(c148);
	float4 Temporal_b5_o256_globalUmScalars : packoffset(c149);
	float4 Temporal_b5_o272_gToneMapScalers : packoffset(c150);
	float4 Temporal_b5_o288_gAmbientOcclusionEffect : packoffset(c151);
	float Temporal_b4_o0_ArmourStrength : packoffset(c152);
	float Temporal_b4_o4_bumpiness : packoffset(c153);
	float Temporal_b4_o8_displacementScale : packoffset(c154);
	float Temporal_b4_o12_specularFactor : packoffset(c155);
	float3 Temporal_b4_o16_specMapIntMask : packoffset(c156);
	float4 Temporal_b4_o32_specMapExpMask : packoffset(c157);
	float4 Temporal_b4_o48_matMaterialColorScale : packoffset(c158);
	float Temporal_b4_o64_orderNumber : packoffset(c159);
	float Temporal_b4_o68_furNumLayers : packoffset(c160);
	float Temporal_b4_o72_furLayerStep : packoffset(c161);
	float4 Temporal_b4_o80_furGlobalParams : packoffset(c162);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float4 r5;
	float3 r6;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * gBoneMtx[r0.y / 3][1];
	r1 = gBoneMtx[r0.x / 3][1] * i.blendweight.x + r1;
	r1 = gBoneMtx[r0.z / 3][1] * i.blendweight.z + r1;
	r1 = gBoneMtx[r0.w / 3][1] * i.blendweight.w + r1;
	r2.x = dot(r1.xyz, i.normal.xyz);
	r2.xyz = r2.xxx * gWorld[1].xyz;
	r3 = i.blendweight.y * gBoneMtx[r0.y / 3][0];
	r3 = gBoneMtx[r0.x / 3][0] * i.blendweight.x + r3;
	r3 = gBoneMtx[r0.z / 3][0] * i.blendweight.z + r3;
	r3 = gBoneMtx[r0.w / 3][0] * i.blendweight.w + r3;
	r2.w = dot(r3.xyz, i.normal.xyz);
	r2.xyz = r2.www * gWorld[0].xyz + r2.xyz;
	r4 = i.blendweight.y * gBoneMtx[r0.y / 3][2];
	r4 = gBoneMtx[r0.x / 3][2] * i.blendweight.x + r4;
	r4 = gBoneMtx[r0.z / 3][2] * i.blendweight.z + r4;
	r0 = asint(gBoneMtx[r0.w / 3][2] * i.blendweight.w + r4);
	r2.w = dot(asfloat(r0.xyz), i.normal.xyz);
	r2.xyz = r2.www * gWorld[2].xyz + r2.xyz;
	r4.xyz = r2.xyz * furGlobalParams.zzz;
	r5.xyz = i.position.xyz;
	r5.w = 1;
	r6.x = dot(r3, r5);
	r2.w = dot(r3.xyz, i.tangent.xyz);
	r6.y = dot(r1, r5);
	r1.x = dot(r1.xyz, i.tangent.xyz);
	r1.xyz = r1.xxx * gWorld[1].xyz;
	r1.xyz = r2.www * gWorld[0].xyz + r1.xyz;
	r6.z = dot(asfloat(r0), r5);
	r0.x = asint(dot(asfloat(r0.xyz), i.tangent.xyz));
	r0.xyz = asint(asfloat(r0.xxx) * gWorld[2].xyz + r1.xyz);
	r1.xyz = r4.xyz * furGlobalParams.xxx + r6.xyz;
	r3.xyz = r6.yyy * gWorld[1].xyz;
	r3.xyz = r6.xxx * gWorld[0].xyz + r3.xyz;
	r3.xyz = r6.zzz * gWorld[2].xyz + r3.xyz;
	o.texcoord7 = r3.xyz + gWorld[3].xyz;
	r3 = r1.y * gWorldViewProj[1];
	r3 = r1.x * gWorldViewProj[0] + r3;
	r1 = r1.z * gWorldViewProj[2] + r3;
	r1 = r1 + gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord = i.texcoord.xy;
	o.texcoord3.x = furGlobalParams.y;
	o.texcoord3.y = 0;
	o.texcoord1.xyz = r2.xyz;
	r0.w = asint(i.color.x * globalScalars.z + -1);
	r0.w = asint(gAmbientOcclusionEffect.y * asfloat(r0.w) + 1);
	r1.x = 1 / gAmbientOcclusionEffect.y;
	r0.w = asint(asfloat(r0.w) * r1.x);
	o.texcoord2.x = min(asfloat(r0.w), 1);
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	o.texcoord4 = asfloat(r0.xyz);
	r1.xyz = r2.yzx * asfloat(r0.zxy);
	r0.xyz = asint(asfloat(r0.yzx) * r2.zxy + -(r1.xyz));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
	o.texcoord5.w = i.tangent.w;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float4 r5;
	float3 r6;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][1];
	r1 = Temporal_b1_o0_gBoneMtx[r0.x / 3][1] * i.blendweight.x + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.z / 3][1] * i.blendweight.z + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.w / 3][1] * i.blendweight.w + r1;
	r2.x = dot(r1.xyz, i.normal.xyz);
	r2.xyz = r2.xxx * Temporal_b0_o0_gWorld[1].xyz;
	r3 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][0];
	r3 = Temporal_b1_o0_gBoneMtx[r0.x / 3][0] * i.blendweight.x + r3;
	r3 = Temporal_b1_o0_gBoneMtx[r0.z / 3][0] * i.blendweight.z + r3;
	r3 = Temporal_b1_o0_gBoneMtx[r0.w / 3][0] * i.blendweight.w + r3;
	r2.w = dot(r3.xyz, i.normal.xyz);
	r2.xyz = r2.www * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r4 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][2];
	r4 = Temporal_b1_o0_gBoneMtx[r0.x / 3][2] * i.blendweight.x + r4;
	r4 = Temporal_b1_o0_gBoneMtx[r0.z / 3][2] * i.blendweight.z + r4;
	r0 = asint(Temporal_b1_o0_gBoneMtx[r0.w / 3][2] * i.blendweight.w + r4);
	r2.w = dot(asfloat(r0.xyz), i.normal.xyz);
	r2.xyz = r2.www * Temporal_b0_o0_gWorld[2].xyz + r2.xyz;
	r4.xyz = r2.xyz * Temporal_b4_o80_furGlobalParams.zzz;
	r5.xyz = i.position.xyz;
	r5.w = 1;
	r6.x = dot(r3, r5);
	r2.w = dot(r3.xyz, i.tangent.xyz);
	r6.y = dot(r1, r5);
	r1.x = dot(r1.xyz, i.tangent.xyz);
	r1.xyz = r1.xxx * Temporal_b0_o0_gWorld[1].xyz;
	r1.xyz = r2.www * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	r6.z = dot(asfloat(r0), r5);
	r0.x = asint(dot(asfloat(r0.xyz), i.tangent.xyz));
	r0.xyz = asint(asfloat(r0.xxx) * Temporal_b0_o0_gWorld[2].xyz + r1.xyz);
	r1.xyz = r4.xyz * Temporal_b4_o80_furGlobalParams.xxx + r6.xyz;
	r3.xyz = r6.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r3.xyz = r6.xxx * Temporal_b0_o0_gWorld[0].xyz + r3.xyz;
	r3.xyz = r6.zzz * Temporal_b0_o0_gWorld[2].xyz + r3.xyz;
	o.texcoord7 = r3.xyz + Temporal_b0_o0_gWorld[3].xyz;
	r3 = r1.y * Temporal_b0_o128_gWorldViewProj[1];
	r3 = r1.x * Temporal_b0_o128_gWorldViewProj[0] + r3;
	r1 = r1.z * Temporal_b0_o128_gWorldViewProj[2] + r3;
	r1 = r1 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord = i.texcoord.xy;
	o.texcoord3.x = Temporal_b4_o80_furGlobalParams.y;
	o.texcoord3.y = 0;
	o.texcoord1.xyz = r2.xyz;
	r0.w = asint(i.color.x * Temporal_b5_o0_globalScalars.z + -1);
	r0.w = asint(Temporal_b5_o288_gAmbientOcclusionEffect.y * asfloat(r0.w) + 1);
	r1.x = 1 / Temporal_b5_o288_gAmbientOcclusionEffect.y;
	r0.w = asint(asfloat(r0.w) * r1.x);
	o.texcoord2.x = min(asfloat(r0.w), 1);
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	o.texcoord4 = asfloat(r0.xyz);
	r1.xyz = r2.yzx * asfloat(r0.zxy);
	r0.xyz = asint(asfloat(r0.yzx) * r2.zxy + -(r1.xyz));
	o.texcoord5.xyz = asfloat(r0.xyz) * i.tangent.www;
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
