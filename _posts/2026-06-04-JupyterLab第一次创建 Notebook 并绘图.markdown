---
layout: post
title: "JupyterLab第一次创建 Notebook 并绘图"
categories: [工具, JupyterLab]
tags: 工具 JupyterLab 绘图 科学计算 研究 图形
math: true


---

# JupyterLab第一次创建 Notebook 并绘图

## 1. 目标

完成以下操作:

- 创建第一个 Jupyter Notebook。
- 绘制一维函数对比图。
- 绘制二维误差热力图。
- 输出误差统计。
- 绘制函数切片图。
- 将 Notebook 整理为可复用结构。
- 保存并退出 JupyterLab。

本文假设已完成《JupyterLab 环境安装与初次进入》。

------

## 2. 占位符说明

| 占位符            | 含义            | 本文示例                              |
| ----------------- | --------------- | ------------------------------------- |
| `[PROJECT_ROOT]`  | 项目根目录      | `E:\PycharmProjects\RenderingMathLab` |
| `[NOTEBOOK_NAME]` | Notebook 文件名 | `brdf_basic_compare.ipynb`            |

说明:

- 占位符不是固定要求。
- 执行操作时, 需要替换为自己的实际值。
- 本文示例值仅用于演示。

------

## 3. 进入 notebooks 目录

操作:

在 JupyterLab 左侧文件列表中, 双击进入:

```text
notebooks
```

预期结果:

当前文件列表显示的是 `[PROJECT_ROOT]\notebooks` 下的内容。

------

## 4. 新建 Notebook

操作:

点击左上角 `+` 打开 Launcher。

在 `Notebook` 区域点击:

```text
Python 3
```

预期结果:

打开一个新的 Notebook 页面。

------

## 5. 保存并命名 Notebook

操作:

点击顶部菜单:

```text
File -> Save Notebook As...
```

输入文件名:

```text
[NOTEBOOK_NAME]
```

本文示例:

```text
brdf_basic_compare.ipynb
```

预期结果:

左侧 `notebooks` 目录中出现:

```text
brdf_basic_compare.ipynb
```

------

## 6. Cell 基础操作

Jupyter Notebook 常用 cell 类型:

| 类型     | 用途             |
| -------- | ---------------- |
| Code     | 写 Python 代码   |
| Markdown | 写标题和说明文字 |

常用操作:

| 操作                  | 快捷键            |
| --------------------- | ----------------- |
| 运行当前 cell         | `Shift + Enter`   |
| 保存 Notebook         | `Ctrl + S`        |
| 将 cell 改为 Markdown | `Esc`, 然后按 `M` |
| 将 cell 改为 Code     | `Esc`, 然后按 `Y` |

------

## 7. 第一次绘制函数曲线

操作:

在第一个 Code cell 中输入以下代码并运行:

```python
import numpy as np
import matplotlib.pyplot as plt

x = np.linspace(0.0, 1.0, 200)

old = x ** 2.0
new = x ** 1.8
diff = new - old

plt.figure(figsize=(8, 4))
plt.plot(x, old, label="old")
plt.plot(x, new, label="new")
plt.plot(x, diff, label="diff")
plt.legend()
plt.grid(True)
plt.xlabel("x")
plt.ylabel("value")
plt.title("Basic Function Compare")
plt.show()
```

预期结果:

Notebook 下方显示三条曲线:

```text
old
new
diff
```

------

## 8. 创建二维采样域

操作:

新建一个 Code cell, 输入以下代码并运行:

```python
sample_count = 256

ndotv_min = 0.001
ndotv_max = 1.0

roughness_min = 0.001
roughness_max = 1.0

ndotv = np.linspace(ndotv_min, ndotv_max, sample_count)
roughness = np.linspace(roughness_min, roughness_max, sample_count)

NdotV, Roughness = np.meshgrid(ndotv, roughness)
```

预期结果:

该 cell 无图像输出。

------

## 9. 定义 old / new 测试函数

操作:

新建一个 Code cell, 输入以下代码并运行:

