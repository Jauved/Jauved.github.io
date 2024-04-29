---
layout: post
title: "基于RendererFeature的后处理(一)"
categories: [URP, 后处理]
tags: URP 后处理 RendererFeature
math: true


---

# 基于`RendererFeature`的后处理(一)

## 00 前言

按照傻瓜教程的方式记录URP中基于RendererFeature的后处理的制作方式. 期望整理完之后能得到一个较为规范的后处理制作方式.

## 01 获得材质球

无论是如何制作的后处理, 本质上还是要基于一个材质球对指定的图像进行处理, 分为以下两种情况:

- 当你需要一个`RendererFeature`中用到多个材质球的时候(比如, 你要制作自己的后处理`rendererFeature`), 可以参照Unity后处理材质管理方式
- 只是一个单独的效果, 仅需要用到一个材质球时(<font color=orange>建议优先度由高到低, 实现速度由低到高, 实现功能时选择速度高的, 重构时选择优先度高的</font>)
  - 参照Unity自身的Package内`RendererFeature`材质管理方式
  - 直接创建材质球并拖动到脚本中
  - 通过`Shader.Find()`方法动态创建

### 01.0 Unity后处理材质管理方式

- 声明一个`MaterialLibrary`类, 用来保存所有要用到的材质球
  - 实现一个`private Material Load(Shader shader)`方法来创建材质球
  - 实现一个`internal void Cleanup()`方法来销毁材质球
  - 创建
    - `MaterialLibrary`的构造函数中基于`PostProcessData.shader`来创建每一个用到的材质球
    - 在`PostProcessPass`的构造函数中来创建`MaterialLibrary`, 即完成了材质的创建
  - 销毁
    - 在`PostProcessPass`的`Cleanup()`方法中调用`MaterialLibrary.Cleanup()`来进行销毁
    - 而`PostProcessPass`的`Cleanup()`方法会在`internal struct PostProcessPasses : IDisposable`中的`public void Dispose()`方法中被调用
    - `UniversalRender`类的`protected override void Dispose(bool disposing)`中会调用`internal struct PostProcessPasses`的`Dispose()`方法
    - 而最终在UniversalRender的基类`public abstract partial class ScriptableRenderer : IDisposable`的`public void Dispose()`方法中被调用

Unity自身的后处理是先通过一个`ShaderResources`类来储存所用到的所有`Shader`的引用. 其中关键的代码如下:

```c++
/// <summary>
/// Class containing shader resources used for Post Processing in URP.
/// </summary>
[Serializable, ReloadGroup]
public sealed class ShaderResources
{
    /// <summary>
    /// The StopNan Post Processing shader.
    /// </summary>
    [Reload("Shaders/PostProcessing/StopNaN.shader")]
    public Shader stopNanPS;

    /// <summary>
    /// The <c>SubpixelMorphologicalAntiAliasing</c> SMAA Post Processing shader.
    /// </summary>
    [Reload("Shaders/PostProcessing/SubpixelMorphologicalAntialiasing.shader")]
    public Shader subpixelMorphologicalAntialiasingPS;
    ......
    /// <summary>
    /// The Final Post Processing shader.
    /// </summary>
    [Reload("Shaders/PostProcessing/FinalPost.shader")]
    public Shader finalPostPassPS;
}
```

这里`public ReloadAttribute(string path, Package package = Package.Root)`这个属性方法, 是Unity内部实现的基于`package`目录的读取资源的方法, 在我看来, 就是通过代码的形式, 把手动拖放`shader`到脚本上的形式改成了按照路径指定. 要注意的是, 如果修改了`shader`的路径, 则需要重新修改这个类中的路径.

有了着色器, 那么如何得到材质球, Unity的后处理用的是一个`Load`方法, 如下

```c++
Material Load(Shader shader)
{
    if (shader == null)
    {
        Debug.LogErrorFormat($"Missing shader. {GetType().DeclaringType.Name} render pass will not execute. Check for missing reference in the renderer resources.");
        return null;
    }
    else if (!shader.isSupported)
    {
        return null;
    }

    return CoreUtils.CreateEngineMaterial(shader);
}
```

Unity是在后处理`pass`的构造函数中对其进行初始化, 并在其`public void Dispose()`方法中进行销毁.

### 01.1  Unity自身的`RendererFeature`材质管理方式

