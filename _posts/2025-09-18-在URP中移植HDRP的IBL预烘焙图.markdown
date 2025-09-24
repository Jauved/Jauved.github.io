---
layout: post
title: "在URP中移植HDRP的IBL预烘焙图"
categories: [URP, IBL]
tags: URP IBL HDRP LUT
math: true


---

# 在URP中移植HDRP的IBL预烘焙图

## 00 前置知识

URP默认的环境光FDG是用函数拟合的

```c#
// Computes the specular term for EnvironmentBRDF
half3 EnvironmentBRDFSpecular(BRDFData brdfData, half fresnelTerm)
{
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    return half3(surfaceReduction * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm));
}
```



而HDRP是使用预积分的LUT图来完成的, 会更准确, 且不会**在边缘产生过亮的高光**, 这个非常重要.

HDRP中关键的几个文件是

- `PreIntegratedFGD.cs`: 记录了LUT图的声明, 其中比较重要的是

  ```c#
  
  public enum FGDTexture
  {
      Resolution = 64	// LUT分辨率为 64
  }
  
  ...
  
  m_PreIntegratedFGD[(int)index] = new RenderTexture(res, res, 0, GraphicsFormat.A2B10G10R10_UNormPack32)
  {
      hideFlags = HideFlags.HideAndDontSave,
      filterMode = FilterMode.Bilinear,	// LUT的FilterMode为 Bilinear
      wrapMode = TextureWrapMode.Clamp,	// LUT的WrapMode为 Clamp
      name = CoreUtils.GetRenderTargetAutoName(res, res, 1, GraphicsFormat.A2B10G10R10_UNormPack32, $"preIntegrated{index}")				// 图片格式为 GraphicsFormat.A2B10G10R10_UNormPack32
  };
  ```

- `PreIntegratedFGD.hlsl`: 记录了重要的解码函数

- LUT渲染用着色器

  - `preIntegratedFGD_GGXDisneyDiffuse.shader`
  - `preIntegratedFGD_CharlieFabricLambert.shader`
  - `PreIntegratedFGD_Marschner.shader`

- `ImageBasedLighting.hlsl`: 记录了生成函数
  - `IntegrateGGXAndDisneyDiffuseFGD`

## 01 实施

离线生成, 不考虑实时生成.

- 制作生成工具

  ```c#
  using UnityEngine;
  using UnityEditor;
  using UnityEngine.Experimental.Rendering;
  using System.IO;
  
  public class GeneratePreIntegratedFGDEditor : EditorWindow
  {
      private const int Resolution = 64;
      private const GraphicsFormat RtFormat = GraphicsFormat.A2B10G10R10_UNormPack32;
      private const TextureFormat SaveFormat = TextureFormat.RGBAFloat;
      private const string ShaderPath = "Hidden/URP/preIntegratedFGD_GGXDisneyDiffuse";
  
      private string assetPath = "Assets/Temp/PreIntegratedFGD_GGXDisneyDiffuse.asset";
  
      [MenuItem("Tools/Generate PreIntegratedFGD LUT")]
      public static void ShowWindow()
      {
          var window = GetWindow<GeneratePreIntegratedFGDEditor>(true, "PreIntegratedFGD Generator");
          window.minSize = new Vector2(400, 80);
          window.Show();
      }
  
      private void OnGUI()
      {
          GUILayout.Label("离线生成 PreIntegratedFGD LUT", EditorStyles.boldLabel);
          assetPath = EditorGUILayout.TextField("Asset Path", assetPath);
  
          if (GUILayout.Button("Generate LUT"))
          {
              GenerateLUT();
          }
      }
  
      private void GenerateLUT()
      {
          // 确保 Shader 路径正确
          Shader lutShader = Shader.Find(ShaderPath);
          if (lutShader == null)
          {
              Debug.LogError($"找不到 Shader '{ShaderPath}'");
              return;
          }
  
          Material mat = new Material(lutShader);
  
          // 创建 RenderTexture
          var rtDesc = new RenderTextureDescriptor(Resolution, Resolution)
          {
              graphicsFormat = RtFormat,
              depthBufferBits = 0,
              sRGB = false,
              msaaSamples = 1
          };
          RenderTexture rt = new RenderTexture(rtDesc)
          {
              filterMode = FilterMode.Bilinear,
              wrapMode = TextureWrapMode.Clamp
          };
  
          // 渲染到 RT
          Graphics.Blit(null, rt, mat);
          // 释放材质
          DestroyImmediate(mat);
  
          // 读取 RT 到 Texture2D
          RenderTexture prev = RenderTexture.active;
          RenderTexture.active = rt;
  
          Texture2D tex = new Texture2D(Resolution, Resolution, SaveFormat, false)
          {
              name = Path.GetFileNameWithoutExtension(assetPath)
          };
          tex.wrapMode = TextureWrapMode.Clamp;
          tex.filterMode = FilterMode.Bilinear;
          tex.ReadPixels(new Rect(0, 0, Resolution, Resolution), 0, 0);
          tex.Apply();
  
          RenderTexture.active = prev;
  
          // 保存成资源
          AssetDatabase.StartAssetEditing();
          if (File.Exists(assetPath))
          {
              AssetDatabase.DeleteAsset(assetPath);
          }
          AssetDatabase.CreateAsset(tex, assetPath);
          AssetDatabase.StopAssetEditing();
          AssetDatabase.SaveAssets();
          // 不刷新的话, 会导致看似选中, 实际上没有选中
          AssetDatabase.Refresh();
  
          Debug.Log($"已生成 PreIntegratedFGD LUT 并保存到: {assetPath}");
  
          //释放 RT
          RenderTexture.active = null;    // ← 先清空 active, 不清空则会报错
          rt.Release();
          DestroyImmediate(rt);
      }
  }
  
  ```



