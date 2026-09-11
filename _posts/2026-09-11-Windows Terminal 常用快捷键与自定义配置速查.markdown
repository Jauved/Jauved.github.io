---
layout: post
title: "Windows Terminal 常用快捷键与自定义配置速查"
categories: [Windows, Terminal]
tags: Windows WindowsTerminal Terminal CLI 命令行
math: true


---

# Windows Terminal 常用快捷键与自定义配置速查

Windows Terminal 支持标签页, Pane 分屏, 命令面板以及自定义快捷键. 如果经常同时使用 PowerShell, CMD, WSL 或其他命令行环境, 熟悉其中几个高频快捷键可以明显减少鼠标操作.

本文以当前 Windows Terminal 官方默认配置为准.

## 1. 优先记住这些快捷键

不需要一开始记住全部快捷键. 对日常使用而言, 建议优先掌握下面这些:

```text
Ctrl+Shift+T          New Tab
Ctrl+Shift+W          Close Pane / Tab
Ctrl+Tab              Next Tab

Alt+Shift++           Vertical Split
Alt+Shift+-           Horizontal Split
Alt+方向键             Switch Pane
Alt+Shift+方向键       Resize Pane

Ctrl+Shift+F          Find
Ctrl+Shift+P          Command Palette
Ctrl+,                Settings
Ctrl+Shift+,          settings.json
```

其中最值得记住的是:

```text
Ctrl+Shift+P
```

它会打开 Command Palette. Windows Terminal 的大部分 Action 都可以从这里搜索执行, 因此没有必要机械记忆所有快捷键.

建议的使用顺序是:

```text
先记住高频快捷键
        ↓
忘记功能时使用 Command Palette
        ↓
发现某个 Action 经常使用
        ↓
再为它建立自己的快捷键
```

## 2. 基础操作

| 功能                 | 快捷键         |
| -------------------- | -------------- |
| 复制                 | `Ctrl+Shift+C` |
| 粘贴                 | `Ctrl+Shift+V` |
| 搜索终端内容         | `Ctrl+Shift+F` |
| 命令面板             | `Ctrl+Shift+P` |
| 打开设置界面         | `Ctrl+,`       |
| 打开 `settings.json` | `Ctrl+Shift+,` |
| 全屏                 | `Alt+Enter`    |

Windows Terminal 当前也支持普通的:

```text
Ctrl+C
Ctrl+V
```

进行复制和粘贴.

其中 `Ctrl+C` 会根据当前状态决定行为:

```text
存在文本选择
    ↓
复制

没有文本选择
    ↓
传递给 Shell
    ↓
通常表示中断当前程序
```

因此不会破坏命令行中常用的 `Ctrl+C` 中断操作.

## 3. Pane 分屏

Pane 是 Windows Terminal 最实用的功能之一. 一个标签内部可以同时运行多个终端.

| 功能                       | 快捷键             |
| -------------------------- | ------------------ |
| 垂直分屏, 新 Pane 位于右侧 | `Alt+Shift++`      |
| 水平分屏, 新 Pane 位于下方 | `Alt+Shift+-`      |
| 自动分屏并复制当前 Pane    | `Alt+Shift+D`      |
| 切换 Pane 焦点             | `Alt+方向键`       |
| 调整 Pane 大小             | `Alt+Shift+方向键` |
| 关闭当前 Pane              | `Ctrl+Shift+W`     |

这里的 `vertical` 和 `horizontal` 描述的是分割线方向:

```text
vertical

Pane A | Pane B
```

得到左右两个 Pane.

```text
horizontal

Pane A
------
Pane B
```

得到上下两个 Pane.

Windows Terminal 也支持 `auto`, 根据当前 Pane 的尺寸自动决定分割方向.

对于开发环境, 一个比较常见的布局是:

```text
Editor
  |
Windows Terminal
  ├─ PowerShell / Git
  ├─ Build
  └─ Log / Server
```

这种情况下, 使用 Pane 通常比反复打开多个独立 Terminal 窗口更方便.

## 4. 标签页

标签页适合区分不同工作上下文, 例如:

```text
Project A
Project B
WSL
Server
Logs
```

常用快捷键如下:

| 功能                 | 快捷键           |
| -------------------- | ---------------- |
| 新建标签             | `Ctrl+Shift+T`   |
| 下一个标签           | `Ctrl+Tab`       |
| 上一个标签           | `Ctrl+Shift+Tab` |
| 跳转到第 1~8 个标签  | `Ctrl+Alt+1~8`   |
| 复制当前标签         | `Ctrl+Shift+D`   |
| 关闭当前 Pane / 标签 | `Ctrl+Shift+W`   |
| 关闭窗口             | `Alt+F4`         |

有两组数字快捷键容易混淆:

```text
Ctrl+Alt+1~8
```

切换到指定序号的标签页.

而:

```text
Ctrl+Shift+1~9
```

表示使用对应序号的 Profile 创建新的标签页.

另外, `Ctrl+Shift+W` 对应的是 `closePane`.

如果当前标签存在多个 Pane, 它会关闭当前 Pane.

如果当前标签只有一个 Pane, 它会关闭当前标签.

如果窗口中只剩最后一个标签, 最终会关闭窗口.

## 5. 字体和滚动

| 功能             | 快捷键            |
| ---------------- | ----------------- |
| 放大字体         | `Ctrl++`          |
| 缩小字体         | `Ctrl+-`          |
| 恢复默认字体大小 | `Ctrl+0`          |
| 向上翻一页       | `Ctrl+Shift+PgUp` |
| 向下翻一页       | `Ctrl+Shift+PgDn` |
| 跳到历史顶部     | `Ctrl+Shift+Home` |
| 跳到历史底部     | `Ctrl+Shift+End`  |

