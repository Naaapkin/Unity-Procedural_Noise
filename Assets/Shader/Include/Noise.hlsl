#ifndef NOISE_H
#define NOISE_H
#define PI 3.14159265359

uint MurmurHash (uint p)
{
    uint m = 0x5bd1e995;
    p *= m;
    p ^= p >> 24;
    p *= m;
    uint h = 0x9747b28c;
    h ^= p.x;
    h ^= h >> 15;
    h *= m;
    h ^= h >> 13;
    return h;
}

uint MurmurHash (uint p, uint seed)
{
    uint m = 0x5bd1e995;
    uint h = seed;
    p *= m;
    p ^= p >> 24;
    p *= m;
    h *= m;
    h ^= p.x;
    h ^= h >> 15;
    h *= m;
    h ^= h >> 13;
    return h;
}

uint MurmurHash (uint2 p, uint seed)
{
    uint m = 0x5bd1e995;
    uint h = seed;
    p *= m;
    p ^= p >> 24;
    p *= m;
    h *= m;
    h ^= p.x;
    h *= m;
    h ^= p.y;
    h ^= h >> 15;
    h *= m;
    h ^= h >> 13;
    return h;
}

uint MurmurHash (uint3 p, uint seed)
{
    uint m = 0x5bd1e995;
    uint h = seed;
    p *= m;
    p ^= p >> 24;
    p *= m;
    
    h *= m;
    h ^= p.x;
    h *= m;
    h ^= p.y;
    h *= m;
    h ^= p.z;
    
    h ^= h >> 16;
    h *= m;
    h ^= h >> 11;
    return h;
}

float Hash31(float3 uvw)
{
    uvw = frac(uvw * 0.1031);
    uvw += dot(uvw, uvw.yzx + 33.33);
    return frac((uvw.x + uvw.y) * uvw.z);
}

float4 Hash44(float4 uvw)
{
    return frac(sin(float4(dot(uvw, float4(127.1, 311.7, 74.7, 269.5)), dot(uvw, float4(183.3, 246.1, 113.5, 271.9)), dot(uvw, float4(124.6, 127.1, 311.7, 74.7)), dot(uvw, float4(269.5, 183.3, 246.1, 113.5)))) * 43758.5453);
}

float3 Hash33(float3 uvw)
{
    return frac(sin(float3(dot(uvw, float3(127.1, 311.7, 74.7)), dot(uvw, float3(269.5, 183.3, 246.1)), dot(uvw, float3(113.5, 271.9, 124.6)))) * 43758.5453);
}

float2 Hash22(float2 uv)
{
    return frac(float2(sin(dot(uv, float2(127.1f, 311.7f))), sin(dot(uv, float2(269.3f, 183.3f))) * 43758.5453f));
}

float3 Grad (int hash)
{
    switch (hash & 15)
    {
        case 0: return float3(1, 1, 0);
        case 1: return float3(-1, 1, 0);
        case 2: return float3(1, -1, 0);
        case 3: return float3(-1, -1, 0);
        case 4: return float3(1, 0, 1);
        case 5: return float3(-1, 0, 1);
        case 6: return float3(1, 0, -1);
        case 7: return float3(-1, 0, -1);
        case 8: return float3(0, 1, 1);
        case 9: return float3(0, -1, 1);
        case 10: return float3(0, 1, -1);
        case 11: return float3(0, -1, -1);
        case 12: return float3(1, 1, 0);
        case 13: return float3(-1, 1, 0);
        case 14: return float3(0, -1, 1);
        default: return float3(0, -1, -1);
    }
}

