---
layout: post
title: "UnityShader内置变量"
categories: [URP, 渲染]
tags: URP Shader 渲染
math: true

---

# UnityShader内置变量

## 00 前言

## 01 内置着色器变量

Unity 的内置文件包含着色器的全局变量：当前对象的变换矩阵、光源参数、当前时间等等。就像任何其他变量一样，可在[着色器程序](https://docs.unity.cn/cn/2021.3/Manual/SL-ShaderPrograms.html)中使用这些变量，但如果已经包含相关的 include 文件，则不必声明这些变量。

有关 include 文件更多信息，请参阅[内置 include 文件](https://docs.unity.cn/cn/2021.3/Manual/SL-BuiltinIncludes.html)。

### 变换

所有这些矩阵都是 `float4x4` 类型，并且是列主序的。

|                     |                              |
| :------------------ | :--------------------------- |
| **名称**            | **值**                       |
| UNITY_MATRIX_MVP    | 当前模型 * 视图 * 投影矩阵。 |
| UNITY_MATRIX_MV     | 当前模型 * 视图矩阵。        |
| UNITY_MATRIX_V      | 当前视图矩阵。               |
| UNITY_MATRIX_P      | 当前投影矩阵。               |
| UNITY_MATRIX_VP     | 当前视图 * 投影矩阵。        |
| UNITY_MATRIX_T_MV   | 模型转置 * 视图矩阵。        |
| UNITY_MATRIX_IT_MV  | 模型逆转置 * 视图矩阵。      |
| unity_ObjectToWorld | 当前模型矩阵。               |
| unity_WorldToObject | 当前世界矩阵的逆矩阵。       |

### 摄像机和屏幕

这些变量将对应于正在渲染的[摄像机](https://docs.unity.cn/cn/2021.3/Manual/class-Camera.html)。例如，在阴影贴图渲染中，它们仍将引用摄像机组件值，而不是用于阴影贴图投影的“虚拟摄像机”。

|                                |          |                                                              |
| :----------------------------- | :------- | :----------------------------------------------------------- |
| **名称**                       | **类型** | **值**                                                       |
| _WorldSpaceCameraPos           | float3   | 摄像机的世界空间位置。                                       |
| _ProjectionParams              | float4   | `x` 是 1.0（如果当前使用[翻转投影矩阵](https://docs.unity.cn/cn/2021.3/Manual/SL-PlatformDifferences.html)进行渲染，则为 –1.0），`y` 是摄像机的近平面，`z` 是摄像机的远平面，`w` 是远平面的倒数。 |
| _ScreenParams                  | float4   | `x` 是摄像机目标纹理的宽度（以像素为单位），`y` 是摄像机目标纹理的高度（以像素为单位），`z` 是 1.0 + 1.0/宽度，`w` 为 1.0 + 1.0/高度。 |
| _ZBufferParams                 | float4   | 用于线性化 Z 缓冲区值。`x` 是 (1-远/近)，`y` 是 (远/近)，`z` 是 (x/远)，`w` 是 (y/远)。 |
| unity_OrthoParams              | float4   | `x` 是正交摄像机的宽度，`y` 是正交摄像机的高度，`z` 未使用，`w` 在摄像机为正交模式时是 1.0，而在摄像机为透视模式时是 0.0。 |
| unity_CameraProjection         | float4x4 | 摄像机的投影矩阵。                                           |
| unity_CameraInvProjection      | float4x4 | 摄像机投影矩阵的逆矩阵。                                     |
| unity_CameraWorldClipPlanes[6] | float4   | 摄像机视锥体平面世界空间方程，按以下顺序：左、右、底、顶、近、远。 |

### 时间

时间以秒为单位，并由项目 [Time 设置](https://docs.unity.cn/cn/2021.3/Manual/class-TimeManager.html)中的时间乘数 (Time multiplier) 进行缩放。没有内置变量可用于访问未缩放的时间。

|                 |          |                                                              |
| :-------------- | :------- | :----------------------------------------------------------- |
| **名称**        | **类型** | **值**                                                       |
| _Time           | float4   | 自关卡加载以来的时间 (t/20, t, t*2, t*3)，用于将着色器中的内容动画化。 |
| _SinTime        | float4   | 时间正弦：(t/8, t/4, t/2, t)。                               |
| _CosTime        | float4   | 时间余弦：(t/8, t/4, t/2, t)。                               |
| unity_DeltaTime | float4   | 增量时间：(dt, 1/dt, smoothDt, 1/smoothDt)。                 |

### 光照

光源参数以不同的方式传递给着色器，具体取决于使用哪个[渲染路径](https://docs.unity.cn/cn/2021.3/Manual/RenderingPaths.html)， 以及着色器中使用哪种光源模式[通道标签](https://docs.unity.cn/cn/2021.3/Manual/SL-PassTags.html)。

[前向渲染](https://docs.unity.cn/cn/2021.3/Manual/RenderTech-ForwardRendering.html)（`ForwardBase` 和 `ForwardAdd` 通道类型）：

|                                                         |             |                                                              |
| :------------------------------------------------------ | :---------- | :----------------------------------------------------------- |
| **名称**                                                | **类型**    | **值**                                                       |
| _LightColor0*（在 UnityLightingCommon.cginc 中声明）*   | fixed4      | 光源颜色。                                                   |
| _WorldSpaceLightPos0                                    | float4      | 方向光：（世界空间方向，0）。其他光源：（世界空间位置，1）。 |
| unity_WorldToLight*（在 AutoLight.cginc 中声明）*       | float4x4    | 世界/光源矩阵。用于对剪影和衰减纹理进行采样。                |
| unity_4LightPosX0、unity_4LightPosY0、unity_4LightPosZ0 | float4      | *（仅限 ForwardBase 通道）*前四个非重要点光源的世界空间位置。 |
| unity_4LightAtten0                                      | float4      | *（仅限 ForwardBase 通道）*前四个非重要点光源的衰减因子。    |
| unity_LightColor                                        | half4[4]    | *（仅限 ForwardBase 通道）*前四个非重要点光源的颜色。        |
| unity_WorldToShadow                                     | float4x4[4] | World-to-shadow matrices. One matrix for Spot Lights, up to four for directional light cascades. |

延迟着色和延迟光照，在光照通道着色器中使用（全部在 UnityDeferredLibrary.cginc 中声明）：

|                     |             |                                                              |
| :------------------ | :---------- | :----------------------------------------------------------- |
| **名称**            | **类型**    | **值**                                                       |
| _LightColor         | float4      | 光源颜色。                                                   |
| unity_WorldToLight  | float4x4    | 世界/光源矩阵。用于对剪影和衰减纹理进行采样。                |
| unity_WorldToShadow | float4x4[4] | World-to-shadow matrices. One matrix for Spot Lights, up to four for directional light cascades. |

为 `ForwardBase`、`PrePassFinal` 和 `Deferred` 通道类型设置了球谐函数系数 （由环境光和光照探针使用）。这些系数包含由世界空间法线求值的三阶 SH 函数（请参阅 [UnityCG.cginc](https://docs.unity.cn/cn/2021.3/Manual/SL-BuiltinIncludes.html) 中的 `ShadeSH9`）。 这些变量都是 half4 类型、`unity_SHAr` 和类似名称。

[顶点光照渲染](https://docs.unity.cn/cn/2021.3/Manual/RenderTech-VertexLit.html)（`Vertex` 通道类型）：

最多可为 `Vertex` 通道类型设置 8 个光源；始终从最亮的光源开始排序。因此，如果您希望 一次渲染受两个光源影响的对象，可直接采用数组中前两个条目。如果影响对象 的光源数量少于 8，则其余光源的颜色将设置为黑色。

|                     |           |                                                              |
| :------------------ | :-------- | :----------------------------------------------------------- |
| **名称**            | **类型**  | **值**                                                       |
| unity_LightColor    | half4[8]  | 光源颜色。                                                   |
| unity_LightPosition | float4[8] | View-space light positions. (-direction,0) for directional lights; (position,1) for Point or Spot Lights. |
| unity_LightAtten    | half4[8]  | Light attenuation factors. *x* is cos(spotAngle/2) or –1 for non-Spot Lights; *y* is 1/cos(spotAngle/4) or 1 for non-Spot Lights; *z* is quadratic attenuation; *w* is squared light range. |
| unity_SpotDirection | float4[8] | View-space Spot Lights positions; (0,0,1,0) for non-Spot Lights. |

### 光照贴图

|                  |           |                                                          |
| :--------------- | :-------- | :------------------------------------------------------- |
| **名称**         | **类型**  | **值**                                                   |
| unity_Lightmap   | Texture2D | 包含光照贴图信息。                                       |
| unity_LightmapST | float4[8] | 缩放 UV 信息并转换到正确的范围以对光照贴图纹理进行采样。 |

### 雾效和环境光

|                          |          |                                                              |
| :----------------------- | :------- | :----------------------------------------------------------- |
| **名称**                 | **类型** | **值**                                                       |
| unity_AmbientSky         | fixed4   | 梯度环境光照情况下的天空环境光照颜色。                       |
| unity_AmbientEquator     | fixed4   | 梯度环境光照情况下的赤道环境光照颜色。                       |
| unity_AmbientGround      | fixed4   | 梯度环境光照情况下的地面环境光照颜色。                       |
| UNITY_LIGHTMODEL_AMBIENT | fixed4   | 环境光照颜色（梯度环境情况下的天空颜色）。旧版变量。         |
| unity_FogColor           | fixed4   | 雾效颜色。                                                   |
| unity_FogParams          | float4   | 用于雾效计算的参数：(density / sqrt(ln(2))、density / ln(2)、–1/(end-start) 和 end/(end-start))。*x* 对于 Exp2 雾模式很有用；_y_ 对于 Exp 模式很有用，_z_ 和 *w* 对于 Linear 模式很有用。 |



### 其他

|                   |          |                                                              |
| :---------------- | :------- | :----------------------------------------------------------- |
| **名称**          | **类型** | **值**                                                       |
| unity_LODFade     | float4   | 使用 [LODGroup](https://docs.unity.cn/cn/2021.3/Manual/class-LODGroup.html) 时的细节级别淡入淡出。*x* 为淡入淡出（0 到 1），_y_ 为量化为 16 级的淡入淡出，_z_ 和 *w* 未使用。 |
| _TextureSampleAdd | float4   | 根据所使用的纹理是 Alpha8 格式（值设置为 (1,1,1,0)）还是不是该格式（值设置为 (0,0,0,0)）由 Unity **仅针对 UI** 自动设置。 |

###### 参考网页

[内置着色器变量 - Unity 手册](https://docs.unity.cn/cn/2021.3/Manual/SL-UnityShaderVariables.html)
