cbuffer rage_matrices : register(b0)
{
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

cbuffer ShadowParam : register(b8)
{
	float4 gShadowParam18192021 : packoffset(c0);
	float4 gShadowParam14151617 : packoffset(c1);
	float4 gShadowParam0123 : packoffset(c2);
	float4 gShadowParam4567 : packoffset(c3);
	float4 gShadowParam891113 : packoffset(c4);
	float4 gCascadeZScales : packoffset(c5);
	float4 gCascadeZOffsets : packoffset(c6);
	float4 gCascadeXMinThresholds : packoffset(c7);
	float4 gCascadeXMaxThresholds : packoffset(c8);
	float4 gCascadeYMinThresholds : packoffset(c9);
	float4 gCascadeYMaxThresholds : packoffset(c10);
	row_major float4x4 gShadowMatrix : packoffset(c11);
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
	float4 color1 : COLOR1;
	float4 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float3 texcoord : TEXCOORD;
};

VS_OUT main(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	int4 r1;
	int4 r2;
	float3 r3;
	r0.x = asint(i.color1.x * globalUmScalars.x);
	r0.xy = asint(asfloat(r0.xx) * umGlobalParams.xx);
	r0.w = asint(-(i.color1.z) + 1);
	r1.x = asint(asfloat(r0.w) * globalUmScalars.y);
	r0.z = asint(asfloat(r1.x) * umGlobalParams.y);
	r1.x = asint(i.color1.y * 6.28318548);
	r1.yzw = asint(globalUmScalars.zzw * umGlobalParams.zzw);
	r1.xyz = asint(globalScalars2.yyy * asfloat(r1.yzw) + asfloat(r1.xxx));
	r1.xyz = asint(sin(asfloat(r1.xyz)));
	r0.xyz = asint(asfloat(r1.xyz) * asfloat(r0.xyz) + i.position.xyz);
	r1.x = asint(asfloat(r0.z) * deSatContrastGamma.w);
	r0.w = asint(asfloat(r0.w) * WindGlobalParams.x);
	r0.xy = asint(asfloat(r1.xx) * asfloat(r0.ww) + asfloat(r0.xy));
	r1.xyz = asint(-(gWorld[3].xyz) + g_vPlayerPosition.xyz);
	r2.x = asint(dot(gWorld[0].xyz, asfloat(r1.xyz)));
	r2.y = asint(dot(gWorld[1].xyz, asfloat(r1.xyz)));
	r2.z = asint(dot(gWorld[2].xyz, asfloat(r1.xyz)));
	r1.xyz = asint(asfloat(r0.xyz) + -(asfloat(r2.xyz)));
	r0.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r0.w = asint(-(asfloat(r0.w)) + g_vCollisionParams.x);
	r0.w = asint(max(asfloat(r0.w), 0));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.z = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.z = asint(rsqrt(asfloat(r1.z)));
	r1.xy = asint(asfloat(r1.zz) * asfloat(r1.xy));
	r1.xy = asint(asfloat(r1.xy) * i.color1.xx);
	r1.xy = asint(asfloat(r0.ww) * asfloat(r1.xy));
	r1.xy = asint(asfloat(r1.xy) * g_fCollisionSqScale + asfloat(r0.xy));
	r0.w = (0 < g_fEnableSpringForces) ? -1 : 0;
	if (r0.w != 0) {
		r0.x = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
		r0.x = asint(asfloat(r0.x) * 10);
		r0.x = asint(globalScalars2.y * g_fGrassSpringRigidity + asfloat(r0.x));
		r0.x = asint(sin(asfloat(r0.x)));
		r0.x = asint(asfloat(r0.x) * g_fGrassSpringScale);
		r1.z = r0.z;
		r0.yw = int2(0, 0);
		r1.w = 0;
		while (true) {
			r2.x = (r1.w >= 5) ? -1 : 0;
			if (r2.x != 0) break;
			r2.xyz = asint(-(gWorld[3].xyz) + g_vCollisionSpheres[r1.w].xyz);
			r3.x = dot(gWorld[0].xyz, asfloat(r2.xyz));
			r3.y = dot(gWorld[1].xyz, asfloat(r2.xyz));
			r3.z = dot(gWorld[2].xyz, asfloat(r2.xyz));
			r2.xyz = asint(asfloat(r1.xyz) + -(r3.xyz));
			r2.w = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
			r2.w = asint(sqrt(asfloat(r2.w)));
			r2.w = asint(-(asfloat(r2.w)) + g_vCollisionSpheres[r1.w].x);
			r2.w = asint(max(asfloat(r2.w), 0));
			r2.w = asint(asfloat(r0.x) * asfloat(r2.w));
			r2.xyz = asint(asfloat(r2.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
			r2.z = asint(dot(asfloat(r2.xyz), asfloat(r2.xyz)));
			r2.z = asint(rsqrt(asfloat(r2.z)));
			r2.xy = asint(asfloat(r2.zz) * asfloat(r2.xy));
			r2.xy = asint(asfloat(r2.xy) * i.color1.xx);
			r2.xy = asint(asfloat(r2.ww) * asfloat(r2.xy));
			r0.yw = asint(asfloat(r2.xy) * g_fCollisionSqScale + asfloat(r0.yw));
			r1.w = r1.w + 1;
		}
		r1.xy = asint(asfloat(r0.yw) + asfloat(r1.xy));
	}
	r0.xyw = asint(asfloat(r1.yyy) * gWorld[1].xyz);
	r0.xyw = asint(asfloat(r1.xxx) * gWorld[0].xyz + asfloat(r0.xyw));
	r0.xyz = asint(asfloat(r0.zzz) * gWorld[2].xyz + asfloat(r0.xyw));
	r0.xyz = asint(asfloat(r0.xyz) + gWorld[3].xyz);
	r1.xyz = asint(asfloat(r0.yyy) * gShadowMatrix[1].xyz);
	r0.xyw = asint(asfloat(r0.xxx) * gShadowMatrix[0].xyz + asfloat(r1.xyz));
	r0.xyz = asint(asfloat(r0.zzz) * gShadowMatrix[2].xyz + asfloat(r0.xyw));
	r0.xyz = asint(asfloat(r0.xyz) + gShadowMatrix[3].xyz);
	o.sv_position.z = max(asfloat(r0.z), 0);
	o.sv_position.xy = asfloat(r0.xy);
	o.sv_position.w = 1;
	o.texcoord.x = 1;
	o.texcoord.yz = i.texcoord.xy;

	return o;
}
