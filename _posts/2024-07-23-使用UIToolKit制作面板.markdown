---
layout: post
title: "使用UIToolKit制作面板"
categories: [Unity, UI]
tags: Unity UI UIToolKit
math: true


---

# 使用UIToolKit制作面板

## 00 制作Editor面板

### 00.0 点击生成按钮

在`Project`面板中右键菜单选择`Create->UI Toolkit->Editor Window`

![image-20240723103347081](/assets/image/image-20240723103347081.png)

### 00.1 选择模板文件

输入名称后, 其中UXML和USS是`EditorWindow`的布局和样式文件, Action可以选择只创建文件或者创建并在UIBuilder中打开, UXML和USS文件不是必须, 熟练之后后续可以不创建或者删除. 

![image-20240723103559266](/assets/image/image-20240723103559266.png)

### 00.2 UI Builder必要的设置

开启编辑器专用的组件

![image-20240723104124282](/assets/image/image-20240723104124282.png)

开启编辑器预览, 通常选择`Active Editor Theme`. 这里笔者选择的是暗色主题.

![image-20240723104218979](/assets/image/image-20240723104218979.png)

### 00.3 存储UI元素为模板以在代码中调用

在`UI Builder`中右键需要保存的UI元素, 选择`Create Template`以创建`uxml`文件. 后续可以在脚本中调用, 见`具体案例`部分.

![image-20240723113756964](/assets/image/image-20240723113756964.png)

### 00.4 Editor脚本的编辑

开启`EditorWindowSample.cs`文件, 内容如下. 建议添加的代码会用`//Add On`和`//Add End`进行包裹.

```csharp
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;

public class EditorWindowSample : EditorWindow
{
    // 这里是通过直接在脚本上赋予EditorWindowSample.uxml来进行关联的
    // 而EditorWindowSample.uss是直接通过UI Builder由EditorWindowSample.uxml引用的.
    [SerializeField]
    private VisualTreeAsset m_VisualTreeAsset = default;
    // Add On
    // 通过一个Vector2来设置窗口最小的Size, 以保证最低的UI排布
    private static Vector2 windowMinSize = new Vector2(500, 500);
    // Add End

    // 工具调用的窗口路径
    [MenuItem("Window/UI Toolkit/EditorWindowSample")]
    public static void ShowExample()
    {
        EditorWindowSample wnd = GetWindow<EditorWindowSample>();
        wnd.titleContent = new GUIContent("EditorWindowSample");
        // Add On
        // 设置窗口最小的Size
        wnd.minSize = windowMinSize;
        // Add End
    }

    public void CreateGUI()
    {
        // Each editor window contains a root VisualElement object
        // 必须声明rootVisualElement, 所有的UI元素都需要添加在Root中
        VisualElement root = rootVisualElement;

        // VisualElements objects can contain other VisualElement following a tree hierarchy.
        // 可以通过c#脚本添加UI元素
        VisualElement label = new Label("Hello World! From C#");
        root.Add(label);

        // Instantiate UXML
        // 也可以通过uxml文件的Instantiate方法来实例化UI元素并添加
        VisualElement labelFromUXML = m_VisualTreeAsset.Instantiate();
        root.Add(labelFromUXML);
    }
}
```

### 00.5 具体案例

通过设置全局着色器变量的预览工具.

