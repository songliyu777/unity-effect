Shader "UnityEffects/ShadowReplace"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
		_AlphaCutoff ("Cutoff", float) = 0.5
	}
	Subshader 
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		// Pass {
    	// 	Lighting Off Fog { Mode off } 
		// 	SetTexture [_MainTex] {
		// 		constantColor (1,1,1,1)
		// 		combine constant
		// 	}
		// }
		Pass
        {
            ZWrite Off
            Cull Off

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _AlphaCutoff;
            
			struct appdata {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

            struct v2f
            {
                float4 pos : POSITION;
				float2 texcoord : TEXCOORD0;
            };
            
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            float4 frag(v2f i) :SV_TARGET
            {
				fixed4 col = tex2D(_MainTex, i.texcoord);
				clip(col.a - _AlphaCutoff);
                return 1;
            }
            
            ENDCG
        }    
	}
	Subshader 
	{
		Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest"}
		Pass {
    		Lighting Off Fog { Mode off } 
			AlphaTest Greater [_AlphaCutoff]
			Color [_TintColor]
			SetTexture [_MainTex] {
				constantColor (1,1,1,1)
				combine constant, previous * texture
			}
		}    
	}
	Subshader 
	{
		Tags { "RenderType"="TransparentAlphaBlended" "Queue"="Transparent"}
		Pass {
    		Lighting Off Fog { Mode off } 
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Color [_TintColor]
			SetTexture [_MainTex] {
				constantColor (1,1,1,1)
				combine constant, previous * texture
			}
		}    
	}
	Subshader 
	{
		Tags { "RenderType"="TransparentAlphaAdditve" "Queue"="Transparent"}
		Pass {
    		Lighting Off Fog { Mode off } 
			ZWrite Off
			Blend SrcAlpha One
			Color [_TintColor]
			SetTexture [_MainTex] {
				constantColor (1,1,1,1)
				combine constant, previous * texture
			}
		}    
	}
}
