---
layout: post
title: "定制ShaderGraph(一)---创建干净的底板"
categories: [URP, ShaderGraph]
tags: URP ShaderGraph 定制
math: true


---

# 定制ShaderGraph(一)---创建干净的底板

## 00 前置知识

### 功能入口

通过搜索`Assets/Create/Shader Graph/URP/`我们能够找到功能的关键入口类

- `CreateLitShaderGraph`

  路径: `Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/AssetCallbacks/CreateLitShaderGraph.cs`

  ```c#
  static class CreateLitShaderGraph
      {
          [MenuItem("Assets/Create/Shader Graph/URP/Lit Shader Graph", priority = CoreUtils.Priorities.assetsCreateShaderMenuPriority)]
          public static void CreateLitGraph()
          {
              var target = (UniversalTarget)Activator.CreateInstance(typeof(UniversalTarget));
              target.TrySetActiveSubTarget(typeof(UniversalLitSubTarget));
  
              var blockDescriptors = new[]
              {
                  BlockFields.VertexDescription.Position,
                  BlockFields.VertexDescription.Normal,
                  BlockFields.VertexDescription.Tangent,
                  BlockFields.SurfaceDescription.BaseColor,
                  BlockFields.SurfaceDescription.NormalTS,
                  BlockFields.SurfaceDescription.Metallic,
                  BlockFields.SurfaceDescription.Smoothness,
                  BlockFields.SurfaceDescription.Emission,
                  BlockFields.SurfaceDescription.Occlusion,
              };
  
              GraphUtil.CreateNewGraphWithOutputs(new[] { target }, blockDescriptors);
          }
      }
  ```

  可以看到, 实际创建的是一个`UniversalTarget`, 然后通过`TrySetActiveSubTarget()`方法去将`m_ActiveSubTarget`赋值为`subTarget`,

  然后输入`blockDescriptors`数组就可以构建出最初状态的`ShaderGraph`着色器. 

### 关键类

- `SubTarget`, `SubTarget<T>`

  路径: `Library/PackageCache/com.unity.shadergraph@12.1.10/Editor/Generation/SubTarget.cs`

- `UniversalTarget`

  路径: `Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/Targets/UniversalTarget.cs`

- `UniversalLitSubTarget`

  路径: `Library/PackageCache/com.unity.render-pipelines.universal@12.1.10/Editor/ShaderGraph/Targets/UniversalLitSubTarget.cs`

## 01 实施

- 拷贝关键类`CreateLitShaderGraph`, `UniversalLitSubTarget`

- 制作自己的`CreateVehiclePaintShaderGraph`类

  ```c#
  static class CreateVehiclePaintShaderGraph
      {
          [MenuItem("Assets/Create/Shader Graph/URP/Vehicle Paint Shader Graph", priority = CoreUtils.Priorities.assetsCreateShaderMenuPriority)]
          public static void CreateVehicleGraph()
          {
              // 基版使用UniversalTarget
              var target = (UniversalTarget)Activator.CreateInstance(typeof(UniversalTarget));
              // SubTarget里面放定制需求
              target.TrySetActiveSubTarget(typeof(UniversalVehiclePaintSubTarget));
              
              // 定义block块
              var blockDescriptors = new[]
              {
                  BlockFields.VertexDescription.Position,
                  BlockFields.VertexDescription.Normal,
                  BlockFields.VertexDescription.Tangent,
                  BlockFields.SurfaceDescription.BaseColor,
                  BlockFields.SurfaceDescription.NormalTS,
                  BlockFields.SurfaceDescription.Metallic,
                  BlockFields.SurfaceDescription.Smoothness,
                  BlockFields.SurfaceDescription.Emission,
                  BlockFields.SurfaceDescription.Occlusion,
              };
  
              // 创建对象
              GraphUtil.CreateNewGraphWithOutputs(new Target[] { target }, blockDescriptors);
          }
  
      }
  ```

  

- 制作自己的`UniversalVehiclePaintSubTarget`类, 替换掉`guid`, 替换掉名称即可

  ```c#
  static readonly GUID kSourceCodeGuid = new GUID("4443eec7cc6a454c86378894f2e8a868"); // UniversalVehiclePaintSubTarget.cs
  ...
  public UniversalVehiclePaintSubTarget()
  {
      // ShaderGraph 的 Material 栏中显示的名字
      displayName = "VehiclePaint";
  }
  ```

  然后我们就得到了一个可以修改的模板, 并可以在`ShaderGraph`中选择, 并且在右键菜单进行创建.

  <img src="/assets/image/image-20250726133320963.png" alt="image-20250726133320963" style="zoom:50%;" />

  <img src="/assets/image/image-20250726133722824.png" alt="image-20250726133722824" style="zoom:50%;" />



###### 参考网页
