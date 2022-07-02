Shader "Custom/triPlanar"
{
    Properties
    {
        /*
            [NoScaleOffset] 을 2D 텍스쳐 프로퍼티 앞에 달아주면
            텍스쳐 인터페이스에 띄워주는 tiling 및 offset 컨트롤 입력창을 제거해버림.

            대신, tiling 및 offset 값을 입력받는 vector4 형태의 인터페이스를 따로 추가해서 만듦.

            왜 이렇게 한거냐면,
            이 예제에서는 Input 구조체에서 uv_MainTex 이런 식으로
            각 텍스쳐마다 할당된 uv좌표를 사용해서 샘플링하는 게 아니라,
            버텍스 월드공간 좌표인 worldPos 를 가지고 샘플링하고 있음.

            그렇기 때문에, 텍스쳐 인터페이스에서 입력받는 tiling 및 offset 컨트롤 값이
            아예 적용이 안되는 거임. worldPos 는 얘내랑 상관없는 아예 다른 좌표값이니까.

            그래서 surf() 함수 내에서 직접 구한 topUV, sideUV, frontUV 얘내들에다가
            직접 tiling 및 offset 값을 받아와서 계산해주기 위해서
            이 값들을 받는 인터페이스를 따로 만들어둔 것임.
        */
        [NoScaleOffset]_MainTex("TopTex", 2D) = "white" {}
        _MainTexUV("tileU, tileV, offsetU, offsetV", vector) = (1, 1, 0, 0)
        [NoScaleOffset]_MainTex2("SideTex", 2D) = "white" {}
        _MainTex2UV("tileU, tileV, offsetU, offsetV", vector) = (1, 1, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        #pragma surface surf Standard 

        sampler2D _MainTex;
        sampler2D _MainTex2;
        float4 _MainTexUV;
        float4 _MainTex2UV;

        struct Input
        {
            // float2 uv_MainTex;
            float3 worldPos; // 옆부분 텍스쳐가 늘어나지 않고 제대로 입혀지려면, 버텍스의 월드공간 좌표를 선언한 뒤 불러와서 사용해야 함.
            float3 worldNormal; // 샘플링한 텍셀값을 적용할 면들(윗면, 앞면, 옆면)을 흰색(즉, 숫자 1로)으로 마스킹하기 위해, 버텍스의 월드공간 노말벡터를 선언한 뒤 가져와서 사용함.
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // 이게 뭐냐면, Input 구조체에 정의된 버텍스 uv좌표가 아닌, 버텍스 월드공간 position 값을 uv좌표로 샘플링에 사용하는 것임.
            // uv_MainTex 로 샘플링했을 때와 동일한 결과를 얻고자 한다면, 
            // 물체를 윗면에서(y축 방향에서) 바라볼 때 변화하는 좌표는? X, Z좌표이므로, 얘내들을 UV좌표로 사용한 것! 
            float2 topUV = float2(IN.worldPos.x, IN.worldPos.z);
            float4 topTex = tex2D(_MainTex, topUV * _MainTexUV.xy + _MainTexUV.zw); // 별도의 인터페이스로부터 따로 받은 tiling 및 offset 값을 가져와서 직접 계산해 줌.

            // 위와 동일한 방식으로, 물체를 앞쪽에서(z축 방향에서) 바라볼 때 변화하는 좌표와,
            // 물체를 옆쪽에서(x축 방향에서) 바라볼 때 변화하는 버텍스 월드공간 좌표를 uv좌표로 사용해서 동일한 텍스쳐를 샘플링함.
            
            // 물체를 앞면에서(z축 방향에서) 바라볼 때의 uv좌표 계산 및 샘플링
            float2 frontUV = float2(IN.worldPos.x, IN.worldPos.y);
            float4 frontTex = tex2D(_MainTex2, frontUV * _MainTex2UV.xy + _MainTex2UV.zw); // 별도의 인터페이스로부터 따로 받은 tiling 및 offset 값을 가져와서 직접 계산해 줌.

            // 물체를 옆면에서(x축 방향에서) 바라볼 때의 uv좌표 계산 및 샘플링
            float2 sideUV = float2(IN.worldPos.z, IN.worldPos.y);
            float4 sideTex = tex2D(_MainTex2, sideUV * _MainTex2UV.xy + _MainTex2UV.zw); // 별도의 인터페이스로부터 따로 받은 tiling 및 offset 값을 가져와서 직접 계산해 줌.

            // 각 버텍스의 월드공간 노멀벡터의 z컴포넌트의 절댓값으로 윗면 또는 앞면 텍셀값을 선형보간함.
            // 즉, 노멀벡터의 z값이 0인 곳(윗면의 픽셀들은 y축을 바라보니 노멀벡터의 z값이 0 이겠지?)은 윗면 텍셀값을 적용하고,
            // 노멀벡터의 z값이 1인 곳(앞면의 픽셀들은 z축을 바라보니 노멀벡터의 z값이 1 이겠지?)는 앞면 텍셀값을 적용할거임.
            // 이때, abs() 로 절댓값을 뽑아준 이유는, z값이 1인 부분과 -1인 부분 모두를, 즉 '양면'에 앞면 텍셀값을 적용하기 위해 무조건 절댓값 1로 찍혀서 흰색으로 마스킹되도록 한 것임!
            o.Albedo = lerp(topTex, frontTex, abs(IN.worldNormal.z));

            // 위와 동일한 방식으로, 각 버텍스 월드공간 노멀벡터의 x컴포넌트의 절댓값으로 원래의 텍셀값 또는 옆면 텍셀값을 선형보간함.
            // 즉, 노멀벡터의 x값이 0인 곳(윗면과 앞면은 각각 y축, z축을 바라보니 노멀벡터의 x값이 0 이겠지?)은 원래의 텍셀값을 적용하고,
            // 노멀벡터의 x값이 1인 곳(옆면의 픽셀들은 x축을 바라보니 노멀벡터의 x값이 1이겠지?)는 옆면 텍셀값을 적용할거임.
            // 이때, abs()를 통해 x값이 1인 부분과 -1인 부분, 즉 '양면'에 옆면 텍셀값을 적용하기 위해 무조건 절댓값 1로 뽑아주는거고!
            o.Albedo = lerp(o.Albedo, sideTex, abs(IN.worldNormal.x));

            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
