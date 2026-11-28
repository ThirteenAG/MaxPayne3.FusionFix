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

cbuffer rage_SoftParticleBuffer : register(b4)
{
  float4 NearFarPlane : packoffset(c0);
  float4 gInvScreenSize : packoffset(c1);
}

cbuffer CacheHybrid : register(b7)
{
  float HybridAdd : packoffset(c0);
}

cbuffer ParticleGlobals : register(b8)
{
  float4 gBloodLightingTuners : packoffset(c0);
}

cbuffer ParticleSprite : register(b9)
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
  float4 r0,r1,r2,r3,r4,r5,r6,r7;
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
  r1.x = v2.w * r1.x;
  o1.w = saturate(gSuperAlpha * r1.x);
  sincos(v1.z, r1.x, r4.x);
  r1.xw = r1.yz * r1.xx;
  r0.x = r1.z * r4.x + -r1.x;
  r0.y = r1.y * r4.x + r1.w;
  o0.xyzw = r0.xyzw * gAspectRatio.xyzw + r3.xyzw;
  r0.zw = gAspectRatio.xy * r0.xy;
  r0.xy = r0.xy * gAspectRatio.xy + float2(9.99999975e-06,9.99999975e-06);
  r0.z = dot(r0.zw, r0.zw);
  r0.z = sqrt(r0.z);
  r0.z = cmp(r0.z != 0.000000);
  r0.w = dot(r0.xy, r0.xy);
  r0.w = rsqrt(r0.w);
  r0.xy = r0.xy * r0.ww;
  r0.xy = r0.zz ? r0.xy : 0;
  r1.xyz = gWorldView._m10_m11_m12 * r2.yyy;
  r1.xyz = r2.xxx * gWorldView._m00_m01_m02 + r1.xyz;
  r1.xyz = r2.zzz * gWorldView._m20_m21_m22 + r1.xyz;
  r1.xyz = gWorldView._m30_m31_m32 + r1.xyz;
  r3.xyz = float3(9.99999975e-06,9.99999975e-06,9.99999975e-06) + -r1.xyz;
  r0.z = dot(r3.xyz, r3.xyz);
  r0.z = rsqrt(r0.z);
  r3.xyz = r3.xyz * r0.zzz;
  r4.xyz = float3(-1,0,0) * r3.zxy;
  r4.xyz = r3.yzx * float3(0,0,-1) + -r4.xyz;
  r4.xyz = float3(9.99999975e-06,9.99999975e-06,9.99999975e-06) + r4.xyz;
  r0.z = dot(r4.xyz, r4.xyz);
  r0.z = rsqrt(r0.z);
  r4.xyz = r4.xyz * r0.zzz;
  r5.xyz = r4.yzx * r3.zxy;
  r5.xyz = r3.yzx * r4.zxy + -r5.xyz;
  r0.yzw = r5.xyz * r0.yyy;
  r0.xyz = r4.xyz * r0.xxx + r0.yzw;
  r0.xyz = r3.xyz * gNormalArc + r0.xyz;
  r3.xyz = float3(9.99999975e-06,9.99999975e-06,9.99999975e-06) + r0.xyz;
  r0.w = dot(r3.xyz, r3.xyz);
  r0.w = rsqrt(r0.w);
  r3.xyz = r3.xyz * r0.www;
  r0.w = dot(r0.xyz, r0.xyz);
  r0.w = sqrt(r0.w);
  r0.w = cmp(r0.w != 0.000000);
  r0.xyz = r0.www ? r3.xyz : r0.xyz;
  r3.xyzw = gLightPosX.xyzw + -r1.xxxx;
  r4.xyzw = -gLightDirX.xyzw * r3.xyzw;
  r5.xyzw = gLightPosY.xyzw + -r1.yyyy;
  r1.xyzw = gLightPosZ.xyzw + -r1.zzzz;
  r4.xyzw = r5.xyzw * -gLightDirY.xyzw + r4.xyzw;
  r4.xyzw = r1.xyzw * -gLightDirZ.xyzw + r4.xyzw;
  r6.xyzw = r3.xyzw * r3.xyzw;
  r6.xyzw = r5.xyzw * r5.xyzw + r6.xyzw;
  r6.xyzw = r1.xyzw * r1.xyzw + r6.xyzw;
  r7.xyzw = float4(9.99999975e-06,9.99999975e-06,9.99999975e-06,9.99999975e-06) + r6.xyzw;
  r6.xyzw = -r6.xyzw * gLightFallOff.xyzw + float4(1,1,1,1);
  r6.xyzw = max(float4(0,0,0,0), r6.xyzw);
  r6.xyzw = r6.xyzw * r6.xyzw;
  r6.xyzw = r6.xyzw * r6.xyzw + float4(-0.100000001,-0.100000001,-0.100000001,-0.100000001);
  r6.xyzw = max(float4(0,0,0,0), r6.xyzw);
  r7.xyzw = rsqrt(r7.xyzw);
  r4.xyzw = r7.xyzw * r4.xyzw;
  r4.xyzw = saturate(r4.xyzw * gLightConeScale.xyzw + gLightConeOffset.xyzw);
  r6.xyzw = r7.xyzw * r6.xyzw;
  r6.xyzw = float4(1.11111116,1.11111116,1.11111116,1.11111116) * r6.xyzw;
  r6.xyzw = min(float4(1,1,1,1), r6.xyzw);
  r4.xyzw = r6.xyzw * r4.xyzw;
  r4.xyzw = r4.xyzw * r7.xyzw;
  r3.xyzw = r4.xyzw * r3.xyzw;
  r3.xyzw = r3.xyzw * r0.xxxx;
  r5.xyzw = r5.xyzw * r4.xyzw;
  r3.xyzw = r0.yyyy * r5.xyzw + r3.xyzw;
  r1.xyzw = r4.xyzw * r1.xyzw;
  r0.w = gWrapBias * r4.x;
  r1.xyzw = saturate(r0.zzzz * r1.xyzw + r3.xyzw);
  r3.x = dot(gLightColR.xyzw, r1.xyzw);
  r3.y = dot(gLightColG.xyzw, r1.xyzw);
  r3.z = dot(gLightColB.xyzw, r1.xyzw);
  r1.x = dot(r0.xyz, -gDirectionalLight.xyz);
  r0.w = saturate(r1.x * gWrapScale + r0.w);
  r1.xyz = r0.www * gDirectionalColour.xyz + r3.xyz;
  r0.w = dot(gLightAmbientDir1.xyz, r0.xyz);
  r0.x = dot(gLightAmbientDir0.xyz, r0.xyz);
  r0.xy = saturate(gLightAmbientDir0.ww + r0.xw);
  r0.yzw = gLightAmbient1.xyz * r0.yyy;
  r0.xyz = r0.xxx * gLightAmbient0.xyz + r0.yzw;
  r0.xyz = r0.xyz * gBloodLightingTuners.zzz + r1.xyz;
  r0.xyz = gDiffuse * r0.xyz;
  r0.xyz = v2.xyz * r0.xyz;
  r0.w = globalScalars4.x * v6.y;
  o1.xyz = r0.xyz * r0.www;
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