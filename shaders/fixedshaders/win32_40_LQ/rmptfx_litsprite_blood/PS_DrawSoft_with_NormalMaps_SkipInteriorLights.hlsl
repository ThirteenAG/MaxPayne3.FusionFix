// Decompiled from the original game shader.

cbuffer direction_light : register(b10)
{
  float4 gDepthFxParams : packoffset(c0);
  float4 gDirectionalLight : packoffset(c1);
  float4 gDirectionalColour : packoffset(c2);
}

cbuffer omni_light : register(b2)
{
  float4 gLightPosX : packoffset(c0);
  float4 gLightPosY : packoffset(c1);
  float4 gLightPosZ : packoffset(c2);
  float4 gLightDirX : packoffset(c3);
  float4 gLightDirY : packoffset(c4);
  float4 gLightDirZ : packoffset(c5);
  float4 gLightFallOff : packoffset(c6);
  float4 gLightConeScale : packoffset(c7);
  float4 gLightConeOffset : packoffset(c8);
  float4 gLightColR : packoffset(c9);
  float4 gLightColG : packoffset(c10);
  float4 gLightColB : packoffset(c11);
  float4 gLightAmbient0 : packoffset(c12);
  float4 gLightAmbient1 : packoffset(c13);
  float4 gLightAmbientDir0 : packoffset(c14);
  float4 gLightAmbientDir1 : packoffset(c15);
  float4 gLightPointColR : packoffset(c16);
  float4 gLightPointColG : packoffset(c17);
  float4 gLightPointColB : packoffset(c18);
  float4 gLightPointPosX : packoffset(c19);
  float4 gLightPointPosY : packoffset(c20);
  float4 gLightPointPosZ : packoffset(c21);
  float4 gLightDir2X : packoffset(c22);
  float4 gLightDir2Y : packoffset(c23);
  float4 gLightDir2Z : packoffset(c24);
  float4 gLightConeScale2 : packoffset(c25);
  float4 gLightConeOffset2 : packoffset(c26);
  float4 gLightPointFallOff : packoffset(c27);
  float4 gDistFadeParams : packoffset(c28);
  float4 gAdrenoFXVars : packoffset(c29);
}

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
  float4 gWaterGlobals : packoffset(c19);
  float4 ColorCorrectTopScreenEdge : packoffset(c20);
  float4 ColorCorrectBottomOffsetScreenEdge : packoffset(c21);
}

cbuffer CacheHybrid : register(b4)
{
  float HybridAdd : packoffset(c0);
}

cbuffer ParticleGlobals : register(b7)
{
  float4 gBloodLightingTuners : packoffset(c0);
}

cbuffer ParticleSprite : register(b8)
{
  float gBiasToCamera : packoffset(c0);
  float gWrapScale : packoffset(c0.y);
  float gWrapBias : packoffset(c0.z);
  float gDiffuse : packoffset(c0.w);
  float gSpecularIntensity : packoffset(c1);
  float gSpecularExponent : packoffset(c1.y);
  float gExtraLights : packoffset(c1.z);
  float gAmbientAmount : packoffset(c1.w);
  float gSuperAlpha : packoffset(c2);
  float gNormalArc : packoffset(c2.y);
  float gScaleFade : packoffset(c2.z);
  float gUseShadows : packoffset(c2.w);
  float gAmbientShadow : packoffset(c3);
  float gLightIntensityClamp : packoffset(c3.y);
  float4 gTexCoordScaleOffset0 : packoffset(c4);
}

SamplerState DiffuseTexSampler_s : register(s0);
SamplerState NormalMapTexSampler_s : register(s1);
Texture2D<float4> DiffuseTexSampler : register(t0);
Texture2D<float4> NormalMapTexSampler : register(t1);


// 3Dmigoto declarations
#define cmp -
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> StereoParams : register(t125);


