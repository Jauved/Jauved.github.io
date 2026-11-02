---
layout: post
title: "Windows 11 使用 AdGuard VPN SOCKS5 实现按需代理与浏览器分流"
categories: [Windows, 网络]
tags: Windows11 AdGuardVPN SOCKS5 PowerShell 代理 proxy cmd
math: false


---

# Windows 11 使用 AdGuard VPN SOCKS5 实现按需代理与浏览器分流

## 1. 结论

通过 AdGuard VPN 的 SOCKS5 模式, 可以实现以下目标:

- **浏览器**: 使用 Falcon 插件, 根据网站规则决定直连或代理.
- **其他 Windows 应用**: 默认直连, 不自动经过 VPN.
- **PowerShell**: 通过环境变量临时启用或关闭代理.
- **命令行工具**: 对支持 SOCKS5 的工具, 不需要额外配置 HTTP 代理.
- **应用排除项**: 当前 SOCKS5 工作模式下不需要逐个配置应用排除项.

本方案已经在 Windows 11 + AdGuard VPN 环境下完成实际验证.

### 1.1 最终网络架构

```
Windows 11
│
├── Edge 浏览器
│   └── Falcon Proxy 插件
│       ├── 命中代理规则
│       │   └── SOCKS5 127.0.0.1:10908
│       │       └── AdGuard VPN
│       │
│       └── 未命中代理规则
│           └── 直连
│
├── PowerShell
│   ├── 默认: 直连
│   └── 设置 ALL_PROXY
│       └── SOCKS5 127.0.0.1:10908
│           └── AdGuard VPN
│
└── 其他应用
    └── 默认直连
```

核心原则: **由应用主动决定是否使用代理, 不让 VPN 默认接管所有系统流量.**

## 2. AdGuard VPN 配置

### 2.1 开启 SOCKS5 模式

打开 AdGuard VPN Windows 客户端.

进入:

```
设置 -> 应用设置 -> 高级设置 -> 运行模式
```

将运行模式从 `VPN` 切换为 `SOCKS5`.

两种模式的区别:

| 特性                   | VPN 模式           | SOCKS5 模式          |
| ---------------------- | ------------------ | -------------------- |
| 自动接管系统网络流量   | 是, 受排除规则影响 | 否                   |
| 应用主动指定代理       | 不要求             | 需要                 |
| 支持浏览器插件分流     | 可由 VPN 自行分流  | 可通过 Falcon 实现   |
| 需要逐个配置应用排除项 | 取决于分流需求     | 当前方案不需要       |
| 本地代理端口           | 不作为主要使用方式 | 提供 SOCKS5 监听端口 |

### 2.2 SOCKS5 端口

当前验证成功的配置:

```
Protocol: SOCKS5
Host:     127.0.0.1
Port:     10908
```

其中 `10908` 为本机配置的端口, 不是所有设备通用的固定端口.

使用时需要保持 AdGuard VPN 客户端运行并连接有效的 VPN 节点.

## 3. Edge 浏览器分流

Edge 使用 Falcon Proxy 插件管理网站代理规则.

在 Falcon 中配置:

```
Proxy Type: SOCKS5
Server:     127.0.0.1
Port:       10908
```

然后沿用之前 Falcon 的网站分流规则.

例如:

```
需要代理的网站
    -> Falcon
    -> AdGuard VPN SOCKS5

不需要代理的网站
    -> Falcon DIRECT
    -> 本地网络
```

注意:

1. Falcon 必须处于启用状态, 并选择正确的代理 Profile.
2. 分流结果由 Falcon 的实际规则决定, 并非所有国外网站都会自动走代理.
3. 如果 Windows 系统代理仍保留了旧的全局配置, 应另外检查和清理.

## 4. PowerShell 临时代理

### 4.1 开启代理

在 PowerShell 中执行:

```
$env:ALL_PROXY = "socks5h://127.0.0.1:10908"
```

之后, 支持 `ALL_PROXY` 环境变量和 SOCKS5 协议的命令行工具可以自动使用代理.

这里使用 `socks5h`, 而不是 `socks5`.

区别:

- `socks5://`: 通常由本地完成目标域名的 DNS 解析.
- `socks5h://`: 由代理端解析目标域名.

推荐优先使用 `socks5h`, 减少本地 DNS 解析产生的额外请求和潜在泄漏.

### 4.2 关闭代理

```
Remove-Item Env:ALL_PROXY
```

恢复当前 PowerShell 会话中没有 `ALL_PROXY` 的状态.

需要注意, 如果还存在 `HTTP_PROXY`、`HTTPS_PROXY` 等其他代理配置, 工具仍然可能使用代理.

### 4.3 查看当前代理环境变量

```
Get-ChildItem Env:*PROXY*
```

该命令用于检查当前会话中所有名称包含 `PROXY` 的环境变量.

### 4.4 临时设置的作用范围

使用 `$env:ALL_PROXY` 设置代理具有以下特点:

- 只影响当前 PowerShell 进程及之后继承其环境变量的子进程.
- 不会修改 Windows 全局代理设置.
- 不会自动改变其他已启动程序的代理配置.
- 关闭 PowerShell 窗口后, 当前窗口内设置的临时变量不会继续存在.

