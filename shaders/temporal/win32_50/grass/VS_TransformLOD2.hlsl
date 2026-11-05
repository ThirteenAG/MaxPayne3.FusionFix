cbuffer rage_matrices : register(b0)
{
	row_major float4x4 gWorld : packoffset(c0);
	row_major float4x4 gWorldView : packoffset(c4);
	row_major float4x4 gWorldViewProj : packoffset(c8);
	row_major float4x4 gViewInverse : packoffset(c12);
};

cbuffer PlanetAttributes : register(b4)
{
	row_major float4x4 matGrassTransform : packoffset(c0);
	float4 plantColor : packoffset(c4);
	float4 groundColor : packoffset(c5);
	float3 vecCameraPos : packoffset(c6);
	float3 vecPlayerPos : packoffset(c7);
	float4 _dimensionLOD2 : packoffset(c8);
	float2 _vecCollParams : packoffset(c9);
	float4 _vecVehCollB : packoffset(c10);
	float4 _vecVehCollM : packoffset(c11);
	float4 _vecVehCollR : packoffset(c12);
	float4 fadeAlphaDistUmTimer : packoffset(c13);
	float4 fadeAlphaLOD1Dist : packoffset(c14);
	float4 fadeAlphaLOD2Dist : packoffset(c15);
	float4 uMovementParams : packoffset(c16);
	float4 _fakedGrassNormal : packoffset(c17);
};

struct VS_OUT
{
	float4 sv_position : SV_Position;
	float4 texcoord : TEXCOORD;
	float4 texcoord1 : TEXCOORD1;
	float4 texcoord2 : TEXCOORD2;
	float4 texcoord3 : TEXCOORD3;
	float3 temporalPrevious : TEXCOORD15;
};

struct TemporalInput
{
	float2 texcoord : TEXCOORD;
};

cbuffer TemporalPrevious : register(b13)
{
	float4 TemporalState : packoffset(c0);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c1);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c5);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c9);
	row_major float4x4 Temporal_b0_o192_gViewInverse : packoffset(c13);
	row_major float4x4 Temporal_b4_o0_matGrassTransform : packoffset(c17);
	float4 Temporal_b4_o64_plantColor : packoffset(c21);
	float4 Temporal_b4_o80_groundColor : packoffset(c22);
	float3 Temporal_b4_o96_vecCameraPos : packoffset(c23);
	float3 Temporal_b4_o112_vecPlayerPos : packoffset(c24);
	float4 Temporal_b4_o128__dimensionLOD2 : packoffset(c25);
	float2 Temporal_b4_o144__vecCollParams : packoffset(c26);
	float4 Temporal_b4_o160__vecVehCollB : packoffset(c27);
	float4 Temporal_b4_o176__vecVehCollM : packoffset(c28);
	float4 Temporal_b4_o192__vecVehCollR : packoffset(c29);
	float4 Temporal_b4_o208_fadeAlphaDistUmTimer : packoffset(c30);
	float4 Temporal_b4_o224_fadeAlphaLOD1Dist : packoffset(c31);
	float4 Temporal_b4_o240_fadeAlphaLOD2Dist : packoffset(c32);
	float4 Temporal_b4_o256_uMovementParams : packoffset(c33);
	float4 Temporal_b4_o272__fakedGrassNormal : packoffset(c34);
};


