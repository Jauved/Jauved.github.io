---
layout: post
title: "从 Voronoi Fragmentation 到 HeartbeatCurve: 延迟三角化的几何架构"
categories: [Unity, 图形学]
tags: Unity HeartbeatCurve Geometry Polygon Tessellation Mesh
math: true


---

# 从 Voronoi Fragmentation 到 HeartbeatCurve: 延迟三角化的几何架构

本文是对以下文章中几何架构思想的进一步延伸:

[Voronoi Fragmentation of a Mesh](https://www.4rknova.com/blog/2026/07/27/voronoi-fracture)

原文讨论的是 Voronoi Mesh Fracture. 本文不讨论破碎算法本身, 而是提取其中的 "延迟三角化" 思路, 用于分析 HeartbeatCurve 的重构方向.

------

## 1. 结论

Voronoi Fragmentation 中有一个可以独立于 Voronoi 算法存在的工程设计原则:

```text
Problem Data
↓
适合算法的 Geometry Representation
↓
完成几何算法
↓
Triangulate
↓
GPU Mesh
```

即:

> 不要因为 GPU 最终需要 Triangle, 就让整个几何算法从一开始都工作在 Triangle 层.

这一原则可以直接用于 HeartbeatCurve 的重构.

当前 HeartbeatCurve 更适合从:

```text
Data
↓
Curve
↓
Triangle Mesh
↓
在 Triangle 层处理转角和异常
```

重构为:

```text
Data
↓
Curve
↓
Centerline
↓
Polygonal Ribbon Geometry
↓
Segment / Join / Cap / Boundary
↓
Triangulate
↓
Unity Mesh
```

------

## 2. 当前问题的本质

HeartbeatCurve 的最终结果是一条有宽度的曲线.

如果在获得 Centerline 后立即生成 Triangle:

```text
P0 → P1
P1 → P2
```

每一个 Segment 可以独立生成 Quad.

但问题会集中出现在:

```text
P1
```

因为相邻 Segment 的宽度边界需要正确连接.

因此出现的:

```text
转角缺口
补三角形
扇形补面
锐角异常
Triangle Overlap
短 Segment 异常
```

表面看是 Mesh Bug, 实际属于:

```text
Stroke Geometry
```

问题.

------

## 3. 推荐中间表示

HeartbeatCurve 不适合像 Voronoi 一样把整条几何表示成一个 Convex Polygon.

整条 Ribbon 可以是 Concave, 甚至可能 Self-Intersect.

因此更合理的是:

```text
Centerline
↓
Polygonal Ribbon Geometry
```

并保持局部 Primitive 尽量简单:

```text
Straight Segment
→ Convex Quad

Bevel Join
→ Convex Polygon

Round Join
→ Convex Polygon / Sector

Cap
→ Simple Polygon
```

即:

> 不要求整个 Ribbon 是 Convex, 但让局部几何尽量保持简单、明确、可验证.

------

## 4. 推荐架构

```text
Heartbeat Data
│
▼
Curve Sampling
│
├── Real Point
├── Insert Point
└── Visual Step
│
▼
Centerline
│
▼
Stroke Geometry Builder
│
├── Segment
├── Join
├── Cap
└── Boundary Validation
│
▼
Polygonal Ribbon Geometry
│
▼
Tessellator
│
▼
Vertex + Index
│
▼
Unity Mesh
```

最重要的职责边界:

```text
Stroke Geometry Builder
≠
Tessellator
```

前者回答:

```text
曲线几何应该是什么形状?
```

后者只回答:

```text
如何把这个几何表示成 Triangle?
```

------

## 5. Curve Layer

Curve Layer 只负责 Centerline.

例如:

```text
P0
P1
P2
P3
...
```

负责:

```text
Real Data
Smooth Insert
Time Sampling
Hermite / Catmull-Rom
visualStepTime
```

这一层不应该知道:

```text
Triangle
Index
MeshTopology
```

------

## 6. Stroke Geometry Layer

对于 Centerline Point:

$P\_i$

根据曲线方向和宽度求:

```text
Li = Left Boundary
Ri = Right Boundary
```

一个普通 Segment 可以先表示为:

```text
L0 -------- L1
|            |
|            |
R0 -------- R1
```

即:

```text
Convex Quad
```

此时仍然不生成 Triangle.

------

## 7. Join

过去的 "转角补面" 应升级为正式的 Join Geometry.

常见类型:

```text
Miter Join
Bevel Join
Round Join
```

### Miter Join

让两侧 Offset Boundary 相交.

优点:

```text
轮廓锐利
```

问题:

```text
锐角时 Miter Length 急剧增加
```

因此需要:

```text
Miter Limit
```

超过限制时退化为 Bevel.

### Bevel Join

直接截断尖角.

优点:

```text
稳定
简单
几何数量少
```

适合作为异常情况的默认 fallback.

### Round Join

生成圆弧近似.

当前 HeartbeatCurve 中的 "扇形补面" 可以重新定义为:

```text
Round Join Geometry
```

区别在于:

```text
旧结构:

Triangle 出现缺口
↓
补 Triangle
```

变成:

```text
新结构:

Corner
↓
生成合法 Round Join Polygon
↓
最后 Triangulate
```

------

## 8. Cap

曲线头尾同样应该成为正式 Geometry Primitive:

```text
Butt Cap
Square Cap
Round Cap
```

而不是在 Triangle 生成代码中加入特殊情况.

因此 Stroke Geometry 的基本组成可以明确为:

```text
Segment
Join
Cap
```

------

## 9. Tessellator

Tessellator 只负责:

```text
Polygon
↓
Triangle
```

它可以处理:

```text
Vertex Output
Index Output
UV
Color
Winding
```

但原则上不应该包含:

```text
if corner broken...
if curve point outside...
if previous triangle overlap...
```

这些都应该在 Stroke Geometry Layer 解决.

------

## 10. Debug 层级

重构后建议允许分别显示:

```text
1. Centerline
2. Left / Right Boundary
3. Segment Polygon
4. Join Polygon
5. Cap Polygon
6. Final Triangle
```

Debug 顺序:

```text
Centerline
↓
Boundary
↓
Polygon
↓
Triangle
```

如果 Boundary 已经错误:

```text
无需继续调查 Triangle
```

如果 Polygon 正确而 Triangle 错误:

```text
问题一定在 Tessellator
```

------

## 11. 原有问题重新分类

| 当前现象              | 新架构中的问题               |
| --------------------- | ---------------------------- |
| 转角缺口              | Join Generation              |
| 扇形补面              | Round Join                   |
| 尖角异常              | Miter Limit                  |
| 短 Segment            | Degenerate Segment           |
| 左右翻转              | Boundary Orientation         |
| Mesh 重叠             | Boundary Intersection        |
| 点落到 Mesh 外        | Offset Boundary Error        |
| 残留 Triangle         | Geometry Lifecycle / Rebuild |
| Triangle Winding 错误 | Tessellation                 |

这样可以把大量 HeartbeatCurve 专用 Bug 转换成标准几何问题.

------

## 12. 重构顺序

不建议直接替换当前实现.

可以保留旧 Builder 作为 Reference:

```text
HeartbeatCurve

├── Existing Mesh Builder
│   └── Reference
│
└── New Geometry Pipeline
```

第一阶段只实现:

```text
Straight Segment
Bevel Join
Butt Cap
```

第二阶段增加:

```text
Round Join
Miter Join
Miter Limit
```

第三阶段再接入:

```text
Smooth Insert
visualStepTime
动态数据更新
```

这样可以把 Geometry Architecture 和 Dynamic Lifecycle 分开验证.

------

## 13. 推荐 Invariant

### Curve

```text
Point 顺序正确.
不存在非法重复点.
不存在无意义 Degenerate Segment.
```

### Stroke

```text
每个有效 Segment 都有合法 Left / Right Boundary.
Boundary Orientation 一致.
```

### Join

```text
相邻 Segment 不出现 Gap.
Join 不产生无限长 Geometry.
```

### Polygon

```text
Vertex 顺序一致.
Area > epsilon.
```

### Tessellation

```text
Triangle Winding 一致.
无 Degenerate Triangle.
Index 不越界.
```

------

## 14. 推荐最终架构

```text
HeartbeatCurve
│
├── Data Layer
│   └── Heartbeat Samples
│
├── Curve Layer
│   ├── Real Points
│   ├── Insert Points
│   └── Centerline
│
├── Stroke Geometry Layer
│   ├── Segment Builder
│   ├── Join Builder
│   ├── Cap Builder
│   └── Boundary Validation
│
├── Tessellation Layer
│   └── Polygon → Triangle
│
└── Render Layer
    ├── Vertex Buffer
    ├── Index Buffer
    └── Unity Mesh
```

依赖方向保持:

```text
Data
↓
Curve
↓
Stroke Geometry
↓
Tessellation
↓
Render
```

------

## 15. 核心原则

Voronoi Fragmentation 中的:

```text
Convex Polygon Solid
↓
Triangulate
```

对应到 HeartbeatCurve 应该变成:

```text
Centerline
↓
Polygonal Ribbon Geometry
↓
Triangulate
```

真正需要改变的不是某一种 "补三角形" 算法, 而是:

> 将几何问题从 Triangle 层提升到 Geometry 层解决.

最终 Triangle 只作为 GPU Mesh 的编码形式, 不再承担曲线拓扑和轮廓逻辑.

------

## 参考来源

- 4rknova, [Voronoi Fragmentation of a Mesh](https://www.4rknova.com/blog/2026/07/27/voronoi-fracture), 2026-07-27.
