Shader "WangQAQ/Poster"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (1,1,1,1)
        _SwitchTime ("Switch Time", Float) = 2
        _IdleTime ("Idle Time", Float) = 1
        _MainTex ("Poster Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _MainColor;
            float _SwitchTime;
            float _IdleTime;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // ���㵱ǰͼ��Ĳ���UV��0.5%�߾ࣩ
                const float scale = 0.999;   // 99.9%���ű���
                const float offset = 0.0005; // 0.05%ƫ����

                // ��ȡ��ǰʱ��
                float totalTime = _Time.y;
                // ÿ��ͼ���������ڣ��ȴ�ʱ�� + ��ҳ����ʱ��
                float totalCycle = _IdleTime + _SwitchTime;
                // 8��ͼ�������ѭ��
                float cycleTime = fmod(totalTime, totalCycle * 8);

                // ���㵱ǰͼ����������� uint ��������������٣�
                uint currentIndex = (uint)(cycleTime / totalCycle);
                uint nextIndex = (currentIndex + 1) & 7; // ȡģ 8����λ���� (&7) ����

                // ��ǰ�����ڵ�ʱ��
                float subCycle = fmod(cycleTime, totalCycle);
                // �ڵȴ��׶� (_IdleTime ��) ����Ϊ 0�����ɽ׶����Ա仯�� 1
                float progress = saturate((subCycle - _IdleTime) / _SwitchTime);

                // ����ͼ�����У�4��2�У����㵱ǰͼ������һͼ�����������
                uint currentCol = currentIndex & 3; // ��Ч�� %4
                uint currentRow = currentIndex >> 2;  // ��Ч�� /4
                uint nextCol = nextIndex & 3;
                uint nextRow = nextIndex >> 2;

                float tileWidth = 0.25;  // ÿ��ͼ��ռ�����ȵ�1/4
                float tileHeight = 0.5;  // ÿ��ͼ��ռ����߶ȵ�1/2

                float2 currentStartUV = float2(currentCol * tileWidth, 1 - (currentRow + 1) * tileHeight);
                float2 nextStartUV    = float2(nextCol * tileWidth, 1 - (nextRow + 1) * tileHeight);

                // ���㻬��ƫ��λ�ã���ǰͼ�����󻬶�����һͼ����Ҳ����
                float currentPos = -progress;
                float nextPos = 1 - progress;

                // ��ǰͼ��UV����
                float2 currentTileUV;
                currentTileUV.x = ((i.uv.x - currentPos) * scale + offset) * tileWidth;
                currentTileUV.y = (i.uv.y * scale + offset) * tileHeight;
                float2 currentUV = currentTileUV + currentStartUV;

                // ��һͼ��UV����
                float2 nextTileUV;
                nextTileUV.x = ((i.uv.x - nextPos) * scale + offset) * tileWidth;
                nextTileUV.y = (i.uv.y * scale + offset) * tileHeight;
                float2 nextUV = nextTileUV + nextStartUV;

                // ������Ļ�ĺ���λ���жϲ�������
                float blendCurrent = step(currentPos, i.uv.x) * step(i.uv.x, currentPos + 1.0);
                float blendNext = step(nextPos, i.uv.x) * step(i.uv.x, nextPos + 1.0);

                // �ֱ������ǰͼ�����һͼ��
                float4 currentColor = tex2D(_MainTex, currentUV) * blendCurrent;
                float4 nextColor = tex2D(_MainTex, nextUV) * blendNext;

                // ͨ�� lerp ������ߣ��� progress Ϊ 0 ʱ���ȴ��׶Σ�ֻ��ʾ��ǰͼ��
                fixed4 color = lerp(currentColor, nextColor, progress) * _MainColor;
                return color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}