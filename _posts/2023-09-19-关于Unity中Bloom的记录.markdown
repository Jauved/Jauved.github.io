---
layout: post
title: "关于Unity中Bloom的记录"
categories: [URP, 后处理]
tags: URP 后处理 Bloom
math: true
---

# 关于Unity中Bloom的记录

其中, 提取亮部的部分, 只看代码完全不知道做了什么.

```c++
half brightness = Max3(color.r, color.g, color.b);
half softness = clamp(brightness - Threshold + ThresholdKnee, 0.0, 2.0 * ThresholdKnee);
softness = (softness * softness) / (4.0 * ThresholdKnee + 1e-4);
half multiplier = max(brightness - Threshold, softness) / max(brightness, 1e-4);
color *= multiplier;
```

通过Desmos的绘图功能做出的[图表](https://www.desmos.com/calculator/4ijao2sjrs)可以直观的看到Unity做了什么. 其中x轴为亮度```brightness```. t为亮度阈值```Threshold)```, j为```ThresholdKnee```, p为```softness```(第一个), 

![image-20230919173355575](/assets/image/image-20230919173355575.png)

通常我们取Bloom亮部的做法是如<font color=orange>橙色线</font>部分, 亮度减去亮度阈值后低于0的部分取0, 高于0的部分取亮度减去亮度阈值.

如果我们需要平滑这个过渡, 那么就要想办法做出<font color=purple>紫色线</font>部分, 然后用max(<font color=purple>紫色线</font>, <font color=orange>橙色线</font>), 来得到最终曲线.

目前的关键在于<font color=purple>紫色线</font>的函数如何得到.

## Step1

首先, 对于一个折线内做一个曲线并相交, 函数应该形如

$$

y= \frac {
{x}^{n}}{a}

$$

我们将 $x-t$ 看作一个整体(或者你可以理解为将 $t=0$ ), 将 $n$ 暂定为2, 并通过反推, 实际上可以简化为新方程组求解:

$$

\begin{cases}
y=x \\
y= \frac {
{(x+j)}^{2}} {aj} \\
\end{cases}

$$

如果这个方程组有唯一解, 根据一元二次方程的通解定义, 

//TODO 补完公式

可以算出

当 $a=4$ 或者 $a=0$ 时可以有唯一解, 当然由于 $a$ 在分母, 则 $a \ne 0$ , 那么 $a=4$ , 也是代码中``` (4.0 * ThresholdKnee + 1e-4)```中的4.0的由来.

此时, $x=j$ , 则交点 $p$ 的值为$2 \cdot j$ 即```2.0 * ThresholdKnee```.

当然, Unity在```E:\Projects\LeiCanYRenderCore\Library\PackageCache\com.unity.render-pipelines.universal@14.0.8\Runtime\Passes\PostProcessPass.cs```中, 直接强制定义了```float thresholdKnee = threshold * 0.5f;```, 我们也可以借此做简化工作.
