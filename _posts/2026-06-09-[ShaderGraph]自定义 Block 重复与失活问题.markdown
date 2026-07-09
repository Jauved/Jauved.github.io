---
layout: post
title: "[ShaderGraph]自定义 Block 重复与失活问题"
categories: [URP, ShaderGraph]
tags: URP ShaderGraph 定制 自定义 BlockFieldDescriptor
math: true


---

# [ShaderGraph]自定义 Block 重复与失活问题

## 问题现象

自定义 Block：

```
Cross Section Color
```

在重新打开 ShaderGraph 后：

- Block 显示为灰色（Inactive）
- 再次启用功能时，会新增一个同名且激活的 Block
- 最终出现两个名称相同的 Block

## 根因

问题出在 `BlockFieldDescriptor` 的 `referenceName`。

例如：

```
new BlockFieldDescriptor(
    name,
    "CrossSectionColorFern",
    "Cross Section Color",
    ...
);
```

其中：

```
"CrossSectionColorFern"
```

即 `referenceName`。

ShaderGraph 在序列化和反序列化时使用 `referenceName` 作为 Block 的唯一标识，而不是 `displayName`。

如果两个 Block 使用相同的 `referenceName`：

- Graph 恢复时可能关联到错误的 Block 定义
- UI 中出现同名但不同实例的 Block
- `activeBlockDescriptors.Contains(descriptor)` 判断失败
- 导致旧 Block 灰掉，同时生成新的激活 Block

## 解决方案

确保所有自定义 Block 的 `referenceName` 全工程唯一。

例如：

```c#
new BlockFieldDescriptor(
    name,
    "Fern_CrossSectionColor",
    "Cross Section Color",
    ...
);
```

## 结论

`displayName` 可以重复。

`referenceName` 必须唯一。

对于 ShaderGraph 自定义 Block，`referenceName` 应视为序列化层面的唯一 ID，不应与任何其它 Block 重名。
