---
layout: post
title: "Unity UPM 使用 Git Package 替换内置 Built-in Package"
categories: [Unity, UPM]
tags: Unity UPM Git Package Built-in URP
math: false


---

# Unity UPM 使用 Git Package 替换内置 Built-in Package

# W - 直接使用

## 1. 使用 Git URL 替换 Built-in Package

修改工程中的 `Packages/manifest.json`, 将原来的版本依赖:

```
"com.unity.render-pipelines.universal": "14.1.0"
```

替换为:

```
"com.unity.render-pipelines.universal": "git+https://git.example.com/graphics/upm-packages.git?path=/Packages/com.unity.render-pipelines.universal@14.1.0#dev"
```

其中:

- `git.example.com/graphics/upm-packages.git`: Git 仓库地址.
- `?path=`: Package 在 Git 仓库中的相对目录.
- `#dev`: 指定 Git 分支.

**已验证: 可以通过 Git URL + 子目录 + 分支的方式, 替换团结引擎中原本解析为 Built-in 的 URP 14.1.0.**

该方案不需要修改 Package 名称, 也不需要将 Package 源码提交到主工程 Git.

前提是本机已安装 Git, 具有仓库读取权限, 并且目标目录下存在有效的 `package.json`.

## 2. 更新 Git Package

当远程仓库有新提交后:

1. 打开 `Window > Package Manager`.
2. 在 `In Project` 中找到对应 Package.
3. 点击 `Update`, 更新到 Git 分支的最新提交.

如果没有 Update 按钮, 或更新没有生效:

1. 点击 `+ > Add package from git URL`.
2. 重新输入相同的 Git URL.
3. 点击 `Add`, 让 UPM 重新解析远程分支.

完成后, 检查并提交更新后的 `Packages/packages-lock.json`.

注意: Git 分支更新后, UPM 不保证自动同步最新提交.

## 3. 验证是否替换成功

打开 `Packages/packages-lock.json`, 查找目标 Package.

成功时应看到类似结果:

```
"com.unity.render-pipelines.universal": {
  "version": "git+https://git.example.com/graphics/upm-packages.git?path=/Packages/com.unity.render-pipelines.universal@14.1.0#dev",
  "depth": 0,
  "source": "git",
  "dependencies": {
    "com.unity.render-pipelines.core": "14.1.0",
    "com.unity.shadergraph": "14.1.0"
  },
  "hash": "<resolved-git-commit-hash>"
}
```

以上为简化示例, 实际依赖以 Package 自身声明为准.

关键检查:

- `source: git`: 已使用 Git Package.
- `version`: 指向预期的仓库、子目录和分支.
- `hash`: 当前锁定的 Git Commit.

如果仍为 `source: builtin`, 说明尚未成功替换.

# I - 配置说明

## 1. Git URL 的组成

完整格式:

```
git+https://<Git仓库地址>.git?path=/<Package目录>#<分支或Tag>
```

| 参数                | 作用                |
| ------------------- | ------------------- |
| `git+https://`      | 明确声明 Git 依赖   |
| `.git`              | Git 仓库地址        |
| `?path=/...`        | 指定 Package 子目录 |
| `#dev`              | 指定分支            |
| `#v14.1.0`          | 指定 Tag            |
| `#<完整CommitHash>` | 指定固定提交        |

`git+` 是 UPM 用于识别 Git 依赖的前缀, 不会作为 Git 协议的一部分传递给 Git.

### Git 子目录

假设仓库结构为:

```
upm-packages/
└── Packages/
    ├── com.example.package-a/
    │   └── package.json
    ├── com.example.package-b/
    │   └── package.json
    └── com.unity.render-pipelines.universal@14.1.0/
        ├── package.json
        ├── Runtime/
        ├── Editor/
        └── Shaders/
```

即使仓库包含多个 Package, UPM 也可以通过 `?path=` 只注册指定的 Package.

需要注意:

- 路径相对于 Git 仓库根目录.
- 目标目录必须包含 `package.json`.
- `package.json` 中的 `name` 必须与依赖名称一致.
- `?path=` 必须位于 `#分支` 之前.

如果目标 Package 位于仓库根目录, 可以直接省略 `?path=`.

## 2. Git 账号与认证

Unity UPM 使用本机 Git 访问仓库, 不需要在 `manifest.json` 中配置账号和密码.

常见认证方式:

- HTTPS + Git Credential Manager.
- HTTPS + Personal Access Token (PAT).
- SSH + SSH Key.

Windows 推荐使用 Git Credential Manager, 让 Git 通过系统凭据管理器获取认证信息.

检查当前配置:

```
git config --global --get credential.helper
```

可以通过以下命令提前验证访问权限:

```
git ls-remote https://git.example.com/graphics/upm-packages.git refs/heads/dev
```

如果能够正常返回 Commit Hash, 表明当前 Git 环境能够读取目标分支.

**不要将账号、密码或 Token 直接写入** `**manifest.json**`**.**

优先使用 HTTPS 或 SSH. 如果内部服务器仅支持 HTTP, 需要额外考虑凭据传输的安全性.

## 3. Git 分支更新与 Lock 文件

Git URL 可以指定分支, 但 UPM 并不会保证每次启动编辑器都拉取远程最新提交.

