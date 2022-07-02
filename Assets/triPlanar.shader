Shader "Custom/triPlanar"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        #pragma surface surf Standard 

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos; // 옆부분 텍스쳐가 늘어나지 않고 제대로 입혀지려면, 버텍스의 월드공간 좌표를 선언한 뒤 불러와서 사용해야 함.
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
