---
layout: post
title: "使用 uv + PySide6 + PyCharm 搭建项目级 Python 桌面工具开发环境"
categories: [Python, 工具开发]
tags: Python uv PySide6 PyCharm Qt 虚拟环境
math: true


---

# 使用 uv + PySide6 + PyCharm 搭建项目级 Python 桌面工具开发环境

## 1. 目标

本文记录一套适合 Python 桌面工具开发的项目环境配置流程.

目标是做到:

1. 每个 Python 工程拥有独立的虚拟环境.
2. 不同项目之间的 Python 包互不干扰.
3. 使用 `pyproject.toml` 描述项目依赖.
4. 使用 `uv` 管理虚拟环境、依赖和 Lock 文件.
5. 使用 PyCharm 作为 IDE.
6. 使用 PySide6 开发 Qt 桌面工具.

最终结构类似:

```text
计算机
│
├── Python 3.12
│
├── uv
│
└── Projects
    │
    ├── ToolA
    │   ├── pyproject.toml
    │   ├── uv.lock
    │   └── .venv
    │
    └── ToolB
        ├── pyproject.toml
        ├── uv.lock
        └── .venv
```

核心原则是:

> Python 本体可以安装在计算机上, 但项目依赖应该隔离在各自工程的 `.venv` 中.

------

# 2. 为什么选择这套方案

## 2.1 为什么每个项目使用独立 `.venv`

不推荐把所有第三方 Python Package 都安装到同一个全局 Python 环境中.

例如:

```text
Python 3.12
├── PySide6
├── NumPy
├── Pillow
├── ...
└── 所有项目共用
```

这种结构容易出现:

```text
Project A
需要 Package X 1.x

Project B
需要 Package X 2.x
```

不同项目的依赖可能互相影响.

更合理的结构是:

```text
Project A
└── .venv
    └── Project A Dependencies

Project B
└── .venv
    └── Project B Dependencies
```

每个项目独立维护自己的 Python 环境.

------

## 2.2 为什么使用 `pyproject.toml`

`pyproject.toml` 是现代 Python 项目用于描述项目配置的重要标准文件.

例如:

```toml
[project]
name = "unitypackagestructurer"
version = "0.1.0"
requires-python = ">=3.12,<3.13"
dependencies = [
    "pyside6",
]
```

它可以描述:

```text
项目名称
项目版本
Python 版本要求
直接依赖
其他 Python 工具配置
```

------

## 2.3 为什么使用 uv

传统 Python 项目常见组合是:

```text
python -m venv
pip
requirements.txt
```

这套方式依然有效.

本文选择 `uv`, 是因为它可以统一处理:

```text
虚拟环境
依赖安装
依赖解析
依赖锁定
Python Interpreter 选择
pyproject.toml 项目管理
```

最终形成:

```text
pyproject.toml
      ↓
   uv.lock
      ↓
    .venv
```

三者职责不同.

| 对象             | 职责                                 |
| ---------------- | ------------------------------------ |
| `pyproject.toml` | 项目希望使用什么 Python 和依赖.      |
| `uv.lock`        | uv 实际解析出来的精确依赖关系和版本. |
| `.venv`          | 当前计算机实际安装好的项目运行环境.  |

------

## 2.4 为什么选择 PySide6

PySide6 是 Qt 的 Python Binding.

它比较适合开发:

```text
技术美术工具
资产处理工具
节点编辑器
批处理工具
配置工具
调试工具
Blender 外部 Pipeline
```

后续如果需要开发节点编辑器, 还可以继续使用 Qt Widgets 中的:

```text
QGraphicsScene
QGraphicsView
QGraphicsItem
```

因此 PySide6 比较适合作为长期 Python 桌面工具开发技术栈.

------

# 3. 本文使用的目录

本文实际使用以下路径.

| 对象          | 路径                                        |
| ------------- | ------------------------------------------- |
| `Python 3.12` | `D:\Dev\App\Python\Python312`               |
| `Python 3.9`  | `D:\Dev\App\Python\Python39`                |
| `uv`          | `D:\Dev\App\Python\AstralUV`                |
| `工程`        | `E:\PycharmProjects\UnityPackageStructurer` |

最终大致结构:

