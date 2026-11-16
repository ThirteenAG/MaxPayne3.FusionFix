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
	r0.z = r1.x + r2.x;
	r1 = r0.xyxy * float4(1.5, 0.5, 1.5, 1.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.x;
	r0.z = r1.x + r0.z;
	r1 = r0.xyxy * float4(0.5, -1.5, 0.5, -0.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.x;
	r0.z = r1.x + r0.z;
	r1 = r0.xyxy * float4(0.5, 0.5, 0.5, 1.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.x;
	r0.z = r1.x + r0.z;
	r1 = r0.xyxy * float4(-0.5, -1.5, -0.5, -0.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.x;
	r0.z = r1.x + r0.z;
	r1 = r0.xyxy * float4(-0.5, 0.5, -0.5, 1.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.x;
	r0.z = r1.x + r0.z;
	r1 = r0.xyxy * float4(-1.5, -1.5, -1.5, -0.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.z = r0.z + r2.x;
	r0.z = r1.x + r0.z;
	r1 = r0.xyxy * float4(-1.5, 0.5, -1.5, 1.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r0.x = r0.z + r2.x;
	r0.x = r1.x + r0.x;
	o = r0.x * 0.0625;

	return o;
}
