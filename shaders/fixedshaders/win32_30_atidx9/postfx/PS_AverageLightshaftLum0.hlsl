sampler2D CurLumSampler : register(s0);
float4 TexelSize : register(c88);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	float3 r0;
	float4 r1;
	float4 r2;
	r0.xy = TexelSize.xy;
	r1 = r0.xyxy * float4(1.5, -1.5, 1.5, -0.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r1.w + r2.w;
	r1 = r0.xyxy * float4(1.5, 0.5, 1.5, 1.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.w;
	r0.z = r1.w + r0.z;
	r1 = r0.xyxy * float4(0.5, -1.5, 0.5, -0.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.w;
	r0.z = r1.w + r0.z;
	r1 = r0.xyxy * float4(0.5, 0.5, 0.5, 1.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.w;
	r0.z = r1.w + r0.z;
	r1 = r0.xyxy * float4(-0.5, -1.5, -0.5, -0.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.w;
	r0.z = r1.w + r0.z;
	r1 = r0.xyxy * float4(-0.5, 0.5, -0.5, 1.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.w;
	r0.z = r1.w + r0.z;
	r1 = r0.xyxy * float4(-1.5, -1.5, -1.5, -0.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.w;
	r0.z = r1.w + r0.z;
	r1 = r0.xyxy * float4(-1.5, 0.5, -1.5, 1.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.x = r0.z + r2.w;
	o = r1.w + r0.x;

	return o;
}
