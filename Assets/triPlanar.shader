Shader "Custom/triPlanar"
{
    Properties
    {
        /*
            [NoScaleOffset] �� 2D �ؽ��� ������Ƽ �տ� �޾��ָ�
            �ؽ��� �������̽��� ����ִ� tiling �� offset ��Ʈ�� �Է�â�� �����ع���.

            ���, tiling �� offset ���� �Է¹޴� vector4 ������ �������̽��� ���� �߰��ؼ� ����.

            �� �̷��� �Ѱųĸ�,
            �� ���������� Input ����ü���� uv_MainTex �̷� ������
            �� �ؽ��ĸ��� �Ҵ�� uv��ǥ�� ����ؼ� ���ø��ϴ� �� �ƴ϶�,
            ���ؽ� ������� ��ǥ�� worldPos �� ������ ���ø��ϰ� ����.

            �׷��� ������, �ؽ��� �������̽����� �Է¹޴� tiling �� offset ��Ʈ�� ����
            �ƿ� ������ �ȵǴ� ����. worldPos �� �곻�� ������� �ƿ� �ٸ� ��ǥ���̴ϱ�.

            �׷��� surf() �Լ� ������ ���� ���� topUV, sideUV, frontUV �곻�鿡�ٰ�
            ���� tiling �� offset ���� �޾ƿͼ� ������ֱ� ���ؼ�
            �� ������ �޴� �������̽��� ���� ������ ����.
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
            float3 worldPos; // ���κ� �ؽ��İ� �þ�� �ʰ� ����� ����������, ���ؽ��� ������� ��ǥ�� ������ �� �ҷ��ͼ� ����ؾ� ��.
            float3 worldNormal; // ���ø��� �ؼ����� ������ ���(����, �ո�, ����)�� ���(��, ���� 1��)���� ����ŷ�ϱ� ����, ���ؽ��� ������� �븻���͸� ������ �� �����ͼ� �����.
        };

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // �̰� ���ĸ�, Input ����ü�� ���ǵ� ���ؽ� uv��ǥ�� �ƴ�, ���ؽ� ������� position ���� uv��ǥ�� ���ø��� ����ϴ� ����.
            // uv_MainTex �� ���ø����� ���� ������ ����� ����� �Ѵٸ�, 
            // ��ü�� ���鿡��(y�� ���⿡��) �ٶ� �� ��ȭ�ϴ� ��ǥ��? X, Z��ǥ�̹Ƿ�, �곻���� UV��ǥ�� ����� ��! 
            float2 topUV = float2(IN.worldPos.x, IN.worldPos.z);
            float4 topTex = tex2D(_MainTex, topUV * _MainTexUV.xy + _MainTexUV.zw); // ������ �������̽��κ��� ���� ���� tiling �� offset ���� �����ͼ� ���� ����� ��.

            // ���� ������ �������, ��ü�� ���ʿ���(z�� ���⿡��) �ٶ� �� ��ȭ�ϴ� ��ǥ��,
            // ��ü�� ���ʿ���(x�� ���⿡��) �ٶ� �� ��ȭ�ϴ� ���ؽ� ������� ��ǥ�� uv��ǥ�� ����ؼ� ������ �ؽ��ĸ� ���ø���.
            
            // ��ü�� �ո鿡��(z�� ���⿡��) �ٶ� ���� uv��ǥ ��� �� ���ø�
            float2 frontUV = float2(IN.worldPos.x, IN.worldPos.y);
            float4 frontTex = tex2D(_MainTex2, frontUV * _MainTex2UV.xy + _MainTex2UV.zw); // ������ �������̽��κ��� ���� ���� tiling �� offset ���� �����ͼ� ���� ����� ��.

            // ��ü�� ���鿡��(x�� ���⿡��) �ٶ� ���� uv��ǥ ��� �� ���ø�
            float2 sideUV = float2(IN.worldPos.z, IN.worldPos.y);
            float4 sideTex = tex2D(_MainTex2, sideUV * _MainTex2UV.xy + _MainTex2UV.zw); // ������ �������̽��κ��� ���� ���� tiling �� offset ���� �����ͼ� ���� ����� ��.

            // �� ���ؽ��� ������� ��ֺ����� z������Ʈ�� �������� ���� �Ǵ� �ո� �ؼ����� ����������.
            // ��, ��ֺ����� z���� 0�� ��(������ �ȼ����� y���� �ٶ󺸴� ��ֺ����� z���� 0 �̰���?)�� ���� �ؼ����� �����ϰ�,
            // ��ֺ����� z���� 1�� ��(�ո��� �ȼ����� z���� �ٶ󺸴� ��ֺ����� z���� 1 �̰���?)�� �ո� �ؼ����� �����Ұ���.
            // �̶�, abs() �� ������ �̾��� ������, z���� 1�� �κа� -1�� �κ� ��θ�, �� '���'�� �ո� �ؼ����� �����ϱ� ���� ������ ���� 1�� ������ ������� ����ŷ�ǵ��� �� ����!
            o.Albedo = lerp(topTex, frontTex, abs(IN.worldNormal.z));

            // ���� ������ �������, �� ���ؽ� ������� ��ֺ����� x������Ʈ�� �������� ������ �ؼ��� �Ǵ� ���� �ؼ����� ����������.
            // ��, ��ֺ����� x���� 0�� ��(����� �ո��� ���� y��, z���� �ٶ󺸴� ��ֺ����� x���� 0 �̰���?)�� ������ �ؼ����� �����ϰ�,
            // ��ֺ����� x���� 1�� ��(������ �ȼ����� x���� �ٶ󺸴� ��ֺ����� x���� 1�̰���?)�� ���� �ؼ����� �����Ұ���.
            // �̶�, abs()�� ���� x���� 1�� �κа� -1�� �κ�, �� '���'�� ���� �ؼ����� �����ϱ� ���� ������ ���� 1�� �̾��ִ°Ű�!
            o.Albedo = lerp(o.Albedo, sideTex, abs(IN.worldNormal.x));

            o.Alpha = 1;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
