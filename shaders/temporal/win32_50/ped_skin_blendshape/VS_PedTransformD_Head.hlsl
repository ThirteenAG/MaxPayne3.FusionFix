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
	float reflectivePower : packoffset(c0.y);
	float3 specMapReflectMask : packoffset(c1);
	float fresnelRolloff : packoffset(c1.w);
	float bumpiness : packoffset(c2);
	float displacementScale : packoffset(c2.y);
	float specularFactor : packoffset(c2.z);
	float3 specMapIntMask : packoffset(c3);
	float4 specMapExpMask : packoffset(c4);
	float4 matMaterialColorScale : packoffset(c5);
	float4 gBloodData : packoffset(c6);
};

cbuffer BloodHitData : register(b7)
{
	float4 gBloodHeadHits[4] : packoffset(c0);
	float4 gBloodHeadCentreMass : packoffset(c4);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
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
	float3 texcoord4 : TEXCOORD4;
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
	float Temporal_b4_o0_ArmourStrength : packoffset(c36);
	float Temporal_b4_o4_reflectivePower : packoffset(c37);
	float3 Temporal_b4_o16_specMapReflectMask : packoffset(c38);
	float Temporal_b4_o28_fresnelRolloff : packoffset(c39);
	float Temporal_b4_o32_bumpiness : packoffset(c40);
	float Temporal_b4_o36_displacementScale : packoffset(c41);
	float Temporal_b4_o40_specularFactor : packoffset(c42);
	float3 Temporal_b4_o48_specMapIntMask : packoffset(c43);
	float4 Temporal_b4_o64_specMapExpMask : packoffset(c44);
	float4 Temporal_b4_o80_matMaterialColorScale : packoffset(c45);
	float4 Temporal_b4_o96_gBloodData : packoffset(c46);
	float4 Temporal_b7_o0_gBloodHeadHits[4] : packoffset(c47);
	float4 Temporal_b7_o64_gBloodHeadCentreMass : packoffset(c51);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float3 r2;
	float3 r3;
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
	r1.x = dot(r0.yzw, r0.yzw);
	r1.x = rsqrt(r1.x);
	r0.yzw = r0.yzw * r1.xxx;
	r0.xyz = r0.xxx * r0.yzw;
	r0.xyz = r0.xyz * gBloodData.xxx + i.position.xyz;
	r1 = r0.y * gWorldViewProj[1];
	r1 = r0.x * gWorldViewProj[0] + r1;
	r1 = r0.z * gWorldViewProj[2] + r1;
	r1 = r1 + gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord = i.texcoord;
	r1.xyz = i.normal.yyy * gWorld[1].xyz;
	r1.xyz = i.normal.xxx * gWorld[0].xyz + r1.xyz;
	r1.xyz = i.normal.zzz * gWorld[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord1 = r1;
	r0.w = i.color.x * globalScalars.z + -1;
	r0.w = gAmbientOcclusionEffect.y * r0.w + 1;
	r1.w = 1 / gAmbientOcclusionEffect.y;
	r0.w = r0.w * r1.w;
	o.texcoord2.x = min(r0.w, 1);
	o.texcoord2.z = -(i.color.y) * i.color.x + 1;
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.w = i.color.w;
	r2 = r0.yyy * gWorld[1].xyz;
	r0.xyw = r0.xxx * gWorld[0].xyz + r2.xyz;
	r0.xyz = r0.zzz * gWorld[2].xyz + r0.xyw;
	r0.xyz = r0.xyz + gWorld[3].xyz;
	r2 = -(r0.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r0.xyz;
	o.texcoord3 = r2.xyz;
	r0.xyz = i.tangent.yyy * gWorld[1].xyz;
	r0.xyz = i.tangent.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.tangent.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord4 = r0.xyz;
	r3 = r1.yzx * r0.zxy;
	r3 = r0.yzx * r1.zxy + -(r3.xyz);
	o.texcoord6.z = dot(r1.xyz, r2.xyz);
	o.texcoord6.x = dot(r0.xyz, r2.xyz);
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
	float4 r1;
	float3 r2;
	float3 r3;
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
	r1.x = dot(r0.yzw, r0.yzw);
	r1.x = rsqrt(r1.x);
	r0.yzw = r0.yzw * r1.xxx;
	r0.xyz = r0.xxx * r0.yzw;
	r0.xyz = r0.xyz * Temporal_b4_o96_gBloodData.xxx + i.position.xyz;
	r1 = r0.y * Temporal_b0_o128_gWorldViewProj[1];
	r1 = r0.x * Temporal_b0_o128_gWorldViewProj[0] + r1;
	r1 = r0.z * Temporal_b0_o128_gWorldViewProj[2] + r1;
	r1 = r1 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord = i.texcoord;
	r1.xyz = i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r1.xyz = i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	r1.xyz = i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord1 = r1;
	r0.w = i.color.x * Temporal_b5_o0_globalScalars.z + -1;
	r0.w = Temporal_b5_o288_gAmbientOcclusionEffect.y * r0.w + 1;
	r1.w = 1 / Temporal_b5_o288_gAmbientOcclusionEffect.y;
	r0.w = r0.w * r1.w;
	o.texcoord2.x = min(r0.w, 1);
	o.texcoord2.z = -(i.color.y) * i.color.x + 1;
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.w = i.color.w;
	r2 = r0.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyw = r0.xxx * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r0.xyz = r0.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyw;
	r0.xyz = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;
	r2 = -(r0.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = r0.xyz;
	o.texcoord3 = r2.xyz;
	r0.xyz = i.tangent.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = i.tangent.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0.xyz = i.tangent.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord4 = r0.xyz;
	r3 = r1.yzx * r0.zxy;
	r3 = r0.yzx * r1.zxy + -(r3.xyz);
	o.texcoord6.z = dot(r1.xyz, r2.xyz);
	o.texcoord6.x = dot(r0.xyz, r2.xyz);
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