- 迁移着色器

  注意:

  - 管线修改`"RenderPipeline" = "UniversalPipeline"`

  - 注释掉`#pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch`

  - HDRP用的全屏三角, 这里直接使用屏幕顶点和UV就好, 对应的转换

    ```c#
    struct Attributes
    {
        float4 position : POSITION; // 裸顶点
        float2 texCoord : TEXCOORD0; // 对应 UV
    };
    ```

    对应的顶点转换代码

    ```c#
    // 直接用 Blit 自带的顶点／UV
    output.positionCS = TransformWorldToHClip(input.position.xyz);
    output.texCoord = input.texCoord;
    ```

  - 其他着色器类似

  ```c#
  Shader "Hidden/URP/preIntegratedFGD_GGXDisneyDiffuse"
  {
      SubShader
      {
          Tags
          {
              "RenderPipeline" = "UniversalPipeline"
          }
          Pass
          {
              ZTest Always Cull Off ZWrite Off
  
              HLSLPROGRAM
              #pragma editor_sync_compilation
  
              #pragma vertex Vert
              #pragma fragment Frag
              #pragma target 4.5
              // #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch
              #define PREFER_HALF 0
              #define FGDTEXTURE_RESOLUTION (64)
              #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
              #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
              #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
              // #define SHADER_TARGET 20
              #include "ImageBasedLighting.hlsl"
  
              // struct Attributes
              // {
              //     uint vertexID : SV_VertexID;
              // };
  
              struct Attributes
              {
                  float4 position : POSITION; // 裸顶点
                  float2 texCoord : TEXCOORD0; // 对应 UV
              };
  
              struct Varyings
              {
                  float4 positionCS : SV_POSITION;
                  float2 texCoord : TEXCOORD0;
              };
  
              Varyings Vert(Attributes input)
              {
                  Varyings output;
  
                  // output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                  // output.texCoord = GetFullScreenTriangleTexCoord(input.vertexID);
                  
                  // 直接用 Blit 自带的顶点／UV
                  output.positionCS = TransformWorldToHClip(input.position.xyz);
                  output.texCoord = input.texCoord;
  
                  return output;
              }
  
              float4 Frag(Varyings input) : SV_Target
              {
                  // We want the LUT to contain the entire [0, 1] range, without losing half a texel at each side.
                  float2 coordLUT = RemapHalfTexelCoordTo01(input.texCoord, FGDTEXTURE_RESOLUTION);
  
                  // The FGD texture is parametrized as follows:
                  // X = sqrt(dot(N, V))
                  // Y = perceptualRoughness
                  // These coordinate sampling must match the decoding in GetPreIntegratedDFG in Lit.hlsl,
                  // i.e here we use perceptualRoughness, must be the same in shader
                  // Note: with this angular parametrization, the LUT is almost perfectly linear,
                  // except for the grazing angle when (NdotV -> 0).
                  float NdotV = coordLUT.x * coordLUT.x;
                  float perceptualRoughness = coordLUT.y;
  
                  // Pre integrate GGX with smithJoint visibility as well as DisneyDiffuse
                  float4 preFGD = IntegrateGGXAndDisneyDiffuseFGD(
                      NdotV, PerceptualRoughnessToRoughness(perceptualRoughness));
  
                  // 可视化 coord.x（N·V 方向渐变）和 coord.y（roughness 方向渐变）
                  // return float4(input.texCoord.x, input.texCoord.y, 0, 1);
                  // return float4(coordLUT.x, coordLUT.y, 0, 1);
                  return float4(preFGD.xyz, 1.0);
              }
              ENDHLSL
          }
      }
      Fallback Off
  }
  ```

  

## 02 坑

