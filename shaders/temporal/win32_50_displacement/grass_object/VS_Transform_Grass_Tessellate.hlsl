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
};

cbuffer Movement : register(b4)
{
	float4 umGlobalParams : packoffset(c0);
	float4 WindGlobalParams : packoffset(c1);
};

cbuffer PlantAttributes : register(b7)
{
	float g_fCollisionSqScale : packoffset(c0);
	float g_fGrassSpringRigidity : packoffset(c0.y);
	float g_fGrassSpringScale : packoffset(c0.z);
	float g_fEnableSpringForces : packoffset(c0.w);
	float4 g_vCollisionSpheres[5] : packoffset(c1);
	float3 g_vPlayerPosition : packoffset(c6);
	float2 g_vCollisionParams : packoffset(c7);
};

struct VS_IN
{
	float3 position : POSITION;
	float3 normal : NORMAL;
	float4 color : COLOR;
	float4 color1 : COLOR1;
	float2 texcoord : TEXCOORD;
};

struct TemporalVertexResult
{
	float4 texcoord8 : TEXCOORD8;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord6 : TEXCOORD6;
};
struct VS_OUT
{
	float4 texcoord8 : TEXCOORD8;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord6 : TEXCOORD6;
	float3 temporalPrevious : TEXCOORD15;
	float4 temporalInput_texcoord8 : TEMPORAL0;
	float4 temporalInput_color : TEMPORAL1;
	float2 temporalInput_texcoord : TEMPORAL2;
	float4 temporalInput_texcoord1 : TEMPORAL3;
	float4 temporalInput_texcoord6 : TEMPORAL4;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c1);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c5);
	float4 Temporal_b5_o0_globalScalars : packoffset(c9);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c10);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c11);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c12);
	float4 Temporal_b5_o64_globalFogParams : packoffset(c13);
	float4 Temporal_b5_o80_globalFogColor : packoffset(c14);
	float4 Temporal_b5_o96_globalFogOffsetN : packoffset(c15);
	float4 Temporal_b5_o112_globalFogColorN : packoffset(c16);
	float4 Temporal_b5_o128_globalScreenSize : packoffset(c17);
	float4 Temporal_b5_o144_globalDayNightEffects : packoffset(c18);
	float4 Temporal_b5_o160_ColorCorrectTopAndPedReflectScale : packoffset(c19);
	float4 Temporal_b5_o176_ColorCorrectBottomOffset : packoffset(c20);
	float4 Temporal_b5_o192_ColorShift : packoffset(c21);
	float4 Temporal_b5_o208_deSatContrastGamma : packoffset(c22);
	float4 Temporal_b5_o224_deSatContrastGammaIFX : packoffset(c23);
	float4 Temporal_b5_o240_colorize : packoffset(c24);
	float4 Temporal_b5_o256_globalUmScalars : packoffset(c25);
	float4 Temporal_b4_o0_umGlobalParams : packoffset(c26);
	float4 Temporal_b4_o16_WindGlobalParams : packoffset(c27);
	float Temporal_b7_o0_g_fCollisionSqScale : packoffset(c28);
	float Temporal_b7_o4_g_fGrassSpringRigidity : packoffset(c29);
	float Temporal_b7_o8_g_fGrassSpringScale : packoffset(c30);
	float Temporal_b7_o12_g_fEnableSpringForces : packoffset(c31);
	float4 Temporal_b7_o16_g_vCollisionSpheres[5] : packoffset(c32);
	float3 Temporal_b7_o96_g_vPlayerPosition : packoffset(c37);
	float2 Temporal_b7_o112_g_vCollisionParams : packoffset(c38);
};