VS_OUT TemporalCurrent(TemporalInput i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float2 r2;
	r0.xyz = gViewInverse[0].xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r0.xyz = r0.xyz * _dimensionLOD2.xxx;
	r1.xyz = -(gViewInverse[1].xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	r1.xyz = r1.xyz * _dimensionLOD2.yyy;
	r2 = i.texcoord.xy + float2(-0.5, 0);
	r1.xyz = r1.xyz * r2.yyy;
	r0.xyz = r2.xxx * r0.xyz + r1.xyz;
	r1.xyz = r0.yyy * matGrassTransform[1].xyz;
	r0.xyw = r0.xxx * matGrassTransform[0].xyz + r1.xyz;
	r0.z = r0.z + _dimensionLOD2.y;
	r0.xyz = r0.zzz * matGrassTransform[2].xyz + r0.xyw;
	r0.xyz = r0.xyz + matGrassTransform[3].xyz;
	r1 = r0.y * gWorldViewProj[1];
	r1 = r0.x * gWorldViewProj[0] + r1;
	r1 = r0.z * gWorldViewProj[2] + r1;
	o.sv_position = r1 + gWorldViewProj[3];
	r1.xy = r0.xy + -(vecCameraPos.xy);
	o.texcoord2.xyz = r0.xyz;
	r0.x = dot(r1.xy, r1.xy);
	r0.xy = saturate(r0.xx * fadeAlphaLOD2Dist.yw + fadeAlphaLOD2Dist.xz);
	r0.x = -(r0.x) + 1;
	r0.x = r0.y * r0.x;
	r0.y = i.texcoord.y * 0.5 + -(r0.y);
	r0.y = r0.y + 1;
	o.texcoord3.w = min(r0.y, 1);
	o.texcoord.w = r0.x * plantColor.w;
	o.texcoord.xyz = plantColor.xyz;
	o.texcoord1.xyz = _fakedGrassNormal.xyz;
	o.texcoord1.w = i.texcoord.x;
	r0.x = i.texcoord.y * 0.5 + 0.5;
	o.texcoord2.w = min(r0.x, 1);
	o.texcoord3.xyz = groundColor.xyz;

	return o;
}

VS_OUT TemporalVertexPrevious(TemporalInput i)
{
	VS_OUT o;

	float4 r0;
	float4 r1;
	float2 r2;
	r0.xyz = Temporal_b0_o192_gViewInverse[0].xyz + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r0.xyz, r0.xyz);
	r0.w = rsqrt(r0.w);
	r0.xyz = r0.www * r0.xyz;
	r0.xyz = r0.xyz * Temporal_b4_o128__dimensionLOD2.xxx;
	r1.xyz = -(Temporal_b0_o192_gViewInverse[1].xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975);
	r0.w = dot(r1.xyz, r1.xyz);
	r0.w = rsqrt(r0.w);
	r1.xyz = r0.www * r1.xyz;
	r1.xyz = r1.xyz * Temporal_b4_o128__dimensionLOD2.yyy;
	r2 = i.texcoord.xy + float2(-0.5, 0);
	r1.xyz = r1.xyz * r2.yyy;
	r0.xyz = r2.xxx * r0.xyz + r1.xyz;
	r1.xyz = r0.yyy * Temporal_b4_o0_matGrassTransform[1].xyz;
	r0.xyw = r0.xxx * Temporal_b4_o0_matGrassTransform[0].xyz + r1.xyz;
	r0.z = r0.z + Temporal_b4_o128__dimensionLOD2.y;
	r0.xyz = r0.zzz * Temporal_b4_o0_matGrassTransform[2].xyz + r0.xyw;
	r0.xyz = r0.xyz + Temporal_b4_o0_matGrassTransform[3].xyz;
	r1 = r0.y * Temporal_b0_o128_gWorldViewProj[1];
	r1 = r0.x * Temporal_b0_o128_gWorldViewProj[0] + r1;
	r1 = r0.z * Temporal_b0_o128_gWorldViewProj[2] + r1;
	o.sv_position = r1 + Temporal_b0_o128_gWorldViewProj[3];
	r1.xy = r0.xy + -(Temporal_b4_o96_vecCameraPos.xy);
	o.texcoord2.xyz = r0.xyz;
	r0.x = dot(r1.xy, r1.xy);
	r0.xy = saturate(r0.xx * Temporal_b4_o240_fadeAlphaLOD2Dist.yw + Temporal_b4_o240_fadeAlphaLOD2Dist.xz);
	r0.x = -(r0.x) + 1;
	r0.x = r0.y * r0.x;
	r0.y = i.texcoord.y * 0.5 + -(r0.y);
	r0.y = r0.y + 1;
	o.texcoord3.w = min(r0.y, 1);
	o.texcoord.w = r0.x * Temporal_b4_o64_plantColor.w;
	o.texcoord.xyz = Temporal_b4_o64_plantColor.xyz;
	o.texcoord1.xyz = Temporal_b4_o272__fakedGrassNormal.xyz;
	o.texcoord1.w = i.texcoord.x;
	r0.x = i.texcoord.y * 0.5 + 0.5;
	o.texcoord2.w = min(r0.x, 1);
	o.texcoord3.xyz = Temporal_b4_o80_groundColor.xyz;

	return o;
}

VS_OUT main(TemporalInput i)
{
    VS_OUT o = TemporalCurrent(i);
    o.temporalPrevious = float3(0, 0, -1);

    [branch] if (TemporalState.x > 0)
    {
        o.temporalPrevious = TemporalVertexPrevious(i).sv_position.xyw;
    }
    return o;
}
