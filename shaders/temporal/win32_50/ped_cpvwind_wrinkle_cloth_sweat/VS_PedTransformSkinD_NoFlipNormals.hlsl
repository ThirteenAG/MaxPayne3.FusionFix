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

Buffer<float4> clothVertexTexture : register(t2);

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
	float4 texcoord4 : TEXCOORD4;
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
Buffer<float4> TemporalResource_t2_clothVertexTexture : register(t127);

VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float3 r5;
	float3 r6;
	float4 r7;
	float4 r8;
	float3 r9;
	float3 r10;
	float3 r11;
	float3 r12;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r1 = r0 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * gBoneMtx[r1.y / 3][0];
	r3 = i.blendweight.y * gBoneMtx[r1.y / 3][1];
	r4 = i.blendweight.y * gBoneMtx[r1.y / 3][2];
	r2 = gBoneMtx[r1.x / 3][0] * i.blendweight.x + r2;
	r3 = gBoneMtx[r1.x / 3][1] * i.blendweight.x + r3;
	r4 = gBoneMtx[r1.x / 3][2] * i.blendweight.x + r4;
	r2 = gBoneMtx[r1.z / 3][0] * i.blendweight.z + r2;
	r3 = gBoneMtx[r1.z / 3][1] * i.blendweight.z + r3;
	r4 = gBoneMtx[r1.z / 3][2] * i.blendweight.z + r4;
	r2 = gBoneMtx[r1.w / 3][0] * i.blendweight.w + r2;
	r3 = gBoneMtx[r1.w / 3][1] * i.blendweight.w + r3;
	r1 = asint(gBoneMtx[r1.w / 3][2] * i.blendweight.w + r4);
	r0.x = (254 < r0.x) ? -1 : 0;
	r2 = (r0.x != 0) ? gBoneMtx[0][0] : r2;
	r3 = (r0.x != 0) ? gBoneMtx[0][1] : r3;
	r1 = (r0.x != 0) ? asint(gBoneMtx[0][2]) : r1;
	r4.xyz = i.position.xyz;
	r4.w = 1;
	r5.x = dot(r2, r4);
	r5.y = dot(r3, r4);
	r5.z = dot(asfloat(r1), r4);
	r4.xyz = r5.yyy * gWorld[1].xyz;
	r4.xyz = r5.xxx * gWorld[0].xyz + r4.xyz;
	r4.xyz = r5.zzz * gWorld[2].xyz + r4.xyz;
	r4.xyz = r4.xyz + gWorld[3].xyz;
	r6 = -(r4.xyz) + gViewInverse[3].xyz;
	r1.w = asint(dot(r2.xyz, i.tangent.xyz));
	r2.w = dot(r3.xyz, i.tangent.xyz);
	r3.w = dot(asfloat(r1.xyz), i.tangent.xyz);
	r7.xyz = r2.www * gWorld[1].xyz;
	r7.xyz = asfloat(r1.www) * gWorld[0].xyz + r7.xyz;
	r7.xyz = r3.www * gWorld[2].xyz + r7.xyz;
	if (r0.x != 0) {
		r8.xyz = clothVertexTexture.Load(r0.y).xyz;
		r0.xyz = asint(clothVertexTexture.Load(r0.z).xyz);
		r9 = clothVertexTexture.Load(r0.w).xyz;
		r10.x = dot(gWorld[0].xyz, r8.xyz);
		r10.y = dot(gWorld[1].xyz, r8.xyz);
		r10.z = dot(gWorld[2].xyz, r8.xyz);
		r8.x = dot(gWorld[0].xyz, asfloat(r0.xyz));
		r8.y = dot(gWorld[1].xyz, asfloat(r0.xyz));
		r8.z = dot(gWorld[2].xyz, asfloat(r0.xyz));
		r0.x = asint(dot(gWorld[0].xyz, r9.xyz));
		r0.y = asint(dot(gWorld[1].xyz, r9.xyz));
		r0.z = asint(dot(gWorld[2].xyz, r9.xyz));
		r9 = -(r8.zxy) + r10.zxy;
		r11 = -(r8.yzx) + asfloat(r0.yzx);
		r12 = r9.xyz * r11.xyz;
		r9 = r9.zxy * r11.yzx + -(r12.xyz);
		r0.w = asint(dot(r9.xyz, r9.xyz));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r9 = asfloat(r0.www) * r9.xyz;
		r8.xyz = r8.xyz * i.blendweight.yyy;
		r8.xyz = i.blendweight.zzz * r10.xyz + r8.xyz;
		r0.xyz = asint(i.blendweight.xxx * asfloat(r0.xyz) + r8.xyz);
		r0.w = asint(i.blendweight.w + -0.5);
		r0.w = asint(asfloat(r0.w) * 0.100000001);
		r5 = asfloat(r0.www) * r9.xyz + asfloat(r0.xyz);
		r0.xyz = asint(r5.yyy * gWorld[1].xyz);
		r0.xyz = asint(r5.xxx * gWorld[0].xyz + asfloat(r0.xyz));
		r0.xyz = asint(r5.zzz * gWorld[2].xyz + asfloat(r0.xyz));
		o.texcoord7 = asfloat(r0.xyz) + gWorld[3].xyz;
		r0.xyz = asint(-(r9.yyy) * gWorld[1].xyz);
		r0.xyz = asint(-(r9.xxx) * gWorld[0].xyz + asfloat(r0.xyz));
		r0.xyz = asint(-(r9.zzz) * gWorld[2].xyz + asfloat(r0.xyz));
		r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
		r1.w = asint(dot(r7.xyz, r7.xyz));
		r1.w = asint(rsqrt(asfloat(r1.w)));
		r7.xyz = asfloat(r1.www) * r7.xyz;
		r8.xyz = asfloat(r0.yzx) * r7.zxy;
		r8.xyz = r7.yzx * asfloat(r0.zxy) + -(r8.xyz);
		r8.xyz = r8.xyz * i.tangent.www;
		r9 = -(r9.xyz);
	} else {
		r1.w = asint(dot(r2.xyz, i.normal.xyz));
		r2.x = dot(r3.xyz, i.normal.xyz);
		r1.x = asint(dot(asfloat(r1.xyz), i.normal.xyz));
		r2.xyz = r2.xxx * gWorld[1].xyz;
		r1.yzw = asint(asfloat(r1.www) * gWorld[0].xyz + r2.xyz);
		r0.xyz = asint(asfloat(r1.xxx) * gWorld[2].xyz + asfloat(r1.yzw));
		r1.xyz = asint(asfloat(r0.yzx) * r7.zxy);
		r1.xyz = asint(r7.yzx * asfloat(r0.zxy) + -(asfloat(r1.xyz)));
		r8.xyz = asfloat(r1.xyz) * i.tangent.www;
		r9 = i.normal.xyz;
		o.texcoord7 = r4.xyz;
	}
	o.texcoord6.x = dot(r7.xyz, r6.xyz);
	o.texcoord6.y = dot(r8.xyz, r6.xyz);
	o.texcoord6.z = dot(asfloat(r0.xyz), r6.xyz);
	r1.x = asint(saturate(dot(AirResist.xyz, asfloat(r0.xyz))));
	r1.x = asint(-(asfloat(r1.x)) + 1);
	r1.x = asint(-(asfloat(r1.x)) * AirResist.w + 1);
	r1.y = (0.800000012 < asfloat(r1.x)) ? -1 : 0;
	r1.x = (r1.y != 0) ? 1065353216 : r1.x;
	r1.yz = asint(AirResist.ww * float2(4, 1.5) + float2(1, 1));
	r2.x = globalScalars3.z + 0.00000999999975;
	r2.y = globalScalars4.z + 0.00000999999975;
	r2.z = 0.00000999999975;
	r1.w = asint(dot(r2.xyz, r2.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asfloat(r1.www) * r2.xyz;
	r1.w = asint(dot(r2.xyz, r9.xyz));
	r1.w = asint(max(asfloat(r1.w), 0.25));
	r1.w = asint(min(asfloat(r1.w), 1));
	r2.xyz = asfloat(r1.yyy) * i.color1.xxz;
	r2.xyz = -(r2.xyz) * r9.xyz;
	r1.y = asint(asfloat(r1.z) * globalScalars3.y);
	r2.w = saturate(WindStr);
	r3.xy = r5.xy * float2(6, 4);
	r1.z = asint(globalScalars3.y * asfloat(r1.z) + r3.x);
	r3.x = dot(r5.xzy, float3(10, 10, 10));
	r3.x = asfloat(r1.y) * gWindParams.z + r3.x;
	r3.x = sin(r3.x);
	r1.y = asint(asfloat(r1.y) * gWindParams.w + r3.y);
	r1.yz = asint(sin(asfloat(r1.yz)));
	r2.xyz = asfloat(r1.xxx) * r2.xyz;
	r2.xyz = asfloat(r1.www) * r2.xyz;
	r1.x = asint(abs(asfloat(r1.z)) * r2.w);
	r1.x = asint(abs(r3.x) * asfloat(r1.x));
	r1.x = asint(abs(asfloat(r1.y)) * asfloat(r1.x));
	r1.xyz = asint(r2.xyz * asfloat(r1.xxx) + r5.xyz);
	r2 = asfloat(r1.y) * gWorldViewProj[1];
	r2 = asfloat(r1.x) * gWorldViewProj[0] + r2;
	r1 = asint(asfloat(r1.z) * gWorldViewProj[2] + r2);
	r1 = asint(asfloat(r1) + gWorldViewProj[3]);
	o.texcoord2.y = i.color.y * globalScalars2.w;
	r2.x = i.color.x * globalScalars.z + -1;
	r2.x = gAmbientOcclusionEffect.y * r2.x + 1;
	r2.y = 1 / gAmbientOcclusionEffect.y;
	r2.x = r2.y * r2.x;
	o.texcoord2.x = min(r2.x, 1);
	o.sv_position = asfloat(r1);
	o.texcoord = i.texcoord;
	r0.w = r1.w;
	o.texcoord1 = asfloat(r0);
	o.texcoord2.zw = i.color.zw;
	r7.w = i.position.z;
	o.texcoord4 = r7;
	r8.w = i.tangent.w;
	o.texcoord5 = r8;
	o.texcoord3 = r6.xyz;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	float3 r5;
	float3 r6;
	float4 r7;
	float4 r8;
	float3 r9;
	float3 r10;
	float3 r11;
	float3 r12;
	r0 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r0 = (int4)asfloat(r0);
	r1 = r0 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][0];
	r3 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][1];
	r4 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][2];
	r2 = Temporal_b1_o0_gBoneMtx[r1.x / 3][0] * i.blendweight.x + r2;
	r3 = Temporal_b1_o0_gBoneMtx[r1.x / 3][1] * i.blendweight.x + r3;
	r4 = Temporal_b1_o0_gBoneMtx[r1.x / 3][2] * i.blendweight.x + r4;
	r2 = Temporal_b1_o0_gBoneMtx[r1.z / 3][0] * i.blendweight.z + r2;
	r3 = Temporal_b1_o0_gBoneMtx[r1.z / 3][1] * i.blendweight.z + r3;
	r4 = Temporal_b1_o0_gBoneMtx[r1.z / 3][2] * i.blendweight.z + r4;
	r2 = Temporal_b1_o0_gBoneMtx[r1.w / 3][0] * i.blendweight.w + r2;
	r3 = Temporal_b1_o0_gBoneMtx[r1.w / 3][1] * i.blendweight.w + r3;
	r1 = asint(Temporal_b1_o0_gBoneMtx[r1.w / 3][2] * i.blendweight.w + r4);
	r0.x = (254 < r0.x) ? -1 : 0;
	r2 = (r0.x != 0) ? Temporal_b1_o0_gBoneMtx[0][0] : r2;
	r3 = (r0.x != 0) ? Temporal_b1_o0_gBoneMtx[0][1] : r3;
	r1 = (r0.x != 0) ? asint(Temporal_b1_o0_gBoneMtx[0][2]) : r1;
	r4.xyz = i.position.xyz;
	r4.w = 1;
	r5.x = dot(r2, r4);
	r5.y = dot(r3, r4);
	r5.z = dot(asfloat(r1), r4);
	r4.xyz = r5.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r4.xyz = r5.xxx * Temporal_b0_o0_gWorld[0].xyz + r4.xyz;
	r4.xyz = r5.zzz * Temporal_b0_o0_gWorld[2].xyz + r4.xyz;
	r4.xyz = r4.xyz + Temporal_b0_o0_gWorld[3].xyz;
	r6 = -(r4.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	r1.w = asint(dot(r2.xyz, i.tangent.xyz));
	r2.w = dot(r3.xyz, i.tangent.xyz);
	r3.w = dot(asfloat(r1.xyz), i.tangent.xyz);
	r7.xyz = r2.www * Temporal_b0_o0_gWorld[1].xyz;
	r7.xyz = asfloat(r1.www) * Temporal_b0_o0_gWorld[0].xyz + r7.xyz;
	r7.xyz = r3.www * Temporal_b0_o0_gWorld[2].xyz + r7.xyz;
	if (r0.x != 0) {
		r8.xyz = TemporalResource_t2_clothVertexTexture.Load(r0.y).xyz;
		r0.xyz = asint(TemporalResource_t2_clothVertexTexture.Load(r0.z).xyz);
		r9 = TemporalResource_t2_clothVertexTexture.Load(r0.w).xyz;
		r10.x = dot(Temporal_b0_o0_gWorld[0].xyz, r8.xyz);
		r10.y = dot(Temporal_b0_o0_gWorld[1].xyz, r8.xyz);
		r10.z = dot(Temporal_b0_o0_gWorld[2].xyz, r8.xyz);
		r8.x = dot(Temporal_b0_o0_gWorld[0].xyz, asfloat(r0.xyz));
		r8.y = dot(Temporal_b0_o0_gWorld[1].xyz, asfloat(r0.xyz));
		r8.z = dot(Temporal_b0_o0_gWorld[2].xyz, asfloat(r0.xyz));
		r0.x = asint(dot(Temporal_b0_o0_gWorld[0].xyz, r9.xyz));
		r0.y = asint(dot(Temporal_b0_o0_gWorld[1].xyz, r9.xyz));
		r0.z = asint(dot(Temporal_b0_o0_gWorld[2].xyz, r9.xyz));
		r9 = -(r8.zxy) + r10.zxy;
		r11 = -(r8.yzx) + asfloat(r0.yzx);
		r12 = r9.xyz * r11.xyz;
		r9 = r9.zxy * r11.yzx + -(r12.xyz);
		r0.w = asint(dot(r9.xyz, r9.xyz));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r9 = asfloat(r0.www) * r9.xyz;
		r8.xyz = r8.xyz * i.blendweight.yyy;
		r8.xyz = i.blendweight.zzz * r10.xyz + r8.xyz;
		r0.xyz = asint(i.blendweight.xxx * asfloat(r0.xyz) + r8.xyz);
		r0.w = asint(i.blendweight.w + -0.5);
		r0.w = asint(asfloat(r0.w) * 0.100000001);
		r5 = asfloat(r0.www) * r9.xyz + asfloat(r0.xyz);
		r0.xyz = asint(r5.yyy * Temporal_b0_o0_gWorld[1].xyz);
		r0.xyz = asint(r5.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
		r0.xyz = asint(r5.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
		o.texcoord7 = asfloat(r0.xyz) + Temporal_b0_o0_gWorld[3].xyz;
		r0.xyz = asint(-(r9.yyy) * Temporal_b0_o0_gWorld[1].xyz);
		r0.xyz = asint(-(r9.xxx) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.xyz));
		r0.xyz = asint(-(r9.zzz) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.xyz));
		r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
		r1.w = asint(dot(r7.xyz, r7.xyz));
		r1.w = asint(rsqrt(asfloat(r1.w)));
		r7.xyz = asfloat(r1.www) * r7.xyz;
		r8.xyz = asfloat(r0.yzx) * r7.zxy;
		r8.xyz = r7.yzx * asfloat(r0.zxy) + -(r8.xyz);
		r8.xyz = r8.xyz * i.tangent.www;
		r9 = -(r9.xyz);
	} else {
		r1.w = asint(dot(r2.xyz, i.normal.xyz));
		r2.x = dot(r3.xyz, i.normal.xyz);
		r1.x = asint(dot(asfloat(r1.xyz), i.normal.xyz));
		r2.xyz = r2.xxx * Temporal_b0_o0_gWorld[1].xyz;
		r1.yzw = asint(asfloat(r1.www) * Temporal_b0_o0_gWorld[0].xyz + r2.xyz);
		r0.xyz = asint(asfloat(r1.xxx) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r1.yzw));
		r1.xyz = asint(asfloat(r0.yzx) * r7.zxy);
		r1.xyz = asint(r7.yzx * asfloat(r0.zxy) + -(asfloat(r1.xyz)));
		r8.xyz = asfloat(r1.xyz) * i.tangent.www;
		r9 = i.normal.xyz;
		o.texcoord7 = r4.xyz;
	}
	o.texcoord6.x = dot(r7.xyz, r6.xyz);
	o.texcoord6.y = dot(r8.xyz, r6.xyz);
	o.texcoord6.z = dot(asfloat(r0.xyz), r6.xyz);
	r1.x = asint(saturate(dot(Temporal_b4_o16_AirResist.xyz, asfloat(r0.xyz))));
	r1.x = asint(-(asfloat(r1.x)) + 1);
	r1.x = asint(-(asfloat(r1.x)) * Temporal_b4_o16_AirResist.w + 1);
	r1.y = (0.800000012 < asfloat(r1.x)) ? -1 : 0;
	r1.x = (r1.y != 0) ? 1065353216 : r1.x;
	r1.yz = asint(Temporal_b4_o16_AirResist.ww * float2(4, 1.5) + float2(1, 1));
	r2.x = Temporal_b5_o32_globalScalars3.z + 0.00000999999975;
	r2.y = Temporal_b5_o48_globalScalars4.z + 0.00000999999975;
	r2.z = 0.00000999999975;
	r1.w = asint(dot(r2.xyz, r2.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asfloat(r1.www) * r2.xyz;
	r1.w = asint(dot(r2.xyz, r9.xyz));
	r1.w = asint(max(asfloat(r1.w), 0.25));
	r1.w = asint(min(asfloat(r1.w), 1));
	r2.xyz = asfloat(r1.yyy) * i.color1.xxz;
	r2.xyz = -(r2.xyz) * r9.xyz;
	r1.y = asint(asfloat(r1.z) * Temporal_b5_o32_globalScalars3.y);
	r2.w = saturate(Temporal_b4_o32_WindStr);
	r3.xy = r5.xy * float2(6, 4);
	r1.z = asint(Temporal_b5_o32_globalScalars3.y * asfloat(r1.z) + r3.x);
	r3.x = dot(r5.xzy, float3(10, 10, 10));
	r3.x = asfloat(r1.y) * Temporal_b4_o0_gWindParams.z + r3.x;
	r3.x = sin(r3.x);
	r1.y = asint(asfloat(r1.y) * Temporal_b4_o0_gWindParams.w + r3.y);
	r1.yz = asint(sin(asfloat(r1.yz)));
	r2.xyz = asfloat(r1.xxx) * r2.xyz;
	r2.xyz = asfloat(r1.www) * r2.xyz;
	r1.x = asint(abs(asfloat(r1.z)) * r2.w);
	r1.x = asint(abs(r3.x) * asfloat(r1.x));
	r1.x = asint(abs(asfloat(r1.y)) * asfloat(r1.x));
	r1.xyz = asint(r2.xyz * asfloat(r1.xxx) + r5.xyz);
	r2 = asfloat(r1.y) * Temporal_b0_o128_gWorldViewProj[1];
	r2 = asfloat(r1.x) * Temporal_b0_o128_gWorldViewProj[0] + r2;
	r1 = asint(asfloat(r1.z) * Temporal_b0_o128_gWorldViewProj[2] + r2);
	r1 = asint(asfloat(r1) + Temporal_b0_o128_gWorldViewProj[3]);
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	r2.x = i.color.x * Temporal_b5_o0_globalScalars.z + -1;
	r2.x = Temporal_b5_o288_gAmbientOcclusionEffect.y * r2.x + 1;
	r2.y = 1 / Temporal_b5_o288_gAmbientOcclusionEffect.y;
	r2.x = r2.y * r2.x;
	o.texcoord2.x = min(r2.x, 1);
	o.sv_position = asfloat(r1);
	o.texcoord = i.texcoord;
	r0.w = r1.w;
	o.texcoord1 = asfloat(r0);
	o.texcoord2.zw = i.color.zw;
	r7.w = i.position.z;
	o.texcoord4 = r7;
	r8.w = i.tangent.w;
	o.texcoord5 = r8;
	o.texcoord3 = r6.xyz;

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
