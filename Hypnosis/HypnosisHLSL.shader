Shader "Unlit/HypnosisHLSL"
{
    Properties
    {
        [NoScaleOffset]_Stripes ("Stripes", 2D) = "white" {}
        _SwirlGradientStart("Swirl Gradient Start", Range(-1.0,1.0)) = 0.065
        _SwirlGradientEnd("Swirl Gradient End", Range(-1.0,1.0)) = 1
        _StripeFrequency ("Stripe Frequency", Float) = 1
        _SwirlFrequency ("Swirl Frequency", Float) = 0.1
        _SwirlSpeed ("Swirl Speed", Float) = 1
        _StripeColorA ("Stripe Color A", Color) = (0,0,0,1)
        _StripeColorB ("Stripe Color B", Color) = (1,1,1,1)
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            //Material properties
            sampler2D _Stripes;
            sampler2D _SwirlAmountGradient;
            half4 _StripeColorA;
            half4 _StripeColorB;
            float _SwirlFrequency;
            float _SwirlSpeed;
            float _StripeFrequency;
            float _SwirlGradientStart;
            float _SwirlGradientEnd;
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            //Polar coordinates from shader graph implementation
            float2 PolarCoordinates(float2 UV, float2 Center, float RadialScale, float LengthScale)
            {
                float2 delta = UV - Center;
                float radius = length(delta) * 2 * RadialScale;
                float angle = atan2(delta.x, delta.y) * 1.0/6.28 * LengthScale;
                return float2(radius, angle);
            }


            half4 frag (v2f i) : SV_Target
            {
                //polar coordinates - polar.x is distance from the center,
                //polar.y is angle between the uv vector and the (0,-1) vector remapped to a 0-1 range
                //(see shader graph for visual, r channel is x, and g channel is y)
                float2 polar = PolarCoordinates(i.uv.xy, float2(0.5,0.5), 0.5,1);
                
                //calculate how much the spiral should swirl as it gets closer to the center
                //(remap the distance from the center (polar.x) to a value on a linear gradient,
                //and then take the reciprocal, because we want the center to get "infinitely" more detail,
                //and smaller numbers have larger and larger reciprocals)
                float swirlAmount = 1.0 / lerp(_SwirlGradientStart,_SwirlGradientEnd,polar.x);

                //increase the amount of swirls we have in a linear way (higher freq = more swirls)
                swirlAmount *= _SwirlFrequency;

                //animate the swirl ( - rotates the final image)
                //because we use the swirl as an x uv coordinate for sampling our gradient, if we add to the swirl,
                //the point that we sample will be offset by this added value
                float animatedSwirl = swirlAmount + _Time.y * _SwirlSpeed;

                //add the original polar coordinate to our animated swirl offset and then apply "tiling" using _StripeFrequency
                //this will control how many stripes we have in the first place
                float swirl = (polar.y + animatedSwirl) * _StripeFrequency;

                //combine the UV, and calculate modulo to have every value between 0 and 1 to avoid mipmap artifacts
                float2 stripeUV = float2(swirl, animatedSwirl) % 1.0;

                //sample grayscale stripe map
                float stripeGrayscale = tex2D(_Stripes, stripeUV).r;
                
                //mix color for our final image (optional, this can be just baked into the stripe texture,
                //if we don't want to customize this later)
                half4 col = lerp(_StripeColorA,_StripeColorB,stripeGrayscale);
                
                return col;
            }
            ENDHLSL
        }
        
        //pass for rendering depth
        Pass
        {
            ColorMask 0
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return 1;
            }
            ENDHLSL
            
            
        }
    }
}
