Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Height ("Height", Range(0.0,1.0)) = 0.5
        _MoveSpeed("Move Speed", Vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        


        Pass
        {
            



            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float4 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Height;
            float2 _MoveSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                float timeOffset = _Time.y;
                float2 uv = TRANSFORM_TEX(v.uv + float2(timeOffset,timeOffset) * _MoveSpeed.yx, _MainTex);
                half4 height = tex2Dlod(_MainTex, float4(uv,0,0));
                float4 pos = v.vertex + v.normal * height * _Height * v.color.x;

                o.vertex = UnityObjectToClipPos(pos);
                o.uv = uv;
                o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDHLSL
        }
    }
}
