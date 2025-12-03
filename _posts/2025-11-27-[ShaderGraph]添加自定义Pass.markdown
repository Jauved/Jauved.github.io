---
layout: post
title: "[ShaderGraph]添加自定义Pass"
categories: [URP, ShaderGraph]
tags: URP ShaderGraph 定制 自定义Pass Pass
math: true


---

# [ShaderGraph]添加自定义Pass

## 00 处理

### 00a 自定义Pass

仿照开关内置Pass的方式, 添加一个自定义Pass, 同时添加开关.

添加Pass可以仿照`ShaderGraph`自身Pass的写法如下:

```c#
public static PassDescriptor CrossSection(UniversalTarget target)
{
    var result = new PassDescriptor()
    {
        // Definition
        displayName = "CrossSection",
        // 这个地方是用来做比较进行一些宏定义的, 文件在
        // Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/Includes/ShaderPass.hlsl
        // 如果你写自己的, 但是又没有在文件中, 默认第一个是SHADERPASS_FORWARD, 会导致光照相关的参数没有, 会报错
        referenceName = "SHADERPASS_UNLIT",
        lightMode = "CrossSection",
        useInPreview = true,

        // Template
        passTemplatePath = UniversalTarget.kUberTemplatePath,
        sharedTemplateDirectories = UniversalTarget.kSharedTemplateDirectories,

        // Port Mask
        validVertexBlocks = CoreBlockMasks.Vertex,
        validPixelBlocks = ExternalBlockMasks.FragmentCrossSection,

        // Fields
        structs = CoreStructCollections.Default,
        fieldDependencies = CoreFieldDependencies.Default,

        // Conditional State
        renderStates = ExternalRenderState.CrossSection(target),
        pragmas = CorePragmas.Instanced,
        defines = new DefineCollection(),
        keywords = new KeywordCollection(),
        includes = ExternalLitIncludes.CrossSection,

        // Custom Interpolator Support
        customInterpolators = CoreCustomInterpDescriptors.Common
    };

    ExtendedPasses.AddAlphaClipControlToPassMultiCompile(ref result, target);

    return result;
}
```

需要注意的是

- `referenceName = "SHADERPASS_UNLIT",` `referenceName`是用来定义一些宏的开关的, 此处可以选择的值在`Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/Includes/ShaderPass.hlsl`文件中, 如下:

  ```shell
  #ifndef UNIVERSAL_SHADERPASS_INCLUDED
  #define UNIVERSAL_SHADERPASS_INCLUDED
  
  #define SHADERPASS_FORWARD (0)
  #define SHADERPASS_GBUFFER (1)
  #define SHADERPASS_DEPTHONLY (2)
  #define SHADERPASS_SHADOWCASTER (3)
  #define SHADERPASS_META (4)
  #define SHADERPASS_2D (5)
  #define SHADERPASS_UNLIT (6)
  #define SHADERPASS_SPRITELIT (7)
  #define SHADERPASS_SPRITENORMAL (8)
  #define SHADERPASS_SPRITEFORWARD (9)
  #define SHADERPASS_SPRITEUNLIT (10)
  #define SHADERPASS_DEPTHNORMALSONLY (11)
  #define SHADERPASS_DBUFFER_PROJECTOR (12)
  #define SHADERPASS_DBUFFER_MESH (13)
  #define SHADERPASS_FORWARD_EMISSIVE_PROJECTOR (14)
  #define SHADERPASS_FORWARD_EMISSIVE_MESH (15)
  #define SHADERPASS_FORWARD_PREVIEW (16)
  #define SHADERPASS_DECAL_SCREEN_SPACE_PROJECTOR (17)
  #define SHADERPASS_DECAL_SCREEN_SPACE_MESH (18)
  #define SHADERPASS_DECAL_GBUFFER_PROJECTOR (19)
  #define SHADERPASS_DECAL_GBUFFER_MESH (20)
  #define SHADERPASS_DEPTHNORMALS (21)
  #endif
  ```

  如果要根据你自己的定义去对`Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/Includes/Varyings.hlsl`做一些操作, 那么才需要添加, 否则使用现有的即可. 具体这些关键字的开关, 可以在`Varyings.hlsl`文件中去确认.