```csharp
using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.UIElements;
using Object = UnityEngine.Object;

/*----------------------------------------------------------------------------------------------------------------------
 * 参考网页
 * 读取UXML和USS文件 https://docs.unity3d.com/Manual/UIE-manage-asset-reference.html
 * 可参考文件
 * LightBatchingDebugger.cs
 * 示例中所有的字符串都建议用常量来保存以避免额外的GC
 ---------------------------------------------------------------------------------------------------------------------*/
public class LutPreviewer : EditorWindow
{
    private const string ResourcePath = "Packages/com.render.core/Editor/LutPreviewer/";
    private static VisualElement root;
    private static int lutFieldNum = 5;
    // 用于临时存储Lut贴图, 将UI和数据分离.
    private static readonly Dictionary<string, Texture2D> s_LutDictionary = new Dictionary<string, Texture2D>();
    private static readonly Vector2 s_WindowMinSize = new Vector2(500, 500);
    private VisualElement _lutArea;
    private IntegerField _lutFieldNumField;

    [MenuItem("Render/工具/LutPreviewer")]
    public static void ShowExample()
    {
        LutPreviewer wnd = GetWindow<LutPreviewer>();
        wnd.titleContent = new GUIContent("LutPreviewer");
        wnd.minSize = s_WindowMinSize;
    }

    // Create once, initialize
    public void CreateGUI()
    {
        // VisualTreeAsset uxml = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>("Assets/Editor/main_window.uxml");
        // StyleSheet uss = AssetDatabase.LoadAssetAtPath<StyleSheet>("Assets/Editor/main_styles.uss");
        // VisualTreeAsset uxml = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>("Packages/<name-of-the-package>/main_window.uxml");
        // StyleSheet uss = AssetDatabase.LoadAssetAtPath<StyleSheet>("Packages/<name-of-the-package>/main_styles.uss");

        root = rootVisualElement;
        CreateLutControls();
        CreateLutFields(lutFieldNum);
    }

    private void CreateLutControls()
    {
        var controlArea = new VisualElement
        {
            style = { flexDirection = FlexDirection.Row }
        };

        _lutFieldNumField = new IntegerField("Lut图栏位数")
        {
            value = lutFieldNum
        };
        _lutFieldNumField.RegisterValueChangedCallback(OnLutFieldNumChanged);

        var slider = new Slider("手动滑条", 0, 1)
        {
            style = { flexGrow = 1 }
        };
        slider.RegisterValueChangedCallback(value =>
        {
            if (value?.newValue != null)
            {
                Shader.SetGlobalFloat("_LutLerp", (float)value.newValue);
            }
        });
        controlArea.Add(_lutFieldNumField);
        controlArea.Add(slider);
        root.Add(controlArea);
    }

    private void CreateLutFields(int fieldCount)
    {
        _lutArea = new VisualElement();
        for (int i = 0; i < fieldCount; i++)
        {
            var lutFieldContainer = LoadLutFieldContainer(i);
            _lutArea.Add(lutFieldContainer);
        }
        root.Add(_lutArea);
    }

    private VisualElement LoadLutFieldContainer(int index)
    {
        // 读取存储模板的uxml文件来绘制UI元素, 将UI与逻辑分离
        var lutFieldContainer = AssetDatabase.LoadAssetAtPath<VisualTreeAsset>(Path.Combine(ResourcePath, "LutTextureField") + ".uxml").Instantiate();
        lutFieldContainer.name = "lutField" + index;

        ObjectField textureField = lutFieldContainer.Q<ObjectField>("TextureField");
        if (s_LutDictionary.TryGetValue(lutFieldContainer.name, out var value))
        {
            textureField.value = value;
        }
        void Callback(ChangeEvent<Object> evt)
        {
            s_LutDictionary[lutFieldContainer.name] = evt.newValue as Texture2D;
        }
        textureField.RegisterValueChangedCallback(Callback);
        var btn = lutFieldContainer.Q<Button>("Button");
        btn.text = "激活";
        btn.clickable.clicked += () => ActivateLut(textureField);

        return lutFieldContainer;
    }

    private void ActivateLut(ObjectField textureField)
    {
        if (textureField.value == null || textureField.value.GetType() != typeof(Texture2D)) return;
        Shader.SetGlobalTexture("_LutMap", (Texture2D)textureField.value);
    }

    private void OnLutFieldNumChanged(ChangeEvent<int> evt)
    {
        // 避免在删除这个数字时的重绘, 0时的重绘除了消除数据没有其他意义.
        if (evt.newValue == 0)
        {
            return;
        }
        lutFieldNum = evt.newValue;
        _lutArea.Clear();
        CreateLutFields(evt.newValue);
    }

    private void OnDisable()
    {
        Shader.SetGlobalFloat("_LutLerp", 0.0f);
        Shader.SetGlobalTexture("_LutMap", null);
    }
}
```



###### 参考网页

[Unity教程：使用UI Toolkit扩展Unity编辑器（五）USS样式&Debug调试 (youtube.com)](https://www.youtube.com/watch?v=rgtYqyhc5xE&list=PLwjV0YbX5INaJzloVvmNfgCbg2gJdpDsU)

[【Unity3D】UI Toolkit自定义元素-CSDN博客](https://blog.csdn.net/m0_37602827/article/details/132750080)

[Unity - Manual: Load UXML and USS C# scripts (unity3d.com)](https://docs.unity3d.com/Manual/UIE-manage-asset-reference.html)
