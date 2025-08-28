---
layout: post
title: "Unity编辑器连接Android设备100%成功"
categories: [Unity, 性能分析]
tags: Unity 性能分析 Adb
math: true


---

# Unity编辑器连接Android设备100%成功

## 00 前言

通常连接编辑器的做法是, 在打包的时候, 勾选`Autoconnect Profiler`复选框, 然后保持`USB`连接. 祈祷能够连上.

## 01 处理方法

其实在古早的Unity文档(4.62)中就很清晰的写明了连接方法. 这里用的原文, 但实际上还是有坑, 下面具体步骤的时候会说明

> For ADB profiling, follow these steps:
> 
> - Attach your device to your Mac/PC via cable and make sure ADB recognizes the device (i.e. it shows in *adb devices* list).
> - Check the “Development Build” checkbox in Unity’s build settings dialog, and hit “Build & Run”.
> - When the app launches on the device, open the profiler window in Unity Editor (Window-Profiler)
> - Select the *AndroidProfiler(ADB@127.0.0.1:54999)* from the Profiler Window Active Profiler drop down menu. **Note:** The Unity editor will automatically create an adb tunnel for your application when you press “Build & Run”. If you want to profile another application or you restart the adb server you have to setup this tunnel manually. To do this, open a Terminal window / CMD prompt and enter `adb forward tcp:54999 localabstract:Unityinsert bundle identifier here`
> 
>**Note:** The entry in the drop down menu is only visible when the selected target is Android.
>
>If you are using a firewall, you need to make sure that ports 54998 to 55511 are open in the firewall’s outbound rules - these are the ports used by Unity for remote profiling.

实际操作下来, 分为以下步骤

- 确保`ADB`配置正确

- 编辑器启动

- 应用正常运行

- 输入以下`ADB`命令

  ```
  adb forward tcp:55000 localabstract:Unity-<Package name>
  ```

  坑点分析

  - 首先, 文档中的`insert bundle identifier here`, 你根本就不知道这里应该填什么
    - 如果用Unity直接Build, 那么这里的名字应该是类似`Unity-com.unity3d.mygame`这样的名称
    - 如果你用`Gradle`进行打包, 那么在`build.gradle`中搜索`applicationId`, 或者`package com.`, 就能找到真正的输出名称, 将这个名称写成`Unity-<true package name>`的形式即可.
  - 然后, 端口事实上55000往上是可以成功的, 没有验证是否是从54999-55511

- 接下来, 在编辑器中, 选择`console`的`Editor`下拉, 在`Direct Connection`栏下点击`<Enter IP>`, 输入`127.0.0.1:55000`, 即可连接

  坑点分析

  - 首先, 新版的Unity, 比如2021, 根本就没有类似`ADB@127.0.0.1:54999`这样的下拉选项
  - 其次, 这里的端口号, 需要和你在`ADB`命令中声明的一致

###### 参考网页

[Unity - Manual: Profiler (Pro only)](https://docs.unity3d.com/462/Documentation/Manual/Profiler.html)

[Android设备连接Unity Profiler性能分析器-腾讯游戏学堂](https://gwb.tencent.com/community/detail/119148)
