---
layout: post
title: "[ShaderGraph]Time字段重定义问题"
categories: [URP, ShaderGraph]
tags: URP ShaderGraph 定制 PBR Time 重定义 redefinition
math: true


---

# [ShaderGraph]Time字段重定义问题

## 00 前置知识

在写ShaderGraph的Custom Function的时候, 经常会遇到`redefinition of '_Time' at line 40`的问题.

经过排查. 

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

其中这个文件`Packages/com.unity.shadergraph/ShaderGraphLibrary/ShaderVariables.hlsl`里面有如下代码

```c
CBUFFER_START(UnityPerCamera)
    // Time (t = time since current level load) values from Unity
    float4 _Time; // (t/20, t, t*2, t*3)
    float4 _LastTime; // Last frame time (t/20, t, t*2, t*3)
    float4 _SinTime; // sin(t/8), sin(t/4), sin(t/2), sin(t)
    float4 _CosTime; // cos(t/8), cos(t/4), cos(t/2), cos(t)
    float4 unity_DeltaTime; // dt, 1/dt, smoothdt, 1/smoothdt
    float4 _TimeParameters;

#if !defined(USING_STEREO_MATRICES)
    float3 _WorldSpaceCameraPos;
#endif

    // x = 1 or -1 (-1 if projection is flipped)
    // y = near plane
    // z = far plane
    // w = 1/far plane
    float4 _ProjectionParams;

    // x = width
    // y = height
    // z = 1 + 1.0/width
    // w = 1 + 1.0/height
    float4 _ScreenParams;

    // Values used to linearize the Z buffer (http://www.humus.name/temp/Linearize%20depth.txt)
    // x = 1-far/near
    // y = far/near
    // z = x/far
    // w = y/far
    // or in case of a reversed depth buffer (UNITY_REVERSED_Z is 1)
    // x = -1+far/near
    // y = 1
    // z = x/far
    // w = 1/far
    float4 _ZBufferParams;

    // x = orthographic camera's width
    // y = orthographic camera's height
    // z = unused
    // w = 1.0 if camera is ortho, 0.0 if perspective
    float4 unity_OrthoParams;
CBUFFER_END
```

可以看到, 定义了`_Time`这个变量.

而非ShaderGraph的hlsl编写, 在`Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl`文件中, 有引用`Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl`, 在该被引用的文件`UnityInput.hlsl`中, 有如下代码

```c
// Time (t = time since current level load) values from Unity
float4 _Time; // (t/20, t, t*2, t*3)
float4 _SinTime; // sin(t/8), sin(t/4), sin(t/2), sin(t)
float4 _CosTime; // cos(t/8), cos(t/4), cos(t/2), cos(t)
float4 unity_DeltaTime; // dt, 1/dt, smoothdt, 1/smoothdt
float4 _TimeParameters; // t, sin(t), cos(t)
```

可以看到也声明了这个_Time.

这就是造成报错的原因.

## 01 解决方案

### 找出include了Input.hlsl的引用

比如:

- 当你使用了了`#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"`

- 进入`GlobalIllumination.hlsl`, 会发现

  ```c
  #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
  #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
  #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
  ```

- 再进入`RealtimeLights.hlsl`, 会发现

  ```
  #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"
  #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
  #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
  #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LightCookie/LightCookie.hlsl"
  #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Clustering.hlsl"
  ```

- 这个`Input.hlsl`就是造成冲突的原因了.

### 确定你要使用的代码在具体的hlsl中, 引用具体的hlsl

比如我要使用的代码其实不在`GlobalIllumination.hlsl`中, 而是在`Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl`中. 

则, 注释掉`GlobalIllumination.hlsl`的引用, 先引用除了`_Time`之外的其他文件

```c
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
```

### 将Input.hlsl做为`#ifndef SHADERGRAPH_PREVIEW`条件引用

```
#ifndef SHADERGRAPH_PREVIEW
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#endif
```

### 最后代码修改结果:

```c
// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
#ifndef SHADERGRAPH_PREVIEW
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#endif
```

就可以避免重定义字段的问题了.

###### 参考网页
