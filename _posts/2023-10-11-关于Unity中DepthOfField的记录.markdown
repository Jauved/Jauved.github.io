---
layout: post
title: "关于Unity中DepthOfField的记录"
categories: [URP, 后处理]
tags: URP 后处理 DepthOfField
math: true
---

# 关于定制Unity中DepthOfField的记录

## 00 前言

- 策划需要将景深进行分段控制

- 直接对深度进行重映射是最方便的做法

- https://www.desmos.com/calculator/outz8ciqgx

  ![desmos-graph](/assets/image/desmos-graph.png)![image-20231012210548195](/assets/image/image-20231012210548195.png)

- 我希望斜率不仅仅是2, 而是可以是任何值, 且方程连续
  - y=(x-2a)/k+i
  - 且x=p+a时, y=p-a
  - 求出i=(p-a)(1-1/k)
  - 最后y=(x-2a)/k+(p-a)(1-1/k).
- https://www.desmos.com/calculator/5aebyotklu
- ![desmos-graph (1)](/assets/image/desmos-graph_1.png)![image-20231012211205892](/assets/image/image-20231012211205892.png)

## 01 初版

初始版本关键代码如下

```c++
        //Changed
        //P面板=p-a
        //p=p面板+a
        //使用k改变变化速率,将远近的模糊程度分开
        //Todo 优化算法, 消除if
        float a = 2.0;
        float p = 7.0;
        float k = 3;//斜率
        if (linearEyeDepth <= p - a)
        {
            linearEyeDepth = linearEyeDepth;
        }
        else if (linearEyeDepth > p - a && linearEyeDepth < p + a)
        {
            linearEyeDepth = p - a;
        }
        else if (linearEyeDepth >= p + a)
        {
            linearEyeDepth = (linearEyeDepth - 2.0 * a) / k + (p - a) * (1.0 - 1 / k);
        }
        //Changed
```

## 02 优化

考虑到```if...else```在着色器中效率不高, 这里使用step进行了优化.

```c++
        float condition1 = step(p - a, linearEyeDepth) * step(linearEyeDepth, p + a);
        float condition2 = step(p + a, linearEyeDepth);

        linearEyeDepth = condition1 * (p - a) +
        condition2 * ((linearEyeDepth - 2.0 * a) / k + (p - a) * (1.0 - 1 / k)) +
        (1.0 - condition1 - condition2) * linearEyeDepth;
```

当然, 这里可以用```rcp(k)```来把除法消除进行优化

```c++
        float invK = rcp(k);
        float condition1 = step(p - a, linearEyeDepth) * step(linearEyeDepth, p + a);
        float condition2 = step(p + a, linearEyeDepth);

        linearEyeDepth = condition1 * (p - a) +
        condition2 * ((linearEyeDepth - 2.0 * a) * invK + (p - a) * (1.0 - invK)) +
        (1.0 - condition1 - condition2) * linearEyeDepth;
```

但是, 实际上, ```1/k```这个值可以在传入之前就计算完毕, 所以更进一步, ```invK```的计算直接交给CPU即可.

### 彩色石头

在搜索```rcp(x)```的时候, 找到了一些好玩的东西.

- ```Packages/com.unity.render-pipelines.core@14.0.8/Runtime/PostProcessing/Shaders/ffx/ffx_a.hlsl```文件中, 关于```*FLOAT APPROXIMATIONS*```(浮动近似值)的部分有如下注释

  ```c++
  //==============================================================================================================================
  //                                                    FLOAT APPROXIMATIONS
  //------------------------------------------------------------------------------------------------------------------------------
  // Michal Drobot has an excellent presentation on these: "Low Level Optimizations For GCN",
  //  - Idea dates back to SGI, then to Quake 3, etc.
  //  - https://michaldrobot.files.wordpress.com/2014/05/gcn_alu_opt_digitaldragons2014.pdf
  //     - sqrt(x)=rsqrt(x)*x
  //     - rcp(x)=rsqrt(x)*rsqrt(x) for positive x
  //  - https://github.com/michaldrobot/ShaderFastLibs/blob/master/ShaderFastMathLib.h
  //------------------------------------------------------------------------------------------------------------------------------
  // These below are from perhaps less complete searching for optimal.
  // Used FP16 normal range for testing with +4096 32-bit step size for sampling error.
  // So these match up well with the half approximations.
  //==============================================================================================================================
  ```

