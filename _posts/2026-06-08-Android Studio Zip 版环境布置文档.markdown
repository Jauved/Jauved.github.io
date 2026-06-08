---
layout: post
title: "Android Studio Zip 版环境布置文档"
categories: [IDE, AndroidStudio]
tags: IDE AndroidStudio zip 重装系统 环境布置
math: true


---

# Android Studio Zip 版环境布置文档

## 1. 目标

本文档用于在 Windows 重装系统后, 快速恢复 Android Studio zip 版环境。

目标包括:

```text
1. Android Studio 本体放在非系统盘。
2. Android SDK 放在非系统盘。
3. Gradle 缓存放在非系统盘。
4. Android 用户数据和 AVD 数据放在非系统盘。
5. 通过 bat 恢复环境变量和 Path。
6. 尽量减少重装系统后的重复配置。
```

------

## 2. 目录规划

统一根目录:

```text
D:\Dev\App\Android
```

推荐结构:

```text
D:\Dev\App\Android
├── android-studio
│   └── bin\studio64.exe
│
├── Sdk
│   ├── platforms
│   ├── build-tools
│   ├── platform-tools
│   ├── emulator
│   └── cmdline-tools
│
├── Gradle
│   ├── gradle-6.1.1
│   ├── gradle-8.13
│   └── GradleCache
│
├── JDK
│   ├── jdk-11.0.28+6
│   └── jdk-21.0.9+10
│
├── UserHome
│   └── avd
│
├── Build
│   ├── AARs
│   └── APK
│
└── Scripts
    └── restore_android_env.bat
```

说明:

```text
android-studio:
Android Studio zip 解压出来的目录。不要由 bat 创建。

Sdk:
Android SDK 目录。

Gradle:
本地 Gradle 工具目录和 Gradle 缓存目录。

JDK:
本地 JDK 目录。

UserHome:
Android 工具的用户级数据目录。

UserHome\avd:
Android 模拟器虚拟设备目录。

Build:
本地构建产物输出目录。

Scripts:
本机私有脚本目录, 不放进 Git 仓库。
```

------

## 3. Android Studio zip 放置方式

Android Studio zip 解压后通常会得到:

```text
android-studio
```

将整个文件夹放到:

```text
D:\Dev\App\Android\android-studio
```

最终应确认以下文件存在:

```text
D:\Dev\App\Android\android-studio\bin\studio64.exe
D:\Dev\App\Android\android-studio\jbr\bin\java.exe
```

注意不要变成:

```text
D:\Dev\App\Android\android-studio\android-studio\bin\studio64.exe
```

------

## 4. 环境恢复脚本

文件位置:

```text
D:\Dev\App\Android\Scripts\restore_android_env.bat
```

用途:

```text
1. 创建基础目录。
2. 设置用户环境变量。
3. 把已经存在的工具目录加入用户 Path。
4. 不创建 android-studio 目录。
5. 不移动文件。
6. 不删除文件。
7. 不创建快捷方式。
```

脚本内容:

