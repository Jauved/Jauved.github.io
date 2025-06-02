---
layout: post
title: "[LookDev开发] 加入NewtonsoftJson序列化"
categories: [Unity, 编辑器]
tags: Unity lookdev 编辑器 自定义
math: true


---

# [LookDev开发] 加入NewtonsoftJson序列化

## 原理

`ScriptableObject`对Unity强依赖, 而某些数据的处理并不想与Unity绑定. 所以需要引入Newtonsoft Json的包.

## 代码

在`manifest.json`中加入如下代码即可, 然后正常按照`Newtonsoft Json`的调用方法使用. 

```json
"com.unity.nuget.newtonsoft-json": "3.2.1"
```

`Newtonsoft Json`版本是`Newtonsoft.Json version 13.0.2`



###### 参考网页

[Changelog \| Newtonsoft Json \| 3.1.0](https://docs.unity3d.com/Packages/com.unity.nuget.newtonsoft-json@3.1/changelog/CHANGELOG.html)

[【开发踩坑】Unity 导入 Newtonsoft Json Package 的版本问题 - 知乎](https://zhuanlan.zhihu.com/p/622624661)
