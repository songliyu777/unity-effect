Shader "Unlit/LitShader"
{
    Properties {
		_Color ("Color", Color) = (1, 1, 1, 1)
	}
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
			
            //#pragma target 3.5
            #pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling
            #pragma prefer_hlsl2glsl gles
			#pragma vertex UnlitPassVertex
			#pragma fragment UnlitPassFragment
			
			#include "LitShader.hlsl"
			
			ENDHLSL
        }
    }
}
