---
layout: post
title: "JupyterLab日常使用与环境维护"
categories: [工具, JupyterLab]
tags: 工具 JupyterLab 绘图 科学计算 研究 图形
math: true


---

# JupyterLab日常使用与环境维护

## 1. 目标

记录以下操作:

- 第二次及以后如何进入 JupyterLab。
- 如何使用 `.bat` 文件快速进入。
- 如何打开已有 Notebook。
- 如何正确关闭 JupyterLab。
- 如何确认 JupyterLab 是否仍在运行。
- 如何修改 Conda 环境名。

本文假设已完成《JupyterLab 环境安装与初次进入》。

------

## 2. 占位符说明

| 占位符             | 含义               | 本文示例                              |
| ------------------ | ------------------ | ------------------------------------- |
| `[ENV_NAME]`       | 当前 Conda 环境名  | `numeric-viz-lab`                     |
| `[MINICONDA_ROOT]` | Miniconda 安装目录 | `D:\Dev\miniconda3`                   |
| `[PROJECT_ROOT]`   | 项目根目录         | `E:\PycharmProjects\RenderingMathLab` |
| `[NOTEBOOK_NAME]`  | Notebook 文件名    | `brdf_basic_compare.ipynb`            |
| `[OLD_ENV_NAME]`   | 旧 Conda 环境名    | `dfg-lab`                             |
| `[NEW_ENV_NAME]`   | 新 Conda 环境名    | `numeric-viz-lab`                     |

说明:

- 占位符不是命令的一部分。
- 执行命令时, 需要将占位符替换为自己的实际值。
- 本文示例值仅用于演示。

------

## 3. 手动进入 JupyterLab

操作:

打开 `Anaconda Prompt`。

输入以下命令并回车:

```bat
conda activate [ENV_NAME]
```

本文示例:

```bat
conda activate numeric-viz-lab
```

继续输入以下命令并回车:

```bat
cd /d [PROJECT_ROOT]
```

本文示例:

```bat
cd /d E:\PycharmProjects\RenderingMathLab
```

继续输入以下命令并回车:

```bat
jupyter lab
```

预期结果:

浏览器打开 JupyterLab 页面。

如果浏览器没有自动打开, 在命令行中找到类似地址:

```text
http://localhost:8888/lab?token=......
```

复制完整地址到浏览器打开。

------

## 4. 打开已有 Notebook

操作:

在 JupyterLab 左侧文件列表中进入:

```text
notebooks
```

双击需要打开的 Notebook。

本文示例:

```text
brdf_basic_compare.ipynb
```

预期结果:

Notebook 页面打开, 可以继续编辑和运行 cell。

如果页面提示 kernel disconnected 或 kernel dead, 点击:

```text
Kernel -> Restart Kernel and Run All Cells
```

------

## 5. 创建快速启动 bat

用途:

双击 `.bat` 文件后直接进入项目目录并打开 JupyterLab。

操作:

在 `[PROJECT_ROOT]` 下创建文件:

```text
Start_JupyterLab.bat
```

写入以下内容:

```bat
@echo off

call "[MINICONDA_ROOT]\condabin\conda.bat" activate [ENV_NAME]

cd /d [PROJECT_ROOT]

jupyter lab

pause
```

本文示例:

```bat
@echo off

call "D:\Dev\miniconda3\condabin\conda.bat" activate numeric-viz-lab

cd /d E:\PycharmProjects\RenderingMathLab

jupyter lab

pause
```

保存后双击该 `.bat` 文件。

预期结果:

浏览器打开 JupyterLab 页面。

------

## 6. bat 备用写法

如果 `.bat` 文件提示:

```text
'jupyter' 不是内部或外部命令, 也不是可运行的程序或批处理文件。
```

将:

```bat
jupyter lab
```

替换为:

```bat
python -m jupyter lab
```

备用完整内容:

