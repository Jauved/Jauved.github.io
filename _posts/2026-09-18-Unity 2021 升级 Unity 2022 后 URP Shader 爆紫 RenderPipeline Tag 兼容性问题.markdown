---
layout: post
title: "Unity 2021 升级 Unity 2022 后 URP Shader 爆紫 RenderPipeline Tag 兼容性问题"
categories: [URP, 后处理]
tags: URP 后处理 DepthOfField
math: true


---

# Unity 2021 升级 Unity 2022 后 URP Shader 爆紫: RenderPipeline Tag 兼容性问题

## A. 结论与解决方案

在 Unity 2021 / URP 12 工程迁移到 Unity 2022 / URP 14 后, 部分原本可以正常工作的手写 URP Shader 在 Android OpenGL ES 设备上出现爆紫(ErrorShader).

最终定位到 ShaderLab 中的 `RenderPipeline` Tag:

```
Tags
{
    "RenderPipeline" = "UniversalRenderPipeline"
}
```

应修改为:

```
Tags
{
    "RenderPipeline" = "UniversalPipeline"
}
```

修正后 Shader 恢复正常.

发生该问题时, 有如下特征:

- 使用FrameDebugger可以看到, 渲染错误的对象最终采用的着色器版本是"Hidden/InternalErrorShader"
- 通常来说"Hidden/InternalErrorShader"这种情况在编辑器中就可以看到Shader文件的Inspector报错和渲染异常, 但编辑器没有报任何错误且没有渲染异常
- 编辑器Shader文件不报任何异常且渲染正确+真机采用"Hidden/InternalErrorShader"且渲染异常, 那么大概率可以锁定是这个情况.

## B. 历史遗留问题与版本测试

需要特别注意:

> `"UniversalRenderPipeline"` 并不是 URP 12 的旧正确写法. `"UniversalPipeline"` 在 URP 12 时就已经是正式的 Shader Tag.
>
> Unity 2021 以及 Unity 2022.3.4f1 以前只是仍然容忍了 `"UniversalRenderPipeline"` 这一错误值. 从 Unity `2022.3.5f1` 开始, 这一错误写法会被严格判定为与当前 Render Pipeline 不兼容.

Unity 官方 Issue Tracker 给出的可复现边界为:

```
Unity 2021.3.x       正常
Unity 2022.3.4f1     正常

----------------------------

Unity 2022.3.5f1     爆紫
Unity 2022.3.52f1    爆紫
Unity 6              爆紫
```

Unity 将该行为标记为符合设计, 修复方式就是:

```
"RenderPipeline" = "UniversalPipeline"
```



因此, 对 Unity 2021 -> Unity 2022.3.5+ 的工程迁移, 建议将以下检查加入 Shader 迁移 Checklist:

```
错误:
"RenderPipeline" = "UniversalRenderPipeline"

正确:
"RenderPipeline" = "UniversalPipeline"
```

## C. 为什么会遗留"错误"写法

既然`"RenderPipeline" = "UniversalRenderPipeline"`是"错误"写法, 为什么会遗留下来?

答案就在于"不要"相信"https://docs.unity.cn"的任何文档. 而是去"https://docs.unity3d.com"查询文档.

在"https://docs.unity.cn"查询到的2022.3版本的文档关于[RenderPipeline tag](https://docs.unity.cn/2022.3/Documentation/Manual/SL-SubShaderTags.html)的文档内容如下:

>RenderPipeline tag
>
> The `RenderPipeline` tag tells Unity whether a SubShader is compatible with the Universal Render Pipeline (URP) or the High Definition Render Pipeline (HDRP).
>
>### Syntax and valid values
>
>| **Signature**               | **Function**                                                 |
| :-------------------------- | :----------------------------------------------------------- |
| “RenderPipeline” = “[name]” | Tells Unity whether this SubShader is compatible with URP or HDRP. |
>
>| **Parameter** | **Value**                          | **Function**                                       |
| :------------ | :--------------------------------- | :------------------------------------------------- |
| [name]        | UniversalRenderPipeline            | This SubShader is compatible with URP only.        |
|               | HighDefinitionRenderPipeline       | This SubShader is compatible with HDRP only.       |
|               | (any other value, or not declared) | This SubShader is not compatible with URP or HDRP. |

而"https://docs.unity3d.com"查询到的2022.3版本的文档关于[RenderPipeline tag](https://docs.unity3d.com/2022.3/Documentation/Manual/SL-SubShaderTags.html)的文档内容如下:

>RenderPipeline tag
>
>The `RenderPipeline` tag tells Unity whether a SubShader is compatible with the Universal Render Pipeline (URP) or the High Definition Render Pipeline (HDRP).
>
>### Syntax and valid values
>
| **Signature**               | **Function**                                                 |
| :-------------------------- | :----------------------------------------------------------- |
| “RenderPipeline” = “[name]” | Tells Unity whether this SubShader is compatible with URP or HDRP. |
>
| **Parameter** | **Value**                                         | **Function**                                       |
| :------------ | :------------------------------------------------ | :------------------------------------------------- |
| [name]        | <font color = "orange">`UniversalPipeline`</font> | This SubShader is compatible with URP only.        |
|               | <font color = "orange">`HDRenderPipeline`</font>  | This SubShader is compatible with HDRP only.       |
|               | (any other value, or not declared)                | This SubShader is not compatible with URP or HDRP. |

也就是说, 该规则取消兼容应该是在`Unity 2022.3.5f1`这个版本(从文档反推则与此结论有分歧, 具体见D.其他栏), 但是对应的文档更新仅在"https://docs.unity3d.com"进行了更新.

## D. 其他

通过查询"https://docs.unity3d.com"的文档, 仅从文档有如下事实: 

- 2020.3, 2021.1, 2021.2版本的RenderPipeline Tag是: UniversalRenderPipeline 和 HighDefinitionRenderPipeline

- 2021.3 及之后的版本的RenderPipeline Tag都改为了: <font color="orange">UniversalPipeline</font> 和 <font color = "orange">HDRenderPipeline</font>. 且进行了标红(此处为橙色仅仅是降低对眼睛的刺激).

## 参考网页

- [Unity Issue Tracker - HLSL shader becomes corrupted when running on an Android device](https://issuetracker.unity.com/issues/12703/hlsl-shader-becomes-corrupted-when-running-on-an-android-device)
- [Unity Issue Tracker - Custom Shader Material is pink when the project is built for the WebGL platform](https://issuetracker.unity.com/issues/8033/custom-shader-material-is-pink-when-the-project-is-built-for-the-webgl-platform)
- [ShaderLab：向子着色器分配标签 - Unity 手册](https://docs.unity.cn/cn/2022.3/Manual/SL-SubShaderTags.html)
- [Unity - Manual: ShaderLab: assigning tags to a SubShader](https://docs.unity.cn/2022.3/Documentation/Manual/SL-SubShaderTags.html)
- [Unity - Manual: ShaderLab: assigning tags to a SubShader](https://docs.unity3d.com/2022.3/Documentation/Manual/SL-SubShaderTags.html)
