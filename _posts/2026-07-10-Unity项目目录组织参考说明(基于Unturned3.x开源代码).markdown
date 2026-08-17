---
layout: post
title: "Unity项目目录组织参考说明(基于Unturned3.x开源代码)"
categories: [Unity, 工程架构]
tags: Unity 工程结构 项目目录组织 Unturned U3-SDK 技术美术 EditorTool Runtime Assets
math: false


---

# Unity项目目录组织参考说明(基于Unturned3.x开源代码)

## 1. 参考来源

本项目的目录组织参考对象为:

```text
SmartlyDressedGames/U3-SDK
https://github.com/SmartlyDressedGames/U3-SDK
```

该仓库是游戏 **Unturned 3.x** 的官方 Unity SDK / 源码工程。它不是普通 Unity 插件, 也不是教程 demo, 而是一个长期运营游戏公开出来的完整 Unity 工程。

参考该仓库的目的不是照搬它的全部目录, 而是借鉴它在大型 Unity 项目中的组织思路:

```text
运行时代码, 编辑器工具, 游戏资源源文件, 第三方依赖, 构建配置, 项目设置, 测试与自动化流程需要有清晰边界。
```

------

## 2. 核心参考原则

### 2.1 不把所有内容都堆在 Assets 根目录

大型 Unity 项目不应只使用如下简单结构:

```text
Assets/
├── Scripts/
├── Materials/
├── Textures/
└── Prefabs/
```

这种结构适合小 demo, 但项目变大后会出现以下问题:

```text
代码和资源边界不清晰
运行时代码和 Editor 代码混杂
资源源文件和最终使用资源混杂
第三方插件和自研代码混杂
构建工具和游戏逻辑混杂
```

更合理的方式是先按工程职责分层, 再在每一层内部按系统或资源类型细分。

------

### 2.2 Runtime 和 Editor 必须严格分离

运行时代码和编辑器工具代码必须分开。

参考目标:

```text
Assets/
├── Runtime/
└── Editor/
```

含义:

```text
Runtime: 游戏运行时需要进入构建包的代码。
Editor: 只在 Unity Editor 中运行的工具代码, 不进入最终构建。
```

这样可以避免:

```text
Editor API 被错误打进运行时
平台构建失败
运行时代码依赖编辑器工具
工具代码污染游戏逻辑
```

------

### 2.3 游戏资源源文件应集中管理

参考 U3-SDK 中的结构:

```text
Assets/Game/Sources/
├── Animations/
├── Models/
├── Scenes/
├── Shaders/
├── Skins/
└── Textures/
```

该结构的重点是: 把“游戏资源源文件”放在统一位置。

对于自己的项目, 可以使用类似结构:

```text
Assets/Game/
├── Sources/
│   ├── Models/
│   ├── Textures/
│   ├── Animations/
│   ├── Shaders/
│   └── Scenes/
├── Prefabs/
├── Materials/
└── Art/
```

其中:

```text
Sources: 原始导入源文件, 例如 fbx, blend, psd, 源贴图, 原始 shader 等。
Prefabs: 项目实际使用的 prefab。
Materials: 项目实际使用的材质。
Art: 已整理好的美术资源。
```

原则是:

```text
源文件, 中间资产, 最终游戏使用资产需要有区分。
```

------

## 3. 推荐目录组织草案

项目初期可以参考以下结构:

```text
ProjectRoot/
├── Assets/
│   ├── Game/
│   │   ├── Sources/
│   │   │   ├── Models/
│   │   │   ├── Textures/
│   │   │   ├── Animations/
│   │   │   ├── Shaders/
│   │   │   └── Scenes/
│   │   ├── Prefabs/
│   │   ├── Materials/
│   │   ├── Scenes/
│   │   └── UI/
│   │
│   ├── Runtime/
│   │   ├── Core/
│   │   ├── Rendering/
│   │   ├── Gameplay/
│   │   ├── UI/
│   │   ├── Data/
│   │   └── Utilities/
│   │
│   ├── Editor/
│   │   ├── Tools/
│   │   ├── Inspectors/
│   │   ├── Build/
│   │   └── Utilities/
│   │
│   ├── Plugins/
│   ├── Resources/
│   └── Tests/
│
├── Packages/
├── ProjectSettings/
├── Builds/
├── Tools/
├── Docs/
└── README.md
```