TemporalVertexResult TemporalCurrent(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	int4 r2;
	float3 r3;
	float3 r4;
	r0.x = asint(i.color1.x * globalUmScalars.x);
	r0.xy = asint(asfloat(r0.xx) * umGlobalParams.xx);
	r0.w = asint(-(i.color1.z) + 1);
	r1.x = asfloat(r0.w) * globalUmScalars.y;
	r0.z = asint(r1.x * umGlobalParams.y);
	r1.x = i.color1.y * 6.28318548;
	r1.yzw = globalUmScalars.zzw * umGlobalParams.zzw;
	r1.xyz = globalScalars2.yyy * r1.yzw + r1.xxx;
	r1.xyz = sin(r1.xyz);
	r1.xyz = r1.xyz * asfloat(r0.xyz) + i.position.xyz;
	r0.x = asint(r1.z * deSatContrastGamma.w);
	r0.y = asint(asfloat(r0.w) * WindGlobalParams.x);
	r1.xy = asfloat(r0.xx) * asfloat(r0.yy) + r1.xy;
	r0.xyz = asint(-(gWorld[3].xyz) + g_vPlayerPosition.xyz);
	r2.x = asint(dot(gWorld[0].xyz, asfloat(r0.xyz)));
	r2.y = asint(dot(gWorld[1].xyz, asfloat(r0.xyz)));
	r2.z = asint(dot(gWorld[2].xyz, asfloat(r0.xyz)));
	r0.xyz = asint(r1.xyz + -(asfloat(r2.xyz)));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(-(asfloat(r0.w)) + g_vCollisionParams.x);
	r0.w = asint(max(asfloat(r0.w), 0));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.z = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r0.xy = asint(asfloat(r0.zz) * asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.xy) * i.color1.xx);
	r0.xy = asint(asfloat(r0.ww) * asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.xy) * g_fCollisionSqScale + r1.xy);
	r0.w = (0 < g_fEnableSpringForces) ? -1 : 0;
	if (r0.w != 0) {
		r0.w = asint(dot(r1.xyz, r1.xyz));
		r0.w = asint(asfloat(r0.w) * 10);
		r0.w = asint(globalScalars2.y * g_fGrassSpringRigidity + asfloat(r0.w));
		r0.w = asint(sin(asfloat(r0.w)));
		r0.w = asint(asfloat(r0.w) * g_fGrassSpringScale);
		r0.z = asint(r1.z);
		r2.xyz = int3(0, 0, 0);
		while (true) {
			r2.w = (r2.z >= 5) ? -1 : 0;
			if (r2.w != 0) break;
			r3 = -(gWorld[3].xyz) + g_vCollisionSpheres[r2.z].xyz;
			r4.x = dot(gWorld[0].xyz, r3.xyz);
			r4.y = dot(gWorld[1].xyz, r3.xyz);
			r4.z = dot(gWorld[2].xyz, r3.xyz);
			r3 = asfloat(r0.xyz) + -(r4.xyz);
			r2.w = asint(dot(r3.xyz, r3.xyz));
			r2.w = asint(sqrt(asfloat(r2.w)));
			r2.w = asint(-(asfloat(r2.w)) + g_vCollisionSpheres[r2.z].x);
			r2.w = asint(max(asfloat(r2.w), 0));
			r2.w = asint(asfloat(r0.w) * asfloat(r2.w));
			r3 = r3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
			r3.z = dot(r3.xyz, r3.xyz);
			r3.z = rsqrt(r3.z);
			r3.xy = r3.zz * r3.xy;
			r3.xy = r3.xy * i.color1.xx;
			r3.xy = asfloat(r2.ww) * r3.xy;
			r2.xy = asint(r3.xy * g_fCollisionSqScale + asfloat(r2.xy));
			r2.z = r2.z + 1;
		}
		r1.xy = asfloat(r0.xy) + asfloat(r2.xy);
	} else {
		r1.xy = asfloat(r0.xy);
	}
	r0.xyz = asint(i.normal.yyy * gWorld[1].xyz);
	r0.xyz = asint(i.normal.xxx * gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.normal.zzz * gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord1.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	r0 = asint(i.position.y * gWorld[1]);
	r0 = asint(i.position.x * gWorld[0] + asfloat(r0));
	r0 = asint(i.position.z * gWorld[2] + asfloat(r0));
	o.texcoord6 = asfloat(r0) + gWorld[3];
	r1.w = 1;
	o.texcoord8 = r1;
	o.color = i.color;
	o.texcoord1.w = 1;
	o.texcoord = i.texcoord.xy;

	return o;
}

