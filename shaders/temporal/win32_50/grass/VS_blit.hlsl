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
	float3 texcoord : TEXCOORD;
};

VS_OUT main(float3 position : POSITION)
{
	VS_OUT o;

	o.sv_position.xyz = position.xyz;
	o.sv_position.w = 1;
	o.texcoord = _fakedGrassNormal.xyz;

	return o;
}
