---
layout: post
title: "将URP默认的Keyword作为可选项"
categories: [URP, 后处理]
tags: URP 后处理 DepthOfField
math: true


---

# 将URP默认的Keyword作为可选项

## 00 前置知识

关于keyword的调用链

图示:

<img src="/assets/image/shapes at 25-09-03 13.12.54.svg" alt="shapes at 25-09-03 13.12.54" style="zoom:50%;" />

`Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/Targets/UniversalLitSubTarget.cs`的`Setup()`函数

```c#
public override void Setup(ref TargetSetupContext context)
{
    ...
    context.AddSubShader(PostProcessSubShader(SubShaders.LitGLESSubShader(target, workflowMode, target.renderType, target.renderQueue, complexLit)));
}
```

同文件中的`SubShader`部分的`result.passes.Add`代码, 这里是Pass相关, 而`keyword`是在这一步加入的

```c#
#region SubShader
static class SubShaders
{
	...
    public static SubShaderDescriptor LitGLESSubShader(UniversalTarget target, WorkflowMode workflowMode, string renderType, string renderQueue, bool complexLit)
    {
        ...
        if (complexLit)
            // 这里是加入Pass, keyword是在这里进行加入的
            result.passes.Add(LitPasses.ForwardOnly(target, workflowMode, complexLit, CoreBlockMasks.Vertex, LitBlockMasks.FragmentComplexLit, CorePragmas.Forward));
        else
            // 这里是加入Pass, keyword是在这里进行加入的
            result.passes.Add(LitPasses.Forward(target, workflowMode));

       ...
        return result;
    }
}
#endregion
```

继续同文件深挖, 到`Pass`部分

```c#
#region Passes
static class LitPasses
{
	...
    public static PassDescriptor Forward(UniversalTarget target, WorkflowMode workflowMode, PragmaCollection pragmas = null)
    {
        var result = new PassDescriptor()
        {
            ...
            // Conditional State
            renderStates = CoreRenderStates.UberSwitchedRenderState(target),
            pragmas = pragmas ?? CorePragmas.Forward,     // NOTE: SM 2.0 only GL
            defines = new DefineCollection() { CoreDefines.UseFragmentFog },
            // 这里就是keyword相关的注入点
            keywords = new KeywordCollection() { LitKeywords.Forward },
            includes = LitIncludes.Forward,

            // Custom Interpolator Support
            customInterpolators = CoreCustomInterpDescriptors.Common
        };

        CorePasses.AddTargetSurfaceControlsToPass(ref result, target);
        AddWorkflowModeControlToPass(ref result, target, workflowMode);
        AddReceiveShadowsControlToPass(ref result, target, target.receiveShadows);

        return result;
    }

    public static PassDescriptor ForwardOnly(
        UniversalTarget target,
        WorkflowMode workflowMode,
        bool complexLit,
        BlockFieldDescriptor[] vertexBlocks,
        BlockFieldDescriptor[] pixelBlocks,
        PragmaCollection pragmas)
    {
        var result = new PassDescriptor
        {
            ...

            // Conditional State
            renderStates = CoreRenderStates.UberSwitchedRenderState(target),
            pragmas = pragmas,
            defines = new DefineCollection() { CoreDefines.UseFragmentFog },
            // 这里就是keyword相关的注入点
            keywords = new KeywordCollection() { LitKeywords.Forward },
            includes = LitIncludes.Forward,

            // Custom Interpolator Support
            customInterpolators = CoreCustomInterpDescriptors.Common
        };

        if (complexLit)
            result.defines.Add(LitDefines.ClearCoat, 1);

        CorePasses.AddTargetSurfaceControlsToPass(ref result, target);
        AddWorkflowModeControlToPass(ref result, target, workflowMode);
        AddReceiveShadowsControlToPass(ref result, target, target.receiveShadows);

        return result;
    }
	...
}
#endregion
```

继续跳转到`keyword`部分, 然后我们终于找到`keyword`定义的部分

