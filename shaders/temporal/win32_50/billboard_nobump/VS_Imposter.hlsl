cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
};

cbuffer ImposterData : register(b4)
{
	float3 imposterDir[8] : packoffset(c0);
	float3 imposterWorldX : packoffset(c8);
	float3 imposterWorldY : packoffset(c9);
	float3 imposterWorldZ : packoffset(c10);
};

struct VS_IN
{
	float3 position : POSITION;
	float3 normal : NORMAL;
	float4 color : COLOR;
	float2 texcoord : TEXCOORD;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 color : COLOR;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
	float4 texcoord4 : TEXCOORD4;
	float3 texcoord5 : TEXCOORD5;
	float3 texcoord6 : TEXCOORD6;
	float3 texcoord7 : TEXCOORD7;
	float3 temporalPrevious : TEXCOORD15;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	float3 Temporal_b4_o0_imposterDir[8] : packoffset(c13);
	float3 Temporal_b4_o128_imposterWorldX : packoffset(c21);
	float3 Temporal_b4_o144_imposterWorldY : packoffset(c22);
	float3 Temporal_b4_o160_imposterWorldZ : packoffset(c23);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	int4 r3;
	int4 r4;
	int4 r5;
	int4 r6;
	int4 r7;
	float4 r8;
	r0 = asint(i.position.y * gWorldViewProj[1]);
	r0 = asint(i.position.x * gWorldViewProj[0] + asfloat(r0));
	r0 = asint(i.position.z * gWorldViewProj[2] + asfloat(r0));
	o.sv_position = asfloat(r0) + gWorldViewProj[3];
	o.color = i.color;
	r0.xyz = asint(i.normal.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.577350259, 0.577350259, -0.577350259)));
	r1.x = asfloat(r0.w) + 1;
	r0.w = asint(dot(asfloat(r0.yxz), float3(0.577350259, -0.577350259, -0.577350259)));
	r1.y = asfloat(r0.w) + 1;
	r0.w = asint(dot(asfloat(r0.xyz), float3(-0.577350259, -0.577350259, -0.577350259)));
	r0.z = asint(dot(asfloat(r0.xyz), float3(0.577350259, -0.577350259, -0.577350259)));
	r2 = asfloat(r0.xyxy) * float4(1, 1, -1, -1) + float4(1, 1, 1, 1);
	r1.zw = asfloat(r0.wz) + float2(1, 1);
	r0 = asint(max(r1, r2));
	r0.xy = asint(max(asfloat(r0.yw), asfloat(r0.xz)));
	r0.x = asint(max(asfloat(r0.y), asfloat(r0.x)));
	r3 = (r1 >= asfloat(r0.x)) ? -1 : 0;
	r0 = (r2 >= asfloat(r0.x)) ? -1 : 0;
	r4 = (r3 != 0) ? int4(0, 0, 0, 0) : int4(1065353216, 1065353216, 1065353216, 1065353216);
	r3 = r3 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r4 = asint(r1 * asfloat(r4));
	r5 = (r0 != 0) ? int4(0, 0, 0, 0) : int4(1065353216, 1065353216, 1065353216, 1065353216);
	r0 = r0 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r5 = asint(r2 * asfloat(r5));
	r6 = asint(max(asfloat(r4), asfloat(r5)));
	r6.xy = asint(max(asfloat(r6.yw), asfloat(r6.xz)));
	r6.x = asint(max(asfloat(r6.y), asfloat(r6.x)));
	r7 = (asfloat(r5) >= asfloat(r6.x)) ? -1 : 0;
	r6 = (asfloat(r4) >= asfloat(r6.x)) ? -1 : 0;
	r8 = (r7 != 0) ? float4(0, 0, 0, 0) : float4(1, 1, 1, 1);
	r7 = r7 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r5 = asint(asfloat(r5) * r8);
	r8 = (r6 != 0) ? float4(0, 0, 0, 0) : float4(1, 1, 1, 1);
	r6 = r6 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r4 = asint(asfloat(r4) * r8);
	r8 = max(asfloat(r4), asfloat(r5));
	r8.xy = max(r8.yw, r8.xz);
	r8.x = max(r8.y, r8.x);
	r4 = (asfloat(r4) >= r8.x) ? -1 : 0;
	r5 = (asfloat(r5) >= r8.x) ? -1 : 0;
	r5 = r5 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r5 = asint(r2 * asfloat(r5));
	r5.x = asint(dot(asfloat(r5), float4(1, 1, 1, 1)));
	r4 = r4 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r4 = asint(r1 * asfloat(r4));
	r4.x = asint(dot(asfloat(r4), float4(1, 1, 1, 1)));
	r4.x = asint(asfloat(r4.x) + asfloat(r5.x));
	r5 = asint(r1 * asfloat(r6));
	r1 = r1 * asfloat(r3);
	o.texcoord2 = asfloat(r3);
	r1.x = dot(r1, float4(1, 1, 1, 1));
	o.texcoord4 = asfloat(r6);
	r1.y = dot(asfloat(r5), float4(1, 1, 1, 1));
	r3 = asint(r2 * asfloat(r7));
	o.texcoord3 = asfloat(r7);
	r2 = r2 * asfloat(r0);
	o.texcoord1 = asfloat(r0);
	r0.x = asint(dot(r2, float4(1, 1, 1, 1)));
	r0.z = asint(r1.x + asfloat(r0.x));
	r0.x = asint(dot(asfloat(r3), float4(1, 1, 1, 1)));
	r0.w = asint(r1.y + asfloat(r0.x));
	r0.xy = asint(-(asfloat(r4.xx)) + asfloat(r0.zw));
	r0.z = asint(asfloat(r0.y) + asfloat(r0.x));
	r0.z = asint(1 / asfloat(r0.z));
	o.texcoord.zw = asfloat(r0.zz) * asfloat(r0.xy);
	o.texcoord.xy = i.texcoord.xy * float2(1, -1) + float2(0, 1);
	o.texcoord5 = imposterWorldX.xyz;
	o.texcoord6 = imposterWorldY.xyz;
	o.texcoord7 = imposterWorldZ.xyz;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	int4 r0;
	float4 r1;
	float4 r2;
	int4 r3;
	int4 r4;
	int4 r5;
	int4 r6;
	int4 r7;
	float4 r8;
	r0 = asint(i.position.y * Temporal_b0_o128_gWorldViewProj[1]);
	r0 = asint(i.position.x * Temporal_b0_o128_gWorldViewProj[0] + asfloat(r0));
	r0 = asint(i.position.z * Temporal_b0_o128_gWorldViewProj[2] + asfloat(r0));
	o.sv_position = asfloat(r0) + Temporal_b0_o128_gWorldViewProj[3];
	o.color = i.color;
	r0.xyz = asint(i.normal.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r0.w = asint(dot(asfloat(r0.xyz), asfloat(r0.xyz)));
	r0.w = asint(rsqrt(asfloat(r0.w)));
	r0.xyz = asint(asfloat(r0.www) * asfloat(r0.xyz));
	r0.w = asint(dot(asfloat(r0.xyz), float3(0.577350259, 0.577350259, -0.577350259)));
	r1.x = asfloat(r0.w) + 1;
	r0.w = asint(dot(asfloat(r0.yxz), float3(0.577350259, -0.577350259, -0.577350259)));
	r1.y = asfloat(r0.w) + 1;
	r0.w = asint(dot(asfloat(r0.xyz), float3(-0.577350259, -0.577350259, -0.577350259)));
	r0.z = asint(dot(asfloat(r0.xyz), float3(0.577350259, -0.577350259, -0.577350259)));
	r2 = asfloat(r0.xyxy) * float4(1, 1, -1, -1) + float4(1, 1, 1, 1);
	r1.zw = asfloat(r0.wz) + float2(1, 1);
	r0 = asint(max(r1, r2));
	r0.xy = asint(max(asfloat(r0.yw), asfloat(r0.xz)));
	r0.x = asint(max(asfloat(r0.y), asfloat(r0.x)));
	r3 = (r1 >= asfloat(r0.x)) ? -1 : 0;
	r0 = (r2 >= asfloat(r0.x)) ? -1 : 0;
	r4 = (r3 != 0) ? int4(0, 0, 0, 0) : int4(1065353216, 1065353216, 1065353216, 1065353216);
	r3 = r3 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r4 = asint(r1 * asfloat(r4));
	r5 = (r0 != 0) ? int4(0, 0, 0, 0) : int4(1065353216, 1065353216, 1065353216, 1065353216);
	r0 = r0 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r5 = asint(r2 * asfloat(r5));
	r6 = asint(max(asfloat(r4), asfloat(r5)));
	r6.xy = asint(max(asfloat(r6.yw), asfloat(r6.xz)));
	r6.x = asint(max(asfloat(r6.y), asfloat(r6.x)));
	r7 = (asfloat(r5) >= asfloat(r6.x)) ? -1 : 0;
	r6 = (asfloat(r4) >= asfloat(r6.x)) ? -1 : 0;
	r8 = (r7 != 0) ? float4(0, 0, 0, 0) : float4(1, 1, 1, 1);
	r7 = r7 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r5 = asint(asfloat(r5) * r8);
	r8 = (r6 != 0) ? float4(0, 0, 0, 0) : float4(1, 1, 1, 1);
	r6 = r6 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r4 = asint(asfloat(r4) * r8);
	r8 = max(asfloat(r4), asfloat(r5));
	r8.xy = max(r8.yw, r8.xz);
	r8.x = max(r8.y, r8.x);
	r4 = (asfloat(r4) >= r8.x) ? -1 : 0;
	r5 = (asfloat(r5) >= r8.x) ? -1 : 0;
	r5 = r5 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r5 = asint(r2 * asfloat(r5));
	r5.x = asint(dot(asfloat(r5), float4(1, 1, 1, 1)));
	r4 = r4 & int4(1065353216, 1065353216, 1065353216, 1065353216);
	r4 = asint(r1 * asfloat(r4));
	r4.x = asint(dot(asfloat(r4), float4(1, 1, 1, 1)));
	r4.x = asint(asfloat(r4.x) + asfloat(r5.x));
	r5 = asint(r1 * asfloat(r6));
	r1 = r1 * asfloat(r3);
	o.texcoord2 = asfloat(r3);
	r1.x = dot(r1, float4(1, 1, 1, 1));
	o.texcoord4 = asfloat(r6);
	r1.y = dot(asfloat(r5), float4(1, 1, 1, 1));
	r3 = asint(r2 * asfloat(r7));
	o.texcoord3 = asfloat(r7);
	r2 = r2 * asfloat(r0);
	o.texcoord1 = asfloat(r0);
	r0.x = asint(dot(r2, float4(1, 1, 1, 1)));
	r0.z = asint(r1.x + asfloat(r0.x));
	r0.x = asint(dot(asfloat(r3), float4(1, 1, 1, 1)));
	r0.w = asint(r1.y + asfloat(r0.x));
	r0.xy = asint(-(asfloat(r4.xx)) + asfloat(r0.zw));
	r0.z = asint(asfloat(r0.y) + asfloat(r0.x));
	r0.z = asint(1 / asfloat(r0.z));
	o.texcoord.zw = asfloat(r0.zz) * asfloat(r0.xy);
	o.texcoord.xy = i.texcoord.xy * float2(1, -1) + float2(0, 1);
	o.texcoord5 = Temporal_b4_o128_imposterWorldX.xyz;
	o.texcoord6 = Temporal_b4_o144_imposterWorldY.xyz;
	o.texcoord7 = Temporal_b4_o160_imposterWorldZ.xyz;

	return o;
}

VS_OUT main(VS_IN i)
{
    VS_OUT o = TemporalCurrent(i);
    o.temporalPrevious = float3(0, 0, -1);

    [branch] if (TemporalState.x > 0)
    {
        o.temporalPrevious = TemporalVertexPrevious(i).sv_position.xyw;
    }
    return o;
}
