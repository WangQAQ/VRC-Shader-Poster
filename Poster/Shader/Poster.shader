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
                // 计算当前图块的采样UV（0.5%边距）
                const float scale = 0.999;   // 99.9%缩放比例
                const float offset = 0.0005; // 0.05%偏移量

                // 获取当前时间
                float totalTime = _Time.y;
                // 每个图块完整周期：等待时间 + 翻页过渡时间
                float totalCycle = _IdleTime + _SwitchTime;
                // 8个图块的完整循环
                float cycleTime = fmod(totalTime, totalCycle * 8);

                // 计算当前图块的索引（用 uint 进行整数运算加速）
                uint currentIndex = (uint)(cycleTime / totalCycle);
                uint nextIndex = (currentIndex + 1) & 7; // 取模 8，用位运算 (&7) 加速

                // 当前周期内的时间
                float subCycle = fmod(cycleTime, totalCycle);
                // 在等待阶段 (_IdleTime 内) 进度为 0，过渡阶段线性变化到 1
                float progress = saturate((subCycle - _IdleTime) / _SwitchTime);

                // 根据图块排列（4列2行）计算当前图块与下一图块的行列索引
                uint currentCol = currentIndex & 3; // 等效于 %4
                uint currentRow = currentIndex >> 2;  // 等效于 /4
                uint nextCol = nextIndex & 3;
                uint nextRow = nextIndex >> 2;

                float tileWidth = 0.25;  // 每个图块占纹理宽度的1/4
                float tileHeight = 0.5;  // 每个图块占纹理高度的1/2

                float2 currentStartUV = float2(currentCol * tileWidth, 1 - (currentRow + 1) * tileHeight);
                float2 nextStartUV    = float2(nextCol * tileWidth, 1 - (nextRow + 1) * tileHeight);

                // 计算滑动偏移位置：当前图块向左滑动，下一图块从右侧进入
                float currentPos = -progress;
                float nextPos = 1 - progress;

                // 当前图块UV计算
                float2 currentTileUV;
                currentTileUV.x = ((i.uv.x - currentPos) * scale + offset) * tileWidth;
                currentTileUV.y = (i.uv.y * scale + offset) * tileHeight;
                float2 currentUV = currentTileUV + currentStartUV;

                // 下一图块UV计算
                float2 nextTileUV;
                nextTileUV.x = ((i.uv.x - nextPos) * scale + offset) * tileWidth;
                nextTileUV.y = (i.uv.y * scale + offset) * tileHeight;
                float2 nextUV = nextTileUV + nextStartUV;

                // 根据屏幕的横向位置判断采样区域
                float blendCurrent = step(currentPos, i.uv.x) * step(i.uv.x, currentPos + 1.0);
                float blendNext = step(nextPos, i.uv.x) * step(i.uv.x, nextPos + 1.0);

                // 分别采样当前图块和下一图块
                float4 currentColor = tex2D(_MainTex, currentUV) * blendCurrent;
                float4 nextColor = tex2D(_MainTex, nextUV) * blendNext;

                // 通过 lerp 混合两者，当 progress 为 0 时（等待阶段）只显示当前图块
                fixed4 color = lerp(currentColor, nextColor, progress) * _MainColor;
                return color;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}