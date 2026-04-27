---
layout: post
title: "安装AdobeCreativeCloud无法验证账号"
categories: [Adobe, Photoshop]
tags: Adobe Photoshop 安装问题
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

  以管理员模式运行梯子, 
  
  - 开启`Tun`模式, 并选择`自动配置系统代理`
  - 或者关闭`Tun`模式, 并选择`Pac`模式
  
  正常安装AdobeCreativeCloud, 以及其他的应用. 安装完毕后恢复通常的状态.

## 02 疑难杂症

- x2rayN, 开启`Tun`模式无法联网

  设置->参数设置->Tun模式设置, 关闭`Strict Route`即可. 参见https://github.com/2dust/v2rayN/discussions/3888#discussioncomment-8577132

- 打开应用, 提示无法连接验证服务器

  开启`Tun`模式. 开启后联网失败参见上一条.

###### 参考网页
