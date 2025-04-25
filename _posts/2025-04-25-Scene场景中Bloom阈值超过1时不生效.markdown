---
layout: post
title: "Scene场景中Bloom阈值超过1时不生效"
categories: [URP, 后处理]
tags: URP 后处理 bloom 不生效 失效 HDR Buffer
math: true


---

# Scene场景中Bloom阈值超过1时不生效

## 00 现象

当后处理Bloom的Threshold值设定超过1时, Bloom效果不生效

## 01 处理方法

检查场景中相机的Tag, 确保有一个相机为MainCamera, 且该相机开启了HDR

## 02 原因

因为Unity的场景相机的Buffer是以Tag为MainCamera的相机为基准设置的. 如果MainCamera不存在或者存在但是没有开启HDR, 那么Scene相机的Buffer就是R8G8B8A8的非HDR格式, 自然无法记录超过1的值.

###### 参考网页

[HDR visible in GameView, but not SceneView - Questions & Answers - Unity Discussions](https://discussions.unity.com/t/hdr-visible-in-gameview-but-not-sceneview/232420)