------

## 4. 各目录目的说明

### 4.1 Assets/Game

用于放项目本身的游戏资源。

建议内容:

```text
场景
Prefab
材质
贴图
模型
动画
UI 资源
美术源文件
```

它关注的是“游戏内容资产”, 而不是通用代码框架。

------

### 4.2 Assets/Game/Sources

用于放原始资源源文件。

例如:

```text
fbx
blend
psd
spp
高精度源贴图
原始 shader 实验文件
导入前的动画文件
```

这个目录的目的不是让游戏直接引用所有内容, 而是作为资源生产链路的输入区。

------

### 4.3 Assets/Runtime

用于放运行时代码。

建议按系统或功能域拆分:

```text
Assets/Runtime/
├── Core/
├── Rendering/
├── Gameplay/
├── UI/
├── Data/
└── Utilities/
```

含义:

```text
Core: 基础框架, 生命周期, 调度, 公共接口。
Rendering: 渲染相关代码, 例如 RendererFeature, RenderPass, 材质控制, 后处理。
Gameplay: 玩法逻辑。
UI: 运行时 UI 逻辑。
Data: 配置读取, 数据结构, 数据表。
Utilities: 通用工具类。
```

如果系统变大, 可以继续拆 asmdef 或独立 package。

------

### 4.4 Assets/Editor

用于放 Unity Editor 专用工具。

建议内容:

```text
自定义 Inspector
EditorWindow
资源处理工具
批处理工具
构建辅助工具
调试工具
```

原则:

```text
凡是依赖 UnityEditor 命名空间的代码, 都必须放在 Editor 目录或 Editor-only asmdef 中。
```

------

### 4.5 Assets/Plugins

用于放第三方插件或原生库。

建议只放确实需要放在 Assets 下的插件, 例如:

```text
native dll
aar
so
第三方 Unity 插件
特殊平台插件
```

如果依赖可以通过 Unity Package Manager 管理, 优先放到 `Packages/manifest.json`。

------

### 4.6 Assets/Resources

保留, 但谨慎使用。

`Resources` 适合少量必须通过路径动态加载的资源, 但不建议作为主要资源管理方式。

原因:

```text
引用不透明
容易导致包体膨胀
资源卸载不清晰
大型项目中难以追踪依赖
```

原则:

```text
能不用 Resources 就不用。
必须使用时, 保持目录小而明确。
```

------

### 4.7 Assets/Tests

用于放测试代码和测试场景。

可以按类型拆分:

```text
Assets/Tests/
├── EditMode/
└── PlayMode/
```

目的:

```text
验证工具代码
验证运行时逻辑
验证资源处理流程
验证关键系统回归
```

------

### 4.8 Packages

用于 Unity Package Manager 依赖管理。

这里应管理:

```text
Unity 官方包
第三方 UPM 包
本地 package
自研 package
```

原则:

```text
通用模块优先 package 化。
项目专用逻辑留在 Assets/Runtime。
```

------

### 4.9 ProjectSettings

Unity 工程设置目录。

该目录必须纳入版本管理。

包括:

```text
渲染管线设置
输入设置
标签和层
质量设置
平台设置
图形 API 设置
Package Manager 设置
```

------

### 4.10 Builds

用于放本地构建输出或构建相关配置。

建议不要把大型构建产物提交到 Git。

可以保留少量构建配置文件, 例如:

```text
BuildProfile
BuildConfig
VersionInfo
ModInfo
Status
```

------

### 4.11 Tools

用于放 Unity 外部工具脚本。

例如:

```text
Python 脚本
PowerShell 脚本
批处理脚本
资源检查脚本
构建流水线脚本
代码生成脚本
```

这个目录和 `Assets/Editor` 的区别是:

```text
Assets/Editor: 在 Unity Editor 内运行。
Tools: 在 Unity 外部运行。
```

------