该方案适合基于Package内的`rendererFeature`

- 在`RendererPass`中声明`material`和创建一个`Setup(ref MieSetting featureSetting, ref ScriptableRenderer renderer, ref Material material)`的bool方法备用
- 在`RendererFeature`中声明`shader`和`material`
  - `shader`使用`public ReloadAttribute(string path, Package package = Package.Root)`属性方法获取
  - 记得在`RendererFeature`的`Creat()`方法中, 使用`TryReloadAllNullIn(object container, string basePath)`, 这样才可以真正的对`shader`赋值
    - 其中`basePath`是你所制作的`package`的根目录
  - 创建一个`GetMaterials()`的bool方法备用, 在`RendererFeature`的`AddRenderPasses`方法中调用以真正的创建材质球
  - 在`RendererFeature`的`AddRenderPasses`方法中调用`rendererPass`的`Setup(ref MieSetting featureSetting, ref ScriptableRenderer renderer, ref Material material)`方法, 将设置,`renderer`以及材质传递过去.
  - 材质通过在`RendererFeature`中的`Dispose(bool disposing)`方法加入`CoreUtils.Destroy(_material);`进行销毁

```C++
public class MieFeature : ScriptableRendererFeature
{
    //Setting类用来保存和传递除了材质球和临时纹理之外的所有参数, 包括renderPassEvent
    [SerializeField]
    private MieSetting _mieSetting = new MieSetting();
    
    [SerializeField]
    //[HideInInspector]//这个标签在Debug阶段注释掉, 以确定是否找到shader
    [Reload("Shaders/PostProcess/MieScattering.shader")]
    private Shader _shader;

    private Material _material;

    public override void Create()
    {
    #if UNITY_EDITOR
        ResourceReloader.TryReloadAllNullIn(this, "Packages/com.render.environment");
    #endif
        _miePass ??= new MiePass(_mieSetting);
    }

    private bool GetMaterials()
    {
        //避免重复创建
        if (_material == null && _shader != null && _shader.isSupported)
            _material = CoreUtils.CreateEngineMaterial(_shader);
        return _material != null;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (!GetMaterials())
        {
    #if UNITY_EDITOR
            Debug.LogErrorFormat("{0}.AddRenderPasses(): Missing material. {1} render pass will not be added.", GetType().Name, name);
    #endif
            return;
        }
        bool shouldAdd = _miePass.Setup(ref _mieSetting, ref renderer, ref _material);
        if (shouldAdd)
        {
            renderer.EnqueuePass(_miePass);
        }
    }
    
    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        _miePass?.Dispose();
        _miePass = null;
        CoreUtils.Destroy(_material);
    }
}

public class MiePass : ScriptableRenderPass
{
    private Material _material;
    
    public bool Setup(ref MieSetting featureSetting, ref ScriptableRenderer renderer, ref Material material)
    {
        this._setting = featureSetting;
        this.renderPassEvent = featureSetting.renderPassEvent;
        this._material = material;
        return _material != null;
    }
}
```

### 01.2 直接创建材质球并拖动到脚本中

这个最为方便, 直接在`rendererFeature`中声明一个可序列化的材质球, 新创建材质球, 之后选择脚本, 将材质球拖动到脚本上成为默认值即可, Unity提供的全屏`rendererFeature`示例即采用的此方法, 也是Unity通常建议用户采用的方法. 由于没有临时材质球, 所以该方法不需要对材质球进行销毁.

![image-20240407103801252](/assets/image/image-20240407103801252.png)

### 01.3 通过`Shader.Find()`方法动态创建

即在`Creat`方法中创建临时的材质球, 并通过`Shader.Find`指定着色器. 由于是临时材质球, 所以在`rendererFeature`的`Dispose()`方法中要对材质进行销毁.

```C++
_material = new Material(Shader.Find("Render/URP/Environment/MieScattering"));
```



## 02 Unity的SSAO分析

通过全局名称设置, 将渲染结果输出.

```c++
cmd.SetGlobalTexture(k_SSAOTextureName, m_SSAOTextures[k_FinalTexID]);
```

## 03 后处理导致反射探针烘焙变黑色

```C++
//后处理着色器中需要包含以下设置
ZTest Always ZWrite Off Cull Off
```







###### 参考网页
