---
layout: post
title: "Lerp01WithEdge 算法推理与最终说明"
categories: [算法]
tags: 算法 HLSL Lerp Lerp01 半透明 Xray
math: true


---

# Lerp01WithEdge 算法推理与最终说明

## 1. 最终结论

`Lerp01WithEdge` 是一个 **01 输入双端外扩映射函数**。

它将输入控制参数 `In` 从标准 `[0,1]` 区间, 映射到可越界的 `[-Edge, 1 + Edge]` 区间。

核心目标是:

```text
In = 0                  -> Out = -Edge
In = Threshold          -> Out = Threshold
In = 1 - Threshold      -> Out = 1 - Threshold
In = 1                  -> Out = 1 + Edge
```

中间区间保持不变:

```text
Threshold <= In <= 1 - Threshold
Out = In
```

左端和右端只在端部区间内加速外扩:

```text
[0, Threshold]             -> [-Edge, Threshold]
[Threshold, 1 - Threshold] -> [Threshold, 1 - Threshold]
[1 - Threshold, 1]         -> [1 - Threshold, 1 + Edge]
```

最终工程实现如下:

```hlsl
/// 输入控制参数 In, 加上扩展宽度 Edge, 加上变速区间 Threshold, 输出重映射后的控制参数 Out。
/// 该 Out 可以保证, 即便加上扩展宽度, 仍旧可以在 In 为 0 或 1 时完整覆盖端部范围。
/// @param In 输入控制参数, 范围为 0-1。
/// @param Edge 两端扩张宽度, 范围为 0 以上。
/// @param Threshold 端部加速区间, 范围为 0-0.5。越大则越早开始变速, 但速度变化越缓。越小则越晚开始变速, 但速度变化越快。
/// @param Out 重映射后的控制参数, 理论范围为 -Edge 到 1+Edge。
void Lerp01WithEdge_float(float In, float Edge, float Threshold, out float Out)
{
    // 1. Normalize inputs.
    In = saturate(In);
    Edge = max(Edge, 0.0);

    float thresholdRaw = max(Threshold, 0.0);
    const float kEps = 1e-6;

    // 0 when Threshold is approximately 0, 1 otherwise.
    float enable = step(kEps, thresholdRaw);

    float threshold = min(max(thresholdRaw, kEps), 0.5);
    float invTh = rcp(threshold);

    // 2. Compute candidate outputs for three regions.

    // Center region: keep aligned.
    float center = In;

    // Left edge region: [0, threshold] -> [-Edge, threshold].
    float wL = enable * saturate((threshold - In) * invTh);
    float left = lerp(threshold, -Edge, wL);

    // Right edge region: [1 - threshold, 1] -> [1 - threshold, 1 + Edge].
    float wR = enable * saturate((In - (1.0 - threshold)) * invTh);
    float right = lerp(1.0 - threshold, 1.0 + Edge, wR);

    // 3. Region selection.

    // Left: In < threshold.
    float isLeft = enable * (1.0 - step(threshold, In));

    // Right: In >= 1 - threshold.
    float isRight = enable * step(1.0 - threshold, In);

    // Center: otherwise.
    float isCenter = 1.0 - isLeft - isRight;

    // 4. Compose.
    Out = left * isLeft + center * isCenter + right * isRight;
}
```

------

## 2. 问题起点: 需要一个端部快速变化的系数

最初的问题是:

```text
输入 a 的范围是 [0,1]。
需要得到一个系数 b。
b 通常为 1。
当 a 越接近 0 或 1 时, b 需要迅速衰减到 0。
```

例如:

```text
0 < a < 0.1 时, a 越接近 0, b 越接近 0。
0.9 < a < 1 时, a 越接近 1, b 越接近 0。
中间区域 b 基本保持为 1。
```

这个阶段的算法思路是 **边缘衰减**。

典型写法是先计算距离两端的最小距离:

```hlsl
float edgeDistance = min(a, 1.0 - a);
```

然后将边缘宽度归一化:

```hlsl
float x = saturate(edgeDistance / threshold);
```

最后得到衰减系数:

```hlsl
float b = pow(x, exponent);
```

或者用 `smoothstep` 得到更平滑的边缘过渡:

```hlsl
float left = smoothstep(0.0, threshold, a);
float right = smoothstep(0.0, threshold, 1.0 - a);
float b = left * right;
```

这个阶段的核心结论是:

