---
layout: post
title: "[LookDev开发] 定制Unity编辑器界面布局"
categories: [Unity, 编辑器]
tags: Unity lookdev 编辑器 自定义
math: true


---

# [LookDev开发] 定制Unity编辑器界面布局

## 原理

unity的界面是通过调用一个`.mode`文件来进行初始化的, 同样也可以通过自定义`.mode`文件来制作我们自己的初始化界面

## 前端代码

打印Unity目前载入的所有的界面布局

```c#
foreach (string modeName in ModeService.modeNames)
{
    Debug.Log(modeName);
}
```

切换布局

```C#
namespace LookDev.EditorUtilities
{
    public static class RenderLookDevEditor
    {
        [MenuItem("LookDev/Enable")]
        public static void EnableLookDev()
        {
            foreach (string modeName in ModeService.modeNames)
            {
                Debug.Log(modeName);
            }
            ModeService.ChangeModeById("lookdevmode");
        }

        [CommandHandler("Commands/Return to Unity", CommandHint.Menu | CommandHint.Validate)]
        private static void DisableLookDev(CommandExecuteContext context)
        {
            ModeService.ChangeModeById("default");
        }
    }
}
```

需要调用的`.mode`文件内容, `.mode`文件可以放置在

- `Unity.exe Path/Data/Resources/default.mode （EditorApplication.applicationContentsPath + “/Resources/default.mode”`
- `Package`中, 一般我会习惯放置在`Editor/Mode`文件夹里

```json
// https://qiita.com/Shiranui_Isuzu/items/b2ca640a75457311f62e
// ModeService.ChangeModeById("lookdevmode");调用的时候用到的字符串
lookdevmode = {
    // startup = true // 具体作用不明
    label = "LookDevMode" // 通过 foreach (string modeName in ModeService.modeNames), 然后打印出来的字符串
    version = "0.0.1" // 版本号

    pane_types = [
        // 目前在default.mode文件中看到的是有以下四个内容, 具体原因不明;
        "ConsoleWindow"
        // "ProfilerWindow"
        "InspectorWindow"
        "ProjectBrowser"
    ]

    layout=
    {
        vertical = true
        top_view =
        {
            size = 30
            horizontal = true
            children =
            [
                {
                    class_name = "ToolbarWindow"
                    size = 0.8
                }
                {
                    class_name = "ProjectSettingWindow"
                    size = 0.2
                }
            ]
        }
        center_view =
        {
            horizontal = true
            children =
            [
                {
                    size = 10
                    vertical = true
                    children =
                    [
                        {
                            size = 20
                            class_name = "SceneHierarchyWindow"
                        }
                        {
                            size = 80
                            class_name = "InspectorWindow"
                        }
                    ]
                }
                {
                    size = 70
                    vertical = true
                    children =
                    [
                        {
                            size = 80
                            tabs = true //排版方式三选一 tabs = true horizontal = true vertical = true
                            children =
                            [
                                {
                                    class_name = "SceneView"
                                }
                                {
                                    class_name = "GameView"
                                }
                                {
                                    class_name = "ProjectBrowser"
                                }
                            ]
                        }
                        // ConsoleWindow窗口
                        //{
                        //    size = 20
                        //    class_name = "ConsoleWindow"
                        //}
                    ]
                }
                {
                    size = 20
                    vertical = true
                    children =
                    [
                        {
                            class_name = "QuickControl"
                            size = 1
                        }
                        {
                            class_name = "QuickSearch"
                            size = 84
                        }
                        {
                            class_name = "LookDevSearchFilters"
                            size = 15
                        }
                    ]
                }
            ]
        }
    }

    menus = [
        // 这里的所有菜单栏, 都需要声明才可以使用, 具体名称参考默认Unity菜单中的名称,
        // 以及参考X:\Program Files\Unity\2021.3.45f1\Editor\Data\Resources\default.mode
        // 重要: 重启后生效
        { name = "File" children = [
            { name = "New Project..." }
            { name = "Open Project..." }
            { name = "Save Project" }
            null
            { name = "Exit" platform="windows"}
            { name = "Exit" platform="linux"}
            { name = "Close" platform="osx"}
        ]}
        { name = "Edit" children = [
            { name = "Undo" }
            { name = "Redo" }
            null
            { name = "Copy" }
            { name = "Paste" }
            null
            { name = "Select All" }
            null
            { name = "Duplicate" }
            { name = "Rename" }
            { name = "Delete" }
            null
            { name = "Frame Selected in Scene" }
            { name = "Frame Selected in Window under Cursor" }
            { name = "Lock View to Selected" }
            null
            { name = "Project Settings..." }
            { name = "Preferences..." platform="windows"}
            { name = "Preferences..." platform="linux"}
        ]}
        { name = "Assets" children = [
            { name = "Create" children = [
                { name = "Folder" }
                null
                { name = "C# Script" }
                { name = "Assembly Definition" }
                { name = "Assembly Definition Reference" }
            ]}
            { name = "Version Control" children = "*" }
            { name = "Show in Explorer" platform="windows" }
            { name = "Reveal in Finder" platform="osx" }
            { name = "Open Containing Folder" platform="linux" }
            { name = "Delete" }
            { name = "Rename" }
            { name = "Copy Path" }
            null
            { name = "View in Package Manager" }
            null
            { name = "Refresh" }
            null
            { name = "Open C# Project" menu_item_id = "Assets/Open C# Project" }
        ]}
        {name = "LookDev" children = [
                { name = "Return to Unity"
                    command_id = "Commands/Return to Unity"
                }
                { name = "Config" }
            ]}
        { name = "Window" children = [
            { name = "Next Window" }
            { name = "Previous Window" }
            null
            { name = "Package Manager" }
            null
            { name = "Asset Management" children = [
                { name = "Version Control" }
            ]}
            null
            { name = "General" children = [
                { name = "Console" }
                { name = "Project" }
                { name = "Inspector" }
            ]}
        ]}
        { name = "Help" children = "*" }
    ]
}
```



###### 参考网页

- [Unity-Technologies/lookdev-studio: LookDev Studio: a template for artists to import their work, and share the result with their directors, team and clients.](https://github.com/Unity-Technologies/lookdev-studio)
- [为编辑器创建自定义模式 #C# - Qiita](https://qiita.com/Shiranui_Isuzu/items/b2ca640a75457311f62e)
