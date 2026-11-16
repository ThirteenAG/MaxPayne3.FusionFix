sampler2D BlurSampler : register(s7);
float4 ColorCorrectBottomOffset : register(c44);
float4 ColorCorrectBottomOffsetScreenEdge : register(c67);
float4 ColorCorrectTopAndPedReflectScale : register(c43);
float4 ColorCorrectTopScreenEdge : register(c66);
float4 ColorShift : register(c45);
sampler2D HDRSampler : register(s5);
float4 deSatContrastGamma : register(c46);
float4 gAdrenoFXVars : register(c68);
float4 globalScalars4 : register(c51);
float4 globalScreenSize : register(c41);

struct PS_IN
{
	float2 texcoord : TEXCOORD;
	float2 vpos : VPOS;
};

float4 main(PS_IN i) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	float4 r4;
	r0 = ColorCorrectTopScreenEdge;
	r0.w = r0.w + -ColorCorrectBottomOffsetScreenEdge.w;
	r0.w = (r0.w >= 0) ? -r0.w : -0;
	r1.x = r0.w + ColorCorrectTopScreenEdge.w;
	r1.x = 1 / r1.x;
	r1.y = 1 / globalScreenSize.x;
	r2.x = r1.y * i.vpos.x;
	r1.y = 1 / globalScreenSize.y;
	r2.y = r1.y * i.vpos.y;
	r1.yz = r2.xy + -0.5;
	r1.y = dot(r1.yz, r1.yz) + 0;
	r1.y = rsqrt(r1.y);
	r1.y = 1 / r1.y;
	r0.w = r0.w + r1.y;
	r1.x = saturate(r1.x * r0.w);
	r0.w = (r0.w >= 0) ? r1.x : 0;
	r1 = tex2D(HDRSampler, i.texcoord.xy);
	r3 = tex2D(BlurSampler, i.texcoord.xy);
	r1.xyz = r1.xyz + r3.xyz;
	r1.xyz = r1.xyz + -2;
	r2.x = gAdrenoFXVars.x;
	r1.w = r2.x * deSatContrastGamma.x;
	r2.x = dot(r1.xyz, float3(0.2125, 0.7154, 0.0721));
	r3.xyz = lerp(r2.xxx, r1.xyz, r1.www);
	r1.x = r2.x * ColorCorrectBottomOffset.w;
	r1.y = r2.x * ColorShift.w;
	r2.xzw = globalScalars4.yzw * -r1.xxx + r3.xyz;
	r3.xyz = ColorShift.xyz * -r1.yyy + r3.xyz;
	r4.xyz = r1.xxx * globalScalars4.yzw;
	r1.x = saturate(r1.x);
	r1.xzw = r1.xxx * r2.xzw + r4.xyz;
	r0.xyz = r2.yyy * ColorCorrectBottomOffsetScreenEdge.xyz + r0.xyz;
	r4.xyz = ColorCorrectBottomOffset.xyz;
	r2.xyz = r2.yyy * r4.xyz + ColorCorrectTopAndPedReflectScale.xyz;
	r4.xyz = r0.xyz * r1.xzw;
	r0.xyz = r1.yyy * ColorShift.xyz;
	r1.y = saturate(r1.y);
	r0.xyz = r1.yyy * r3.xyz + r0.xyz;
	r1.xyz = r2.xyz * r0.xyz;
	r4.w = 1;
	r1.w = 1;
	r2 = lerp(r1, r4, r0.w);
	o = (ColorCorrectTopScreenEdge.w >= 0) ? r2 : r1;

	return o;
}
