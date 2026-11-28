// Decompiled from the original game shader.

cbuffer rage_matrices : register(b0)
{
  row_major float4x4 gWorld : packoffset(c0);
  row_major float4x4 gWorldView : packoffset(c4);
  row_major float4x4 gWorldViewProj : packoffset(c8);
  row_major float4x4 gViewInverse : packoffset(c12);
}

cbuffer rage_ptx : register(b3)
{
  float4 gForcedColor : packoffset(c0);
  float4 gAspectRatio : packoffset(c1);
}

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
  float4 r0,r1,r2,r3,r4,r5;
  uint4 bitmask, uiDest;
  float4 fDest;

  sincos(v1.z, r0.x, r1.x);
  r0.xy = v1.yx * r0.xx;
  r2.x = v1.x * r1.x + -r0.x;
  r2.y = v1.y * r1.x + r0.y;
  r2.z = 0;
  r0.xy = v0.xy;
  r0.z = 0;
  r1.xyz = r2.xyz * gAspectRatio.xyz + r0.xyz;
  r2.xyz = gAspectRatio.xyz * r2.xyz;
  r0.w = cmp(v1.w == 1.000000);
  o0.xyz = r0.www ? r1.xyz : r0.xyz;
  r0.xyz = r0.www ? r2.xyz : v0.xyz;
  o0.w = 1;
  r1.xy = gAspectRatio.xy;
  r1.z = 1;
  r0.xyz = r0.xyz / r1.xyz;
  r0.xyz = float3(9.99999975e-06,9.99999975e-06,9.99999975e-06) + r0.xyz;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = rsqrt(r0.w);
  r0.xyz = r0.xyz * r0.www;
  r1.xyz = gWorldView._m10_m11_m12 * v0.yyy;
  r1.xyz = v0.xxx * gWorldView._m00_m01_m02 + r1.xyz;
  r1.xyz = v0.zzz * gWorldView._m20_m21_m22 + r1.xyz;
  r1.xyz = gWorldView._m30_m31_m32 + r1.xyz;
  r2.xyzw = gLightPosX.xyzw + -r1.xxxx;
  r3.xyzw = r2.xyzw * r0.xxxx;
  r4.xyzw = gLightPosY.xyzw + -r1.yyyy;
  r1.xyzw = gLightPosZ.xyzw + -r1.zzzz;
  r3.xyzw = r4.xyzw * r0.yyyy + r3.xyzw;
  r3.xyzw = r1.xyzw * r0.zzzz + r3.xyzw;
  r5.xyzw = r2.xyzw * r2.xyzw;
  r2.xyzw = -gLightDirX.xyzw * r2.xyzw;
  r2.xyzw = r4.xyzw * -gLightDirY.xyzw + r2.xyzw;
  r4.xyzw = r4.xyzw * r4.xyzw + r5.xyzw;
  r4.xyzw = r1.xyzw * r1.xyzw + r4.xyzw;
  r2.xyzw = r1.xyzw * -gLightDirZ.xyzw + r2.xyzw;
  r5.xyzw = -r4.xyzw * gLightFallOff.xyzw + float4(1,1,1,1);
  r4.xyzw = float4(9.99999975e-06,9.99999975e-06,9.99999975e-06,9.99999975e-06) + r4.xyzw;
  r4.xyzw = rsqrt(r4.xyzw);
  r5.xyzw = max(float4(0,0,0,0), r5.xyzw);
  r5.xyzw = r5.xyzw * r5.xyzw;
  r5.xyzw = r5.xyzw * r5.xyzw + float4(-0.100000001,-0.100000001,-0.100000001,-0.100000001);
  r5.xyzw = max(float4(0,0,0,0), r5.xyzw);
  r5.xyzw = float4(1.11111116,1.11111116,1.11111116,1.11111116) * r5.xyzw;
  r3.xyzw = r5.xyzw * r3.xyzw;
  r1.xyzw = r5.xyzw * r1.xyzw;
  r1.xyzw = saturate(r1.xyzw * r4.xyzw);
  r3.xyzw = saturate(r3.xyzw * r4.xyzw);
  r2.xyzw = r4.xyzw * r2.xyzw;
  r2.xyzw = saturate(r2.xyzw * gLightConeScale.xyzw + gLightConeOffset.xyzw);
  r3.xyzw = r2.xyzw * r3.xyzw;
  r1.xyzw = r2.xyzw * r1.xyzw;
  r0.w = dot(gLightColR.xyzw, r3.xyzw);
  r2.x = dot(gLightColR.xyzw, r1.xyzw);
  r2.x = r2.x * 0.25 + r0.w;
  r0.w = dot(gLightColG.xyzw, r1.xyzw);
  r1.x = dot(gLightColB.xyzw, r1.xyzw);
  r1.y = dot(gLightColG.xyzw, r3.xyzw);
  r1.z = dot(gLightColB.xyzw, r3.xyzw);
  r2.z = r1.x * 0.25 + r1.z;
  r2.y = r0.w * 0.25 + r1.y;
  r1.xyz = max(gBloodLightingTuners.xxx, r2.xyz);
  r1.xyz = min(gBloodLightingTuners.yyy, r1.xyz);
  r1.xyz = v2.xyz * r1.xyz;
  r1.xyz = max(float3(0,0,0), r1.xyz);
  r0.w = dot(r0.xyz, -gDirectionalLight.xyz);
  r0.w = max(-gLightIntensityClamp, r0.w);
  r0.w = min(gLightIntensityClamp, r0.w);
  r1.w = 1 + -r0.w;
  r0.w = gNormalArc * r1.w + r0.w;
  r0.w = r0.w * gWrapScale + gWrapBias;
  r0.w = gDirectionalColour.x * r0.w;
  r0.w = gDiffuse * r0.w;
  r0.w = max(gBloodLightingTuners.x, r0.w);
  r0.w = min(gBloodLightingTuners.y, r0.w);
  r2.xyz = v2.xyz * r0.www;
  r2.xyz = max(float3(0,0,0), r2.xyz);
  r2.xyz = v2.xyz + r2.xyz;
  r1.xyz = r2.xyz + r1.xyz;
  r0.w = dot(gLightAmbientDir1.xyz, r0.xyz);
  r0.x = dot(gLightAmbientDir0.xyz, r0.xyz);
  r0.xy = saturate(gLightAmbientDir0.ww + r0.xw);
  r0.yzw = gLightAmbient1.xyz * r0.yyy;
  r0.xyz = r0.xxx * gLightAmbient0.xyz + r0.yzw;
  r0.xyz = gBloodLightingTuners.zzz * r0.xyz;
  r0.xyz = v2.xyz * r0.xyz;
  r0.xyz = max(float3(0,0,0), r0.xyz);
  r0.xyz = r0.xyz * gAmbientShadow + r1.xyz;
  r0.w = globalScalars4.x * v6.y;
  o1.xyz = r0.xyz * r0.www;
  o1.w = saturate(gSuperAlpha * v2.w);
  r0.xyzw = gWorldView._m10_m11_m12_m13 * v0.yyyy;
  r0.xyzw = v0.xxxx * gWorldView._m00_m01_m02_m03 + r0.xyzw;
  r0.xyzw = v0.zzzz * gWorldView._m20_m21_m22_m23 + r0.xyzw;
  o2.xyzw = gWorldView._m30_m31_m32_m33 + r0.xyzw;
  o3.xyzw = v3.xyzw * gTexCoordScaleOffset0.xyxy + gTexCoordScaleOffset0.zwzw;
  r0.x = 1 + -v6.x;
  r0.y = cmp(0.5 < HybridAdd);
  o4.z = r0.y ? r0.x : 1;
  o4.x = v5.z;
  o4.y = 0;
  o4.w = v6.y;
  r0.xyz = -gViewInverse._m30_m31_m32 + v0.xyz;
  r0.w = globalFogParams.x * r0.z;
  r0.x = dot(r0.xyz, r0.xyz);
  r0.x = sqrt(r0.x);
  r0.x = globalFogParams.z * r0.x;
  r0.y = -1.44269502 * r0.w;
  r0.y = exp2(r0.y);
  r0.y = 1 + -r0.y;
  r0.y = r0.y / r0.w;
  r0.z = cmp(9.99999975e-05 < abs(r0.w));
  r0.y = r0.x * r0.y;
  r0.x = r0.z ? r0.y : r0.x;
  r0.x = -globalFogParams.y * r0.x;
  r0.x = 1.44269502 * r0.x;
  r0.x = exp2(r0.x);
  o5.w = 1 + -r0.x;
  o5.xyz = globalFogColorN.xyz;
  return;
}