```c#
#region Keywords
static class LitKeywords
{
    ...
    public static readonly KeywordCollection Forward = new KeywordCollection
    {
        { ScreenSpaceAmbientOcclusion },
        { CoreKeywordDescriptors.StaticLightmap },
        { CoreKeywordDescriptors.DynamicLightmap },
        { CoreKeywordDescriptors.DirectionalLightmapCombined },
        { CoreKeywordDescriptors.MainLightShadows },
        { CoreKeywordDescriptors.AdditionalLights },
        { CoreKeywordDescriptors.AdditionalLightShadows },
        { CoreKeywordDescriptors.ReflectionProbeBlending },
        { CoreKeywordDescriptors.ReflectionProbeBoxProjection },
        { CoreKeywordDescriptors.ShadowsSoft },
        { CoreKeywordDescriptors.LightmapShadowMixing },
        { CoreKeywordDescriptors.ShadowsShadowmask },
        { CoreKeywordDescriptors.DBuffer },
        { CoreKeywordDescriptors.LightLayers },
        { CoreKeywordDescriptors.DebugDisplay },
        { CoreKeywordDescriptors.LightCookies },
        { CoreKeywordDescriptors.ClusteredRendering },
    };
    ...
}
#endregion
```



## 01 实施

首先, 我们之前已经将各个部分分割成了多个文件, 以确保逻辑清晰.

<img src="/assets/image/shapes at 25-09-03 13.30.13.svg" alt="shapes at 25-09-03 13.30.13" style="zoom:50%;" />

其中

`ExternalPasses`: 即(原`UniversalSubTarget`文件, 下同)`#region Passes`部分, `RequiredFields`部分, `PortMasks`部分(暂时未做继续拆分)

`Includes`: 即`#region Includes`部分

`Keywords`: 即`#region Keywords`部分和`#region Defines`部分(暂时未做继续拆分)

`SubShader`: 即`#region Subshader`部分

`UniversalVehicleSubTargetExternal`: 额外的其他部分

`UniversalVehicleSubTargetExternalUI`: 额外的与面板相关的部分, 即大部分的自定义部分放在这个文件中

`UniversalVehicleSubTarget`: 分割后剩下的部分

### 01.0 思路-数据结构

首先, 我需要一组数据结构, 一方面用于面板绘制, 另一方面用于Keyword启用逻辑

<img src="/assets/image/shapes at 25-09-03 13.45.42.png" alt="shapes at 25-09-03 13.45.42" style="zoom:50%;" />

作为面板绘制的时候, 直接在`UniversalVehicleSubTargetExternalUI`调用即可;

作为Keyword启用逻辑时, 则需要层层传递到`Keywords`中, 才可以生效.

现在我们来制作这个数据结构:

### 01.0 实现-数据结构

先看看Unity绘制UI的数据结构

```c#
[SerializeField] bool m_ClearCoat = false;// 序列化用数据
public bool clearCoat					// 对应属性
{
    get => m_ClearCoat;
    set => m_ClearCoat = value;
}
```

以及实际绘制时的调用方式

```c#
context.AddProperty("Clear Coat", new Toggle() { value = clearCoat }, (evt) =>
        {
            if (Equals(clearCoat, evt.newValue)) // 用Equals, 效率略低, 需装箱, 但可以支持null
                return;

            registerUndo("Change Clear Coat");
            clearCoat = evt.newValue;
            onChange();
        });
```

这里仍旧保持Unity原本的`序列化数据`和`属性`不变, 在属性和UI之间, 新增一个数据结构做桥接. 

- 通过`Func<bool> Get`, `Action<bool> Set`对接属性, 同时对接UI
- 通过`string Label`对接UI
- 通过`KeywordDescriptor? Descriptor`对接keyword逻辑
- 数据结构放在一个新的文件`SubTargetExternalUIUtils.cs`

暂时命名为`ToggleDefinition`

`ToggleDefinition`类代码为: 