```text
越靠近 0 或 1, 输出越接近 0。
中间区域输出接近 1。
```

------

## 3. 需求变化: 不再是边缘衰减, 而是右端外扩映射

后续需求发生变化:

```text
输入 a 范围仍然是 [0,1]。
输出 b 范围变成 [0,t]。
t > 1。
当 a < 0.9 时, b = a。
当 a > 0.9 时, a 从 0.9 到 1, b 从 0.9 到 t。
```

这时算法目标从“生成衰减系数”变成了 **区间重映射**。

也就是:

```text
[0, 0.9] -> [0, 0.9]
[0.9, 1] -> [0.9, t]
```

中间不变, 右端区间被拉伸。

分段写法是:

```hlsl
float ComputeB(float a, float t)
{
    a = saturate(a);

    if (a <= 0.9)
    {
        return a;
    }

    float alpha = (a - 0.9) / 0.1;
    return lerp(0.9, t, alpha);
}
```

这里得到一个关键公式:

```hlsl
float alpha = (a - inMin) / (inMax - inMin);
float b = lerp(outMin, outMax, alpha);
```

也就是:

```text
先把输入区间归一化到 [0,1],
再用 lerp 映射到目标区间。
```

这是后续算法的基础。

------

## 4. 去掉硬编码: 将 0.1 变成可调变量

接着, 右端 `[0.9,1]` 这段长度不希望写死为 `0.1`, 而是需要变成变量。

于是引入:

```hlsl
threshold
```

它表示端部过渡区间长度。

原来的:

```text
0.9
```

变成:

```hlsl
1.0 - threshold
```

原来的:

```text
0.1
```

变成:

```hlsl
threshold
```

因此右侧映射变成:

```hlsl
float rightStart = 1.0 - threshold;
float alpha = (a - rightStart) / threshold;
float b = lerp(rightStart, t, alpha);
```

此时算法变成:

```text
[0, 1 - threshold] -> 原样输出
[1 - threshold, 1] -> 映射到 [1 - threshold, t]
```

这个阶段的核心结论是:

```text
threshold 表示端部变速区间长度。
threshold 越大, 越早进入变速区间, 变化更缓。
threshold 越小, 越晚进入变速区间, 变化更快。
```

------

## 5. 需求再次变化: 左右两端都需要外扩

然后需求被改成当前的完整形式:

```text
a 的范围是 [0,1]。
b 的范围是 [-t, 1+t]。
当 threshold < a < 1 - threshold 时, b = a。
当 a < threshold 时:
    a 从 threshold 到 0。
    b 从 threshold 到 -t。
当 a > 1 - threshold 时:
    a 从 1 - threshold 到 1。
    b 从 1 - threshold 到 1 + t。
```

这时算法不再只是右端外扩, 而是 **左右双端外扩**。

完整映射关系变成:

```text
a = 0                  -> b = -t
a = threshold          -> b = threshold
a = 1 - threshold      -> b = 1 - threshold
a = 1                  -> b = 1 + t
```

对应三个区间:

```text
左端: [0, threshold] -> [-t, threshold]
中间: [threshold, 1 - threshold] -> 原样输出
右端: [1 - threshold, 1] -> [1 - threshold, 1 + t]
```

------

## 6. 推导左端映射

左端输入区间是:

```text
[0, threshold]
```

目标输出区间是:

```text
[-t, threshold]
```

但是为了符合直觉, 按从中心往边缘的方向描述:

```text
a = threshold -> b = threshold
a = 0         -> b = -t
```

因此归一化权重应该满足:

```text
a = threshold 时, alpha = 0
a = 0 时, alpha = 1
```

所以:

```hlsl
float alphaL = (threshold - a) / threshold;
```

再限制到 `[0,1]`:

```hlsl
float alphaL = saturate((threshold - a) / threshold);
```

最终左侧输出:

```hlsl
float b_left = lerp(threshold, -t, alphaL);
```

也就是:

```text
alphaL = 0 -> threshold
alphaL = 1 -> -t
```

------

## 7. 推导中间映射

中间区间是:

```text
[threshold, 1 - threshold]
```

需求是保持输入输出一致:

```hlsl
float b_center = a;
```

也就是:

```text
b = a
```

这个区间不做外扩, 不做变速。

------

## 8. 推导右端映射

右端输入区间是:

```text
[1 - threshold, 1]
```

目标输出区间是:

```text
[1 - threshold, 1 + t]
```

