---
layout: post
title: "关于Unity中DepthOfField的记录"
categories: [URP, 后处理]
tags: URP 后处理 DepthOfField
math: true
---

# 关于定制Unity中DepthOfField的记录

## 00 前言

- 策划需要将景深进行分段控制

- 直接对深度进行重映射是最方便的做法

- https://www.desmos.com/calculator/outz8ciqgx

  ![desmos-graph](/assets/image/desmos-graph.png)![image-20231012210548195](/assets/image/image-20231012210548195.png)

- 我希望斜率不仅仅是2, 而是可以是任何值, 且方程连续
  - y=(x-2a)/k+i
  - 且x=p+a时, y=p-a
  - 求出i=(p-a)(1-1/k)
  - 最后y=(x-2a)/k+(p-a)(1-1/k).
- https://www.desmos.com/calculator/5aebyotklu
- ![desmos-graph (1)](/assets/image/desmos-graph_1.png)![image-20231012211205892](/assets/image/image-20231012211205892.png)

## 01 初版

初始版本关键代码如下

```c++
        //Changed
        //P面板=p-a
        //p=p面板+a
        //使用k改变变化速率,将远近的模糊程度分开
        //Todo 优化算法, 消除if
        float a = 2.0;
        float p = 7.0;
        float k = 3;//斜率
        if (linearEyeDepth <= p - a)
        {
            linearEyeDepth = linearEyeDepth;
        }
        else if (linearEyeDepth > p - a && linearEyeDepth < p + a)
        {
            linearEyeDepth = p - a;
        }
        else if (linearEyeDepth >= p + a)
        {
            linearEyeDepth = (linearEyeDepth - 2.0 * a) / k + (p - a) * (1.0 - 1 / k);
        }
        //Changed
```

## 02 优化

考虑到```if...else```在着色器中效率不高, 这里使用step进行了优化.

```c++
        float condition1 = step(p - a, linearEyeDepth) * step(linearEyeDepth, p + a);
        float condition2 = step(p + a, linearEyeDepth);

        linearEyeDepth = condition1 * (p - a) +
        condition2 * ((linearEyeDepth - 2.0 * a) / k + (p - a) * (1.0 - 1 / k)) +
        (1.0 - condition1 - condition2) * linearEyeDepth;
```

当然, 这里可以用```rcp(k)```来把除法消除进行优化

```c++
        float invK = rcp(k);
        float condition1 = step(p - a, linearEyeDepth) * step(linearEyeDepth, p + a);
        float condition2 = step(p + a, linearEyeDepth);

        linearEyeDepth = condition1 * (p - a) +
        condition2 * ((linearEyeDepth - 2.0 * a) * invK + (p - a) * (1.0 - invK)) +
        (1.0 - condition1 - condition2) * linearEyeDepth;
```

但是, 实际上, ```1/k```这个值可以在传入之前就计算完毕, 所以更进一步, ```invK```的计算直接交给CPU即可.

### 彩色石头

在搜索```rcp(x)```的时候, 找到了一些好玩的东西.

- ```Packages/com.unity.render-pipelines.core@14.0.8/Runtime/PostProcessing/Shaders/ffx/ffx_a.hlsl```文件中, 关于```*FLOAT APPROXIMATIONS*```(浮动近似值)的部分有如下注释

  ```c++
  //==============================================================================================================================
  //                                                    FLOAT APPROXIMATIONS
  //------------------------------------------------------------------------------------------------------------------------------
  // Michal Drobot has an excellent presentation on these: "Low Level Optimizations For GCN",
  //  - Idea dates back to SGI, then to Quake 3, etc.
  //  - https://michaldrobot.files.wordpress.com/2014/05/gcn_alu_opt_digitaldragons2014.pdf
  //     - sqrt(x)=rsqrt(x)*x
  //     - rcp(x)=rsqrt(x)*rsqrt(x) for positive x
  //  - https://github.com/michaldrobot/ShaderFastLibs/blob/master/ShaderFastMathLib.h
  //------------------------------------------------------------------------------------------------------------------------------
  // These below are from perhaps less complete searching for optimal.
  // Used FP16 normal range for testing with +4096 32-bit step size for sampling error.
  // So these match up well with the half approximations.
  //==============================================================================================================================
  ```

