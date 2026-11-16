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
	float reflectivePower : packoffset(c0.y);
	float3 specMapReflectMask : packoffset(c1);
	float fresnelRolloff : packoffset(c1.w);
	float bumpiness : packoffset(c2);
	float displacementScale : packoffset(c2.y);
	float specularFactor : packoffset(c2.z);
	float3 specMapIntMask : packoffset(c3);
	float4 specMapExpMask : packoffset(c4);
	float4 matMaterialColorScale : packoffset(c5);
};

cbuffer Details : register(b7)
{
	float4 detailSettings : packoffset(c0);
};

cbuffer Wrinkles : register(b9)
{
	float4 wrinkleMaskStrengths0 : packoffset(c0);
	float4 wrinkleMaskStrengths1 : packoffset(c1);
	float4 wrinkleMaskStrengths2 : packoffset(c2);
	float4 wrinkleMaskStrengths3 : packoffset(c3);
};

SamplerState DiffuseSampler : register(s0);
SamplerState EnvironmentSampler : register(s1);
SamplerState BumpSampler : register(s5);
SamplerState SpecSampler : register(s6);
SamplerState VolumeSampler : register(s7);
SamplerState WrinkleMaskSampler_0 : register(s8);
SamplerState WrinkleMaskSampler_1 : register(s9);
SamplerState WrinkleSampler_A : register(s10);
SamplerState WrinkleSampler_B : register(s11);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D EnvironmentSampler_tex : register(t1);
Texture2D BumpTex : register(t5);
Texture2D SpecSampler_tex : register(t6);
Texture3D VolumeSampler_tex : register(t7);
Texture2D WrinkleMaskSampler_0_tex : register(t8);
Texture2D WrinkleMaskSampler_1_tex : register(t9);
Texture2D WrinkleSampler_A_tex : register(t10);
Texture2D WrinkleSampler_B_tex : register(t11);

