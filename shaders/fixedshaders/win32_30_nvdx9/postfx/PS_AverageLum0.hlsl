sampler2D CurLumSampler : register(s0);
float4 TexelSize : register(c88);

float4 main(float2 texcoord : TEXCOORD) : COLOR
{
	float4 o;

	float4 r0;
	float4 r1;
	float4 r2;
	float4 r3;
	r0.xy = TexelSize.xy;
	r1 = r0.xyxy * float4(1.5, -1.5, 1.5, -0.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r1.xy);
	r1 = tex2D(CurLumSampler, r1.zw);
	r1.xyz = r1.xyz + r2.xyz;
	r2 = r0.xyxy * float4(1.5, 0.5, 1.5, 1.5) + texcoord.xyxy;
	r3 = tex2D(CurLumSampler, r2.xy);
	r2 = tex2D(CurLumSampler, r2.zw);
	r1.xyz = r1.xyz + r3.xyz;
	r1.xyz = r2.xyz + r1.xyz;
	r2 = r0.xyxy * float4(0.5, -1.5, 0.5, -0.5) + texcoord.xyxy;
	r3 = tex2D(CurLumSampler, r2.xy);
	r2 = tex2D(CurLumSampler, r2.zw);
	r1.xyz = r1.xyz + r3.xyz;
	r1.xyz = r2.xyz + r1.xyz;
	r2 = r0.xyxy * float4(0.5, 0.5, 0.5, 1.5) + texcoord.xyxy;
	r3 = tex2D(CurLumSampler, r2.xy);
	r2 = tex2D(CurLumSampler, r2.zw);
	r1.xyz = r1.xyz + r3.xyz;
	r1.xyz = r2.xyz + r1.xyz;
	r2 = r0.xyxy * float4(-0.5, -1.5, -0.5, -0.5) + texcoord.xyxy;
	r3 = tex2D(CurLumSampler, r2.xy);
	r2 = tex2D(CurLumSampler, r2.zw);
	r1.xyz = r1.xyz + r3.xyz;
	r1.xyz = r2.xyz + r1.xyz;
	r2 = r0.xyxy * float4(-0.5, 0.5, -0.5, 1.5) + texcoord.xyxy;
	r3 = tex2D(CurLumSampler, r2.xy);
	r2 = tex2D(CurLumSampler, r2.zw);
	r1.xyz = r1.xyz + r3.xyz;
	r1.xyz = r2.xyz + r1.xyz;
	r2 = r0.xyxy * float4(-1.5, -1.5, -1.5, -0.5) + texcoord.xyxy;
	r3 = tex2D(CurLumSampler, r2.xy);
	r2 = tex2D(CurLumSampler, r2.zw);
	r1.xyz = r1.xyz + r3.xyz;
	r1.xyz = r2.xyz + r1.xyz;
	r0 = r0.xyxy * float4(-1.5, 0.5, -1.5, 1.5) + texcoord.xyxy;
	r2 = tex2D(CurLumSampler, r0.xy);
	r0 = tex2D(CurLumSampler, r0.zw);
	r1.xyz = r1.xyz + r2.xyz;
	r0.xyz = r0.xyz + r1.xyz;
	r1.x = 1 / r0.x;
	r1.y = 1 / r0.y;
	r1.z = 1 / r0.z;
	r0.xyz = (-abs(r1.xyz) >= 0) ? 16 : r0.xyz;
	r0.x = dot(r0.xyz, float3(0.2125, 0.7154, 0.0721));
	o = r0.x * 0.0625;

	return o;
}
