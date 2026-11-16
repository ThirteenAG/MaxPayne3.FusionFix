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

cbuffer PedWind : register(b9)
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

struct TemporalVertexResult
{
	float4 texcoord8 : TEXCOORD8;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
};
struct VS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_texcoord : TEMPORAL1;
	float4 temporalInput_texcoord1 : TEMPORAL2;
	float4 temporalInput_texcoord2 : TEMPORAL3;
	float3 temporalInput_texcoord4 : TEMPORAL4;
	float4 temporalInput_texcoord5 : TEMPORAL5;
	float3 temporalInput_texcoord6 : TEMPORAL6;
	float3 temporalInput_texcoord7 : TEMPORAL7;
	float3 temporalInput_texcoord9 : TEMPORAL8;
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
	float4 Temporal_b9_o0_gWindParams : packoffset(c169);
	float4 Temporal_b9_o16_AirResist : packoffset(c170);
	float Temporal_b9_o32_WindStr : packoffset(c171);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	int4 r1;
	float4 r2;
	float3 r3;
	float4 r4;
	float3 r5;
	float4 r6;
	float3 r7;
	r0.xyz = asint(-(i.position.xyz) + gBloodHeadHits[0].xyz);
	r0.x = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.x = asint(sqrt(asfloat(r0.x)));
	r0.x = asint(-(asfloat(r0.x)) + 0.0500000007);
	r0.x = asint(asfloat(r0.x) * 0.239999995);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.yzw = asint(-(i.position.xyz) + gBloodHeadHits[1].xyz);
	r0.y = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r0.y = asint(sqrt(asfloat(r0.y)));
	r0.y = asint(-(asfloat(r0.y)) + 0.0500000007);
	r0.y = asint(asfloat(r0.y) * 0.239999995);
	r0.x = asint(max(asfloat(r0.y), asfloat(r0.x)));
	r0.yzw = asint(-(i.position.xyz) + gBloodHeadHits[2].xyz);
	r0.y = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r0.y = asint(sqrt(asfloat(r0.y)));
	r0.y = asint(-(asfloat(r0.y)) + 0.0500000007);
	r0.y = asint(asfloat(r0.y) * 0.239999995);
	r0.x = asint(max(asfloat(r0.y), asfloat(r0.x)));
	r0.yzw = asint(-(i.position.xyz) + gBloodHeadHits[3].xyz);
	r0.y = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r0.y = asint(sqrt(asfloat(r0.y)));
	r0.y = asint(-(asfloat(r0.y)) + 0.0500000007);
	r0.y = asint(asfloat(r0.y) * 0.239999995);
	r0.x = asint(max(asfloat(r0.y), asfloat(r0.x)));
	r0.yzw = asint(-(i.position.xyz) + gBloodHeadCentreMass.xyz);
	r0.yzw = asint(asfloat(r0.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.x = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.yzw = asint(asfloat(r0.yzw) * asfloat(r1.xxx));
	r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
	r0.xyz = asint(asfloat(r0.xyz) * gBloodData.xxx + i.position.xyz);
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * gBoneMtx[r1.y / 3][0];
	r2 = gBoneMtx[r1.x / 3][0] * i.blendweight.x + r2;
	r2 = gBoneMtx[r1.z / 3][0] * i.blendweight.z + r2;
	r2 = gBoneMtx[r1.w / 3][0] * i.blendweight.w + r2;
	r0.w = 1065353216;
	r3.x = dot(r2, asfloat(r0));
	r4 = i.blendweight.y * gBoneMtx[r1.y / 3][2];
	r4 = gBoneMtx[r1.x / 3][2] * i.blendweight.x + r4;
	r4 = gBoneMtx[r1.z / 3][2] * i.blendweight.z + r4;
	r4 = gBoneMtx[r1.w / 3][2] * i.blendweight.w + r4;
	r3.z = dot(r4, asfloat(r0));
	r5 = r3.xxz * float3(6, 10, 10);
	r2.w = r5.z + r5.y;
	r6 = i.blendweight.y * gBoneMtx[r1.y / 3][1];
	r6 = gBoneMtx[r1.x / 3][1] * i.blendweight.x + r6;
	r6 = gBoneMtx[r1.z / 3][1] * i.blendweight.z + r6;
	r1 = asint(gBoneMtx[r1.w / 3][1] * i.blendweight.w + r6);
	r3.y = dot(asfloat(r1), asfloat(r0));
	r0.x = asint(r3.y * 10 + r2.w);
	r0.yz = asint(AirResist.ww * float2(4, 1.5) + float2(1, 1));
	r0.w = asint(asfloat(r0.z) * globalScalars3.y);
	r0.x = asint(asfloat(r0.w) * gWindParams.z + asfloat(r0.x));
	r0.z = asint(globalScalars3.y * asfloat(r0.z) + r5.x);
	r5 = asfloat(r0.yyy) * i.color1.xxz;
	r5 = -(r5.xyz) * i.normal.xyz;
	r0.xy = asint(sin(asfloat(r0.xz)));
	r0.z = asint(saturate(WindStr));
	r0.y = asint(abs(asfloat(r0.y)) * asfloat(r0.z));
	r0.x = asint(abs(asfloat(r0.x)) * asfloat(r0.y));
	r0.y = asint(r3.y * 4);
	r0.y = asint(asfloat(r0.w) * gWindParams.w + asfloat(r0.y));
	r0.y = asint(sin(asfloat(r0.y)));
	r0.x = asint(abs(asfloat(r0.y)) * asfloat(r0.x));
	r6.x = globalScalars3.z + 0.00000999999975;
	r6.y = globalScalars4.z + 0.00000999999975;
	r6.z = 0.00000999999975;
	r0.y = asint(dot(r6.xyz, r6.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r0.yzw = asint(asfloat(r0.yyy) * r6.xyz);
	r0.y = asint(dot(asfloat(r0.yzw), i.normal.xyz));
	r0.y = asint(max(asfloat(r0.y), 0.25));
	r0.y = asint(min(asfloat(r0.y), 1));
	r6.y = dot(asfloat(r1.xyz), i.normal.xyz);
	r0.z = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.zzz) * gWorld[1].xyz);
	r7 = r6.yyy * gWorld[1].xyz;
	r6.x = dot(r2.xyz, i.normal.xyz);
	r0.z = asint(dot(r2.xyz, i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.zzz) * gWorld[0].xyz + asfloat(r1.xyz));
	r2.xyz = r6.xxx * gWorld[0].xyz + r7.xyz;
	r6.z = dot(r4.xyz, i.normal.xyz);
	r0.z = asint(dot(r4.xyz, i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.zzz) * gWorld[2].xyz + asfloat(r1.xyz));
	r2.xyz = r6.zzz * gWorld[2].xyz + r2.xyz;
	o.texcoord9 = r6.xyz;
	r0.z = asint(saturate(dot(AirResist.xyz, r2.xyz)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(-(asfloat(r0.z)) * AirResist.w + 1);
	r0.w = (0.800000012 < asfloat(r0.z)) ? -1 : 0;
	r0.z = (r0.w != 0) ? 1065353216 : r0.z;
	r4.xyz = asfloat(r0.zzz) * r5.xyz;
	r0.yzw = asint(asfloat(r0.yyy) * r4.xyz);
	o.texcoord8.xyz = asfloat(r0.yzw) * asfloat(r0.xxx) + r3.xyz;
	r0.xyz = asint(r3.yyy * gWorld[1].xyz);
	r0.xyz = asint(r3.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(r3.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + gWorld[3].xyz);
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord;
	o.texcoord1.xyz = r2.xyz;
	o.texcoord1.w = 1;
	r0.w = asint(i.color.x * globalScalars.z + -1);
	r0.w = asint(gAmbientOcclusionEffect.y * asfloat(r0.w) + 1);
	r1.w = asint(1 / gAmbientOcclusionEffect.y);
	r0.w = asint(asfloat(r0.w) * asfloat(r1.w));
	o.texcoord2.x = min(asfloat(r0.w), 1);
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	o.texcoord4 = asfloat(r1.xyz);
	r3 = asfloat(r1.zxy) * r2.yzx;
	r3 = asfloat(r1.yzx) * r2.zxy + -(r3.xyz);
	r3 = r3.xyz * i.tangent.www;
	o.texcoord5.xyz = r3.xyz;
	o.texcoord5.w = i.tangent.w;
	r4.xyz = -(asfloat(r0.xyz)) + gViewInverse[3].xyz;
	o.texcoord7 = asfloat(r0.xyz);
	o.texcoord6.x = dot(asfloat(r1.xyz), r4.xyz);
	o.texcoord6.z = dot(r2.xyz, r4.xyz);
	o.texcoord6.y = dot(r3.xyz, r4.xyz);

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	int4 r1;
	float4 r2;
	float3 r3;
	float4 r4;
	float3 r5;
	float4 r6;
	float3 r7;
	r0.xyz = asint(-(i.position.xyz) + Temporal_b7_o0_gBloodHeadHits[0].xyz);
	r0.x = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.x = asint(sqrt(asfloat(r0.x)));
	r0.x = asint(-(asfloat(r0.x)) + 0.0500000007);
	r0.x = asint(asfloat(r0.x) * 0.239999995);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.yzw = asint(-(i.position.xyz) + Temporal_b7_o0_gBloodHeadHits[1].xyz);
	r0.y = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r0.y = asint(sqrt(asfloat(r0.y)));
	r0.y = asint(-(asfloat(r0.y)) + 0.0500000007);
	r0.y = asint(asfloat(r0.y) * 0.239999995);
	r0.x = asint(max(asfloat(r0.y), asfloat(r0.x)));
	r0.yzw = asint(-(i.position.xyz) + Temporal_b7_o0_gBloodHeadHits[2].xyz);
	r0.y = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r0.y = asint(sqrt(asfloat(r0.y)));
	r0.y = asint(-(asfloat(r0.y)) + 0.0500000007);
	r0.y = asint(asfloat(r0.y) * 0.239999995);
	r0.x = asint(max(asfloat(r0.y), asfloat(r0.x)));
	r0.yzw = asint(-(i.position.xyz) + Temporal_b7_o0_gBloodHeadHits[3].xyz);
	r0.y = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r0.y = asint(sqrt(asfloat(r0.y)));
	r0.y = asint(-(asfloat(r0.y)) + 0.0500000007);
	r0.y = asint(asfloat(r0.y) * 0.239999995);
	r0.x = asint(max(asfloat(r0.y), asfloat(r0.x)));
	r0.yzw = asint(-(i.position.xyz) + Temporal_b7_o64_gBloodHeadCentreMass.xyz);
	r0.yzw = asint(asfloat(r0.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.x = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.yzw = asint(asfloat(r0.yzw) * asfloat(r1.xxx));
	r0.xyz = asint(asfloat(r0.xxx) * asfloat(r0.yzw));
	r0.xyz = asint(asfloat(r0.xyz) * Temporal_b4_o64_gBloodData.xxx + i.position.xyz);
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][0];
	r2 = Temporal_b1_o0_gBoneMtx[r1.x / 3][0] * i.blendweight.x + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.z / 3][0] * i.blendweight.z + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.w / 3][0] * i.blendweight.w + r2;
	r0.w = 1065353216;
	r3.x = dot(r2, asfloat(r0));
	r4 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][2];
	r4 = Temporal_b1_o0_gBoneMtx[r1.x / 3][2] * i.blendweight.x + r4;
	r4 = Temporal_b1_o0_gBoneMtx[r1.z / 3][2] * i.blendweight.z + r4;
	r4 = Temporal_b1_o0_gBoneMtx[r1.w / 3][2] * i.blendweight.w + r4;
	r3.z = dot(r4, asfloat(r0));
	r5 = r3.xxz * float3(6, 10, 10);
	r2.w = r5.z + r5.y;
	r6 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][1];
	r6 = Temporal_b1_o0_gBoneMtx[r1.x / 3][1] * i.blendweight.x + r6;
	r6 = Temporal_b1_o0_gBoneMtx[r1.z / 3][1] * i.blendweight.z + r6;
	r1 = asint(Temporal_b1_o0_gBoneMtx[r1.w / 3][1] * i.blendweight.w + r6);
	r3.y = dot(asfloat(r1), asfloat(r0));
	r0.x = asint(r3.y * 10 + r2.w);
	r0.yz = asint(Temporal_b9_o16_AirResist.ww * float2(4, 1.5) + float2(1, 1));
	r0.w = asint(asfloat(r0.z) * Temporal_b5_o32_globalScalars3.y);
	r0.x = asint(asfloat(r0.w) * Temporal_b9_o0_gWindParams.z + asfloat(r0.x));
	r0.z = asint(Temporal_b5_o32_globalScalars3.y * asfloat(r0.z) + r5.x);
	r5 = asfloat(r0.yyy) * i.color1.xxz;
	r5 = -(r5.xyz) * i.normal.xyz;
	r0.xy = asint(sin(asfloat(r0.xz)));
	r0.z = asint(saturate(Temporal_b9_o32_WindStr));
	r0.y = asint(abs(asfloat(r0.y)) * asfloat(r0.z));
	r0.x = asint(abs(asfloat(r0.x)) * asfloat(r0.y));
	r0.y = asint(r3.y * 4);
	r0.y = asint(asfloat(r0.w) * Temporal_b9_o0_gWindParams.w + asfloat(r0.y));
	r0.y = asint(sin(asfloat(r0.y)));
	r0.x = asint(abs(asfloat(r0.y)) * asfloat(r0.x));
	r6.x = Temporal_b5_o32_globalScalars3.z + 0.00000999999975;
	r6.y = Temporal_b5_o48_globalScalars4.z + 0.00000999999975;
	r6.z = 0.00000999999975;
	r0.y = asint(dot(r6.xyz, r6.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r0.yzw = asint(asfloat(r0.yyy) * r6.xyz);
	r0.y = asint(dot(asfloat(r0.yzw), i.normal.xyz));
	r0.y = asint(max(asfloat(r0.y), 0.25));
	r0.y = asint(min(asfloat(r0.y), 1));
	r6.y = dot(asfloat(r1.xyz), i.normal.xyz);
	r0.z = asint(dot(asfloat(r1.xyz), i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.zzz) * Temporal_b0_o0_gWorld[1].xyz);
	r7 = r6.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r6.x = dot(r2.xyz, i.normal.xyz);
	r0.z = asint(dot(r2.xyz, i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.zzz) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r1.xyz));
	r2.xyz = r6.xxx * Temporal_b0_o0_gWorld[0].xyz + r7.xyz;
	r6.z = dot(r4.xyz, i.normal.xyz);
	r0.z = asint(dot(r4.xyz, i.tangent.xyz));
	r1.xyz = asint(asfloat(r0.zzz) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r1.xyz));
	r2.xyz = r6.zzz * Temporal_b0_o0_gWorld[2].xyz + r2.xyz;
	o.texcoord9 = r6.xyz;
	r0.z = asint(saturate(dot(Temporal_b9_o16_AirResist.xyz, r2.xyz)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(-(asfloat(r0.z)) * Temporal_b9_o16_AirResist.w + 1);
	r0.w = (0.800000012 < asfloat(r0.z)) ? -1 : 0;
	r0.z = (r0.w != 0) ? 1065353216 : r0.z;
	r4.xyz = asfloat(r0.zzz) * r5.xyz;
	r0.yzw = asint(asfloat(r0.yyy) * r4.xyz);
	o.texcoord8.xyz = asfloat(r0.yzw) * asfloat(r0.xxx) + r3.xyz;
	r0.xyz = asint(r3.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(r3.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(r3.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + Temporal_b0_o0_gWorld[3].xyz);
	o.texcoord8.w = 1;
	o.texcoord = i.texcoord;
	o.texcoord1.xyz = r2.xyz;
	o.texcoord1.w = 1;
	r0.w = asint(i.color.x * Temporal_b5_o0_globalScalars.z + -1);
	r0.w = asint(Temporal_b5_o288_gAmbientOcclusionEffect.y * asfloat(r0.w) + 1);
	r1.w = asint(1 / Temporal_b5_o288_gAmbientOcclusionEffect.y);
	r0.w = asint(asfloat(r0.w) * asfloat(r1.w));
	o.texcoord2.x = min(asfloat(r0.w), 1);
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.zw = i.color.zw;
	o.texcoord4 = asfloat(r1.xyz);
	r3 = asfloat(r1.zxy) * r2.yzx;
	r3 = asfloat(r1.yzx) * r2.zxy + -(r3.xyz);
	r3 = r3.xyz * i.tangent.www;
	o.texcoord5.xyz = r3.xyz;
	o.texcoord5.w = i.tangent.w;
	r4.xyz = -(asfloat(r0.xyz)) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = asfloat(r0.xyz);
	o.texcoord6.x = dot(asfloat(r1.xyz), r4.xyz);
	o.texcoord6.z = dot(r2.xyz, r4.xyz);
	o.texcoord6.y = dot(r3.xyz, r4.xyz);

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
    o.texcoord7 = c.texcoord7;
    o.texcoord9 = c.texcoord9;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord1 = o.texcoord1;
    o.temporalInput_texcoord2 = o.texcoord2;
    o.temporalInput_texcoord4 = o.texcoord4;
    o.temporalInput_texcoord5 = o.texcoord5;
    o.temporalInput_texcoord6 = o.texcoord6;
    o.temporalInput_texcoord7 = o.texcoord7;
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
        o.temporalInput_texcoord7 = p.texcoord7;
        o.temporalInput_texcoord9 = p.texcoord9;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
