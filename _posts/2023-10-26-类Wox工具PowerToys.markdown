---
layout: post
title: "类Wox工具PowerToys"
categories: [工具, PowerToys]
tags: 工具 Wox PowerToys
math: true
---

# 类Wox工具PowerToys

## 00 前言

之前一直使用[Wox](http://www.wox.one/)作为一个便捷工具, 并配合[Everything](https://www.voidtools.com/zh-cn/)进行文件搜索. 但可惜的是, Wox在2020年3月停止更新了, 随着系统的进化, 一直担心Wox有一天会无法使用. 于是想找一个替代Wox的软件.

## 01 处理方法

终于, 找到了微软官方提供的[PowerToys](https://learn.microsoft.com/zh-cn/windows/powertoys/), 其中的[PowerToys Run](https://learn.microsoft.com/zh-cn/windows/powertoys/run)工具同样实现了文件搜索功能.

PowerToys Run默认使用的是Windows Search, 而我正是因为Windows Search的效率问题才选用的Everything. 所幸, PowerToys Run支持插件替换, 即我们可以同样使用Everything来进行文件检索.

### 01.1 安装Powertoys

[安装 PowerToys \| Microsoft Learn](https://learn.microsoft.com/zh-cn/windows/powertoys/install)

建议从 [Microsoft Store 的 PowerToys 页面](https://aka.ms/getPowertoys)进行安装.

### 01.2 设置管理员方式启动

启动PowerToys后, 在```常规```页面中进行设置

![image-20231026123130356](/assets/image/image-20231026123130356.png)

### 01.3 安装Everything插件

进入```PowerToys Run```页面, 下滑到插件栏, 点击```查找更多插件```.

![image-20231026123252589](/assets/image/image-20231026123252589.png)

在弹出的[页面](https://github.com/microsoft/PowerToys/blob/main/doc/thirdPartyRunPlugins.md)中, 选择```Everything```

![image-20231026123423346](/assets/image/image-20231026123423346.png)

按照[页面](https://github.com/lin-ycv/EverythingPowerToys)中的提示进行安装

![image-20231026123511214](/assets/image/image-20231026123511214.png)

- 在```release```[页面](https://github.com/lin-ycv/EverythingPowerToys/releases/tag/v0.73.0)中下载[压缩包](https://github.com/lin-ycv/EverythingPowerToys/releases/download/v0.73.0/Everything-0.73.0-x64.zip)

  ![image-20231026123652155](/assets/image/image-20231026123652155.png)

- 解压缩
- 将解压出的```Everything```文件夹拷贝到```C:\Program Files\PowerToys\RunPlugins```目录中
- 重启```PowerToys```

### 01.4 将默认的Windows Search关闭

在```PowerToys```的```PowerToys Run```页面中, 插件部分找到```Windows 搜索```, 将其关闭

![image-20231026123919279](/assets/image/image-20231026123919279.png)



###### 参考网页

[Wox](http://www.wox.one/)

[voidtools](https://www.voidtools.com/zh-cn/)

[Microsoft PowerToys | Microsoft Learn](https://learn.microsoft.com/zh-cn/windows/powertoys/)