```c#
/// <summary>
/// 单个 toggle 的定义：面板显示名, 对应的属性, undo 文案
/// </summary>
internal class ToggleDefinition
{
    public readonly string CustomLabel;        // UI 显示
    public readonly KeywordDescriptor? Descriptor;
    public Func<bool> Get;      // 读取当前值
    public Action<bool> Set;    // 写入新值

    // 构造函数
    public ToggleDefinition(KeywordDescriptor? descriptor, string customLabel = null)
    {
        Descriptor  = descriptor;
        CustomLabel = customLabel;
    }

    public ToggleDefinition(string customLabel = null)
    {
        CustomLabel = customLabel;

        _customLabelHash = !string.IsNullOrEmpty(customLabel)
            ? customLabel.GetHashCode()
            : 0;
    }

    public string Label
    {
        get
        {
            if (!string.IsNullOrEmpty(CustomLabel))
                return CustomLabel;
            if (Descriptor.HasValue)
                return Descriptor.Value.displayName;
            throw new InvalidOperationException(
                "ToggleDefinition must have either CustomLabel or Descriptor set");
        }
    }
    
    // 根据Label自动组装好的UndoMessage
    public string UndoMessage => $"Change {Label}";
}
```

加入Hash算法相关的代码, 以便于之后使用HashSet自动去重

```c#
internal class ToggleDefinition
{
    ...
    // 将两个构造函数改为支持HashS值生成的
    public ToggleDefinition(KeywordDescriptor? descriptor, string customLabel = null)
    {
        Descriptor  = descriptor;
        CustomLabel = customLabel;

        // 预先计算各部分的哈希
        _refNameHash     = descriptor.HasValue
            ? (descriptor.Value.referenceName?.GetHashCode() ?? 0)
            : 0;
        _displayNameHash    = descriptor.HasValue
            ? (descriptor.Value.displayName?.GetHashCode() ?? 0)
            : 0;
        _customLabelHash = !string.IsNullOrEmpty(customLabel)
            ? customLabel.GetHashCode()
            : 0;
    }

    public ToggleDefinition(string customLabel = null)
    {
        CustomLabel = customLabel;

        _customLabelHash = !string.IsNullOrEmpty(customLabel)
            ? customLabel.GetHashCode()
            : 0;
    }

    ...

    // 预先计算好的子哈希
    private readonly int _refNameHash;
    private readonly int _displayNameHash;
    private readonly int _customLabelHash;

    public bool Equals(ToggleDefinition other)
    {
        if (ReferenceEquals(this, other)) return true;
        if (other is null)               return false;

        if (Descriptor.HasValue && other.Descriptor.HasValue)
        {
            var a = Descriptor.Value;
            var b = other.Descriptor.Value;
            // 优先按 referenceName 区分，不同则直接返回
            if (!string.IsNullOrEmpty(a.referenceName) ||
                !string.IsNullOrEmpty(b.referenceName))
            {
                return a.referenceName == b.referenceName;
            }
            // referenceName 都为空时，退而按 displayName
            return a.displayName == b.displayName;
        }

        // 都没有 descriptor，则按 CustomLabel
        return string.Equals(CustomLabel, other.CustomLabel, StringComparison.Ordinal);
    }

    public override bool Equals(object obj)
        => obj is ToggleDefinition td && Equals(td);

    public override int GetHashCode()
    {
        unchecked
        {
            // 按 _refNameHash -> _dispNameHash -> _customLabelHash 顺序合并
            int hash = _refNameHash;
            hash = hash * 397 ^ _displayNameHash;
            hash = hash * 397 ^ _customLabelHash;
            return hash;
        }
    }

    /// <summary>
    /// 备用哈希算法：使用 HashCode.Combine（.NET Standard 2.1+ / .NET Core）
    /// </summary>
    public int GetHashCodeBackUp()
    {
        return HashCode.Combine(_refNameHash, _displayNameHash, _customLabelHash);
    }

    public static bool operator ==(ToggleDefinition left, ToggleDefinition right)
        => Equals(left, right);

    public static bool operator !=(ToggleDefinition left, ToggleDefinition right)
        => !Equals(left, right);
}
```

在`UniversalVehicleSubTargetExternalUI.cs`声明数据结构, 以及数据初始化(在`Setup()`函数中调用)

