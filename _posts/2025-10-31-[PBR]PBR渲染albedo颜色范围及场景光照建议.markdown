---
layout: post
title: "[PBR]PBR渲染albedo颜色范围"
categories: [渲染, PBR]
tags: 渲染 PBR 基础 URP
math: true


---

# [PBR]PBR渲染albedo颜色范围及场景光照建议

## 00 结论

---

### BaseColor取值范围

**非金属BaseColor建议sRGB值**: (30)50-240(250)

**金属BaseColor建议sRGB值**: 180-255

注: (30)50的意义是, 严格意义上, 是50, 根据实际情况, 可以调低到30, 但因为调整到30导致的光照问题自行处理

---

### 场景光照建议(URP管线)

场景主光源

强度: 0.31830 * 2



注: Unity在URP下的光强度需要除以 $\pi$ 才符合正确的光照计算. 此处的强度实际上等于2

---

## 01 前置信息

### Unity

[真实表面Metallic工作流与Specular工作流参数参考](https://docs.unity3d.com/6000.2/Documentation/Manual/StandardShaderMaterialCharts.html)

#### Metallic工作流

![Reference Chart for Metallic settings](/assets/image/StandardShaderCalibrationChartMetallic.png)

#### Specular工作流

![Reference Chart for Specular settings](/assets/image/StandardShaderCalibrationChartSpecular.png)

### Substance

注: Substance被Adobe收购之后, 其官方文档访问受限, 目前参考的是第三方翻译的版本

其中在[The PBR Guide 2](https://isux.tencent.com/articles/THE-PBR-GUIDE-2.html)中, 在关于Albedo贴图制作部分有如下内容:

>**制图指引**
>
>Base Color贴图的色调一般看起来会比较平，它的对比度会低于传统的Diffuse贴图（传统的Diffuse贴图带有光影信息），因为在贴图中，如果数值太亮或太暗可能都会影响后续的光影渲染效果。物体在光影色调中的实际效果通常比我们印象中存在的样子亮很多。可以试想一下，以碳作为最黑的物质，而雪作为最亮的物质。虽然碳的固有色看上去是黑的，但是它不是0.0的黑，同样雪也不是1.0白。所以我们对于基础色的选择需要在一定的亮度范围内，这样物体在渲染环境中才能表现出较更明亮的高光和更深邃的阴影。
>
>说到亮度范围，这里通常是指非导体（电介质）材质反射的颜色。在图23中，你可以看到污垢的色值超出正确亮度范围的效果（红色区域）。对于暗色值，尽量不要低于30-50 sRGB，严格控制下应该不低于50 sRGB。对于亮色值，贴图中也不应该有色值高于240 sRGB。
>
><img src="/assets/image/image-20251031100333536.png" alt="image-20251031100333536" style="zoom:50%;" />
>
>...
>
>当Base Color贴图中的值是指金属的反射值时，这些值应当采用真实世界中的测量值。这些值大概会有70-100%的镜面反射，映射到sRGB大概为180-255。

### 综合考虑

在采用金属工作流的基础上, 

| 组织      | 非金属(sRGB值)  | 金属(sRGB值) |
| --------- | --------------- | ------------ |
| Unity     | 50-243          | 186-255      |
| Substance | (30)50-240(249) | 180-255      |
| 作者      | (30)50-240(250) | 180-255      |

注: 取值原因仅仅是取整后便于记忆, 无任何渲染计算层面的考量.



###### 参考网页

[Unity - Manual: Reference for metallic and specular values of real surfaces](https://docs.unity3d.com/6000.2/Documentation/Manual/StandardShaderMaterialCharts.html)

[ISUX译文 \| The PBR Guide 基于物理的渲染指引(上) - Tencent ISUX Design](https://isux.tencent.com/articles/THE-PBR-GUIDE-1.html)

[ISUX译文 \| The PBR Guide基于物理的渲染指引(下) - Tencent ISUX Design](https://isux.tencent.com/articles/THE-PBR-GUIDE-2.html)
