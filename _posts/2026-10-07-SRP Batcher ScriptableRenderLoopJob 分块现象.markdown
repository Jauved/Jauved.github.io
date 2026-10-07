---
layout: post
title: "SRP Batcher ScriptableRenderLoopJob 分块现象"
categories: [Unity, URP, Performance]
tags: Unity URP SRPBatcher ScriptableRenderLoopJob Performance 243
math: false


---

# SRP Batcher ScriptableRenderLoopJob 分块现象

# W - What

开启 SRP Batcher 后, 当参与渲染的对象数量增加到一定程度时, `ScriptableRenderLoopJob` 会被拆分为多个 Job.

当前测试中:

- 253 以下时, 没有观察到拆分.
- 254 时开始拆分为 `128 + 126`.
- 数量继续增加后, Unity 会继续增加 LoopJob 数量.
- 拆分后并不是固定大小切块, 而是倾向于将工作近似均匀地分配到多个 LoopJob.

因此这个现象更接近 **Scriptable Render Loop 内部的 Job 分块行为**, 而不是 SRP Batcher 最多只能处理约 250 个 Mesh.

# I - Insight

当前测试结果:

| 测试数量 | LoopJob 分布          |
| -------- | --------------------- |
| < 253    | 原数量                |
| 254      | 128 + 126             |
| 300      | 151 + 149             |
| 400      | 201 + 199             |
| 500      | 251 + 249             |
| 600      | 201 + 201 + 198       |
| 700      | 234 + 234 + 232       |
| 800      | 201 + 201 + 201 + 197 |

从数据可以看到, Unity 并不是简单按照某个固定长度连续切块.

例如 600 个对象没有表现为:

```
253 + 253 + 94
```

而是:

```
201 + 201 + 198
```

800 个对象则表现为:

```
201 + 201 + 201 + 197
```

因此目前可以认为:

```
总工作量增加
    ↓
增加 ScriptableRenderLoopJob 数量
    ↓
将工作近似均匀分配到多个 Job
```

具体分块单位是 Mesh、Renderer、Render Node 还是其他内部渲染数据, 当前尚未确认.

# S - System

目前没有更多测试数据, Unity / Tuanjie 官方文档中也没有找到关于这一分块数量及算法的明确说明.

因此暂时无法进一步确认其内部调度机制.

# E - Evidence

目前没有发现与上述数值规律直接对应的其他公开测试记录或官方参考文档.
