#ifndef MYRP_LIT_INCLUDED
	#define MYRP_LIT_INCLUDED

	#define UNITY_MATRIX_M unity_ObjectToWorld //如果开启instancing会被改写成 unity_ObjectToWorldArray

	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

	CBUFFER_START(UnityPerFrame)
	float4x4 unity_MatrixVP;
	CBUFFER_END
	CBUFFER_START(UnityPerDraw)
	float4x4 unity_ObjectToWorld;
	CBUFFER_END
	// CBUFFER_START(UnityPerMaterial)
	// 	float4 _Color;
	// CBUFFER_END
	UNITY_INSTANCING_BUFFER_START(PerInstance)
	UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
	UNITY_INSTANCING_BUFFER_END(PerInstance)

	#define MAX_VISIBLE_LIGHTS 4

	CBUFFER_START(_LightBuffer)
	float4 _VisibleLightColors[MAX_VISIBLE_LIGHTS];
	float4 _VisibleLightDirectionsOrPositions[MAX_VISIBLE_LIGHTS];
	float4 _VisibleLightAttenuations[MAX_VISIBLE_LIGHTS];
	CBUFFER_END

	struct VertexInput {
		float4 pos : POSITION;
		float3 normal : NORMAL;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};
	
	struct VertexOutput {
		float4 clipPos : SV_POSITION;
		float3 normal : TEXCOORD0;
		float3 worldPos : TEXCOORD1;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	float3 DiffuseLight (int index, float3 normal, float3 worldPos) {
		float3 lightColor = _VisibleLightColors[index].rgb;
		float4 lightPositionOrDirection = _VisibleLightDirectionsOrPositions[index];
		float4 lightAttenuation = _VisibleLightAttenuations[index];
		//这里综合处理点光源和方向光，方向光w为0，方向就是光源方向，点光源w为1方向就是物体与光源方向。
		float3 lightVector = lightPositionOrDirection.xyz - worldPos * lightPositionOrDirection.w;
		float3 lightDirection = normalize(lightVector);
		float diffuse = saturate(dot(normal, lightDirection));

		//光照范围衰减
		float rangeFade = dot(lightVector, lightVector) * lightAttenuation.x;
		rangeFade = saturate(1.0 - rangeFade * rangeFade);
		rangeFade *= rangeFade;

		//光照强度会随着距离衰减 1/(dxd)
		float distanceSqr = max(dot(lightVector, lightVector), 0.00001);

		diffuse *= rangeFade / distanceSqr;
		return diffuse * lightColor;
	}

	VertexOutput UnlitPassVertex (VertexInput input) {
		VertexOutput output;
		UNITY_SETUP_INSTANCE_ID(input);
		UNITY_TRANSFER_INSTANCE_ID(input, output);
		float4 worldPos = mul(UNITY_MATRIX_M, float4(input.pos.xyz, 1.0));
		output.clipPos = mul(unity_MatrixVP, worldPos);
		output.normal = mul((float3x3)UNITY_MATRIX_M, input.normal);
		output.worldPos = worldPos.xyz;
		return output;
	}
	
	float4 UnlitPassFragment (VertexOutput input) : SV_TARGET {
		UNITY_SETUP_INSTANCE_ID(input);
		input.normal = normalize(input.normal);
		float3 albedo = UNITY_ACCESS_INSTANCED_PROP(PerInstance, _Color).rgb;
		
		float3 diffuseLight = 0;
		for (int i = 0; i < MAX_VISIBLE_LIGHTS; i++) {
			diffuseLight += DiffuseLight(i, input.normal, input.worldPos);
		}
		float3 color = diffuseLight * albedo;
		return float4(color, 1);
	}
	
#endif // MYRP_LIT_INCLUDED