归一化权重应该满足:

```text
a = 1 - threshold 时, alpha = 0
a = 1 时, alpha = 1
```

因此:

```hlsl
float alphaR = (a - (1.0 - threshold)) / threshold;
```

限制到 `[0,1]`:

```hlsl
float alphaR = saturate((a - (1.0 - threshold)) / threshold);
```

最终右侧输出:

```hlsl
float b_right = lerp(1.0 - threshold, 1.0 + t, alphaR);
```

也就是:

```text
alphaR = 0 -> 1 - threshold
alphaR = 1 -> 1 + t
```

------

## 9. 分段版算法

根据三个区间, 可以得到直观的分段版:

```hlsl
float ComputeB(float a, float t, float threshold)
{
    a = saturate(a);

    if (a < threshold)
    {
        float alpha = saturate((threshold - a) / threshold);
        return lerp(threshold, -t, alpha);
    }

    if (a > 1.0 - threshold)
    {
        float alpha = saturate((a - (1.0 - threshold)) / threshold);
        return lerp(1.0 - threshold, 1.0 + t, alpha);
    }

    return a;
}
```

这个版本最容易阅读。

但在 HLSL 中, 为了减少分支并更适合 ShaderGraph Custom Function 或 GPU 批量计算, 后续整理为无分支版本。

------

## 10. 从分段版改成无分支版

无分支版本的思路是:

```text
不先判断当前属于哪个区间。
先同时计算三个候选结果: left, center, right。
再计算三个区域权重: isLeft, isCenter, isRight。
最后加权合成。
```

候选值:

```hlsl
float center = In;

float wL = saturate((threshold - In) / threshold);
float left = lerp(threshold, -Edge, wL);

float wR = saturate((In - (1.0 - threshold)) / threshold);
float right = lerp(1.0 - threshold, 1.0 + Edge, wR);
```

区域选择:

```hlsl
float isLeft = 1.0 - step(threshold, In);
float isRight = step(1.0 - threshold, In);
float isCenter = 1.0 - isLeft - isRight;
```

最终合成:

```hlsl
Out = left * isLeft + center * isCenter + right * isRight;
```

这里使用 `step(edge, x)` 的语义:

```text
x < edge  -> 0
x >= edge -> 1
```

所以:

```hlsl
1.0 - step(threshold, In)
```

表示:

```text
In < threshold -> 1
In >= threshold -> 0
```

而:

```hlsl
step(1.0 - threshold, In)
```

表示:

```text
In >= 1.0 - threshold -> 1
In < 1.0 - threshold  -> 0
```

------

## 11. Threshold = 0 的问题

直接使用:

```hlsl
float alphaL = (threshold - In) / threshold;
float alphaR = (In - (1.0 - threshold)) / threshold;
```

会在 `threshold = 0` 时发生除以 0。

但工程上 `Threshold = 0` 是有意义的, 它应该表示:

```text
关闭端部变速。
Out = In。
```

因此最终版本加入了 `enable` 控制:

```hlsl
float thresholdRaw = max(Threshold, 0.0);
const float kEps = 1e-6;

float enable = step(kEps, thresholdRaw);
float threshold = min(max(thresholdRaw, kEps), 0.5);
float invTh = rcp(threshold);
```

当 `Threshold` 接近 0 时:

```hlsl
enable = 0;
```

此时左右区域关闭:

```hlsl
isLeft = 0;
isRight = 0;
isCenter = 1;
```

最终:

```hlsl
Out = In;
```

这样既避免了除以 0, 又保留了 `Threshold = 0` 作为“关闭功能”的语义。

------

## 12. Threshold 上限为什么是 0.5

`Threshold` 表示左右两端各自的端部区间长度。

左侧区间:

```text
[0, Threshold]
```

右侧区间:

```text
[1 - Threshold, 1]
```

如果 `Threshold > 0.5`, 左右区间会发生重叠。

例如:

```text
Threshold = 0.6
左侧区间: [0, 0.6]
右侧区间: [0.4, 1]
```

中间 `[Threshold, 1 - Threshold]` 会变成反向区间。

所以最终将其限制为:

```hlsl
threshold = min(max(thresholdRaw, kEps), 0.5);
```

也就是:

```text
0 < threshold <= 0.5
```

------

## 13. Edge 的含义

之前推导中的 `t` 在最终代码中命名为 `Edge`。

