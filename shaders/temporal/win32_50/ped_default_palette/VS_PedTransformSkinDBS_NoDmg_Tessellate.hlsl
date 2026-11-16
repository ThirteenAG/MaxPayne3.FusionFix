cbuffer rage_bonemtx : register(b1)
{
	row_major float3x4 gBoneMtx[40] : packoffset(c0);
};

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
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float4 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 color : COLOR;
};

struct TemporalVertexResult
{
	float4 texcoord8 : TEXCOORD8;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
};
struct VS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord7 : TEXCOORD7;
	float3 texcoord9 : TEXCOORD9;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_texcoord : TEMPORAL1;
	float4 temporalInput_texcoord1 : TEMPORAL2;
	float4 temporalInput_texcoord2 : TEMPORAL3;
	float3 temporalInput_texcoord7 : TEMPORAL4;
	float3 temporalInput_texcoord9 : TEMPORAL5;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float3x4 Temporal_b1_o0_gBoneMtx[40] : packoffset(c1);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c121);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c125);
	float4 Temporal_b5_o0_globalScalars : packoffset(c129);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c130);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c131);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c132);
	float4 Temporal_b5_o64_globalFogParams : packoffset(c133);
	float4 Temporal_b5_o80_globalFogColor : packoffset(c134);
	float4 Temporal_b5_o96_globalFogOffsetN : packoffset(c135);
	float4 Temporal_b5_o112_globalFogColorN : packoffset(c136);
	float4 Temporal_b5_o128_globalScreenSize : packoffset(c137);
	float4 Temporal_b5_o144_globalDayNightEffects : packoffset(c138);
	float4 Temporal_b5_o160_ColorCorrectTopAndPedReflectScale : packoffset(c139);
	float4 Temporal_b5_o176_ColorCorrectBottomOffset : packoffset(c140);
	float4 Temporal_b5_o192_ColorShift : packoffset(c141);
	float4 Temporal_b5_o208_deSatContrastGamma : packoffset(c142);
	float4 Temporal_b5_o224_deSatContrastGammaIFX : packoffset(c143);
	float4 Temporal_b5_o240_colorize : packoffset(c144);
	float4 Temporal_b5_o256_globalUmScalars : packoffset(c145);
	float4 Temporal_b5_o272_gToneMapScalers : packoffset(c146);
	float4 Temporal_b5_o288_gAmbientOcclusionEffect : packoffset(c147);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	float4 r4;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * gBoneMtx[r0.y / 3][0];
	r1 = gBoneMtx[r0.x / 3][0] * i.blendweight.x + r1;
	r1 = gBoneMtx[r0.z / 3][0] * i.blendweight.z + r1;
	r1 = gBoneMtx[r0.w / 3][0] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz;
	r2.w = 1;
	r3.x = dot(r1, r2);
	r1.x = dot(r1.xyz, i.normal.xyz);
	r4 = i.blendweight.y * gBoneMtx[r0.y / 3][1];
	r4 = gBoneMtx[r0.x / 3][1] * i.blendweight.x + r4;
	r4 = gBoneMtx[r0.z / 3][1] * i.blendweight.z + r4;
	r4 = gBoneMtx[r0.w / 3][1] * i.blendweight.w + r4;
	r3.y = dot(r4, r2);
	r1.y = dot(r4.xyz, i.normal.xyz);
	r1.yzw = r1.yyy * gWorld[1].xyz;
	r1.xyz = r1.xxx * gWorld[0].xyz + r1.yzw;
	r4 = i.blendweight.y * gBoneMtx[r0.y / 3][2];
	r4 = gBoneMtx[r0.x / 3][2] * i.blendweight.x + r4;
	r4 = gBoneMtx[r0.z / 3][2] * i.blendweight.z + r4;
	r0 = asint(gBoneMtx[r0.w / 3][2] * i.blendweight.w + r4);
	r3.z = dot(asfloat(r0), r2);
	r0.x = asint(dot(asfloat(r0.xyz), i.normal.xyz));
	o.texcoord1.xyz = asfloat(r0.xxx) * gWorld[2].xyz + r1.xyz;
	o.texcoord8.xyz = r3.xyz;
	r0.xyz = asint(r3.yyy * gWorld[1].xyz);
	r0.xyz = asint(r3.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(r3.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	o.texcoord9 = asfloat(r0.xyz) + gWorld[3].xyz;
	o.texcoord8.w = 1;
	o.texcoord.xy = i.texcoord.xy;
	o.texcoord.zw = float2(0, 0);
	o.texcoord1.w = 1;
	r0.x = asint(dot(i.color.xy, globalDayNightEffects.zw));
	r0.x = asint(asfloat(r0.x) * globalScalars.z + -1);
	r0.x = asint(gAmbientOcclusionEffect.y * asfloat(r0.x) + 1);
	r0.y = asint(1 / gAmbientOcclusionEffect.y);
	o.texcoord2.xy = asfloat(r0.yy) * asfloat(r0.xx);
	o.texcoord2.zw = i.color.zw;
	o.texcoord7 = float3(0, 0, 0);

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	float4 r2;
	float3 r3;
	float4 r4;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r0 = r0 * int4(3, 3, 3, 3);
	r1 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][0];
	r1 = Temporal_b1_o0_gBoneMtx[r0.x / 3][0] * i.blendweight.x + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.z / 3][0] * i.blendweight.z + r1;
	r1 = Temporal_b1_o0_gBoneMtx[r0.w / 3][0] * i.blendweight.w + r1;
	r2.xyz = i.position.xyz;
	r2.w = 1;
	r3.x = dot(r1, r2);
	r1.x = dot(r1.xyz, i.normal.xyz);
	r4 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][1];
	r4 = Temporal_b1_o0_gBoneMtx[r0.x / 3][1] * i.blendweight.x + r4;
	r4 = Temporal_b1_o0_gBoneMtx[r0.z / 3][1] * i.blendweight.z + r4;
	r4 = Temporal_b1_o0_gBoneMtx[r0.w / 3][1] * i.blendweight.w + r4;
	r3.y = dot(r4, r2);
	r1.y = dot(r4.xyz, i.normal.xyz);
	r1.yzw = r1.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r1.xyz = r1.xxx * Temporal_b0_o0_gWorld[0].xyz + r1.yzw;
	r4 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r0.y / 3][2];
	r4 = Temporal_b1_o0_gBoneMtx[r0.x / 3][2] * i.blendweight.x + r4;
	r4 = Temporal_b1_o0_gBoneMtx[r0.z / 3][2] * i.blendweight.z + r4;
	r0 = asint(Temporal_b1_o0_gBoneMtx[r0.w / 3][2] * i.blendweight.w + r4);
	r3.z = dot(asfloat(r0), r2);
	r0.x = asint(dot(asfloat(r0.xyz), i.normal.xyz));
	o.texcoord1.xyz = asfloat(r0.xxx) * Temporal_b0_o0_gWorld[2].xyz + r1.xyz;
	o.texcoord8.xyz = r3.xyz;
	r0.xyz = asint(r3.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(r3.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(r3.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	o.texcoord9 = asfloat(r0.xyz) + Temporal_b0_o0_gWorld[3].xyz;
	o.texcoord8.w = 1;
	o.texcoord.xy = i.texcoord.xy;
	o.texcoord.zw = float2(0, 0);
	o.texcoord1.w = 1;
	r0.x = asint(dot(i.color.xy, Temporal_b5_o144_globalDayNightEffects.zw));
	r0.x = asint(asfloat(r0.x) * Temporal_b5_o0_globalScalars.z + -1);
	r0.x = asint(Temporal_b5_o288_gAmbientOcclusionEffect.y * asfloat(r0.x) + 1);
	r0.y = asint(1 / Temporal_b5_o288_gAmbientOcclusionEffect.y);
	o.texcoord2.xy = asfloat(r0.yy) * asfloat(r0.xx);
	o.texcoord2.zw = i.color.zw;
	o.texcoord7 = float3(0, 0, 0);

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
    o.texcoord7 = c.texcoord7;
    o.texcoord9 = c.texcoord9;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord1 = o.texcoord1;
    o.temporalInput_texcoord2 = o.texcoord2;
    o.temporalInput_texcoord7 = o.texcoord7;
    o.temporalInput_texcoord9 = o.texcoord9;
    [branch] if (TemporalState.x > 0)
    {
        TemporalVertexResult p = TemporalVertexPrevious(i);
        o.temporalInput_texcoord8 = p.texcoord8;
        o.temporalInput_texcoord = p.texcoord;
        o.temporalInput_texcoord1 = p.texcoord1;
        o.temporalInput_texcoord2 = p.texcoord2;
        o.temporalInput_texcoord7 = p.texcoord7;
        o.temporalInput_texcoord9 = p.texcoord9;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
