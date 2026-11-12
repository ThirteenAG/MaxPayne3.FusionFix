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

cbuffer CacheZShiftandParallax : register(b4)
{
	float zShiftScale : packoffset(c0);
};

cbuffer vehicle_switchon : register(b13)
{
	bool switchOn : packoffset(c0);
};

cbuffer CacheVehicleRadius : register(b7)
{
	float BoundRadius : packoffset(c0);
};

cbuffer CacheMegaVariables : register(b9)
{
	float specularFactor : packoffset(c0);
	float specularColorFactor : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
	float reflectivePower : packoffset(c0.w);
	float fresnelRolloff : packoffset(c1);
	float HardAlphaBlend : packoffset(c1.y);
	row_major float4x4 gBloodUVBoundsPage : packoffset(c2);
};

SamplerState DamageSampler : register(s1);
Texture2D DamageSampler_tex : register(t1);

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
	float2 texcoord7 : TEXCOORD7;
	float4 texcoord1 : TEXCOORD1;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float4 texcoord6 : TEXCOORD6;
	float4 texcoord2 : TEXCOORD2;
	float3 temporalPrevious : TEXCOORD15;
};

cbuffer TemporalPrevious : register(b12)
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
	float Temporal_b4_o0_zShiftScale : packoffset(c36);
	bool Temporal_b13_o0_switchOn : packoffset(c37);
	float Temporal_b7_o0_BoundRadius : packoffset(c38);
	float Temporal_b9_o0_specularFactor : packoffset(c39);
	float Temporal_b9_o4_specularColorFactor : packoffset(c40);
	float Temporal_b9_o8_bumpiness : packoffset(c41);
	float Temporal_b9_o12_reflectivePower : packoffset(c42);
	float Temporal_b9_o16_fresnelRolloff : packoffset(c43);
	float Temporal_b9_o20_HardAlphaBlend : packoffset(c44);
	row_major float4x4 Temporal_b9_o32_gBloodUVBoundsPage : packoffset(c45);
};
Texture2D TemporalResource_t1_DamageSampler_tex : register(t127);

VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	int4 r2;
	int4 r3;
	float4 r4;
	float3 r5;
	float4 r6;
	float3 r7;
	float3 r8;
	r0.x = asint(i.color.z * 255);
	r0.x = asint(round(asfloat(r0.x)));
	r0.x = (int)asfloat(r0.x);
	if (switchOn != 0) {
		r0.y = asint(dot(i.position.xyz, i.position.xyz));
		r0.y = asint(sqrt(asfloat(r0.y)));
		r1.xyz = asint(i.position.xyz / asfloat(r0.yyy));
		r0.z = asint(-(asfloat(r1.z)) + 1);
		r0.z = asint(asfloat(r0.z) * 0.5);
		r1.xy = asint(asfloat(r1.xy) + float2(0.00000999999975, 0.00000999999975));
		r0.w = asint(dot(asfloat(r1.xy), asfloat(r1.xy)));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r1.xy = asint(asfloat(r0.ww) * asfloat(r1.xy));
		r0.zw = asint(asfloat(r0.zz) * asfloat(r1.xy));
		r0.zw = asint(asfloat(r0.zw) * float2(0.5, 0.5) + float2(0.5, 0.5));
		r1.xy = asint(asfloat(r0.zw) * float2(126.732674, 126.732674));
		r1.zw = (asfloat(r1.xy) >= -(asfloat(r1.xy))) ? -1 : 0;
		r1.xy = asint(frac(abs(asfloat(r1.xy))));
		r1.xy = (r1.zw != 0) ? r1.xy : asint(-(asfloat(r1.xy)));
		r1.z = asint(DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r0.zw), 0).x);
		r0.zw = asint(-(asfloat(r1.xy)) * float2(0.00789062493, 0.00789062493) + asfloat(r0.zw));
		r2 = asint(asfloat(r0.zwzw) + float4(0.00789062493, 0, 0, 0.00789062493));
		r1.w = asint(DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.xy), 0).x);
		r2.x = asint(DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.zw), 0).x);
		r2.yz = asint(asfloat(r0.zw) + float2(0.00789062493, 0.00789062493));
		r2.y = asint(DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.yz), 0).x);
		r2.z = asint(asfloat(r1.z) * 0.0000152587891);
		r3.z = asint(trunc(asfloat(r2.z)));
		r1.z = asint(-(asfloat(r3.z)) * 65536 + asfloat(r1.z));
		r2.z = asint(asfloat(r1.z) * 0.00390625);
		r3.y = asint(trunc(asfloat(r2.z)));
		r3.x = asint(-(asfloat(r3.y)) * 256 + asfloat(r1.z));
		r1.z = asint(asfloat(r1.w) * 0.0000152587891);
		r4.z = trunc(asfloat(r1.z));
		r1.z = asint(-(r4.z) * 65536 + asfloat(r1.w));
		r1.w = asint(asfloat(r1.z) * 0.00390625);
		r4.y = trunc(asfloat(r1.w));
		r4.x = -(r4.y) * 256 + asfloat(r1.z);
		r1.z = asint(asfloat(r2.x) * 0.0000152587891);
		r5.z = trunc(asfloat(r1.z));
		r1.z = asint(-(r5.z) * 65536 + asfloat(r2.x));
		r1.w = asint(asfloat(r1.z) * 0.00390625);
		r5.y = trunc(asfloat(r1.w));
		r5.x = -(r5.y) * 256 + asfloat(r1.z);
		r1.z = asint(asfloat(r2.y) * 0.0000152587891);
		r6.z = trunc(asfloat(r1.z));
		r1.z = asint(-(r6.z) * 65536 + asfloat(r2.y));
		r1.w = asint(asfloat(r1.z) * 0.00390625);
		r6.y = trunc(asfloat(r1.w));
		r6.x = -(r6.y) * 256 + asfloat(r1.z);
		r1.zw = asint(-(asfloat(r1.xy)) + float2(1, 1));
		r2.xyz = asint(asfloat(r1.zzz) * asfloat(r3.xyz));
		r7 = asfloat(r1.xxx) * r4.xyz;
		r7 = asfloat(r1.www) * r7.xyz;
		r2.xyz = asint(asfloat(r2.xyz) * asfloat(r1.www) + r7.xyz);
		r7 = asfloat(r1.zzz) * r5.xyz;
		r2.xyz = asint(r7.xyz * asfloat(r1.yyy) + asfloat(r2.xyz));
		r1.xzw = asint(asfloat(r1.xxx) * r6.xyz);
		r1.xyz = asint(asfloat(r1.xzw) * asfloat(r1.yyy) + asfloat(r2.xyz));
		r1.xyz = asint(asfloat(r1.xyz) + float3(-128, -128, -128));
		r1.xyz = asint(asfloat(r1.xyz) * float3(0.0078125, 0.0078125, 0.0078125));
		r0.y = asint(asfloat(r0.y) / BoundRadius);
		r0.y = asint(min(asfloat(r0.y), 1));
		r1.xyz = asint(asfloat(r0.yyy) * asfloat(r1.xyz));
		r1.xyz = asint(asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + i.position.xyz);
		r2.xyz = (i.normal.xyz == float3(1, 1, 1)) ? -1 : 0;
		r1.w = r2.y & r2.x;
		r1.w = r2.z & r1.w;
		if (r1.w != 0) {
			r2.xyz = int3(0, 0, 1065353216);
		} else {
			r6 = asfloat(r0.zwzw) + float4(-0.5, -0.5, -0.492109388, -0.5);
			r6 = r6 + r6;
			r1.w = asint(dot(r6.xy, r6.xy));
			r2.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r1.w = asint(sqrt(asfloat(r1.w)));
			r1.w = r1.w & r2.w;
			r2.w = asint(-(asfloat(r1.w)) * 2 + 1);
			r7.z = max(asfloat(r2.w), -1);
			r2.w = (r7.z < 1) ? -1 : 0;
			r3.w = (-1 < r7.z) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = asint(-(r7.z) * r7.z + 1);
			r3.w = asint(sqrt(asfloat(r3.w)));
			r1.w = asint(asfloat(r3.w) / asfloat(r1.w));
			r1.w = r1.w & r2.w;
			r7.xy = asfloat(r1.ww) * r6.xy;
			r3.xyz = asint(asfloat(r3.xyz) + float3(-128, -128, -128));
			r3.xyz = asint(asfloat(r0.yyy) * asfloat(r3.xyz));
			r3.xyz = asint(asfloat(r3.xyz) * float3(0.00390625, 0.00390625, 0.00390625));
			r1.w = asint(dot(r6.zw, r6.zw));
			r2.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r1.w = asint(sqrt(asfloat(r1.w)));
			r1.w = r1.w & r2.w;
			r2.w = asint(-(asfloat(r1.w)) * 2 + 1);
			r8.z = max(asfloat(r2.w), -1);
			r2.w = (r8.z < 1) ? -1 : 0;
			r3.w = (-1 < r8.z) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = asint(-(r8.z) * r8.z + 1);
			r3.w = asint(sqrt(asfloat(r3.w)));
			r1.w = asint(asfloat(r3.w) / asfloat(r1.w));
			r1.w = r1.w & r2.w;
			r8.xy = asfloat(r1.ww) * r6.zw;
			r6.xyz = r8.xyz + float3(0.00000000999999994, 0.00000000999999994, 0.00000000999999994);
			r4.xyz = r4.xyz + float3(-128, -128, -128);
			r4.xyz = asfloat(r0.yyy) * r4.xyz;
			r6.xyz = -(r7.xyz) + r6.xyz;
			r4.xyz = r4.xyz * float3(0.00390625, 0.00390625, 0.00390625) + -(asfloat(r3.xyz));
			r1.w = asint(dot(r4.xyz, i.normal.xyz));
			r2.w = asint(dot(r6.xyz, r6.xyz));
			r3.w = (0 < asfloat(r2.w)) ? -1 : 0;
			r1.w = asint(-(asfloat(r1.w)) / asfloat(r2.w));
			r4.xyz = r6.xyz * asfloat(r1.www) + i.normal.xyz;
			r4.xyz = (r3.www != 0) ? r4.xyz : i.normal.xyz;
			r0.zw = asint(asfloat(r0.zw) + float2(-0.5, -0.492109388));
			r0.zw = asint(asfloat(r0.zw) + asfloat(r0.zw));
			r1.w = asint(dot(asfloat(r0.zw), asfloat(r0.zw)));
			r2.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r1.w = asint(sqrt(asfloat(r1.w)));
			r1.w = r1.w & r2.w;
			r2.w = asint(-(asfloat(r1.w)) * 2 + 1);
			r6.z = max(asfloat(r2.w), -1);
			r2.w = (r6.z < 1) ? -1 : 0;
			r3.w = (-1 < r6.z) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = asint(-(r6.z) * r6.z + 1);
			r3.w = asint(sqrt(asfloat(r3.w)));
			r1.w = asint(asfloat(r3.w) / asfloat(r1.w));
			r1.w = r1.w & r2.w;
			r6.xy = asfloat(r0.zw) * asfloat(r1.ww);
			r5 = r5.xyz + float3(-128, -128, -128);
			r0.yzw = asint(asfloat(r0.yyy) * r5.xyz);
			r5 = -(r7.xyz) + r6.xyz;
			r0.yzw = asint(asfloat(r0.yzw) * float3(0.00390625, 0.00390625, 0.00390625) + -(asfloat(r3.xyz)));
			r0.y = asint(dot(asfloat(r0.yzw), i.normal.xyz));
			r0.z = asint(dot(r5.xyz, r5.xyz));
			r0.w = (0 < asfloat(r0.z)) ? -1 : 0;
			r0.y = asint(-(asfloat(r0.y)) / asfloat(r0.z));
			r3.xyz = asint(r5.xyz * asfloat(r0.yyy) + r4.xyz);
			r0.yzw = (r0.www != 0) ? r3.xyz : asint(r4.xyz);
			r1.w = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
			r1.w = asint(sqrt(asfloat(r1.w)));
			r2.xyz = asint(asfloat(r0.yzw) / asfloat(r1.www));
		}
	} else {
		r1.xyz = asint(i.position.xyz);
		r2.xyz = asint(i.normal.xyz);
	}
	r0.yzw = asint(asfloat(r1.yyy) * gWorld[1].xyz);
	r0.yzw = asint(asfloat(r1.xxx) * gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r1.zzz) * gWorld[2].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r0.yzw) + gWorld[3].xyz);
	o.texcoord3 = -(asfloat(r0.yzw)) + gViewInverse[3].xyz;
	r3.xyz = asint(asfloat(r2.yyy) * gWorld[1].xyz);
	r2.xyw = asint(asfloat(r2.xxx) * gWorld[0].xyz + asfloat(r3.xyz));
	r2.xyz = asint(asfloat(r2.zzz) * gWorld[2].xyz + asfloat(r2.xyw));
	r2.xyz = asint(asfloat(r2.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asint(asfloat(r1.www) * asfloat(r2.xyz));
	r3.xyz = asint(i.tangent.yyy * gWorld[1].xyz);
	r3.xyz = asint(i.tangent.xxx * gWorld[0].xyz + asfloat(r3.xyz));
	r3.xyz = asint(i.tangent.zzz * gWorld[2].xyz + asfloat(r3.xyz));
	r3.xyz = asint(asfloat(r3.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r3.xyz = asint(asfloat(r1.www) * asfloat(r3.xyz));
	r4.xyz = asfloat(r2.yzx) * asfloat(r3.zxy);
	r4.xyz = asfloat(r3.yzx) * asfloat(r2.zxy) + -(r4.xyz);
	o.texcoord5 = r4.xyz * i.tangent.www;
	r4.xyz = -(gWorld[3].xyz) + gViewInverse[3].xyz;
	r5.x = dot(gWorld[0].xyz, r4.xyz);
	r5.y = dot(gWorld[1].xyz, r4.xyz);
	r5.z = dot(gWorld[2].xyz, r4.xyz);
	r4.xyz = -(asfloat(r1.xyz)) + r5.xyz;
	r4.xyz = r4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r4.xyz, r4.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r4.xyz = asfloat(r1.www) * r4.xyz;
	r1.xyz = asint(r4.xyz * zShiftScale + asfloat(r1.xyz));
	r4 = asfloat(r1.y) * gWorldViewProj[1];
	r4 = asfloat(r1.x) * gWorldViewProj[0] + r4;
	r1 = asint(asfloat(r1.z) * gWorldViewProj[2] + r4);
	r1 = asint(asfloat(r1) + gWorldViewProj[3]);
	r2.w = asint(dot(float2(1, 1), globalDayNightEffects.zw));
	r2.w = asint(asfloat(r2.w) * globalScalars.z + -1);
	r2.w = asint(gAmbientOcclusionEffect.x * asfloat(r2.w) + 1);
	o.color.xy = asfloat(r2.ww) * gAmbientOcclusionEffect.yy;
	o.sv_position = asfloat(r1);
	o.color.z = 1;
	o.color.w = i.color.w;
	o.texcoord = i.texcoord.xy;
	o.texcoord7 = i.color.xy;
	o.texcoord1.w = asfloat(r1.w);
	o.texcoord1.xyz = asfloat(r2.xyz);
	o.texcoord6.xyz = asfloat(r0.yzw);
	o.texcoord6.w = 1;
	o.texcoord2 = gBloodUVBoundsPage[r0.x];
	o.texcoord4 = asfloat(r3.xyz);

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	int4 r2;
	int4 r3;
	float4 r4;
	float3 r5;
	float4 r6;
	float3 r7;
	float3 r8;
	r0.x = asint(i.color.z * 255);
	r0.x = asint(round(asfloat(r0.x)));
	r0.x = (int)asfloat(r0.x);
	if (Temporal_b13_o0_switchOn != 0) {
		r0.y = asint(dot(i.position.xyz, i.position.xyz));
		r0.y = asint(sqrt(asfloat(r0.y)));
		r1.xyz = asint(i.position.xyz / asfloat(r0.yyy));
		r0.z = asint(-(asfloat(r1.z)) + 1);
		r0.z = asint(asfloat(r0.z) * 0.5);
		r1.xy = asint(asfloat(r1.xy) + float2(0.00000999999975, 0.00000999999975));
		r0.w = asint(dot(asfloat(r1.xy), asfloat(r1.xy)));
		r0.w = asint(rsqrt(asfloat(r0.w)));
		r1.xy = asint(asfloat(r0.ww) * asfloat(r1.xy));
		r0.zw = asint(asfloat(r0.zz) * asfloat(r1.xy));
		r0.zw = asint(asfloat(r0.zw) * float2(0.5, 0.5) + float2(0.5, 0.5));
		r1.xy = asint(asfloat(r0.zw) * float2(126.732674, 126.732674));
		r1.zw = (asfloat(r1.xy) >= -(asfloat(r1.xy))) ? -1 : 0;
		r1.xy = asint(frac(abs(asfloat(r1.xy))));
		r1.xy = (r1.zw != 0) ? r1.xy : asint(-(asfloat(r1.xy)));
		r1.z = asint(TemporalResource_t1_DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r0.zw), 0).x);
		r0.zw = asint(-(asfloat(r1.xy)) * float2(0.00789062493, 0.00789062493) + asfloat(r0.zw));
		r2 = asint(asfloat(r0.zwzw) + float4(0.00789062493, 0, 0, 0.00789062493));
		r1.w = asint(TemporalResource_t1_DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.xy), 0).x);
		r2.x = asint(TemporalResource_t1_DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.zw), 0).x);
		r2.yz = asint(asfloat(r0.zw) + float2(0.00789062493, 0.00789062493));
		r2.y = asint(TemporalResource_t1_DamageSampler_tex.SampleLevel(DamageSampler, asfloat(r2.yz), 0).x);
		r2.z = asint(asfloat(r1.z) * 0.0000152587891);
		r3.z = asint(trunc(asfloat(r2.z)));
		r1.z = asint(-(asfloat(r3.z)) * 65536 + asfloat(r1.z));
		r2.z = asint(asfloat(r1.z) * 0.00390625);
		r3.y = asint(trunc(asfloat(r2.z)));
		r3.x = asint(-(asfloat(r3.y)) * 256 + asfloat(r1.z));
		r1.z = asint(asfloat(r1.w) * 0.0000152587891);
		r4.z = trunc(asfloat(r1.z));
		r1.z = asint(-(r4.z) * 65536 + asfloat(r1.w));
		r1.w = asint(asfloat(r1.z) * 0.00390625);
		r4.y = trunc(asfloat(r1.w));
		r4.x = -(r4.y) * 256 + asfloat(r1.z);
		r1.z = asint(asfloat(r2.x) * 0.0000152587891);
		r5.z = trunc(asfloat(r1.z));
		r1.z = asint(-(r5.z) * 65536 + asfloat(r2.x));
		r1.w = asint(asfloat(r1.z) * 0.00390625);
		r5.y = trunc(asfloat(r1.w));
		r5.x = -(r5.y) * 256 + asfloat(r1.z);
		r1.z = asint(asfloat(r2.y) * 0.0000152587891);
		r6.z = trunc(asfloat(r1.z));
		r1.z = asint(-(r6.z) * 65536 + asfloat(r2.y));
		r1.w = asint(asfloat(r1.z) * 0.00390625);
		r6.y = trunc(asfloat(r1.w));
		r6.x = -(r6.y) * 256 + asfloat(r1.z);
		r1.zw = asint(-(asfloat(r1.xy)) + float2(1, 1));
		r2.xyz = asint(asfloat(r1.zzz) * asfloat(r3.xyz));
		r7 = asfloat(r1.xxx) * r4.xyz;
		r7 = asfloat(r1.www) * r7.xyz;
		r2.xyz = asint(asfloat(r2.xyz) * asfloat(r1.www) + r7.xyz);
		r7 = asfloat(r1.zzz) * r5.xyz;
		r2.xyz = asint(r7.xyz * asfloat(r1.yyy) + asfloat(r2.xyz));
		r1.xzw = asint(asfloat(r1.xxx) * r6.xyz);
		r1.xyz = asint(asfloat(r1.xzw) * asfloat(r1.yyy) + asfloat(r2.xyz));
		r1.xyz = asint(asfloat(r1.xyz) + float3(-128, -128, -128));
		r1.xyz = asint(asfloat(r1.xyz) * float3(0.0078125, 0.0078125, 0.0078125));
		r0.y = asint(asfloat(r0.y) / Temporal_b7_o0_BoundRadius);
		r0.y = asint(min(asfloat(r0.y), 1));
		r1.xyz = asint(asfloat(r0.yyy) * asfloat(r1.xyz));
		r1.xyz = asint(asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + i.position.xyz);
		r2.xyz = (i.normal.xyz == float3(1, 1, 1)) ? -1 : 0;
		r1.w = r2.y & r2.x;
		r1.w = r2.z & r1.w;
		if (r1.w != 0) {
			r2.xyz = int3(0, 0, 1065353216);
		} else {
			r6 = asfloat(r0.zwzw) + float4(-0.5, -0.5, -0.492109388, -0.5);
			r6 = r6 + r6;
			r1.w = asint(dot(r6.xy, r6.xy));
			r2.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r1.w = asint(sqrt(asfloat(r1.w)));
			r1.w = r1.w & r2.w;
			r2.w = asint(-(asfloat(r1.w)) * 2 + 1);
			r7.z = max(asfloat(r2.w), -1);
			r2.w = (r7.z < 1) ? -1 : 0;
			r3.w = (-1 < r7.z) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = asint(-(r7.z) * r7.z + 1);
			r3.w = asint(sqrt(asfloat(r3.w)));
			r1.w = asint(asfloat(r3.w) / asfloat(r1.w));
			r1.w = r1.w & r2.w;
			r7.xy = asfloat(r1.ww) * r6.xy;
			r3.xyz = asint(asfloat(r3.xyz) + float3(-128, -128, -128));
			r3.xyz = asint(asfloat(r0.yyy) * asfloat(r3.xyz));
			r3.xyz = asint(asfloat(r3.xyz) * float3(0.00390625, 0.00390625, 0.00390625));
			r1.w = asint(dot(r6.zw, r6.zw));
			r2.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r1.w = asint(sqrt(asfloat(r1.w)));
			r1.w = r1.w & r2.w;
			r2.w = asint(-(asfloat(r1.w)) * 2 + 1);
			r8.z = max(asfloat(r2.w), -1);
			r2.w = (r8.z < 1) ? -1 : 0;
			r3.w = (-1 < r8.z) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = asint(-(r8.z) * r8.z + 1);
			r3.w = asint(sqrt(asfloat(r3.w)));
			r1.w = asint(asfloat(r3.w) / asfloat(r1.w));
			r1.w = r1.w & r2.w;
			r8.xy = asfloat(r1.ww) * r6.zw;
			r6.xyz = r8.xyz + float3(0.00000000999999994, 0.00000000999999994, 0.00000000999999994);
			r4.xyz = r4.xyz + float3(-128, -128, -128);
			r4.xyz = asfloat(r0.yyy) * r4.xyz;
			r6.xyz = -(r7.xyz) + r6.xyz;
			r4.xyz = r4.xyz * float3(0.00390625, 0.00390625, 0.00390625) + -(asfloat(r3.xyz));
			r1.w = asint(dot(r4.xyz, i.normal.xyz));
			r2.w = asint(dot(r6.xyz, r6.xyz));
			r3.w = (0 < asfloat(r2.w)) ? -1 : 0;
			r1.w = asint(-(asfloat(r1.w)) / asfloat(r2.w));
			r4.xyz = r6.xyz * asfloat(r1.www) + i.normal.xyz;
			r4.xyz = (r3.www != 0) ? r4.xyz : i.normal.xyz;
			r0.zw = asint(asfloat(r0.zw) + float2(-0.5, -0.492109388));
			r0.zw = asint(asfloat(r0.zw) + asfloat(r0.zw));
			r1.w = asint(dot(asfloat(r0.zw), asfloat(r0.zw)));
			r2.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r1.w = asint(sqrt(asfloat(r1.w)));
			r1.w = r1.w & r2.w;
			r2.w = asint(-(asfloat(r1.w)) * 2 + 1);
			r6.z = max(asfloat(r2.w), -1);
			r2.w = (r6.z < 1) ? -1 : 0;
			r3.w = (-1 < r6.z) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = (0 < asfloat(r1.w)) ? -1 : 0;
			r2.w = r2.w & r3.w;
			r3.w = asint(-(r6.z) * r6.z + 1);
			r3.w = asint(sqrt(asfloat(r3.w)));
			r1.w = asint(asfloat(r3.w) / asfloat(r1.w));
			r1.w = r1.w & r2.w;
			r6.xy = asfloat(r0.zw) * asfloat(r1.ww);
			r5 = r5.xyz + float3(-128, -128, -128);
			r0.yzw = asint(asfloat(r0.yyy) * r5.xyz);
			r5 = -(r7.xyz) + r6.xyz;
			r0.yzw = asint(asfloat(r0.yzw) * float3(0.00390625, 0.00390625, 0.00390625) + -(asfloat(r3.xyz)));
			r0.y = asint(dot(asfloat(r0.yzw), i.normal.xyz));
			r0.z = asint(dot(r5.xyz, r5.xyz));
			r0.w = (0 < asfloat(r0.z)) ? -1 : 0;
			r0.y = asint(-(asfloat(r0.y)) / asfloat(r0.z));
			r3.xyz = asint(r5.xyz * asfloat(r0.yyy) + r4.xyz);
			r0.yzw = (r0.www != 0) ? r3.xyz : asint(r4.xyz);
			r1.w = asint(dot(asfloat(r0.yzw), asfloat(r0.yzw)));
			r1.w = asint(sqrt(asfloat(r1.w)));
			r2.xyz = asint(asfloat(r0.yzw) / asfloat(r1.www));
		}
	} else {
		r1.xyz = asint(i.position.xyz);
		r2.xyz = asint(i.normal.xyz);
	}
	r0.yzw = asint(asfloat(r1.yyy) * Temporal_b0_o0_gWorld[1].xyz);
	r0.yzw = asint(asfloat(r1.xxx) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r1.zzz) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r0.yzw));
	r0.yzw = asint(asfloat(r0.yzw) + Temporal_b0_o0_gWorld[3].xyz);
	o.texcoord3 = -(asfloat(r0.yzw)) + Temporal_b0_o192_gViewInverse[3].xyz;
	r3.xyz = asint(asfloat(r2.yyy) * Temporal_b0_o0_gWorld[1].xyz);
	r2.xyw = asint(asfloat(r2.xxx) * Temporal_b0_o0_gWorld[0].xyz + asfloat(r3.xyz));
	r2.xyz = asint(asfloat(r2.zzz) * Temporal_b0_o0_gWorld[2].xyz + asfloat(r2.xyw));
	r2.xyz = asint(asfloat(r2.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asint(asfloat(r1.www) * asfloat(r2.xyz));
	r3.xyz = asint(i.tangent.yyy * Temporal_b0_o0_gWorld[1].xyz);
	r3.xyz = asint(i.tangent.xxx * Temporal_b0_o0_gWorld[0].xyz + asfloat(r3.xyz));
	r3.xyz = asint(i.tangent.zzz * Temporal_b0_o0_gWorld[2].xyz + asfloat(r3.xyz));
	r3.xyz = asint(asfloat(r3.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r3.xyz = asint(asfloat(r1.www) * asfloat(r3.xyz));
	r4.xyz = asfloat(r2.yzx) * asfloat(r3.zxy);
	r4.xyz = asfloat(r3.yzx) * asfloat(r2.zxy) + -(r4.xyz);
	o.texcoord5 = r4.xyz * i.tangent.www;
	r4.xyz = -(Temporal_b0_o0_gWorld[3].xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	r5.x = dot(Temporal_b0_o0_gWorld[0].xyz, r4.xyz);
	r5.y = dot(Temporal_b0_o0_gWorld[1].xyz, r4.xyz);
	r5.z = dot(Temporal_b0_o0_gWorld[2].xyz, r4.xyz);
	r4.xyz = -(asfloat(r1.xyz)) + r5.xyz;
	r4.xyz = r4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r4.xyz, r4.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r4.xyz = asfloat(r1.www) * r4.xyz;
	r1.xyz = asint(r4.xyz * Temporal_b4_o0_zShiftScale + asfloat(r1.xyz));
	r4 = asfloat(r1.y) * Temporal_b0_o128_gWorldViewProj[1];
	r4 = asfloat(r1.x) * Temporal_b0_o128_gWorldViewProj[0] + r4;
	r1 = asint(asfloat(r1.z) * Temporal_b0_o128_gWorldViewProj[2] + r4);
	r1 = asint(asfloat(r1) + Temporal_b0_o128_gWorldViewProj[3]);
	r2.w = asint(dot(float2(1, 1), Temporal_b5_o144_globalDayNightEffects.zw));
	r2.w = asint(asfloat(r2.w) * Temporal_b5_o0_globalScalars.z + -1);
	r2.w = asint(Temporal_b5_o288_gAmbientOcclusionEffect.x * asfloat(r2.w) + 1);
	o.color.xy = asfloat(r2.ww) * Temporal_b5_o288_gAmbientOcclusionEffect.yy;
	o.sv_position = asfloat(r1);
	o.color.z = 1;
	o.color.w = i.color.w;
	o.texcoord = i.texcoord.xy;
	o.texcoord7 = i.color.xy;
	o.texcoord1.w = asfloat(r1.w);
	o.texcoord1.xyz = asfloat(r2.xyz);
	o.texcoord6.xyz = asfloat(r0.yzw);
	o.texcoord6.w = 1;
	o.texcoord2 = Temporal_b9_o32_gBloodUVBoundsPage[r0.x];
	o.texcoord4 = asfloat(r3.xyz);

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