这非常适合需要临时访问外部网络的开发工作.

## 5. 不修改环境变量, 只代理单条命令

以 curl 为例:

```
curl.exe --proxy socks5h://127.0.0.1:10908 https://www.cloudflare.com/cdn-cgi/trace
```

该命令仅为本次请求指定 SOCKS5 代理.

对于支持 SOCKS5 的 Git HTTPS 传输, 也可以使用类似方式:

```
git -c http.proxy=socks5h://127.0.0.1:10908 clone https://github.com/example/repo.git
```

注意: 并非所有 CLI 都支持 `ALL_PROXY` 或 SOCKS5. 需要根据具体工具确认.

## 6. 验证方法

使用 Cloudflare 的公开 IP 查询接口:

https://www.cloudflare.com/cdn-cgi/trace

不需要登录, 可以查看当前网络请求使用的公网出口 IP.

### 6.1 验证默认直连

```
curl.exe --ssl-no-revoke --noproxy "*" https://www.cloudflare.com/cdn-cgi/trace
```

实际测试:

```
loc=CN
```

### 6.2 验证显式 SOCKS5 代理

```
curl.exe --ssl-no-revoke --proxy socks5h://127.0.0.1:10908 https://www.cloudflare.com/cdn-cgi/trace
```

实际测试:

```
loc=US
```

### 6.3 验证 ALL_PROXY

```
$env:ALL_PROXY = "socks5h://127.0.0.1:10908"

curl.exe --ssl-no-revoke https://www.cloudflare.com/cdn-cgi/trace
```

实际测试:

```
loc=US
```

### 6.4 验证关闭代理

```
Remove-Item Env:ALL_PROXY

curl.exe --ssl-no-revoke https://www.cloudflare.com/cdn-cgi/trace
```

实际测试:

```
loc=CN
```

### 6.5 验证结果汇总

| 测试           | 预期行为 | 实测     |
| -------------- | -------- | -------- |
| 强制直连       | 本地出口 | CN, 通过 |
| 显式 SOCKS5    | VPN 出口 | US, 通过 |
| 设置 ALL_PROXY | VPN 出口 | US, 通过 |
| 删除 ALL_PROXY | 恢复直连 | CN, 通过 |

由此确认, 当前 AdGuard VPN SOCKS5 配置工作正常.

需要注意, 以上结果验证的是 `curl.exe` 的代理行为, 不代表所有命令行工具都具备相同的代理支持.

## 7. 常见问题

### 7.1 为什么不需要配置 AdGuard VPN 的应用排除项?

因为当前使用 SOCKS5 模式.

该模式下, AdGuard VPN 提供本地代理服务, 不会像系统级 VPN 模式那样自动接管所有应用流量.

只有主动使用该代理的程序, 才会通过 VPN 转发.

但如果系统或其他软件仍配置了全局代理、透明代理或其他网络隧道, 则需要另外排查.

### 7.2 SOCKS5 能否替代 HTTP 代理?

对于支持 SOCKS5 的程序, 可以.

| 能力          | HTTP Proxy          | SOCKS5                   |
| ------------- | ------------------- | ------------------------ |
| HTTP/HTTPS    | 支持                | 支持                     |
| 通用 TCP 连接 | 取决于 CONNECT 支持 | 支持                     |
| 远端 DNS 解析 | 取决于实现          | `socks5h` 可实现         |
| UDP           | 通常不支持          | 协议支持, 具体取决于实现 |
| 命令行兼容性  | 通常更广            | 取决于程序               |

不支持 SOCKS5 的软件仍可能需要 HTTP 代理.

### 7.3 curl 出现证书吊销错误

可能出现:

```
CRYPT_E_REVOCATION_OFFLINE (0x80092013)
```

原因是 Windows Schannel 无法完成证书吊销状态检查.

临时验证网络时可以添加:

```
--ssl-no-revoke
```

例如:

```
curl.exe --ssl-no-revoke https://www.cloudflare.com/cdn-cgi/trace
```

该参数仅跳过吊销检查, 不会完全关闭 TLS 证书验证.

这只是测试期间的临时规避方式, 不建议长期依赖. 后续应排查证书吊销服务的网络连通性.

## 8. 推荐日常用法

正常工作时:

- AdGuard VPN 保持 SOCKS5 模式.
- Falcon 负责浏览器分流.
- Windows 其他应用保持默认网络行为.
- PowerShell 默认不设置 `ALL_PROXY`.

命令行需要代理时:

```
$env:ALL_PROXY = "socks5h://127.0.0.1:10908"
```

使用结束后:

```
Remove-Item Env:ALL_PROXY
```

**最终原则: 将代理选择权交还给应用, 只让确实需要代理的流量通过 VPN.**

## 参考资料

- [AdGuard VPN for Windows - 官方文档](https://adguard-vpn.com/kb/adguard-vpn-for-windows/overview/)
- [curl - Proxy environment variables](https://everything.curl.dev/usingcurl/proxies/env.html)
- [curl - SOCKS Proxy](https://everything.curl.dev/usingcurl/proxies/socks.html)
- [Cloudflare - IP Trace](https://www.cloudflare.com/cdn-cgi/trace)
