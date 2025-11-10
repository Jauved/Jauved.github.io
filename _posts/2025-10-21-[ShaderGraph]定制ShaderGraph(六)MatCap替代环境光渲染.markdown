---
layout: post
title: "[ShaderGraph]定制ShaderGraph(六)MatCap替代环境光渲染"
categories: [URP, ShaderGraph]
tags: URP ShaderGraph 定制 PBR MatCap 环境光
math: true


---

# [ShaderGraph]定制ShaderGraph(六)MatCap替代环境光渲染

## 00 前置知识

> MatCap（Material Capture，也常叫做 “球面环境贴图” 或 “法线贴图”）是一种极其轻量级的实时着色方法，它将复杂的光照计算预先渲染到一张贴图上，并在运行时只通过法线查表来完成最终的着色

我们不需要整体对物体采用MatCap渲染, 这一次我们仅仅用MatCap来替换掉环境光镜面反射部分, 以及拟合环境光漫反射部分.

## 01 实施

### View空间法线

首先, 我们需要得到View空间的法线, 然后才能在View空间对MatCap图进行采样. 

Unity内部没有`TransformWorldToViewNormal`的函数, 但我们可以在`SpaceTransforms.hlsl`文件中找到`TransformObjectToWorldNormal`和`TransformWorldToObjectNormal`函数, 我们可以仿照其形式进行法线转换. 

因为法线转换与方向和坐标转换不同, 法线转换需要的是`mul(变换矩阵的逆转置矩阵, 法线)`, 在hlsl中实际操作是`mul(法线, 变换矩阵的逆矩阵)`. 

```c++
// Transforms normal from object to world space
float3 TransformObjectToWorldNormal(float3 normalOS, bool doNormalize = true)
{
#ifdef UNITY_ASSUME_UNIFORM_SCALING
    return TransformObjectToWorldDir(normalOS, doNormalize);
#else
    // Normal need to be multiply by inverse transpose
    float3 normalWS = mul(normalOS, (float3x3)GetWorldToObjectMatrix());
    if (doNormalize)
        return SafeNormalize(normalWS);

    return normalWS;
#endif
}

// Transforms normal from world to object space
float3 TransformWorldToObjectNormal(float3 normalWS, bool doNormalize = true)
{
#ifdef UNITY_ASSUME_UNIFORM_SCALING
    return TransformWorldToObjectDir(normalWS, doNormalize);
#else
    // Normal need to be multiply by inverse transpose
    float3 normalOS = mul(normalWS, (float3x3)GetObjectToWorldMatrix());
    if (doNormalize)
        return SafeNormalize(normalOS);

    return normalOS;
#endif
}
```

仿照写出来结果是:

```c++
float4x4 GetViewToWorldMatrix()
{
    return UNITY_MATRIX_I_V;
}

// 仿照TransformObjectToWorldNormal
float3 TransformWorldToViewNormal(real3 normalWS, bool doNormalize = false)
{
    #ifdef UNITY_ASSUME_UNIFORM_SCALING
    return TransformWorldToViewDir(normalWS, doNormalize);
    #else
    float3 normalVS = mul(normalWS, (float3x3)GetViewToWorldMatrix());
    if (doNormalize)
        return SafeNormalize(normalVS);
    return normalVS;
    #endif
}
```

原理和步骤:

- 我们先要得到WorldToView的逆矩阵`UNITY_MATRIX_I_V`, 该内置变量可以在`Input.hlsl`中找到.

  ```c
  #define UNITY_MATRIX_V     unity_MatrixV
  #define UNITY_MATRIX_I_V   unity_MatrixInvV
  ```

- 如果是统一缩放, 则`mul(变换矩阵, 法线)`即可.

