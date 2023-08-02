Shader "TowerDeffense/ToonShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        [Header(Complex Model)]
        [Space]
        //_ComplexModel("Complex Model", Range(0,1)) = 1 
        [Toggle(COMPLEX)] _COMPLEX("Complex Model", Float) = 0

        [Header(Toon Shader)]
        [Space]
        _Albedo("Albedo", Color) = (1, 1, 1, 1)

        [Header(Outline Info)]
        [Space]
        _OutlineInk("Outline Color", Color) = (0, 0, 0, 0)
        _OutlineSize("Outline Size", Range(0,1)) = 1 
        _OutlineSizeComplex("Outline Size Complex", Range(1,2)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 100

        //Pass outline
        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature COMPLEX

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            float4 _OutlineInk;
            float _OutlineSize;
            float _OutlineSizeComplex;
            //float _ComplexModel;

            v2f vert (appdata v)
            {
                v2f o;
                //Scale the object from its center

                #if COMPLEX // use vertex colors for flow
                    o.vertex = UnityObjectToClipPos(v.vertex * _OutlineSizeComplex);
                #else // or world normal
                        
                    o.vertex = UnityObjectToClipPos(v.vertex + v.normal * _OutlineSize);
                #endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutlineInk;
            }
            ENDCG
        }

        //Pass toon shading
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXTCOORD0;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Albedo;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                //Calculating cosine between normal and light direction
                //The world space light direction is stored in _WorldSpaceLightPos0
                //The world soace normal is stored in i.worldNormal
                //Normalize and do the dot product
                float cosineAngle = dot(normalize(i.worldNormal), normalize(_WorldSpaceLightPos0.xyz));

                //Set the min to zero in negative cases
                cosineAngle = max(cosineAngle, 0.0);

                //Set the quantity of colors

                // if(cosineAngle > 0.75)
                //     return _Albedo * col * 1.0;
                // else if(cosineAngle > 0.5)
                //     return _Albedo * col * 0.75;
                // else if(cosineAngle > 0.25)
                //     return _Albedo * col * 0.5;
                // else
                //     return _Albedo * col * 0.25;

                if(cosineAngle > 0.5)
                    return _Albedo * col * 1.0;
                else
                    return _Albedo * col * 0.25;
            }
            ENDCG
        }
    }

    Fallback "VertexLit"
}