原因是最终算法中的 `t` 不再只是“右侧目标最大值”, 而是两端外扩距离:

```text
左端从 0 外扩到 -Edge。
右端从 1 外扩到 1 + Edge。
```

因此命名为 `Edge` 更贴近工程语义。

约束为:

```hlsl
Edge = max(Edge, 0.0);
```

负数没有实际意义, 因此被钳制为 0。

------

## 14. 为什么这个算法能解决“扩展宽度后仍完整覆盖”的问题

在很多 Shader 控制参数中, `0` 和 `1` 往往对应效果的两个边界。

如果直接使用标准 `[0,1]` 控制参数, 当效果本身带有额外宽度, 模糊, 扩散, 挤出或边缘过渡时, 仅仅到达 `0` 或 `1` 可能不足以完全覆盖或完全移除边缘像素。

该算法通过把输出范围扩展为:

```text
[-Edge, 1 + Edge]
```

使得:

```text
In = 0 -> Out = -Edge
In = 1 -> Out = 1 + Edge
```

这样即便后续效果计算中存在额外宽度, 控制值也能越过原始 `[0,1]` 边界, 从而覆盖端部误差或边缘残留。

中间区间仍然保持 `Out = In`, 因此不会破坏主要控制区间的线性一致性。

------

## 15. Vector3 版本的意义

`Lerp01WithEdgeVector3_float` 是标量版本的逐通道扩展。

它等价于分别对 X/Y/Z 三个通道执行一次:

```hlsl
Lerp01WithEdge_float
```

每个通道都可以有独立的:

```text
In
Edge
Threshold
```

因此适合以下情况:

```text
不同轴向有不同外扩宽度。
不同控制通道需要不同端部加速区间。
同一个函数同时处理三个独立的 01 控制量。
```

------

## 16. 当前最终版本的定位

当前 `Lerp01WithEdge` 已经不是一个临时公式, 而是一个可以复用的数学工具函数。

它的工程定位可以概括为:

```text
对标准 01 控制参数进行双端安全外扩, 同时保持中间区间线性一致。
```

适用场景包括但不限于:

```text
遮罩推进。
边缘擦除。
基于 0-1 控制量的可见性过渡。
带宽度补偿的线性插值。
需要保证端部完全覆盖或完全移除的 Shader 控制参数。
```

推荐参数范围:

```text
Edge >= 0
0 <= Threshold <= 0.5
```

常见取值:

```text
Edge = 0.05 ~ 0.2
Threshold = 0.05 ~ 0.2
```

当希望端部变化更快时, 减小 `Threshold`。

当希望端部变化更缓时, 增大 `Threshold`。

当希望关闭外扩宽度时:

```text
Edge = 0
```

当希望关闭端部变速逻辑时:

```text
Threshold = 0
```

------

## 17. TODO: 增加曲线映射模式

当前 `Lerp01WithEdge` 使用的是分段线性映射模式。

当前模式可以称为:

```text
Piecewise Linear Mode
```

其行为如下:

```text
[0, Threshold]             -> 左端线性外扩
[Threshold, 1 - Threshold] -> 保持 Out = In
[1 - Threshold, 1]         -> 右端线性外扩
```

该模式的优点是:

```text
逻辑直观。
中间区间严格保持 Out = In。
Threshold 可以明确控制端部变速区间。
In = 0 和 In = 1 时可以稳定映射到 -Edge 和 1 + Edge。
```

但它也有一个特征:

```text
Out 的数值是连续的, 但在 Threshold 和 1 - Threshold 处, 斜率会发生突变。
```

也就是说, 当 `In` 从中间区间进入端部区间时, 映射速度会突然改变。

------

### 17.1 下一步演化目标

后续可以增加一个新的曲线映射模式。

该模式可以暂称为:

```text
Curve Mode
```

或:

```text
Global Curve Mode
```

该模式的目标是:

```text
不要等到 In 到达 Threshold 或 1 - Threshold 后才突然变速。
而是从整个 [0,1] 区间开始, 使用一条连续曲线完成外扩映射。
```

换句话说, 当前模式是:

```text
先保持线性, 到端部区间后再变速。
```

新的曲线模式是:

```text
全程根据曲线逐渐调整映射速度。
```

------

### 17.2 曲线模式的目标映射关系

曲线模式仍然应保留端点约束:

```text
In = 0 -> Out = -Edge
In = 1 -> Out = 1 + Edge
```