```bat
@echo off
setlocal

rem ============================================================
rem Android development environment restore script.
rem - Create folders if missing.
rem - Set user environment variables.
rem - Add existing tool paths to user PATH.
rem - Does not move, delete files, or create shortcuts.
rem - Does not create the android-studio folder.
rem ============================================================

set "ANDROID_ROOT=D:\Dev\App\Android"

set "ANDROID_STUDIO_DIR=%ANDROID_ROOT%\android-studio"
set "ANDROID_SDK_DIR=%ANDROID_ROOT%\Sdk"

set "GRADLE_DIR=%ANDROID_ROOT%\Gradle"
set "GRADLE_USER_HOME_DIR=%ANDROID_ROOT%\Gradle\GradleCache"

set "JDK_DIR=%ANDROID_ROOT%\JDK"
set "JDK_11_DIR=%ANDROID_ROOT%\JDK\jdk-11.0.28+6"
set "JDK_21_DIR=%ANDROID_ROOT%\JDK\jdk-21.0.9+10"

set "ANDROID_USER_HOME_DIR=%ANDROID_ROOT%\UserHome"
set "ANDROID_AVD_HOME_DIR=%ANDROID_ROOT%\UserHome\avd"

rem Default: use Android Studio bundled JBR.
set "JAVA_HOME_DIR=%ANDROID_STUDIO_DIR%\jbr"

rem Optional JDK choices:
rem set "JAVA_HOME_DIR=%JDK_11_DIR%"
rem set "JAVA_HOME_DIR=%JDK_21_DIR%"

rem ---------- Create folders if missing ----------
if not exist "%ANDROID_ROOT%" mkdir "%ANDROID_ROOT%"
if not exist "%ANDROID_SDK_DIR%" mkdir "%ANDROID_SDK_DIR%"
if not exist "%GRADLE_DIR%" mkdir "%GRADLE_DIR%"
if not exist "%GRADLE_USER_HOME_DIR%" mkdir "%GRADLE_USER_HOME_DIR%"
if not exist "%JDK_DIR%" mkdir "%JDK_DIR%"
if not exist "%ANDROID_USER_HOME_DIR%" mkdir "%ANDROID_USER_HOME_DIR%"
if not exist "%ANDROID_AVD_HOME_DIR%" mkdir "%ANDROID_AVD_HOME_DIR%"
if not exist "%ANDROID_ROOT%\Build" mkdir "%ANDROID_ROOT%\Build"
if not exist "%ANDROID_ROOT%\Build\AARs" mkdir "%ANDROID_ROOT%\Build\AARs"
if not exist "%ANDROID_ROOT%\Build\APK" mkdir "%ANDROID_ROOT%\Build\APK"
if not exist "%ANDROID_ROOT%\Scripts" mkdir "%ANDROID_ROOT%\Scripts"

rem ---------- Set user environment variables ----------
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Environment]::SetEnvironmentVariable('ANDROID_HOME', '%ANDROID_SDK_DIR%', 'User');" ^
  "[Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', '%ANDROID_SDK_DIR%', 'User');" ^
  "[Environment]::SetEnvironmentVariable('GRADLE_USER_HOME', '%GRADLE_USER_HOME_DIR%', 'User');" ^
  "[Environment]::SetEnvironmentVariable('ANDROID_USER_HOME', '%ANDROID_USER_HOME_DIR%', 'User');" ^
  "[Environment]::SetEnvironmentVariable('ANDROID_AVD_HOME', '%ANDROID_AVD_HOME_DIR%', 'User');"

rem ---------- Set JAVA_HOME only when java.exe exists ----------
if exist "%JAVA_HOME_DIR%\bin\java.exe" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "[Environment]::SetEnvironmentVariable('JAVA_HOME', '%JAVA_HOME_DIR%', 'User');"
) else (
    echo [WARN] JAVA_HOME target does not exist yet:
    echo %JAVA_HOME_DIR%
    echo [WARN] JAVA_HOME was not changed.
)

rem ---------- Add existing tool paths to user PATH ----------
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pathsToAdd = @();" ^
  "if (Test-Path '%ANDROID_STUDIO_DIR%\bin') { $pathsToAdd += '%ANDROID_STUDIO_DIR%\bin' }" ^
  "if (Test-Path '%ANDROID_SDK_DIR%\platform-tools') { $pathsToAdd += '%ANDROID_SDK_DIR%\platform-tools' }" ^
  "if (Test-Path '%ANDROID_SDK_DIR%\emulator') { $pathsToAdd += '%ANDROID_SDK_DIR%\emulator' }" ^
  "if (Test-Path '%ANDROID_SDK_DIR%\cmdline-tools\latest\bin') { $pathsToAdd += '%ANDROID_SDK_DIR%\cmdline-tools\latest\bin' }" ^
  "if (Test-Path '%JAVA_HOME_DIR%\bin') { $pathsToAdd += '%JAVA_HOME_DIR%\bin' }" ^
  "$current = [Environment]::GetEnvironmentVariable('Path', 'User');" ^
  "$items = @();" ^
  "if ($current) { $items = $current -split ';' | Where-Object { $_ -and $_.Trim() -ne '' } }" ^
  "$normalized = $items | ForEach-Object { $_.Trim().TrimEnd('\').ToLowerInvariant() };" ^
  "foreach ($p in $pathsToAdd) {" ^
  "  $np = $p.Trim().TrimEnd('\').ToLowerInvariant();" ^
  "  if ($normalized -notcontains $np) { $items += $p; $normalized += $np }" ^
  "}" ^
  "[Environment]::SetEnvironmentVariable('Path', ($items -join ';'), 'User');"

echo.
echo [OK] Android environment restored.
echo.
echo Created / checked folders:
echo %ANDROID_ROOT%
echo %ANDROID_SDK_DIR%
echo %GRADLE_DIR%
echo %GRADLE_USER_HOME_DIR%
echo %JDK_DIR%
echo %ANDROID_USER_HOME_DIR%
echo %ANDROID_AVD_HOME_DIR%
echo %ANDROID_ROOT%\Build
echo %ANDROID_ROOT%\Build\AARs
echo %ANDROID_ROOT%\Build\APK
echo %ANDROID_ROOT%\Scripts
echo.
echo Android Studio expected path:
echo %ANDROID_STUDIO_DIR%
echo.
echo Environment variables:
echo ANDROID_HOME=%ANDROID_SDK_DIR%
echo ANDROID_SDK_ROOT=%ANDROID_SDK_DIR%
echo GRADLE_USER_HOME=%GRADLE_USER_HOME_DIR%
echo ANDROID_USER_HOME=%ANDROID_USER_HOME_DIR%
echo ANDROID_AVD_HOME=%ANDROID_AVD_HOME_DIR%
echo JAVA_HOME target=%JAVA_HOME_DIR%
echo.
echo PATH was updated only for paths that already exist.
echo Restart terminal / Rider / Android Studio to reload environment variables.
echo.

pause
exit /b 0
```

