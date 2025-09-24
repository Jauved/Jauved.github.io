---
layout: post
title: "定制ShaderGraph(五)---PBR的核心算法实现"
categories: [URP, ShaderGraph]
tags: URP ShaderGraph 定制 PBR
math: true


---

# 定制ShaderGraph(五)---PBR的核心算法实现

## 00 前置知识

HDRP去除全部的干扰项才能够看到具体的计算结构.

HDRP默认就启用了大量的后处理和额外的光照系统, 现在我们来一个一个的关掉.

建立一个HDRP的空工程的空场景.

找到你的默认Volume文件, Reset它.

![image-20250916162352440](/assets/image/image-20250916162352440.png)

创建一个相机, 参数如下, 只有橙框内的参数才是重要的.

- 角度调整可以根据你的物体的需要改变
- Background Type一定要选Color并且选成黑色, 不然Buffer不刷新

<img src="/assets/image/image-20250916162803505.png" alt="image-20250916162803505" style="zoom:50%;" />

创建一盏灯光, 参数如下

- 角度可以格局你的需要进行调整
- 强度为Pi, 3.1415926535...

<img src="/assets/image/image-20250916163141643.png" alt="image-20250916163141643" style="zoom:50%;" />

创建一个Sphere对象, 新建材质球, 无需设置, 参数如下

<img src="/assets/image/image-20250916163506314.png" alt="image-20250916163506314" style="zoom:50%;" />

然后你就可以在Game窗口得到最基础的光照模型表现

<img src="/assets/image/image-20250916163625064.png" alt="image-20250916163625064" style="zoom:50%;" />

类似的方式, 在URP中, 得到的图像是这样, 整体会比HDRP的要亮一些, 但目前我没有找到原因.

<img src="/assets/image/image-20250916164047370.png" alt="image-20250916164047370" style="zoom:50%;" />

注意: 在URP中, 如果你开启了相机的Post Processing, 那么一定要选择`High Dynamic Range`, 不然你的黑色会被映射成(13,13,0)的颜色

<img src="/assets/image/image-20250916165934376.png" alt="image-20250916165934376" style="zoom:50%;" />

## 01 预热

说了那么一大段的前置知识, 仅仅是为了说明, 在(URP中光强度1)=(HDRP中光强度PI).

原因在于HDRP核心算法`EvaluateBSDF`中,  `float diffTerm = Lambert();`这里的Lambert(), 代码是

```c#
real Lambert()
{
    return INV_PI;
}
```

核心代码

HDRP

- `Library/PackageCache/com.unity.render-pipelines.high-definition@d4732d67dfef/Runtime/Material/Lit/Lit.hlsl`
- `EvaluateBSDF`()

URP

- `Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/ShaderLibrary/Lighting.hlsl`
- `LightingPhysicallyBased()`

下面开始移植

## 02 PBR

URP的核心函数

```c#
// Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/ShaderLibrary/Lighting.hlsl
half3 LightingPhysicallyBased(BRDFData brdfData, BRDFData brdfDataClearCoat,
    half3 lightColor, half3 lightDirectionWS, half lightAttenuation,
    half3 normalWS, half3 viewDirectionWS,
    half clearCoatMask, bool specularHighlightsOff)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);

    half3 brdf = brdfData.diffuse;
#ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        brdf += brdfData.specular * DirectBRDFSpecular(brdfData, normalWS, lightDirectionWS, viewDirectionWS);

#if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        // Clear coat evaluates the specular a second timw and has some common terms with the base specular.
        // We rely on the compiler to merge these and compute them only once.
        half brdfCoat = kDielectricSpec.r * DirectBRDFSpecular(brdfDataClearCoat, normalWS, lightDirectionWS, viewDirectionWS);

            // Mix clear coat and base layer using khronos glTF recommended formula
            // https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_materials_clearcoat/README.md
            // Use NoV for direct too instead of LoH as an optimization (NoV is light invariant).
            half NoV = saturate(dot(normalWS, viewDirectionWS));
            // Use slightly simpler fresnelTerm (Pow4 vs Pow5) as a small optimization.
            // It is matching fresnel used in the GI/Env, so should produce a consistent clear coat blend (env vs. direct)
            half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * Pow4(1.0 - NoV);

        brdf = brdf * (1.0 - clearCoatMask * coatFresnel) + brdfCoat * clearCoatMask;
#endif // _CLEARCOAT
    }
#endif // _SPECULARHIGHLIGHTS_OFF

    return brdf * radiance;
}
```