```c#
private readonly HashSet<ToggleDefinition> m_keywordToggleDefinitions = new HashSet<ToggleDefinition>();

private void InitKeywordToggleDefinitions()
{
    m_keywordToggleDefinitions.Add(new ToggleDefinition(LitKeywords.ScreenSpaceAmbientOcclusion)
    {
        Get = () => screenSpaceAmbientOcclusion,
        Set = v => screenSpaceAmbientOcclusion = v,
    });
    ...
}

public override void Setup(ref TargetSetupContext context)
{
    context.AddAssetDependency(kSourceCodeGuid, AssetCollection.Flags.SourceDependency);

    #region 辅助数据初始化
    InitKeywordToggleDefinitions();
    #endregion
}
```



### 02.0 思路-统一绘制函数

当数据结构一定的情况下, 需要一个绘制函数进行`foreach`的绘制, 可以避免反复写绘制函数

绘制`ToggleDefinition[]`的伪代码为

```c#
// 折叠打开后，依次绘制 toggle
int toggleIndent = foldIndent + 1;
foreach (var td in section.Toggles)
{
    context.AddProperty(
        label:       td.Label,
        indentLevel: toggleIndent,
        new Toggle { value = td.Get() },
        evt =>
        {
            if (td.Get() == evt.newValue) return; // 用==, 效率略高, 且无需装箱, 在确定两个值都不会为null时可以使用
            registerUndo(td.UndoMessage);
            td.Set(evt.newValue);
            onChange();
        });
}
```

同时, 我们需要把一类的物体放在一个`Foldout`中, 以免大量的`Toggle`同时显示在面板上.

### 02.1 实现-统一绘制函数

与`ToggleDefinition`一样, 声明一个`SectionDefinition`, 用来提供绘制`Foldout`所需的信息, 并且将`HashSet<ToggleDefinition>`作为字段放在其中, 以方便绘制函数统一绘制. 

```c#
/// <summary>
/// 折叠面板的定义：标题、颜色、折叠状态访问器，以及它下面的所有 toggles
/// </summary>
internal class SectionDefinition
{
    public string Title;
    public Color  LabelColor;
    public Func<bool>  GetFold;
    public Action<bool> SetFold;
    public HashSet<ToggleDefinition> Toggles;
}
```

然后, 默认的`TargetPropertyGUIContext`中并没有`AddFoldout`的支持, 所以得自己实现一个, 参照`AddProperty`的实现, 代码如下:

注: 其中`kIndentWidthInPixel`的值为15. 另, `ApplyPadding(PropertyRow row, int indentLevel)`是私有方法, 直接copy实现即可(也可以用反射), 这两个部分都在文件`PackageCache\com.unity.shadergraph\Editor\Generation\Contexts\TargetPropertyGUIContext.cs`中. 所以, 我把这部分写在`TargetPropertyGUIContextExtensions.cs`中, 作为扩展方法.

```c#
/// <summary>
/// 在 TargetPropertyGUIContext 中添加一个 Foldout 控件：
/// 可选 tooltip、indentLevel、labelColor、callback；
/// 使用 PropertyRow 包装，调用 ApplyPadding 保持缩进一致。
/// </summary>
public static void AddFoldout(this TargetPropertyGUIContext context,
    string title,
    string tooltip,
    Foldout foldout,
    int indentLevel,
    Color? labelColor,
    EventCallback<ChangeEvent<bool>> callback)
{
    // 注册回调
    if (callback != null)
        foldout.RegisterValueChangedCallback(callback);

    // 构建行容器
    var labelItem = new Label(title) { tooltip = tooltip };
    var row = new PropertyRow(labelItem);

    // 手动应用缩进：复制 ApplyPadding 的内部逻辑
    // 本来应该用 context.ApplyPadding, 是私有方法, 我不想反射去取
    // 内部是： row.Q(className:"unity-label").style.marginLeft = (ctx.globalIndentLevel + indentLevel) * kIndentWidthInPixel;
    var unityLabel = row.Q(className: "unity-label");
    if (unityLabel != null)
    {
        unityLabel.style.marginLeft = (context.globalIndentLevel + indentLevel) * kIndentWidthInPixel;
    }

    // 可选上色
    if (labelColor.HasValue)
        labelItem.style.color = labelColor.Value;

    // 把 Foldout 本体放入行内
    row.Add(foldout);
    context.hierarchy.Add(row);
}
```



