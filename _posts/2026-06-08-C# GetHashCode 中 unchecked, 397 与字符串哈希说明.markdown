---
layout: post
title: "C# GetHashCode 中 unchecked, 397 与字符串哈希说明"
categories: [C#, API]
tags: C# API HashCode unchecked 字符串 String GetHashCode
math: true


---

# C# GetHashCode 中 unchecked, 397 与字符串哈希说明

## 1. 使用建议

在自定义 `GetHashCode()` 时, 推荐优先使用以下两种方式之一:

### 1.1 优先方案: `HashCode.Combine`

如果项目环境支持 `System.HashCode`, 推荐使用:

```csharp
public override int GetHashCode()
{
    return HashCode.Combine(Renderer, SlotIndex, _labelHash);
}
```

优点:

- 不需要手动选择乘数。
- 不需要显式处理整数溢出。
- 可读性更好。
- 降低手写哈希组合逻辑出错的概率。

### 1.2 兼容方案: 手写哈希组合

如果需要兼容旧环境, 或者希望保持当前写法, 可以使用:

```csharp
public override int GetHashCode()
{
    unchecked
    {
        int hash = (Renderer?.GetHashCode() ?? 0) * 397 ^ SlotIndex;
        hash = (hash * 397) ^ _labelHash;
        return hash;
    }
}
```

这种写法在 Unity 项目中较常见, 适合简单稳定的哈希组合场景。

------

## 2. `unchecked` 的作用

`unchecked` 用于关闭整数溢出检查。

在下面的代码中:

```csharp
unchecked
{
    int hash = (Renderer?.GetHashCode() ?? 0) * 397 ^ SlotIndex;
    hash = (hash * 397) ^ _labelHash;
    return hash;
}
```

`hash * 397` 很容易超过 `int` 的取值范围。

`int` 的范围是:

```text
-2147483648 到 2147483647
```

如果开启溢出检查, 乘法结果超过范围时可能抛出 `OverflowException`。

而在 `unchecked` 中, 即使发生溢出, 也不会抛异常。结果会按照二进制补码规则自动截断, 继续参与后续计算。

------

## 3. 为什么 `GetHashCode()` 中通常允许溢出

哈希计算的目标不是保留数学上的精确乘法结果, 而是尽量把多个字段的信息混合到一个 `int` 中。

因此, 在哈希计算中:

```csharp
hash = hash * 397;
```

发生整数溢出通常不是错误。

溢出后的二进制截断结果仍然可以作为新的哈希值继续使用, 并且这种“环绕”效果有助于位混合。

所以, `GetHashCode()` 中显式使用 `unchecked` 是一种常见写法, 目的是保证哈希计算不会因为溢出而中断。

------

## 4. 为什么使用 397

`397` 是一个素数。

在哈希组合中, 常见模式是:

```csharp
hash = hash * prime ^ nextFieldHash;
```

这里的 `prime` 通常选择素数, 例如:

```text
31, 397, 486187739
```

使用素数的原因是:

- 减少不同字段组合后产生相同哈希值的概率。
- 避免与常见字段值形成简单倍数关系。
- 让参与计算的字段在二进制位上混合得更充分。

`397` 并不是唯一正确的值。它更多是 C# / .NET 社区中较常见的经验值, 尤其常见于 ReSharper 生成的 `GetHashCode()` 模板。

------

## 5. 397 是否必须使用

不是必须。

下面这些写法本质上都属于类似思路:

```csharp
hash = hash * 31 ^ fieldHash;
hash = hash * 397 ^ fieldHash;
hash = hash * 486187739 ^ fieldHash;
```

关键点不是一定要用 `397`, 而是:

- 使用一个合适的非零常数。
- 通常选择素数。
- 保证字段能参与充分混合。
- 保持 `Equals()` 和 `GetHashCode()` 的字段依据一致。

如果没有特殊需求, 继续使用 `397` 没有问题。

如果项目环境支持, 更推荐使用:

```csharp
HashCode.Combine(...)
```

------

## 6. `StringComparer.Ordinal.GetHashCode(label)` 是否稳定

对于同一个字符串内容:

```csharp
StringComparer.Ordinal.GetHashCode(label)
```

在同一个程序运行期间, 返回值是稳定的。

也就是说, 只要 `label` 的内容完全一致, 在同一进程内多次调用会得到相同的 `int` 哈希值。

例如:

```csharp
string a = "Door_LF";
string b = "Door_LF";

int hashA = StringComparer.Ordinal.GetHashCode(a);
int hashB = StringComparer.Ordinal.GetHashCode(b);

// 同一进程内, hashA == hashB
```

------

## 7. 字符串哈希的跨进程注意事项

不要把 `StringComparer.Ordinal.GetHashCode(label)` 的结果当作“永久稳定 ID”。

在某些 .NET 运行时中, 字符串哈希可能带有随机化种子。

这意味着:

- 同一进程内: 相同字符串通常得到相同哈希。
- 不同程序启动之间: 相同字符串不一定得到相同哈希。
- 不同运行时之间: 相同字符串也不保证得到相同哈希。
- 不同平台之间: 也不应依赖其结果完全一致。

所以, 字符串哈希适合用于:

- 字典 key 的哈希。
- HashSet 内部查找。
- 当前运行期间的临时快速比较。
- 自定义 `GetHashCode()` 的字段组合。

不适合用于:

- 存档数据。
- 配置文件中的持久 ID。
- 网络同步 ID。
- 跨进程通信 ID。
- 需要跨平台一致的资源标识。

------

## 8. 如果需要稳定字符串 ID

如果 `label` 的哈希值需要跨运行, 跨平台, 跨进程保持一致, 不应使用:

```csharp
StringComparer.Ordinal.GetHashCode(label)
```

应改用明确的确定性哈希算法, 例如:

- FNV-1a
- MurmurHash
- xxHash
- 自定义固定算法
- 直接存储原始字符串
- 使用预定义枚举或显式 ID

例如, 如果 `label` 是材质槽位的持久标识, 更安全的方式是保留字符串本身或使用稳定的配置 ID。

------

## 9. 当前代码的含义

当前代码:

```csharp
public override int GetHashCode()
{
    unchecked
    {
        // 将 labelHash 也纳入主哈希（这样做是为了减少字典冲突）
        int hash = (Renderer?.GetHashCode() ?? 0) * 397 ^ SlotIndex;
        hash = (hash * 397) ^ _labelHash;
        return hash;
    }
}
```

含义是:

1. 先取 `Renderer` 的哈希值。
2. 如果 `Renderer` 为空, 使用 `0`。
3. 将 `Renderer` 哈希乘以 `397`, 再与 `SlotIndex` 做异或。
4. 再将结果乘以 `397`, 并与 `_labelHash` 做异或。
5. 返回最终混合后的哈希值。
6. 整个过程允许整数溢出, 不抛异常。

------

## 10. 实际结论

对于当前这类 `MaterialSlot` / `SlotBinding` 场景:

- `unchecked` 是合理的。
- `397` 是合理的经验值。
- `_labelHash` 可以减少哈希冲突。
- `StringComparer.Ordinal.GetHashCode(label)` 在当前运行期间可用于哈希组合。
- 不要把 `_labelHash` 当作跨运行稳定 ID。
- 如果只是用于 `Dictionary` / `HashSet`, 当前写法可以接受。
- 如果 Unity 版本和项目环境支持, 可以考虑改成 `HashCode.Combine(Renderer, SlotIndex, _labelHash)`。

推荐最终写法之一:

```csharp
public override int GetHashCode()
{
    unchecked
    {
        int hash = (Renderer?.GetHashCode() ?? 0) * 397 ^ SlotIndex;
        hash = (hash * 397) ^ _labelHash;
        return hash;
    }
}
```

如果可用, 更简洁的写法:

```csharp
public override int GetHashCode()
{
    return HashCode.Combine(Renderer, SlotIndex, _labelHash);
}
```