TemporalVertexResult TemporalVertexPrevious(VS_IN i)
{
	TemporalVertexResult o;

	int4 r0;
	float4 r1;
	int4 r2;
	float3 r3;
	float3 r4;
	r0.x = asint(i.color1.x * Temporal_b5_o256_globalUmScalars.x);
	r0.xy = asint(asfloat(r0.xx) * Temporal_b4_o0_umGlobalParams.xx);
	r0.w = asint(-(i.color1.z) + 1);
	r1.x = asfloat(r0.w) * Temporal_b5_o256_globalUmScalars.y;
	r0.z = asint(r1.x * Temporal_b4_o0_umGlobalParams.y);
	r1.x = i.color1.y * 6.28318548;
	r1.yzw = Temporal_b5_o256_globalUmScalars.zzw * Temporal_b4_o0_umGlobalParams.zzw;
	r1.xyz = Temporal_b5_o16_globalScalars2.yyy * r1.yzw + r1.xxx;
	r1.xyz = sin(r1.xyz);
	r1.xyz = r1.xyz * asfloat(r0.xyz) + i.position.xyz;
	r0.x = asint(r1.z * Temporal_b5_o208_deSatContrastGamma.w);
	r0.y = asint(asfloat(r0.w) * Temporal_b4_o16_WindGlobalParams.x);
	r1.xy = asfloat(r0.xx) * asfloat(r0.yy) + r1.xy;
	r0.xyz = asint(-(Temporal_b0_o0_gWorld[3].xyz) + Temporal_b7_o96_g_vPlayerPosition.xyz);
	r2.x = asint(dot(Temporal_b0_o0_gWorld[0].xyz, asfloat(r0.xyz)));
	r2.y = asint(dot(Temporal_b0_o0_gWorld[1].xyz, asfloat(r0.xyz)));
	r2.z = asint(dot(Temporal_b0_o0_gWorld[2].xyz, asfloat(r0.xyz)));
	r0.xyz = asint(r1.xyz + -(asfloat(r2.xyz)));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(-(asfloat(r0.w)) + Temporal_b7_o112_g_vCollisionParams.x);
	r0.w = asint(max(asfloat(r0.w), 0));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.z = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r0.xy = asint(asfloat(r0.zz) * asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.xy) * i.color1.xx);
	r0.xy = asint(asfloat(r0.ww) * asfloat(r0.xy));
	r0.xy = asint(asfloat(r0.xy) * Temporal_b7_o0_g_fCollisionSqScale + r1.xy);
	r0.w = (0 < Temporal_b7_o12_g_fEnableSpringForces) ? -1 : 0;
	if (r0.w != 0) {
		r0.w = asint(dot(r1.xyz, r1.xyz));
		r0.w = asint(asfloat(r0.w) * 10);
		r0.w = asint(Temporal_b5_o16_globalScalars2.y * Temporal_b7_o4_g_fGrassSpringRigidity + asfloat(r0.w));
		r0.w = asint(sin(asfloat(r0.w)));
		r0.w = asint(asfloat(r0.w) * Temporal_b7_o8_g_fGrassSpringScale);
		r0.z = asint(r1.z);
		r2.xyz = int3(0, 0, 0);
		while (true) {
			r2.w = (r2.z >= 5) ? -1 : 0;
			if (r2.w != 0) break;
			r3 = -(Temporal_b0_o0_gWorld[3].xyz) + Temporal_b7_o16_g_vCollisionSpheres[r2.z].xyz;
			r4.x = dot(Temporal_b0_o0_gWorld[0].xyz, r3.xyz);
			r4.y = dot(Temporal_b0_o0_gWorld[1].xyz, r3.xyz);
			r4.z = dot(Temporal_b0_o0_gWorld[2].xyz, r3.xyz);
			r3 = asfloat(r0.xyz) + -(r4.xyz);
			r2.w = asint(dot(r3.xyz, r3.xyz));
			r2.w = asint(sqrt(asfloat(r2.w)));
			r2.w = asint(-(asfloat(r2.w)) + Temporal_b7_o16_g_vCollisionSpheres[r2.z].x);
			r2.w = asint(max(asfloat(r2.w), 0));
			r2.w = asint(asfloat(r0.w) * asfloat(r2.w));
			r3 = r3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
			r3.z = dot(r3.xyz, r3.xyz);
			r3.z = rsqrt(r3.z);
			r3.xy = r3.zz * r3.xy;
			r3.xy = r3.xy * i.color1.xx;
			r3.xy = asfloat(r2.ww) * r3.xy;
			r2.xy = asint(r3.xy * Temporal_b7_o0_g_fCollisionSqScale + asfloat(r2.xy));
			r2.z = r2.z + 1;
		}
		r1.xy = asfloat(r0.xy) + asfloat(r2.xy);
	} else {
		r1.xy = asfloat(r0.xy);
	}
	r0.xyz = asint(i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r0.xyz = asint(i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
	r0.xyz = asint(i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	o.texcoord1.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	r0 = asint(i.position.y * Temporal_b0_o0_gWorld[1]);
	r0 = asint(i.position.x * Temporal_b0_o0_gWorld[0] + asfloat(r0));
	r0 = asint(i.position.z * Temporal_b0_o0_gWorld[2] + asfloat(r0));
	o.texcoord6 = asfloat(r0) + Temporal_b0_o0_gWorld[3];
	r1.w = 1;
	o.texcoord8 = r1;
	o.color = i.color;
	o.texcoord1.w = 1;
	o.texcoord = i.texcoord.xy;

	return o;
}

VS_OUT main(VS_IN i)
{
    TemporalVertexResult c = TemporalCurrent(i);
    VS_OUT o;
    o.texcoord8 = c.texcoord8;
    o.color = c.color;
    o.texcoord = c.texcoord;
    o.texcoord1 = c.texcoord1;
    o.texcoord6 = c.texcoord6;
    o.temporalPrevious = float3(0, 0, -1);
    o.temporalInput_texcoord8 = o.texcoord8;
    o.temporalInput_color = o.color;
    o.temporalInput_texcoord = o.texcoord;
    o.temporalInput_texcoord1 = o.texcoord1;
    o.temporalInput_texcoord6 = o.texcoord6;
    [branch] if (TemporalState.x > 0)
    {
        TemporalVertexResult p = TemporalVertexPrevious(i);
        o.temporalInput_texcoord8 = p.texcoord8;
        o.temporalInput_color = p.color;
        o.temporalInput_texcoord = p.texcoord;
        o.temporalInput_texcoord1 = p.texcoord1;
        o.temporalInput_texcoord6 = p.texcoord6;
        o.temporalPrevious = mul(p.texcoord8, Temporal_b0_o128_gWorldViewProj).xyw;
    }
    return o;
}
