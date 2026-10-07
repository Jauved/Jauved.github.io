---
layout: post
title: "ChatGPT Desktop App 安装与代理配置"
categories: [ChatGPT, 工具]
tags: ChatGPT Codex Desktop Windows 代理 app AI Agent 应用回环 store microsoft MSIX
math: false

---

# ChatGPT Desktop App 安装与代理配置

> 目标: 安装 Windows 版 ChatGPT Desktop App, 并确保 ChatGPT GUI 与内置 Codex 的网络流量通过本地 HTTP 代理 `127.0.0.1:10809`, 而不是直接连接公网.
>
> 本文记录的是我们在 Windows 上**实际完成并验证成功**的最终流程. 其中包含 2026-09-28 之后新版 App 的启动方式变化, 旧的“直接执行 `WindowsApps\...\ChatGPT.exe`”方案已经不再使用.

官方入口:

- [ChatGPT 官方下载页](https://chatgpt.com/download/)
- [ChatGPT Desktop App Quickstart](https://learn.chatgpt.com/docs/app)

------

# 0. 当前结论

当前验证通过的组合是:

```text
Microsoft Store / MSIX 安装
        ↓
AppContainer Loopback Exemption
        ↓
%USERPROFILE%\.codex\.env
        ↓
chatgpt-proxy.cmd
        ↓
chatgpt-proxy.ps1
        ↓
IApplicationActivationManager
        ↓
通过 AUMID 正规激活 ChatGPT
        ↓
--proxy-server=http://127.0.0.1:10809
--disable-quic
        ↓
ChatGPT.exe → 127.0.0.1:10809
codex.exe   → 127.0.0.1:10809
```

最终实测:

```text
ChatGPT.exe → 127.0.0.1:10809
codex.exe   → 127.0.0.1:10809
```

完整进程树检查输出:

```text
OK: No direct external TCP connections were detected in the ChatGPT process tree.
```

同时验证:

- ChatGPT App 可以正常登录.
- ChatGPT 普通对话正常.
- 内置 Codex 可以正常联网.
- Windows Setup / Codex Sandbox 设置可以正常完成.
- `codex-windows-sandbox-service.exe` 正常运行.

**当前不要再使用旧版的直接 `Start-Process ChatGPT.exe` 或 `& $exe --proxy-server=...` 启动方式.**

------

# 1. 下载并安装 ChatGPT Desktop

打开:

[ChatGPT 官方下载页](https://chatgpt.com/download/)

选择 Windows 版本.

当前 Windows 版通过 Microsoft Store / MSIX 体系安装. 安装后实际 AppX 包名实测为:

```text
OpenAI.Codex
```

查看包信息:

```powershell
Get-AppxPackage |
    Where-Object {
        $_.Name -match 'OpenAI|ChatGPT|Codex'
    } |
    Select-Object Name, Version, PackageFamilyName, PackageFullName, InstallLocation
```

我们先后实测过的版本包括:

```text
26.917.6896.0
26.924.2738.0
```

安装路径形式为:

```text
C:\Program Files\WindowsApps\
OpenAI.Codex_<版本>_x64__2p2nqsd0c76g0\
app\ChatGPT.exe
```

版本号会随着 Store 更新变化, 因此:

> **不要在启动脚本中硬编码完整 WindowsApps 路径.**

------

# 2. ChatGPT Desktop 与 Codex CLI 是两套会话

新版 App 中可以使用 ChatGPT / Work / Codex 等入口.

实测发现:

> **ChatGPT Desktop 内置 Codex 的会话记录, 与我们单独安装的 Codex CLI 本地会话并不会自动共用.**

Codex CLI 的 session 仍由 CLI 自己管理, 可以使用 `/rename`, `/delete`, `/archive`, `resume` 等方式处理.

另外, 当前机器上的 CLI 使用了自定义 `CODEX_HOME`, 而本文 Desktop App 代理配置使用:

```text
%USERPROFILE%\.codex\.env
```

两者不要混淆.

------

# 3. 确认 Codex Sandbox Service

安装 ChatGPT/Codex 后会看到:

```text
codex-windows-sandbox-service.exe
```

查询:

```powershell
Get-Service | Where-Object {
    $_.Name -like '*codex*' -or
    $_.DisplayName -like '*codex*'
} | Format-List Name,DisplayName,Status,StartType
```

实测:

```text
Name        : CodexSandboxService.OpenAI.Codex
DisplayName : ChatGPT
Status      : Running
StartType   : Automatic
```

这是正常 Windows Service.

**不要因为关闭 ChatGPT / Codex CLI 后它仍存在就强制结束.**

------

# 4. 配置 AppContainer Loopback Exemption

本地 HTTP 代理监听:

```text
127.0.0.1:10809
```

Store/MSIX App 需要能够访问 localhost / loopback.

我们使用 Fiddler 的 AppContainer Loopback Exemption Utility.

官方下载:

- [Fiddler Classic Add-ons](https://www.telerik.com/fiddler/add-ons)
- [EnableLoopback Utility](https://telerik-fiddler.s3.amazonaws.com/fiddler/addons/enableloopbackutility.exe)

## 4.1 勾选 ChatGPT / Codex

在工具中找到 OpenAI / ChatGPT / Codex 对应 AppContainer, 勾选并保存.

最终实测名称:

```text
openai.codex_2p2nqsd0c76g0
```

## 4.2 验证

管理员 PowerShell:

```powershell
CheckNetIsolation.exe LoopbackExempt -s
```

期望看到:

```text
名称: openai.codex_2p2nqsd0c76g0
SID:  S-1-15-2-...
```

注意:

> Loopback Exemption 只代表“允许 AppContainer 访问 localhost”, **不代表应用已经使用代理**.

## 4.3 Fiddler Utility 的 0x57

我们曾遇到:

```text
Failed to set IsolationExempt AppContainers;
call returned 0x57
```

并看到 orphaned exemption SID 提示.

后来重新操作后成功保存.

如果再次遇到:

1. 不要一次性 Exempt All.
2. 先只处理 ChatGPT / OpenAI AppContainer.
3. 使用 `CheckNetIsolation.exe LoopbackExempt -s` 验证最终状态.
4. 不要为了“清理干净”随意清空全部 exemption.

------

# 5. 默认启动不会自动走 10809

仅配置 Loopback Exemption 后, 正常从开始菜单启动 ChatGPT.

查找 NetworkService:

```powershell
Get-CimInstance Win32_Process |
Where-Object {
    $_.Name -eq 'ChatGPT.exe' -and
    $_.CommandLine -match 'network\.mojom\.NetworkService'
} |
Select-Object ProcessId,CommandLine
```

查询该 PID 的连接:

```powershell
Get-NetTCPConnection -State Established |
Where-Object {
    $_.OwningProcess -eq <NetworkService PID>
} |
Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,OwningProcess
```

默认启动时我们实测出现:

```text
ChatGPT.exe
→ 公网 IPv6
→ RemotePort 443
```

结论:

> **Loopback Exemption 本身不会强制 ChatGPT 使用 `127.0.0.1:10809`.**

------

# 6. 重要变化: 不再直接启动 WindowsApps 中的 ChatGPT.exe

早期版本中, 我们曾经成功使用:

```powershell
$pkg = Get-AppxPackage OpenAI.Codex
$exe = Join-Path $pkg.InstallLocation "app\ChatGPT.exe"

& $exe --proxy-server="http://127.0.0.1:10809"
```

当时确实能够启动, 并且 NetworkService 会连接:

```text
127.0.0.1:10809
```

但是更新到实测版本:

```text
OpenAI.Codex 26.924.2738.0
```

之后, 直接执行 `WindowsApps\...\ChatGPT.exe` 会失败:

```text
ChatGPT failed to start.
该进程没有程序包标识符.
```

与此同时, 从 Windows 开始菜单正常启动 App 仍然成功.

因此可以确定问题在启动方式, 而不是 App 安装损坏.

## 6.1 为什么旧方案不再使用

直接运行:

```text
WindowsApps\...\ChatGPT.exe
```

会绕过正常的 MSIX App 激活流程.

新版 App 需要正确的 Package Identity, 所以最终方案改为:

```text
IApplicationActivationManager
        ↓
AUMID
        ↓
正规 MSIX 激活
```

## 6.2 当前 AUMID

查询:

```powershell
Get-StartApps |
Where-Object {
    $_.Name -match 'ChatGPT|Codex|OpenAI'
} |
Format-Table Name,AppID -AutoSize
```

实测:

```text
Name    AppID
----    -----
ChatGPT OpenAI.Codex_2p2nqsd0c76g0!App
```

最终脚本会动态解析包与 AUMID, 不依赖版本化的 WindowsApps 路径.

------

# 7. 配置 Codex backend 的代理环境

为了让 Desktop App 中独立的 `codex.exe` backend 也走本地代理, 最终实测配置保留:

```text
C:\Users\%USERPROFILE%\.codex\.env
```

即通用写法:

```text
%USERPROFILE%\.codex\.env
```

内容:

```env
HTTP_PROXY=http://127.0.0.1:10809
HTTPS_PROXY=http://127.0.0.1:10809
http_proxy=http://127.0.0.1:10809
https_proxy=http://127.0.0.1:10809

NO_PROXY=localhost,127.0.0.1,::1
no_proxy=localhost,127.0.0.1,::1
```

这里**不要再配置**:

```text
ALL_PROXY=socks5://127.0.0.1:10808
```

我们最终成功登录和联网的配置统一使用 `10809` HTTP Proxy.

`NO_PROXY` 中保留:

```text
localhost
127.0.0.1
::1
```

用于避免本地 OAuth callback / IPC 流量被送进外部代理.

> 当前成功状态同时存在 `.codex\.env` 和 launcher 设置的 `HTTP_PROXY / HTTPS_PROXY / NO_PROXY`.
>
> 我们没有继续破坏性拆分测试“Codex backend 究竟依赖哪一个来源”, 因此文档保留**实际验证成功的组合**, 不再擅自简化.

------

# 8. 最终启动方式: CMD + PowerShell 两文件

最终目录建议:

```text
D:\Dev\Tools\bin\
├── chatgpt-proxy.cmd
└── chatgpt-proxy.ps1
```

职责拆分:

```text
chatgpt-proxy.cmd
        ↓
稳定的命令行入口
        ↓
chatgpt-proxy.ps1
        ↓
检查 10809 / 检查旧进程
        ↓
设置代理环境
        ↓
动态解析 OpenAI.Codex 包和 AUMID
        ↓
IApplicationActivationManager
        ↓
MSIX 正规激活
        ↓
--proxy-server=http://127.0.0.1:10809
--disable-quic
```

以后正常启动:

```powershell
chatgpt-proxy
```

启动前要满足:

```text
xray / 本地代理已启动
127.0.0.1:10809 可用
ChatGPT 尚未运行
```

如果已有 ChatGPT 进程, 脚本会拒绝继续, 防止复用一个此前按“直连方式”启动的进程.

完整脚本见附录 A / B.

------

# 9. 为什么同时使用几种代理配置

当前方案不是只靠一个参数.

## 9.1 Chromium NetworkService

ChatGPT Desktop 本身使用 Chromium 多进程网络架构.

通过:

```text
--proxy-server=http://127.0.0.1:10809
```

显式指定 ChatGPT Chromium 网络代理.

另外加入:

```text
--disable-quic
```

避免 Chromium 使用 QUIC / HTTP3 UDP 路径, 让实际流量保持在我们已经验证的 TCP + HTTP Proxy 链路中.

## 9.2 Codex backend

Desktop App 会额外启动:

```text
codex.exe
```

最终验证成功时, 它也建立了:

```text
codex.exe → 127.0.0.1:10809
```

因此保留:

```text
HTTP_PROXY
HTTPS_PROXY
NO_PROXY
```

以及 `%USERPROFILE%\.codex\.env`.

## 9.3 Loopback Exemption

Loopback Exemption 负责:

```text
允许 Store/MSIX App 访问 localhost
```

它本身**不负责选择代理**.

完整关系:

```text
Loopback Exemption
        ↓
允许访问 127.0.0.1
        ↓
MSIX Activation
        ↓
ChatGPT Chromium --proxy-server
+
Codex HTTP_PROXY / HTTPS_PROXY
        ↓
127.0.0.1:10809
        ↓
xray
        ↓
公网
```

------

# 10. 最终验证: 整棵 ChatGPT 进程树

不要只检查主进程.

任务管理器中看到很多:

```text
ChatGPT
Codex
Codex
...
```

是正常现象.

典型结构:

```text
ChatGPT.exe 主进程
├─ GPU Process
├─ NetworkService
├─ StorageService
├─ Renderer
├─ Renderer
└─ codex.exe
```

我们最终用附录 C 的脚本递归收集整个 ChatGPT 进程树的 Established TCP 连接.

在 App 中实际进行普通 ChatGPT 对话和 Codex 操作之后, 实测:

```text
ChatGPT.exe → 127.0.0.1:10809
codex.exe   → 127.0.0.1:10809
```

并输出:

```text
OK: No direct external TCP connections were detected in the ChatGPT process tree.
```

因此当前版本下可以确认:

> **没有观察到 ChatGPT / Codex 进程树直接建立公网 TCP 连接.**

------

# 11. Windows Setup / Sandbox 设置失败的修复

新版 Desktop App 的 Codex 页面可能提示:

```text
Windows 设置未完成
设置已停止
```

这个设置对普通 ChatGPT 对话不是核心依赖, 但对 Codex 在 Windows 本地执行命令, 修改文件和使用 sandbox 很重要.

## 11.1 查看错误

```powershell
Get-Content "$env:USERPROFILE\.codex\.sandbox\setup_error.json" -Raw
```

我们实测错误为:

```json
{
  "code": "helper_sandbox_lock_failed",
  "message": "lock sandbox bin dir ...\\.codex\\.sandbox-bin failed: open directory ..."
}
```

说明旧的:

```text
%USERPROFILE%\.codex\.sandbox-bin
```

目录处于异常的锁定 / 权限状态.

## 11.2 实测成功的修复

先完全退出 ChatGPT / Codex.

然后用**管理员 PowerShell**:

```powershell
Rename-Item "$env:USERPROFILE\.codex\.sandbox-bin" ".sandbox-bin.bak"
```

重新通过 `chatgpt-proxy` 启动 App, 再点击:

```text
重新设置
```

实测 Windows Setup 随后正常完成.

确认 Codex 本地任务正常后, 旧备份:

```text
%USERPROFILE%\.codex\.sandbox-bin.bak
```

可以再手工删除.

不要因为这个错误去结束:

```text
CodexSandboxService.OpenAI.Codex
```

该服务本身是正常组件.

------

# 12. 登录异常时的处理顺序

如果 ChatGPT GUI 能启动, 但登录失败, 不要立即去改 Loopback 或系统网络.

先确认最终配置仍然是:

```text
HTTP_PROXY  = http://127.0.0.1:10809
HTTPS_PROXY = http://127.0.0.1:10809
NO_PROXY    = localhost,127.0.0.1,::1
```

并确保没有遗留:

```text
ALL_PROXY=socks5://127.0.0.1:10808
```

我们最终恢复登录后, ChatGPT 与 Codex 都实测连接到:

```text
127.0.0.1:10809
```

如果再次出现登录异常, 优先使用附录 C 检查实际 TCP 连接, 不要仅根据“App 能打开”判断代理状态.

------

# 13. 安全边界

当前方案是:

> **应用层强制代理, 并通过实际进程树 TCP 连接验证.**

我们已经实测:

```text
ChatGPT → 10809
Codex   → 10809
无直接公网 TCP
```

但它不是 Windows Firewall 意义上的:

```text
无论未来应用如何实现, 都绝对禁止直连
```

如果以后要求网络层硬性禁止直连, 需要额外使用:

```text
Windows Firewall outbound rule
```

或:

```text
TUN / 系统级路由
```

当前文档只描述已经验证成功的应用层方案.

------

# 附录 A: chatgpt-proxy.cmd

```cmd
@echo off
setlocal

rem ============================================================================
rem ChatGPT Desktop / Codex proxy launcher
rem
rem Keep this .cmd file in the same directory as chatgpt-proxy.ps1.
rem The PowerShell script performs the actual MSIX activation and proxy setup.
rem ============================================================================

set "SCRIPT=%~dp0chatgpt-proxy.ps1"

if not exist "%SCRIPT%" (
    echo.
    echo [ERROR] Cannot find:
    echo         %SCRIPT%
    echo.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
    echo.
    echo [ERROR] ChatGPT proxy launcher failed.
    echo         Exit code: %EXIT_CODE%
    echo.
    pause
)

exit /b %EXIT_CODE%
```

------

# 附录 B: chatgpt-proxy.ps1

```powershell
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ============================================================================
# ChatGPT Desktop / Codex proxy launcher
#
# Verified setup:
#   HTTP proxy : 127.0.0.1:10809
#
# Why MSIX activation is used:
#   Newer ChatGPT Desktop builds must retain their MSIX package identity.
#   Launching ChatGPT.exe directly from WindowsApps can fail with:
#       "The process has no package identity."
#
# Proxy strategy:
#   1. HTTP_PROXY / HTTPS_PROXY:
#      inherited by ChatGPT and Codex backend processes that honor them.
#
#   2. --proxy-server:
#      explicitly configures the Chromium networking used by ChatGPT Desktop.
#
#   3. --disable-quic:
#      keeps Chromium away from QUIC / HTTP3 UDP networking so the tested TCP
#      proxy path remains the active path.
#
#   4. NO_PROXY:
#      keeps localhost traffic, including local callback / IPC traffic, local.
#
# ALL_PROXY is deliberately removed to avoid conflicts between the tested
# HTTP proxy and a separate SOCKS proxy.
#
# The verified setup also keeps %USERPROFILE%\.codex\.env with matching
# HTTP(S) proxy and NO_PROXY values. We have not isolated whether the Codex
# backend relies on inherited environment variables, .env, or both, so keep
# the tested .env configuration unless you intentionally re-verify the setup.
# ============================================================================

$proxyHost = '127.0.0.1'
$proxyPort = 10809
$proxyUri  = "http://${proxyHost}:$proxyPort"

function Test-TcpEndpoint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostName,

        [Parameter(Mandatory = $true)]
        [int]$Port,

        [int]$TimeoutMs = 1500
    )

    $client = New-Object System.Net.Sockets.TcpClient

    try {
        $asyncResult = $client.BeginConnect($HostName, $Port, $null, $null)

        if (-not $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            return $false
        }

        $client.EndConnect($asyncResult)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Close()
    }
}

try {
    # Do not attach to an already-running ChatGPT instance. An existing process
    # may have been started without the proxy arguments/environment.
    if (Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue) {
        throw 'ChatGPT is already running. Fully exit ChatGPT before using chatgpt-proxy.cmd.'
    }

    if (-not (Test-TcpEndpoint -HostName $proxyHost -Port $proxyPort)) {
        throw "HTTP proxy ${proxyHost}:$proxyPort is not available."
    }

    # Resolve the currently installed package and its registered AUMID instead
    # of hard-coding a versioned WindowsApps path.
    $package = Get-AppxPackage -Name 'OpenAI.Codex' -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if (-not $package) {
        throw 'OpenAI.Codex package was not found.'
    }

    $packageFamilyName = $package.PackageFamilyName

    $startAppCandidates = @(
        Get-StartApps |
        Where-Object {
            $\_.AppID -like "$packageFamilyName!*"
        }
    )

    $startApp = $startAppCandidates |
        Where-Object {
            $\_.AppID -eq "$packageFamilyName!App"
        } |
        Select-Object -First 1

    if (-not $startApp) {
        $startApp = $startAppCandidates | Select-Object -First 1
    }

    if (-not $startApp) {
        throw "No Start-menu application entry was found for package family '$packageFamilyName'."
    }

    $appUserModelId = $startApp.AppID

    # Keep all tested HTTP(S) traffic on the local HTTP proxy.
    $env:HTTP\_PROXY  = $proxyUri
    $env:HTTPS\_PROXY = $proxyUri
    $env:NO_PROXY    = 'localhost,127.0.0.1,::1,.local'

    # Avoid ambiguity between HTTP(S) proxy variables and a separate SOCKS
    # endpoint. The verified configuration does not require ALL_PROXY.
    Remove-Item Env:ALL_PROXY -ErrorAction SilentlyContinue

    if (-not ('MsixAppLauncher' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class MsixAppLauncher
{
    [ComImport]
    [Guid("2E941141-7F97-4756-BA1D-9DECDE894A3D")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IApplicationActivationManager
    {
        [PreserveSig]
        int ActivateApplication(
            [MarshalAs(UnmanagedType.LPWStr)] string appUserModelId,
            [MarshalAs(UnmanagedType.LPWStr)] string arguments,
            uint options,
            out uint processId);
    }

    [ComImport]
    [Guid("45BA127D-10A8-46EA-8AB7-56EA9078943C")]
    private class ApplicationActivationManager
    {
    }

    public static uint Activate(string appUserModelId, string arguments)
    {
        var manager =
            (IApplicationActivationManager)new ApplicationActivationManager();

        uint processId;

        int hr = manager.ActivateApplication(
            appUserModelId,
            arguments,
            0,
            out processId);

        if (hr < 0)
            Marshal.ThrowExceptionForHR(hr);

        return processId;
    }
}
'@
    }

    $arguments = "--proxy-server=$proxyUri --disable-quic"

    $appPid = [MsixAppLauncher]::Activate(
        $appUserModelId,
        $arguments
    )

    Write-Host ''
    Write-Host '[OK] ChatGPT started through proxy.'
    Write-Host "     PID   : $appPid"
    Write-Host "     AUMID : $appUserModelId"
    Write-Host "     Proxy : $proxyUri"
    Write-Host ''

    exit 0
}
catch {
    Write-Host ''
    Write-Host '[ERROR] Failed to start ChatGPT through proxy.'
    Write-Host "        $($_.Exception.Message)"
    Write-Host ''

    exit 1
}
```

------

# 附录 C: ChatGPT 整棵进程树 TCP 验证脚本

```powershell
$all = Get-CimInstance Win32_Process

$chatgptIds = @(
    $all |
    Where-Object { $_.Name -eq 'ChatGPT.exe' } |
    Select-Object -ExpandProperty ProcessId
)

$roots = $all | Where-Object {
    $_.Name -eq 'ChatGPT.exe' -and
    $\_.ParentProcessId -notin $chatgptIds
}

$tree = [System.Collections.Generic.HashSet[int]]::new()

function Add-ProcessTree([int]$id) {
    if ($tree.Add($id)) {
        $all |
            Where-Object { $\_.ParentProcessId -eq $id } |
            ForEach-Object { Add-ProcessTree $_.ProcessId }
    }
}

$roots | ForEach-Object {
    Add-ProcessTree $_.ProcessId
}

$connections = Get-NetTCPConnection -State Established |
Where-Object {
    $tree.Contains([int]$_.OwningProcess)
} |
Select-Object `
    OwningProcess,
    @{Name='Process';Expression={
        try { (Get-Process -Id $_.OwningProcess).ProcessName }
        catch { '<unknown>' }
    }},
    LocalAddress,
    LocalPort,
    RemoteAddress,
    RemotePort

$connections |
Sort-Object OwningProcess,RemoteAddress,RemotePort |
Format-Table -AutoSize

$direct = $connections | Where-Object {
    $_.RemoteAddress -notin @('127.0.0.1', '::1')
}

Write-Host ""

if ($direct) {
    Write-Host "WARNING: Direct external connections were detected:"
    $direct | Format-Table -AutoSize
} else {
    Write-Host "OK: No direct external TCP connections were detected in the ChatGPT process tree."
}
```

------

# 附录 D: 快速检查命令

查看 AppX 包:

```powershell
Get-AppxPackage |
    Where-Object {
        $_.Name -match 'OpenAI|ChatGPT|Codex'
    } |
    Select-Object Name,Version,PackageFamilyName,PackageFullName,InstallLocation
```

查看 AUMID:

```powershell
Get-StartApps |
Where-Object {
    $_.Name -match 'ChatGPT|Codex|OpenAI'
} |
Format-Table Name,AppID -AutoSize
```

查看 Loopback Exemption:

```powershell
CheckNetIsolation.exe LoopbackExempt -s
```

查看 Codex Sandbox Service:

```powershell
Get-Service | Where-Object {
    $_.Name -like '*codex*' -or
    $_.DisplayName -like '*codex*'
} | Format-List Name,DisplayName,Status,StartType
```

查看 Windows Setup 错误:

```powershell
Get-Content "$env:USERPROFILE\.codex\.sandbox\setup_error.json" -Raw
```

查看 ChatGPT NetworkService:

```powershell
Get-CimInstance Win32_Process |
Where-Object {
    $_.Name -eq 'ChatGPT.exe' -and
    $_.CommandLine -match 'network\.mojom\.NetworkService'
} |
Format-List ProcessId,ParentProcessId,CommandLine
```

------

# 14. 后续维护原则

如果 ChatGPT Desktop 再次更新, 优先验证以下三件事:

```text
1. chatgpt-proxy 是否还能通过 AUMID 正常启动 App.
2. ChatGPT.exe / codex.exe 是否仍全部连接 127.0.0.1:10809.
3. Windows Setup / Sandbox 是否仍然完成.
```

不要因为版本更新就重新回到直接运行:

```text
WindowsApps\...\ChatGPT.exe
```

如果 MSIX 激活机制再次变化, 应优先调整 AUMID / Activation 层, 而不是绕开 Package Identity.