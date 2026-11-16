float4 ColorShift : register(c45);
float ColorShiftScalar : register(c188);
sampler2D GBufferTextureSamplerDepth : register(s3);
sampler2D GBufferTextureSamplerSSAODepth : register(s4);
sampler2D HDRSampler : register(s5);
float PedBrightness : register(c187);
float PlayerBrightness : register(c186);
sampler2D StencilCopySampler : register(s8);
float4 deSatContrastGamma : register(c46);
float4 dofProj : register(c136);
float4 gAdrenoFXVars : register(c68);
float4 globalFogColorN : register(c50);
float4 globalFogParams : register(c37);

struct PS_IN
{
	float2 texcoord : TEXCOORD;
	float3 texcoord1 : TEXCOORD1;
};

float4 main(PS_IN i) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	r0 = tex2D(GBufferTextureSamplerDepth, i.texcoord.xy);
	r0.y = -dofProj.x + dofProj.y;
	r0.y = 1 / r0.y;
	r0.x = dofProj.y * -r0.y + r0.x;
	r0.y = r0.y * dofProj.y;
	r0.y = r0.y * -dofProj.x;
	r0.x = 1 / r0.x;
	r0.x = r0.x * r0.y;
	r0.xyz = -r0.xxx * i.texcoord1.xyz;
	r0.w = r0.z * globalFogParams.x;
	r0.x = dot(r0.xyz, r0.xyz);
	r0.x = rsqrt(r0.x);
	r0.x = 1 / r0.x;
	r0.x = r0.x * globalFogParams.z;
	r0.y = r0.w * -1.442695;
	r0.y = exp2(r0.y);
	r0.z = r0.y + -65504;
	r0.y = -r0.y + 1;
	r0.y = (r0.z >= 0) ? -65503 : r0.y;
	r0.z = 1 / r0.w;
	r0.w = -abs(r0.w) + 0.0001;
	r0.y = r0.z * r0.y;
	r0.y = r0.y * r0.x;
	r0.x = (r0.w >= 0) ? r0.x : r0.y;
	r0.x = r0.x * -globalFogParams.y;
	r0.x = r0.x * 1.442695;
	r0.x = saturate(exp2(r0.x));
	r1 = tex2D(StencilCopySampler, i.texcoord.xy);
	r1 = tex2D(GBufferTextureSamplerSSAODepth, r1.ww);
	r2 = (-abs(r1.zywy) >= 0) ? 0 : float4(1, 1, 1, -1);
	r0.y = (-abs(r1.w) >= 0) ? r2.w : -0;
	r0.zw = r2.yz + r2.xx;
	r2.x = 1;
	r0.y = (r0.y >= 0) ? r2.x : PedBrightness.x;
	r0.w = (-r0.w >= 0) ? r2.x : PlayerBrightness.x;
	r0.z = (-r0.z >= 0) ? r2.x : ColorShiftScalar.x;
	r0.y = r0.y * r0.w;
	r2 = tex2D(HDRSampler, i.texcoord.xy);
	r0.y = (-abs(r2.w) >= 0) ? 1 : r0.y;
	r2.xyz = r2.xyz * r0.yyy + -globalFogColorN.xyz;
	o.w = r2.w;
	r0.xyw = r0.xxx * r2.xyz + globalFogColorN.xyz;
	r1.w = dot(r0.xyw, float3(0.2125, 0.7154, 0.0721));
	r2.x = saturate(dot(r1.xyz, 1));
	r3.yzw = r1.xyz;
	r3.x = -r2.x + 1;
	r1.x = dot(r3, gAdrenoFXVars);
	r1.x = r1.x * deSatContrastGamma.x;
	r2.xyz = lerp(r1.www, r0.xyw, r1.xxx);
	r0.x = r1.w * ColorShift.w;
	r0.x = r0.z * r0.x;
	r0.yzw = ColorShift.xyz * -r0.xxx + r2.xyz;
	r1.xyz = r0.xxx * ColorShift.xyz;
	r0.x = saturate(r0.x);
	o.xyz = r0.xxx * r0.yzw + r1.xyz;

	return o;
}