HDRP的核心函数

```c#
// Library/PackageCache/com.unity.render-pipelines.high-definition@d4732d67dfef/Runtime/Material/Lit/Lit.hlsl
CBSDF EvaluateBSDF(float3 V, float3 L, PreLightData preLightData, BSDFData bsdfData)
{
    CBSDF cbsdf;
    ZERO_INITIALIZE(CBSDF, cbsdf);

    float3 N = bsdfData.normalWS;

    float NdotV = preLightData.NdotV;
    float NdotL = dot(N, L);
    float clampedNdotV = ClampNdotV(NdotV);
    float clampedNdotL = saturate(NdotL);
    float flippedNdotL = ComputeWrappedDiffuseLighting(-NdotL, TRANSMISSION_WRAP_LIGHT);
    float diffuseNdotL = clampedNdotL;

    float LdotV, NdotH, LdotH, invLenLV;
    GetBSDFAngle(V, L, NdotL, NdotV, LdotV, NdotH, LdotH, invLenLV);

    // This F90 term can be used as a way to suppress completely specular when using the specular workflow.
    float3 F = F_Schlick(bsdfData.fresnel0, bsdfData.fresnel90, LdotH);
    // Remark: Fresnel must be use with LdotH angle. But Fresnel for iridescence is expensive to compute at each light.
    // Instead we use the incorrect angle NdotV as an approximation for LdotH for Fresnel evaluation.
    // The Fresnel with iridescence and NDotV angle is precomputed ahead and here we jsut reuse the result.
    // Thus why we shouldn't apply a second time Fresnel on the value if iridescence is enabled.
    if (HasFlag(bsdfData.materialFeatures, MATERIALFEATUREFLAGS_LIT_IRIDESCENCE))
    {
        F = lerp(F, bsdfData.fresnel0, bsdfData.iridescenceMask);
    }

    float DV;
    if (HasFlag(bsdfData.materialFeatures, MATERIALFEATUREFLAGS_LIT_ANISOTROPY))
    {
        float3 H = (L + V) * invLenLV;

        // For anisotropy we must not saturate these values
        float TdotH = dot(bsdfData.tangentWS, H);
        float TdotL = dot(bsdfData.tangentWS, L);
        float BdotH = dot(bsdfData.bitangentWS, H);
        float BdotL = dot(bsdfData.bitangentWS, L);

        // TODO: Do comparison between this correct version and the one from isotropic and see if there is any visual difference
        // We use abs(NdotL) to handle the none case of double sided
        DV = DV_SmithJointGGXAniso(TdotH, BdotH, NdotH, clampedNdotV, TdotL, BdotL, abs(NdotL),
                                   bsdfData.roughnessT, bsdfData.roughnessB, preLightData.partLambdaV);
    }
    else if (HasFlag(bsdfData.materialFeatures, MATERIALFEATUREFLAGS_SSS_DUAL_LOBE))
    {
        // We reload roughnesses from diffusion profile to save VGPRs. As a result we don't have correct ClampRoughness but it's ok
        float lobeA, lobeB, lobeMix;
        GetDualLobeParameters(bsdfData.diffusionProfileIndex, lobeA, lobeB, lobeMix);

        // We have to inline the call to PerceptualRoughnessToPerceptualSmoothness for better codegen
        float roughnessL = PerceptualSmoothnessToRoughness(saturate(lobeA - bsdfData.perceptualRoughness * lobeA));
        float roughnessH = PerceptualSmoothnessToRoughness(saturate(lobeB - bsdfData.perceptualRoughness * lobeB));

        DV = lerp(DV_SmithJointGGX(NdotH, abs(NdotL), clampedNdotV, roughnessL, preLightData.partLambdaV),
                  DV_SmithJointGGX(NdotH, abs(NdotL), clampedNdotV, roughnessH, preLightData.partLambdaV),
                  lobeMix);
    }
    else
    {
        // We use abs(NdotL) to handle the none case of double sided
        DV = DV_SmithJointGGX(NdotH, abs(NdotL), clampedNdotV, bsdfData.roughnessT, preLightData.partLambdaV);
    }

    float3 specTerm = F * DV;

#ifdef USE_DIFFUSE_LAMBERT_BRDF
    float diffTerm = Lambert();
#else
    // A note on subsurface scattering: [SSS-NOTE-TRSM]
    // The correct way to handle SSS is to transmit light inside the surface, perform SSS,
    // and then transmit it outside towards the viewer.
    // Transmit(X) = F_Transm_Schlick(F0, F90, NdotX), where F0 = 0, F90 = 1.
    // Therefore, the diffuse BSDF should be decomposed as follows:
    // f_d = A / Pi * F_Transm_Schlick(0, 1, NdotL) * F_Transm_Schlick(0, 1, NdotV) + f_d_reflection,
    // with F_Transm_Schlick(0, 1, NdotV) applied after the SSS pass.
    // The alternative (artistic) formulation of Disney is to set F90 = 0.5:
    // f_d = A / Pi * F_Transm_Schlick(0, 0.5, NdotL) * F_Transm_Schlick(0, 0.5, NdotV) + f_retro_reflection.
    // That way, darkening at grading angles is reduced to 0.5.
    // In practice, applying F_Transm_Schlick(F0, F90, NdotV) after the SSS pass is expensive,
    // as it forces us to read the normal buffer at the end of the SSS pass.
    // Separating f_retro_reflection also has a small cost (mostly due to energy compensation
    // for multi-bounce GGX), and the visual difference is negligible.
    // Therefore, we choose not to separate diffuse lighting into reflected and transmitted.

    // Use abs NdotL to evaluate diffuse term also for transmission
    // TODO: See with Evgenii about the clampedNdotV here. This is what we use before the refactor
    // but now maybe we want to revisit it for transmission
    float diffTerm = DisneyDiffuse(clampedNdotV, abs(NdotL), LdotV, bsdfData.perceptualRoughness);
#endif

    if (HasFlag(bsdfData.materialFeatures, MATERIALFEATUREFLAGS_LIT_CLEAR_COAT))
    {
        // Apply isotropic GGX for clear coat
        // Note: coat F is scalar as it is a dieletric
        float coatF = F_Schlick(CLEAR_COAT_F0, LdotH) * bsdfData.coatMask;
        // Scale base specular
        specTerm *= Sq(1.0 - coatF);

        // Add top specular
        // TODO: Should we call just D_GGX here ?
        // We use abs(NdotL) to handle the none case of double sided
        float DV = DV_SmithJointGGX(NdotH, abs(NdotL), clampedNdotV, bsdfData.coatRoughness, preLightData.coatPartLambdaV);
        specTerm += coatF * DV;

        // Note: The modification of the base roughness and fresnel0 by the clear coat is already handled in FillMaterialClearCoatData

        // Very coarse attempt at doing energy conservation for the diffuse layer based on NdotL. No science.
        diffTerm *= lerp(1, 1.0 - coatF, bsdfData.coatMask);
    }

    // Diffuse power modification
    if (HasFlag(bsdfData.materialFeatures, MATERIALFEATUREFLAGS_SSS_DIFFUSE_POWER))
    {
        float power = GetDiffusePower(bsdfData.diffusionProfileIndex);
        diffuseNdotL = pow(diffuseNdotL, max(power + 1, 1.0f));
        diffuseNdotL *= power * 0.5 + 1; // normalize
    }

    // The compiler should optimize these. Can revisit later if necessary.
    cbsdf.diffR = diffTerm * diffuseNdotL;
    cbsdf.diffT = diffTerm * flippedNdotL;

    // Probably worth branching here for perf reasons.
    // This branch will be optimized away if there's no transmission.
    if (NdotL > 0)
    {
        cbsdf.specR = specTerm * clampedNdotL;
    }

    // We don't multiply by 'bsdfData.diffuseColor' here. It's done only once in PostEvaluateBSDF().
    return cbsdf;
}
```





## 参考网页

- 

## 参考代码

- 

  



