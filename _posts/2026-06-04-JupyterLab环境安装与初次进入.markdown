---
layout: post
title: "JupyterLab环境安装与初次进入"
categories: [工具, JupyterLab]
tags: 工具 JupyterLab 绘图 科学计算 研究 图形
math: true


---

# JupyterLab环境安装与初次进入

## 1. 目标

完成以下操作:

* 安装 Miniconda。
* 创建 Conda 环境。
* 安装 JupyterLab, NumPy, Matplotlib, SciPy, ipywidgets。
* 创建项目目录。
* 第一次进入 JupyterLab 页面。

本文不包含 Notebook 创建和绘图流程。

---

## 2. 占位符说明

| 占位符                | 含义             | 本文示例                                  |
| ------------------ | -------------- | ------------------------------------- |
| `[ENV_NAME]`       | Conda 环境名      | `numeric-viz-lab`                     |
| `[MINICONDA_ROOT]` | Miniconda 安装目录 | `D:\Dev\miniconda3`                   |
| `[PROJECT_ROOT]`   | 项目根目录          | `E:\PycharmProjects\RenderingMathLab` |

说明:

* 占位符不是命令的一部分。
* 执行命令时, 需要将占位符替换为自己的实际值。
* 本文示例值仅用于演示。

---

## 3. 安装 Miniconda

[下载 Windows 64-bit Graphical Installer](https://anaconda.com/api/installers/Miniconda3-latest-Windows-x86_64.exe)。([页面](https://www.anaconda.com/download/success))

安装时按以下选项配置:

```text
Install for: Just Me
Install Location: [MINICONDA_ROOT]
Advanced Options:
  不勾选 Add Miniconda to PATH
  勾选 Register Miniconda as default Python
```

本文示例安装目录:

```text
D:\Dev\miniconda3
```

---

## 4. 打开 Anaconda Prompt

操作:

在 Windows 开始菜单搜索并打开:

```text
Anaconda Prompt
```

预期结果:

命令行前缀类似:

```text
(base) C:\Users\YourName>
```

说明:

`(base)` 表示当前处于 Conda 的默认环境。

---

## 5. 创建 Conda 环境

操作:

输入以下命令并回车:

```bat
conda create -n [ENV_NAME] python=3.12
```

本文示例:

```bat
conda create -n numeric-viz-lab python=3.12
```

如果出现确认:

```text
Proceed ([y]/n)?
```

输入以下内容并回车:

```bat
y
```

如果首次使用时出现 Terms of Service 确认:

```text
Do you accept the Terms of Service?
```

输入以下内容并回车:

```bat
a
```

预期结果:

环境创建完成后, 命令行显示类似提示:

```text
To activate this environment, use

    conda activate [ENV_NAME]
```

---

## 6. 激活 Conda 环境

操作:

输入以下命令并回车:

```bat
conda activate [ENV_NAME]
```

本文示例:

```bat
conda activate numeric-viz-lab
```

预期结果:

命令行前缀变为:

```text
([ENV_NAME]) C:\Users\YourName>
```

本文示例:

```text
(numeric-viz-lab) C:\Users\YourName>
```

---

## 7. 安装基础包

操作:

输入以下命令并回车:

```bat
conda install -c conda-forge jupyterlab numpy matplotlib scipy ipywidgets
```

如果出现确认:

```text
Proceed ([y]/n)?
```

输入以下内容并回车:

```bat
y
```

安装内容:

| 包名           | 用途            |
| ------------ | ------------- |
| `jupyterlab` | Notebook 工作界面 |
| `numpy`      | 数值计算          |
| `matplotlib` | 绘图            |
| `scipy`      | 科学计算扩展        |
| `ipywidgets` | 交互控件          |

预期结果:

安装完成后, 命令行返回输入状态:

```text
([ENV_NAME]) C:\Users\YourName>
```

---

## 8. 创建项目目录

操作:

输入以下命令并回车:

```bat
mkdir [PROJECT_ROOT]
cd /d [PROJECT_ROOT]
```

本文示例:

```bat
mkdir E:\PycharmProjects\RenderingMathLab
cd /d E:\PycharmProjects\RenderingMathLab
```

继续输入以下命令并回车:

```bat
mkdir notebooks
mkdir outputs
mkdir scripts
```

目录用途:

| 目录          | 用途                   |
| ----------- | -------------------- |
| `notebooks` | 存放 `.ipynb` Notebook |
| `outputs`   | 存放导出的图片, 数据等         |
| `scripts`   | 存放可复用 Python 脚本      |

预期结果:

当前命令行位置变为:

```text
([ENV_NAME]) [PROJECT_ROOT]>
```

本文示例:

```text
(numeric-viz-lab) E:\PycharmProjects\RenderingMathLab>
```

---

## 9. 第一次进入 JupyterLab

操作:

确认当前命令行前缀和路径类似:

```text
([ENV_NAME]) [PROJECT_ROOT]>
```

输入以下命令并回车:

```bat
jupyter lab
```

预期结果:

浏览器自动打开 JupyterLab 页面。

如果浏览器没有自动打开, 在命令行中找到类似地址:

```text
http://localhost:8888/lab?token=......
```

复制完整地址到浏览器打开。

---

## 10. 完成检查

确认以下结果:

* 浏览器成功打开 JupyterLab。
* JupyterLab 左侧文件列表显示 `[PROJECT_ROOT]` 下的内容。
* 可以看到以下目录:

```text
notebooks
outputs
scripts
```

到此, 环境安装与初次进入完成。

---

## 11. 常见问题

### 11.1 `conda` 不是内部或外部命令

原因:

* 当前不是 Anaconda Prompt。
* 或 Miniconda 未加入系统 PATH。

处理方式:

* 使用开始菜单中的 `Anaconda Prompt`。
* 不建议为了方便直接把 Miniconda 加入系统 PATH。

---

### 11.2 `jupyter` 不是内部或外部命令

原因:

* 未激活目标 Conda 环境。
* 或 `jupyterlab` 未安装成功。

操作:

输入以下命令并回车, 检查环境列表:

```bat
conda info --envs
```

输入以下命令并回车, 激活环境:

```bat
conda activate [ENV_NAME]
```

输入以下命令并回车, 重新安装 JupyterLab:

```bat
conda install -c conda-forge jupyterlab
```

---

### 11.3 当前目录和 Conda 环境目录是否相同

不是同一件事。

Conda 环境目录用于存放 Python 和依赖包, 通常在:

```text
[MINICONDA_ROOT]\envs\[ENV_NAME]
```

项目目录用于存放 Notebook 和项目文件, 例如:

```text
[PROJECT_ROOT]
```

二者不需要相同。

---

### 11.4 是否需要更新 Conda

如果安装过程中出现类似提示:

```text
A newer version of conda exists.
```

初次安装流程中可以先忽略。

完成标准是:

* Conda 环境能正常创建。
* 基础包能正常安装。
* JupyterLab 能正常进入。
