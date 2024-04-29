---
layout: post
title: "Unity大量Meta文件Git冲突"
categories: [URP, 后处理]
tags: URP 后处理 DepthOfField
math: true


---

# Unity大量Meta文件Git冲突

## 00 前言

如果你遇到了大量Meta文件Git冲突, 同时仅仅是guid的变更. 原因可能是因为untrack的文件占用了已经有的guid, 然后导致已经有的guid发生变更, 而变更后的guid又占用了已有的guid, 导致恶性循环, 最终整个工程的meta文件全变更. 在大规模协作时有概率遇到.

## 01 处理方法

- 首先, 将没有track的文件, 拷贝出来

- 然后使用以下命令将git仓库还原
  ```c++
  git clean -df .//或者git clean -ndf .
  git checkout .
  ```

- 此时应该可以解决.

- 代价是没有track的那部分文件, 关联可能会丢失.

###### 参考网页