```python
def dfg_old(ndotv, roughness):
    return (1.0 - roughness * 0.5) * np.power(1.0 - ndotv, 5.0)


def dfg_new(ndotv, roughness):
    return (1.0 - roughness * 0.35) * np.power(1.0 - ndotv, 4.5)
```

预期结果:

该 cell 无图像输出。

说明:

这不是正式 DFG 公式。
该函数仅用于验证 Notebook 工作流。

------

## 10. 计算 old / new / error

操作:

新建一个 Code cell, 输入以下代码并运行:

```python
old_value = dfg_old(NdotV, Roughness)
new_value = dfg_new(NdotV, Roughness)

diff = new_value - old_value
abs_error = np.abs(diff)
```

预期结果:

该 cell 无图像输出。

------

## 11. 绘制误差热力图

操作:

新建一个 Code cell, 输入以下代码并运行:

```python
plt.figure(figsize=(6, 5))
plt.imshow(
    abs_error,
    origin="lower",
    extent=[ndotv_min, ndotv_max, roughness_min, roughness_max],
    aspect="auto"
)
plt.colorbar(label="abs error")
plt.xlabel("NdotV")
plt.ylabel("roughness")
plt.title("DFG Function Absolute Error")
plt.show()
```

预期结果:

显示一张二维误差热力图。

图像含义:

| 图像元素 | 含义                              |
| -------- | --------------------------------- |
| 横轴     | `NdotV`                           |
| 纵轴     | `roughness`                       |
| 颜色     | `dfg_new` 与 `dfg_old` 的绝对误差 |

------

## 12. 输出误差统计

操作:

新建一个 Code cell, 输入以下代码并运行:

```python
max_abs_error = np.max(abs_error)
mean_abs_error = np.mean(abs_error)
rmse = np.sqrt(np.mean(diff ** 2))
p95_abs_error = np.percentile(abs_error, 95)
p99_abs_error = np.percentile(abs_error, 99)

print(f"Max Abs Error  : {max_abs_error:.6f}")
print(f"Mean Abs Error : {mean_abs_error:.6f}")
print(f"RMSE           : {rmse:.6f}")
print(f"P95 Abs Error  : {p95_abs_error:.6f}")
print(f"P99 Abs Error  : {p99_abs_error:.6f}")
```

预期结果:

输出类似:

```text
Max Abs Error  : 0.149575
Mean Abs Error : 0.025009
RMSE           : 0.038519
P95 Abs Error  : 0.086077
P99 Abs Error  : 0.118000
```

说明:

该 cell 只输出文本, 不绘图。

------

## 13. 绘制三图对比

操作:

新建一个 Code cell, 输入以下代码并运行:

```python
value_min = min(np.min(old_value), np.min(new_value))
value_max = max(np.max(old_value), np.max(new_value))

fig, axes = plt.subplots(1, 3, figsize=(15, 4))

heatmaps = [
    (old_value, "Old Function", value_min, value_max),
    (new_value, "New Function", value_min, value_max),
    (abs_error, "Absolute Error", None, None),
]

for ax, (data, title, vmin, vmax) in zip(axes, heatmaps):
    im = ax.imshow(
        data,
        origin="lower",
        extent=[ndotv_min, ndotv_max, roughness_min, roughness_max],
        aspect="auto",
        vmin=vmin,
        vmax=vmax
    )

    ax.set_title(title)
    ax.set_xlabel("NdotV")
    ax.set_ylabel("roughness")
    fig.colorbar(im, ax=ax)

plt.tight_layout()
plt.show()
```

预期结果:

显示三张图:

```text
Old Function
New Function
Absolute Error
```

说明:

`Old Function` 和 `New Function` 使用相同色阶, 便于对比。

------

## 14. 绘制 old / new 切片曲线

操作:

新建一个 Code cell, 输入以下代码并运行:

```python
roughness_slices = [0.05, 0.25, 0.5, 0.75, 1.0]

plt.figure(figsize=(10, 6))

for r in roughness_slices:
    old_slice = dfg_old(ndotv, r)
    new_slice = dfg_new(ndotv, r)

    plt.plot(ndotv, old_slice, linestyle="--", label=f"old r={r}")
    plt.plot(ndotv, new_slice, linestyle="-", label=f"new r={r}")

plt.xlabel("NdotV")
plt.ylabel("value")
plt.title("Old vs New Function Slices")
plt.grid(True)
plt.legend()
plt.show()
```

预期结果:

显示多条曲线。
虚线表示 old function, 实线表示 new function。

------

## 15. 绘制差异切片曲线

操作:

新建一个 Code cell, 输入以下代码并运行:

```python
plt.figure(figsize=(10, 5))

for r in roughness_slices:
    old_slice = dfg_old(ndotv, r)
    new_slice = dfg_new(ndotv, r)
    diff_slice = new_slice - old_slice

    plt.plot(ndotv, diff_slice, label=f"r={r}")

plt.axhline(0.0, linewidth=1)
plt.xlabel("NdotV")
plt.ylabel("new - old")
plt.title("Difference Slices")
plt.grid(True)
plt.legend()
plt.show()
```

预期结果:

显示 `new - old` 的差异曲线。

------

## 16. 整理 Notebook 结构

操作:

在对应位置插入 Markdown cell, 将 Notebook 整理为以下结构:

```text
1. BRDF / DFG Function Comparison
2. Imports and Settings
3. Function Definitions
4. Sampling Domain
5. Heatmap Comparison
6. Error Statistics
7. Old vs New Slices
8. Difference Slices
```

建议整理方式:

| 章节                 | Cell 类型 |
| -------------------- | --------- |
| 标题说明             | Markdown  |
| Imports and Settings | Code      |
| Function Definitions | Code      |
| Sampling Domain      | Code      |
| Heatmap Comparison   | Code      |
| Error Statistics     | Code      |
| Old vs New Slices    | Code      |
| Difference Slices    | Code      |

------

## 17. 整理后的 Notebook 内容

### 17.1 标题说明

Cell 类型: Markdown

输入以下内容:

```markdown
# BRDF / DFG Function Comparison

This notebook is used to compare old and new rendering math functions.

Current scope:
- Compare old and new function values.
- Visualize absolute error heatmap.
- Print error statistics.
- Inspect fixed roughness slices.
- Inspect difference slices.
```

------

### 17.2 Imports and Settings

Cell 类型: Code

```python
import numpy as np
import matplotlib.pyplot as plt

sample_count = 256

ndotv_min = 0.001
ndotv_max = 1.0

roughness_min = 0.001
roughness_max = 1.0
```

------

### 17.3 Function Definitions

Cell 类型: Code

```python
def dfg_old(ndotv, roughness):
    return (1.0 - roughness * 0.5) * np.power(1.0 - ndotv, 5.0)


def dfg_new(ndotv, roughness):
    return (1.0 - roughness * 0.35) * np.power(1.0 - ndotv, 4.5)
```

------

### 17.4 Sampling Domain

Cell 类型: Code

```python
ndotv = np.linspace(ndotv_min, ndotv_max, sample_count)
roughness = np.linspace(roughness_min, roughness_max, sample_count)

NdotV, Roughness = np.meshgrid(ndotv, roughness)

old_value = dfg_old(NdotV, Roughness)
new_value = dfg_new(NdotV, Roughness)

diff = new_value - old_value
abs_error = np.abs(diff)
```

------

### 17.5 Heatmap Comparison

Cell 类型: Code

```python
value_min = min(np.min(old_value), np.min(new_value))
value_max = max(np.max(old_value), np.max(new_value))

fig, axes = plt.subplots(1, 3, figsize=(15, 4))

heatmaps = [
    (old_value, "Old Function", value_min, value_max),
    (new_value, "New Function", value_min, value_max),
    (abs_error, "Absolute Error", None, None),
]

for ax, (data, title, vmin, vmax) in zip(axes, heatmaps):
    im = ax.imshow(
        data,
        origin="lower",
        extent=[ndotv_min, ndotv_max, roughness_min, roughness_max],
        aspect="auto",
        vmin=vmin,
        vmax=vmax
    )

    ax.set_title(title)
    ax.set_xlabel("NdotV")
    ax.set_ylabel("roughness")
    fig.colorbar(im, ax=ax)

plt.tight_layout()
plt.show()
```

