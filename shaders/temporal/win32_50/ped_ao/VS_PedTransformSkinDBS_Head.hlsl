cbuffer rage_bonemtx : register(b1)
{
	row_major float3x4 gBoneMtx[40] : packoffset(c0);
};

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
	float4 blendweight : BLENDWEIGHT;
	float4 blendindices : BLENDINDICES;
	float4 texcoord : TEXCOORD;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float4 color : COLOR;
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
	row_major float3x4 Temporal_b1_o0_gBoneMtx[40] : packoffset(c1);
	row_major float4x4 Temporal_b0_o0_gWorld : packoffset(c121);
	row_major float4x4 Temporal_b0_o64_gWorldView : packoffset(c125);
	row_major float4x4 Temporal_b0_o128_gWorldViewProj : packoffset(c129);
	row_major float4x4 Temporal_b0_o192_gViewInverse : packoffset(c133);
	float Temporal_b4_o0_ArmourStrength : packoffset(c137);
	float Temporal_b4_o4_reflectivePower : packoffset(c138);
	float3 Temporal_b4_o16_specMapReflectMask : packoffset(c139);
	float Temporal_b4_o28_fresnelRolloff : packoffset(c140);
	float Temporal_b4_o32_bumpiness : packoffset(c141);
	float Temporal_b4_o36_displacementScale : packoffset(c142);
	float Temporal_b4_o40_specularFactor : packoffset(c143);
	float3 Temporal_b4_o48_specMapIntMask : packoffset(c144);
	float4 Temporal_b4_o64_specMapExpMask : packoffset(c145);
	float4 Temporal_b4_o80_matMaterialColorScale : packoffset(c146);
	float4 Temporal_b4_o96_gBloodData : packoffset(c147);
	float4 Temporal_b7_o0_gBloodHeadHits[4] : packoffset(c148);
	float4 Temporal_b7_o64_gBloodHeadCentreMass : packoffset(c152);
};


VS_OUT TemporalCurrent(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	float4 r6;
	r0.xyz = i.position.xyz + i.position1.xyz;
	r1.xyz = asint(-(r0.xyz) + gBloodHeadHits[0].xyz);
	r0.w = dot(asfloat(r1.xyz), asfloat(r1.xyz));
	r0.w = sqrt(r0.w);
	r0.w = -(r0.w) + 0.0500000007;
	r0.w = r0.w * 0.239999995;
	r0.w = max(r0.w, 0);
	r1.xyz = asint(-(r0.xyz) + gBloodHeadHits[1].xyz);
	r1.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.x = asint(sqrt(asfloat(r1.x)));
	r1.x = asint(-(asfloat(r1.x)) + 0.0500000007);
	r1.x = asint(asfloat(r1.x) * 0.239999995);
	r0.w = max(r0.w, asfloat(r1.x));
	r1.xyz = asint(-(r0.xyz) + gBloodHeadHits[2].xyz);
	r1.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.x = asint(sqrt(asfloat(r1.x)));
	r1.x = asint(-(asfloat(r1.x)) + 0.0500000007);
	r1.x = asint(asfloat(r1.x) * 0.239999995);
	r0.w = max(r0.w, asfloat(r1.x));
	r1.xyz = asint(-(r0.xyz) + gBloodHeadHits[3].xyz);
	r1.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.x = asint(sqrt(asfloat(r1.x)));
	r1.x = asint(-(asfloat(r1.x)) + 0.0500000007);
	r1.x = asint(asfloat(r1.x) * 0.239999995);
	r0.w = max(r0.w, asfloat(r1.x));
	r1.xyz = asint(-(r0.xyz) + gBloodHeadCentreMass.xyz);
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r1.xyz = asint(r0.www * asfloat(r1.xyz));
	r0.xyz = asfloat(r1.xyz) * gBloodData.xxx + r0.xyz;
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * gBoneMtx[r1.y / 3][1];
	r2 = gBoneMtx[r1.x / 3][1] * i.blendweight.x + r2;
	r2 = gBoneMtx[r1.z / 3][1] * i.blendweight.z + r2;
	r2 = gBoneMtx[r1.w / 3][1] * i.blendweight.w + r2;
	r0.w = 1;
	r2.w = dot(r2, r0);
	r3 = r2.w * gWorldViewProj[1];
	r4 = r2.www * gWorld[1].xyz;
	r5 = i.blendweight.y * gBoneMtx[r1.y / 3][0];
	r5 = gBoneMtx[r1.x / 3][0] * i.blendweight.x + r5;
	r5 = gBoneMtx[r1.z / 3][0] * i.blendweight.z + r5;
	r5 = gBoneMtx[r1.w / 3][0] * i.blendweight.w + r5;
	r2.w = dot(r5, r0);
	r3 = r2.w * gWorldViewProj[0] + r3;
	r4 = r2.www * gWorld[0].xyz + r4.xyz;
	r6 = i.blendweight.y * gBoneMtx[r1.y / 3][2];
	r6 = gBoneMtx[r1.x / 3][2] * i.blendweight.x + r6;
	r6 = gBoneMtx[r1.z / 3][2] * i.blendweight.z + r6;
	r1 = asint(gBoneMtx[r1.w / 3][2] * i.blendweight.w + r6);
	r0.x = dot(asfloat(r1), r0);
	r3 = r0.x * gWorldViewProj[2] + r3;
	r0.xyz = r0.xxx * gWorld[2].xyz + r4.xyz;
	r0.xyz = r0.xyz + gWorld[3].xyz;
	r3 = r3 + gWorldViewProj[3];
	o.sv_position = r3;
	o.texcoord = i.texcoord;
	r3.xyz = i.normal.xyz + i.normal1.xyz;
	r0.w = dot(r2.xyz, r3.xyz);
	r4 = r0.www * gWorld[1].xyz;
	r0.w = dot(r5.xyz, r3.xyz);
	r1.w = asint(dot(asfloat(r1.xyz), r3.xyz));
	r3.xyz = r0.www * gWorld[0].xyz + r4.xyz;
	r3.xyz = asfloat(r1.www) * gWorld[2].xyz + r3.xyz;
	o.texcoord1 = r3;
	o.texcoord2 = i.color;
	r4 = -(r0.xyz) + gViewInverse[3].xyz;
	o.texcoord7 = r0.xyz;
	o.texcoord3 = r4.xyz;
	r0 = i.tangent + i.tangent1;
	r1.w = asint(dot(r2.xyz, r0.xyz));
	r2.xyz = asfloat(r1.www) * gWorld[1].xyz;
	r1.w = asint(dot(r5.xyz, r0.xyz));
	r2.xyz = asfloat(r1.www) * gWorld[0].xyz + r2.xyz;
	r0.x = dot(asfloat(r1.xyz), r0.xyz);
	r0.xyz = r0.xxx * gWorld[2].xyz + r2.xyz;
	o.texcoord4 = r0.xyz;
	r1.xyz = asint(r3.yzx * r0.zxy);
	r1.xyz = asint(r0.yzx * r3.zxy + -(asfloat(r1.xyz)));
	o.texcoord6.z = dot(r3.xyz, r4.xyz);
	o.texcoord6.x = dot(r0.xyz, r4.xyz);
	r0.xyz = r0.www * asfloat(r1.xyz);
	o.texcoord5 = r0;
	o.texcoord6.y = dot(r0.xyz, r4.xyz);

	return o;
}

