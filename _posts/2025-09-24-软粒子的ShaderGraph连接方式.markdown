---
layout: post
title: "软粒子的ShaderGraph连接方式"
categories: [URP, Shader]
tags: URP Shader ShaderGraph 软粒子 深度
math: true


---

# 软粒子的ShaderGraph连接方式

## 00 前置知识

Unity在开启了摄像机的DepthTexture之后, 可以支持软粒子.

## 01 实施

整体构造是这样, 其中Soft Factor使用`lerp(x, x*x, step(1,x))`, 当x小于1的时候, 走$y=x$曲线, 当x大于1的时候走$y=x^2$. Soft On用来做切换总开关.

![image-20250924131915776](/assets/image/image-20250924131915776.png)

###### 参考网页

[Unity Shader Graph - 软粒子 Fade 值，Screen Position.w 分量是啥_shadergraph软粒子-CSDN博客](https://blog.csdn.net/linjf520/article/details/124450971)