```text
D:\Dev\App\Python\
├── Python312\
│   └── python.exe
│
├── Python39\
│   └── python.exe
│
└── AstralUV\
    ├── uv.exe
    ├── uvx.exe
    └── uvw.exe
```

项目:

```text
E:\PycharmProjects\UnityPackageStructurer\
├── .venv\
├── pyproject.toml
├── uv.lock
└── ...
```

如果实际安装路径不同, 将本文命令中的路径替换为自己的路径即可.

------

# 4. 环境配置 Checklist

按照以下顺序操作.

-  确认已有 Python 安装.
-  删除工程旧 `.venv`, 如果存在.
-  规划 `uv` 安装目录.
-  安装 `uv`.
-  验证 `uv`.
-  启动 PyCharm 并打开工程.
-  打开 PyCharm Terminal 并确认当前目录.
-  将已有工程初始化为 `uv` 项目.
-  设置项目 Python 版本要求.
-  创建项目独立 `.venv`.
-  让 PyCharm 使用现有 `uv` 环境.
-  添加 PySide6.
-  检查 `pyproject.toml`.
-  检查 `uv.lock`.
-  验证 PySide6.

------

# 5. 确认 Python 安装

首先确认计算机已经安装需要使用的 Python.

打开 Windows PowerShell.

本文准备使用:

```text
D:\Dev\App\Python\Python312\python.exe
```

执行:

```powershell
& "D:\Dev\App\Python\Python312\python.exe" --version
```

本文实际得到:

```text
Python 3.12.0
```

如果机器同时安装了其他 Python, 也可以检查.

例如:

```powershell
& "D:\Dev\App\Python\Python39\python.exe" --version
```

本文实际得到:

```text
Python 3.9.13
```

后续 `UnityPackageStructurer` 明确使用 Python 3.12.

------

# 6. 删除旧 `.venv`

如果这是一个已有 Python 工程, 并且工程根目录已经存在:

```text
.venv
```

建议先删除旧 `.venv`.

例如:

```text
E:\PycharmProjects\UnityPackageStructurer\.venv
```

只删除 `.venv`.

不要因为删除虚拟环境而删除自己的 Python 源代码.

如果工程原本没有 `.venv`, 则跳过这一步.

`.venv` 属于本机环境生成物.

它不应该承担“描述项目依赖”的职责.

真正用于描述项目环境的是后续的:

```text
pyproject.toml
uv.lock
```

------

# 7. 规划 uv 安装目录

`uv` 是独立的 Python 开发工具, 不属于某一个具体项目的 `.venv`.

本文将其安装到:

```text
D:\Dev\App\Python\AstralUV
```

之所以使用 `AstralUV` 作为目录名, 是为了避免和 3D 工作中常见的 Mesh UV 概念混淆.

需要注意:

> 软件本身的正式名称仍然是 `uv`.

`Astral` 是它的开发方.

------

# 8. 安装 uv

打开一个普通 Windows PowerShell.

执行:

```powershell
powershell -ExecutionPolicy ByPass -c {$env:UV\_INSTALL\_DIR = "D:\Dev\App\Python\AstralUV"; $env:UV_NO_MODIFY_PATH = "1"; irm https://astral.sh/uv/install.ps1 | iex}
```

其中:

```text
UV_INSTALL_DIR
```

指定 `uv` 的安装位置.

而:

```text
UV_NO_MODIFY_PATH = "1"
```

表示:

> 不允许安装器自动修改系统 PATH.

本文采用这种方式, 是为了让开发工具的路径完全由自己管理.

成功后应该看到类似:

```text
downloading uv ...
installing to D:\Dev\App\Python\AstralUV
  uv.exe
  uvx.exe
  uvw.exe
everything's installed!
```

最终应该得到:

```text
D:\Dev\App\Python\AstralUV\
├── uv.exe
├── uvx.exe
└── uvw.exe
```

------

# 9. 验证 uv

因为上一节明确设置了:

```text
UV_NO_MODIFY_PATH = "1"
```

所以本文不会假定系统可以直接识别:

```powershell
uv
```

因此不要直接使用:

```powershell
uv --version
```