根据具体需求, 可以选择是否保留中心点约束:

```text
In = 0.5 -> Out = 0.5
```

对于左右对称的曲线模式, 建议保留中心点约束。

也可以选择是否要求:

```text
In 接近 0.5 时, Out 尽量接近 In。
```

这样可以避免中间区域被过度拉伸。

------

### 17.3 可选曲线类型

后续可以考虑以下曲线类型。

#### 17.3.1 Power Curve

使用幂曲线控制外扩速度。

示意:

```hlsl
float shaped = pow(x, exponent);
```

特点:

```text
exponent > 1 时, 端部变化更集中。
exponent < 1 时, 端部变化更提前。
```

适合需要简单参数控制的场景。

------

#### 17.3.2 SmoothStep Curve

使用 `smoothstep` 或更高阶的平滑函数。

示意:

```hlsl
float shaped = smoothstep(0.0, 1.0, x);
```

特点:

```text
端点附近变化更平滑。
不会像线性分段那样在区间交界处产生明显斜率突变。
```

适合视觉过渡需要更柔和的场景。

------

#### 17.3.3 Sin Curve

使用正弦曲线控制映射。

示意:

```hlsl
float shaped = 0.5 - 0.5 * cos(x * PI);
```

特点:

```text
曲线天然平滑。
适合需要柔和加速和减速的过渡。
```

------

### 17.4 一个可能的曲线模式设计方向

可以把最终映射拆成两部分:

```text
Out = In + Offset
```

其中 `Offset` 由曲线控制。

目标是:

```text
In = 0   -> Offset = -Edge
In = 0.5 -> Offset = 0
In = 1   -> Offset = Edge
```

也就是说:

```text
Out = -Edge        when In = 0
Out = 0.5          when In = 0.5
Out = 1 + Edge     when In = 1
```

一个简单的对称写法可以是:

```hlsl
float signedX = In * 2.0 - 1.0;          // [-1, 1]
float signX = sign(signedX);
float absX = abs(signedX);               // [0, 1]

float shaped = pow(absX, Exponent);      // [0, 1]
float offset = signX * shaped * Edge;

Out = In + offset;
```

该模式下:

```text
In = 0:
signedX = -1
offset = -Edge
Out = -Edge

In = 0.5:
signedX = 0
offset = 0
Out = 0.5

In = 1:
signedX = 1
offset = Edge
Out = 1 + Edge
```

这类方案不依赖 `Threshold` 分段, 而是让整个 `[0,1]` 区间都受到曲线影响。

------

### 17.5 需要进一步确认的问题

在实现曲线模式前, 需要确认以下设计点:

```text
曲线模式是否必须保持中间区域完全 Out = In。
是否只要求中心点 In = 0.5 时 Out = 0.5。
是否允许整个 [0,1] 都发生轻微偏移。
是否需要继续保留 Threshold 作为曲线影响范围。
是否需要 Curve Mode 和 Piecewise Linear Mode 共存。
```

如果希望中间大范围严格保持 `Out = In`, 那么仍然需要保留分段逻辑, 只是把端部线性段替换为端部曲线段。

如果希望完全避免 `Threshold` 和 `1 - Threshold` 处的突然变速, 那么更适合使用全局曲线模式。

------

### 17.6 暂定模式划分

后续可以将函数扩展为两种模式:

```text
Mode 0: Piecewise Linear Mode
```

当前版本。

特点:

```text
中间区间严格保持 Out = In。
端部区间线性外扩。
Threshold 控制端部区间长度。
Mode 1: Global Curve Mode
```

新增版本。

特点:

```text
整个 [0,1] 区间都根据曲线产生偏移。
不会在 Threshold 和 1 - Threshold 处产生突然变速。
曲线可以使用 Power, SmoothStep, Sin 等形式。
```

未来也可以继续增加:

```text
Mode 2: Piecewise Curve Mode
```

特点:

```text
仍然保留 Threshold。
中间区间保持 Out = In。
但端部区间不再使用线性映射, 而是使用 Power, SmoothStep 或 Sin 曲线映射。
```

需要注意的是, `Piecewise Curve Mode` 只能让端部区间内部更平滑, 但如果中间区间仍然是严格线性, 在 `Threshold` 和 `1 - Threshold` 的交界处仍然可能存在斜率变化。

若目标是完全避免交界处突然变速, 应优先考虑 `Global Curve Mode`。
