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
	float HardAlphaBlend : packoffset(c0);
	float ArmourStrength : packoffset(c0.y);
	float bumpiness : packoffset(c0.z);
	float displacementScale : packoffset(c0.w);
	float specularFactor : packoffset(c1);
	float3 specMapIntMask : packoffset(c1.y);
	float4 specMapExpMask : packoffset(c2);
	float4 matMaterialColorScale : packoffset(c3);
};

cbuffer Details : register(b7)
{
	float4 detailSettings : packoffset(c0);
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState SpecSampler : register(s2);
SamplerState VolumeSampler : register(s3);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D SpecSampler_tex : register(t2);
Texture3D VolumeSampler_tex : register(t3);

struct PS_IN
{
	noperspective float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord4 : TEXCOORD4;
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
	float4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	r0.x = asint(i.sv_position.y + i.sv_position.x);
	r0.x = (uint)asfloat(r0.x);
	r0.x = r0.x & 1;
	r0.x = (r0.x == 0) ? -1 : 0;
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.y = asint(r1.w * i.texcoord2.w);
	r1.xyz = r1.xyz * matMaterialColorScale.xxx;
	r0.z = asint(asfloat(r0.y) * globalScalars.x + -0.501960814);
	r0.y = asint(asfloat(r0.y) * globalScalars.x);
	r0.z = asint(asfloat(r0.z) * 20.0787411 + -(asfloat(r0.y)));
	r0.z = asint(HardAlphaBlend * asfloat(r0.z) + asfloat(r0.y));
	r0.zw = (float2(0.899999976, 0.501960814) >= asfloat(r0.zz)) ? -1 : 0;
	r0.x = r0.z & r0.x;
	r0.x = r0.w | r0.x;
	if (r0.x != 0) discard;
	o.sv_target.w = asfloat(r0.y);
	r0.x = asint(i.texcoord2.w * detailSettings.x);
	r2.xy = i.texcoord.xy * detailSettings.zw;
	r3 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.z = asint(r3.z * 16);
	r0.z = asint(trunc(asfloat(r0.z)));
	r0.z = asint(asfloat(r0.z) + 0.5);
	r2.z = asfloat(r0.z) * 0.0625;
	r2.xyz = VolumeSampler_tex.Sample(VolumeSampler, r2.xyz).xyz;
	r2.xyz = r2.yzx * float3(2, 2, 2) + float3(-1, -1, -1);
	r0.x = asint(r2.z * asfloat(r0.x) + 1);
	o.sv_target.xyz = asfloat(r0.xxx) * r1.xyz;
	r1.xyz = r2.yyy * i.texcoord5.xyz;
	r1.xyz = i.texcoord4.xyz * r2.xxx + r1.xyz;
	r1.xyz = r1.xyz * detailSettings.yyy;
	r2.xyz = BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw;
	r0.z = asint(-(r2.z) + 1);
	r0.z = (asfloat(r0.z) < r2.x) ? -1 : 0;
	r0.z = r0.z & 1065353216;
	r2.xw = -(r2.zy) + r2.xy;
	r0.zw = asint(asfloat(r0.zz) * r2.xw + r2.zy);
	r0.zw = asint(asfloat(r0.zw) * float2(2, 2) + float2(-1, -1));
	r0.zw = asint(asfloat(r0.zw) * bumpiness);
	r1.w = dot(asfloat(r0.zw), asfloat(r0.zw));
	r1.w = -(r1.w) + 1;
	r1.w = max(r1.w, 0);
	r1.w = sqrt(r1.w);
	r2.xyz = asfloat(r0.zzz) * i.texcoord4.xyz;
	r2.xyz = r1.www * i.texcoord1.xyz + r2.xyz;
	r2.xyz = asfloat(r0.www) * i.texcoord5.xyz + r2.xyz;
	r2.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = asint(dot(r2.xyz, r2.xyz));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r4 = asfloat(r0.zzz) * r2.xyz;
	r2.xyz = r2.xyz * asfloat(r0.zzz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.xyz = r1.xyz * i.texcoord2.www + r4.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = asint(dot(r1.xyz, r1.xyz));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r1.xyz = asfloat(r0.zzz) * r1.xyz;
	o.sv_target1.xyz = r1.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = asfloat(r0.y);
	o.sv_target2.w = asfloat(r0.y);
	r0.y = asint(dot(r2.xyz, r2.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r0.yzw = asint(asfloat(r0.yyy) * r2.xyz);
	r1.xyz = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = rsqrt(r1.w);
	r1.xyz = r1.www * r1.xyz;
	r0.y = asint(dot(r1.xyz, asfloat(r0.yzw)));
	r0.y = asint(asfloat(r0.y) * -1.5);
	r0.y = asint(max(asfloat(r0.y), 0));
	r0.y = asint(-(asfloat(r0.y)) + 1);
	r0.y = asint(max(asfloat(r0.y), 0));
	r0.y = asint(asfloat(r0.y) * i.texcoord2.y);
	r0.z = asint(dot(r3.xyz, specMapIntMask));
	r0.w = asint(dot(r3, specMapExpMask));
	r0.w = asint(asfloat(r0.w) * specularFactor);
	r0.w = asint(max(asfloat(r0.w), 1));
	r1.y = asfloat(r0.w) * matMaterialColorScale.w;
	r0.z = asint(asfloat(r0.z) * matMaterialColorScale.w);
	r0.w = asint(saturate(asfloat(r0.z) * 5));
	r0.y = asint(asfloat(r0.w) * asfloat(r0.y));
	r0.w = asint(saturate(-(r1.y) * 0.00999999978 + 1));
	r0.y = asint(asfloat(r0.w) * asfloat(r0.y) + asfloat(r0.z));
	o.sv_target2.x = saturate(asfloat(r0.x) * asfloat(r0.y));
	r0.xyz = asint(i.texcoord4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r2.xyz = -(i.texcoord7.xyz) + gViewInverse[3].xyz;
	r2.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = asint(dot(r2.xyz, r2.xyz));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r2.xyz = asfloat(r0.www) * r2.xyz;
	r0.x = asint(dot(r2.xyz, asfloat(r0.xyz)));
	r3.xyz = i.texcoord5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = asint(dot(r3.xyz, r3.xyz));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r3.xyz = asfloat(r0.zzz) * r3.xyz;
	r0.z = asint(dot(r2.xyz, r3.xyz));
	r0.xy = asint(asfloat(r0.xz) * asfloat(r0.xz));
	r1.x = 1;
	r0.x = asint(dot(asfloat(r0.xy), r1.xy));
	r0.x = asint(max(asfloat(r0.x), 1));
	r0.x = asint(asfloat(r0.x) * 0.00510204071);
	r0.x = asint(min(asfloat(r0.x), 1));
	r0.x = asint(sqrt(asfloat(r0.x)));
	o.sv_target2.y = sqrt(asfloat(r0.x));
	r0.x = asint(saturate(gAmbientOcclusionEffect.z));
	r0.x = asint(saturate(asfloat(r0.x) + i.texcoord2.x));
	o.sv_target2.z = asfloat(r0.x) * gAmbientOcclusionEffect.w;
	o.sv_target3 = float4(0, 0, 0, 0);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
