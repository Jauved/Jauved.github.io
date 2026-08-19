---
layout: post
title: "《Linear Algebra Done Right》学习指南: 面向图形开发的线性代数路线"
categories: [数学, 线性代数]
tags: 线性代数 LinearAlgebra LinearAlgebraDoneRight 图形学 数学基础
math: true


---

# 《Linear Algebra Done Right》学习指南: 面向图形开发的线性代数路线

## 1. 这本书是什么

《[Linear Algebra Done Right](https://linear.axler.net/)》是 Sheldon Axler 编写的一本线性代数教材.

- [英文版](https://linear.axler.net/LADR4e.pdf)
- [中文版](https://linear.axler.net/LADR4eChinese.pdf)

目前最新版本为第 4 版. 官方网站提供免费的英文和中文版 PDF. 第 4 版采用 Creative Commons BY-NC 许可.

这本书并不是一本以"如何计算矩阵"为中心的教材.

它更关注:

> 向量空间是什么, 线性映射是什么, 以及线性映射本身具有怎样的结构.

作者将这本书定位为通常意义上的第二次线性代数学习. 书本虽然从基础定义开始, 但学习重点是定义、定理和证明, 而不是矩阵计算技巧.

因此, 更适合将其理解为:

> 从"会使用矩阵", 进入"理解矩阵背后的线性代数".

------

# 2. 这本书最重要的思想

传统工程学习中, 很容易形成这样的认识:

```text
向量
    ↓
矩阵
    ↓
矩阵乘法
    ↓
旋转 / 缩放 / 坐标转换
```

但从线性代数本身来看, 更合理的结构是:

```text
向量空间
    ↓
线性映射
    ↓
选择一组基
    ↓
矩阵
```

也就是说:

**矩阵并不是最基础的对象.**

真正的对象是线性映射.

例如:

$$

T:V\rightarrow W

$$

表示一个从向量空间 $V$ 到向量空间 $W$ 的线性映射.

当我们分别给 $V$ 和 $W$ 选择一组基以后, 才可以使用一个矩阵 $M$ 表示这个映射:

$$

[T(v)] = M[v]

$$

因此工程中常见的:

$$

p'=Mp

$$

更准确的理解应该是:

```text
空间中的向量 p
        ↓
    线性映射 T
        ↓
空间中的向量 p'

选择坐标系之后:

p
↓
矩阵 M
↓
p'
```

矩阵只是线性映射在某组基下的数字表示.

这是阅读这本书时需要始终保持的核心认识.

------

# 3. 为什么这种理解对图形学有意义

图形编程中大量问题本质上都属于线性代数.

例如:

```text
Object Space
    ↓
World Space
    ↓
View Space
    ↓
Clip Space
```

表面上看是在不断乘矩阵.

实际上是在不断改变:

```text
向量所在空间
+
空间之间的映射
+
这些映射在指定基下的矩阵表示
```

理解这一点以后, 很多以前需要"记住规则"的问题会逐渐变成可以推导的问题.

例如:

- 为什么矩阵乘法有顺序.
- 为什么改变坐标系需要基变换.
- 为什么 Position 和 Direction 的变换不同.
- 为什么 Normal 不能直接使用普通的 Model Matrix 变换.
- 为什么 Normal Matrix 与逆转置矩阵有关.
- 为什么正交矩阵的逆等于转置.
- 为什么旋转可以被理解为保持长度和角度的线性映射.
- 为什么某些矩阵可以对角化.
- 特征向量到底表示什么.
- SVD 为什么可以分析一个变换究竟做了多少旋转和缩放.

这些都不只是"矩阵计算问题".

------

# 4. 本书整体结构

第 4 版主要分为 9 章.

```text
Linear Algebra
│
├── Chapter 1
│   Vector Spaces
│   向量空间
│
├── Chapter 2
│   Finite-Dimensional Vector Spaces
│   有限维向量空间
│
├── Chapter 3
│   Linear Maps
│   线性映射
│
├── Chapter 4
│   Polynomials
│   多项式
│
├── Chapter 5
│   Eigenvalues and Eigenvectors
│   特征值与特征向量
│
├── Chapter 6
│   Inner Product Spaces
│   内积空间
│
├── Chapter 7
│   Operators on Inner Product Spaces
│   内积空间上的算子
│
├── Chapter 8
│   Operators on Complex Vector Spaces
│   复向量空间上的算子
│
└── Chapter 9
    Multilinear Algebra and Determinants
    多重线性代数与行列式
```

其中第 7 章还包含:

```text
Spectral Theorem
谱定理

QR Factorization
QR 分解

Cholesky Factorization
Cholesky 分解

Singular Value Decomposition
奇异值分解, SVD
```

这些内容在数值计算、图形学、几何处理和数据分析中都会出现.

------

# 5. 不建议按照工程需求从头机械读到尾

如果目标是数学专业课程, 可以按照原书顺序完整学习.

如果目标主要是图形开发, 更适合按照重要程度划分.

建议分为:

```text
A. 核心基础
B. 图形学重要内容
C. 进阶内容
D. 暂时可以跳过
```

------

# 6. 第一阶段: 核心基础

## 6.1 Vector Space: 向量空间

重点:

```text
Vector Space
Subspace
Linear Combination
Span
Linear Independence
Basis
Dimension
```

即:

```text
向量空间
子空间
线性组合
张成
线性无关
基
维数
```

对应本书:

```text
Chapter 1
Chapter 2
```

这是全书最重要的基础.

需要解决一个核心问题:

> 什么东西才是真正意义上的"向量"?

图形开发中经常把:

```text
float3
Vector3
```

直接称为向量.

数学上的"向量"范围要广得多.

例如:

$$

(x,y,z)

$$

可以是向量.

一个多项式:

$$

a+bx+cx^2

$$

也可以被看成向量.

一个函数同样可以属于某个向量空间.

真正重要的不是它是否长得像:

```text
(x,y,z)
```

而是它是否满足向量空间所要求的代数结构.

### 学习目标

完成这一阶段以后, 应该能够解释:

1. 什么是向量空间.
2. 什么是子空间.
3. 什么是线性组合.
4. 什么是张成.
5. 什么是线性无关.
6. 什么是基.
7. 什么是维数.
8. 为什么一个向量本身和它的坐标不是同一个东西.

最后一条尤其重要:

```text
Vector ≠ Coordinates
```

坐标只是向量在指定基下的一组数字表示.

------

# 7. 第二阶段: Linear Map, 线性映射

对应:

```text
Chapter 3
```

这是整本书的核心章节之一.

需要建立:

```text
Vector Space
     ↓
Linear Map
     ↓
Matrix Representation
```

而不是:

```text
Matrix
     ↓
一堆计算规则
```

------

## 7.1 什么是线性映射

一个映射:

$$

T:V\rightarrow W

$$

如果满足:

$$

T(u+v)=T(u)+T(v)

$$

以及:

$$

T(\lambda v)=\lambda T(v)

$$

就是线性映射.

旋转、缩放等大量图形学变换都可以放入这个框架中理解.

------

## 7.2 Null Space 与 Range

需要理解:

```text
Null Space
零空间

Range
值域

Injective
单射

Surjective
满射
```

它们描述的是一个变换:

```text
丢失了哪些信息?
能够到达哪些位置?
是否可以反向恢复?
```

这比单纯判断:

```text
matrix inverse 是否存在
```

更接近问题的本质.

------

## 7.3 Matrix Representation

本书直到建立线性映射以后才正式讨论矩阵.

应该重点理解:

> Matrix represents a linear map with respect to chosen bases.

即:

> 矩阵表示的是某个线性映射在指定基下的表示.

这是以后理解坐标空间转换的基础.

------

# 8. 第三阶段: Change of Basis, 基变换

对应:

```text
Chapter 3D
```

这是图形开发中优先级非常高的内容.

需要理解:

```text
Vector
    ↓
Basis A 下的坐标
    ↓
Change of Basis
    ↓
Basis B 下的坐标
```

图形编程中的:

```text
Object Space
World Space
View Space
Tangent Space
```

都可以从这个角度重新理解.

学习到这里以后, 应重新检查以下工程概念:

```text
Model Matrix
View Matrix
TBN Matrix
LocalToWorld
WorldToLocal
```

重点不再是记住:

```text
应该乘哪个矩阵.
```

而是能够回答:

> 我现在拥有的是哪个空间中的坐标, 我要得到哪个空间中的坐标?

------

# 9. 第四阶段: Dual Space, 对偶空间

对应:

```text
Chapter 3F
```

普通工程教材很少认真讲这一部分.

但它对理解 Normal 非常有价值.

Position 和 Direction 可以自然地视为向量.

Normal 更严格地说具有不同的变换性质.

这也是为什么普通向量通常使用:

$$

v'=Mv

$$

而法线经常需要:

$$

n'=(M^{-1})^Tn

$$

即逆转置矩阵.

只记住:

```text
Normal 使用 inverse transpose
```

可以完成工程工作.

理解 Dual Space 以后, 则可以进一步理解:

> 为什么数学结构本身要求 Normal 具有这种变换方式.

因此对于图形开发, Chapter 3F 并不是无意义的纯理论章节.

------

# 10. 第五阶段: Inner Product Space, 内积空间

对应:

```text
Chapter 6
```

这是另一个必须重点学习的章节.

主要包括:

```text
Inner Product
内积

Norm
范数

Orthogonal
正交

Orthonormal Basis
标准正交基

Gram-Schmidt Procedure
Gram-Schmidt 正交化

Orthogonal Complement
正交补
```

这些概念几乎直接对应图形学中的:

```text
dot()
length()
normalize()
projection
orthogonal basis
TBN
camera basis
```

例如点积并不仅仅是一个 API:

```hlsl
dot(a, b)
```

它来自内积结构.

向量长度:

$$

|v|

$$

也可以由内积定义:

$$

|v|=\sqrt{\langle v,v\rangle}

$$

夹角、投影、正交等概念都由这里统一起来.

------

# 11. 第六阶段: Eigenvalue 与 Eigenvector

对应:

```text
Chapter 5
```

即:

```text
Eigenvalue
特征值

Eigenvector
特征向量
```

定义可以写成:

$$

Tv=\lambda v

$$

含义是:

经过线性变换 $T$ 以后, 向量 $v$ 的方向没有发生根本改变, 只发生了由 $\lambda$ 描述的缩放.

从几何角度可以理解为:

> 寻找一个变换自身所具有的特殊方向.

这类思想会出现在:

- 主方向分析.
- 惯性张量.
- 协方差矩阵.
- Principal Component Analysis, 主成分分析, PCA.
- 几何数据分析.
- 变换分解.
- 物理模拟.

对于实时渲染而言不一定每天直接计算特征值, 但理解它对后续谱定理和 SVD 很重要.

------

# 12. 第七阶段: Spectral Theorem, 谱定理

对应:

```text
Chapter 7B
```

谱定理解决的是一类非常重要的问题:

> 什么情况下一个线性算子能够找到一组非常好的正交基, 从而得到简单的表示?

它把之前学习的:

```text
Eigenvalue
Eigenvector
Orthogonal Basis
Linear Operator
```

连接起来.

因此不建议孤立地记忆谱定理.

正确路线应该是:

```text
向量空间
    ↓
线性映射
    ↓
特征向量
    ↓
内积
    ↓
正交
    ↓
谱定理
```

------

# 13. 第八阶段: SVD, 奇异值分解

对应:

```text
Chapter 7E
Chapter 7F
```

SVD 全称:

**Singular Value Decomposition, 奇异值分解.**

本书第 4 版明确包含线性映射和矩阵形式的 SVD, 以及低维近似等后续内容.

它是非常值得掌握的工具.

SVD 可以粗略理解为将一个复杂线性变换拆解为:

```text
正交变换
    ↓
沿特殊方向缩放
    ↓
正交变换
```

常见形式为:

$$

A=U\Sigma V^*

$$

其中:

```text
U
正交 / 酉部分

Σ
奇异值

V*
另一个正交 / 酉部分
```

SVD 的价值不只是"把矩阵分解".

它实际上是在回答:

> 这个线性变换到底沿哪些方向进行了多大的拉伸?

因此在:

- 几何处理.
- 最小二乘.
- 降维.
- 数据压缩.
- 低秩近似.
- Numerical Robustness.
- Computer Vision.
- 变换分析.

中都非常重要.

------

# 14. 第九阶段: Matrix Factorization

Chapter 7 还包括:

```text
QR Factorization
Cholesky Factorization
```

这些内容更偏数值线性代数.

对于纯 Shader 编写优先级不是最高.

但如果继续进入:

```text
Geometry Processing
Optimization
Simulation
Computer Vision
Numerical Methods
```

它们会逐渐变得重要.

建议至少知道:

```text
它解决什么问题.
输入是什么.
输出是什么.
为什么需要这种分解.
```

第一次学习不要求熟练手算.

------

# 15. 行列式为什么被放到了最后

传统线性代数通常很早介绍:

$$

\det(A)

$$

Axler 则刻意将 Determinant, 即行列式, 放到第 9 章.

这是这本书最著名的特点之一. 官方对本书的介绍也明确指出, 其目标是尽可能通过线性算子的结构建立理论, 将行列式推迟到最后.

这并不意味着行列式没有用.

在图形学中它依然有明显的几何含义.

例如二维:

$$

|\det(A)|

$$

可以描述面积缩放.

三维中可以描述体积缩放.

符号还可以用于判断:

```text
orientation
handedness
reflection
```

例如:

```text
det(M) > 0
```

和:

```text
det(M) < 0
```

意味着变换的 orientation 存在区别.

因此行列式应该学习.

只是没有必要把它当作整个线性代数的中心.

------

# 16. 可以暂时降低优先级的内容

第一次学习时, 以下内容不需要投入同等精力.

## Chapter 4: Polynomials

需要理解它为什么会进入线性算子理论.

但不需要一开始大量投入.

------

## Chapter 5B: Minimal Polynomial

即最小多项式.

对理解线性算子的完整理论有价值, 但对于第一轮图形学学习优先级不高.

------

## Chapter 8: Generalized Eigenvectors 与 Jordan Form

包括:

```text
Generalized Eigenvectors
广义特征向量

Nilpotent Operators
幂零算子

Jordan Form
Jordan 标准形
```

属于进一步研究线性算子结构的内容.

第一次可以降低优先级.

------

## Chapter 9D: Tensor Products

Tensor Product, 即张量积.

这是非常重要的数学结构, 但第一次建立图形学线性代数基础时无需强行掌握.

以后学习:

```text
Tensor
Differential Geometry
Physics
Machine Learning
```

时再深入更合适.

------

# 17. 面向图形开发的推荐学习顺序

不建议简单按照:

```text
1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9
```

平均投入精力.

第一轮建议:

```text
Chapter 1
Vector Spaces
    ↓
Chapter 2
Basis / Dimension
    ↓
Chapter 3A ~ 3D
Linear Maps / Matrix / Change of Basis
    ↓
Chapter 3F
Dual Space
    ↓
Chapter 6
Inner Product Spaces
    ↓
Chapter 5
Eigenvalues / Eigenvectors
    ↓
Chapter 7B
Spectral Theorem
    ↓
Chapter 7E ~ 7F
SVD
```

形成的知识结构为:

```text
向量空间
│
├── 子空间
├── 线性组合
├── 线性无关
├── 基
└── 维数
        │
        ↓
    线性映射
        │
        ├── 零空间
        ├── 值域
        ├── 可逆性
        └── 矩阵表示
                │
                ↓
             基变换
                │
                ├── 坐标空间
                └── 对偶空间
                        │
                        ↓
                    内积空间
                        │
                        ├── 长度
                        ├── 正交
                        ├── 投影
                        └── 正交基
                                │
                                ↓
                         特征值 / 特征向量
                                │
                                ↓
                             谱定理
                                │
                                ↓
                               SVD
```

这可以作为第一轮学习的主干.

------

# 18. 第一轮学习优先级

可以进一步划分为:

## 必须理解

```text
Vector Space
Linear Combination
Span
Linear Independence
Basis
Dimension
Linear Map
Matrix Representation
Invertibility
Change of Basis
Inner Product
Norm
Orthogonal
Orthonormal Basis
Eigenvalue
Eigenvector
```

------

## 强烈建议理解

```text
Null Space
Range
Dual Space
Orthogonal Complement
Gram-Schmidt
Spectral Theorem
SVD
```

------

## 第二轮再深入

```text
Minimal Polynomial
Quotient Space
Generalized Eigenvector
Jordan Form
Multilinear Form
Tensor Product
```

------

# 19. 不建议使用"看完一章"作为学习完成标准

数学书和普通技术文档不同.

作者在学生序言中也明确提醒, 数学不能像小说一样快速连续阅读, 本书强调对定义、定理和证明的深入理解.

因此学习单位应该从:

```text
今天看完 Chapter 2
```

改成:

```text
今天理解 Basis.
```

或者:

```text
今天解决 Change of Basis.
```

------

# 20. 推荐的学习循环

每个概念都采用下面的过程.

```text
1. Definition
   定义

2. Geometric Meaning
   几何意义

3. Simple Example
   简单例子

4. Theorem
   相关定理

5. Why
   为什么成立

6. Graphics Mapping
   与图形学中的概念对应

7. Implementation
   用代码验证
```

例如学习 Basis:

```text
Basis 的数学定义
        ↓
二维空间中的几何直觉
        ↓
为什么坐标必须依赖 Basis
        ↓
Change of Basis
        ↓
Object / World / View Space
        ↓
写一个简单程序验证
```

这样数学概念不会与工程经验割裂.

------

# 21. 学习过程中需要特别避免的问题

## 21.1 不要把向量和坐标混为一谈

必须区分:

```text
Vector
```

与:

```text
Coordinates of Vector
```

这是后续基变换的基础.

------

## 21.2 不要把矩阵当成变换本身

更准确的是:

```text
Linear Map
    ↓
在指定基下
    ↓
Matrix Representation
```

------

## 21.3 不要只记公式

例如:

$$

n'=(M^{-1})^Tn

$$

如果只记住:

```text
Normal 要乘 inverse transpose.
```

那么数学学习并没有真正解决问题.

应该继续追问:

```text
为什么 Position 可以正常变换?
为什么 Normal 不可以?
Normal 到底表示什么?
它必须保持什么关系?
```

------

## 21.4 不要求第一次就能独立证明所有定理

证明应该阅读.

但第一轮的目标不是训练成为纯数学专业学生.

更现实的目标是:

```text
理解定义
    ↓
理解定理说了什么
    ↓
理解证明的大致逻辑
    ↓
知道它与工程中的什么问题有关
```

复杂证明可以在第二轮学习时重新处理.

------

# 22. 配套视频

作者官方网站提供与第 4 版各章节对应的视频和部分配套幻灯片. 官方说明这些视频主要用于提供直觉、动机和章节辅助理解.

因此遇到难以仅通过文字建立直觉的章节时, 可以采用:

```text
先看书中的 Definition
        ↓
看对应视频
        ↓
重新阅读 Definition / Theorem
        ↓
完成几个 Exercise
```

不建议完全用视频替代教材.

------

# 23. 最终学习目标

学习这本书的目标不应该是:

```text
会做更多矩阵题.
```

而应该逐渐完成下面的认识转换.

第一阶段:

```text
矩阵就是用来变换向量的.
```

↓

第二阶段:

```text
矩阵表示一个线性变换.
```

↓

第三阶段:

```text
线性映射独立于矩阵存在.
矩阵只是它在指定基下的表示.
```

↓

第四阶段:

```text
通过选择合适的基,
可以看清线性映射自身的结构.
```

↓

第五阶段:

```text
Eigenvalue
Spectral Theorem
SVD

本质上都在研究:
如何找到合适的方向和表示方式,
使复杂的线性映射变得简单.
```

这才是《Linear Algebra Done Right》最值得学习的部分.

------

# 24. 建议的实际学习计划

第一轮先完成:

```text
阶段 1:
Chapter 1 + Chapter 2

目标:
Vector Space
Basis
Dimension
```

然后:

```text
阶段 2:
Chapter 3A ~ 3D

目标:
Linear Map
Matrix Representation
Change of Basis
```

然后:

```text
阶段 3:
Chapter 3F + Chapter 6

目标:
Dual Space
Inner Product
Orthogonal
Projection
```

然后:

```text
阶段 4:
Chapter 5

目标:
Eigenvalue
Eigenvector
Diagonalization
```

最后:

```text
阶段 5:
Chapter 7B + 7E + 7F

目标:
Spectral Theorem
SVD
```

完成这一轮以后, 再根据实际需要返回:

```text
Chapter 4
Chapter 5B
Chapter 7D
Chapter 8
Chapter 9
```

进行第二轮学习.

------

# 25. 总结

《Linear Algebra Done Right》不应该被当成一本:

> 矩阵计算手册.

它真正适合解决的是:

> 已经接触了大量向量、矩阵和坐标变换以后, 如何建立这些工具背后的统一数学结构.

对于图形开发而言, 最值得建立的核心关系是:

```text
Vector
    ↓
Vector Space
    ↓
Basis
    ↓
Coordinates

Linear Map
    ↓
Matrix Representation
    ↓
Change of Basis

Inner Product
    ↓
Length / Angle / Orthogonal / Projection

Eigenvalue
    ↓
Spectral Theorem
    ↓
SVD
```

学习完成以后, 希望达到的状态不是记住更多公式, 而是面对新的矩阵和空间问题时, 能够判断:

```text
现在讨论的对象是什么?

它属于哪个空间?

当前坐标基是什么?

这个矩阵表示什么映射?

这个映射是否可逆?

它保持了什么?

它破坏了什么?

是否存在更合适的基来观察它?
```

当这些问题能够自然出现时, 线性代数才真正开始从"计算工具"变成理解图形问题的基础语言.
