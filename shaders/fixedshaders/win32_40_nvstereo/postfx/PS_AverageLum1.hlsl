cbuffer _Globals : register(b1)
{
	float4 TexelSize : packoffset(c98);
};

SamplerState CurLumSampler : register(s0);
Texture2D CurLumSampler_tex : register(t0);

struct PS_IN
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float2 texcoord1 : TEXCOORD1;
	float2 texcoord2 : TEXCOORD2;
};

float4 main(PS_IN i) : SV_Target
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	r0 = TexelSize.xyxy * float4(1.5, -1.5, 1.5, -0.5) + i.texcoord.xyxy;
	r1 = CurLumSampler_tex.Sample(CurLumSampler, r0.xy);
	r0 = CurLumSampler_tex.Sample(CurLumSampler, r0.zw);
	r0.x = r0.x + r1.x;
	r1 = TexelSize.xyxy * float4(1.5, 0.5, 1.5, 1.5) + i.texcoord.xyxy;
	r2 = CurLumSampler_tex.Sample(CurLumSampler, r1.xy);
	r1 = CurLumSampler_tex.Sample(CurLumSampler, r1.zw);
	r0.x = r0.x + r2.x;
	r0.x = r1.x + r0.x;
	r1 = TexelSize.xyxy * float4(0.5, -1.5, 0.5, -0.5) + i.texcoord.xyxy;
	r2 = CurLumSampler_tex.Sample(CurLumSampler, r1.xy);
	r1 = CurLumSampler_tex.Sample(CurLumSampler, r1.zw);
	r0.x = r0.x + r2.x;
	r0.x = r1.x + r0.x;
	r1 = TexelSize.xyxy * float4(0.5, 0.5, 0.5, 1.5) + i.texcoord.xyxy;
	r2 = CurLumSampler_tex.Sample(CurLumSampler, r1.xy);
	r1 = CurLumSampler_tex.Sample(CurLumSampler, r1.zw);
	r0.x = r0.x + r2.x;
	r0.x = r1.x + r0.x;
	r1 = TexelSize.xyxy * float4(-0.5, -1.5, -0.5, -0.5) + i.texcoord.xyxy;
	r2 = CurLumSampler_tex.Sample(CurLumSampler, r1.xy);
	r1 = CurLumSampler_tex.Sample(CurLumSampler, r1.zw);
	r0.x = r0.x + r2.x;
	r0.x = r1.x + r0.x;
	r1 = TexelSize.xyxy * float4(-0.5, 0.5, -0.5, 1.5) + i.texcoord.xyxy;
	r2 = CurLumSampler_tex.Sample(CurLumSampler, r1.xy);
	r1 = CurLumSampler_tex.Sample(CurLumSampler, r1.zw);
	r0.x = r0.x + r2.x;
	r0.x = r1.x + r0.x;
	r1 = TexelSize.xyxy * float4(-1.5, -1.5, -1.5, -0.5) + i.texcoord.xyxy;
	r2 = CurLumSampler_tex.Sample(CurLumSampler, r1.xy);
	r1 = CurLumSampler_tex.Sample(CurLumSampler, r1.zw);
	r0.x = r0.x + r2.x;
	r0.x = r1.x + r0.x;
	r1 = TexelSize.xyxy * float4(-1.5, 0.5, -1.5, 1.5) + i.texcoord.xyxy;
	r2 = CurLumSampler_tex.Sample(CurLumSampler, r1.xy);
	r1 = CurLumSampler_tex.Sample(CurLumSampler, r1.zw);
	r0.x = r0.x + r2.x;
	r0.x = r1.x + r0.x;
	o = r0.x * float4(0.0625, 0.0625, 0.0625, 0.0625);

	return o;
}
