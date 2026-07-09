---
layout: post
title: "You can only call cameraDepthTarget inside the scope of a ScriptableRenderPass"
categories: [URP, 后处理]
tags: URP 后处理 RendererFeature ScriptableRenderPass cameraDepthTarget RenderTarget AddRenderPasses
math: true


---

# You can only call cameraDepthTarget inside the scope of a ScriptableRenderPass

## 00 问题现象

在自定义 `ScriptableRendererFeature` 中, 通过 `renderer.cameraDepthTarget` 将当前相机深度传给自定义 Pass 时, Unity Console 报错:

```c#
You can only call cameraDepthTarget inside the scope of a ScriptableRenderPass.
Otherwise the pipeline camera target texture might have not been created or might have already been disposed.

UnityEngine.Rendering.Universal.ScriptableRenderer:get_cameraDepthTarget ()
Vehicle.Runtime.Rendering.DitherSMAAMaskRendererFeature:AddRenderPasses(...)
```

对应问题代码位于 `ScriptableRendererFeature.AddRenderPasses`:

```c#
_maskPass.Setup(renderer.cameraDepthTarget);

renderer.EnqueuePass(_maskPass);
renderer.EnqueuePass(_cleanupPass);
```

## 01 根因

`cameraDepthTarget` 是 URP 当前相机渲染过程中的临时 RenderTarget。

它的生命周期由 URP 管线控制, 不能在 `ScriptableRendererFeature.AddRenderPasses` 阶段直接访问。

原因是:

```c#
AddRenderPasses 阶段:
只适合创建 Pass, 设置 Pass 参数, EnqueuePass。
此时 camera target 可能还没有被创建, 或者在某些时机已经被释放。

ScriptableRenderPass 阶段:
处于具体相机渲染流程中。
此时访问 cameraDepthTarget 才是安全的。
```

所以错误点不是 Dither SMAA 逻辑, 而是 RenderTarget 获取位置不对。

## 02 错误写法

错误写法是从 `RendererFeature` 中提前取出 `cameraDepthTarget`, 再传给 Pass。

```c#
public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
{
    _maskPass.Setup(renderer.cameraDepthTarget);

    renderer.EnqueuePass(_maskPass);
}
```

这种写法在旧版本 URP 中有时可以工作, 但在较新的 URP 中会触发生命周期检查。

## 03 修改方案

核心原则:

```c#
不要在 ScriptableRendererFeature 中访问 cameraDepthTarget。
改为在 ScriptableRenderPass.Execute 内部访问 cameraDepthTarget。
```

### 03.01 RendererFeature 修改

原代码:

```c#
_maskPass.Setup(renderer.cameraDepthTarget);
```

改为:

```c#
_maskPass.Setup();
```

完整示例:

```c#
public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
{
    if (settings == null)
    {
        return;
    }

    if (RenderFeatureCameraFilter.ShouldSkip(ref renderingData))
    {
        return;
    }

    // Unity 重新加载或 RendererFeature 状态异常时, 保底重建 Pass。<br/>
    if (_maskPass == null || _cleanupPass == null)
    {
        Create();
    }

    // 注意: renderPassEvent 可能在 Inspector 中被修改, 这里每帧同步一次, 避免 Create 后旧值残留。<br/>
    _maskPass.renderPassEvent = settings.renderPassEvent;

    // 注意: 清理 Pass 必须晚于 SMAA / PostProcessing。<br/>
    // 当前统一放在 AfterRendering, 确保本帧后处理已经完成。<br/>
    _cleanupPass.renderPassEvent = RenderPassEvent.AfterRendering;

    // 注意: 不要在 AddRenderPasses 中访问 renderer.cameraDepthTarget。<br/>
    // cameraDepthTarget 必须在 ScriptableRenderPass 内部访问。<br/>
    _maskPass.Setup();

    renderer.EnqueuePass(_maskPass);
    renderer.EnqueuePass(_cleanupPass);
}
```

### 03.02 ScriptableRenderPass 修改

原本 Pass 中通过字段保存外部传入的 depth target:

```c#
private RenderTargetIdentifier _depthTarget;

public void Setup(RenderTargetIdentifier depthTarget)
{
    _depthTarget = depthTarget;
    _shaderTagId = new ShaderTagId(_settings.shaderTag);
}
```

修改后删除 `_depthTarget`, 改为在 `Execute` 中读取:

```c#
RenderTargetIdentifier depthTarget =
    renderingData.cameraData.renderer.cameraDepthTarget;
```

修改后的关键代码:

