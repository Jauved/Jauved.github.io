---
layout: post
title: "ShaderModel"
categories: [Unity, 豆知识]
tags: PBR着色器豆知识
---


# ShaderModel

## 相关页面

- [SystemInfo-graphicsShaderLevel - Unity 脚本 API](https://docs.unity.cn/cn/current/ScriptReference/SystemInfo-graphicsShaderLevel.html)

  图形设备着色器功能级别（只读）。

  此为近似的图形设备“着色器功能”级别，以 DirectX 着色器模型术语表述。 可能的值为：

  **50** Shader Model 5.0 (DX11.0)
  **46** OpenGL 4.1 功能（Shader Model 4.0 + 曲面细分）
  **45** Metal / OpenGL ES 3.1 功能（Shader Model 3.5 + 计算着色器）
  **40** Shader Model 4.0 (DX10.0)
  **35** OpenGL ES 3.0 功能（Shader Model 3.0 + 整数、纹理数组、实例化）
  **30** Shader Model 3.0
  **25** Shader Model 2.5（DX11 功能级别 9.3 功能集）
  **20** Shader Model 2.0