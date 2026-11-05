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
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord3 : TEXCOORD3;
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

	float4 r0;
	float4 r1;
	int4 r2;
	float4 r3;
	r0 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.xyz = r0.xyz * i.texcoord3.xxx;
	r0.w = r0.w * i.texcoord2.w;
	r0.w = saturate(r0.w * 1.70000005);
	r0.w = r0.w * globalScalars.x;
	r0.xyz = r0.xyz * matMaterialColorScale.xxx;
	r1.x = i.texcoord2.w * detailSettings.x;
	r2.xy = asint(i.texcoord.xy * detailSettings.zw);
	r3 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r1.y = r3.z * 16;
	r1.y = trunc(r1.y);
	r1.y = r1.y + 0.5;
	r2.z = asint(r1.y * 0.0625);
	r1.yzw = VolumeSampler_tex.Sample(VolumeSampler, asfloat(r2.xyz)).xyz;
	r1.yzw = r1.zwy * float3(2, 2, 2) + float3(-1, -1, -1);
	r1.x = r1.w * r1.x + 1;
	o.sv_target.xyz = r0.xyz * r1.xxx;
	o.sv_target.w = r0.w;
	r0.xyz = r1.zzz * i.texcoord5.xyz;
	r0.xyz = i.texcoord4.xyz * r1.yyy + r0.xyz;
	r0.xyz = r0.xyz * detailSettings.yyy;
	r1.yzw = BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw;
	r2.x = asint(-(r1.w) + 1);
	r2.x = (asfloat(r2.x) < r1.y) ? -1 : 0;
	r2.x = r2.x & 1065353216;
	r2.yz = asint(-(r1.wz) + r1.yz);
	r1.yz = asfloat(r2.xx) * asfloat(r2.yz) + r1.wz;
	r1.yz = r1.yz * float2(2, 2) + float2(-1, -1);
	r1.yz = r1.yz * bumpiness;
	r1.w = dot(r1.yz, r1.yz);
	r1.w = -(r1.w) + 1;
	r1.w = max(r1.w, 0);
	r1.w = sqrt(r1.w);
	r2.xyz = asint(r1.yyy * i.texcoord4.xyz);
	r2.xyz = asint(r1.www * i.texcoord1.xyz + asfloat(r2.xyz));
	r1.yzw = r1.zzz * i.texcoord5.xyz + asfloat(r2.xyz);
	r1.yzw = r1.yzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.x = asint(dot(r1.yzw, r1.yzw));
	r2.x = asint(rsqrt(asfloat(r2.x)));
	r2.yzw = asint(r1.yzw * asfloat(r2.xxx));
	r1.yzw = r1.yzw * asfloat(r2.xxx) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.xyz = r0.xyz * i.texcoord2.www + asfloat(r2.yzw);
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.x = asint(dot(r0.xyz, r0.xyz));
	r2.x = asint(rsqrt(asfloat(r2.x)));
	r0.xyz = r0.xyz * asfloat(r2.xxx);
	o.sv_target1.xyz = r0.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = r0.w;
	r0.x = dot(r1.yzw, r1.yzw);
	r0.x = rsqrt(r0.x);
	r0.xyz = r0.xxx * r1.yzw;
	r1.yzw = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r1.yzw = r1.yzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r2.x = asint(dot(r1.yzw, r1.yzw));
	r2.x = asint(rsqrt(asfloat(r2.x)));
	r1.yzw = r1.yzw * asfloat(r2.xxx);
	r0.x = dot(r1.yzw, r0.xyz);
	r0.x = r0.x * -1.5;
	r0.x = max(r0.x, 0);
	r0.x = -(r0.x) + 1;
	r0.x = max(r0.x, 0);
	r0.x = r0.x * i.texcoord2.y;
	r0.y = dot(r3.xyz, specMapIntMask.xyz);
	r0.z = dot(r3, specMapExpMask);
	r0.z = r0.z * specularFactor;
	r0.z = max(r0.z, 1);
	r2.y = asint(r0.z * matMaterialColorScale.w);
	r0.y = r0.y * matMaterialColorScale.w;
	r0.z = saturate(r0.y * 5);
	r0.x = r0.z * r0.x;
	r0.z = saturate(-(asfloat(r2.y)) * 0.00999999978 + 1);
	r0.x = r0.z * r0.x + r0.y;
	o.sv_target2.x = saturate(r1.x * r0.x);
	r0.xyz = i.texcoord4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = dot(r0.xyz, r0.xyz);
	r1.x = rsqrt(r1.x);
	r0.xyz = r0.xyz * r1.xxx;
	r1.xyz = -(i.texcoord7.xyz) + gViewInverse[3].xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = rsqrt(r1.w);
	r1.xyz = r1.www * r1.xyz;
	r0.x = dot(r1.xyz, r0.xyz);
	r3.xyz = i.texcoord5.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = dot(r3.xyz, r3.xyz);
	r0.z = rsqrt(r0.z);
	r3.xyz = r0.zzz * r3.xyz;
	r0.z = dot(r1.xyz, r3.xyz);
	r0.xy = r0.xz * r0.xz;
	r2.x = 1065353216;
	r0.x = dot(r0.xy, asfloat(r2.xy));
	r0.x = max(r0.x, 1);
	r0.x = r0.x * 0.00510204071;
	r0.x = min(r0.x, 1);
	r0.x = sqrt(r0.x);
	o.sv_target2.y = sqrt(r0.x);
	o.sv_target2.w = r0.w;
	o.sv_target3.w = r0.w;
	r0.x = saturate(gAmbientOcclusionEffect.z);
	r0.x = saturate(r0.x + i.texcoord2.x);
	o.sv_target2.z = r0.x * gAmbientOcclusionEffect.w;
	o.sv_target3.xyz = float3(0, 0, 0);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