```bat
@echo off

call "[MINICONDA_ROOT]\condabin\conda.bat" activate [ENV_NAME]

cd /d [PROJECT_ROOT]

python -m jupyter lab

pause
```

本文示例:

```bat
@echo off

call "D:\Dev\miniconda3\condabin\conda.bat" activate numeric-viz-lab

cd /d E:\PycharmProjects\RenderingMathLab

python -m jupyter lab

pause
```

------

## 7. 正确关闭 JupyterLab

操作:

在 Notebook 中按:

```text
Ctrl + S
```

预期结果:

Notebook 保存完成。

继续操作:

点击 JupyterLab 页面中File菜单中的:

```text
Shut Down
```

如果通过 `.bat` 启动, 回到命令行窗口后可能显示:

```text
请按任意键继续. . .
```

按任意键关闭窗口。

------

## 8. Logout 和 Shut Down 区别

| 按钮        | 含义                     | 本地使用建议 |
| ----------- | ------------------------ | ------------ |
| `Logout`    | 退出当前网页登录状态     | 通常不用     |
| `Shut Down` | 关闭本地 JupyterLab 服务 | 退出时使用   |

结论:

- 只关闭浏览器标签页, 不等于关闭 JupyterLab 服务。
- 要彻底退出本地 JupyterLab, 使用 `Shut Down`。

------

## 9. 使用 Ctrl + C 关闭

操作:

在启动 JupyterLab 的命令行窗口中按:

```text
Ctrl + C
```

可能出现确认:

```text
Shutdown this Jupyter server? [y/N]
```

输入以下内容并回车:

```bat
y
```

也可能不出现确认, 直接显示:

```text
[IPKernelApp] WARNING | Parent appears to have exited, shutting down.
```

说明:

该 warning 通常不是错误。
它表示 Jupyter 主进程已经退出, Python kernel 自动关闭。

完成标准:

命令行回到输入状态, 例如:

```text
([ENV_NAME]) [PROJECT_ROOT]>
```

------

## 10. 确认 JupyterLab 是否仍在运行

### 10.1 使用浏览器确认

操作:

刷新之前的 JupyterLab 页面。

判断:

- 如果页面正常打开, JupyterLab 仍在运行。
- 如果页面连接失败, JupyterLab 通常已经关闭。

------

### 10.2 使用端口确认

操作:

打开 CMD 或 PowerShell。

输入以下命令并回车:

```bat
netstat -ano | findstr :8888
```

判断:

如果没有输出, 通常表示 8888 端口没有 JupyterLab 在运行。

如果有类似输出:

```text
TCP    127.0.0.1:8888    0.0.0.0:0    LISTENING    12345
```

说明有程序正在监听 8888 端口。

继续输入以下命令并回车:

```bat
tasklist /FI "PID eq 12345"
```

将 `12345` 替换为实际 PID。

如果结果显示 `python.exe`, 可能是 JupyterLab。

------

### 10.3 使用 jupyter 命令确认

操作:

打开 `Anaconda Prompt`。

输入以下命令并回车:

```bat
conda activate [ENV_NAME]
```

继续输入以下命令并回车:

```bat
jupyter server list
```

判断:

如果列出 `localhost` 地址, 表示有 Jupyter server 正在运行。

------

## 11. Conda 环境改名原则

不建议直接修改环境文件夹名。

不要手动改名:

```text
[MINICONDA_ROOT]\envs\[ENV_NAME]
```

原因:

环境内部可能记录了路径。
直接改文件夹名可能导致路径不一致。

推荐方式:

```text
克隆旧环境 -> 测试新环境 -> 删除旧环境
```

------

## 12. 克隆旧环境为新环境

操作:

确认当前没有正在运行的 JupyterLab。

打开 `Anaconda Prompt`。

输入以下命令并回车, 退出当前环境:

```bat
conda deactivate
```

如仍处于某个 Conda 环境中, 可以再次执行:

