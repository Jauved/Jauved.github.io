---
layout: post
title: "URP中基于ShaderFeature和ComputeShader的OverDraw工具"
categories: [URP, 工具]
tags: URP 工具 OverDraw 优化 Inspector只读字段 computeshader
math: true
---

# URP中基于ShaderFeature和ComputeShader的OverDraw工具

## 00 前言



## 01 处理方法

目前采用的方式是使用`context.DrawRenderers`方法中的`drawSettings.overrideMaterial = _material;`, 进行替代渲染. 核心方法见下方代码:

```csharp
private void DrawRenderers(ScriptableRenderContext context, ref RenderingData renderingData)
{
    var sortFlags = _isOpaque ? renderingData.cameraData.defaultOpaqueSortFlags : SortingCriteria.CommonTransparent;
    var drawSettings = CreateDrawingSettings(_tagIdList, ref renderingData, sortFlags);
    drawSettings.overrideMaterial = _material;
    context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref _filteringSettings);
}
```

\*事实上, 如果是自己的工程的话, 仿照URP的多Pass进行渲染会更可控和准确, 后续会尝试采用这个方案.

## 02 QA

### x00 Q: URP中如何用脚本改变摄像机的Renderer

A: 使用`camera`的`GetUniversalAdditionalCameraData()`方法得到`UniversalAdditionalCameraData`对象, 然后调用其`SetRenderer(int index)`方法即可, 但`unity2019`没有根据名称获取`index`的方法, 只能每次去设置. [参考网页](https://forum.unity.com/threads/urp-how-to-change-camera-renderer-at-runtime.956982/), 另[动态切换Universal Render Pipeline Asset的方法](https://blog.csdn.net/smile_otl/article/details/130358034)
```csharp
public static void SyncAddProperties(this Camera camera, Camera otherCamera, OverdrawCameraConfig config)
{
    camera.GetUniversalAdditionalCameraData().SetRenderer(config.rendererIndex);
    camera.GetUniversalAdditionalCameraData().renderPostProcessing = config.renderPostProcessing;
    camera.GetUniversalAdditionalCameraData().renderType = config.cameraRenderType;
    camera.GetUniversalAdditionalCameraData().renderShadows = false;
}
```

### x01 Q: RenderTexture的释放该调用什么API

A: 一般来说, 如果不是需要长期存储的RenderTexture(以下简称"RT"), 尽量使用`RenderTexture.GetTemporary(RenderTextureDescriptor descriptor)`类似的方法来获取, 相对应的, 释放时不能直接使用`RenderTexture.Release()`, 而是要使用`RenderTexture.ReleaseTemporary(RenderTexture rt)`来进行资源释放. [参考网页](https://blog.csdn.net/yu__jiaoshou/article/details/90168844).

### x02 Q: `CommandBuffer.GetTemporaryRT`与`RenderTexture.GetTemporary`有什么异同

A: [参考网页](https://zhuanlan.zhihu.com/p/460779772), 即如果需要在多个CommandBuffer之间传递RT, 那么请使用`RenderTexture.GetTemporary`, 比如bloom后处理, 一般的后处理使用`CommandBuffer.GetTemporaryRT`即可.

> CommandBuffer.GetTemporaryRT获取的RT会在Graphics.ExecuteCommandBuffer或者CameraEvent渲染完成后被回收，这就可能导致在不同CameraEvent获取RT时，取得之前创建的RT，覆盖原有的效果。如果是持续化显示，通过RenderTexture.GetTemporary接口可以避免这类问题。

### x03 Q: 在EditorWindow类中如何显示List与数组?

A: 必须的代码见下, [参考网页0](https://blog.csdn.net/dzj2021/article/details/121250814), [参考网页1](https://www.jianshu.com/p/ef8bd9d9c6ea), [U3D编辑器扩展_虚拟喵的博客-CSDN博客](https://blog.csdn.net/qq_35361471/category_8476835.html)
```csharp
public class OverdrawWindow : EditorWindow
{
    //...
    [SerializeField] private List<Camera> _cams;
    private SerializedObject _serializedObject;
    private SerializedProperty _camsProperty;
    //...
     [MenuItem("Tools/Overdraw Window")]
    //...
    static void ShowWindow()
    {
        GetWindow<OverdrawWindow>().Show();
    }
    //...
    //声明一个List所在类的SerializedObject, 因为这里直接把List存在了OverdrawWindow类中, 所以是this.
    //然后使用_serializedObject.FindProperty(name)的方式得到SerializedProperty
    private void OnEnable()
    {
        
        _serializedObject = new SerializedObject(this);
        _camsProperty = _serializedObject.FindProperty("_cams");
    }
    //...
    private void OnGUI()
    {
        //...
        DisplayCurCameras();
        //...
        Repaint();
    }
    //...
    private void DisplayCurCameras()
    {
        //通过EditorGUILayout.PropertyField(SerializedProperty prop)的Api来在EditorWindow面板上显示List
        EditorGUILayout.PropertyField(_camsProperty);
    }
}
```

### x04 Q: 当打开MSAA后, 在`framdebugger`中会出现大量的MSAA的渲染过程, 如何解决?

A: 参考以下网页, 后续对管线进行优化

[【精选】大型项目中 MSAA 的方案参考_a multisampled texture being bound to a non-multis-CSDN博客](https://blog.csdn.net/Jaihk662/article/details/126752896)

### x05 Q: 报错日志：Non matching Profiler.EndSample (BeginSample and EndSample count must match)

A: [unity的Profiler报错 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/273644659), 实际上并没有真正解决在"实际"工程中遇到的报错, 临时把这段注释掉了, 代码如下:
```csharp
CommandBuffer cmd = CommandBufferPool.Get(_profilerTag);
//注释掉了以下这句代码
//using (new ProfilingScope(cmd, _profilingSampler))
{
    var desc = renderingData.cameraData.cameraTargetDescriptor;
    desc.enableRandomWrite = true;
    desc.graphicsFormat = GraphicsFormat.R32_SFloat;
    //刷新数据
    // OverdrawData.Descriptor = desc;
    // OverdrawData.rendTextureDic[renderingData.cameraData.camera] = OverdrawData.OverdrawTexture;
    OverdrawData.RefreshDataRendTexture(camera,desc);
    cmd.Blit(_source, OverdrawData.rendTextureDic[camera]);
    context.ExecuteCommandBuffer(cmd);
    CommandBufferPool.Release(cmd);
}
```

## 04 小石头

### x00 [异步截图工具](https://github.com/keijiro/AsyncCaptureTest)

### x01 [How to resolve this error with Unity's AsyncGPUReadback?](https://stackoverflow.com/questions/66010731/how-to-resolve-this-error-with-unitys-asyncgpureadback)

### x02 [Fast Pixel Reading (Part 2): AsyncGPUReadback ](https://dev.to/alpenglow/unity-fast-pixel-reading-part-2-asyncgpureadback-4kgn)

### x03 [喷涂、绘制与填充 - KuanMi](https://www.kuanmi.top/2022/12/26/draw/)

### x04 [How to use compute shaders to compute enclosed regions within a texture](https://forum.unity.com/threads/how-to-use-compute-shaders-to-compute-enclosed-regions-within-a-texture.1379337/)

### x05 [How to use compute shaders to compute enclosed regions within a texture](https://forum.unity.com/threads/how-to-use-compute-shaders-to-compute-enclosed-regions-within-a-texture.1379337/)

### x06 运行时控制RendererFeature

- [Unity URP 运行时控制ScriptableRendererFeature](https://blog.csdn.net/lvcoc/article/details/111593695)
- [通过代码动态添加URP渲染通道RendererFeature](https://blog.csdn.net/boyZhenGui/article/details/125974779)

### x07 [tkonexhh/LookingShader (github.com)](https://github.com/tkonexhh/LookingShader/tree/master)

x08 [Overdraw概念、指标和分析工具 - (built-in方案)](https://zhuanlan.zhihu.com/p/323421079)

###### 参考网页

[Overdraw概念、指标和分析工具 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/323421079)

[[URP\]RenderFeature+ComputeShader计算OverDraw - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/577015774)

[ina-amagami/OverdrawForURP: Scene Overdraw in Universal Render Pipeline. (github.com)](https://github.com/ina-amagami/OverdrawForURP)

[srp-compute-render-feature/Assets/Scripts/ExampleRendererFeature.cs at main · dj24/srp-compute-render-feature (github.com)](https://github.com/dj24/srp-compute-render-feature/blob/main/Assets/Scripts/ExampleRendererFeature.cs)

[Rendering.FilteringSettings - Unity 脚本 API](https://docs.unity.cn/cn/2020.2/ScriptReference/Rendering.FilteringSettings.html)

[Rendering.DrawingSettings - Unity 脚本 API](https://docs.unity.cn/cn/2020.3/ScriptReference/Rendering.DrawingSettings.html)

[Unity3D:URP下输出深度图以及自定义ScriptableRenderer - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/351390737)

[phi-lira/CustomScriptableRenderer (github.com)](https://github.com/phi-lira/CustomScriptableRenderer/tree/master)

[在运行时替换着色器 - Unity 手册](https://docs.unity.cn/cn/2023.1/Manual/SL-ShaderReplacement.html)

[How to make a readonly property in inspector? - Questions & Answers - Unity Discussions](https://discussions.unity.com/t/how-to-make-a-readonly-property-in-inspector/75448/5)

[初识Compute Shader - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/438515815)

[【Unity】Compute Shader的基础介绍与使用 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/368307575)

[Unity Compute Shader入门初探 - 简书 (jianshu.com)](https://www.jianshu.com/p/ec9ba6c3a155)

[Compute Shader中的Parallel Reduction和Parallel Scan - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/113532940)

[How can we access thread group and global variables from threads in compute shader? - Unity Forum](https://forum.unity.com/threads/how-can-we-access-thread-group-and-global-variables-from-threads-in-compute-shader.468306/)

[Nordeus/Unite2017 (github.com)](https://github.com/Nordeus/Unite2017/tree/master)

[ken48/UnityOverdrawMonitor: Overdraw profiler for Unity, shows fill rate (github.com)](https://github.com/ken48/UnityOverdrawMonitor)

[srp-compute-render-feature/Assets/Scripts/ExampleRendererFeature.cs at main · dj24/srp-compute-render-feature (github.com)](https://github.com/dj24/srp-compute-render-feature/blob/main/Assets/Scripts/ExampleRendererFeature.cs)

[URP延迟渲染+Native Renderpass踩坑记录 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/574540329)

[从零实现Unity通用渲染管线(URP)二:DrawObjectPass - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/365734868)

[How to get a data from compute shader in custom pass. - Unity Forum](https://forum.unity.com/threads/how-to-get-a-data-from-compute-shader-in-custom-pass.1305633/)

[Unity - Scripting API: AsyncGPUReadbackRequest (unity3d.com)](https://docs.unity3d.com/ScriptReference/Rendering.AsyncGPUReadbackRequest.html)

[[URP\]RenderFeature+ComputeShader计算OverDraw - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/577015774)
