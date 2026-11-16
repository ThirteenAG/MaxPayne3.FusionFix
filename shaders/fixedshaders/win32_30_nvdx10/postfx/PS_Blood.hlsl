sampler2D AdapLumSampler : register(s1);
sampler2D BloomSampler : register(s10);
sampler2D BlurSampler : register(s7);
float BurnoutLimit : register(c147);
float2 Exposures : register(c142);
sampler2D HDRSampler : register(s5);
float4 ToneMapParams : register(c144);
float4 deSatContrastGamma : register(c46);
float3 g_BloodColor : register(c205);
float4 g_BloodSplatParams : register(c206);

struct PS_IN
{
	float2 texcoord : TEXCOORD;
	float2 texcoord1 : TEXCOORD1;
	float4 color : COLOR;
};

float4 main(PS_IN i) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	r0.x = saturate(1.1 + -i.color.w);
	r0.x = 1 / r0.x;
	r0.y = 1 + i.color.w;
	r1 = tex2D(HDRSampler, i.texcoord.xy);
	r0.z = -r1.x + 1;
	r0.w = r0.z * r0.z + -i.color.w;
	r0.w = saturate(r0.w * 1.4);
	r1.x = pow(r0.w, r0.y);
	o.w = r0.x * r1.x;
	r0.x = abs(r0.z) + 1E-05;
	r0.y = saturate(r0.z * g_BloodSplatParams.y);
	r0.y = -r0.y + 1;
	r1.x = pow(r0.y, g_BloodSplatParams.z);
	r0.z = 1E-05;
	r0.y = r0.z + g_BloodSplatParams.x;
	r1.y = pow(r0.x, r0.y);
	r0.xyz = g_BloodColor.xyz;
	r2.x = dot(float3(0.4124564, 0.3575761, 0.1804375), r0.xyz);
	r2.z = dot(float3(0.0193339, 0.119192, 0.9503041), r0.xyz);
	r2.y = dot(float3(0.2126729, 0.7151522, 0.072175), r0.xyz);
	r0.x = 1 / r2.y;
	r3 = tex2D(AdapLumSampler, 0);
	r0.x = r0.x * r3.x;
	r0.y = r3.x + 1E-06;
	r0.y = 1 / r0.y;
	r0.y = r0.y * ToneMapParams.y;
	r0.xzw = r0.xxx * r2.xyz;
	r2.x = dot(float3(3.2404542, -1.5371385, -0.4985314), r0.xzw);
	r2.y = dot(float3(-0.969266, 1.8760108, 0.041556), r0.xzw);
	r2.z = dot(float3(0.0556434, -0.2040259, 1.0572252), r0.xzw);
	r0.xzw = lerp(r2.xyz, g_BloodColor.xyz, r1.yyy);
	r2 = tex2D(BlurSampler, i.texcoord.xy);
	r1.yz = r2.xy * 2 + i.texcoord1.xy;
	r1.yz = r1.yz + -1;
	r2 = tex2D(BloomSampler, r1.yz);
	r0.xzw = r2.xyz * r1.xxx + r0.xzw;
	r0.xzw = r0.xzw * Exposures.xxx;
	r1.x = dot(r0.xzw, float3(0.2125, 0.7154, 0.0721));
	r1.y = r0.y * r1.x;
	r0.y = r1.x * r0.y + 1;
	r0.y = 1 / r0.y;
	r1.x = BurnoutLimit.x * BurnoutLimit.x;
	r1.x = 1 / r1.x;
	r1.x = r1.y * r1.x + 1;
	r1.x = r1.x * r1.y;
	r0.y = r0.y * r1.x;
	r0.xyz = r0.yyy * r0.xzw;
	r0.w = saturate(dot(r0.xyz, float3(0.2125, 0.7154, 0.0721)));
	r0.w = r0.w + 1.01E-05;
	r1.w = -0.99999;
	r1.x = r1.w + deSatContrastGamma.z;
	r2.x = pow(r0.w, r1.x);
	r0.w = min(r2.x, 65000);
	o.xyz = r0.www * r0.xyz;

	return o;
}
