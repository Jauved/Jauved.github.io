---
layout: post
title: "Unity对应UI的Photoshop设置"
categories: [URP, UI]
tags: URP UI photoshop PS ps Unity
math: true


---

# Unity对应UI的Photoshop设置

## 00 前言

Photophop中, 设计师出的图, 与Unity中的颜色对应不上. 此处先不讨论Gamma空间和Linear空间的转换, 先处理Photoshop与Unity颜色不对应的情况.

## 01 处理方法

### PhotoShop设置

#### 新文件(在新建文件之前进行如下设置)

0. 编辑 -> 颜色设置 -> 设置, 选择"显示器颜色"

   - Unity并不支持色彩管理, 此时, 任何的PS色彩管理在Unity中并不会生效, 除非我们在Unity中写一套PS的色彩管理

     ![image-20240515120616266](/assets/image/image-20240515120616266.png)

1. 编辑 -> 颜色设置 -> 色彩管理方案

   - RGB - 关
   - CMYK - 关
   - 灰色 - 关

#### 旧文件(打开旧文件后, 进行如下设置后"导出")

0. 编辑 -> 指定配置文件 -> 不对此文档应用色彩管理
   <img src="/assets/image/image-20240515121244164.png" alt="image-20240515121244164" style="zoom:80%;" />

### 导出设置

0. 文件 -> 导出 -> 导出为... -> 色彩空间
   - 转换为sRGB - 勾选
   - 嵌入色彩管理方案 - 取消勾选
     <img src="/assets/image/image-20240515121646827.png" alt="image-20240515121646827" style="zoom:80%;" />

## 02 验证

### PhotoShop端

半透图片, 叠加方式是正常, 在底层叠加一个黑色100%的图层, 结果如下
![image-20240515122207494](/assets/image/image-20240515122207494.png)

### Unity端

半透图片, Sprite导入, 以UI/Image的方式添加到Canvas, 叠加方式Alpha Blend, 在其下建立纯黑色100%透明度的另一个UI/Image.结果如下:
![image-20240515122713145](/assets/image/image-20240515122713145.png)

###### 参考网页

[Why are there color differences between photoshop and Unity? - Questions & Answers - Unity Discussions](https://discussions.unity.com/t/why-are-there-color-differences-between-photoshop-and-unity/128891/5)
