---
layout: post
title: "Voronoi Fragmentation of a Mesh: 基于 Voronoi 的网格破碎"
categories: [图形学, 几何处理]
tags: Voronoi MeshFracture Geometry Polygon Triangulation
math: true


---

# Voronoi Fragmentation of a Mesh: 基于 Voronoi 的网格破碎

[Voronoi Fragmentation of a Mesh](https://www.4rknova.com/blog/2026/07/27/voronoi-fracture)

---

## 1. 结论

文章实现了一套基于 Voronoi Diagram 的 Mesh Fracture 算法.

基本思路不是直接构建完整的 Voronoi Diagram, 而是把每个 Voronoi Cell 表示为一组 Half-Space 的交集:

```text
Input Convex Mesh
↓
Generate Seeds
↓
根据 Seed 两两构造分割平面
↓
连续 Plane Clip
↓
得到一个 Voronoi Cell
↓
对所有 Seed 重复
↓
生成全部 Fragments
```

实现成立的关键前提:

```text
输入 Mesh 必须是 Convex.
```

文章中最重要的工程设计是:

```text
Mesh
↓
Convex Polygon Solid
↓
在 Polygon 层完成所有几何处理
↓
Triangulate
↓
GPU Mesh
```

即:

> Triangle 是最终输出格式, 而不是主要的几何计算数据结构.

------

## 2. Voronoi Cell 如何转化为 Plane Clipping

设两个 Seed:

$s\_i,\ s\_j$

属于 $s\_i$ 的空间位置满足:

$\|x-s\_i\|\leq\|x-s\_j\|$

展开后可以得到一个线性不等式:

$n\cdot x+d\leq0$

它表示一个 Half-Space.

边界平面就是:

```text
Seed i
    │
    │
----┼---- Perpendicular Bisector Plane
    │
    │
Seed j
```

因此一个 Voronoi Cell 可以表示为:

$V\_i = H\_{i0} \cap H\_{i1} \cap H\_{i2} \cap\cdots$

也就是说:

> 一个 Seed 对应的 Voronoi Cell, 就是它相对于其他所有 Seed 的 Half-Space 的交集.

所以并不需要先显式构建一个完整 Voronoi Diagram.

只需要不断执行:

```text
Current Solid
↓
Plane Clip
↓
Current Solid
↓
Plane Clip
↓
...
```

最终剩余几何就是该 Seed 的 Fragment.

------

## 3. 几何处理中保持 Polygon

文章没有直接对 Triangle Soup 做所有操作.

内部结构类似:

```text
Solid
├── Face
│   ├── Vertex
│   ├── Vertex
│   └── ...
├── Face
└── ...
```

每个 Face 仍然是一个 Convex Polygon.

这样 Plane Clipping 后可以直接得到新的 Polygon Face.

如果一开始就使用 Triangle:

```text
Triangle
Triangle
Triangle
↓
Plane Cut
↓
大量 Cut Segment
↓
Endpoint Matching
↓
重新 Stitch Loop
```

后续就需要处理:

```text
Segment Matching
Topology Reconstruction
Epsilon
Gap
Winding
```

保持 Polygon 后, 问题会简单很多.

------

## 4. Plane Clip

对于 Polygon 上的每一条边:

```text
A → B
```

根据 A、B 相对于 Plane 的位置, 处理四种情况:

```text
Inside → Inside
保留 B

Inside → Outside
保留 Intersection

Outside → Inside
保留 Intersection + B

Outside → Outside
什么都不保留
```

本质上类似 Sutherland-Hodgman Polygon Clipping.

裁剪完成后得到新的 Face.

------

## 5. Cut 后必须生成 Cap

Plane 切开 Solid 后会产生新的截面.

例如:

```text
Cube
↓
Plane Cut
↓
原有 Face 被裁剪
+
出现开放截面
```

如果不生成新的 Face:

```text
Solid → Open Mesh
```

所以需要生成 Cap.

文章的方法是:

```text
遍历被切 Face
↓
记录 Crossing Points
↓
去重
↓
求截面中心
↓
建立 Plane 局部坐标系
↓
atan2 计算角度
↓
排序
↓
构造 Polygon Loop
↓
生成 Cap Face
```

这里依赖了一个非常重要的性质:

> Convex Solid 和 Plane 的交集只能得到一个 Convex Polygon.

因此所有 Crossing Points 一定属于同一个 Loop.

这也是算法要求输入为 Convex Mesh 的主要原因之一.

------

## 6. Fracture Surface

文章将 Face 分为两类:

```text
Surface
Fracture
```

原始 Mesh 上的 Face:

```text
Surface
```

Plane Clip 生成的新 Cap:

```text
Fracture
```

原始 Surface 即使之后再次被裁剪, 类型也保持不变.

因此最终可以区分:

```text
Original Surface
→ 使用原材质

Fracture Surface
→ 使用内部破碎材质
```

例如:

```text
陶瓷外表面
→ 光滑釉面

断裂内部
→ 粗糙陶瓷
```

这一 Tag 同时也非常适合 Debug.

------

## 7. 最后再 Triangulate

所有 Plane Clipping 完成后, 每个 Fragment 由多个 Convex Polygon Face 组成.

最后才进行:

```text
Polygon
↓
Triangle
```

因为 Polygon 是 Convex, 可以直接使用 Triangle Fan:

```text
v0, v1, v2
v0, v2, v3
v0, v3, v4
...
```

不需要复杂的 Polygon Triangulation.

最终再生成:

```text
Vertex Buffer
Index Buffer
```

供 GPU 使用.

------

## 8. Seed Distribution 决定破碎风格

如果 Seed 完全 Uniform Random:

```text
*       *
    *
        *
  *          *
```

最终 Fragment 的尺寸比较均匀.

视觉上更像:

```text
空间分区
```

而不像撞击破碎.

撞击情况下通常希望:

```text
Impact
↓
附近 Seed 密集
↓
小 Fragment

远处 Seed 稀疏
↓
大 Fragment
```

因此文章使用了距离 Impact Point 的概率 Falloff.

大致可以理解为:

$P(r)\propto(1-r)^k$

文章实验了不同 Falloff, 最终选择较强的非线性分布.

这样无需修改 Fracture Algorithm 本身, 只改变 Seed Distribution 就可以改变最终视觉效果.

------

## 9. 正确性验证

文章没有只依赖视觉判断, 而是设计了多个 Geometry Invariant.

## 9.1 Closed Mesh

每条 Edge 应该被恰好两个 Face 使用.

如果不是:

```text
1 次
→ Hole

>2 次
→ Duplicate / Non-Manifold
```

------

## 9.2 Volume Conservation

所有 Fragment 总体积应该近似等于原始 Mesh:

$\sum\_iV\_i\approx V\_{original}$

如果:

```text
Fragment Volume < Original
→ Geometry Lost

Fragment Volume > Original
→ Geometry Overlap
```

体积通过 Triangle Mesh 与 Divergence Theorem 计算.

------

## 9.3 Voronoi Ownership

每个 Fragment 的位置应该满足:

```text
距离自己的 Seed
<
距离其他 Seed
```

可以使用 Fragment Centroid 做检查.

这样可以直接验证输出是否仍满足 Voronoi 定义.

------

## 10. 性能

直接实现需要让每个 Seed 和其他 Seed 比较:

$O(N^2)$

例如 120 Seeds:

$120\times119=14280$

个潜在 Plane.

文章使用两个简单优化.

### 10.1 Plane Rejection

在真正执行 Polygon Clip 之前, 先检查当前 Cell 是否完全位于 Plane 的保留侧.

如果是:

```text
Plane 与当前 Cell 不相交
↓
Skip
```

无需执行真正的 Clip.

------

### 10.2 Near Seeds First

优先处理距离当前 Seed 最近的 Seed.

原因:

```text
Nearest Plane
↓
快速缩小 Cell

Cell 越小
↓
后续更多远处 Plane 无法相交

↓
大量 Skip
```

文章的测试中, 大部分候选 Plane 最终都可以直接跳过.

因此虽然理论复杂度仍然是 $O(N^2)$, 实际几何操作数量会显著下降.

------

## 11. Convex 限制

当前方法无法直接处理任意 Concave Mesh.

对于 Concave Geometry, 一个 Plane 的截面可能出现:

```text
Loop A

+

Loop B
```

甚至更多独立区域.

此时:

```text
收集 Crossing Points
↓
按角度排序
↓
生成一个 Polygon
```

就不再成立.

算法可能错误地把多个独立截面连接起来.

因此当前实现要求:

```text
Input Mesh
=
Convex Solid
```

如果需要支持 Concave Mesh, 通常需要:

```text
方案 A
Concave Mesh
↓
Convex Decomposition
↓
对每个 Convex Piece 进行 Fracture
```

或者使用更完整的:

```text
Mesh Boolean
CSG
BSP
```

系统.

------

## 12. 这不是完整的物理破碎系统

文章实现的是:

```text
Geometry Fracture
```

而不是完整的:

```text
Physics Destruction
```

Demo 中 Fragment 飞散主要是简单的:

```text
Velocity
Gravity
Floor Bounce
```

没有完整处理:

```text
Rigid Body Contact
Shard-Shard Collision
Constraint
Structural Connectivity
```

真实游戏系统通常应该是:

```text
Voronoi Fracture
↓
Shard Mesh
↓
Convex Collider
↓
Rigidbody
↓
Physics Engine
```

这里 Voronoi Fragment 有一个天然优势:

> 每个 Cell 本身就是 Convex Polyhedron.

因此非常适合作为 Convex Collider.

------

## 13. 工程上最值得关注的部分

这篇文章真正值得借鉴的不只是 Voronoi.

更重要的是几个通用设计原则.

### 13.1 将数学问题转换为简单 Primitive

Voronoi Cell:

```text
复杂空间划分
```

被转换为:

```text
Half-Space Intersection
```

最终只需要一个稳定的 Plane Clip Primitive.

------

### 13.2 不要过早 Triangulate

```text
Polygon Geometry
↓
完成算法
↓
Triangulate
```

比:

```text
Triangle
↓
处理复杂拓扑
```

简单很多.

------

### 13.3 利用问题约束降低复杂度

要求:

```text
Convex Input
```

看起来限制了功能.

但它换来了:

```text
单一截面 Loop
简单 Cap
简单 Triangulation
简单 Collider
```

从而显著降低整个系统复杂度.

------

### 13.4 建立 Geometry Invariant

不要只判断:

```text
看起来是否正确
```

还应该验证:

```text
Closed
Volume Conservation
Ownership
```

这是几何算法非常值得采用的 Debug 方法.

------

## 14. 整体流程

完整流程可以概括为:

```text
Input Convex Mesh
│
▼
Convert To Polygon Solid
│
▼
Generate Seeds
│
▼
For Each Seed
│
├── Find Other Seeds
│
├── Sort Near → Far
│
├── Build Bisector Plane
│
├── Plane Reject
│
└── Polygon Clip
│       │
│       └── Generate Cap
│
▼
Voronoi Fragment
│
▼
Triangulate Faces
│
▼
Generate Vertex / Index
│
▼
GPU Mesh
```

------

## 15. 核心结论

文章最终展示的是一套非常简洁的 Voronoi Fracture 实现:

```text
Voronoi
↓
Half-Space
↓
Plane Clipping
↓
Convex Polygon Solid
↓
Triangulation
```

其核心工程思想可以概括为:

> 先为几何算法选择适合的中间表示, 完成几何计算之后, 再转换为 GPU 所需要的 Triangle Mesh.

这个设计比直接在 Triangle Soup 上解决所有几何问题更加简单、稳定, 也更容易验证.
