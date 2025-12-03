---
layout: post
title: "[ShaderGraph]为Porperties添加HideInInspector前缀"
categories: [URP, ShaderGraph]
tags: URP ShaderGraph 定制 HideInInspector 隐藏参数 反射优化 字符串优化
math: true


---

# [ShaderGraph]为Porperties添加HideInInspector前缀

## 00 前置知识

ShaderGraph没有办法直接添加隐藏参数.

## 01 实施

### 0 初次尝试(失败)

如果能修改ShaderGraph源码的话, 其实只需要很简单的参数就能够添加. 

找到`ShaderInputPropertyDrawer.cs`, 在其中添加`BuildHideInInspectorField`方案, 并写到`BuildPropertyFields`中

```c#
void BuildPropertyFields(PropertySheet propertySheet)
{
    if (shaderInput is AbstractShaderProperty property)
    {
        ...

        BuildPrecisionField(propertySheet, property);

        BuildExposedField(propertySheet);

        BuildHLSLDeclarationOverrideFields(propertySheet, property);
        // Add Start
        BuildHideInInspectorField(propertySheet);
        // Add End
    }

    BuildCustomBindingField(propertySheet, shaderInput);
}

void BuildHideInInspectorField(PropertySheet propertySheet)
{
    if (!isSubGraph && shaderInput is AbstractShaderProperty abstractShaderProperty)
    {
        var toggleDataPropertyDrawer = new ToggleDataPropertyDrawer();
        propertySheet.Add(toggleDataPropertyDrawer.CreateGUI(evt =>
        {
            this._preChangeValueCallback("Change HideInInspector Toggle");
            abstractShaderProperty.hidden = evt.isOn;
            this._postChangeValueCallback(false, ModificationScope.Graph);

        },
            new ToggleData(abstractShaderProperty.hidden),
                "HideInInspector",
                out var hideInInspectorToggleVisualElement));
    }
}
```



就可以在ShaderGraph的Property中添加一个CheckBox用来控制最终生成的代码的Properties中添加`[HideInInspector]`前缀.

但是, 实际上, 由于ShaderGraph绘制代码用的是另一套自定义的界面绘制方案, 即便是加了`[HideInInspector]`, 仍旧会绘制这个属性.

所以还需要在绘制的时候识别该前缀.

### 1 继续推进(功能已实现)

通过查看, 绘制ShaderGraph的GUI部分是在文件`Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGUI/ShaderGraphLitGUI.cs`中

```c#
class ShaderGraphLitGUI : BaseShaderGUI
{
...
}
```

而在这个派生类中并没有自定义的UI的绘制, 所以我们查看基类文件`Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGUI/BaseShaderGUI.cs`

```c#
public abstract class BaseShaderGUI : ShaderGUI
{
...
#region DrawingFunctions
internal void DrawShaderGraphProperties(Material material, IEnumerable<MaterialProperty> properties)
{
    if (properties == null)
        return;

    ShaderGraphPropertyDrawers.DrawShaderGraphGUI(materialEditor, properties);
}
...
##endregion

```

继续查下去到文件`Packages/com.unity.shadergraph@12.1.10/Editor/Drawing/MaterialEditor/ShaderGraphPropertyDrawers.cs`, 继续查函数调用链.

```c#
internal static class ShaderGraphPropertyDrawers
{
...
    public static void DrawShaderGraphGUI(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties)
    {
        Material m = materialEditor.target as Material;
        Shader s = m.shader;
        string path = AssetDatabase.GetAssetPath(s);
        ShaderGraphMetadata metadata = null;
        foreach (var obj in AssetDatabase.LoadAllAssetsAtPath(path))
        {
            if (obj is ShaderGraphMetadata meta)
            {
                metadata = meta;
                break;
            }
        }

        if (metadata != null)
            DrawShaderGraphGUI(materialEditor, properties, metadata.categoryDatas);
        else
            PropertiesDefaultGUI(materialEditor, properties);
    }
...
    public static void DrawShaderGraphGUI(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties, IEnumerable<MinimalCategoryData> categoryDatas)
    {
        foreach (MinimalCategoryData mcd in categoryDatas)
        {
            DrawCategory(materialEditor, properties, mcd);
        }
    }
...
     static void DrawCategory(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties, MinimalCategoryData minimalCategoryData)
    {
```
    if (minimalCategoryData.expanded)
        {
            foreach (var propData in minimalCategoryData.propertyDatas)
            {
                if (propData.isCompoundProperty == false)
                {
                    MaterialProperty prop = FindProperty(propData.referenceName, properties);
                    if (prop == null) continue;
                    // Add Start
                    if ((prop.flags & MaterialProperty.PropFlags.HideInInspector) !=0)
                    {
                        continue;
                    }
                    // Add End
                    DrawMaterialProperty(materialEditor, prop, propData.propertyType, propData.isKeyword, propData.keywordType);
                }
                else
                {
                    DrawCompoundProperty(materialEditor, properties, propData);
                }
            }
        }
    
        EditorGUILayout.EndFoldoutHeaderGroup();
    }
