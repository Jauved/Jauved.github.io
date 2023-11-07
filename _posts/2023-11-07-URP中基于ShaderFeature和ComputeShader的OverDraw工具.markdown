---
layout: post
title: "URP中基于ShaderFeature和ComputeShader的OverDraw工具"
categories: [URP, 工具]
tags: URP 工具 OverDraw 优化 Inspector只读字段 computeshader
math: true
---

# URP中基于ShaderFeature和ComputeShader的OverDraw工具

## 00 前言

## 01 处理方法

###### 参考网页

[Overdraw概念、指标和分析工具 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/323421079)

[[URP\]RenderFeature+ComputeShader计算OverDraw - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/577015774)

[ina-amagami/OverdrawForURP: Scene Overdraw in Universal Render Pipeline. (github.com)](https://github.com/ina-amagami/OverdrawForURP)

[在运行时替换着色器 - Unity 手册](https://docs.unity.cn/cn/2023.1/Manual/SL-ShaderReplacement.html)

[How to make a readonly property in inspector? - Questions & Answers - Unity Discussions](https://discussions.unity.com/t/how-to-make-a-readonly-property-in-inspector/75448/5)

[初识Compute Shader - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/438515815)

[Unity Compute Shader入门初探 - 简书 (jianshu.com)](https://www.jianshu.com/p/ec9ba6c3a155)

[Compute Shader中的Parallel Reduction和Parallel Scan - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/113532940)

[How can we access thread group and global variables from threads in compute shader? - Unity Forum](https://forum.unity.com/threads/how-can-we-access-thread-group-and-global-variables-from-threads-in-compute-shader.468306/)

[Nordeus/Unite2017 (github.com)](https://github.com/Nordeus/Unite2017/tree/master)

[ken48/UnityOverdrawMonitor: Overdraw profiler for Unity, shows fill rate (github.com)](https://github.com/ken48/UnityOverdrawMonitor)
