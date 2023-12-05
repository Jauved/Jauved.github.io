---
layout: post
title: "Canvas对象渲染到RenderTexture在Windows下打包不显示的问题"
categories: [URP, 疑难杂症]
tags: URP 坑 疑难杂症
math: true
---

# Canvas对象渲染到RenderTexture在Windows下打包不显示的问题

## 00 前言

引发Bug的具体情况是:

- 用一个Camera赋值到Canvas
- 将Camera的Display选择为Display1之外的其他显示
- 然后给这个相机一个RenderTexture对象(此时Display的选项消失)

表现为: 此时Canvas下的所有Canvas相关的对象, 比如Image, 都无法渲染到RenderTexture上, 其他非Canvas相关的对象不受影响.

## 01 处理方法

- 将Camera的Display修改为默认值即可

###### 参考网页