...
    static void DrawCompoundProperty(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties, GraphInputData compoundPropertyData)
    {
    ```
       if (foldoutState)
        {
            EditorGUI.indentLevel++;
            foreach (var subProperty in compoundPropertyData.subProperties)
            {
                var property = FindProperty(subProperty.referenceName, properties);
                if (property == null) continue;
                // Add Start
                if ((property.flags & MaterialProperty.PropFlags.HideInInspector) !=0)
                {
                    continue;
                }
                // Add End
                DrawMaterialProperty(materialEditor, property, subProperty.propertyType);
            }
            EditorGUI.indentLevel--;
        } 
    ...
}
```

至此, 功能实现.

### 2 减少侵入性(妥协性改良)

目前的修改, 算是相对逻辑正确的方法. 分两部分实现:

- 在ShaderInputPropertyDrawer中, 让ShaderGraph的面板上添加HideInInspector来让Shader的参数有`[HideInInspector]`前缀.
- 在ShaderGraphPropertyDrawers.cs中, 让最终绘制的面板识别这个[HideInInspector]前缀而不去绘制.

好处是, 即便是不使用ShaderGraph的面板, Unity默认的Shader面板绘制, 也能正确的隐藏参数, 坏处是, 修改了ShaderGraph的源码, 属于侵入式修改. 而且目前能力不足, 找不到方便的正常非侵入式做法.

目前的方案就改为: 

不强求添加`[HideInInspector]`前缀, 仅仅是通过参数或者Category的名称中的特殊字段来决定是否绘制. 

好处是, 不用进行侵入式修改.

坏处是, 不优雅, 且对命名有额外的需求.

鉴于其实并不想对ShaderGraph进行深入定制, 且并不排斥对隐藏的面板的命名要求(因为已经隐藏了, 那么命名也就无意义), 所以采用这个方案. 

#### 2a 替换自定义面板

仿照`Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGUI/ShaderGraphLitGUI.cs`复制一份, 比如叫`ShaderGraphExtensionLitGUI.cs`

在之前我们的自定义的`ShaderGraphExtensionLitGUI.cs`文件中找到`Setup`函数, 替换掉其中的`ShaderGraphLitGUI`为`ShaderGraphExtensionLitGUI`

```c#
public override void Setup(ref TargetSetupContext context)
{
...

    base.Setup(ref context);

    var universalRPType = typeof(UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset);
    if (!context.HasCustomEditorForRenderPipeline(universalRPType))
    {
        // 替换这里
        var gui = typeof(ShaderGraphExtensionLitGUI);
#if HAS_VFX_GRAPH
        if (TargetsVFX())
            gui = typeof(VFXShaderGraphLitGUI);
#endif
        context.AddCustomEditorForRenderPipeline(gui.FullName, universalRPType);
    }

...
}
```

#### 1a 替换UI绘制方法

在复制出来的`ShaderGraphExtensionLitGUI.cs`文件中, 找到`DrawSurfaceInputs`方法, 然后把其中的`DrawShaderGraphProperties`函数, 替换为自己写的`DrawShaderGraphPropertiesExtended`函数.

```
public override void DrawSurfaceInputs(Material material)
{
    // DrawShaderGraphProperties(material, properties);
    DrawShaderGraphPropertiesExtended();
}

internal void DrawShaderGraphPropertiesExtended()
{
    if (properties == null)
        return;

    ShaderGraphPropertyDrawersExtension.DrawShaderGraphGUI(materialEditor, properties);
}
```

#### 1b 修改真正要修改的部分

`ShaderGraphPropertyDrawersExtension`类对应的是`E:\Projects\CarModelTestCase\Packages\com.unity.shadergraph@12.1.10\Editor\Drawing\MaterialEditor\ShaderGraphPropertyDrawers.cs`类.

其中, 其实只需要修改`DrawCategory`方法, 我们把其他方法用反射的方式调用

```c#
using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEditor.ShaderGraph;
using UnityEditor.ShaderGraph.Drawing;
using UnityEditor.ShaderGraph.Internal;
using UnityEngine;

namespace ShaderGraphExtension
{
    internal static class ShaderGraphPropertyDrawersExtension
    {
        static readonly string HideInInspector = "HideInInspector";
        static readonly string MethodNamePropertiesDefaultGUI = "PropertiesDefaultGUI";
        static readonly string MethodNameDrawMaterialProperty = "DrawMaterialProperty";
        static readonly string MethodNameDrawCompoundProperty = "DrawCompoundProperty";
        
        public static void DrawShaderGraphGUI(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties)
        {
            Material m = materialEditor.target as Material;
            Shader s = m.shader;
            string path = AssetDatabase.GetAssetPath(s);
            ShaderGraphMetadata metadata = null;
            foreach (var obj in AssetDatabase.LoadAllAssetsAtPath(path))
            {
                if (obj is ShaderGraphMetadata meta)
                {
                    metadata = meta;
                    break;
                }
            }

            if (metadata != null)
                DrawShaderGraphGUI(materialEditor, properties, metadata.categoryDatas);
            else
                PropertiesDefaultGUI(materialEditor, properties);
        }
        
        static MaterialProperty FindProperty(string propertyName, IEnumerable<MaterialProperty> properties)
        {
            foreach (var prop in properties)
            {
                if (prop.name == propertyName)
                {
                    return prop;
                }
            }

            return null;
        }

        public static void DrawShaderGraphGUI(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties,
            IEnumerable<MinimalCategoryData> categoryDatas)
        {
            foreach (MinimalCategoryData mcd in categoryDatas)
            {
                DrawCategory(materialEditor, properties, mcd);
            }
        }
        
        static void DrawCategory(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties, MinimalCategoryData minimalCategoryData)
        {
            // Add by Yumiao
            if (minimalCategoryData.categoryName.Contains(HideInInspector))
            {
                return;
            }
            // End Add
            if (minimalCategoryData.categoryName.Length > 0)
            {
                minimalCategoryData.expanded = EditorGUILayout.BeginFoldoutHeaderGroup(minimalCategoryData.expanded, minimalCategoryData.categoryName);
            }
            else
            {
                // force draw if no category name to do foldout on
                minimalCategoryData.expanded = true;
            }

            if (minimalCategoryData.expanded)
            {
                foreach (var propData in minimalCategoryData.propertyDatas)
                {
                    if (propData.isCompoundProperty == false)
                    {
                        MaterialProperty prop = FindProperty(propData.referenceName, properties);
                        if (prop == null) continue;
                        // Add by Yumiao
                        if (prop.displayName.Contains(HideInInspector))
                        {
                            continue;
                        }
                        // End Add
                        DrawMaterialProperty(materialEditor, prop, propData.propertyType, propData.isKeyword, propData.keywordType);
                    }
                    else
                    {
                        DrawCompoundProperty(materialEditor, properties, propData);
                    }
                }
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }
        
        static MethodInfo s_PropertiesDefaultGUI;
        static MethodInfo s_DrawMaterialProperty;
        static MethodInfo s_DrawCompoundProperty;

        static ShaderGraphPropertyDrawersExtension()
        {
            // 获取 private static 方法
            var type = typeof(ShaderGraphPropertyDrawers);
            s_PropertiesDefaultGUI = type.GetMethod(
                MethodNamePropertiesDefaultGUI,
                BindingFlags.NonPublic | BindingFlags.Static,
                null,
                new[] { typeof(MaterialEditor), typeof(IEnumerable<MaterialProperty>) },
                null
            );
            if (s_PropertiesDefaultGUI == null)
                Debug.LogError("找不到 PropertiesDefaultGUI 方法");

            s_DrawMaterialProperty = type.GetMethod(
                MethodNameDrawMaterialProperty,
                BindingFlags.NonPublic | BindingFlags.Static,
                null,
                new[] { typeof(MaterialEditor), typeof(MaterialProperty), typeof(PropertyType), typeof(bool), typeof(KeywordType) },
                null
            );
            if (s_DrawMaterialProperty == null)
                Debug.LogError("找不到 DrawMaterialProperty 方法");

            s_DrawCompoundProperty = type.GetMethod(
                MethodNameDrawCompoundProperty,
                BindingFlags.NonPublic | BindingFlags.Static,
                null,
                new[]
                {
                    typeof(MaterialEditor), typeof(IEnumerable<MaterialProperty>), typeof(GraphInputData),
                },
                null
            );
            if (s_DrawCompoundProperty == null)
                Debug.LogError("找不到 DrawCompoundProperty 方法");
        }

        private static void PropertiesDefaultGUI(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties)
        {
            if (s_PropertiesDefaultGUI == null)
                return;
            // 调用 private static 方法
            s_PropertiesDefaultGUI.Invoke(
                /* obj */ null,
                /* parameters */ new object[] { materialEditor, properties }
            );
        }

        private static void DrawMaterialProperty(MaterialEditor materialEditor, MaterialProperty property, PropertyType propertyType, bool isKeyword = false, KeywordType keywordType = KeywordType.Boolean)
        {
            if (s_DrawMaterialProperty == null)
                return;
            s_DrawMaterialProperty.Invoke(
                null,
                new object[] { materialEditor, property, propertyType, isKeyword, keywordType }
            );
        }

        private static void DrawCompoundProperty(MaterialEditor materialEditor,
            IEnumerable<MaterialProperty> properties, GraphInputData compoundPropertyData)
        {
            if (s_DrawCompoundProperty == null)
                return;
            s_DrawCompoundProperty.Invoke(
                null,
                new object[] { materialEditor, properties, compoundPropertyData }
            );
        }
    }
}
```

### 2 优化

#### ~~2a 优化反射~~

~~这部分是AI协助完成的. 解释如下:~~

>~~所有未来需要通过反射调用的私有方法，都可以套用同一套「懒加载＋委托缓存」的模式来优化。核心步骤如下：~~
>
>1. ~~**定义一个通用的委托工厂**~~
>
>   ```
>   static T CreateStaticDelegate<T>(Type host, string name, BindingFlags flags, Type[] sig)
>       where T : Delegate
>   {
>       var mi = host.GetMethod(name, flags, null, sig, null)
>                ?? throw new InvalidOperationException($"Cannot find {host.FullName}.{name}");
>       return (T)mi.CreateDelegate(typeof(T));
>   }
>   ```
>
>2. ~~**为每个反射目标用 `Lazy<T>` 懒加载一次**~~
>
>   ```
>   static readonly Lazy<Action<MaterialEditor, IEnumerable<MaterialProperty>>> _propsGui =
>     new Lazy<Action<MaterialEditor, IEnumerable<MaterialProperty>>>(() =>
>       CreateStaticDelegate<Action<MaterialEditor, IEnumerable<MaterialProperty>>>(
>         typeof(ShaderGraphPropertyDrawers),
>         "PropertiesDefaultGUI",
>         BindingFlags.NonPublic | BindingFlags.Static,
>         new[]{ typeof(MaterialEditor), typeof(IEnumerable<MaterialProperty>) }
>       )
>     );
>   ```
>
>   ~~这样你永远只在第一次调用时做一次 `GetMethod`＋`CreateDelegate`，之后直接用 `_propsGui.Value(...)`。~~
>
>3. ~~**后续所有反射调用全都走这个套路**~~
>
>   - ~~私有**静态**方法用 `Action<…>` 或 `Func<…>`；~~
>   - ~~私有**实例**方法可以用 `Func<TTarget,…>`／`Action<TTarget,…>`；~~
>   - ~~参数/signature 只要在 `CreateStaticDelegate` 里指定正确即可。~~
>
>4. ~~**调用时不再用 `Invoke`**~~
>
>   ```
>   _propsGui.Value(materialEditor, properties);
>   ```
>
>   ~~避免了每次反射查找与装箱开销，性能接近直接方法调用。~~
>
>------
>
>### ~~小结~~
>
>- ~~**懒加载**：`Lazy<T>` 保证只做一次反射查找。~~
>- ~~**委托缓存**：`CreateDelegate` 结果缓存起来，用委托调用替代 `Invoke`。~~
>- ~~**通用可复用**：无论是 `PropertiesDefaultGUI`、`DrawMaterialProperty` 还是其他任何私有方法，只要签名匹配，都能用这一套写法。~~
>
>~~这样，你后面所有的反射需求都能统一走这条高速通道，既优雅又高效~~

这套反射优化会导致调用出错, 后续可以用其他方式优化. 考虑到编辑器功能, 放弃优化即可.

#### 2b 优化字符串比较

将类似`string.Contains(string value)`换成`string.IndexOf("strings", StringComparison.Ordinal)`的写法, AI优化, 解释如下: 

>`string.Contains(string value)` 在大多数 .NET 实现里默认使用“当前文化”（CurrentCulture）规则去查找子串，这意味着它必须考虑区域性规则（大写/小写折叠、组合字符、Unicode 分类等）——这会引入额外的开销。而：
>
>```
>prop.displayName.IndexOf(HideInInspector, StringComparison.Ordinal)
>```
>
>则是**纯字节级**（binary）比较，不做任何文化或语言层面的转换，直接在内存里逐个 `char` 对比，类似于 `memcmp`。
>
>- **无文化开销**：不需要检查 Unicode 分类、不做大小写折叠。
>- **更少分支和函数调用**：底层直接调用高效的本机代码或简单循环。
>- **确定性更强**：同一段内存一定返回同一结果，不受系统区域设置影响。
>
>因此，指定 `StringComparison.Ordinal` 的 `IndexOf` 性能最佳，特别是当你只需要“原始”字符匹配时。
>
>
>
>```
>prop.displayName.IndexOf(HideInInspector, StringComparison.Ordinal)
>```
>
>
>的含义是：
>
>在 `prop.displayName` 这个字符串里，搜索子串 `HideInInspector`。
>
>使用 `StringComparison.Ordina`l，也就是“逐字符、按 Unicode 编码”进行比较，不考虑任何文化（地区/语言）差异。
>
>如果找到，返回子串首次出现的索引（从 0 开始）；如果没找到，返回 –1。
>
>
>
>常见情况下你都可以把
>
>```
>if (str.Contains(sub))
>{
>    …
>}
>```
>
>改写成
>
>```
>if (str.IndexOf(sub, StringComparison.Ordinal) >= 0)
>{
>    …
>}
>```
>
>这样做有两个好处：
>
>1. **显式指定比较规则**
>   - `StringComparison.Ordinal` 表示“按字符编码逐字节比较”，不做任何文化或大小写折叠。
>   - 对比 `Contains`（在某些 .NET 版本下默认是文化相关比较），能避免因系统区域设置不同而产生的差异。
>2. **性能略优**
>   - 底层直接做二进制级的字符串扫描，较少额外判断和分支，尤其适合大量或频繁的匹配场景。
>
>> **小贴士**：
>>
>> - 如果你需要**同时忽略大小写**，可以用
>>
>>   ```
>>   str.IndexOf(sub, StringComparison.OrdinalIgnoreCase) >= 0
>>   ```
>>
>> - 在 .NET Core/.NET 5+ 里，也可以直接用带比较器的 `Contains`：
>>
>>   ```
>>   str.Contains(sub, StringComparison.Ordinal)
>>   ```
>>
>>   但在更早的 .NET/Mono 环境下，这个重载并不存在，所以 `IndexOf` 是最通用的做法。

## 02 最终代码

```c#
using System;
using System.Collections.Generic;
using System.Reflection;
using UnityEditor;
using UnityEditor.ShaderGraph;
using UnityEditor.ShaderGraph.Drawing;
using UnityEditor.ShaderGraph.Internal;
using UnityEngine;

namespace ShaderGraphExtension
{
    internal static class ShaderGraphPropertyDrawersExtension
    {
        static readonly string HideInInspector = "HideInInspector";
        static readonly string MethodNamePropertiesDefaultGUI = "PropertiesDefaultGUI";
        static readonly string MethodNameDrawMaterialProperty = "DrawMaterialProperty";
        static readonly string MethodNameDrawCompoundProperty = "DrawCompoundProperty";
        
        public static void DrawShaderGraphGUI(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties)
        {
            Material m = materialEditor.target as Material;
            Shader s = m.shader;
            string path = AssetDatabase.GetAssetPath(s);
            ShaderGraphMetadata metadata = null;
            foreach (var obj in AssetDatabase.LoadAllAssetsAtPath(path))
            {
                if (obj is ShaderGraphMetadata meta)
                {
                    metadata = meta;
                    break;
                }
            }

            if (metadata != null)
                DrawShaderGraphGUI(materialEditor, properties, metadata.categoryDatas);
            else
                // PropertiesDefaultGUI(materialEditor, properties);
                _propertiesDefaultGui.Value(materialEditor, properties);
        }
        
        static MaterialProperty FindProperty(string propertyName, IEnumerable<MaterialProperty> properties)
        {
            foreach (var prop in properties)
            {
                if (prop.name == propertyName)
                {
                    return prop;
                }
            }

            return null;
        }

        public static void DrawShaderGraphGUI(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties,
            IEnumerable<MinimalCategoryData> categoryDatas)
        {
            foreach (MinimalCategoryData mcd in categoryDatas)
            {
                DrawCategory(materialEditor, properties, mcd);
            }
        }
        
        static void DrawCategory(MaterialEditor materialEditor, IEnumerable<MaterialProperty> properties, MinimalCategoryData minimalCategoryData)
        {
            // Add by Yumiao
            if (minimalCategoryData.categoryName.IndexOf(HideInInspector, StringComparison.Ordinal) >= 0)
            {
                return;
            }
            // End Add
            if (minimalCategoryData.categoryName.Length > 0)
            {
                minimalCategoryData.expanded = EditorGUILayout.BeginFoldoutHeaderGroup(minimalCategoryData.expanded, minimalCategoryData.categoryName);
            }
            else
            {
                // force draw if no category name to do foldout on
                minimalCategoryData.expanded = true;
            }

            if (minimalCategoryData.expanded)
            {
                foreach (var propData in minimalCategoryData.propertyDatas)
                {
                    if (propData.isCompoundProperty == false)
                    {
                        MaterialProperty prop = FindProperty(propData.referenceName, properties);
                        if (prop == null) continue;
                        // Add by Yumiao
                        if (prop.displayName.IndexOf(HideInInspector, StringComparison.Ordinal) >= 0)
                        {
                            continue;
                        }
                        // End Add
                        // DrawMaterialProperty(materialEditor, prop, propData.propertyType, propData.isKeyword, propData.keywordType);
                        _drawMaterialProp.Value(materialEditor, prop, propData.propertyType, propData.isKeyword,
                            propData.keywordType);
                    }
                    else
                    {
                        // DrawCompoundProperty(materialEditor, properties, propData);
                        _drawCompoundProp.Value(materialEditor, properties, propData);
                    }
                }
            }

            EditorGUILayout.EndFoldoutHeaderGroup();
        }
        
        // ===== 1. 反射 Helper & 懒加载 =====

        static readonly Lazy<Action<MaterialEditor, IEnumerable<MaterialProperty>>> _propertiesDefaultGui =
            new Lazy<Action<MaterialEditor, IEnumerable<MaterialProperty>>>(() =>
                CreateStaticDelegate<Action<MaterialEditor, IEnumerable<MaterialProperty>>>(
                    typeof(ShaderGraphPropertyDrawers),
                    MethodNamePropertiesDefaultGUI,
                    BindingFlags.NonPublic | BindingFlags.Static,
                    new[] { typeof(MaterialEditor), typeof(IEnumerable<MaterialProperty>) }
                )
            );

        static readonly Lazy<Action<MaterialEditor, MaterialProperty, PropertyType, bool, KeywordType>> _drawMaterialProp =
            new Lazy<Action<MaterialEditor, MaterialProperty, PropertyType, bool, KeywordType>>(() =>
                CreateStaticDelegate<Action<MaterialEditor, MaterialProperty, PropertyType, bool, KeywordType>>(
                    typeof(ShaderGraphPropertyDrawers),
                    MethodNameDrawMaterialProperty,
                    BindingFlags.NonPublic | BindingFlags.Static,
                    new[] {
                        typeof(MaterialEditor),
                        typeof(MaterialProperty),
                        typeof(PropertyType),
                        typeof(bool),
                        typeof(KeywordType)
                    }
                )
            );

        static readonly Lazy<Action<MaterialEditor, IEnumerable<MaterialProperty>, GraphInputData>> _drawCompoundProp =
            new Lazy<Action<MaterialEditor, IEnumerable<MaterialProperty>, GraphInputData>>(() =>
                CreateStaticDelegate<Action<MaterialEditor, IEnumerable<MaterialProperty>, GraphInputData>>(
                    typeof(ShaderGraphPropertyDrawers),
                    MethodNameDrawCompoundProperty,
                    BindingFlags.NonPublic | BindingFlags.Static,
                    new[] {
                        typeof(MaterialEditor),
                        typeof(IEnumerable<MaterialProperty>),
                        typeof(GraphInputData)
                    }
                )
            );

        // 通用：生成静态方法的委托
        static T CreateStaticDelegate<T>(Type host, string name, BindingFlags flags, Type[] signature)
            where T : Delegate
        {
            var mi = host.GetMethod(name, flags, null, signature, null);
            if (mi == null)
                throw new InvalidOperationException($"Cannot find method {host.FullName}.{name}");
            return (T)mi.CreateDelegate(typeof(T));
        }
    }
}
```



###### 参考网页
