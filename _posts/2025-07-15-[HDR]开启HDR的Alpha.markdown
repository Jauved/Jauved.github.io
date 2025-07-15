---
layout: post
title: "[HDR]开启HDR的Alpha"
categories: [URP, HDR]
tags: URP HDR Alpha
math: true


---

# [HDR]开启HDR的Alpha

## 00 前言

Unity在URP管线下, 开启HDR后, 会丢失渲染结果的Alpha, 在HDRP下, 是可以开启的, 将Buffer格式设置为R16G16B16A16_SFloat. 即可输出渲染结果的Alpha. 而URP下面没有这个设置, 默认的HDR的Buffer格式为B10G11R11_UFloatPack32,  无Alpha值.

## 01 处理方法

PlayerSetting中是有这个设置的, 只是被屏蔽了. 通过`PlayerSettings.preserveFramebufferAlpha`的设置, 可以开启. 具体方法见源代码部分. 注意: 这个只是编辑器设置, 打包设置需要另查.

## 02 源代码

```c#
/// <summary>
/// 强制开启HDR下的输出图的Alpha通道, 会让输出的Buffer大小加倍
/// </summary>
public static class PreserveFrameBufferAlphaMenu
{
    [MenuItem("LookDev/PreserveFrameBufferAlpha/On")]
    private static void PreserveFrameBufferAlphaOn()
    {
        PlayerSettings.preserveFramebufferAlpha = true;
    }

    [MenuItem("LookDev/PreserveFrameBufferAlpha/Off")]
    private static void PreserveFrameBufferAlphaOff()
    {
        PlayerSettings.preserveFramebufferAlpha = false;
    }
}
```



###### 参考网页
