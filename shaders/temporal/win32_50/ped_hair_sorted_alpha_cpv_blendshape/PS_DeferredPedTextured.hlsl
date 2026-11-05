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

cbuffer stipplingPattern : register(b3)
{
	float4 stipplePattern : packoffset(c0);
};

cbuffer CachePedParam : register(b4)
{
	float HardAlphaBlend : packoffset(c0);
	float AnisotropicAlphaBias : packoffset(c0.y);
	float ArmourStrength : packoffset(c0.z);
	float reflectivePower : packoffset(c0.w);
	float3 specMapReflectMask : packoffset(c1);
	float fresnelRolloff : packoffset(c1.w);
	float bumpiness : packoffset(c2);
	float displacementScale : packoffset(c2.y);
	float specularFactor : packoffset(c2.z);
	float3 specMapIntMask : packoffset(c3);
	float4 specMapExpMask : packoffset(c4);
	float4 matMaterialColorScale : packoffset(c5);
	float2 anisotropicSpecularIntensity : packoffset(c6);
	float2 anisotropicSpecularExponent : packoffset(c6.z);
	float4 anisotropicSpecularColour : packoffset(c7);
	float4 specularNoiseMapUVScaleFactor : packoffset(c8);
};

cbuffer Details : register(b7)
{
	float4 detailSettings : packoffset(c0);
};

cbuffer Wet : register(b9)
{
	float4 WetDarken : packoffset(c0);
	float4 WetAnisotropicSpecularColour : packoffset(c1);
	float2 WetAnisotropicSpecular : packoffset(c2);
	float4 vHairParams : packoffset(c3);
};

static const float4 icb[4] =
{
	float4(1, 0, 0, 0),
	float4(0, 1, 0, 0),
	float4(0, 0, 1, 0),
	float4(0, 0, 0, 1),
};

SamplerState DiffuseSampler : register(s0);
SamplerState BumpSampler : register(s1);
SamplerState SpecSampler : register(s2);
SamplerState AnisoNoiseSpecSampler : register(s3);
SamplerState VolumeSampler : register(s4);
SamplerState DynamicEnvironmentSampler : register(s13);
Texture2D DiffuseSampler_tex : register(t0);
Texture2D BumpSampler_tex : register(t1);
Texture2D SpecSampler_tex : register(t2);
Texture2D AnisoNoiseSpecSampler_tex : register(t3);
Texture3D VolumeSampler_tex : register(t4);
Texture2D DynamicEnvironmentSampler_tex : register(t13);