------

### 17.6 Error Statistics

Cell 类型: Code

```python
max_abs_error = np.max(abs_error)
mean_abs_error = np.mean(abs_error)
rmse = np.sqrt(np.mean(diff ** 2))
p95_abs_error = np.percentile(abs_error, 95)
p99_abs_error = np.percentile(abs_error, 99)

print(f"Max Abs Error  : {max_abs_error:.6f}")
print(f"Mean Abs Error : {mean_abs_error:.6f}")
print(f"RMSE           : {rmse:.6f}")
print(f"P95 Abs Error  : {p95_abs_error:.6f}")
print(f"P99 Abs Error  : {p99_abs_error:.6f}")
```

------

### 17.7 Old vs New Slices

Cell 类型: Code

```python
roughness_slices = [0.05, 0.25, 0.5, 0.75, 1.0]

plt.figure(figsize=(10, 6))

for r in roughness_slices:
    old_slice = dfg_old(ndotv, r)
    new_slice = dfg_new(ndotv, r)

    plt.plot(ndotv, old_slice, linestyle="--", label=f"old r={r}")
    plt.plot(ndotv, new_slice, linestyle="-", label=f"new r={r}")

plt.xlabel("NdotV")
plt.ylabel("value")
plt.title("Old vs New Function Slices")
plt.grid(True)
plt.legend()
plt.show()
```

------

### 17.8 Difference Slices

Cell 类型: Code

```python
plt.figure(figsize=(10, 5))

for r in roughness_slices:
    old_slice = dfg_old(ndotv, r)
    new_slice = dfg_new(ndotv, r)
    diff_slice = new_slice - old_slice

    plt.plot(ndotv, diff_slice, label=f"r={r}")

plt.axhline(0.0, linewidth=1)
plt.xlabel("NdotV")
plt.ylabel("new - old")
plt.title("Difference Slices")
plt.grid(True)
plt.legend()
plt.show()
```

------

## 18. 重新运行全部 Cell

操作:

点击顶部菜单:

```text
Run -> Run All Cells
```

预期结果:

全部 cell 从上到下运行完成, 且没有报错。

如果需要清空旧状态后重新运行, 点击:

```text
Kernel -> Restart Kernel and Run All Cells
```

------

## 19. 保存 Notebook

操作:

按下:

```text
Ctrl + S
```

或点击:

```text
File -> Save Notebook
```

预期结果:

Notebook 保存完成。

------

## 20. 退出 JupyterLab

操作:

点击 JupyterLab 页面中的:

```text
Shut Down
```

如果通过 `.bat` 启动, 回到命令行窗口后可能显示:

```text
请按任意键继续. . .
```

按任意键关闭窗口。

------

## 21. 常见问题

### 21.1 `NameError: name 'ndotv_min' is not defined`

原因:

定义 `ndotv_min` 的 cell 没有先运行。

处理方式:

点击:

```text
Kernel -> Restart Kernel and Run All Cells
```

或从上到下手动运行所有 cell。

------

### 21.2 运行后没有图, 只有文字输出

原因:

当前 cell 只包含 `print` 输出, 不包含绘图代码。

说明:

误差统计 cell 只输出文本, 这是正常结果。

------

### 21.3 `In [7]` 是否表示第 7 个 cell

不是。

`In [7]` 表示第 7 次执行, 不表示页面中的第 7 个 cell。

------

### 21.4 修改函数后图没有变化

原因:

后续 cell 没有重新运行。

处理方式:

点击:

```text
Run -> Run All Cells
```

或从函数定义 cell 开始, 按顺序重新运行后续 cell。

------

### 21.5 Kernel disconnected 或 Kernel dead

处理方式:

点击:

```text
Kernel -> Restart Kernel and Run All Cells
```

如果仍然失败, 关闭 JupyterLab 后重新进入。