最终的绘制函数为

```c#
internal static void DrawSection(
        ref TargetPropertyGUIContext context,
        SectionDefinition section,
        Action onChange,
        Action<string> registerUndo,
        int foldIndent = 0)
{
    // 折叠面板
    var foldout = new Foldout { value = section.GetFold() };
    context.AddFoldout(
        title:       section.Title,
        foldout:     foldout,
        indentLevel: foldIndent,
        labelColor:  section.LabelColor,
        callback:    evt =>
        {
            section.SetFold(evt.newValue);
            onChange();
        });

    if (!section.GetFold())
        return;

    // 折叠打开后，依次绘制 toggle
    int toggleIndent = foldIndent + 1;
    foreach (var td in section.Toggles)
    {
        context.AddProperty(
            label:       td.Label,
            indentLevel: toggleIndent,
            new Toggle { value = td.Get() },
            evt =>
            {
                if (td.Get() == evt.newValue) return;
                registerUndo(td.UndoMessage);
                td.Set(evt.newValue);
                onChange();
            });
    }
}
```

增加绘制函数, 绘制函数需要用到的`SectionDefinition`和需要调用的属性(`classicKeywordsFoldoutOn`), 以及属性对应的序列化字段(`m_ClassicKeywordsFoldoutOn`默认值为`false`即收起), 和通常的属性和属性对应的序列化字段一样, 正常声明即可. 绘制函数在 `GetPropertiesGUI()`方法中, 绘制完原本的参数后, 再调用即可.

```c#

public override void GetPropertiesGUI(ref TargetPropertyGUIContext context, Action onChange,
    Action<String> registerUndo)
{
    ...

    context.AddProperty("Clear Coat", new Toggle() { value = clearCoat }, (evt) =>
    {
        if (Equals(clearCoat, evt.newValue))
            return;

        registerUndo("Change Clear Coat");
        clearCoat = evt.newValue;
        onChange();
    });

    #region 加入自定义UI

    // 自定义 External Control 块
    DrawExternalControlGUI(ref context, onChange, registerUndo);

    #endregion
}

private void DrawExternalControlGUI(
            ref TargetPropertyGUIContext context,
            Action onChange,
            Action<string> registerUndo)
    {
#if UNITY_EDITOR
        Debug.Log("DrawExternalControlGUI");
#endif
        var sections = CreateSectionDefinitions();

        foreach (var section in sections)
        {
            SubTargetExternalUIUtils.DrawSection(
                ref context,
                section,
                onChange,
                registerUndo
            );
        }
    }

SectionDefinition[] CreateSectionDefinitions()
{
    return new SectionDefinition[]
    {
        ...
        new SectionDefinition()
        {
            Title = CustomStyles.ClassicKeywordsFoldoutName,
            LabelColor = CustomStyles.ClassicKeywordsFoldoutColor,
            GetFold = () => classicKeywordsFoldoutOn,
            SetFold = v => classicKeywordsFoldoutOn = v,
            Toggles = m_keywordToggleDefinitions
        },
        ...
    }
}
```



### 03.0 思路-正式添加

分三个步骤

- 添加序列化字段
- 添加字段对应属性
- 在初始化函数中添加对应的`ToggleDefinition`

### 03.1 实现-正式添加

添加序列化字段

```c#
[SerializeField] private bool m_ScreenSpaceAmbientOcclusion = true;
```

添加字段对应属性

```c#
public bool screenSpaceAmbientOcclusion
{
    get => m_ScreenSpaceAmbientOcclusion;
    set => m_ScreenSpaceAmbientOcclusion = value;
}
```

在初始化函数中添加对应的`ToggleDefinition`

```c#
private void InitKeywordToggleDefinitions()
{
    m_keywordToggleDefinitions.Add(new ToggleDefinition(LitKeywords.ScreenSpaceAmbientOcclusion)
    {
        Get = () => screenSpaceAmbientOcclusion,
        Set = v => screenSpaceAmbientOcclusion = v,
    });
    ...
}
```

至此, 添加结束


###### 参考网页