```bat
conda deactivate
```

输入以下命令并回车:

```bat
conda create --name [NEW_ENV_NAME] --clone [OLD_ENV_NAME]
```

本文示例:

```bat
conda create --name numeric-viz-lab --clone dfg-lab
```

如果出现确认:

```text
Proceed ([y]/n)?
```

输入以下内容并回车:

```bat
y
```

预期结果:

新环境创建完成, 命令行显示类似:

```text
To activate this environment, use

    conda activate [NEW_ENV_NAME]
```

------

## 13. 测试新环境

操作:

输入以下命令并回车:

```bat
conda activate [NEW_ENV_NAME]
```

本文示例:

```bat
conda activate numeric-viz-lab
```

继续输入以下命令并回车:

```bat
cd /d [PROJECT_ROOT]
```

继续输入以下命令并回车:

```bat
jupyter lab
```

预期结果:

JupyterLab 正常打开。

继续检查:

- 可以进入 `notebooks`。
- 可以打开已有 Notebook。
- 可以运行 Notebook cell。

------

## 14. 修改 bat 环境名

操作:

打开 `[PROJECT_ROOT]\Start_JupyterLab.bat`。

将旧环境名:

```bat
[OLD_ENV_NAME]
```

替换为新环境名:

```bat
[NEW_ENV_NAME]
```

示例:

修改前:

```bat
call "D:\Dev\miniconda3\condabin\conda.bat" activate dfg-lab
```

修改后:

```bat
call "D:\Dev\miniconda3\condabin\conda.bat" activate numeric-viz-lab
```

保存文件。

预期结果:

双击 `.bat` 后, JupyterLab 使用新环境启动。

------

## 15. 删除旧环境

前置条件:

- 新环境已测试通过。
- `.bat` 已改为新环境名。
- 当前没有使用旧环境运行 JupyterLab。

操作:

打开 `Anaconda Prompt`。

输入以下命令并回车:

```bat
conda deactivate
```

输入以下命令并回车:

```bat
conda remove --name [OLD_ENV_NAME] --all
```

本文示例:

```bat
conda remove --name dfg-lab --all
```

如果出现确认:

```text
Proceed ([y]/n)?
```

输入以下内容并回车:

```bat
y
```

预期结果:

旧环境被删除。

------

## 16. 查看当前 Conda 环境列表

操作:

输入以下命令并回车:

```bat
conda info --envs
```

预期结果:

显示所有 Conda 环境。

确认:

- `[NEW_ENV_NAME]` 存在。
- `[OLD_ENV_NAME]` 已不存在, 如果已执行删除操作。

------

## 17. 常见问题

### 17.1 `.bat` 提示 `conda` 不是内部或外部命令

原因:

Miniconda 没有加入系统 PATH。

处理方式:

不要直接写:

```bat
conda activate [ENV_NAME]
```

使用完整路径:

```bat
call "[MINICONDA_ROOT]\condabin\conda.bat" activate [ENV_NAME]
```

------

### 17.2 `.bat` 提示 `jupyter` 不是内部或外部命令

处理方式:

将:

```bat
jupyter lab
```

替换为:

```bat
python -m jupyter lab
```

------

### 17.3 关闭浏览器后, JupyterLab 是否已经关闭

不一定。

浏览器是前端页面。
JupyterLab 服务运行在命令行进程中。

要彻底退出, 使用:

```text
Shut Down
```

或在命令行中按:

```text
Ctrl + C
```

------

### 17.4 是否可以立刻删除旧环境

不建议。

应先完成:

- 新环境可以启动 JupyterLab。
- Notebook 可以正常运行。
- `.bat` 已改为新环境名。

确认无误后再删除旧环境。

------

### 17.5 是否可以删除 base 环境

不建议。

`base` 是 Conda 的默认环境, 用于管理 conda 本身。
日常项目应使用独立环境, 不应删除 `base`。
