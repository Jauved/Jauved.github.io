---
layout: post
title: "内网npm私服Package配置"
categories: [Unity, Package]
tags: Unity Package npm
math: true


---

# 内网npm私服Package配置

## 修改manifest.json文件

- 路径: [项目文件夹名]/Packages/manifest.json

## 添加下载地址

- 在scopedRegistries块增加如下代码

  ```json
  {
      "name": "Surender",
      "url": "http://172.16.10.34:4873",
      "scopes": [
      "com.surender"
      ]
  }
  ```

  

## 添加Package包

- 在dependencies块增加包名和版本号, 形如

  ```json
  "com.render.core": "0.1.0"
  ```

  

## 示例伪代码

```json
{
    "scopedRegistries": [
        {
            "name": "Unity",
            "url": "http://172.16.10.34:4873",
            "scopes": [
                "com.unity"
            ]
        },
        {
            "name": "render",
            "url": "http://172.16.10.34:4873",
            "scopes": [
                "com.surender"
            ]
        }
    ],
    "dependencies": {
        "com.surender.core": "1.0.0",
        "com.unity.collab-proxy": "1.2.16",
        ......
        "com.unity.modules.xr": "1.0.0"
    }
}
```