float fade(float t) {
    // 6t^5 - 15t^4 + 10t^3
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float2 fade(float2 t) {
    // 6t^5 - 15t^4 + 10t^3
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float3 fade(float3 t) {
    // 6t^5 - 15t^4 + 10t^3
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float2 RandN (float2 st)
{
    float root = sqrt(-2 * log(1e-5 + MurmurHash(st, 1) / float(0xffffffff)));    // Avoid log(0)
    float phase = 2 * PI * MurmurHash(st, 2) / float(0xffffffff);
    return float2(cos(phase), sin(phase)) * root;                     // Box-Muller transform
}

float PerlinNoise2(float2 uv, uint seed, uint2 wrap)
{
    float4 offSet = float4(frac(uv), 1, 1);
    offSet.zw = offSet.xy - 1;
    uint4 gps = uint4(uv, uint2(1 + uv) % wrap);

    float2 grad00 = Grad(MurmurHash(gps.xy, seed)).xy;
    float2 grad01 = Grad(MurmurHash(gps.xw, seed)).xy;
    float2 grad10 = Grad(MurmurHash(gps.zy, seed)).xy;
    float2 grad11 = Grad(MurmurHash(gps.zw, seed)).xy;

    float4 dots = float4(
        dot(offSet.xy, grad00),
        dot(offSet.xw, grad01),
        dot(offSet.zy, grad10),
        dot(offSet.zw, grad11));

    offSet.xy = fade(offSet.xy);
    float2 lx = lerp(dots.xy, dots.zw, offSet.x);
    return lerp(lx.x, lx.y, offSet.y);
}

float PerlinNoise3(float3 uvw, uint seed, uint3 wrap)
{
    float3 offSet = frac(uvw);
    float3 negOffSet = offSet - 1;
    
    uint3 gp = floor(uvw);
    uint3 gp1 = (gp + 1) % wrap;

    float3 grad000 = Grad(MurmurHash(gp, seed));
    float3 grad001 = Grad(MurmurHash(uint3(gp.xy, gp1.z), seed));
    float3 grad010 = Grad(MurmurHash(uint3(gp.x, gp1.y, gp.z), seed));
    float3 grad011 = Grad(MurmurHash(uint3(gp.x, gp1.yz), seed));
    float3 grad100 = Grad(MurmurHash(uint3(gp1.x, gp.yz), seed));
    float3 grad101 = Grad(MurmurHash(uint3(gp1.x, gp.y, gp1.z), seed));
    float3 grad110 = Grad(MurmurHash(uint3(gp1.xy, gp.z), seed));
    float3 grad111 = Grad(MurmurHash(gp1, seed));

    float4 dots0 = float4(
        dot(offSet, grad000),
        dot(float3(offSet.xy, negOffSet.z), grad001),
        dot(float3(offSet.x, negOffSet.y, offSet.z), grad010),
        dot(float3(offSet.x, negOffSet.yz), grad011));
    float4 dots1 = float4(
        dot(float3(negOffSet.x, offSet.yz), grad100),
        dot(float3(negOffSet.x, offSet.y, negOffSet.z), grad101),
        dot(float3(negOffSet.xy, offSet.z), grad110),
        dot(negOffSet, grad111));

    offSet = fade(offSet);
    float4 lx = lerp(dots0, dots1, offSet.x);
    float2 ly = lerp(lx.xy, lx.zw, offSet.y);
    return lerp(ly.x, ly.y, offSet.z);
}

float WorleyNoise2(float2 uv, uint seed, uint2 wrap)
{
    uint2 gp = floor(uv);        // 晶格坐标
    float minDistance = 2.0f;
    int2 offsetN = -1;
    for(; offsetN.x <= 1; offsetN.x++)
    {
        for(offsetN.y = -1; offsetN.y <= 1; offsetN.y++)
        {
            int2 neighbor = gp + offsetN;
            float d = length(neighbor - uv + Hash33(float3(neighbor % wrap, seed / float(0xffffffff))).xy);
            minDistance = min(minDistance, d);
        }
    }

    return minDistance;
}

float WorleyNoise3(float3 uvw, uint seed, int3 wrap)
{
    uint3 gp = floor(uvw);
    float minDistance = 1.0f;
    int3 offsetN = -1;
    for(; offsetN.x <= 1; offsetN.x++)
    {
        for(offsetN.y = -1; offsetN.y <= 1; offsetN.y++)
        {
            for(offsetN.z = -1; offsetN.z <= 1; offsetN.z++)
            {
                uint3 neighbor = gp + offsetN;
                float d = length(neighbor - uvw + Hash44(float4(neighbor % wrap, seed / float(0xffffffff))).xyz);
                minDistance = min(minDistance, d);
            }
        }
    }

    return minDistance;
}

float2 hash( float2 p ) // replace this by something better
{
    p = float2( dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)) );
    return -1.0 + 2.0*frac(sin(p)*43758.5453123);
}

float SimplexNoise2(float2 uv, uint seed)
{
    uint2 s_uv0 = floor(uv + (uv.x + uv.y) * 0.366025404f);         // 所在网格坐标
    float2 d0 = uv - s_uv0 + (s_uv0.x + s_uv0.y) * 0.211324865f;    // 将三角晶格坐标s_uv0进行逆skew变换并计算标准坐标系下uv相对它的偏移
    float s = step(d0.y, d0.x);
    uint2 s_uv0Tuv1 = int2(s, 1 - s);                               // 确定坐标在哪个三角形，得到三角晶格坐标下s_o_uv1 = 第二个晶格点坐标 - 第一个晶格点坐标
    
    // 相对第二和第三个的顶点的偏移, 等于第二个顶点和第三个顶点相对晶格原点的偏移减去坐标相对晶格原点的偏移
    // 第二个顶点坐标通过对s_o_uv1应用Skew逆变换获得
    float2 d1 = d0 - s_uv0Tuv1 + 0.2113248654f;                     // d0 - (s_o_uv1 - (s_o_uv1.x + s_o_uv1.y) * simplexFac2) = d0 - uv1 + 1 * simplexFac2
    float2 d2 = d0 - 0.5773502692f;                                 // d0 - (s_o_uv2 - (s_o_uv2.x + s_o_uv2.y) * simplexFac2) = d0 - 1 + 2 * simplexFac2    (s_o_uv2 = (1, 1))
    float3 t = max(0, 0.6f - float3(dot(d0, d0), dot(d1, d1), dot(d2, d2)));
    float3 dots = float3(
        dot(Grad(MurmurHash(s_uv0, seed)), d0),
        dot(Grad(MurmurHash(s_uv0 + s_uv0Tuv1, seed)), d1),
        dot(Grad(MurmurHash(s_uv0 + 1, seed)), d2));
    
    t *= t;
    return dot(24 * t * t, dots);                                   // 计算三个顶点的贡献, max(0, (0.6 - |dist|^2))^4 * dot(grad, dist)
}


#endif