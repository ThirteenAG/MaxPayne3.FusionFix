cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

cbuffer CachePedParam : register(b4)
{
	float ArmourStrength : packoffset(c0);
	float reflectivePower : packoffset(c0.y);
	float3 specMapReflectMask : packoffset(c1);
	float fresnelRolloff : packoffset(c1.w);
	float bumpiness : packoffset(c2);
	float displacementScale : packoffset(c2.y);
	float specularFactor : packoffset(c2.z);
	float3 specMapIntMask : packoffset(c3);
	float4 specMapExpMask : packoffset(c4);
	float4 matMaterialColorScale : packoffset(c5);
	float4 gBloodData : packoffset(c6);
};

cbuffer BloodHitData : register(b7)
{
	float4 gBloodHeadHits[4] : packoffset(c0);
	float4 gBloodHeadCentreMass : packoffset(c4);
};

struct VS_IN
{
	float3 position : POSITION;
	float4 color : COLOR;
	float4 texcoord : TEXCOORD;
	float4 normal : NORMAL;
	float4 tangent : TANGENT;
	float3 position1 : POSITION1;
	float3 normal1 : NORMAL1;
	float4 tangent1 : TANGENT1;
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float3 texcoord3 : TEXCOORD3;
	float3 texcoord4 : TEXCOORD4;
	float4 texcoord5 : TEXCOORD5;
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
	row_major float4x4 Temporal_b0_o192_gViewInverse : packoffset(c13);
	float Temporal_b4_o0_ArmourStrength : packoffset(c17);
	float Temporal_b4_o4_reflectivePower : packoffset(c18);
	float3 Temporal_b4_o16_specMapReflectMask : packoffset(c19);
	float Temporal_b4_o28_fresnelRolloff : packoffset(c20);
	float Temporal_b4_o32_bumpiness : packoffset(c21);
	float Temporal_b4_o36_displacementScale : packoffset(c22);
	float Temporal_b4_o40_specularFactor : packoffset(c23);
	float3 Temporal_b4_o48_specMapIntMask : packoffset(c24);
	float4 Temporal_b4_o64_specMapExpMask : packoffset(c25);
	float4 Temporal_b4_o80_matMaterialColorScale : packoffset(c26);
	float4 Temporal_b4_o96_gBloodData : packoffset(c27);
	float4 Temporal_b7_o0_gBloodHeadHits[4] : packoffset(c28);
	float4 Temporal_b7_o64_gBloodHeadCentreMass : packoffset(c32);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float3 r2;
	float3 r3;
	r0.xyz = i.position.xyz + i.position1.xyz;
	r1.xyz = -(r0.xyz) + gBloodHeadHits[0].xyz;
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = sqrt(r0.w);
	r0.w = -(r0.w) + 0.0500000007;
	r0.w = r0.w * 0.239999995;
	r0.w = max(r0.w, 0);
	r1.xyz = -(r0.xyz) + gBloodHeadHits[1].xyz;
	r1.x = dot(r1.xyz, r1.xyz);
	r1.x = sqrt(r1.x);
	r1.x = -(r1.x) + 0.0500000007;
	r1.x = r1.x * 0.239999995;
	r0.w = max(r0.w, r1.x);
	r1.xyz = -(r0.xyz) + gBloodHeadHits[2].xyz;
	r1.x = dot(r1.xyz, r1.xyz);
	r1.x = sqrt(r1.x);
	r1.x = -(r1.x) + 0.0500000007;
	r1.x = r1.x * 0.239999995;
	r0.w = max(r0.w, r1.x);
	r1.xyz = -(r0.xyz) + gBloodHeadHits[3].xyz;
	r1.x = dot(r1.xyz, r1.xyz);
	r1.x = sqrt(r1.x);
	r1.x = -(r1.x) + 0.0500000007;
	r1.x = r1.x * 0.239999995;
	r0.w = max(r0.w, r1.x);
	r1.xyz = -(r0.xyz) + gBloodHeadCentreMass.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = rsqrt(r1.w);
	r1.xyz = r1.www * r1.xyz;
	r1.xyz = r0.www * r1.xyz;
	r0.xyz = r1.xyz * gBloodData.xxx + r0.xyz;
	r1 = r0.y * gWorldViewProj[1];
	r1 = r0.x * gWorldViewProj[0] + r1;
	r1 = r0.z * gWorldViewProj[2] + r1;
	r1 = r1 + gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord = i.texcoord;
	r1.xyz = i.normal.xyz + i.normal1.xyz;
	r2 = r1.yyy * gWorld[1].xyz;
	r1.xyw = r1.xxx * gWorld[0].xyz + r2.xyz;
	r1.xyz = r1.zzz * gWorld[2].xyz + r1.xyw;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord2 = i.color;
	r2 = r0.yyy * gWorld[1].xyz;
	r0.xyw = r0.xxx * gWorld[0].xyz + r2.xyz;
	r0.xyz = r0.zzz * gWorld[2].xyz + r0.xyw;
	r0.xyz = r0.xyz + gWorld[3].xyz;
	r2 = -(r0.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r0.xyz;
	o.texcoord3 = r2.xyz;
	r0 = i.tangent + i.tangent1;
	r3 = r0.yyy * gWorld[1].xyz;
	r3 = r0.xxx * gWorld[0].xyz + r3.xyz;
	r0.xyz = r0.zzz * gWorld[2].xyz + r3.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r0.xyz, r0.xyz);
	r1.w = rsqrt(r1.w);
	r0.xyz = r0.xyz * r1.www;
	o.texcoord4 = r0.xyz;
	r3 = r1.yzx * r0.zxy;
	r3 = r0.yzx * r1.zxy + -(r3.xyz);
	o.texcoord6.z = dot(r1.xyz, r2.xyz);
	o.texcoord6.x = dot(r0.xyz, r2.xyz);
	r0.xyz = r0.www * r3.xyz;
	o.texcoord5 = r0;
	o.texcoord6.y = dot(r0.xyz, r2.xyz);

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float3 r2;
	float3 r3;
	r0.xyz = i.position.xyz + i.position1.xyz;
	r1.xyz = -(r0.xyz) + Temporal_b7_o0_gBloodHeadHits[0].xyz;
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = sqrt(r0.w);
	r0.w = -(r0.w) + 0.0500000007;
	r0.w = r0.w * 0.239999995;
	r0.w = max(r0.w, 0);
	r1.xyz = -(r0.xyz) + Temporal_b7_o0_gBloodHeadHits[1].xyz;
	r1.x = dot(r1.xyz, r1.xyz);
	r1.x = sqrt(r1.x);
	r1.x = -(r1.x) + 0.0500000007;
	r1.x = r1.x * 0.239999995;
	r0.w = max(r0.w, r1.x);
	r1.xyz = -(r0.xyz) + Temporal_b7_o0_gBloodHeadHits[2].xyz;
	r1.x = dot(r1.xyz, r1.xyz);
	r1.x = sqrt(r1.x);
	r1.x = -(r1.x) + 0.0500000007;
	r1.x = r1.x * 0.239999995;
	r0.w = max(r0.w, r1.x);
	r1.xyz = -(r0.xyz) + Temporal_b7_o0_gBloodHeadHits[3].xyz;
	r1.x = dot(r1.xyz, r1.xyz);
	r1.x = sqrt(r1.x);
	r1.x = -(r1.x) + 0.0500000007;
	r1.x = r1.x * 0.239999995;
	r0.w = max(r0.w, r1.x);
	r1.xyz = -(r0.xyz) + Temporal_b7_o64_gBloodHeadCentreMass.xyz;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r1.xyz, r1.xyz);
	r1.w = rsqrt(r1.w);
	r1.xyz = r1.www * r1.xyz;
	r1.xyz = r0.www * r1.xyz;
	r0.xyz = r1.xyz * Temporal_b4_o96_gBloodData.xxx + r0.xyz;
	r1 = r0.y * Temporal_b0_o128_gWorldViewProj[1];
	r1 = r0.x * Temporal_b0_o128_gWorldViewProj[0] + r1;
	r1 = r0.z * Temporal_b0_o128_gWorldViewProj[2] + r1;
	r1 = r1 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r1;
	o.texcoord1.w = r1.w;
	o.texcoord = i.texcoord;
	r1.xyz = i.normal.xyz + i.normal1.xyz;
	r2 = r1.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r1.xyw = r1.xxx * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r1.xyz = r1.zzz * Temporal_b0_o0_gWorld[2].xyz + r1.xyw;
	r1.xyz = r1.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	o.texcoord1.xyz = r1.xyz;
	o.texcoord2 = i.color;
	r2 = r0.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r0.xyw = r0.xxx * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r0.xyz = r0.zzz * Temporal_b0_o0_gWorld[2].xyz + r0.xyw;
	r0.xyz = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;
	r2 = -(r0.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = r0.xyz;
	o.texcoord3 = r2.xyz;
	r0 = i.tangent + i.tangent1;
	r3 = r0.yyy * Temporal_b0_o0_gWorld[1].xyz;
	r3 = r0.xxx * Temporal_b0_o0_gWorld[0].xyz + r3.xyz;
	r0.xyz = r0.zzz * Temporal_b0_o0_gWorld[2].xyz + r3.xyz;
	r0.xyz = r0.xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r1.w = dot(r0.xyz, r0.xyz);
	r1.w = rsqrt(r1.w);
	r0.xyz = r0.xyz * r1.www;
	o.texcoord4 = r0.xyz;
	r3 = r1.yzx * r0.zxy;
	r3 = r0.yzx * r1.zxy + -(r3.xyz);
	o.texcoord6.z = dot(r1.xyz, r2.xyz);
	o.texcoord6.x = dot(r0.xyz, r2.xyz);
	r0.xyz = r0.www * r3.xyz;
	o.texcoord5 = r0;
	o.texcoord6.y = dot(r0.xyz, r2.xyz);

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