------

## 5. 首次布置步骤

### 5.1 准备目录

创建:

```text
D:\Dev\App\Android
```

### 5.2 解压 Android Studio

将 Android Studio zip 解压出的 `android-studio` 放到:

```text
D:\Dev\App\Android\android-studio
```

确认:

```text
D:\Dev\App\Android\android-studio\bin\studio64.exe
D:\Dev\App\Android\android-studio\jbr\bin\java.exe
```

### 5.3 放入 Gradle

放入:

```text
D:\Dev\App\Android\Gradle\gradle-6.1.1
D:\Dev\App\Android\Gradle\gradle-8.13
```

### 5.4 放入 JDK

放入:

```text
D:\Dev\App\Android\JDK\jdk-11.0.28+6
D:\Dev\App\Android\JDK\jdk-21.0.9+10
```

### 5.5 执行环境恢复脚本

执行:

```text
D:\Dev\App\Android\Scripts\restore_android_env.bat
```

执行后关闭并重新打开 CMD / PowerShell / Rider Terminal。

------

## 6. Android Studio 首次启动

运行:

```text
D:\Dev\App\Android\android-studio\bin\studio64.exe
```

首次启动时, SDK 目录选择:

```text
D:\Dev\App\Android\Sdk
```

Android Studio 安装 SDK 组件后, SDK 应落在:

```text
D:\Dev\App\Android\Sdk\platforms
D:\Dev\App\Android\Sdk\build-tools
D:\Dev\App\Android\Sdk\platform-tools
D:\Dev\App\Android\Sdk\emulator
```

如果 SDK 安装完成后才创建 `platform-tools`, 需要再次运行:

```text
D:\Dev\App\Android\Scripts\restore_android_env.bat
```

然后重新打开终端。

------

## 7. 验证环境

### 7.1 验证 adb

执行:

```bat
where adb
adb version
```

正常应输出:

```text
D:\Dev\App\Android\Sdk\platform-tools\adb.exe
```

如果 `where adb` 找不到, 但下面命令可用:

```bat
"D:\Dev\App\Android\Sdk\platform-tools\adb.exe" version
```

说明 adb 本体正常, 只是当前终端还没有刷新 Path。

### 7.2 验证用户 Path

执行:

```powershell
[Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Select-String "platform-tools"
```

正常应看到:

```text
D:\Dev\App\Android\Sdk\platform-tools
```

------

## 8. 常见问题

### 8.1 adb 不是内部或外部命令

原因通常是当前终端没有刷新用户 Path。

处理方式:

```text
1. 确认 adb.exe 存在。
2. 重新执行 restore_android_env.bat。
3. 关闭并重新打开 CMD / PowerShell / Rider Terminal。
4. 再执行 where adb。
```

### 8.2 JAVA_HOME 没有设置

如果看到:

```text
[WARN] JAVA_HOME target does not exist yet
```

说明这个文件不存在:

```text
D:\Dev\App\Android\android-studio\jbr\bin\java.exe
```

检查 Android Studio zip 是否解压正确。

### 8.3 AVD 目录为空

这是正常的。只有创建 Android Virtual Device 后才会生成具体设备数据。

目标目录:

```text
D:\Dev\App\Android\UserHome\avd
```

如果创建模拟器后该目录仍为空, 检查 Android Studio 是否在新环境变量生效后启动。