VS_OUT TemporalVertexPrevious(VS_IN i)
{
	VS_OUT o;

	float4 r0;
	int4 r1;
	float4 r2;
	float4 r3;
	float3 r4;
	float4 r5;
	float4 r6;
	r0.xyz = i.position.xyz + i.position1.xyz;
	r1.xyz = asint(-(r0.xyz) + Temporal_b7_o0_gBloodHeadHits[0].xyz);
	r0.w = dot(asfloat(r1.xyz), asfloat(r1.xyz));
	r0.w = sqrt(r0.w);
	r0.w = -(r0.w) + 0.0500000007;
	r0.w = r0.w * 0.239999995;
	r0.w = max(r0.w, 0);
	r1.xyz = asint(-(r0.xyz) + Temporal_b7_o0_gBloodHeadHits[1].xyz);
	r1.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.x = asint(sqrt(asfloat(r1.x)));
	r1.x = asint(-(asfloat(r1.x)) + 0.0500000007);
	r1.x = asint(asfloat(r1.x) * 0.239999995);
	r0.w = max(r0.w, asfloat(r1.x));
	r1.xyz = asint(-(r0.xyz) + Temporal_b7_o0_gBloodHeadHits[2].xyz);
	r1.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.x = asint(sqrt(asfloat(r1.x)));
	r1.x = asint(-(asfloat(r1.x)) + 0.0500000007);
	r1.x = asint(asfloat(r1.x) * 0.239999995);
	r0.w = max(r0.w, asfloat(r1.x));
	r1.xyz = asint(-(r0.xyz) + Temporal_b7_o0_gBloodHeadHits[3].xyz);
	r1.x = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.x = asint(sqrt(asfloat(r1.x)));
	r1.x = asint(-(asfloat(r1.x)) + 0.0500000007);
	r1.x = asint(asfloat(r1.x) * 0.239999995);
	r0.w = max(r0.w, asfloat(r1.x));
	r1.xyz = asint(-(r0.xyz) + Temporal_b7_o64_gBloodHeadCentreMass.xyz);
	r1.xyz = asint(asfloat(r1.xyz) + float3(0.00000999999975, 0.00000999999975, 0.00000999999975));
	r1.w = asint(dot(asfloat(r1.xyz), asfloat(r1.xyz)));
	r1.w = asint(rsqrt(asfloat(r1.w)));
	r1.xyz = asint(asfloat(r1.www) * asfloat(r1.xyz));
	r1.xyz = asint(r0.www * asfloat(r1.xyz));
	r0.xyz = asfloat(r1.xyz) * Temporal_b4_o96_gBloodData.xxx + r0.xyz;
	r1 = asint(i.blendindices * float4(255.001953, 255.001953, 255.001953, 255.001953));
	r1 = (int4)asfloat(r1);
	r1 = r1 * int4(3, 3, 3, 3);
	r2 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][1];
	r2 = Temporal_b1_o0_gBoneMtx[r1.x / 3][1] * i.blendweight.x + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.z / 3][1] * i.blendweight.z + r2;
	r2 = Temporal_b1_o0_gBoneMtx[r1.w / 3][1] * i.blendweight.w + r2;
	r0.w = 1;
	r2.w = dot(r2, r0);
	r3 = r2.w * Temporal_b0_o128_gWorldViewProj[1];
	r4 = r2.www * Temporal_b0_o0_gWorld[1].xyz;
	r5 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][0];
	r5 = Temporal_b1_o0_gBoneMtx[r1.x / 3][0] * i.blendweight.x + r5;
	r5 = Temporal_b1_o0_gBoneMtx[r1.z / 3][0] * i.blendweight.z + r5;
	r5 = Temporal_b1_o0_gBoneMtx[r1.w / 3][0] * i.blendweight.w + r5;
	r2.w = dot(r5, r0);
	r3 = r2.w * Temporal_b0_o128_gWorldViewProj[0] + r3;
	r4 = r2.www * Temporal_b0_o0_gWorld[0].xyz + r4.xyz;
	r6 = i.blendweight.y * Temporal_b1_o0_gBoneMtx[r1.y / 3][2];
	r6 = Temporal_b1_o0_gBoneMtx[r1.x / 3][2] * i.blendweight.x + r6;
	r6 = Temporal_b1_o0_gBoneMtx[r1.z / 3][2] * i.blendweight.z + r6;
	r1 = asint(Temporal_b1_o0_gBoneMtx[r1.w / 3][2] * i.blendweight.w + r6);
	r0.x = dot(asfloat(r1), r0);
	r3 = r0.x * Temporal_b0_o128_gWorldViewProj[2] + r3;
	r0.xyz = r0.xxx * Temporal_b0_o0_gWorld[2].xyz + r4.xyz;
	r0.xyz = r0.xyz + Temporal_b0_o0_gWorld[3].xyz;
	r3 = r3 + Temporal_b0_o128_gWorldViewProj[3];
	o.sv_position = r3;
	o.texcoord = i.texcoord;
	r3.xyz = i.normal.xyz + i.normal1.xyz;
	r0.w = dot(r2.xyz, r3.xyz);
	r4 = r0.www * Temporal_b0_o0_gWorld[1].xyz;
	r0.w = dot(r5.xyz, r3.xyz);
	r1.w = asint(dot(asfloat(r1.xyz), r3.xyz));
	r3.xyz = r0.www * Temporal_b0_o0_gWorld[0].xyz + r4.xyz;
	r3.xyz = asfloat(r1.www) * Temporal_b0_o0_gWorld[2].xyz + r3.xyz;
	o.texcoord1 = r3;
	o.texcoord2 = i.color;
	r4 = -(r0.xyz) + Temporal_b0_o192_gViewInverse[3].xyz;
	o.texcoord7 = r0.xyz;
	o.texcoord3 = r4.xyz;
	r0 = i.tangent + i.tangent1;
	r1.w = asint(dot(r2.xyz, r0.xyz));
	r2.xyz = asfloat(r1.www) * Temporal_b0_o0_gWorld[1].xyz;
	r1.w = asint(dot(r5.xyz, r0.xyz));
	r2.xyz = asfloat(r1.www) * Temporal_b0_o0_gWorld[0].xyz + r2.xyz;
	r0.x = dot(asfloat(r1.xyz), r0.xyz);
	r0.xyz = r0.xxx * Temporal_b0_o0_gWorld[2].xyz + r2.xyz;
	o.texcoord4 = r0.xyz;
	r1.xyz = asint(r3.yzx * r0.zxy);
	r1.xyz = asint(r0.yzx * r3.zxy + -(asfloat(r1.xyz)));
	o.texcoord6.z = dot(r3.xyz, r4.xyz);
	o.texcoord6.x = dot(r0.xyz, r4.xyz);
	r0.xyz = r0.www * asfloat(r1.xyz);
	o.texcoord5 = r0;
	o.texcoord6.y = dot(r0.xyz, r4.xyz);

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
