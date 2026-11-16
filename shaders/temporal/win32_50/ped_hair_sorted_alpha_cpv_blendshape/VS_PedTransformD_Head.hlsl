cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

cbuffer rage_globals : register(b5)
{
	float4 globalScalars : packoffset(c0);
	float4 globalScalars2 : packoffset(c1);
	float4 globalScalars3 : packoffset(c2);
	float4 globalScalars4 : packoffset(c3);
};

cbuffer PedWind : register(b4)
{
	float4 gWindParams : packoffset(c0);
	float4 AirResist : packoffset(c1);
	float WindStr : packoffset(c2);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float4 color1 : COLOR1;
	float2 texcoord : TEXCOORD;
	float4 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float2 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
	float3 texcoord7 : TEXCOORD7;
	float3 temporalPrevious : TEXCOORD15;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	row_major float4x4 Temporal_b0_o192_gViewInverse : packoffset(c13);
	float4 Temporal_b5_o0_globalScalars : packoffset(c17);
	float4 Temporal_b5_o16_globalScalars2 : packoffset(c18);
	float4 Temporal_b5_o32_globalScalars3 : packoffset(c19);
	float4 Temporal_b5_o48_globalScalars4 : packoffset(c20);
	float4 Temporal_b4_o0_gWindParams : packoffset(c21);
	float4 Temporal_b4_o16_AirResist : packoffset(c22);
	float Temporal_b4_o32_WindStr : packoffset(c23);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float3 r2;
	r0.x = globalScalars3.z + 0.00000999999975;
	r0.y = globalScalars4.z + 0.00000999999975;
	r0.z = 0.00000999999975;
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r0.x = dot(r0.xyz, i.normal.xyz);
	r0.x = max(r0.x, 0.25);
	r0.x = min(r0.x, 1);
	r0.y = i.color1.z * AirResist.w;
	r0.y = r0.y * 5;
	r1.z = -(r0.y);
	r1.xy = -(i.color1.xx);
	r0.yzw = r1.xyz * i.normal.xyz;
	r0.xyz = r0.xxx * r0.yzw;
	r0.w = saturate(WindStr);
	r1.x = AirResist.w * 0.00999999978 + 1;
	r1.yz = i.position.xy * float2(6, 4);
	r1.y = globalScalars3.y * r1.x + r1.y;
	r1.x = r1.x * globalScalars3.y;
	r1.z = r1.x * gWindParams.w + r1.z;
	r1.yz = sin(r1.yz);
	r0.w = r0.w * abs(r1.y);
	r1.y = dot(i.position.xzy, float3(10, 10, 10));
	r1.x = r1.x * gWindParams.z + r1.y;
	r1.x = sin(r1.x);
	r0.w = r0.w * abs(r1.x);
	r0.w = abs(r1.z) * r0.w;
	r0.xyz = r0.xyz * r0.www + i.position.xyz;
	r1 = r0.y * gWorldViewProj[1];
	r1 = r0.x * gWorldViewProj[0] + r1;
	r0 = r0.z * gWorldViewProj[2] + r1;
	r0 = r0 + gWorldViewProj[3];
	o.sv_position = r0;
	o.texcoord1.w = r0.w;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * gWorld[1].xyz;
	r0.xyz = i.normal.xxx * gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord1.xyz = r0.xyz;
	o.texcoord2.y = i.color.y * globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	r1.xyz = i.position.yyy * gWorld[1].xyz;
	r1.xyz = i.position.xxx * gWorld[0].xyz + r1.xyz;
	r1.xyz = i.position.zzz * gWorld[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + gWorld[3].xyz;
	o.texcoord3 = -(r1.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r1.xyz;
	r1.xyz = i.tangent.yyy * gWorld[1].xyz;
	r1.xyz = i.tangent.xxx * gWorld[0].xyz + r1.xyz;
	r1.xyz = i.tangent.zzz * gWorld[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord4 = r1.xyz;
	r2 = r0.yzx * r1.zxy;
	r0.xyz = r1.yzx * r0.zxy + -(r2.xyz);
	o.texcoord5.xyz = r0.xyz * i.tangent.www;
	o.texcoord5.w = i.tangent.w;

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float3 r2;
	r0.x = Temporal_b5_o32_globalScalars3.z + 0.00000999999975;
	r0.y = Temporal_b5_o48_globalScalars4.z + 0.00000999999975;
	r0.z = 0.00000999999975;
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r0.x = dot(r0.xyz, i.normal.xyz);
	r0.x = max(r0.x, 0.25);
	r0.x = min(r0.x, 1);
	r0.y = i.color1.z * Temporal_b4_o16_AirResist.w;
	r0.y = r0.y * 5;
	r1.z = -(r0.y);
	r1.xy = -(i.color1.xx);
	r0.yzw = r1.xyz * i.normal.xyz;
	r0.xyz = r0.xxx * r0.yzw;
	r0.w = saturate(Temporal_b4_o32_WindStr);
	r1.x = Temporal_b4_o16_AirResist.w * 0.00999999978 + 1;
	r1.yz = i.position.xy * float2(6, 4);
	r1.y = Temporal_b5_o32_globalScalars3.y * r1.x + r1.y;
	r1.x = r1.x * Temporal_b5_o32_globalScalars3.y;
	r1.z = r1.x * Temporal_b4_o0_gWindParams.w + r1.z;
	r1.yz = sin(r1.yz);
	r0.w = r0.w * abs(r1.y);
	r1.y = dot(i.position.xzy, float3(10, 10, 10));
	r1.x = r1.x * Temporal_b4_o0_gWindParams.z + r1.y;
	r1.x = sin(r1.x);
	r0.w = r0.w * abs(r1.x);
	r0.w = abs(r1.z) * r0.w;
	r0.xyz = r0.xyz * r0.www + i.position.xyz;
	r1 = r0.y * Temporal_b0_o128_gWorldViewProj[1];
	r1 = r0.x * Temporal_b0_o128_gWorldViewProj[0] + r1;
	r0 = r0.z * Temporal_b0_o128_gWorldViewProj[2] + r1;
	r0 = r0 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r0;
	o.texcoord1.w = r0.w;
	o.texcoord = i.texcoord.xy;
	r0.xyz = i.normal.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyz = i.normal.xxx * Temporal_b0_o0_gWorld[0].xyz + r0.xyz;
	r0.xyz = i.normal.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	o.texcoord1.xyz = r0.xyz;
	o.texcoord2.y = i.color.y * Temporal_b5_o16_globalScalars2.w;
	o.texcoord2.xzw = i.color.xzw;
	r1.xyz = i.position.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r1.xyz = i.position.xxx * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	r1.xyz = i.position.zzz * Temporal_b0_o0_gWorld[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + Temporal_b0_o0_gWorld[3].xyz;
	o.texcoord3 = -(r1.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = r1.xyz;
	r1.xyz = i.tangent.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r1.xyz = i.tangent.xxx * Temporal_b0_o0_gWorld[0].xyz + r1.xyz;
	r1.xyz = i.tangent.zzz * Temporal_b0_o0_gWorld[2].xyz + r1.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord4 = r1.xyz;
	r2 = r0.yzx * r1.zxy;
	r0.xyz = r1.yzx * r0.zxy + -(r2.xyz);
	o.texcoord5.xyz = r0.xyz * i.tangent.www;
	o.texcoord5.w = i.tangent.w;

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