- 其中的pdf文件有一些特别的优化方式, 当然, pdf是2014年的, 无法保证仍旧有效, 毕竟硬件发展迅速.

- ```Packages/com.unity.render-pipelines.core@14.0.8/ShaderLibrary/API/GLES2.hlsl```中, 由于```rcp(x)```函数的不支持, 所以有如下预定义```#define rcp(x) 1.0 / (x)```

- 关于```rcp(x)```的兼容性, 还有这一篇文章[**unity shader SSAO 环境光屏蔽 rcp 函数 bug - 知乎 (zhihu.com)**](https://zhuanlan.zhihu.com/p/489666024)

  - ```Library/PackageCache/com.unity.postprocessing@3.2.2/PostProcessing/Shaders/StdLib.hlsl```中使用这样的代码来做兼容.

    ```c++
    #if (SHADER_TARGET < 50 && !defined(SHADER_API_PSSL))
    float rcp(float value)
    {
        return 1.0 / value;
    }
    #endif
    ```

- 总之就是, 要使用```rcp(x)```函数, 需要用额外的语句保证兼容性.


## 03 另一种方式

之前用的是定位 $p$ 点, 然后前后扩展 $a$ 距离的方式, 现在是定好近位置 $m$ 和远位置 $n$ 然后来处理, 代码修改如下:
```c++
        // float a = 2.0;
        // float p = 7.0;        
        float k = 3;//斜率//
        float invK = rcp(k);

        // float condition1 = step(p - a, linearEyeDepth) * step(linearEyeDepth, p + a);
        // float condition2 = step(p + a, linearEyeDepth);
        //
        // linearEyeDepth = condition1 * (p - a) +
        // condition2 * ((linearEyeDepth - 2.0 * a) * invK + (p - a) * (1.0 - invK)) +
        // (1.0 - condition1 - condition2) * linearEyeDepth;

        float m = 5;
        float n = 9;

        float condition1 = step(m, linearEyeDepth) * step(linearEyeDepth, n);
        float condition2 = step(n, linearEyeDepth);
        linearEyeDepth = condition1 * m + condition2 * ((linearEyeDepth - (n - m)) * invK +
            m * (1.0 - invK)) + (1.0 - condition1 - condition2) * linearEyeDepth;
```

[图像](https://www.desmos.com/calculator/ojdhutm9gs)如下:
![desmos-graph (2)](/assets/image/desmos-graph_2.png)![image-20231013170825374](/assets/image/image-20231013170825374.png)

## 04 定制记录

### 注释标识: *//C10132023*

### 涉及文件:

- 着色器: 
  ```Packages/com.unity.render-pipelines.universal@14.0.8/Shaders/PostProcessing/BokehDepthOfField.shader```
- 面板: 
  ```Packages/com.unity.render-pipelines.universal@14.0.8/Runtime/Overrides/DepthOfField.cs```
  ```Packages/com.unity.render-pipelines.universal@14.0.8/Editor/Overrides/DepthOfFieldEditor.cs```
- Pass:
  ```Packages/com.unity.render-pipelines.universal@14.0.8/Runtime/Passes/PostProcessPass.cs```

### 彩色石头:

- DOF的算法有这样的注释```*// "A Lens and Aperture Camera Model for Synthetic Image Generation" [Potmesil81]*```
- [A lens and aperture camera model for synthetic image generation \| ACM SIGGRAPH Computer Graphics](https://dl.acm.org/doi/10.1145/965161.806818)
- [文件下载](https://dl.acm.org/doi/pdf/10.1145/965161.806818)
- 81年的算法

###### 参考网页: 

[Depth Of Field \| Universal RP \| 14.0.9 (unity3d.com)](https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@14.0/manual/post-processing-depth-of-field.html)

[图形学基础\|景深效果（Depth of Field/DOF）_后处理dof 原理-CSDN博客](https://blog.csdn.net/qjh5606/article/details/118960868)

[光学成像原理之景深(Depth of Field)-CSDN博客](https://blog.csdn.net/mingjinliu/article/details/103648118)
