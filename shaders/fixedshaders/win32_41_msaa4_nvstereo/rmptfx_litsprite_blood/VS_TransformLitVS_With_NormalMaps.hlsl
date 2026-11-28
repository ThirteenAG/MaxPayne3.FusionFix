// Decompiled from the original game shader.

cbuffer rage_matrices : register(b0)
{
  row_major float4x4 gWorld : packoffset(c0);
  row_major float4x4 gWorldView : packoffset(c4);
  row_major float4x4 gWorldViewProj : packoffset(c8);
  row_major float4x4 gViewInverse : packoffset(c12);
  float4 gConverengeDepth : packoffset(c16);
}

cbuffer rage_ptx : register(b3)
{
  float4 gForcedColor : packoffset(c0);
  float4 gAspectRatio : packoffset(c1);
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

cbuffer rage_SoftParticleBuffer : register(b4)
{
  float4 NearFarPlane : packoffset(c0);
  float4 gInvScreenSize : packoffset(c1);
}

cbuffer CacheHybrid : register(b7)
{
  float HybridAdd : packoffset(c0);
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



// 3Dmigoto declarations
#define cmp -
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> StereoParams : register(t125);


void main( 
  float3 v0 : POSITION0,
  float4 v1 : NORMAL0,
  float4 v2 : COLOR0,
  float4 v3 : TEXCOORD0,
  float4 v4 : TEXCOORD1,
  float4 v5 : TEXCOORD2,
  float4 v6 : TEXCOORD3,
  out float4 o0 : SV_Position0,
  out float4 o1 : TEXCOORD0,
  out float4 o2 : TEXCOORD7,
  out float4 o3 : TEXCOORD1,
  out float4 o4 : TEXCOORD3,
  out float4 o5 : TEXCOORD4)
{
  float4 r0,r1,r2,r3,r4;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.zw = float2(0,0);
  r1.x = cmp(9.99999997e-07 >= v2.w);
  r1.y = 1 / gScaleFade;
  r2.xyz = gViewInverse._m30_m31_m32 + -v0.xyz;
  r1.z = 0.100000001 * gBiasToCamera;
  r2.xyz = r2.xyz * r1.zzz + v0.xyz;
  r3.xyzw = gWorldViewProj._m10_m11_m12_m13 * r2.yyyy;
  r3.xyzw = r2.xxxx * gWorldViewProj._m00_m01_m02_m03 + r3.xyzw;
  r3.xyzw = r2.zzzz * gWorldViewProj._m20_m21_m22_m23 + r3.xyzw;
  r3.xyzw = gWorldViewProj._m30_m31_m32_m33 + r3.xyzw;
  r1.z = -NearFarPlane.x + r3.w;
  r1.y = saturate(r1.z * r1.y);
  r1.x = r1.x ? 0 : r1.y;
  r1.yz = v1.yx * r1.xx;
  o1.w = v2.w * r1.x;
  sincos(v1.z, r1.x, r4.x);
  r1.xw = r1.yz * r1.xx;
  r0.x = r1.z * r4.x + -r1.x;
  r0.y = r1.y * r4.x + r1.w;
  o0.xyzw = r0.xyzw * gAspectRatio.xyzw + r3.xyzw;
  r0.x = globalScalars4.x * v6.y;
  o1.xyz = v2.xyz * r0.xxx;
  r0.xyzw = gWorldView._m10_m11_m12_m13 * r2.yyyy;
  r0.xyzw = r2.xxxx * gWorldView._m00_m01_m02_m03 + r0.xyzw;
  r0.xyzw = r2.zzzz * gWorldView._m20_m21_m22_m23 + r0.xyzw;
  r1.xyz = -gViewInverse._m30_m31_m32 + r2.xyz;
  o2.xyzw = gWorldView._m30_m31_m32_m33 + r0.xyzw;
  o3.xyzw = v3.xyzw * gTexCoordScaleOffset0.xyxy + gTexCoordScaleOffset0.zwzw;
  r0.x = 1 + -v6.x;
  r0.y = cmp(0.5 < HybridAdd);
  o4.z = r0.y ? r0.x : 1;
  o4.x = v5.z;
  o4.y = 0;
  o4.w = v6.y;
  r0.x = globalFogParams.x * r1.z;
  r0.y = dot(r1.xyz, r1.xyz);
  r0.y = sqrt(r0.y);
  r0.y = globalFogParams.z * r0.y;
  r0.z = -1.44269502 * r0.x;
  r0.z = exp2(r0.z);
  r0.z = 1 + -r0.z;
  r0.z = r0.z / r0.x;
  r0.x = cmp(9.99999975e-05 < abs(r0.x));
  r0.z = r0.y * r0.z;
  r0.x = r0.x ? r0.z : r0.y;
  r0.x = -globalFogParams.y * r0.x;
  r0.x = 1.44269502 * r0.x;
  r0.x = exp2(r0.x);
  o5.w = 1 + -r0.x;
  o5.xyz = globalFogColorN.xyz;
  return;
}