---
layout: post
title: "[烘焙]反射探针没有体现出RendererFeature的效果"
categories: [URP, 后处理]
tags: URP 后处理 反射探针
math: true


---

# [烘焙]反射探针没有体现出RendererFeature的效果

## 00 前言

反射探针烘焙的结果中没有`rendererfeature`的效果.

## 01 处理方法

用于后处理的着色器如果想要在反射探针中有效果, 那么需要按照如下方式设置`ZTest`, `ZWrite` 与 `Cull`. 具体可以参考Unity官方的后处理着色器.

```c
ZTest Always ZWrite Off Cull Off
```



###### 参考网页