```c#
public void Setup()
{
    // 注意: shaderTag 可能在 Inspector 中被修改, 这里每帧同步一次。<br/>
    _shaderTagId = new ShaderTagId(_settings.shaderTag);
}

public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
{
    CommandBuffer cmd = CommandBufferPool.Get(ProfilerTag);

    try
    {
        using (new ProfilingScope(cmd, ProfilingSampler))
        {
            RenderTextureDescriptor descriptor =
                RenderTextureDescriptorBuilder.FromCamera(renderingData.cameraData.cameraTargetDescriptor)
                    .WithNoDepth()
                    .WithNoMSAA()
                    .WithColorFormat(RenderTextureFormat.R8)
                    .Build();

            RenderTargetIdentifier maskTarget =
                new RenderTargetIdentifier(DitherSMAAMaskShaderIds.DitherSMAAMaskTexture);

            cmd.GetTemporaryRT(
                DitherSMAAMaskShaderIds.DitherSMAAMaskTexture,
                descriptor,
                FilterMode.Point
            );

            // 注意: cameraDepthTarget 必须在 ScriptableRenderPass 作用域内访问。<br/>
            // 不要在 RendererFeature.AddRenderPasses 中提前读取。<br/>
            RenderTargetIdentifier depthTarget =
                renderingData.cameraData.renderer.cameraDepthTarget;

            // 注意: 绑定 camera depth 作为 depth attachment, 使 mask 绘制遵守当前场景深度。<br/>
            // Mask RT 自身不需要 depth buffer。<br/>
            cmd.SetRenderTarget(maskTarget, depthTarget);
            cmd.ClearRenderTarget(false, true, Color.clear);

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            SortingCriteria sortingCriteria = renderingData.cameraData.defaultOpaqueSortFlags;

            DrawingSettings drawingSettings =
                CreateDrawingSettings(_shaderTagId, ref renderingData, sortingCriteria);

            FilteringSettings filteringSettings =
                new FilteringSettings(RenderQueueRange.opaque, _settings.layerMask);

            context.DrawRenderers(
                renderingData.cullResults,
                ref drawingSettings,
                ref filteringSettings
            );

            cmd.SetGlobalTexture(
                DitherSMAAMaskShaderIds.DitherSMAAMaskTexture,
                maskTarget
            );

            cmd.SetGlobalFloat(
                DitherSMAAMaskShaderIds.DitherSMAASuppression,
                Mathf.Clamp01(_settings.smaaSuppression)
            );
        }

        context.ExecuteCommandBuffer(cmd);
    }
    finally
    {
        CommandBufferPool.Release(cmd);
    }
}
```

## 04 修改后的职责边界

修改后职责更清晰:

```c#
DitherSMAAMaskRendererFeature:
- 创建 Pass。
- 同步 renderPassEvent。
- 同步 Inspector 中可变配置。
- EnqueuePass。
- 不访问 cameraDepthTarget / cameraColorTarget。

DitherSMAAMaskPass:
- 创建临时 Mask RT。
- 在 Execute 内部获取 cameraDepthTarget。
- SetRenderTarget。
- Clear。
- DrawRenderers。
- SetGlobalTexture。
```

这是更符合 URP 生命周期的写法。

## 05 后续注意事项

如果修复报错后, mask 深度遮挡结果仍然不对, 需要继续检查 `renderPassEvent`。

如果 mask 需要依赖已经写好的 opaque depth, 通常应放在:

```c#
RenderPassEvent.AfterRenderingOpaques
```

或确保 Pass 执行时, camera depth 已经包含需要参与遮挡的场景深度。

否则不会再触发当前报错, 但生成的 mask 可能没有正确遵守场景深度。

## 06 总结

本问题的最小修复是:

```c#
- _maskPass.Setup(renderer.cameraDepthTarget);
+ _maskPass.Setup();
```

然后在 `DitherSMAAMaskPass.Execute` 内部读取:

```c#
RenderTargetIdentifier depthTarget =
    renderingData.cameraData.renderer.cameraDepthTarget;
```

核心结论:

```c#
RendererFeature 只负责编排。
RenderTarget 的读取和绑定应放在 ScriptableRenderPass 内部。
```

###### 参考网页

- Unity ScriptableRenderer API 文档: https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@15.0/api/UnityEngine.Rendering.Universal.ScriptableRenderer.html
- Unity Discussions, Custom renderer features broken on URP 10: https://discussions.unity.com/t/custom-renderer-features-broken-on-10-0-0-preview-26/810927