- 其中的pdf文件有一些特别的优化方式, 当然, pdf是2014年的, 无法保证仍旧有效, 毕竟硬件发展迅速.

- ```Packages/com.unity.render-pipelines.core@14.0.8/ShaderLibrary/API/GLES2.hlsl```中, 由于```rcp(x)```函数的不支持, 所以有如下预定义```#define rcp(x) 1.0 / (x)```

- 关于```rcp(x)```的兼容性, 还有这一篇文章[**unity shader SSAO 环境光屏蔽 rcp 函数 bug - 知乎 (zhihu.com)**](https://zhuanlan.zhihu.com/p/489666024)

  - ```Library/PackageCache/com.unity.postprocessing@3.2.2/PostProcessing/Shaders/StdLib.hlsl```中使用这样的代码来做兼容.

    ```c++
    #if (SHADER_TARGET < 50 && !defined(SHADER_API_PSSL))
    float rcp(float value)
    {
        return 1.0 / value;
    }
    #endif
    ```

- 总之就是, 要使用```rcp(x)```函数, 需要用额外的语句保证兼容性.


## 03 另一种方式

之前用的是定位 $p$ 点, 然后前后扩展 $a$ 距离的方式, 现在是定好近位置 $m$ 和远位置 $n$ 然后来处理, 代码修改如下:
```c++
        // float a = 2.0;
        // float p = 7.0;        
        float k = 3;//斜率//
        float invK = rcp(k);

        // float condition1 = step(p - a, linearEyeDepth) * step(linearEyeDepth, p + a);
        // float condition2 = step(p + a, linearEyeDepth);
        //
        // linearEyeDepth = condition1 * (p - a) +
        // condition2 * ((linearEyeDepth - 2.0 * a) * invK + (p - a) * (1.0 - invK)) +
        // (1.0 - condition1 - condition2) * linearEyeDepth;

        float m = 5;
        float n = 9;

        float condition1 = step(m, linearEyeDepth) * step(linearEyeDepth, n);
        float condition2 = step(n, linearEyeDepth);
        linearEyeDepth = condition1 * m + condition2 * ((linearEyeDepth - (n - m)) * invK +
            m * (1.0 - invK)) + (1.0 - condition1 - condition2) * linearEyeDepth;
```

[图像](https://www.desmos.com/calculator/ojdhutm9gs)如下:
![desmos-graph (2)](/assets/image/desmos-graph_2.png)![image-20231013170825374](/assets/image/image-20231013170825374.png)

## 04 定制记录

### 注释标识: *//C10132023*

### 涉及文件:

- 着色器: 
  ```Packages/com.unity.render-pipelines.universal@14.0.8/Shaders/PostProcessing/BokehDepthOfField.shader```
- 面板: 
  ```Packages/com.unity.render-pipelines.universal@14.0.8/Runtime/Overrides/DepthOfField.cs```
  ```Packages/com.unity.render-pipelines.universal@14.0.8/Editor/Overrides/DepthOfFieldEditor.cs```
- Pass:
  ```Packages/com.unity.render-pipelines.universal@14.0.8/Runtime/Passes/PostProcessPass.cs```

### 彩色石头:

- DOF的算法有这样的注释```*// "A Lens and Aperture Camera Model for Synthetic Image Generation" [Potmesil81]*```
- [A lens and aperture camera model for synthetic image generation \| ACM SIGGRAPH Computer Graphics](https://dl.acm.org/doi/10.1145/965161.806818)
- [文件下载](https://dl.acm.org/doi/pdf/10.1145/965161.806818)
- 81年的算法
- [Unity Gizmos使用绘制-CSDN博客](https://blog.csdn.net/qq_39162826/article/details/124687714)

###### 参考网页: 

[Depth Of Field \| Universal RP \| 14.0.9 (unity3d.com)](https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@14.0/manual/post-processing-depth-of-field.html)

[图形学基础\|景深效果（Depth of Field/DOF）_后处理dof 原理-CSDN博客](https://blog.csdn.net/qjh5606/article/details/118960868)

[光学成像原理之景深(Depth of Field)-CSDN博客](https://blog.csdn.net/mingjinliu/article/details/103648118)

[Unity Shader PostProcessing - 7 - DepthOfField(DOF)景深-CSDN博客](https://blog.csdn.net/linjf520/article/details/104994304)

### 完整代码

shader代码

```c++
half FragCoCV2(Varyings input) : SV_Target
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    uint w;
    uint h;
    #if defined(SHADER_API_GLCORE)
        // GetDimensions will use textureQueryLevels in OpenGL and that's not
        // supported in OpenGL 4.1 or below. In that case we use _MainTex_TexelSize
        // which is fine as we don't support dynamic scaling in OpenGL.
        w = _MainTex_TexelSize.z;
        h = _MainTex_TexelSize.w;
    #elif defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
        uint x;
        _CameraDepthTexture.GetDimensions(w, h, x);
    #else
    _CameraDepthTexture.GetDimensions(w, h);
    #endif

    float2 uv = UnityStereoTransformScreenSpaceTex(input.uv);
    float depth = LOAD_TEXTURE2D_X(_CameraDepthTexture, float2(w, h) * uv).x;
    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams);

    //C10132023
    float m = _CoCParams.x;
    float n = _FarClearPlane;
    float invK = _FarBlurAttend;

    float condition1 = step(m, linearEyeDepth) * step(linearEyeDepth, n);
    float condition2 = step(n, linearEyeDepth);
    linearEyeDepth = condition1 * m + condition2 * ((linearEyeDepth - (n - m)) * invK +
        m * (1.0f - invK)) + (1.0f - condition1 - condition2) * linearEyeDepth;
    //C10132023

    half coc = (1.0h - FocusDist / linearEyeDepth) * MaxCoC;
    half nearCoC = clamp(coc, -1.0h, 0.0h);
    half farCoC = saturate(coc);

    return saturate((farCoC + nearCoC + 1.0h) * 0.5h);
}

...
Pass
{
    Name "Bokeh Depth Of Field CoC Ver 2"

    HLSLPROGRAM
    #pragma vertex Vert
    #pragma fragment FragCoCV2
    #pragma target 3.0
    ENDHLSL
}
```

Pass代码

```c++
void DoDepthOfField(Camera camera, CommandBuffer cmd, int source, int destination, Rect pixelRect)
{
    if (m_DepthOfField.mode.value == DepthOfFieldMode.Gaussian)
        DoGaussianDepthOfField(camera, cmd, source, destination, pixelRect);
    else if (m_DepthOfField.mode.value == DepthOfFieldMode.Bokeh)
        DoBokehDepthOfField(cmd, source, destination, pixelRect);
    //C10132023
    else if (m_DepthOfField.mode.value == DepthOfFieldMode.BokehVer2)
    {
        DoBokehDepthOfFieldV2(cmd, source, destination, pixelRect);
    }
    //C10132023
}

...
    
void DoBokehDepthOfFieldV2(CommandBuffer cmd, int source, int destination, Rect pixelRect)
{
    m_DepthOfField.nearClearPlane.value = URPUserData.NearClearPlane;
    m_DepthOfField.farClearPlane.value = URPUserData.FarClearPlane;
    m_DepthOfField.farBlurAttend.value = URPUserData.FarBlurAttend;
    m_DepthOfField.focalLength.value = URPUserData.FocalLength;
    m_DepthOfField.aperture.value = URPUserData.Aperture;

    var material = m_Materials.bokehDepthOfField;
    int wh = m_Descriptor.width / 2;
    int hh = m_Descriptor.height / 2;

    // "A Lens and Aperture Camera Model for Synthetic Image Generation" [Potmesil81]
    float F = m_DepthOfField.focalLength.value / 1000f;
    float A = m_DepthOfField.focalLength.value / m_DepthOfField.aperture.value;
    //C10132023
    // float P = m_DepthOfField.focusDistance.value;
    float P = m_DepthOfField.nearClearPlane.value / 100f;
    //C10132023
    float maxCoC = (A * F) / (P - F);
    float maxRadius = GetMaxBokehRadiusInPixels(m_Descriptor.height);
    float rcpAspect = 1f / (wh / (float)hh);
    //C10132023
    float N = m_DepthOfField.farClearPlane.value / 100f; //因为是厘米
    float farBlurAttend = m_DepthOfField.farBlurAttend.value;
    cmd.SetGlobalFloat(ShaderConstants._FarClearPlane, N);
    cmd.SetGlobalFloat(ShaderConstants._FarBlurAttend, farBlurAttend);
    //C10132023

    cmd.SetGlobalVector(ShaderConstants._CoCParams, new Vector4(P, maxCoC, maxRadius, rcpAspect));

    // Prepare the bokeh kernel constant buffer
    int hash = m_DepthOfField.GetHashCode();
    if (hash != m_BokehHash)
    {
        m_BokehHash = hash;
        PrepareBokehKernel();
    }

    cmd.SetGlobalVectorArray(ShaderConstants._BokehKernel, m_BokehKernel);

    // Temporary textures
    cmd.GetTemporaryRT(ShaderConstants._FullCoCTexture, GetStereoCompatibleDescriptor(m_Descriptor.width, m_Descriptor.height, GraphicsFormat.R8_UNorm), FilterMode.Bilinear);
    cmd.GetTemporaryRT(ShaderConstants._PingTexture, GetStereoCompatibleDescriptor(wh, hh, GraphicsFormat.R16G16B16A16_SFloat), FilterMode.Bilinear);
    cmd.GetTemporaryRT(ShaderConstants._PongTexture, GetStereoCompatibleDescriptor(wh, hh, GraphicsFormat.R16G16B16A16_SFloat), FilterMode.Bilinear);

    // Compute CoC
    cmd.Blit(source, ShaderConstants._FullCoCTexture, material, 5);
    cmd.SetGlobalTexture(ShaderConstants._FullCoCTexture, ShaderConstants._FullCoCTexture);

    // Downscale & prefilter color + coc
    cmd.Blit(source, ShaderConstants._PingTexture, material, 1);

    // Bokeh blur
    cmd.Blit(ShaderConstants._PingTexture, ShaderConstants._PongTexture, material, 2);

    // Post-filtering
    cmd.Blit(ShaderConstants._PongTexture, BlitDstDiscardContent(cmd, ShaderConstants._PingTexture), material, 3);

    // Composite
    cmd.SetGlobalTexture(ShaderConstants._DofTexture, ShaderConstants._PingTexture);
    cmd.Blit(source, BlitDstDiscardContent(cmd, destination), material, 4);

    // Cleanup
    cmd.ReleaseTemporaryRT(ShaderConstants._FullCoCTexture);
    cmd.ReleaseTemporaryRT(ShaderConstants._PingTexture);
    cmd.ReleaseTemporaryRT(ShaderConstants._PongTexture);
}
```

面板, Runtime

```c++
using System;

namespace UnityEngine.Rendering.Universal
{
    public enum DepthOfFieldMode
    {
        Off,
        Gaussian, // Non physical, fast, small radius, far blur only
        Bokeh,
        //C10132023
        BokehVer2
        //C10132023
    }

    [Serializable, VolumeComponentMenu("Post-processing/Depth Of Field")]
    public sealed class DepthOfField : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("Use \"Gaussian\" for a faster but non physical depth of field; \"Bokeh\" for a more realistic but slower depth of field.")]
        public DepthOfFieldModeParameter mode = new DepthOfFieldModeParameter(DepthOfFieldMode.Off);

        [Tooltip("The distance at which the blurring will start.")]
        public MinFloatParameter gaussianStart = new MinFloatParameter(10f, 0f);

        [Tooltip("The distance at which the blurring will reach its maximum radius.")]
        public MinFloatParameter gaussianEnd = new MinFloatParameter(30f, 0f);

        [Tooltip("The maximum radius of the gaussian blur. Values above 1 may show under-sampling artifacts.")]
        public ClampedFloatParameter gaussianMaxRadius = new ClampedFloatParameter(1f, 0.5f, 1.5f);

        [Tooltip("Use higher quality sampling to reduce flickering and improve the overall blur smoothness.")]
        public BoolParameter highQualitySampling = new BoolParameter(false);

        [Tooltip("The distance to the point of focus.")]
        public MinFloatParameter focusDistance = new MinFloatParameter(10f, 0.1f);

        [Tooltip("The ratio of aperture (known as f-stop or f-number). The smaller the value is, the shallower the depth of field is.")]
        public ClampedFloatParameter aperture = new ClampedFloatParameter(5.6f, 1f, 32f);

        [Tooltip("The distance between the lens and the film. The larger the value is, the shallower the depth of field is.")]
        public ClampedFloatParameter focalLength = new ClampedFloatParameter(50f, 1f, 300f);

        [Tooltip("The number of aperture blades.")]
        public ClampedIntParameter bladeCount = new ClampedIntParameter(5, 3, 9);

        [Tooltip("The curvature of aperture blades. The smaller the value is, the more visible aperture blades are. A value of 1 will make the bokeh perfectly circular.")]
        public ClampedFloatParameter bladeCurvature = new ClampedFloatParameter(1f, 0f, 1f);

        [Tooltip("The rotation of aperture blades in degrees.")]
        public ClampedFloatParameter bladeRotation = new ClampedFloatParameter(0f, -180f, 180f);

        //C10132023
        /// <summary>
        /// 近清晰面与摄像机距离(厘米)
        /// </summary>
        [Tooltip("近清晰面与摄像机距离(厘米)")]
        public MinIntParameter nearClearPlane = new MinIntParameter(value: 500, 1);

        /// <summary>
        /// 远清晰面与摄像机距离(厘米)
        /// </summary>
        [Tooltip("远清晰面与摄像机距离(厘米)")]
        public MinIntParameter farClearPlane = new MinIntParameter(value: 900, min: 2);

        /// <summary>
        /// 远端模糊度强度
        /// </summary>
        [Tooltip("远端模糊度强度")]
        public ClampedFloatParameter farBlurAttend = new ClampedFloatParameter(value: 1.0f, min: 0.1f, max: 1.0f);
        //C10132023
        
        public bool IsActive()
        {
            if (mode.value == DepthOfFieldMode.Off || SystemInfo.graphicsShaderLevel < 35)
                return false;

            return mode.value != DepthOfFieldMode.Gaussian || SystemInfo.supportedRenderTargetCount > 1;
        }

        public bool IsTileCompatible() => false;
    }

    [Serializable]
    public sealed class DepthOfFieldModeParameter : VolumeParameter<DepthOfFieldMode> { public DepthOfFieldModeParameter(DepthOfFieldMode value, bool overrideState = false) : base(value, overrideState) { } }
}

```

面板, Editor

```c++
using UnityEngine.Rendering.Universal;

namespace UnityEditor.Rendering.Universal
{
    [VolumeComponentEditor(typeof(DepthOfField))]
    sealed class DepthOfFieldEditor : VolumeComponentEditor
    {
        SerializedDataParameter m_Mode;

        SerializedDataParameter m_GaussianStart;
        SerializedDataParameter m_GaussianEnd;
        SerializedDataParameter m_GaussianMaxRadius;
        SerializedDataParameter m_HighQualitySampling;

        SerializedDataParameter m_FocusDistance;
        SerializedDataParameter m_FocalLength;
        SerializedDataParameter m_Aperture;
        SerializedDataParameter m_BladeCount;
        SerializedDataParameter m_BladeCurvature;
        SerializedDataParameter m_BladeRotation;
        
        //C10132023
        private SerializedDataParameter m_NearClearPlane;
        private SerializedDataParameter m_FarClearPlane;
        private SerializedDataParameter m_FarBlurAttend;
        //C10132023

        public override void OnEnable()
        {
            var o = new PropertyFetcher<DepthOfField>(serializedObject);

            m_Mode = Unpack(o.Find(x => x.mode));
            m_GaussianStart = Unpack(o.Find(x => x.gaussianStart));
            m_GaussianEnd = Unpack(o.Find(x => x.gaussianEnd));
            m_GaussianMaxRadius = Unpack(o.Find(x => x.gaussianMaxRadius));
            m_HighQualitySampling = Unpack(o.Find(x => x.highQualitySampling));

            m_FocusDistance = Unpack(o.Find(x => x.focusDistance));
            m_FocalLength = Unpack(o.Find(x => x.focalLength));
            m_Aperture = Unpack(o.Find(x => x.aperture));
            m_BladeCount = Unpack(o.Find(x => x.bladeCount));
            m_BladeCurvature = Unpack(o.Find(x => x.bladeCurvature));
            m_BladeRotation = Unpack(o.Find(x => x.bladeRotation));
            
            //C10132023
            m_NearClearPlane = Unpack(o.Find(x => x.nearClearPlane));
            m_FarClearPlane = Unpack(o.Find(x => x.farClearPlane));
            m_FarBlurAttend = Unpack(o.Find(x => x.farBlurAttend));
            //C10132023
        }

        public override void OnInspectorGUI()
        {
            if (UniversalRenderPipeline.asset?.postProcessingFeatureSet == PostProcessingFeatureSet.PostProcessingV2)
            {
                EditorGUILayout.HelpBox(UniversalRenderPipelineAssetEditor.Styles.postProcessingGlobalWarning, MessageType.Warning);
                return;
            }

            PropertyField(m_Mode);

            if (m_Mode.value.intValue == (int)DepthOfFieldMode.Gaussian)
            {
                PropertyField(m_GaussianStart, EditorGUIUtility.TrTextContent("Start"));
                PropertyField(m_GaussianEnd, EditorGUIUtility.TrTextContent("End"));
                PropertyField(m_GaussianMaxRadius, EditorGUIUtility.TrTextContent("Max Radius"));
                PropertyField(m_HighQualitySampling);
            }
            else if (m_Mode.value.intValue == (int)DepthOfFieldMode.Bokeh)
            {
                PropertyField(m_FocusDistance);
                PropertyField(m_FocalLength);
                PropertyField(m_Aperture);
                PropertyField(m_BladeCount);
                PropertyField(m_BladeCurvature);
                PropertyField(m_BladeRotation);
            }
            //C10132023
            else if (m_Mode.value.intValue == (int)DepthOfFieldMode.BokehVer2)
            {
                // PropertyField(m_FocusDistance);
                
                PropertyField(m_NearClearPlane);
                PropertyField(m_FarClearPlane);
                PropertyField(m_FarBlurAttend);
                PropertyField(m_FocalLength);
                PropertyField(m_Aperture);
                PropertyField(m_BladeCount);
                PropertyField(m_BladeCurvature);
                PropertyField(m_BladeRotation);
            }
            //C10132023
        }
    }
}
```

