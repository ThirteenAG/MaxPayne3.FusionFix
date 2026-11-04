sampler2D AdapLumSampler : register(s1);
sampler2D BloomSampler : register(s10);
sampler2D DeathSampler : register(s15);
sampler2D GBufferTextureSamplerSSAODepth : register(s4);
sampler2D HDRSampler : register(s5);
float4 SunRaysParams : register(c192);
float4 TexelSize : register(c88);
float4 ToneMapParams : register(c144);
float4 lightrayParams : register(c191);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	r0.xyw = float3(-0.5, 0.5, 0.25);
	r1 = TexelSize.zwzw * r0.xxxy + texcoord.xyxy;
	r2 = tex2D(HDRSampler, r1.xy);
	r1 = tex2D(HDRSampler, r1.zw);
	r1.xyz = r1.xyz + r2.xyz;
	r2 = TexelSize.zwzw * r0.yyyx + texcoord.xyxy;
	r3 = tex2D(HDRSampler, r2.xy);
	r2 = tex2D(HDRSampler, r2.zw);
	r1.xyz = r1.xyz + r3.xyz;
	r1.xyz = r2.xyz + r1.xyz;
	r1.xyz = r1.xyz * SunRaysParams.xyz;
	r1.xyz = r1.xyz * 4;
	r2 = TexelSize.xyxy * r0.xxxy + texcoord.xyxy;
	r3 = tex2D(GBufferTextureSamplerSSAODepth, r2.xy);
	r2 = tex2D(GBufferTextureSamplerSSAODepth, r2.zw);
	r0.z = r2.w + r3.w;
	r2 = TexelSize.xyxy * r0.yyyx + texcoord.xyxy;
	r3 = tex2D(GBufferTextureSamplerSSAODepth, r2.xy);
	r2 = tex2D(GBufferTextureSamplerSSAODepth, r2.zw);
	r0.x = r0.z + r3.w;
	r0.x = r2.w + r0.x;
	r0.yzw = r0.www * lightrayParams.xyz;
	r0.xyz = r0.yzw * r0.xxx + r1.xyz;
	r1 = tex2D(AdapLumSampler, 0);
	r0.w = 1 / r1.x;
	r0.w = r0.w * ToneMapParams.y;
	r0.w = 1 / r0.w;
	r1 = tex2D(BloomSampler, texcoord.xy);
	r2.xyz = max(r1.xyz, 0);
	r1.xyz = min(r2.xyz, 11);
	r1.xyz = ToneMapParams.xxx * -r0.www + r1.xyz;
	r2.xyz = max(r1.xyz, 0);
	r1 = tex2D(DeathSampler, texcoord.xy);
	r0.w = -r1.x + 1;
	r1.x = -ToneMapParams.z + ToneMapParams.w;
	r0.w = r0.w * r1.x + ToneMapParams.z;
	r0.w = 1 / r0.w;
	o.xyz = r0.xyz * r0.www + r2.xyz;
	o.w = 1;

	return o;
}
