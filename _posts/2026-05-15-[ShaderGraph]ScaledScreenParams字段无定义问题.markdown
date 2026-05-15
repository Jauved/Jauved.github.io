---
layout: post
title: "[ShaderGraph]ScaledScreenParams字段无定义问题"
categories: [URP, ShaderGraph]
tags: URP ShaderGraph 定制 ScaledScreenParams 重定义 redefinition 字段
math: true


---

# [ShaderGraph]ScaledScreenParams字段无定义问题

## 00 前置知识

在写`ShaderGraph`的`Custom Function`的时候, 会遇到`undefinition of '_ScaledScreenParams' at line xx`的问题.

实际情况是, 

ShaderGraph在Preview的时候会调用`PreviewTarget`这个`Target`. 

路径是`Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Generation/Targets/PreviewTarget.cs`

能在代码中查到`include`是这些:

```c#
includes = new IncludeCollection
{
    // Pre-graph
    { "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl", IncludeLocation.Pregraph },
    { "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl", IncludeLocation.Pregraph },
    { "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl", IncludeLocation.Pregraph },       // TODO: put this on a conditional
    { "Packages/com.unity.render-pipelines.core/ShaderLibrary/NormalSurfaceGradient.hlsl", IncludeLocation.Pregraph },
    { "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl", IncludeLocation.Pregraph },
    { "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl", IncludeLocation.Pregraph },
    { "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl", IncludeLocation.Pregraph },
    { "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl", IncludeLocation.Pregraph },
    { "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariables.hlsl", IncludeLocation.Pregraph },
    { "Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariablesFunctions.hlsl", IncludeLocation.Pregraph },
    { "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl", IncludeLocation.Pregraph },

    // Post-graph
    { "Packages/com.unity.shadergraph/ShaderGraphLibrary/PreviewVaryings.hlsl", IncludeLocation.Postgraph },
    { "Packages/com.unity.shadergraph/ShaderGraphLibrary/PreviewPass.hlsl", IncludeLocation.Postgraph },
}
```

其中这个文件`Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariables.hlsl`里面有只定义了`_ScreenParams`:

```c
// x = width
// y = height
// z = 1 + 1.0/width
// w = 1 + 1.0/height
float4 _ScreenParams;
```

而运行态时, Unity会用`"Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"`, 该文件中才定义了`_ScaledScreenParams`.

```
float4 _ScaledScreenParams;
```

## 01 解决方案

这个时候在`Custom Function`中, 加入如下宏:

```c
#ifndef SHADERGRAPH_PREVIEW
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#else
#define _ScaledScreenParams _ScreenParams
#endif
```

意思是在`Preview`时, 无视渲染缩放, 统一用`_ScreenParams`既可以解决.

###### 参考网页