而应该明确执行:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" --version
```

本文实际得到:

```text
uv 0.12.5 (210d1f678 2026-08-14 x86_64-pc-windows-msvc)
```

只要能够正常输出版本号, 就说明 `uv` 安装成功.

------

# 10. 启动 PyCharm 并打开工程

完成 Python 和 `uv` 的准备以后, 启动 PyCharm.

在 PyCharm 启动页面选择:

```text
Open
```

然后选择项目根目录.

本文使用:

```text
E:\PycharmProjects\UnityPackageStructurer
```

打开以后, PyCharm 左侧 Project 面板应该显示当前工程内容.

如果之前删除了 `.venv`, 此时 PyCharm 可能提示:

```text
未为 unitypackagestructurer 配置 Python 解释器
```

这是正常现象.

暂时不用处理.

因为新的 `.venv` 还没有创建.

------

# 11. 打开 PyCharm Terminal

在 PyCharm 窗口底部找到:

```text
Terminal(终端)
```

打开 Terminal.

不要假定 Terminal 当前目录一定正确.

首先执行:

```powershell
pwd
```

本文应该看到:

```text
Path
----
E:\PycharmProjects\UnityPackageStructurer
```

如果当前目录不是项目根目录, 执行:

```powershell
cd "E:\PycharmProjects\UnityPackageStructurer"
```

然后再次执行:

```powershell
pwd
```

直到当前路径确认是:

```text
E:\PycharmProjects\UnityPackageStructurer
```

后面的项目级命令都应该在这个目录执行.

------

# 12. 初始化 uv 项目

这里分两种情况:

```text
情况 A:
已有 Python 工程, 只想把现有工程纳入 uv 管理.

情况 B:
准备创建一个全新的 Python 工程.
```

两种情况不要混用.

------

## 12.1 情况 A: 已有工程

如果当前目录已经存在自己的 Python 源代码、README、目录结构等内容, 不希望 `uv` 自动生成新的项目模板, 建议使用:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" init --bare
```

`--bare` 的目的可以理解为:

> 只初始化 uv 项目配置, 尽量不改动已有工程结构.

成功后通常会看到类似:

```text
Initialized project `unitypackagestructurer`
```

工程根目录会新增:

```text
pyproject.toml
```

例如:

```toml
[project]
name = "unitypackagestructurer"
version = "0.1.0"
requires-python = ">=3.14"
dependencies = []
```

`requires-python` 可能不是项目实际需要的版本, 后续还需要手动检查和修改.

------

## 12.2 情况 B: 全新工程

如果准备从零创建一个新的 Python 工程, 可以直接让 `uv` 初始化项目.

### 方式一: 已经手动创建并打开了空工程目录

例如已经在 PyCharm 中打开:

```text
E:\PycharmProjects\NewTool
```

并且 PyCharm Terminal 当前位于:

```text
E:\PycharmProjects\NewTool
```

可以执行:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" init
```

`uv` 会在当前目录中初始化一个新的 Python 项目.

与 `--bare` 不同, 普通 `uv init` 可能同时创建一些基础项目文件.

因此执行以后应该先检查工程目录, 确认生成结果是否符合自己的项目结构要求, 再继续后面的步骤.

------

### 方式二: 直接让 uv 创建新的项目目录

如果项目目录本身都还没有创建, 可以先在准备存放项目的父目录中打开 PowerShell.

例如:

```powershell
cd "E:\PycharmProjects"
```

然后执行:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" init NewTool
```

这会创建类似:

```text
E:\PycharmProjects\NewTool
```

并在其中初始化 Python 项目.

完成以后再启动 PyCharm, 选择:

```text
Open
```

打开:

```text
E:\PycharmProjects\NewTool
```

然后打开 PyCharm Terminal, 使用:

```powershell
pwd
```

确认当前目录已经是新工程根目录.

------

## 12.3 应该选择哪一种

可以按下面判断:

```text
已有代码和目录结构
        ↓
uv init --bare
全新空工程
        ↓
uv init
连工程目录都没有
        ↓
uv init ProjectName
```

对于本文示例的 `UnityPackageStructurer`, 因为它原本已经存在代码和目录结构, 所以使用的是:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" init --bare
```

而不是普通的:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" init
```

------

# 13. 设置项目 Python 版本

使用 PyCharm 打开:

```text
pyproject.toml
```

本文希望这个项目明确使用 Python 3.12 系列.

因此将:

```toml
requires-python = ">=3.14"
```

修改为:

```toml
requires-python = ">=3.12,<3.13"
```

最终:

```toml
[project]
name = "unitypackagestructurer"
version = "0.1.0"
requires-python = ">=3.12,<3.13"
dependencies = []
```

这里使用:

```text
>=3.12,<3.13
```

意味着:

```text
允许 Python 3.12.x
不允许 Python 3.13 及更高版本
```

这样可以防止未来环境中安装了 Python 3.13 或 3.14 后, 项目在没有明确确认的情况下自动切换到更高 Python 版本.

------

# 14. 创建项目独立 `.venv`

确保当前仍然位于 PyCharm Terminal.

再次确认:

```powershell
pwd
```

应该显示:

```text
E:\PycharmProjects\UnityPackageStructurer
```

然后执行:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" venv --python "D:\Dev\App\Python\Python312\python.exe"
```

这里明确告诉 `uv`:

> 使用已经安装好的 `D:\Dev\App\Python\Python312\python.exe` 创建虚拟环境.

这样不会依赖 `uv` 自己选择其他 Python.

成功后应该看到类似:

```text
Using CPython 3.12.0 interpreter at: D:\Dev\App\Python\Python312\python.exe
Creating virtual environment at: .venv
Activate with: .venv\Scripts\activate
```

现在项目根目录应该出现:

```text
.venv
```

即:

```text
E:\PycharmProjects\UnityPackageStructurer\.venv
```

现在可以理解为:

```text
D:\Dev\App\Python\Python312\python.exe
        ↓
机器安装的基础 Python


E:\PycharmProjects\UnityPackageStructurer\.venv
        ↓
当前项目自己的 Python 环境
```

------

# 15. 在 PyCharm 中配置现有 uv 环境

创建 `.venv` 后, PyCharm 可能仍然显示:

```text
未为 unitypackagestructurer 配置 Python 解释器
```

这是因为:

> `.venv` 已经存在, 但 PyCharm 还不知道应该使用它.

文字版请阅读`15.1`至`15.5`的章节. 图片版见:
![image-20260826105744820](/assets/image/image-20260826105744820.png)

------

## 15.1 打开添加 Python Interpreter 界面

可以直接点击 PyCharm 提示栏中的:

```text
未为 unitypackagestructurer 配置 Python 解释器 提示 中的 "添加解释器"
```

或者进入:

```text
File(文件)
→ Settings(设置)
→ Python
→ Interpreter(解释器)
→ Add Interpreter(添加解释器)
```

不同版本 PyCharm 的具体文字可能略有区别.

------

## 15.2 环境选择“选择现有”

点击`Add Interpreter(添加解释器)`会打开`添加 Python 解释器`窗口.

此时, 将:

```text
环境
```

设置为:

```text
选择现有
```

不要选择:

```text
生成新的
```

因为 `.venv` 已经由 `uv` 创建完成.

------

## 15.3 类型选择 uv

将:

```text
类型
```

选择为:

```text
uv
```

PyCharm 默认可能显示:

```text
Python
```

需要从下拉列表中改为:

```text
uv
```

这里选择 `uv`, 是为了让 PyCharm 明确知道该项目环境由 `uv` 管理.

------

## 15.4 指定 uv.exe

接下来要指定:

```text
uv 的路径
```

点击右侧文件选择按钮.

选择:

```text
D:\Dev\App\Python\AstralUV\uv.exe
```

注意:

> 不要让 PyCharm 另外下载或安装一份 `uv`.

我们已经有自己规划好的 `uv`.

------

## 15.5 选择已有 `.venv`

指定正确的 `uv.exe` 后, PyCharm 应该能够识别当前工程的 `.venv`.

应该能够看到类似:

```text
Python 3.12