例如:

```
Git dev 分支
    |
    ├── Commit A
    ├── Commit B
    └── Commit C
```

即使远程已经更新到 Commit C, 当前工程的 `packages-lock.json` 仍可能锁定 Commit A.

UPM 使用 Lock 文件固定 Git Commit, 以保证不同开发者解析到相同的 Package 版本.

因此, 推荐的更新流程为:

```
修改 Package
    ↓
Push 到远程 Git
    ↓
Unity Package Manager 更新
    ↓
检查 packages-lock.json 中的 hash
    ↓
测试通过
    ↓
提交 packages-lock.json
```

对于正式发布版本, 可以考虑使用 Git Tag 或完整 Commit Hash 固定依赖, 减少开发分支持续变化产生的不确定性.

# S - 机制与限制

## 1. 为什么 Scoped Registry 没有成功?

本次实际遇到的情况:

- 已将修改版 URP 14.1.0 发布到私有 UPM Registry.
- 包名与编辑器内置 URP 完全相同.
- 在 `scopedRegistries` 中精确添加 `com.unity.render-pipelines.universal`.
- 删除 `packages-lock.json`, 重新启动编辑器.
- 解析结果仍为 `source: builtin`.

之后尝试添加:

```
"overrideBuiltIns": true
```

实际测试依然无效.

最终改为显式 Git URL 依赖后, `source` 成功变为 `git`.

这说明在本次使用的编辑器版本及工程环境中, **Git URL 能够替换原先解析为 Built-in 的 URP, 而 Scoped Registry 未能实现这一目标**.

需要注意, 这是本次工程的实际验证结果, 不代表所有 Unity / 团结引擎版本具有完全相同的 Package 解析行为.

## 2. 不同 Package Source 的区别

| Source          | 来源               | 特点                        |
| --------------- | ------------------ | --------------------------- |
| `builtin`       | 编辑器内置         | 随编辑器提供                |
| `registry`      | UPM Registry       | 使用版本号和 Registry 管理  |
| `git`           | Git 仓库           | 使用 Git URL 和 Commit 管理 |
| `embedded`      | 工程 Packages 目录 | 直接使用工程内的 Package    |
| `local`         | 本地文件夹         | 使用本地路径引用            |
| `local-tarball` | 本地 `.tgz`        | 从本地归档安装              |

在本次测试中, 显式声明 Git URL 后, UPM 将目标 Package 解析为 `git`, 而不再使用原来的 `builtin`.

这是判断替换成功的直接证据.

但不能仅凭这一次测试推导所有 Source 之间的通用优先级. 不同 Unity 版本、包类型及项目配置可能存在不同处理规则.

## 3. Git Package 的限制

### Git 子目录不等于只下载子目录

`?path=` 决定最终注册哪个 Package, 并不意味着 Git 网络传输只会获取该目录的文件.

如果 Git 仓库包含大量 Package 或较长历史, 首次获取可能比较慢.

### Git Package 无法直接作为其他 Package 的 Git 依赖

Git URL 依赖需要配置在工程的 `Packages/manifest.json` 中.

Unity 2022.3 的 UPM 不支持在一个 Package 的 `package.json` 依赖列表中直接声明另一个 Git URL 依赖.

### 不会自动替换其他相关 Package

例如通过 Git 替换:

```
com.unity.render-pipelines.universal
```

并不会自动替换:

```
com.unity.render-pipelines.core
com.unity.shadergraph
```

这些依赖仍然按照各自的配置独立解析.

如果修改版 URP 依赖 Core 或 ShaderGraph 的自定义接口, 必须额外处理版本兼容性.

### 更新频繁时建议采用独立版本管理

开发阶段可以使用:

```
#dev
```

正式发行时更建议使用稳定的 Tag 或固定 Commit.

这样可以明确每个工程使用的代码版本, 便于回滚及问题追踪.

## 4. 其他方案及验证结果

| 方案                                | 本次结论                             |
| ----------------------------------- | ------------------------------------ |
| 私有 UPM Registry + Scoped Registry | 未成功覆盖 Built-in                  |
| `overrideBuiltIns`                  | 实测无效                             |
| Git URL + 子目录 + 分支             | 已验证成功                           |
| npm 下载 + Embedded Package         | 可作为备选, 本次未实际验证           |
| 修改 Package 名称                   | 不推荐, 可能造成重复程序集和依赖冲突 |

对于已经能通过 Git URL 正常替换的工程, 无需增加额外下载脚本或重新维护一份 Embedded Package.

# E - 参考资料

- [Unity - Git Dependencies](https://docs.unity.cn/2022.3/Documentation/Manual/upm-git.html)
- [Unity - Install a Package from a Git URL](https://docs.unity.cn/2022.3/Documentation/Manual/upm-ui-giturl.html)
- [Unity - Switching to Another Package Version](https://docs.unity.cn/2022.3/Documentation/Manual/upm-ui-update.html)
- [Unity - Scoped Registries](https://docs.unity.cn/2022.3/Documentation/Manual/upm-scoped.html)
- [Unity - Embedded Dependencies](https://docs.unity.cn/2022.3/Documentation/Manual/upm-embed.html)
