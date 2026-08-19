---
layout: post
title: "基于Jekyll的Mathjax语法替换"
categories: [其他, Blog]
tags: Jekyll blog Mathjax 公式 数学
math: true
---


# 基于Jekyll的Mathjax语法替换

## 1.单行公式

### 1.1上下标

```
$f\_0$
$f\_{a+b}$

```

$f\_0$,$f\_{a+b}$

```
$f^2$
$f^{a+b}$
```

 $f^2$,$f^{a+b}$​

```
$^af$
$^{a+b}f$
```

$^af$,$^{a+b}f$

```
$\_af$
$\_{a+b}f$
```

$\_af$,$\_{a+b}f$​

```
$f^a\_b$
$f^{a+b}\_{c+d}$
```

$f^a\_b$,$f^{a+b}\_{c+d}$

```
$\mathop{A} \limits\_{i=0}^n$
```

$\mathop{A} \limits\_{i=0}^n$

```
$X\stackrel{F}{\longrightarrow}Y$
```

$X\stackrel{F}{\longrightarrow}Y$

### 1.2 求和

```
$\sum\_a^b$
\limits_{i=0}^n$
```

$\sum\_a^b$,$\sum \limits\_{i=0}^n$

### 1.3 积分

```
$\int\_0^{\pi}\frac{e^3/x}{x^2} \, {\mathrm d}x$
```

$\int\_0^{\pi}\frac{e^3/x}{x^2} \, {\mathrm d}x$

### 1.4 求和积分极限综合

```

$$

\int_a^b f(x) \, \mathrm{d}x=\lim_{N\to\infty}
\sum_{i=0}^{N-1}
f(x_i)\Delta x

$$

```

$$

\int_a^b f(x) \, \mathrm{d}x=\lim_{N\to\infty}
\sum_{i=0}^{N-1}
f(x_i)\Delta x

$$

### 1.5 对齐

```

$$

\begin{aligned}
F(2)-F(0) &= (4.05+C)-C \\ &= 4 \\ 
\end{aligned}

$$

```

$$

\begin{aligned}
F(2)-F(0) 	&= (4.05+C)-C \\ 
			&= 4.05 \\
			&\approx4
\end{aligned}

$$

除了`begin{aligned}`和`end{aligned}`, 关键是用`&`符号标识出对齐的位置即可. 

### 1.5 省略号

```

$$

f(x_0)\Delta x
+
f(x_1)\Delta x
+
f(x_2)\Delta x
+\cdots

$$

```

$f(x\_0)\Delta x+f(x\_1)\Delta x+f(x\_2)\Delta x+\cdots$





## 2. 注意

不要出现类似:

**\{\{**

这样会触发类似:

```
Liquid syntax error (line 216):
Variable '\{\{\rm d}' was not properly terminated
```

的报错.

原因是:

> Jekyll 使用的 Liquid 模板语言会把"\{\{"识别成"Liquid 变量开始".
>
> 然后又无法按照 Liquid 语法找到合法的结束结构, 于是构建直接失败



###### 参考网页

[jekyll下Markdown的填坑技巧 \| Weclome to eipi10](https://eipi10.cn/others/2019/12/07/jekyll-markdown-skills/)

[LaTex写公式怎么换行？ - 知乎 (zhihu.com)](https://www.zhihu.com/question/618818933)