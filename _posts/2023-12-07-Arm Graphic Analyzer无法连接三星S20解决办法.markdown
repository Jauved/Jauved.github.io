---
layout: post
title: "Arm Graphic Analyzer无法连接三星S20解决办法"
categories: [性能测试]
tags: 性能测试 Arm Android 三星
math: true

---

# Arm Graphic Analyzer无法连接三星S20解决办法

## 00 前言

首先处理好"开发者选项", "USB调试", "ADB安装". 

Samsung Galaxy S20 连接Arm Graphics Analyzer时, 出现`"Coundln't get the list of install packages"`提示.

![img_v3_025t_d1c34b90-dde8-4b1e-a899-710833b14c6g](/assets/image/img_v3_025t_d1c34b90-dde8-4b1e-a899-710833b14c6g.jpg)

## 01 处理方法

原因时因为三星自己的app, "安全文件夹"导致的. 删除该app即可.

如果忘记"安全文件夹"密码, 可以从设置中的"安全和隐私"条目重置密码.

###### 参考网页

[三星手机安全文件夹的常见问题 \| 三星电子 CN (samsung.com.cn)](https://www.samsung.com.cn/support/mobile-devices/frequently-asked-questions-about-samsung-mobile-security-folder/)

[真机调试一直处于 正在建立手机连接... - DCloud问答](https://ask.dcloud.net.cn/question/163529)

[ADB 命令大全 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/89060003)
