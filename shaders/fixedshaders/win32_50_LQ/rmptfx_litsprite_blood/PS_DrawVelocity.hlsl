// Decompiled from the original game shader.

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
  float4 gScreenSpaceTessFactors : packoffset(c22);
  float4 gTessFactors : packoffset(c23);
  float4 gFrustumPlaneEquation_Left : packoffset(c24);
  float4 gFrustumPlaneEquation_Right : packoffset(c25);
  float4 gFrustumPlaneEquation_Top : packoffset(c26);
  float4 gFrustumPlaneEquation_Bottom : packoffset(c27);
  float4 gTessParameters : packoffset(c28);
}

cbuffer CacheHybrid : register(b4)
{
  float HybridAdd : packoffset(c0);
}

SamplerState DiffuseTexSampler_s : register(s0);
Texture2D<float4> DiffuseTexSampler : register(t0);


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
  float4 r0,r1,r2;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = saturate(v4.x);
  r1.xyzw = DiffuseTexSampler.Sample(DiffuseTexSampler_s, v3.zw).xyzw;
  r2.xyzw = DiffuseTexSampler.Sample(DiffuseTexSampler_s, v3.xy).xyzw;
  r1.xyzw = -r2.xyzw + r1.xyzw;
  r0.xyzw = r0.xxxx * r1.xyzw + r2.xyzw;
  r1.xyzw = v1.wxyz * r0.wxyz;
  r0.w = dot(r1.yzw, float3(0.212500006,0.715399981,0.0720999986));
  r1.x = saturate(r1.x);
  r0.xyz = r0.xyz * v1.xyz + -r0.www;
  r1.y = deSatContrastGamma.x * gAdrenoFXVars.x;
  r0.xyz = r1.yyy * r0.xyz + r0.www;
  r1.yzw = v5.xyz + -r0.xyz;
  r0.xyz = v5.www * r1.yzw + r0.xyz;
  r0.w = cmp(0 < HybridAdd);
  r0.w = r0.w ? r1.x : 1;
  r1.w = v4.z * r1.x;
  r1.xyz = r0.xyz * r0.www;
  r0.xyzw = max(float4(0,0,0,0), r1.xyzw);
  o0.xyzw = min(float4(32,32,32,32), r0.xyzw);
  return;
}