- `lightMode = "CrossSection",`这个是用来在做`RendererFeature`的时候用来指定`LightMode`的, 需要保持一致.

- `validPixelBlocks = ExternalBlockMasks.FragmentCrossSection,`这里只需要传递你要用到的中间变量即可. 比如我只需要用到的是:

  ```c#
  public static readonly BlockFieldDescriptor[] FragmentCrossSection = new BlockFieldDescriptor[]
  {
      ExtensionBlockFields.SurfaceDescription.CrossSectionColor,
      BlockFields.SurfaceDescription.Alpha,
      BlockFields.SurfaceDescription.AlphaClipThreshold,
  };
  ```

- `renderStates = ExternalRenderState.CrossSection(target),`, 这里是定义`ZTest, ZWrite, Cull`之类的, 按照需求定义即可

  ```
  public static RenderStateCollection CrossSection(UniversalTarget target)
  {
      var result = new RenderStateCollection
      {
          { RenderState.ZTest(ZTest.LEqual) },
          { RenderState.ZWrite(ZWrite.On) },
          { RenderState.Cull(Cull.Front) },
      };
  
      return result;
  }
  ```

- `includes = ExternalLitIncludes.CrossSection,`这一行用来引用外部的`hlsl`, 具体定义如下, 这样就可以自己去写对应的`hlsl`文件.

  ```c#
  private const string kCrossSectionPass =
             "Packages/xxxx/ShaderLibrary/CrossSectionPass.hlsl";
  public static readonly IncludeCollection CrossSection = new IncludeCollection
  {
     // Pre-graph
     { CoreIncludes.CorePregraph },
     { CoreIncludes.ShaderGraphPregraph },
  
     // Post-graph
     { CoreIncludes.CorePostgraph },
     { kCrossSectionPass, IncludeLocation.Postgraph },
  };
  ```
  自定义的`hlsl`文件可以仿照`Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/Includes`中的`hlsl`文件, 例子如下: 

  ```c
  #ifndef SG_CROSS_SECTION_PASS_INCLUDED
  #define SG_CROSS_SECTION_PASS_INCLUDED
  
  PackedVaryings vert(Attributes input)
  {
      Varyings output = (Varyings)0;
      output = BuildVaryings(input);
      PackedVaryings packedOutput = (PackedVaryings)0;
      packedOutput = PackVaryings(output);
      return packedOutput;
  }
  
  half4 frag(PackedVaryings packedInput) : SV_TARGET
  {
      Varyings unpacked = UnpackVaryings(packedInput);
      UNITY_SETUP_INSTANCE_ID(unpacked);
      UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(unpacked);
      SurfaceDescription surfaceDescription = BuildSurfaceDescription(unpacked);
  
      #if _ALPHATEST_ON
      half alpha = surfaceDescription.Alpha;
      clip(alpha - surfaceDescription.AlphaClipThreshold);
      #else
      half alpha = 1.h;
      #endif
  
      half4 color = half4(surfaceDescription.CrossSectionColor,alpha);
  
      return 0;
  }
  
  #endif
  ```

  

### 00b 在SubShader中调用Pass

```c#
public static SubShaderDescriptor VehicleLitGLESSubShader(UniversalTarget target, WorkflowMode workflowMode,
            string renderType, string renderQueue, bool complexLit,
            SubShaderOptions options)
{
    ...

    if (options.crossSectionPassOn)
        result.passes.Add(SubShaderUtils.PassVariant(ExtendedPasses.CrossSection(target),
            ExtendedPragmas.ExtendedDefault));

    return result;
}
```





## 参考网页