struct PS_IN
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
	int4 r1;
	float4 r2;
	int4 r3;
	float4 r4;
	float3 r5;
	float4 r6;
	r0.x = i.texcoord2.w * detailSettings.x;
	r1.xy = asint(i.texcoord.xy * detailSettings.zw);
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.y = r2.z * 16;
	r0.y = trunc(r0.y);
	r0.y = r0.y + 0.5;
	r1.z = asint(r0.y * 0.0625);
	r0.yzw = VolumeSampler_tex.Sample(VolumeSampler, asfloat(r1.xyz)).xyz;
	r0.yzw = r0.zwy * float3(2, 2, 2) + float3(-1, -1, -1);
	r0.x = r0.w * r0.x + 1;
	r1 = asint(DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy));
	r1.xyz = asint(asfloat(r1.xyz) * matMaterialColorScale.xxx);
	r0.w = asfloat(r1.w) * i.texcoord2.w;
	r0.w = r0.w * globalScalars.x;
	o.sv_target.xyz = r0.xxx * asfloat(r1.xyz);
	o.sv_target.w = r0.w;
	r1.xyz = asint(WrinkleSampler_B_tex.Sample(WrinkleSampler_B, i.texcoord.xy).xyw);
	r1.w = asint(-(asfloat(r1.z)) + 1);
	r1.w = (asfloat(r1.w) < asfloat(r1.x)) ? -1 : 0;
	r1.w = r1.w & 1065353216;
	r3.xy = asint(-(asfloat(r1.zy)) + asfloat(r1.xy));
	r1.xy = asint(asfloat(r1.ww) * asfloat(r3.xy) + asfloat(r1.zy));
	r3.xyz = asint(WrinkleSampler_A_tex.Sample(WrinkleSampler_A, i.texcoord.xy).xyw);
	r1.z = asint(-(asfloat(r3.z)) + 1);
	r1.z = (asfloat(r1.z) < asfloat(r3.x)) ? -1 : 0;
	r1.z = r1.z & 1065353216;
	r3.xw = asint(-(asfloat(r3.zy)) + asfloat(r3.xy));
	r1.zw = asint(asfloat(r1.zz) * asfloat(r3.xw) + asfloat(r3.zy));
	r1 = asint(asfloat(r1) + float4(-0.5, -0.5, -0.5, -0.5));
	r3.xyz = asint(BumpTex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r3.w = asint(-(asfloat(r3.z)) + 1);
	r3.w = (asfloat(r3.w) < asfloat(r3.x)) ? -1 : 0;
	r3.w = r3.w & 1065353216;
	r4.xy = -(asfloat(r3.zy)) + asfloat(r3.xy);
	r3.xy = asint(asfloat(r3.ww) * r4.xy + asfloat(r3.zy));
	r3.zw = asint(asfloat(r3.xy) + float2(-0.5, -0.5));
	r3.xy = asint(asfloat(r3.xy) * float2(2, 2) + float2(-1, -1));
	r3 = asint(asfloat(r3) * bumpiness);
	r3.zw = asint(asfloat(r3.zw) + asfloat(r3.zw));
	r1.zw = asint(asfloat(r1.zw) * float2(2, 2) + -(asfloat(r3.zw)));
	r4 = WrinkleMaskSampler_0_tex.Sample(WrinkleMaskSampler_0, i.texcoord.xy);
	r5.x = dot(wrinkleMaskStrengths0, r4);
	r4.x = dot(wrinkleMaskStrengths2, r4);
	r6 = WrinkleMaskSampler_1_tex.Sample(WrinkleMaskSampler_1, i.texcoord.xy);
	r4.y = dot(wrinkleMaskStrengths1, r6);
	r4.z = dot(wrinkleMaskStrengths3, r6);
	r4.x = r4.z + r4.x;
	r4.y = r4.y + r5.x;
	r1.zw = asint(r4.yy * asfloat(r1.zw) + asfloat(r3.zw));
	r1.xy = asint(asfloat(r1.xy) * float2(2, 2) + -(asfloat(r1.zw)));
	r1.xy = asint(r4.xx * asfloat(r1.xy) + asfloat(r1.zw));
	r1.w = asint(dot(asfloat(r1.xy), asfloat(r1.xy)));
	r1.w = asint(-(asfloat(r1.w)) + 1);
	r1.w = asint(max(asfloat(r1.w), 0));
	r1.z = asint(sqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r4.xyz = asfloat(r1.xxx) * i.texcoord4.xyz;
	r1.xzw = asint(i.texcoord1.xyz * asfloat(r1.zzz) + r4.xyz);
	r1.xyz = asint(i.texcoord5.xyz * asfloat(r1.yyy) + asfloat(r1.xzw));
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r4.xyz = asfloat(r1.www) * asfloat(r1.xyz);
	r1.xyz = asint(asfloat(r1.xyz) * asfloat(r1.www) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r5 = r0.zzz * i.texcoord5.xyz;
	r5 = i.texcoord4.xyz * r0.yyy + r5.xyz;
	r5 = r5.xyz * detailSettings.yyy;
	r4.xyz = r5.xyz * i.texcoord2.www + r4.xyz;
	r4.xyz = r4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.y = dot(r4.xyz, r4.xyz);
	r0.y = rsqrt(r0.y);
	r4.xyz = r0.yyy * r4.xyz;
	o.sv_target1.xyz = r4.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	o.sv_target1.w = r0.w;
	r0.y = dot(asfloat(r1.xyz), asfloat(r1.xyz));
	r0.y = rsqrt(r0.y);
	r1.xyz = asint(r0.yyy * asfloat(r1.xyz));
	r4.xyz = i.texcoord7.xyz + -(gViewInverse[3].xyz);
	r4.xyz = r4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.y = dot(r4.xyz, r4.xyz);
	r0.y = rsqrt(r0.y);
	r4.xyz = r0.yyy * r4.xyz;
	r0.y = dot(r4.xyz, asfloat(r1.xyz));
	r0.y = r0.y * -1.5;
	r0.y = max(r0.y, 0);
	r0.y = -(r0.y) + 1;
	r0.y = max(r0.y, 0);
	r0.y = r0.y * i.texcoord2.y;
	r0.z = saturate(dot(r2.xyz, specMapIntMask.xyz));
	r0.z = r0.z * matMaterialColorScale.w;
	r1.x = asint(saturate(r0.z * 5));
	r0.y = r0.y * asfloat(r1.x);
	r1.x = asint(dot(r2, specMapExpMask));
	r1.y = asint(dot(r2.xyz, specMapReflectMask.xyz));
	r1.x = asint(asfloat(r1.x) * specularFactor);
	r1.x = asint(max(asfloat(r1.x), 1));
	r1.x = asint(asfloat(r1.x) * matMaterialColorScale.w);
	r1.z = asint(saturate(-(asfloat(r1.x)) * 0.00999999978 + 1));
	r1.x = asint(asfloat(r1.x) * 0.00510204071);
	r1.x = asint(saturate(asfloat(r1.x)));
	r1.x = asint(sqrt(asfloat(r1.x)));
	o.sv_target2.y = sqrt(asfloat(r1.x));
	r0.y = asfloat(r1.z) * r0.y + r0.z;
	o.sv_target2.x = saturate(r0.x * r0.y);
	o.sv_target2.w = r0.w;
	o.sv_target3.w = r0.w;
	r0.x = saturate(gAmbientOcclusionEffect.z);
	r0.x = saturate(r0.x + i.texcoord2.x);
	o.sv_target2.z = r0.x * gAmbientOcclusionEffect.w;
	r0.x = dot(asfloat(r3.xy), asfloat(r3.xy));
	r0.x = -(r0.x) + 1;
	r0.x = max(r0.x, 0);
	r0.x = sqrt(r0.x);
	r0.yzw = asfloat(r3.xxx) * i.texcoord4.xyz;
	r0.xyz = r0.xxx * i.texcoord1.xyz + r0.yzw;
	r0.xyz = asfloat(r3.yyy) * i.texcoord5.xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r1.xzw = asint(i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = dot(asfloat(r1.xzw), asfloat(r1.xzw));
	r0.w = rsqrt(r0.w);
	r1.xzw = asint(r0.www * asfloat(r1.xzw));
	r0.w = dot(-(asfloat(r1.xzw)), r0.xyz);
	r0.w = r0.w + r0.w;
	r2.xyz = r0.xyz * -(r0.www) + -(asfloat(r1.xzw));
	r0.x = saturate(dot(asfloat(r1.xzw), r0.xyz));
	r0.x = -(r0.x) + 1.00001001;
	r0.yzw = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.x = asint(dot(r0.yzw, r0.yzw));
	r1.x = asint(rsqrt(asfloat(r1.x)));
	r0.yzw = r0.wyz * asfloat(r1.xxx);
	r0.y = saturate(r0.y);
	r0.y = r0.y + 1;
	r0.y = r0.y + r0.y;
	r0.yz = r0.zw / r0.yy;
	r0.yz = r0.yz + float2(0.5, 0.5);
	r0.yz = -(r0.yz) + float2(1, 1);
	r0.yzw = EnvironmentSampler_tex.SampleLevel(EnvironmentSampler, r0.yz, 0).xyz;
	r0.yzw = r0.yzw * r0.yzw;
	r0.yzw = r0.yzw * float3(16, 16, 16);
	r1.x = asint(r0.x * r0.x);
	r1.x = asint(asfloat(r1.x) * asfloat(r1.x));
	r0.x = r0.x * asfloat(r1.x);
	r1.x = asint(-(fresnelRolloff) + 1);
	r0.x = fresnelRolloff * r0.x + asfloat(r1.x);
	r0.xyz = r0.xxx * r0.yzw;
	r0.w = EnvironmentSampler_tex.Sample(EnvironmentSampler, i.texcoord.xy).w;
	r0.xyz = r0.www * r0.xyz;
	r0.xyz = r0.xyz * reflectivePower;
	r0.xyz = asfloat(r1.yyy) * r0.xyz;
	r0.xyz = r0.xyz * ColorCorrectTopAndPedReflectScale.www;
	r0.xyz = r0.xyz * matMaterialColorScale.zzz;
	r0.xyz = saturate(r0.xyz * float3(0.0625, 0.0625, 0.0625));
	o.sv_target3.xyz = sqrt(r0.xyz);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