E:\PycharmProjects\UnityPackageStructurer\.venv\Scripts\python.exe
```

并且该环境会被标记为:

```text
uv
```

确认路径正确后点击:

```text
确定
```

------

## 15.6 检查 PyCharm 状态

配置完成以后:

```text
未配置 Python 解释器
```

提示应该消失.

重新打开或者观察 PyCharm Terminal 时, 提示符前可能出现:

```text
(UnityPackageStructurer)
```

例如:

```text
(UnityPackageStructurer) PS E:\PycharmProjects\UnityPackageStructurer>
```

这说明当前 Terminal 已经激活项目虚拟环境.

------

# 16. 添加 PySide6

现在开始给当前项目添加 PySide6.

在 PyCharm 中打开:

```text
Terminal
```

确认当前目录:

```powershell
pwd
```

应该仍然是:

```text
E:\PycharmProjects\UnityPackageStructurer
```

然后执行:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" add pyside6
```

注意:

本文没有把 `uv` 添加到 PATH.

因此本文所有实际需要执行的 `uv` 命令都使用:

```text
D:\Dev\App\Python\AstralUV\uv.exe
```

的完整路径.

不要改写成:

```powershell
uv add pyside6
```

否则当前系统会因为找不到全局 `uv` 命令而报错.

本文实际安装时得到:

```text
Resolved 5 packages in 3ms
Checked 4 packages in 2ms
```

只要没有出现错误信息, 即可继续检查结果.

------

# 17. 检查 pyproject.toml

执行上一节的:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" add pyside6
```

以后, 打开:

```text
pyproject.toml
```

其中的:

```toml
dependencies = []
```

应该已经发生变化.

例如类似:

```toml
[project]
name = "unitypackagestructurer"
version = "0.1.0"
requires-python = ">=3.12,<3.13"
dependencies = [
    "pyside6>=...",
]
```

具体版本约束以当前 `uv` 实际写入内容为准.

------

# 18. 检查 uv.lock

这一节不需要执行新的命令.

在第 16 节执行:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" add pyside6
```

以后, 查看工程根目录.

应该出现:

```text
uv.lock
```

例如:

```text
UnityPackageStructurer/
├── .venv/
├── pyproject.toml
├── uv.lock
└── ...
```

`uv.lock` 用来记录 `uv` 实际解析得到的依赖关系和版本.

可以理解成:

```text
pyproject.toml
    ↓
声明:
项目需要 PySide6


uv.lock
    ↓
记录:
实际解析出的 PySide6 版本
实际解析出的 Shiboken6 版本
其他间接依赖版本
```

因此:

```text
pyproject.toml
```

更像是“项目要求”.

而:

```text
uv.lock
```

更像是“这套要求经过依赖解析后的确定结果”.

------

# 19. 验证 PySide6

现在验证当前项目环境是否真的可以加载 PySide6.

打开 PyCharm Terminal.

如果已经正确配置 Interpreter, 终端前面可能显示:

```text
(UnityPackageStructurer)
```

执行:

```powershell
python -c "import PySide6; print(PySide6.__version__)"
```

这里可以直接使用:

```text
python
```

是因为当前 PyCharm Terminal 已经激活:

```text
UnityPackageStructurer\.venv
```

此时:

```powershell
python
```

实际指向的是当前项目 `.venv` 中的 Python.

本文实际得到:

```text
6.11.2
```

说明 PySide6 已经成功安装并且可以正常导入.

------

# 20. 最终环境关系

完成以后, 整个环境可以理解为:

```text
D:\Dev\App\Python\
│
├── Python312\
│   └── python.exe
│
└── AstralUV\
    ├── uv.exe
    ├── uvx.exe
    └── uvw.exe
```

以及:

```text
E:\PycharmProjects\
└── UnityPackageStructurer\
    │
    ├── .venv\
    │   └── Scripts\
    │       └── python.exe
    │
    ├── pyproject.toml
    ├── uv.lock
    │
    └── 项目代码...
```

它们的职责分别是:

```text
Python312
    ↓
机器安装的基础 Python Interpreter


AstralUV
    ↓
Python 项目、环境和依赖管理工具


pyproject.toml
    ↓
描述项目和直接依赖要求


uv.lock
    ↓
保存实际解析后的依赖结果


.venv
    ↓
当前项目独立的 Python 运行环境


PyCharm
    ↓
IDE
使用当前项目的 .venv 进行代码补全、运行和调试
```

------

# 21. 为什么不把 uv 加入 PATH

本文安装 `uv` 时明确使用了:

