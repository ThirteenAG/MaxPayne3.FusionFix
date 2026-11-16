cbuffer TemporalPixel : register(b13) { float4 TemporalSizeJitter; };
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
};

cbuffer Details : register(b7)
{
	float4 detailSettings : packoffset(c0);
};

cbuffer ClothSweat : register(b9)
{
	float4 vSweatParams : packoffset(c0);
	float4 ClothDarken : packoffset(c1);
	float4 ClothSweatSpec : packoffset(c2);
	float4 ClothDarkenColor : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState SpecSampler : register(s2);
SamplerState VolumeSampler : register(s3);
SamplerState ClothSweatMapSampler : register(s4);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpTex : register(t1);
Texture2D SpecSampler_tex : register(t2);
Texture3D VolumeSampler_tex : register(t3);
Texture2D ClothSweatMapSampler_tex : register(t4);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord7 : TEXCOORD7;
	float3 temporalPrevious : TEXCOORD15;
};

struct PS_OUT
{
	float4 sv_target : SV_Target;
	float4 sv_target1 : SV_Target1;
	float4 sv_target2 : SV_Target2;
	float4 sv_target3 : SV_Target3;
	float2 temporalVelocity : SV_Target4;
};

PS_OUT main(PS_IN i)
{
	PS_OUT o;

	int4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	r0.x = asint(-(i.texcoord4.w) + vSweatParams.z);
	r0.x = asint(saturate(asfloat(r0.x) / vSweatParams.w));
	r0.x = asint(asfloat(r0.x) * vSweatParams.y);
	r0.y = (vSweatParams.z < i.texcoord4.w) ? -1 : 0;
	r0.x = (r0.y != 0) ? 0 : r0.x;
	r0.yz = asint(ClothSweatMapSampler_tex.Sample(ClothSweatMapSampler, i.texcoord.xy).xy);
	r0.z = asint(-(asfloat(r0.z)) + vSweatParams.x);
	r0.x = asint(saturate(max(asfloat(r0.x), asfloat(r0.z))));
	r0.z = asint(-(asfloat(r0.x)) + ClothDarken.w);
	r0.z = asint(asfloat(r0.z) / ClothDarken.w);
	r1.xyz = asint(-(ClothDarken.xyz) + float3(1, 1, 1));
	r1.xyz = asint(asfloat(r0.zzz) * asfloat(r1.xyz) + ClothDarken.xyz);
	r0.z = (ClothDarken.w < asfloat(r0.x)) ? -1 : 0;
	r1.xyz = (r0.zzz != 0) ? asint(ClothDarken.xyz) : r1.xyz;
	r2 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r2.xyz = r2.xyz + -(ClothDarkenColor.xyz);
	r0.z = asint(r2.w * i.texcoord2.w);
	r0.z = asint(asfloat(r0.z) * globalScalars.x);
	r1.xyz = asint(asfloat(r1.xyz) * r2.xyz + ClothDarkenColor.xyz);
	r1.xyz = asint(asfloat(r1.xyz) * matMaterialColorScale.xxx);
	r0.w = asint(i.texcoord2.w * detailSettings.x);
	r2.xy = i.texcoord.xy * detailSettings.zw;
	r3 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r1.w = asint(r3.z * 16);
	r1.w = asint(trunc(asfloat(r1.w)));
	r1.w = asint(asfloat(r1.w) + 0.5);
	r2.z = asfloat(r1.w) * 0.0625;
	r2.xyz = VolumeSampler_tex.Sample(VolumeSampler, r2.xyz).xyz;
	r2.xyz = r2.yzx * float3(2, 2, 2) + float3(-1, -1, -1);
	r0.w = asint(r2.z * asfloat(r0.w) + 1);
	o.sv_target.xyz = asfloat(r0.www) * asfloat(r1.xyz);
	o.sv_target.w = asfloat(r0.z);
	r1.xyz = asint(r2.yyy * i.texcoord5.xyz);
	r1.xyz = asint(i.texcoord4.xyz * r2.xxx + asfloat(r1.xyz));
	r1.xyz = asint(asfloat(r1.xyz) * detailSettings.yyy);
	r2.xyz = BumpTex.Sample(BumpSampler, i.texcoord.xy).xyw;
	r1.w = asint(-(r2.z) + 1);
	r1.w = (asfloat(r1.w) < r2.x) ? -1 : 0;
	r1.w = r1.w & 1065353216;
	r2.xw = -(r2.zy) + r2.xy;
	r2.xy = asfloat(r1.ww) * r2.xw + r2.zy;
	r2.xy = r2.xy * float2(2, 2) + float2(-1, -1);
	r2.xy = r2.xy * bumpiness;
	r1.w = asint(dot(r2.xy, r2.xy));
	r1.w = asint(-(asfloat(r1.w)) + 1);
	r1.w = asint(max(asfloat(r1.w), 0));
	r1.w = asint(sqrt(asfloat(r1.w)));
	r2.xzw = r2.xxx * i.texcoord4.xyz;
	r2.xzw = asfloat(r1.www) * i.texcoord1.xyz + r2.xzw;
	r2.xyz = r2.yyy * i.texcoord5.xyz + r2.xzw;
	r2.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r2.xyz, r2.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r4 = asfloat(r1.www) * r2.xyz;
	r2.xyz = r2.xyz * asfloat(r1.www) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.xyz = asint(asfloat(r1.xyz) * i.texcoord2.www + r4.xyz);
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	o.sv_target1.xyz = asfloat(r1.xyz) * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = asfloat(r0.z);
	r1.x = asint(dot(r2.xyz, r2.xyz));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r1.xyz = asint(asfloat(r1.xxx) * r2.xyz);
	r2.xyz = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r2.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = asint(dot(r2.xyz, r2.xyz));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r2.xyz = asfloat(r1.www) * r2.xyz;
	r1.x = asint(dot(r2.xyz, asfloat(r1.xyz)));
	r1.x = asint(asfloat(r1.x) * -1.5);
	r1.x = asint(max(asfloat(r1.x), 0));
	r1.x = asint(-(asfloat(r1.x)) + 1);
	r1.x = asint(max(asfloat(r1.x), 0));
	r1.x = asint(asfloat(r1.x) * i.texcoord2.y);
	r1.y = asint(dot(r3.xyz, specMapIntMask.xyz));
	r1.z = asint(dot(r3, specMapExpMask));
	r1.z = asint(asfloat(r1.z) * specularFactor);
	r1.z = asint(max(asfloat(r1.z), 1));
	r0.y = asint(asfloat(r0.y) * ClothSweatSpec.x + -(asfloat(r1.y)));
	r0.y = asint(asfloat(r0.x) * asfloat(r0.y) + asfloat(r1.y));
	r0.y = asint(asfloat(r0.y) * matMaterialColorScale.w);
	r1.y = asint(saturate(asfloat(r0.y) * 5));
	r1.x = asint(asfloat(r1.y) * asfloat(r1.x));
	r1.y = asint(-(asfloat(r1.z)) + ClothSweatSpec.y);
	r0.x = asint(asfloat(r0.x) * asfloat(r1.y) + asfloat(r1.z));
	r0.x = asint(asfloat(r0.x) * matMaterialColorScale.w);
	r1.y = asint(saturate(-(asfloat(r0.x)) * 0.00999999978 + 1));
	r0.x = asint(asfloat(r0.x) * 0.00510204071);
	r0.x = asint(saturate(asfloat(r0.x)));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	r0.x = asint(asfloat(r1.y) * asfloat(r1.x) + asfloat(r0.y));
	o.sv_target2.x = saturate(asfloat(r0.w) * asfloat(r0.x));
	o.sv_target2.w = asfloat(r0.z);
	o.sv_target3.w = asfloat(r0.z);
	r0.x = asint(saturate(gAmbientOcclusionEffect.z));
	r0.x = asint(saturate(asfloat(r0.x) + i.texcoord2.x));
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	o.sv_target3.xyz = float3(0, 0, 0);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
