---
layout: post
title: "FindReference插件导致的Unity编辑器一直高频率刷新"
categories: [Unity, 插件]
tags: Unity 插件 FR FindReference 卡顿 编辑器忙
math: true


---

# FindReference插件导致的Unity编辑器一直高频率刷新

## 00 前置知识

安装`FindReference2`插件之后, 在某些情况下, 会触发Unity编辑器模式下, 不停高频率刷新的问题. 

## 01 解决

点开FR2的窗口, 点击窗口右上角的三个点, 呼出菜单, 临时取消勾选`Enable`和`Auto Refresh`, 然后手动`Refresh`, 之后再勾选`Enable`, 即可解决.

![image-20260806154455881](C:\Users\ASUS\AppData\Roaming\Typora\typora-user-images\image-20260806154455881.png)

###### 参考网页
