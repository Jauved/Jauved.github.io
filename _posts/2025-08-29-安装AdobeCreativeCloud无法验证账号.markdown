---
layout: post
title: "安装AdobeCreativeCloud无法验证账号"
categories: [Adobe, photoshop]
tags: Adobe photoshop 安装问题
math: true


---

# 安装AdobeCreativeCloud无法验证账号

## 00 前言

安装AdobeCreativeCoud时, 总是无法下载到国际版, 或者验证账号的时候总是跳转到非国际版, 导致无法安装.

## 01 处理方法

- 摆脱跳转非国际官网

  将下列规则加入目前激活的梯子规则中, 然后将顺序放在"绕过非国际域名"这个规则前

  ```
  domain:adobe.com,
  domain:adobelogin.com,
  domain:adobe.io,
  ```

- 摆脱账号非国际验证

  在安装AdobeCreativeCloud的时候

  以管理员模式运行梯子, 开启`Tun`模式, 并选择`自动配置系统代理`, 正常安装AdobeCreativeCloud, 以及其他的应用. 安装完毕后恢复通常的状态.



###### 参考网页
