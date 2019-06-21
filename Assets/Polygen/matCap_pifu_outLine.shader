// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// MatCap Shader, (c) 2013 Jean Moreno

Shader "MatCap/Vertex/matCap_pifu_outLine"
{
	Properties
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}

		_NoiseTex ("Noise", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_Fade ("Color fade", Range(0,1)) = 0.99
		
		_Density ("Density", Float) = 1.0
		_Intensity ("Intensity", Range(0,1)) = 0.0
		_GlowStartColor ("Glow Start Color", Color) = (1, 0.2, 0.8, 1)
		_GlowEndColor ("Glow End Color", Color) = (1, 0.2, 0.8, 1)
		_GlowWidth ("Glow Width", Range(0,1)) = 0.1
		_GlowFadeWidth ("Glow Fade Width", Range(0,1)) = 0.1

        [Space(50)]
		_MatCap ("MatCap (RGB)", 2D) = "white" {}
		_MatCapVal("_MatCapVal",Range(0.1,1))=0.55
		_MatCapColor("MatCapColor",Color)=(0.46,0.46,0.46,1)

		_RampTex ("_RampTex", 2D) = "white" {}
		_RampVal("_RampVal",float)=4.4
		_RampColor("_RampColor",Color)=(0.854,0.97,1,1)

		_Lian_blend("Lian_blend",Range(0,1))=0.6

		_OutLineWidth("outLineWidth",Range(0,.01))=0.002
		_OutLineColor("outLineColor",Color)=(1,0,0,1)
		_OutLineParam("outLineParam", float) = 0.25

		[Space(50)]
		_MaskTex ("MaskTex", 2D) = "white" {}
		_MaskStrength("MaskStrength",Range(0,1))=0

		_EdgeColor("EdgeColor",Color)=(1,0,0,1)
        _EdgeColorStrength("EdgeColorStrength",Range(1,5))=1

        _isOpenRJ("_isOpenRJ",Range(0,1))=0



		_SpeMap("SpeMap",2D)="white"{}
		_SpeCol("speCol",Color)=(1,1,1,1)
		// _SpeStrength("strength",Range(0,4))=1
		_SpePreperty("SpePreperty",Vector)=(0,0,0,0)
	}
	
	Subshader
	{
		Tags { "Queue"="AlphaTest+300" "RenderType"="TransparentCutout" "IgnoreProjector"="True" }
		Lod 200
		Pass
		{
			ZWrite On
			Cull Back
			Blend SrcAlpha OneMinusSrcAlpha 
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile_fog 
				#pragma multi_compile _ FADE_IN FADE_OUT
				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 texcoord : TEXCOORD0;
					float2 uv:TEXCOORD1;
					float4 color:COLOR0;
				};
				
				struct v2f
				{
					float4 pos	: SV_POSITION;
					float2 uv 	: TEXCOORD0;
					float2 cap	: TEXCOORD1;
					float4 color:COLOR0;
					UNITY_FOG_COORDS(2)
				    #if FADE_IN | FADE_OUT
				    float3 worldPos : TEXCOORD3;
				    float2 noiseUv : TEXCOORD4;
				    #endif
				};
				
				uniform float4 _MainTex_ST;
				uniform float4 _NoiseTex_ST;
				
				uniform sampler2D _MainTex;
				uniform sampler2D _MatCap;
				

				uniform sampler2D _NoiseTex;
				uniform float _Cutoff; 
				uniform float _Fade;
				
                half _Density;
                float _Intensity;
                float _GlowWidth;
                float _GlowFadeWidth;
                fixed4 _GlowStartColor;
                fixed4 _GlowEndColor;
                
				fixed4 _MatCapColor;
				fixed _MatCapVal;

				sampler2D _RampTex;
				fixed4 _RampColor;
				fixed _RampVal;
				fixed _Lian_blend;


				//溶解
				sampler2D _MaskTex;
			    float4 _MaskTex_ST;

			    fixed _MaskStrength;
			    fixed4 _EdgeColor;
			    fixed _EdgeColorStrength;

			    fixed _Strength;

                fixed _isOpenRJ;


				sampler2D _SpeMap;
				float4 _SpeMap_ST;
				fixed4 _SpeCol;
				fixed4 _SpePreperty;

                
				v2f vert (appdata v)
				{
					v2f o;
//溶解
                float vertexMask=tex2Dlod(_MaskTex,float4(v.uv.xy,0,0)).b;
                vertexMask=step(0.5,vertexMask);

				if(vertexMask==1)
				{
					v.vertex.xyz+=pow(tex2Dlod(_MaskTex,float4(v.uv+float2(_Time.x*6,0),0,0)).g*2,_MaskStrength)*0.1-0.1;
				}
				
				//------------------------

					o.pos = UnityObjectToClipPos (v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.color=v.color;
					
					half2 capCoord;
					capCoord.x = dot(UNITY_MATRIX_IT_MV[0].xyz,normalize(v.normal));
					capCoord.y = dot(UNITY_MATRIX_IT_MV[1].xyz,normalize(v.normal));
					o.cap = capCoord * 0.5 + 0.5;

                    #if FADE_IN | FADE_OUT
				    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				    o.noiseUv = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				    #endif

                    //float3 temp;
                    //temp.z = dot(float4(0,0,-1.0000066666888889629632098773663, -0.02000006666688888962963209877366), mul(UNITY_MATRIX_MV, v.vertex));
					//UNITY_TRANSFER_FOG(o,temp);
					UNITY_TRANSFER_FOG(o,o.pos);
					return o;
				}
				fixed4 frag (v2f i) : COLOR
				{
				    #if FADE_IN | FADE_OUT
                    float noise = tex2D(_NoiseTex, i.noiseUv).r;
                    #if FADE_OUT
                    noise -= _Intensity;
                    clip(noise);
                    #endif
                    #ifdef FADE_IN
                    noise = _Intensity - noise;
                    clip(noise);
                    #endif
                    #endif

					fixed4 tex = tex2D(_MainTex, i.uv);
					fixed4 mc = tex2D(_MatCap, i.cap);
					
					fixed4 ramp = tex2D(_RampTex, i.cap)*_RampColor;
					mc=pow(mc,_MatCapVal);
					fixed4 col1=lerp(tex,_MatCapColor*tex,(1-mc.r)*_MatCapColor.a*i.color.b);
					fixed4 col2=lerp(tex,_MatCapColor*tex,(1-mc.r)*_MatCapColor.a*i.color.g);
					/*
					if(i.color.b>=0.9)
					{
						col1=lerp(tex,_MatCapColor*tex,(1-mc.r)*_MatCapColor.a*i.color.b);
					}else{
						col2=lerp(tex,_MatCapColor*tex,(1-mc.r)*_MatCapColor.a*i.color.g);
					}
					*/
					fixed4 col=lerp(col1,col2,_Lian_blend);



					if(_isOpenRJ==1){
						fixed alphaMask=tex2D(_MaskTex,i.uv).b;

				        fixed3 col_zb=col.rgb*alphaMask;
				        fixed3 col_l=col.rgb*(1-alphaMask);

				        fixed4 maskCol=tex2D(_MaskTex,i.uv);
				        fixed alpha=step(maskCol.g,_MaskStrength);
				
				        alpha*=alphaMask;
				        alpha=1-alpha;

				        fixed alphaBlur=smoothstep(-0.1,maskCol.g,_MaskStrength);
				        alphaBlur=1-alphaBlur;

				        fixed3 glowCol=tex2D(_MaskTex,float2(alphaBlur+0.01,alphaBlur)).r*_EdgeColor.rgb;
				        glowCol*=alphaMask;
                
				
				       col=fixed4(col_zb.rgb+_Strength*alphaMask+col_l.rgb+glowCol.rgb*_EdgeColorStrength,alpha*col.a);
				       if(col.a<=0.5)
					   {
					       discard;
				       }

					}
			    
					
					
					
					ramp=pow(ramp,_RampVal);
					col+=ramp;
					col.a = tex.a;
					col.rgb *= _Fade;
					clip(col.a - _Cutoff);
					UNITY_APPLY_FOG(i.fogCoord, col);
					
				    #if FADE_IN | FADE_OUT
                    float glowPercent = clamp(noise / _GlowWidth, 0.0, 1.0);
                    float fadePercent = clamp((noise - _GlowWidth) / _GlowFadeWidth, 0.0, 1.0);
                    fixed4 glow = lerp(_GlowStartColor, _GlowEndColor, glowPercent);
                    col = lerp(glow, col, fadePercent);
				    #endif


					 i.uv+=_SpePreperty.xy*_Time.x*_SpePreperty.w+col.r*0.45;
						fixed3 SpeCol=tex2D(_SpeMap,i.uv).r;
						fixed3 sc0=pow(SpeCol*_SpePreperty.z,4);
						fixed3 sc1=pow(SpeCol*_SpePreperty.z*_SpeCol.rgb,2);
						col.rgb+=sc0+sc1;

					return col;


					
				}
			ENDCG
		}


		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha 
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv:TEXCOORD0;
				float3 normal:NORMAL0;
			};

			struct v2f
			{
				float2 uv:TEXCOORD0;
				float4 vertex : SV_POSITION;
				UNITY_FOG_COORDS(2)
			};

			uniform sampler2D _MainTex;
			
			float _OutLineWidth;
			fixed4 _OutLineColor;
			float _OutLineParam;

			//溶解
				sampler2D _MaskTex;
			    float4 _MaskTex_ST;

			    fixed _MaskStrength;
			    fixed4 _EdgeColor;
			    fixed _EdgeColorStrength;

			    fixed _Strength;

                fixed _isOpenRJ;


					


			v2f vert (appdata v)
			{
				v2f o;
				float vertexMask=tex2Dlod(_MaskTex,float4(v.uv.xy,0,0)).b;
                vertexMask=step(0.5,vertexMask);

				if(vertexMask==1)
				{
					v.vertex.xyz+=pow(tex2Dlod(_MaskTex,float4(v.uv+float2(_Time.x*6,0),0,0)).g*2,_MaskStrength)*0.1-0.1;
				}
				v.vertex.xyz=v.vertex.xyz+v.normal*_OutLineWidth;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv=v.uv;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				fixed4 mc = tex2D(_MainTex,i.uv);
				//fixed4 col=_OutLineColor;
				fixed4 col=mc + fixed4(-mc.x*_OutLineParam,-mc.y*_OutLineParam,-mc.z*_OutLineParam,0);

				if(_isOpenRJ==1){
						fixed alphaMask=tex2D(_MaskTex,i.uv).b;

				        fixed3 col_zb=col.rgb*alphaMask;
				        fixed3 col_l=col.rgb*(1-alphaMask);

				        fixed4 maskCol=tex2D(_MaskTex,i.uv);
				        fixed alpha=step(maskCol.g,_MaskStrength);
				
				        alpha*=alphaMask;
				        alpha=1-alpha;

				        fixed alphaBlur=smoothstep(-0.1,maskCol.g,_MaskStrength);
				        alphaBlur=1-alphaBlur;

				        fixed3 glowCol=tex2D(_MaskTex,float2(alphaBlur+0.01,alphaBlur)).r*_EdgeColor.rgb;
				        glowCol*=alphaMask;
                
				
				       col=fixed4(col_zb.rgb+_Strength*alphaMask+col_l.rgb+glowCol.rgb*_EdgeColorStrength,alpha*col.a);
				       if(col.a<=0.5)
					   {
					       discard;
				       }

					  
					}

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
	Subshader
	{
		Tags { "Queue"="AlphaTest+300" "RenderType"="TransparentCutout" "IgnoreProjector"="True" }
		Lod 100
		Pass
		{
			ZWrite On
			Cull Back
			Blend SrcAlpha OneMinusSrcAlpha 
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest
				#pragma multi_compile_fog 
				#pragma multi_compile _ FADE_IN FADE_OUT
				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal : NORMAL;
					float4 texcoord : TEXCOORD0;
					float2 uv:TEXCOORD1;
					float4 color:COLOR0;
				};
				
				struct v2f
				{
					float4 pos	: SV_POSITION;
					float2 uv 	: TEXCOORD0;
					float2 cap	: TEXCOORD1;
					float4 color:COLOR0;
					UNITY_FOG_COORDS(2)
				    #if FADE_IN | FADE_OUT
				    float3 worldPos : TEXCOORD3;
				    float2 noiseUv : TEXCOORD4;
				    #endif
				};
				
				uniform float4 _MainTex_ST;
				uniform float4 _NoiseTex_ST;
				
				uniform sampler2D _MainTex;
				uniform sampler2D _MatCap;
				

				uniform sampler2D _NoiseTex;
				uniform float _Cutoff; 
				uniform float _Fade;
				
                half _Density;
                float _Intensity;
                float _GlowWidth;
                float _GlowFadeWidth;
                fixed4 _GlowStartColor;
                fixed4 _GlowEndColor;
                
				fixed4 _MatCapColor;
				fixed _MatCapVal;

				sampler2D _RampTex;
				fixed4 _RampColor;
				fixed _RampVal;
				fixed _Lian_blend;


				//溶解
				sampler2D _MaskTex;
			    float4 _MaskTex_ST;

			    fixed _MaskStrength;
			    fixed4 _EdgeColor;
			    fixed _EdgeColorStrength;

			    fixed _Strength;

                fixed _isOpenRJ;


				sampler2D _SpeMap;
				float4 _SpeMap_ST;
				fixed4 _SpeCol;
				fixed4 _SpePreperty;

                
				v2f vert (appdata v)
				{
					v2f o;
//溶解
                float vertexMask=tex2Dlod(_MaskTex,float4(v.uv.xy,0,0)).b;
                vertexMask=step(0.5,vertexMask);

				if(vertexMask==1)
				{
					v.vertex.xyz+=pow(tex2Dlod(_MaskTex,float4(v.uv+float2(_Time.x*6,0),0,0)).g*2,_MaskStrength)*0.1-0.1;
				}
				
				//------------------------

					o.pos = UnityObjectToClipPos (v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.color=v.color;
					
					half2 capCoord;
					capCoord.x = dot(UNITY_MATRIX_IT_MV[0].xyz,normalize(v.normal));
					capCoord.y = dot(UNITY_MATRIX_IT_MV[1].xyz,normalize(v.normal));
					o.cap = capCoord * 0.5 + 0.5;

                    #if FADE_IN | FADE_OUT
				    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				    o.noiseUv = TRANSFORM_TEX(v.texcoord, _NoiseTex);
				    #endif

                    //float3 temp;
                    //temp.z = dot(float4(0,0,-1.0000066666888889629632098773663, -0.02000006666688888962963209877366), mul(UNITY_MATRIX_MV, v.vertex));
					//UNITY_TRANSFER_FOG(o,temp);
					UNITY_TRANSFER_FOG(o,o.pos);
					return o;
				}
				fixed4 frag (v2f i) : COLOR
				{
				    #if FADE_IN | FADE_OUT
                    float noise = tex2D(_NoiseTex, i.noiseUv).r;
                    #if FADE_OUT
                    noise -= _Intensity;
                    clip(noise);
                    #endif
                    #ifdef FADE_IN
                    noise = _Intensity - noise;
                    clip(noise);
                    #endif
                    #endif

					fixed4 tex = tex2D(_MainTex, i.uv);


					fixed4 mc = tex2D(_MatCap, i.cap);
					
					fixed4 ramp = tex2D(_RampTex, i.cap)*_RampColor;
					mc=pow(mc,_MatCapVal);
					fixed4 col1=lerp(tex,_MatCapColor*tex,(1-mc.r)*_MatCapColor.a*i.color.b);
					fixed4 col2=lerp(tex,_MatCapColor*tex,(1-mc.r)*_MatCapColor.a*i.color.g);
					/*
					if(i.color.b>=0.9)
					{
						col1=lerp(tex,_MatCapColor*tex,(1-mc.r)*_MatCapColor.a*i.color.b);
					}else{
						col2=lerp(tex,_MatCapColor*tex,(1-mc.r)*_MatCapColor.a*i.color.g);
					}
					*/
					fixed4 col=lerp(col1,col2,_Lian_blend);



					if(_isOpenRJ==1){
						fixed alphaMask=tex2D(_MaskTex,i.uv).b;

				        fixed3 col_zb=col.rgb*alphaMask;
				        fixed3 col_l=col.rgb*(1-alphaMask);

				        fixed4 maskCol=tex2D(_MaskTex,i.uv);
				        fixed alpha=step(maskCol.g,_MaskStrength);
				
				        alpha*=alphaMask;
				        alpha=1-alpha;

				        fixed alphaBlur=smoothstep(-0.1,maskCol.g,_MaskStrength);
				        alphaBlur=1-alphaBlur;

				        fixed3 glowCol=tex2D(_MaskTex,float2(alphaBlur+0.01,alphaBlur)).r*_EdgeColor.rgb;
				        glowCol*=alphaMask;
                
				
				       col=fixed4(col_zb.rgb+_Strength*alphaMask+col_l.rgb+glowCol.rgb*_EdgeColorStrength,alpha*col.a);
				       if(col.a<=0.5)
					   {
					       discard;
				       }

					}
			    
					
					
					
					ramp=pow(ramp,_RampVal);
					col+=ramp;
					col.a = tex.a;
					col.rgb *= _Fade;
					clip(col.a - _Cutoff);
					UNITY_APPLY_FOG(i.fogCoord, col);
					
				    #if FADE_IN | FADE_OUT
                    float glowPercent = clamp(noise / _GlowWidth, 0.0, 1.0);
                    float fadePercent = clamp((noise - _GlowWidth) / _GlowFadeWidth, 0.0, 1.0);
                    fixed4 glow = lerp(_GlowStartColor, _GlowEndColor, glowPercent);
                    col = lerp(glow, col, fadePercent);


					


				    #endif

					i.uv+=_SpePreperty.xy*_Time.x*_SpePreperty.w+tex.r*0.45;
					fixed3 SpeCol=tex2D(_SpeMap,i.uv).r;
					fixed3 sc0=pow(SpeCol*_SpePreperty.z,4);
					fixed3 sc1=pow(SpeCol*_SpePreperty.z*_SpeCol.rgb,2);
					col.rgb+=sc0+sc1;
					return col;



					
				}
			ENDCG
		}


	}
	// Fallback "VertexLit"
}