```text
UV_NO_MODIFY_PATH = "1"
```

因此:

```powershell
uv --version
```

以及:

```powershell
uv add pyside6
```

在普通 PowerShell 中会出现类似:

```text
无法将“uv”项识别为 cmdlet、函数、脚本文件或可运行程序的名称
```

这是预期行为, 不是安装失败.

本文选择这种做法, 是因为希望开发工具安装路径完全可控.

因此所有 `uv` 操作统一使用完整路径.

例如:

```powershell
& "D:\Dev\App\Python\AstralUV\uv.exe" --version
& "D:\Dev\App\Python\AstralUV\uv.exe" init --bare
& "D:\Dev\App\Python\AstralUV\uv.exe" venv --python "D:\Dev\App\Python\Python312\python.exe"
& "D:\Dev\App\Python\AstralUV\uv.exe" add pyside6
```

这样不会依赖系统 PATH 中是否存在 `uv`.

------

# 22. 哪些东西应该跟随工程

对于 Git 等版本管理系统, 可以将项目环境理解成两部分.

## 应该跟随工程

```text
pyproject.toml
uv.lock
Python 源代码
资源文件
配置文件
```

这些文件用于描述和构成项目.

## 不应该依赖复制的本地环境

```text
.venv
```

`.venv` 应该在每台机器上重新创建.

例如换了一台机器后, 不应该直接复制旧电脑上的:

```text
.venv
```

而应该重新根据项目配置建立环境.

------

# 23. 推荐的 .gitignore

项目使用 Git 时, 建议至少忽略:

```gitignore
.venv/
__pycache__/
*.pyc
```

PyCharm 的:

```text
.idea/
```

是否提交可以根据团队自己的 JetBrains 项目配置策略决定.

如果不希望保存本机 IDE 配置, 也可以加入:

```gitignore
.idea/
```

------

# 24. 新电脑重新配置时的思路

换电脑以后, 正确恢复流程是:

```text
安装基础 Python
        ↓
安装 uv
        ↓
Clone / Copy 项目
        ↓
使用 uv 创建新的项目 .venv
        ↓
恢复项目依赖
        ↓
打开 PyCharm
        ↓
让 PyCharm 指向新的 .venv
```

不要复制另一台电脑生成的:

```text
.venv
```

项目环境应该根据:

```text
pyproject.toml
+
uv.lock
```

重新建立.

------

# 25. 本文实际验证版本

本文实际配置和验证使用:

```text
Python 3.12.0
uv 0.12.5
PySide6 6.11.2
```

实际路径:

```text
Python:
D:\Dev\App\Python\Python312\python.exe
uv:
D:\Dev\App\Python\AstralUV\uv.exe
Project:
E:\PycharmProjects\UnityPackageStructurer
Project Virtual Environment:
E:\PycharmProjects\UnityPackageStructurer\.venv
```

这些版本只是本文实际验证环境.

如果以后使用更新版本, 操作界面或输出文字可能略有不同.

------

# 26. 最终检查 Checklist

完成全部操作后, 可以逐项检查:

-  Python 3.12 可以通过绝对路径正常运行.
-  `uv.exe` 位于自己规划的目录.
-  使用 `uv.exe` 完整路径可以正常显示版本号.
-  PyCharm 已经打开正确的工程根目录.
-  PyCharm Terminal 的当前目录是工程根目录.
-  工程根目录存在 `pyproject.toml`.
-  `requires-python` 已设置为需要的 Python 版本范围.
-  工程根目录存在 `.venv`.
-  `.venv` 基于指定 Python 3.12 创建.
-  PyCharm Interpreter 类型选择了 `uv`.
-  PyCharm 使用的是项目自己的 `.venv`.
-  PyCharm 中已经指定正确的 `uv.exe`.
-  PySide6 已通过完整 `uv.exe` 路径添加.
-  `pyproject.toml` 中存在 PySide6 依赖.
-  工程根目录存在 `uv.lock`.
-  `import PySide6` 可以正常执行.
-  `PySide6.__version__` 可以正常输出.

全部通过以后, Python + uv + PyCharm + PySide6 的项目级开发环境就已经配置完成.

接下来即可开始正式开发 PySide6 / Qt 桌面工具.