void main( 
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  float4 v2 : TEXCOORD7,
  float4 v3 : TEXCOORD1,
  float4 v4 : TEXCOORD3,
  float4 v5 : TEXCOORD4,
  out float4 o0 : SV_Target0)
{
  float4 r0,r1,r2,r3;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.xyzw = NormalMapTexSampler.Sample(NormalMapTexSampler_s, v3.zw).xyzw;
  r0.xyz = r0.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r1.xyzw = NormalMapTexSampler.Sample(NormalMapTexSampler_s, v3.xy).xyzw;
  r1.xyz = r1.xyz * float3(2,2,2) + float3(-1,-1,-1);
  r0.xyz = -r1.xyz + r0.xyz;
  r0.w = saturate(v4.x);
  r1.xyz = r0.www * r0.xyz + r1.xyz;
  r1.w = -r1.y;
  r0.xyz = float3(9.99999975e-06,9.99999975e-06,9.99999975e-06) + r1.xwz;
  r1.x = dot(r0.xyz, r0.xyz);
  r1.x = rsqrt(r1.x);
  r0.xyz = r1.xxx * r0.xyz;
  r1.x = -2 * r0.z;
  r1.xyz = r0.xyz * -r1.xxx + float3(0,0,-1);
  r1.x = saturate(dot(r1.xyz, -gDirectionalLight.xyz));
  r1.x = 9.99999975e-06 + r1.x;
  r1.x = log2(r1.x);
  r1.y = 9.99999975e-06 + gSpecularExponent;
  r1.x = r1.y * r1.x;
  r1.x = exp2(r1.x);
  r1.x = r1.x * gWrapScale + gWrapBias;
  r1.x = gDirectionalColour.x * r1.x;
  r1.x = gSpecularIntensity * r1.x;
  r1.y = dot(r0.xyz, -gDirectionalLight.xyz);
  r1.y = max(-gLightIntensityClamp, r1.y);
  r1.y = min(gLightIntensityClamp, r1.y);
  r1.z = 1 + -r1.y;
  r1.y = gNormalArc * r1.z + r1.y;
  r1.y = r1.y * gWrapScale + gWrapBias;
  r1.y = gDirectionalColour.x * r1.y;
  r1.y = gDiffuse * r1.y;
  r1.y = max(gBloodLightingTuners.x, r1.y);
  r1.y = min(gBloodLightingTuners.y, r1.y);
  r1.yzw = v1.xyz * r1.yyy;
  r1.xyzw = max(float4(0,0,0,0), r1.xyzw);
  r1.xyz = r1.yzw + r1.xxx;
  r1.w = dot(gLightAmbientDir1.xyz, r0.xyz);
  r0.x = dot(gLightAmbientDir0.xyz, r0.xyz);
  r0.x = saturate(gLightAmbientDir0.w + r0.x);
  r0.y = saturate(gLightAmbientDir0.w + r1.w);
  r2.xyz = gLightAmbient1.xyz * r0.yyy;
  r0.xyz = r0.xxx * gLightAmbient0.xyz + r2.xyz;
  r0.xyz = gBloodLightingTuners.zzz * r0.xyz;
  r0.xyz = v1.xyz * r0.xyz;
  r0.xyz = max(float3(0,0,0), r0.xyz);
  r1.xyz = r0.xyz * gAmbientShadow + r1.xyz;
  r2.xyzw = DiffuseTexSampler.Sample(DiffuseTexSampler_s, v3.zw).xyzw;
  r3.xyzw = DiffuseTexSampler.Sample(DiffuseTexSampler_s, v3.xy).xyzw;
  r2.xyzw = -r3.xyzw + r2.xyzw;
  r0.xyzw = r0.wwww * r2.xyzw + r3.xyzw;
  r1.w = saturate(gSuperAlpha * v1.w);
  r2.xyzw = r1.wxyz * r0.wxyz;
  r0.w = dot(r2.yzw, float3(0.212500006,0.715399981,0.0720999986));
  r2.x = saturate(r2.x);
  r0.xyz = r1.xyz * r0.xyz + -r0.www;
  r1.x = deSatContrastGamma.x * gAdrenoFXVars.x;
  r0.xyz = r1.xxx * r0.xyz + r0.www;
  r1.xyz = v5.xyz + -r0.xyz;
  r0.xyz = v5.www * r1.xyz + r0.xyz;
  r0.w = cmp(0 < HybridAdd);
  r0.w = r0.w ? r2.x : 1;
  o0.w = v4.z * r2.x;
  o0.xyz = r0.xyz * r0.www;
  // Transparent parts of the sprite must not occlude later blood particles.
  clip(o0.w - (1.0 / 255.0));
  return;
}