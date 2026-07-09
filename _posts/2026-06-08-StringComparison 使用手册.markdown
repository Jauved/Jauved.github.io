---
layout: post
title: "StringComparison 使用手册"
categories: [C#, API]
tags: C# API String 比较 性能 StringComparison
math: true


---

# StringComparison 使用手册

## 1. 性能对比

一般情况下, 性能从高到低大致如下:

```text
Ordinal
OrdinalIgnoreCase
InvariantCulture
InvariantCultureIgnoreCase
CurrentCulture
CurrentCultureIgnoreCase
```

说明:

- `Ordinal` 最快, 只按字符编码比较。
- `OrdinalIgnoreCase` 需要额外处理大小写, 但仍然不依赖区域文化, 性能较好。
- `InvariantCulture` / `InvariantCultureIgnoreCase` 使用固定文化规则, 比 `Ordinal` 慢。
- `CurrentCulture` / `CurrentCultureIgnoreCase` 依赖当前系统或线程文化规则, 通常最慢。

------

## 2. 实际使用建议

### 2.1 程序内部标识符, Key, 配置项

推荐:

```csharp
StringComparison.Ordinal
StringComparison.OrdinalIgnoreCase
```

适用场景:

- 配置 Key
- Shader 属性名
- 文件扩展名
- 字典 Key
- 协议字段
- 内部枚举字符串
- 路径片段匹配
- Unity 对象命名规则匹配

建议:

```csharp
string.Equals(a, b, StringComparison.Ordinal)
```

或:

```csharp
string.Equals(a, b, StringComparison.OrdinalIgnoreCase)
```

如果业务不需要语言文化规则, 优先使用 `Ordinal` 系列。

------

### 2.2 面向用户显示文本的搜索和排序

推荐:

```csharp
StringComparison.CurrentCulture
StringComparison.CurrentCultureIgnoreCase
```

适用场景:

- 用户输入搜索
- UI 文本排序
- 本地化文本比较
- 需要符合用户语言习惯的字符串处理

注意:

`CurrentCulture` 会受到当前系统语言环境影响。不同语言环境下, 比较结果可能不同。

------

### 2.3 需要固定文化规则, 但不是纯编码比较

推荐:

```csharp
StringComparison.InvariantCulture
StringComparison.InvariantCultureIgnoreCase
```

适用场景:

- 跨区域数据处理
- 固定规则的文本比较
- 不希望受用户系统语言影响, 但又需要文化感知比较

注意:

`InvariantCulture` 不是最高性能选择。若只是比较程序内部 Key, 通常仍应优先使用 `Ordinal`。

------

## 3. 参数说明

## 3.1 Ordinal

```csharp
StringComparison.Ordinal
```

含义:

按字符的 Unicode 编码值直接比较。

特点:

- 区分大小写。
- 不考虑任何语言文化规则。
- 结果稳定, 不受系统语言影响。
- 性能最好。

示例:

```csharp
string.Equals("Alpha", "alpha", StringComparison.Ordinal); // false
```

适合:

- 程序内部标识符
- Key
- 路径
- Shader 属性名
- 文件扩展名
- 协议字段

------

## 3.2 OrdinalIgnoreCase

```csharp
StringComparison.OrdinalIgnoreCase
```

含义:

忽略大小写, 但仍然按 Unicode 编码规则比较。

特点:

- 不区分大小写。
- 不考虑当前语言文化。
- 结果稳定。
- 性能较好。

示例:

```csharp
string.Equals("Alpha", "alpha", StringComparison.OrdinalIgnoreCase); // true
```

适合:

- 不区分大小写的内部 Key
- 文件扩展名比较
- 命令字符串
- 标签字符串
- 稳定的工具逻辑

推荐示例:

```csharp
if (name.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
{
    // ...
}
```

------

## 3.3 CurrentCulture

```csharp
StringComparison.CurrentCulture
```

含义:

使用当前线程或系统文化规则进行比较。

特点:

- 区分大小写。
- 受当前语言环境影响。
- 适合用户可见文本。
- 不适合程序内部 Key。

示例:

```csharp
string.Equals(a, b, StringComparison.CurrentCulture);
```

适合:

- UI 文本
- 用户输入
- 本地化文本排序
- 需要符合当前语言习惯的比较

------

## 3.4 CurrentCultureIgnoreCase

```csharp
StringComparison.CurrentCultureIgnoreCase
```

含义:

使用当前文化规则进行比较, 并忽略大小写。

特点:

- 不区分大小写。
- 受当前语言环境影响。
- 在不同语言环境下结果可能不同。

示例:

```csharp
string.Equals(a, b, StringComparison.CurrentCultureIgnoreCase);
```

适合:

- 用户输入搜索
- UI 文本匹配
- 本地化文本比较

注意:

土耳其语等语言对大小写有特殊规则。使用该方式时, `"i"` 和 `"I"` 的比较结果可能与英语环境不同。

------

## 3.5 InvariantCulture

```csharp
StringComparison.InvariantCulture
```

含义:

使用固定的、不随用户系统语言变化的文化规则进行比较。

特点:

- 区分大小写。
- 不受当前系统语言影响。
- 比 `Ordinal` 更偏向语言规则。
- 性能低于 `Ordinal`。

示例:

```csharp
string.Equals(a, b, StringComparison.InvariantCulture);
```

适合:

- 需要固定文化规则的文本处理
- 跨区域但仍需要文化感知的比较

不推荐用于:

- 内部 Key
- Shader 属性名
- 协议字段
- 配置字段

这些场景通常应使用 `Ordinal`。

------

## 3.6 InvariantCultureIgnoreCase

```csharp
StringComparison.InvariantCultureIgnoreCase
```

含义:

使用固定文化规则进行比较, 并忽略大小写。

特点:

- 不区分大小写。
- 不受当前系统语言影响。
- 比 `OrdinalIgnoreCase` 更偏向语言规则。
- 性能低于 `OrdinalIgnoreCase`。

示例:

```csharp
string.Equals(a, b, StringComparison.InvariantCultureIgnoreCase);
```

适合:

- 需要固定文化规则, 且忽略大小写的文本比较。
- 不希望比较结果受用户语言环境影响的文化感知文本处理。

------

## 4. 快速选择表

| 场景                                      | 推荐值                       |
| ----------------------------------------- | ---------------------------- |
| 内部 Key, 标识符, Shader 属性名, 协议字段 | `Ordinal`                    |
| 内部 Key, 但忽略大小写                    | `OrdinalIgnoreCase`          |
| 用户可见文本比较                          | `CurrentCulture`             |
| 用户可见文本比较, 忽略大小写              | `CurrentCultureIgnoreCase`   |
| 固定文化规则比较                          | `InvariantCulture`           |
| 固定文化规则比较, 忽略大小写              | `InvariantCultureIgnoreCase` |

------

## 5. 常用代码示例

### 5.1 精确比较内部字符串

```csharp
if (string.Equals(propertyName, "_BaseColor", StringComparison.Ordinal))
{
    // ...
}
```

### 5.2 忽略大小写比较扩展名

```csharp
if (path.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
{
    // ...
}
```

### 5.3 用户输入搜索

```csharp
if (displayName.Contains(keyword, StringComparison.CurrentCultureIgnoreCase))
{
    // ...
}
```

------

## 6. 总结

优先级建议:

```text
程序内部逻辑: Ordinal / OrdinalIgnoreCase
用户可见文本: CurrentCulture / CurrentCultureIgnoreCase
固定文化规则: InvariantCulture / InvariantCultureIgnoreCase
```

工程中最常用的选择通常是:

```csharp
StringComparison.Ordinal
StringComparison.OrdinalIgnoreCase
```

除非明确需要用户语言文化规则, 否则不要默认使用 `CurrentCulture`。
