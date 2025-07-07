---
layout: post
title: "gitignore文件不生效的处理方式"
categories: [Git]
tags: Git gitignore
math: true
---

# gitignore文件不生效的处理方式

## 00 前言

在.gitignore文件中增加规则后, 之前已经跟踪并上传的文件并不会因为增加的规则而取消跟踪.

原因是, git缓存中已经将之前的文件纳入了版本管理, 此时即便是在.gitignore中声明了忽略也是无法影响这部分文件的.

## 01 处理方式

git清除本地缓存, 再加入版本管理后提交, 命令行代码如下:

```c++
git rm -r --cached .
git add .
git commit -m 'update .gitignore'
git push -u origin master
```

一般来说, 只执行前两句命令即可清除缓存并按照新的gitignore规则将文件加入版本管理, 后续的提交和推送可以按照需要去完成.

如果需要忽略的文件和文件夹较少, 也可以使用如下命令来单独忽略,  其中[directory]是需要忽略的文件/文件夹路径.

```c++
git rm -r --cached [directory]
```



###### 参考网页

[Git忽略规则(.gitignore配置）不生效原因和解决 - 星宸如愿 - 博客园 (cnblogs.com)](https://www.cnblogs.com/rainbowk/p/10932322.html)