struct PS_IN
{
	noperspective float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
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
	int4 r3;
	float4 r4;
	int4 r5;
	float4 r6;
	float3 r7;
	r0.xyz = asint(BumpSampler_tex.Sample(BumpSampler, i.texcoord.xy).xyw);
	r0.w = asint(-(asfloat(r0.z)) + 1);
	r0.w = (asfloat(r0.w) < asfloat(r0.x)) ? -1 : 0;
	r0.w = r0.w & 1065353216;
	r1.xy = -(asfloat(r0.zy)) + asfloat(r0.xy);
	r0.xy = asint(asfloat(r0.ww) * r1.xy + asfloat(r0.zy));
	r1 = DiffuseSampler_tex.Sample(DiffuseSampler, i.texcoord.xy);
	r0.xy = asint(asfloat(r0.xy) * float2(2, 2) + float2(-1, -1));
	r0.xy = asint(asfloat(r0.xy) * bumpiness);
	r0.z = asint(dot(asfloat(r0.xy), asfloat(r0.xy)));
	r0.z = asint(-(asfloat(r0.z)) + 1);
	r0.z = asint(max(asfloat(r0.z), 0));
	r0.z = asint(sqrt(asfloat(r0.z)));
	r2 = SpecSampler_tex.Sample(SpecSampler, i.texcoord.xy);
	r0.w = asint(dot(r2, specMapExpMask));
	r0.w = asint(asfloat(r0.w) * specularFactor);
	r0.w = asint(max(asfloat(r0.w), 1));
	r3.xyz = asint(asfloat(r0.xxx) * i.texcoord4.xyz);
	r3.xyz = asint(asfloat(r0.zzz) * i.texcoord1.xyz + asfloat(r3.xyz));
	r0.xyz = asint(asfloat(r0.yyy) * i.texcoord5.xyz + asfloat(r3.xyz));
	r0.xyz = asint(asfloat(r0.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.w = dot(asfloat(r0.xyz), asfloat(r0.xyz));
	r2.w = rsqrt(r2.w);
	r3.xyz = asint(asfloat(r0.xyz) * r2.www);
	r3.w = (0 < reflectivePower) ? -1 : 0;
	if (r3.w != 0) {
		r3.w = asint(asfloat(r0.w) * 0.015625);
		r3.w = asint(min(asfloat(r3.w), 1));
		r3.w = asint(-(asfloat(r3.w)) * 4 + 4);
		r4.xyz = i.texcoord3.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
		r4.w = dot(r4.xyz, r4.xyz);
		r4.w = rsqrt(r4.w);
		r4.xyz = r4.www * r4.xyz;
		r4.w = dot(-(r4.xyz), asfloat(r3.xyz));
		r4.w = r4.w + r4.w;
		r5.xyz = asint(asfloat(r3.xyz) * -(r4.www) + -(r4.xyz));
		r5.xyz = asint(asfloat(r5.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
		r4.w = dot(asfloat(r5.xyz), asfloat(r5.xyz));
		r4.w = rsqrt(r4.w);
		r5.xyz = asint(r4.www * asfloat(r5.zxy));
		r5.x = asint(saturate(asfloat(r5.x)));
		r4.w = asfloat(r5.x) + 1;
		r4.w = r4.w + r4.w;
		r5.xy = asint(asfloat(r5.yz) / r4.ww);
		r5.xy = asint(asfloat(r5.xy) + float2(0.5, 0.5));
		r5.xy = asint(-(asfloat(r5.xy)) + float2(1, 1));
		r5.xyz = asint(DynamicEnvironmentSampler_tex.SampleLevel(DynamicEnvironmentSampler, asfloat(r5.xy), asfloat(r3.w)).xyz);
		r5.xyz = asint(asfloat(r5.xyz) * asfloat(r5.xyz));
		r5.xyz = asint(asfloat(r5.xyz) * float3(16, 16, 16));
		r3.w = asint(saturate(dot(r4.xyz, asfloat(r3.xyz))));
		r4.x = -(fresnelRolloff) + 1;
		r3.w = asint(-(asfloat(r3.w)) + 1.00001001);
		r4.y = asfloat(r3.w) * asfloat(r3.w);
		r4.y = r4.y * r4.y;
		r3.w = asint(asfloat(r3.w) * r4.y);
		r3.w = asint(fresnelRolloff * asfloat(r3.w) + r4.x);
		r4.xyz = asfloat(r3.www) * asfloat(r5.xyz);
	} else {
		r4.xyz = float3(0, 0, 0);
	}
	r5.xy = asint(i.sv_position.xy * float2(0.5, 0.5));
	r5.zw = (asfloat(r5.xy) >= -(asfloat(r5.xy))) ? -1 : 0;
	r5.xy = asint(frac(abs(asfloat(r5.xy))));
	r5.xy = (r5.zw != 0) ? r5.xy : asint(-(asfloat(r5.xy)));
	r5.xy = asint(asfloat(r5.xy) + asfloat(r5.xy));
	r5.xy = asint(floor(asfloat(r5.xy)));
	r3.w = asint(asfloat(r5.y) * 2 + asfloat(r5.x));
	r3.w = (uint)asfloat(r3.w);
	r3.w = asint(dot(stipplePattern, icb[r3.w]));
	r3.w = (asfloat(r3.w) >= r1.w) ? -1 : 0;
	if (r3.w != 0) discard;
	r3.w = asint(dot(r2.xyz, specMapIntMask.xyz));
	r4.xyz = r4.xyz * reflectivePower;
	r2.x = dot(r2.xyz, specMapReflectMask.xyz);
	r4.xyz = r2.xxx * r4.xyz;
	r4.xyz = r4.xyz * ColorCorrectTopAndPedReflectScale.www;
	r1.w = r1.w * i.texcoord2.w;
	r1.xyz = r1.xyz * matMaterialColorScale.xxx;
	r4.xyz = r4.xyz * matMaterialColorScale.zzz;
	r2.x = asfloat(r3.w) * matMaterialColorScale.w;
	r0.w = asint(asfloat(r0.w) * matMaterialColorScale.w);
	r5.xyz = asint(i.texcoord7.xyz + -(gViewInverse[3].xyz));
	r5.xyz = asint(asfloat(r5.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.y = dot(asfloat(r5.xyz), asfloat(r5.xyz));
	r2.y = rsqrt(r2.y);
	r5.xyz = asint(r2.yyy * asfloat(r5.xyz));
	r0.xyz = asint(asfloat(r0.xyz) * r2.www + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.y = dot(asfloat(r0.xyz), asfloat(r0.xyz));
	r2.y = rsqrt(r2.y);
	r0.xyz = asint(asfloat(r0.xyz) * r2.yyy);
	r0.x = asint(dot(asfloat(r5.xyz), asfloat(r0.xyz)));
	r0.x = asint(asfloat(r0.x) * -1.5);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(-(asfloat(r0.x)) + 1);
	r0.x = asint(max(asfloat(r0.x), 0));
	r0.x = asint(asfloat(r0.x) * i.texcoord2.y);
	r0.y = asint(saturate(r2.x * 5));
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x));
	r5.x = asint(asfloat(r0.w) * 0.00510204071);
	r0.y = asint(saturate(-(asfloat(r0.w)) * 0.00999999978 + 1));
	r0.x = asint(asfloat(r0.y) * asfloat(r0.x) + r2.x);
	r0.y = asint(r2.z * 16);
	r0.y = asint(trunc(asfloat(r0.y)));
	r2.xy = i.texcoord.xy * detailSettings.zw;
	r0.y = asint(asfloat(r0.y) + 0.5);
	r2.z = asfloat(r0.y) * 0.0625;
	r0.yzw = asint(VolumeSampler_tex.Sample(VolumeSampler, r2.xyz).xyz);
	r0.yzw = asint(asfloat(r0.zwy) * float3(2, 2, 2) + float3(-1, -1, -1));
	r2.x = i.texcoord2.w * detailSettings.x;
	r0.w = asint(asfloat(r0.w) * r2.x + 1);
	r2.xyz = asfloat(r0.zzz) * i.texcoord5.xyz;
	r2.xyz = i.texcoord4.xyz * asfloat(r0.yyy) + r2.xyz;
	r2.xyz = r2.xyz * detailSettings.yyy;
	r2.xyz = r2.xyz * i.texcoord2.www + asfloat(r3.xyz);
	r2.xyz = r2.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.y = asint(dot(r2.xyz, r2.xyz));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r2.xyz = asfloat(r0.yyy) * r2.xyz;
	r0.x = asint(saturate(asfloat(r0.w) * asfloat(r0.x)));
	r3.xyz = asint(-(i.texcoord7.xyz) + gViewInverse[3].xyz);
	r5.yzw = asint(i.texcoord4.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.y = asint(dot(asfloat(r5.yzw), asfloat(r5.yzw)));
	r0.y = asint(rsqrt(asfloat(r0.y)));
	r5.yzw = asint(asfloat(r0.yyy) * asfloat(r5.yzw));
	r6 = i.texcoord.xyxy * specularNoiseMapUVScaleFactor;
	r0.y = asint(AnisoNoiseSpecSampler_tex.Sample(AnisoNoiseSpecSampler, r6.xy).x);
	r6.xy = AnisoNoiseSpecSampler_tex.Sample(AnisoNoiseSpecSampler, r6.zw).xy;
	r3.xyz = asint(asfloat(r3.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.z = asint(dot(asfloat(r3.xyz), asfloat(r3.xyz)));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r3.xyz = asint(asfloat(r0.zzz) * asfloat(r3.xyz));
	r7 = gViewInverse[2].xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = asint(dot(r7.xyz, r7.xyz));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r7 = asfloat(r0.zzz) * r7.xyz;
	r6.xy = r6.xy * float2(2, 2) + float2(-1, -1);
	r6.xzw = r6.xxx * i.texcoord1.xyz;
	r6.xzw = r6.xzw * float3(0.100000001, 0.100000001, 0.100000001) + asfloat(r5.yzw);
	r6.xzw = r6.xzw + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.z = asint(dot(r6.xzw, r6.xzw));
	r0.z = asint(rsqrt(asfloat(r0.z)));
	r6.xzw = asfloat(r0.zzz) * r6.xzw;
	r0.z = asint(dot(asfloat(r3.xyz), r6.xzw));
	r2.w = dot(r7.xyz, r6.xzw);
	r3.w = asint(-(asfloat(r0.z)) * asfloat(r0.z) + 1);
	r3.w = asint(max(asfloat(r3.w), 0));
	r3.w = asint(sqrt(asfloat(r3.w)));
	r4.w = -(r2.w) * r2.w + 1;
	r4.w = max(r4.w, 0);
	r4.w = sqrt(r4.w);
	r0.z = asint(asfloat(r0.z) * r2.w);
	r0.z = asint(asfloat(r3.w) * r4.w + -(asfloat(r0.z)));
	r0.z = asint(abs(asfloat(r0.z)) + 0.00000999999975);
	r6.xz = -(anisotropicSpecularExponent.xy) + WetAnisotropicSpecular.xy;
	r6.xz = vHairParams.xx * r6.xz + anisotropicSpecularExponent.xy;
	r6.xz = r6.xz + float2(8.00000954, 16.0000095);
	r0.z = asint(log2(asfloat(r0.z)));
	r0.z = asint(asfloat(r0.z) * r6.x);
	r0.z = asint(exp2(asfloat(r0.z)));
	r5.yzw = asint(i.texcoord1.xyz * r6.yyy + asfloat(r5.yzw));
	r5.yzw = asint(asfloat(r5.yzw) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r2.w = dot(asfloat(r5.yzw), asfloat(r5.yzw));
	r2.w = rsqrt(r2.w);
	r5.yzw = asint(r2.www * asfloat(r5.yzw));
	r2.w = dot(asfloat(r3.xyz), asfloat(r5.yzw));
	r3.x = asint(dot(r7.xyz, asfloat(r5.yzw)));
	r3.y = asint(-(r2.w) * r2.w + 1);
	r3.y = asint(max(asfloat(r3.y), 0));
	r3.z = asint(-(asfloat(r3.x)) * asfloat(r3.x) + 1);
	r3.z = asint(max(asfloat(r3.z), 0));
	r3.yz = asint(sqrt(asfloat(r3.yz)));
	r2.w = r2.w * asfloat(r3.x);
	r2.w = asfloat(r3.y) * asfloat(r3.z) + -(r2.w);
	r2.w = abs(r2.w) + 0.00000999999975;
	r2.w = log2(r2.w);
	r2.w = r2.w * r6.z;
	r2.w = exp2(r2.w);
	r0.z = asint(asfloat(r0.z) + r2.w);
	r0.x = asint(asfloat(r0.z) * asfloat(r0.x));
	r0.z = asint(anisotropicSpecularIntensity.x + 0.200000003);
	r0.x = asint(asfloat(r0.z) * asfloat(r0.x));
	o.sv_target2.x = asfloat(r0.y) * asfloat(r0.x);
	r0.xyz = asint(-(anisotropicSpecularColour.xyz) + WetAnisotropicSpecularColour.xyz);
	r0.xyz = asint(vHairParams.xxx * asfloat(r0.xyz) + anisotropicSpecularColour.xyz);
	r0.xyz = asint(r2.www * asfloat(r0.xyz));
	r0.xyz = asint(asfloat(r0.xyz) * float3(0.5, 0.5, 0.5));
	r0.xyz = asint(r1.xyz * asfloat(r0.www) + asfloat(r0.xyz));
	r0.w = asint(i.texcoord2.x * 1.5);
	o.sv_target.xyz = asfloat(r0.www) * asfloat(r0.xyz);
	r0.x = asint(saturate(r1.w * 1.70000005));
	r0.y = asint(saturate(gAmbientOcclusionEffect.z));
	r0.y = asint(saturate(asfloat(r0.y) + i.texcoord2.x));
	o.sv_target1.xyz = r2.xyz * float3(0.5, 0.5, 0.5) + float3(0.5, 0.5, 0.5);
	r5.x = asint(saturate(asfloat(r5.x)));
	r0.z = asint(sqrt(asfloat(r5.x)));
	o.sv_target2.y = sqrt(asfloat(r0.z));
	o.sv_target2.z = asfloat(r0.y) * gAmbientOcclusionEffect.w;
	r0.x = asint(asfloat(r0.x) * globalScalars.x);
	r0.yzw = asint(saturate(r4.xyz * float3(0.0625, 0.0625, 0.0625)));
	o.sv_target3.xyz = sqrt(asfloat(r0.yzw));
	o.sv_target.w = asfloat(r0.x);
	o.sv_target1.w = asfloat(r0.x);
	o.sv_target2.w = asfloat(r0.x);
	o.sv_target3.w = asfloat(r0.x);

	float w = i.temporalPrevious.z;
    float2 previousUV = i.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = i.sv_position.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;
}