- `ImageBasedLighting.hlsl`中的`IntegrateGGXAndDisneyDiffuseFGD`函数中调用了`Hammersley2d`函数

  ```c#
  real VanDerCorputBase2(uint i)
  {
      return ReverseBits32(i) * rcp(4294967296.0); // 2^-32
  }
  
  real2 Hammersley2dSeq(uint i, uint sequenceLength)
  {
      return real2(real(i) / real(sequenceLength), VanDerCorputBase2(i));
  }
  
  // Loads elements from one of the precomputed tables for sample counts of 16, 32, 64, 256.
  // Computes sample positions at runtime otherwise.
  real2 Hammersley2d(uint i, uint sampleCount)
  {
      switch (sampleCount)
      {
      #ifdef HAMMERSLEY_USE_CB
          case 16:  return hammersley2dSeq16[i].xy;
          case 32:  return hammersley2dSeq32[i].xy;
          case 64:  return hammersley2dSeq64[i].xy;
          case 256: return hammersley2dSeq256[i].xy;
      #else
          case 16:  return k_Hammersley2dSeq16[i];
          case 32:  return k_Hammersley2dSeq32[i];
          case 64:  return k_Hammersley2dSeq64[i];
          case 256: return k_Hammersley2dSeq256[i];
      #endif
          default:  return Hammersley2dSeq(i, sampleCount); // 因为默认采样数为4096, 所以直接走的这个分支
      }
  }
  ```

  这个函数在`Hammersley.hlsl`文件中

  ```c#
  // Ref: http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html
  uint ReverseBits32(uint bits)
  {
  #if (SHADER_TARGET >= 45)		// 分支A
      return reversebits(bits);
  #else							// 分支B
      bits = (bits << 16) | (bits >> 16);
      bits = ((bits & 0x00ff00ff) << 8) | ((bits & 0xff00ff00) >> 8);
      bits = ((bits & 0x0f0f0f0f) << 4) | ((bits & 0xf0f0f0f0) >> 4);
      bits = ((bits & 0x33333333) << 2) | ((bits & 0xcccccccc) >> 2);
      bits = ((bits & 0x55555555) << 1) | ((bits & 0xaaaaaaaa) >> 1);
      return bits;
  #endif
  }
  ```

  

  如果走分支A, 原本`reversebits`会走`uint  bitfieldReverse(uint  x)`这个, 因为`bits`是`uint`的理论上应该走这个重载. 但`Compile and show code`会发现, 实际走的是`int  bitfieldReverse(int  x)`这个重载, 因为编出来的代码是`bitfieldReverse((int)  x)`, 走了一次转义, 然后会报错`error C7011: implicit cast from "int" to "uint"`, 导致无法渲染.

  如果走分支B(在`#include ImageBasedLighting.hlsl`前强制`#define SHADER_TARGET 30`), 则会发现, 编出来的代码有类似这样的代码`u_xlatu27 =  uint(int(bitfieldInsert(int(u_xlatu19.x), int(u_xlatu_loop_1), 16 & 0x1F, 16)));`, 而这里实际走的也是`int  bitfieldInsert(int  a, int b, int c, int d)`的重载, 而理论上应该走`uint  bitfieldInsert(uint  a, uint b, int c, int d)`. 这个虽然不会报错, 但是会渲染错误的图片.

  - 原因猜测

    在编辑器的Android平台环境下, 

  - 解决方案

    因为位移操作的本质是提升渲染效率, HDRP是实时每帧生成这张图, 所以会在意. 而这次的方案是离线渲染, 预生成无需考虑效率, 那么抛弃位移操作, 直接硬算即可, 其他的不用改动.

    ```c#
    // ——— 纯浮点版 Hammersley，不用任何位运算 ———
    float RadicalInverse2_PURE(int bits)
    {
        float invBase = 0.5;
        float result = 0.0;
        float fBits = float(bits);
    
        UNITY_UNROLL
        while (fBits > 0.0)
        {
            // 等价于 bits % 2
            float b = floor(frac(fBits * 0.5) * 2.0);
            result += b * invBase;
    
            // 相当于 bits >>= 1
            fBits *= 0.5;
            fBits = floor(fBits);
    
            invBase *= 0.5;
        }
        return result;
    }
    
    float2 Hammersley2d_PURE(int i, int N)
    {
        float phi = RadicalInverse2_PURE(i);
        float theta = float(i) / float(N);
        return float2(phi, theta);
    }
    
    // ————————————————————————————————————————————————
    ```

    最后成图如下, 左图是离线运算结果, 右图是HDRP生成的图

    ![image-20250918221645977](/assets/image/image-20250918221645977.png)![image-20250918221713323](/assets/image/image-20250918221713323.png)



## 参考网页

- [【unity】 HDRP的IBL和URP的IBL对比 - 知乎](https://zhuanlan.zhihu.com/p/1926017942560179928)
- [bitfieldReverse](https://developer.download.nvidia.cn/cg/bitfieldReverse.html)
- [bitfieldInsert](https://developer.download.nvidia.cn/cg/bitfieldInsert.html)
- [基于图像的光照IBL](https://huailiang.github.io/blog/2019/ibl/)
