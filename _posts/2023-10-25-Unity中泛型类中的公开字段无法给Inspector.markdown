---
layout: post
title: "Unity中泛型类中的公开字段无法给Inspector"
categories: [Unity, 代码]
tags: Unity C# 代码
math: true
---

# Unity中泛型类中的公开字段无法给Inspector

## 00 前言

在Unity中泛型的类, 比如

```c++
using System;
using System.Collections.Generic;
using UnityEngine;
using XLua;

[Serializable]
public class LuaLoader<T>
{
    public TextAsset luaScript; // 从Resources加载的Lua脚本
    [HideInInspector]
    public Dictionary<int, T> DataDictionary;

    private LuaEnv _luaEnv;
    public Dictionary<int, T> GetData()
    {
        // TextAsset luaScript = Resources.Load<TextAsset>("Cfg_Effect.lua");
        // Debug.Log(luaScript.text);
        _luaEnv = _luaEnv ?? new LuaEnv();

        // 执行Lua脚本
        _luaEnv.DoString(luaScript.text);

        // 获取Lua表中的数据
        // var data = _luaEnv.Global.Get<Dictionary<int,Dictionary<string,object>>>("data");
        var data2 = _luaEnv.Global.Get<Dictionary<int, T>>("data");

        // Debug.Log(data2[1].Path);
        // 将数组赋值给到CfgEffects以便外部调用.
        DataDictionary = data2;
        return data2;
    }

    public void Dispose()
    {
        _luaEnv.Dispose();
    }
}
```

此时, 如果用

```c++
public LuaLoader<GameObject> luaLoader = new LuaLoader<GameObject>()
```

声明的话, 在Unity的```Inspector```面板上是不会显示这个类的```public TextAsset luaScript;```字段的.

## 01 处理方法

此时使用子类的方式来处理即可.

```c++
using System;
using UnityEngine;

[Serializable]
public class LuaEffectLoader : LuaLoader<CfgEffect>
{

    public void Check()
    {
        DataDictionary[1].DebugLog();
    }

}

public struct CfgEffect
{
    public int EffectId;
    public string Path;
    public string Path2;
    public int DestoryTime;
    public int PreLoadEff;
    public int FlowBones;
    public int Direction;
    public int FollowScale;
    public int Mirror;
    public int Scaling;

    public void DebugLog()
    {
        Debug.Log($"EffectId:   {EffectId}\nPath:   {Path}");
    }
}
```

此时, 用以下代码声明的字段就可以在```Inspector```面板上显示.

```c++
public LuaEffectLoader luaEffectLoader = new LuaEffectLoader();
```

![image-20231025200525972](/assets/image/image-20231025200525972.png)

###### 参考网页

[unity:如何将具有泛型类的字段公开给Inspector？ - unity - Codebug](https://codebug.vip/questions-375605.htm)