- 如果是非统一缩放, 则`mul(法线, 变换矩阵的逆矩阵).

- 是否归一化与Unity原写法一致.

### MatCap采样UV

通常来说, MatCap的采样UV就是`normalVS.xy * 0.5 + 0.5`, 但是这样的算法对于平面不友好, 因为平面的采样对于MatCap图来说就是一个点, 会导致整个平面只有单色. 此时, 需要用反射采样的方式获取到UV, 即`normalize(reflect(-viewDirVS, normalVS)).xy;`. 同时我们使用`ddx(normalVS)和ddy(normalVS)`的和, 即x方向和y方向的法线变化率来判断是不是平面, 如果变化率小于设定的值, 则认定为平面, 走反射采样的UV, 如果不是平面则走通常的MatCapUV. 这样可以得到比较好的效果.

以下代码用lerp替代了分支判断, 是优化性能的一种方式, 原理是一样的.

注: 

- 全部的计算都在View空间下进行.
- 这里之所以要用一个`uvScale = 0.95`是不希望采样过节, 实际上0.99也是可以的, 为了更多的安全区域, 取的`0.95`.

```c
float2 MatCapUV(real3 normalVS, real3 viewDirVS, float uvScale = 0.95)
{
    float3 dNx = ddx(normalVS);
    float3 dNy = ddy(normalVS);
    float curvature = length(dNx) + length(dNy);

    float PlanarEpsilon = 0.001;

    float w = saturate(curvature / PlanarEpsilon);

    float2 uv_normal = normalVS.xy;
    float2 uv_reflection = normalize(reflect(-viewDirVS, normalVS)).xy;

    float2 uv = lerp(uv_reflection, uv_normal, w) * uvScale * 0.5 + 0.5;
    return uv;

    if (curvature > PlanarEpsilon)
    {
        return normalVS.xy * uvScale * 0.5 + 0.5;
    }
    else
    {
        float3 R = normalize(reflect(-viewDirVS, normalVS));
        return R.xy * uvScale * 0.5 + 0.5;
    }
}
```

### GlossyEnvironmentReflectionMatCap函数

最终, 我们再次仿照`GlossyEnvironmentReflection`函数(文件`GlobalIllumination.hlsl`中)得到了`GlossyEnvironmentReflectionMatCap`函数, 通常来说MatCap不会是HDR图片, 所以我们不用去进行HDR图的解码.

注意: 这里的`fadeIndirectDiffuse = half4(SAMPLE_TEXTURE2D_LOD(matCapTexture, matCapSampleState, matCapUV, 6)).rgb;`, 是trick, 仅仅只是用高度模糊的`indirectSpecular`来替代. 后续可以优化.

```c++
void GlossyEnvironmentReflectionMatCap(Texture2D matCapTexture, SamplerState matCapSampleState,
                                       half perceptualRoughness, float3 normalWS, float3 viewDirVS, half occlusion,
                                       out float3 indirectSpecular, out float3 fadeIndirectDiffuse)
{
    #if !defined(_ENVIRONMENTREFLECTIONS_OFF)
    half3 irradianceMatCap;

    float3 normalVS = TransformWorldToViewNormal(normalWS, true);
    float2 matCapUV = MatCapUV(normalVS, viewDirVS);

    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    half4 encodedIrradianceMatCap = half4(SAMPLE_TEXTURE2D_LOD(matCapTexture, matCapSampleState, matCapUV, mip));

    fadeIndirectDiffuse = half4(SAMPLE_TEXTURE2D_LOD(matCapTexture, matCapSampleState, matCapUV, 6)).rgb;

    // #if defined(UNITY_USE_NATIVE_HDR)
    irradianceMatCap = encodedIrradianceMatCap.rgb;
    // #else
    // irradianceMatCap = DecodeHDRExr(encodedIrradianceMatCap, unity_SpecCube0_HDR);
    // #endif
    indirectSpecular = irradianceMatCap * occlusion;
    #else
    #ifndef SHADERGRAPH_PREVIEW
    indirectSpecular = _GlossyEnvironmentColor.rgb * occlusion;
    #else
    indirectSpecular = float3(0, 0, 0);
    #endif
    #endif
}
```

### 自定义ShaderGraph的部分

把`Indirect Diffuse`和`Indirect Specular`替换接口暴露出来. 由于我们使用的是MatCap模拟`Indirect Specular`, 而此时我们是拿不到正确的`Indirect Diffuse`的. 后续可以考虑预烘焙一张对应的漫反射MatCap. 最终调用的`GlobalIllumination`如下. 其实就是在进入这个函数之前, 用`fadeIndirectDiffuse`替换掉`bakedGI`, 然后在这个函数中, 用接入的`customIndirectSpecular`替换掉`indirectSpecular`. 

```c++
half3 GlobalIlluminationExtension(BRDFData brdfData, BRDFData brdfDataClearCoat, float clearCoatMask,
    half3 bakedGI, half occlusion, float3 positionWS,
    half3 normalWS, half3 viewDirectionWS, half3 customIndirectSpecular)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half NoV = saturate(dot(normalWS, viewDirectionWS));
    half fresnelTerm = Pow4(1.0 - NoV);

    half3 indirectDiffuse = bakedGI;
#ifdef _GIMODE_CUSTOM
    half3 indirectSpecular = customIndirectSpecular;
#else
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, positionWS, brdfData.perceptualRoughness, 1.0h);
#endif

    half3 color = EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);

    if (IsOnlyAOLightingFeatureEnabled())
    {
        color = half3(1,1,1); // "Base white" for AO debug lighting mode
    }

    #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
    half3 coatIndirectSpecular = GlossyEnvironmentReflection(reflectVector, positionWS, brdfDataClearCoat.perceptualRoughness, 1.0h);
    // TODO: "grazing term" causes problems on full roughness
    half3 coatColor = EnvironmentBRDFClearCoat(brdfDataClearCoat, clearCoatMask, coatIndirectSpecular, fresnelTerm);

    // Blend with base layer using khronos glTF recommended way using NoV
    // Smooth surface & "ambiguous" lighting
    // NOTE: fresnelTerm (above) is pow4 instead of pow5, but should be ok as blend weight.
    half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * fresnelTerm;
    return (color * (1.0 - coatFresnel * clearCoatMask) + coatColor) * occlusion;
    #else
    return color * occlusion;
    #endif
}
```



## 参考网页

- [nidorx/matcaps: Huge library of matcap PNG textures organized by color](https://github.com/nidorx/matcaps)