### 4.12 Docs

用于放项目文档。

建议内容:

```text
目录组织说明
编码规范
资源导入规范
渲染系统说明
构建流程说明
工具使用说明
已确认结论
未确认问题
```

对于长期项目, `Docs` 应该作为项目黑板使用。

------

## 5. 从 U3-SDK 借鉴的关键点

### 5.1 真实项目会有历史包袱

U3-SDK 仍保留大量主体代码在 `Assembly-CSharp` 中, 并没有强行一次性重构到完美模块化结构。

这说明大型 Unity 项目的目录组织不一定从第一天就是最终形态。

更合理的方式是:

```text
旧系统保持稳定
新系统逐步模块化
高风险迁移分阶段完成
不要为了目录“漂亮”破坏现有资产引用
```

------

### 5.2 新模块可以逐步独立

U3-SDK 中除了历史主体代码外, 也能看到一些独立模块, 例如网络, UI 抽象, 系统扩展等。

自己的项目也可以采用类似策略:

```text
核心系统先放 Runtime
稳定后再拆 asmdef
可复用后再拆 package
跨项目复用后再独立仓库
```

不要一开始就过度 package 化。

------

### 5.3 资源生产链路需要独立位置

U3-SDK 将游戏资源源文件集中在 `Assets/Game/Sources`。

这对技术美术项目尤其重要。

建议原则:

```text
原始文件放 Sources
处理后资源放正式资源目录
运行时只引用正式资源
工具链可以读取 Sources
```

这样有利于后续做:

```text
资源导入规范
批量处理
AssetBundle
Addressables
资源检查
自动化构建
```

------

### 5.4 构建和工具链也属于项目结构的一部分

大型 Unity 项目不只是 `Assets`。

还需要管理:

```text
构建脚本
CI 脚本
测试配置
平台配置
版本信息
外部工具
发布辅助文件
```

因此目录组织必须覆盖 Unity 外部流程。

------

## 6. 当前项目采用该参考时的执行原则

本项目可以参考 U3-SDK 的工程思想, 但不照搬它的全部结构。

执行原则如下:

```text
1. 先按职责分层, 再按功能细分。
2. Runtime 和 Editor 严格分离。
3. 游戏资源和通用代码分离。
4. 原始资源源文件和最终游戏资源分离。
5. 第三方依赖和自研代码分离。
6. 构建工具和游戏逻辑分离。
7. 项目初期不要过度抽象。
8. 系统稳定后再考虑 asmdef, package 化和独立仓库。
```

------

## 7. 后续和 AI 讨论项目结构时的默认前提

后续讨论本项目目录组织时, 默认以本说明为参考。

当需要新增系统时, 优先判断它属于哪一类:

```text
游戏内容资产 -> Assets/Game
运行时代码 -> Assets/Runtime
编辑器工具 -> Assets/Editor
第三方依赖 -> Assets/Plugins 或 Packages
外部脚本工具 -> Tools
项目文档 -> Docs
测试内容 -> Assets/Tests
构建输出或构建配置 -> Builds
```

当目录选择不明确时, 优先遵循以下判断:

```text
是否进入最终构建?
是 -> Runtime 或 Game
否 -> Editor, Tools, Docs, Tests

是否依赖 UnityEditor?
是 -> Editor
否 -> Runtime 或普通资源目录

是否是项目专用?
是 -> Assets
否 -> Packages 或 Plugins

是否是原始资源源文件?
是 -> Game/Sources
否 -> Game 下的正式资源目录
```

------

## 8. 简短总结

本项目目录组织参考 `SmartlyDressedGames/U3-SDK`, 即 Unturned 3.x 的官方 Unity SDK / 源码工程。

参考重点不是具体文件名, 而是大型 Unity 项目的组织原则:

```text
代码分层
资源分层
运行时和编辑器分离
源文件和成品资源分离
项目逻辑和工具链分离
历史系统稳定保留
新系统逐步模块化
```

该参考适合用于中大型 Unity 项目, 尤其适合包含渲染系统, 技术美术工具, 编辑器扩展, 资源处理流程和长期维护需求的项目。
