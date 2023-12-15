---
layout: post
title: "RootAndroid手机"
categories: [URP, 后处理]
tags: URP 后处理 DepthOfField
math: true

---

# RootAndroid手机

## 00 前言

## 01 处理方法

### 01.1 打开手机开发者模式

- 通常操作为点击版本号
- 具体不同的手机不同, 可以自行搜索方法

### 01.2 使用Andoird Studio安装ADB工具和USB驱动

![image-20231205150355011](/assets/image/image-20231205150355011.png)

![image-20231205150600271](/assets/image/image-20231205150600271.png)

### 01.3 解锁Bootloader

连接手机到电脑, 以下命令行建立在配置好ADB工具, 手机打开开发者模式中的usb调试功能, 命令行模式下

#### 00x 重启手机进入bootload模式

`adb reboot bootloader`

#### 01x 检查手机是否可以在fastboot下检测到

如果正常的话, 执行以下命令之后会显示设备号, 否则检查USB驱动是否正常安装

`fastboot devices`

#### 02x 解锁bootloader

`fastboot flashing unlock`

输入以上命令后, 手机上会有一个信息让你确认, 大意就是该操作会清空数据, 并且让你的手机不在安全. 使用音量键选择继续或者中止, 使用开机键进行确认.

#### 03x 重启手机

`fastboot reboot`

#### 04x 解除wifi受限(非必须)

`adb shell settings put global captive_portal_https_url https://www.google.cn/generate_204`

### 01.4 刷入Magisk并Root

#### 01x 下载官方出厂镜像包

这里是google原厂机的出厂镜像下载地址, 其他品牌的需要自行搜索.

[Nexus 和 Pixel 设备的出厂映像  \| Google Play services  \| Google for Developers](https://developers.google.com/android/images?hl=zh-cn)

#### 02x 解压下载后的包, 并提取出boot.img备用

#### 03x 下载Magisk Manager

[Releases · topjohnwu/Magisk (github.com)](https://github.com/topjohnwu/Magisk/releases)

#### 04x 将上述boot.img和MagiskManager-v7.4.0.apk两个文件传到手机里备用

#### 05x 在手机上安装Magisk Manager后并打开, 点击安装Magisk, **选择安装方法**—**选择并修补一个文件**, 找到刚才传到手机中的boot.img并选中, 修补, 修补完后不要重启.

#### 06x 修补后会在boot.img的同文件夹下生成一个magisk_patched.img文件，把magisk_patched.img传到电脑备用

#### 07x 重启进入bootload

`adb reboot bootloader`

#### 07x 命令行载入镜像

`fastboot flash boot magisk_patched.img`

#### 08x 重启

`fastboot reboot`

#### 01.5 获取超级用户权限并打开Debuggable

每次开机后都要做, 并且

```
adb shell #激活adb命令行
su #切换至超级用户
magisk resetprop ro.debuggable 1
stop;start; #重启
```

用以下命令行检测是否生效

```
adb shell
getprop ro.debuggable
```

如果值为1则生效.

### 02 简易步骤总结

Unlock bootloader

```csharp
//重启到fastboot状态
adb reboot bootloader
//检查在fastboot下有没有识别手机
fastboot devices
//如果没有识别, 打开AndroidStudio, tools->SDK Manager
//选择usbdriver进行下载, 下载后的目录为
//X:\AndroidSDK\extras\google\usb_driver
fastboot flashing unlock
//用音量键选择unlock, 用开机键确定
//重启手机
fastboot reboot
//进入adb shell
adb shell
//su
su
```

本来可以安装MagiskHide Props Config模块实现全局可调式(目前版本的Magisk失效, 可以搜索有没有其他办法), 但目前阶段暂时手动开启.

```csharp
#使用magisk工具
adb shell //adb进入命令行模式
su //切换至超级用户
magisk resetprop ro.debuggable 1 //设置debuggable
stop;start; //一定要通过该方式重启
#再次进入adb shell
adb shell
getprop ro.debuggable//查看是否已经变为1了
```



###### 参考网页

[小胡子的干货铺——Pixel 4 XL解锁Bootloader - 少数派 (sspai.com)](https://sspai.com/post/57922)

[小胡子的干货铺——Pixel 4 XL刷入Magisk、Root - 少数派 (sspai.com)](https://sspai.com/post/57923#!)

[Nexus 和 Pixel 设备的出厂映像  \| Google Play services  \| Google for Developers](https://developers.google.com/android/images?hl=zh-cn)

[Android修改ro.debuggable 的四种方法-CSDN博客](https://blog.csdn.net/jinmie0193/article/details/111355867)

[Download Magisk Manager Latest Version 26.4 For Android 2023](https://magiskmanager.com/)

[使用Magisk获取Android设备root权限 - xyxyxyxyxyxy - 博客园 (cnblogs.com)](https://www.cnblogs.com/my1127/p/16133653.html)

[cnrd/MagiskHide-Props-Config: MagiskHidePropsConf (github.com)](https://github.com/cnrd/MagiskHide-Props-Config)
