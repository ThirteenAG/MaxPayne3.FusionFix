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

cbuffer CachePedParam : register(b4)
{
	float ArmourStrength : packoffset(c0);
	float bumpiness : packoffset(c0.y);
	float displacementScale : packoffset(c0.z);
	float specularFactor : packoffset(c0.w);
	float3 specMapIntMask : packoffset(c1);
	float4 specMapExpMask : packoffset(c2);
	float4 matMaterialColorScale : packoffset(c3);
	float4 gBloodData : packoffset(c4);
};

cbuffer BloodHitData : register(b7)
{
	float4 gBloodHeadHits[4] : packoffset(c0);
	float4 gBloodHeadCentreMass : packoffset(c4);
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
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
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
	float Temporal_b4_o0_ArmourStrength : packoffset(c156);
	float Temporal_b4_o4_bumpiness : packoffset(c157);
	float Temporal_b4_o8_displacementScale : packoffset(c158);
	float Temporal_b4_o12_specularFactor : packoffset(c159);
	float3 Temporal_b4_o16_specMapIntMask : packoffset(c160);
	float4 Temporal_b4_o32_specMapExpMask : packoffset(c161);
	float4 Temporal_b4_o48_matMaterialColorScale : packoffset(c162);
	float4 Temporal_b4_o64_gBloodData : packoffset(c163);
	float4 Temporal_b7_o0_gBloodHeadHits[4] : packoffset(c164);
	float4 Temporal_b7_o64_gBloodHeadCentreMass : packoffset(c168);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	float4 r6;
	r0.xyz = -(i.position.xyz) + gBloodHeadHits[0].xyz;
	r0.x = dot(r0.xyz, r0.xyz);
	r0.x = sqrt(r0.x);
	r0.x = -(r0.x) + 0.0500000007;
	r0.x = r0.x * 0.239999995;
	r0.x = max(r0.x, 0);
	r0.yzw = -(i.position.xyz) + gBloodHeadHits[1].xyz;
	r0.y = dot(r0.yzw, r0.yzw);
	r0.y = sqrt(r0.y);
	r0.y = -(r0.y) + 0.0500000007;
	r0.y = r0.y * 0.239999995;
	r0.x = max(r0.y, r0.x);
	r0.yzw = -(i.position.xyz) + gBloodHeadHits[2].xyz;
	r0.y = dot(r0.yzw, r0.yzw);
	r0.y = sqrt(r0.y);
	r0.y = -(r0.y) + 0.0500000007;
	r0.y = r0.y * 0.239999995;
	r0.x = max(r0.y, r0.x);
	r0.yzw = -(i.position.xyz) + gBloodHeadHits[3].xyz;
	r0.y = dot(r0.yzw, r0.yzw);
	r0.y = sqrt(r0.y);
	r0.y = -(r0.y) + 0.0500000007;
	r0.y = r0.y * 0.239999995;
	r0.x = max(r0.y, r0.x);
	r0.yzw = -(i.position.xyz) + gBloodHeadCentreMass.xyz;
	r0.yzw = r0.yzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = asint(dot(r0.yzw, r0.yzw));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.yzw = r0.yzw * asfloat(r1.xxx);
	r0.xyz = r0.xxx * r0.yzw;
	r0.xyz = r0.xyz * gBloodData.xxx + i.position.xyz;
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * gBoneMtx[r1.y / 3][1];
	r2 = gBoneMtx[r1.x / 3][1] * i.blendweight.x + r2;
	r2 = gBoneMtx[r1.z / 3][1] * i.blendweight.z + r2;
	r2 = gBoneMtx[r1.w / 3][1] * i.blendweight.w + r2;
	r0.w = 1;
	r2.w = dot(r2, r0);
	r3 = r2.w * gWorldViewProj[1];
	r4 = r2.www * gWorld[1].xyz;
	r5 = i.blendweight.y * gBoneMtx[r1.y / 3][0];
	r5 = gBoneMtx[r1.x / 3][0] * i.blendweight.x + r5;
	r5 = gBoneMtx[r1.z / 3][0] * i.blendweight.z + r5;
	r5 = gBoneMtx[r1.w / 3][0] * i.blendweight.w + r5;
	r2.w = dot(r5, r0);
	r3 = r2.w * gWorldViewProj[0] + r3;
	r4 = r2.www * gWorld[0].xyz + r4.xyz;
	r6 = i.blendweight.y * gBoneMtx[r1.y / 3][2];
	r6 = gBoneMtx[r1.x / 3][2] * i.blendweight.x + r6;
	r6 = gBoneMtx[r1.z / 3][2] * i.blendweight.z + r6;
	r1 = asint(gBoneMtx[r1.w / 3][2] * i.blendweight.w + r6);
	r0.x = dot(asfloat(r1), r0);
	r3 = r0.x * gWorldViewProj[2] + r3;
	r0.xyz = r0.xxx * gWorld[2].xyz + r4.xyz;
	r0.xyz = r0.xyz + gWorld[3].xyz;
	r3 = r3 + gWorldViewProj[3];
	o.sv_position = r3;
	o.texcoord1.w = r3.w;
	o.texcoord = i.texcoord;
	r0.w = dot(r2.xyz, i.normal.xyz);
	r1.w = asint(dot(r2.xyz, i.tangent.xyz));
	r2.xyz = asfloat(r1.www) * gWorld[1].xyz;
	r3.xyz = r0.www * gWorld[1].xyz;
	r0.w = dot(r5.xyz, i.normal.xyz);
	r1.w = asint(dot(r5.xyz, i.tangent.xyz));
	r2.xyz = asfloat(r1.www) * gWorld[0].xyz + r2.xyz;
	r3.xyz = r0.www * gWorld[0].xyz + r3.xyz;
	r0.w = dot(asfloat(r1.xyz), i.normal.xyz);
	r1.x = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r1.xyz = asint(asfloat(r1.xxx) * gWorld[2].xyz + r2.xyz);
	r2.xyz = r0.www * gWorld[2].xyz + r3.xyz;
	o.texcoord1.xyz = r2.xyz;
	r0.w = i.color.x * globalScalars.z + -1;
	r0.w = gAmbientOcclusionEffect.y * r0.w + 1;
	r1.w = asint(1 / gAmbientOcclusionEffect.y);
	r0.w = r0.w * asfloat(r1.w);
	o.texcoord2.x = min(r0.w, 1);
	o.texcoord2.z = -(i.color.y) * i.color.x + 1;
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.w = i.color.w;
	o.texcoord4 = asfloat(r1.xyz);
	r3.xyz = asfloat(r1.zxy) * r2.yzx;
	r3.xyz = asfloat(r1.yzx) * r2.zxy + -(r3.xyz);
	r3.xyz = r3.xyz * i.tangent.www;
	o.texcoord5.xyz = r3.xyz;
	o.texcoord5.w = i.tangent.w;
	r4 = -(r0.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r0.xyz;
	o.texcoord6.x = dot(asfloat(r1.xyz), r4.xyz);
	o.texcoord6.z = dot(r2.xyz, r4.xyz);
	o.texcoord6.y = dot(r3.xyz, r4.xyz);

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	float4 r6;
	r0.xyz = -(i.position.xyz) + Temporal_b7_o0_gBloodHeadHits[0].xyz;
	r0.x = dot(r0.xyz, r0.xyz);
	r0.x = sqrt(r0.x);
	r0.x = -(r0.x) + 0.0500000007;
	r0.x = r0.x * 0.239999995;
	r0.x = max(r0.x, 0);
	r0.yzw = -(i.position.xyz) + Temporal_b7_o0_gBloodHeadHits[1].xyz;
	r0.y = dot(r0.yzw, r0.yzw);
	r0.y = sqrt(r0.y);
	r0.y = -(r0.y) + 0.0500000007;
	r0.y = r0.y * 0.239999995;
	r0.x = max(r0.y, r0.x);
	r0.yzw = -(i.position.xyz) + Temporal_b7_o0_gBloodHeadHits[2].xyz;
	r0.y = dot(r0.yzw, r0.yzw);
	r0.y = sqrt(r0.y);
	r0.y = -(r0.y) + 0.0500000007;
	r0.y = r0.y * 0.239999995;
	r0.x = max(r0.y, r0.x);
	r0.yzw = -(i.position.xyz) + Temporal_b7_o0_gBloodHeadHits[3].xyz;
	r0.y = dot(r0.yzw, r0.yzw);
	r0.y = sqrt(r0.y);
	r0.y = -(r0.y) + 0.0500000007;
	r0.y = r0.y * 0.239999995;
	r0.x = max(r0.y, r0.x);
	r0.yzw = -(i.position.xyz) + Temporal_b7_o64_gBloodHeadCentreMass.xyz;
	r0.yzw = r0.yzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = asint(dot(r0.yzw, r0.yzw));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.yzw = r0.yzw * asfloat(r1.xxx);
	r0.xyz = r0.xxx * r0.yzw;
	r0.xyz = r0.xyz * Temporal_b4_o64_gBloodData.xxx + i.position.xyz;
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][1];
	r2 = Temporal_b1_o0_gBoneMtx[r1.x / 3][1] * i.blendweight.x + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.z / 3][1] * i.blendweight.z + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.w / 3][1] * i.blendweight.w + r2;
	r0.w = 1;
	r2.w = dot(r2, r0);
	r3 = r2.w * Temporal_b0_o128_gWorldViewProj[1];
	r4 = r2.www * Temporal_b0_o0_gWorld[1].xyz;
	r5 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][0];
	r5 = Temporal_b1_o0_gBoneMtx[r1.x / 3][0] * i.blendweight.x + r5;
	r5 = Temporal_b1_o0_gBoneMtx[r1.z / 3][0] * i.blendweight.z + r5;
	r5 = Temporal_b1_o0_gBoneMtx[r1.w / 3][0] * i.blendweight.w + r5;
	r2.w = dot(r5, r0);
	r3 = r2.w * Temporal_b0_o128_gWorldViewProj[0] + r3;
	r4 = r2.www * Temporal_b0_o0_gWorld[0].xyz + r4.xyz;
	r6 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][2];
	r6 = Temporal_b1_o0_gBoneMtx[r1.x / 3][2] * i.blendweight.x + r6;
	r6 = Temporal_b1_o0_gBoneMtx[r1.z / 3][2] * i.blendweight.z + r6;
	r1 = asint(Temporal_b1_o0_gBoneMtx[r1.w / 3][2] * i.blendweight.w + r6);
	r0.x = dot(asfloat(r1), r0);
	r3 = r0.x * Temporal_b0_o128_gWorldViewProj[2] + r3;
	r0.xyz = r0.xxx * Temporal_b0_o0_gWorld[2].xyz + r4.xyz;
	r0.xyz = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;
	r3 = r3 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r3;
	o.texcoord1.w = r3.w;
	o.texcoord = i.texcoord;
	r0.w = dot(r2.xyz, i.normal.xyz);
	r1.w = asint(dot(r2.xyz, i.tangent.xyz));
	r2.xyz = asfloat(r1.www) * Temporal_b0_o0_gWorld[1].xyz;
	r3.xyz = r0.www * Temporal_b0_o0_gWorld[1].xyz;
	r0.w = dot(r5.xyz, i.normal.xyz);
	r1.w = asint(dot(r5.xyz, i.tangent.xyz));
	r2.xyz = asfloat(r1.www) * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r3.xyz = r0.www * Temporal_b0_o0_gWorld[0].xyz + r3.xyz;
	r0.w = dot(asfloat(r1.xyz), i.normal.xyz);
	r1.x = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r1.xyz = asint(asfloat(r1.xxx) * Temporal_b0_o0_gWorld[2].xyz + r2.xyz);
	r2.xyz = r0.www * Temporal_b0_o0_gWorld[2].xyz + r3.xyz;
	o.texcoord1.xyz = r2.xyz;
	r0.w = i.color.x * Temporal_b5_o0_globalScalars.z + -1;
	r0.w = Temporal_b5_o288_gAmbientOcclusionEffect.y * r0.w + 1;
	r1.w = asint(1 / Temporal_b5_o288_gAmbientOcclusionEffect.y);
	r0.w = r0.w * asfloat(r1.w);
	o.texcoord2.x = min(r0.w, 1);
	o.texcoord2.z = -(i.color.y) * i.color.x + 1;
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.w = i.color.w;
	o.texcoord4 = asfloat(r1.xyz);
	r3.xyz = asfloat(r1.zxy) * r2.yzx;
	r3.xyz = asfloat(r1.yzx) * r2.zxy + -(r3.xyz);
	r3.xyz = r3.xyz * i.tangent.www;
	o.texcoord5.xyz = r3.xyz;
	o.texcoord5.w = i.tangent.w;
	r4 = -(r0.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = r0.xyz;
	o.texcoord6.x = dot(asfloat(r1.xyz), r4.xyz);
	o.texcoord6.z = dot(r2.xyz, r4.xyz);
	o.texcoord6.y = dot(r3.xyz, r4.xyz);

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