其中:

```text
Ctrl++
Ctrl+-
Ctrl+0
```

分别对应调整字号和恢复默认字号.

查看大量编译日志或运行日志时, `Ctrl+Shift+Home / End` 也比较实用.

## 6. Command Palette

使用:

```text
Ctrl+Shift+P
```

打开 Command Palette.

可以直接搜索 Action, 例如:

```text
Split Pane
Duplicate Pane
Rename Tab
Toggle Pane Zoom
Focus Mode
Change Color Scheme
```

它的一个重要作用是降低快捷键的记忆成本.

整个操作逻辑可以理解为:

```text
用户输入快捷键
        ↓
Windows Terminal Action
        ↓
执行对应操作
```

而 Command Palette 本质上就是这些 Action 的搜索入口.

因此 Windows Terminal 中某个功能"找不到快捷键"时, 可以先在 Command Palette 中搜索对应 Action.

## 7. 自定义快捷键

Windows Terminal 的快捷键建立在 Action 系统上.

对于较大的配置, 推荐将 Action 和 Key Binding 分离, 使用 `id` 建立关联:

```json
{
    "actions": [
        {
            "command": "newTab",
            "id": "User.NewTab"
        },
        {
            "command": {
                "action": "splitPane",
                "split": "vertical"
            },
            "id": "User.SplitVertical"
        },
        {
            "command": "togglePaneZoom",
            "id": "User.TogglePaneZoom"
        }
    ],

    "keybindings": [
        {
            "keys": "ctrl+n",
            "id": "User.NewTab"
        },
        {
            "keys": "alt+shift+v",
            "id": "User.SplitVertical"
        },
        {
            "keys": "alt+z",
            "id": "User.TogglePaneZoom"
        }
    ]
}
```

这种方式相当于:

```text
Action
  ↓
ID
  ↓
Key Binding
```

Action 本身和具体快捷键解耦.

这样做有几个好处:

- 修改快捷键时不需要修改 Action.
- 同一个 Action 可以绑定不同按键.
- 配置规模较大时更容易维护.
- Action 可以同时被快捷键和 Command Palette 使用.

对于非常简单的配置, 也可以直接在 Action 中指定 `keys`.

## 8. 快捷键冲突和 Unbind

Terminal 的快捷键可能和 Vim, Tmux 或终端内部程序发生冲突.

原因是快捷键存在两层处理:

```text
Keyboard
   ↓
Windows Terminal
   ↓
Shell / Vim / Tmux / Application
```

如果 Windows Terminal 已经消费了某个快捷键, 底层程序就可能无法收到它.

此时可以解除 Terminal 对这个按键的绑定.

例如:

```json
{
    "keybindings": [
        {
            "id": null,
            "keys": "ctrl+v"
        }
    ]
}
```

解除后:

```text
Ctrl+V
  ↓
Windows Terminal 不处理
  ↓
继续传递给终端内部程序
```

因此如果发现 Vim, Tmux 或某个 CLI 工具的快捷键失效, 可以优先检查 Windows Terminal 是否已经占用了相同键位.

## 9. 全局呼出 Terminal

Windows Terminal 还支持 `globalSummon` 和 `quakeMode`.

`globalSummon` 可以注册系统级快捷键, 在使用其他程序时快速呼出已经运行的 Terminal.

`quakeMode` 则是一种特殊的 Terminal 窗口模式, 效果类似游戏中的下拉控制台.

例如:

```json
{
    "actions": [
        {
            "command": {
                "action": "globalSummon",
                "name": "_quake",
                "dropdownDuration": 200,
                "toggleVisibility": true
            },
            "id": "User.QuakeTerminal"
        }
    ],

    "keybindings": [
        {
            "keys": "ctrl+alt+`",
            "id": "User.QuakeTerminal"
        }
    ]
}
```

之后可以通过:

```text
Ctrl+Alt+`
```

快速显示或隐藏 Terminal.

需要注意, `globalSummon` 依赖已经运行的 Windows Terminal 实例, 同时系统级快捷键不能和其他程序已经注册的快捷键冲突.

## 10. 使用建议

Windows Terminal 的快捷键很多, 但实际上没有必要全部记住.

更推荐按照下面的方式逐步建立自己的操作习惯:

```text
高频操作
    ↓
记住默认快捷键

低频操作
    ↓
Command Palette

反复使用的低频操作
    ↓
自定义快捷键
```

如果只保留一组核心快捷键, 可以记住:

```text
Ctrl+Shift+T          New Tab
Ctrl+Shift+W          Close

Alt+Shift++           Split Right
Alt+Shift+-           Split Down
Alt+方向键             Switch Pane

Ctrl+Shift+F          Find
Ctrl+Shift+P          Command Palette
```

这几个快捷键已经可以覆盖 Windows Terminal 中绝大多数高频操作.

## 参考资料

- [Windows Terminal - Custom actions](https://learn.microsoft.com/windows/terminal/customize-settings/actions)
- [Windows Terminal - Panes](https://learn.microsoft.com/windows/terminal/panes)
- [Windows Terminal - Tips and tricks](https://learn.microsoft.com/windows/terminal/tips-and-tricks)
- [Windows Terminal documentation](https://learn.microsoft.com/windows/terminal/)
- [Windows Terminal 快捷键速览](https://blog.csdn.net/gitblog_00157/article/details/152097487)
