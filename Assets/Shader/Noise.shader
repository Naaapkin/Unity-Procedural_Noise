Shader "Addition/Post-processing/NoisePreview"
{
    Properties
    {
        _Frequency ("Frequency", Float) = 0.015625
        _Octaves ("Octaves", Range(1, 8)) = 4
        _Persistence ("Persistence", Range(0, 1)) = 0.5
        _Lacunarity ("Lacunarity", Float) = 2
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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/Shader/Include/Noise.hlsl"

            struct VertexInfo
            {
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct FragInfo
            {
                float4 positionCS : POSITION;
                float2 texcoord   : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            FragInfo vert(VertexInfo input)
            {
                FragInfo output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                float4 pos = GetFullScreenTriangleVertexPosition(input.vertexID);
                float2 uv  = GetFullScreenTriangleTexCoord(input.vertexID);
                output.positionCS = pos;
                output.texcoord   = uv;
                return output;
            }

            #define SEED 0xAC4B4C07

            CBUFFER_START(UnityPerMaterial)
            float _Frequency;
            uint _Octaves;
            float _Persistence;
            float _Lacunarity;
            CBUFFER_END

            float Simplex (float2 position)
            {
                float value = 0.0;
                float amplitude = 1.0;
                float currentFrequency = _Frequency;
                uint currentSeed = SEED;
                for (uint i = 0; i < _Octaves; i++) {
                    currentSeed = MurmurHash(currentSeed);
                    value += SimplexNoise2(position * currentFrequency, currentSeed) * amplitude;
                    amplitude *= _Persistence;
                    currentFrequency *= _Lacunarity;
                }
                return 0.5 * (value + 1);
            }

            float Worley (float2 position)
            {
                float value = 0.0;
                float amplitude = 1.0;
                float totalAmplitude = 0.0;
                float currentFrequency = _Frequency;
                float currentSeed = SEED;
                for (uint i = 0; i < _Octaves; i++) {
                    currentSeed = MurmurHash(currentSeed);
                    value += (1 - WorleyNoise2(position * currentFrequency, currentSeed, 0xffffffff)) * amplitude;
                    totalAmplitude += amplitude;
                    amplitude *= _Persistence;
                    currentFrequency *= _Lacunarity;
                }
                return value / totalAmplitude;
            }

            float Perlin (float2 position)
            {
                float value = 0.0;
                float amplitude = 1.0;
                float currentFrequency = _Frequency;
                float currentSeed = SEED;
                for (uint i = 0; i < _Octaves; i++) {
                    currentSeed = MurmurHash(currentSeed);
                    value += PerlinNoise2(position * currentFrequency, currentSeed, 0xffffffff) * amplitude;
                    amplitude *= _Persistence;
                    currentFrequency *= _Lacunarity;
                }
                return 0.5 * (value + 1);
            }

            float PerlinWorley (float2 position)
            {
                float value_p = 0.0;
                float value_w = 0.0;
                float amplitude = 1.0;
                float totalAmplitude = 0.0;
                float currentFrequency = _Frequency;
                float currentSeed = SEED;
                for (uint i = 0; i < 2; i++) {
                    currentSeed = MurmurHash(currentSeed);
                    value_p += PerlinNoise2(position * currentFrequency, currentSeed, 0xffffffff) * amplitude;
                    amplitude *= _Persistence;
                    totalAmplitude += amplitude;
                    currentFrequency *= _Lacunarity;
                }
                for (uint i = 0; i < _Octaves - 2; i++) {
                    currentSeed = MurmurHash(currentSeed);
                    value_w += (1 - WorleyNoise2(position * currentFrequency, currentSeed, 0xffffffff)) * amplitude;
                    amplitude *= _Persistence;
                    totalAmplitude += amplitude;
                    currentFrequency *= _Lacunarity;
                }
                return 0.5 * (value_p + 1) + value_w / totalAmplitude;
            }

            float4 frag (FragInfo i) : SV_Target
            {
                float2 pos = i.positionCS.xy * max(_ScreenSize.z, _ScreenSize.w) + _Time.x;
                float2 sign = i.texcoord - 0.5;
                if (sign.x < 0)
                {
                    if (sign.y < 0) return Perlin(pos);
                    return PerlinWorley(pos);
                }
                if (sign.y < 0) return Worley(pos);
                return Simplex(pos);
            }
            ENDHLSL
        }
    }
}
