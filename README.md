# Lee-HiDPI

Lee-HiDPI is a small macOS menu bar app that helps external displays use clearer HiDPI scaling.

Lee-HiDPI 是一个轻量 macOS 菜单栏工具，用来给外接显示器启用更清晰的 HiDPI 显示效果。它的目标是做成“傻瓜式”工具：选择显示器，点击一个按钮，剩下的交给 App 处理。

## Features

- One-click clarity optimization for external displays.
- Recommended HiDPI mode for 24-inch QHD/2K displays.
- Automatic Chinese / English UI based on system language.
- Manual Chinese / English switch inside the app.
- Safe reset button to remove Lee-HiDPI's display override.
- Menu bar app with only `Open` and `Quit`.
- CLI for debugging and advanced users.
- Built with Swift Package Manager and native AppKit.

## What It Does

Many external displays run in a standard 1x mode on macOS. Text can look blurry because the UI resolution and render resolution are the same.

Lee-HiDPI creates a macOS display override for the selected external monitor so macOS can expose HiDPI modes such as:

```text
1920x1080 HiDPI -> 3840x2160 rendered
2048x1152 HiDPI -> 4096x2304 rendered
```

For a 24-inch QHD/2K external display, the default recommendation is:

```text
Best:   1920x1080 HiDPI
Backup: 2048x1152 HiDPI
```

## Screenshot

No screenshot is committed yet. After packaging, launch the app with:

```sh
open dist/Lee-HiDPI.app
```

## Requirements

- macOS 14 or later
- Xcode command line tools
- Swift 6.3 or later
- External display

## Quick Start

Build and run from source:

```sh
swift run lee-hidpi
```

Package as a macOS app:

```sh
./Scripts/package_app.sh
open dist/Lee-HiDPI.app
```

## App Usage

The app is intentionally simple:

1. Choose your external display.
2. Click `Optimize Clarity` / `一键优化清晰度`.
3. If macOS asks for administrator permission, approve it.
4. Reconnect the display or restart macOS if prompted.
5. Click the button again after reconnecting/restarting.

To undo changes:

1. Choose the external display.
2. Click `Reset` / `恢复默认`.
3. Reconnect the display or restart macOS.

## Language

On first launch:

- Chinese system language -> Chinese UI
- Other system languages -> English UI

The language switch in the app saves your preference with `UserDefaults`.

## CLI

List detected displays:

```sh
swift run lee-hidpi --list
```

Apply or prepare the recommended setup for the first external display:

```sh
swift run lee-hidpi --best
```

Reset the first external display configuration:

```sh
swift run lee-hidpi --reset
```

Export recommended display override files to the user folder:

```sh
swift run lee-hidpi --export
```

Export directly to the system override folder:

```sh
sudo .build/release/lee-hidpi --export --system
```

## File Locations

User export folder:

```text
~/Documents/LeeHiDPIOverrides
```

macOS display override folder:

```text
/Library/Displays/Contents/Resources/Overrides
```

Lee-HiDPI only targets the selected external display's vendor/product override file.

## Safety Notes

Display overrides affect how macOS exposes display modes. Lee-HiDPI keeps the UI simple, but the underlying operation still touches system display configuration.

The app is designed to be conservative:

- It does not automatically configure built-in displays.
- It only writes the selected external display override.
- Reset removes Lee-HiDPI's override for the selected display.
- Administrator permission is requested through macOS when needed.

After installing or resetting an override, macOS usually needs one of these:

- reconnect the external display
- restart macOS

## Project Structure

```text
Package.swift
Sources/
  LeeHiDPICore/
    DisplayInventory.swift
    DisplayModeControl.swift
    DisplayModel.swift
    DisplayOverridePayload.swift
    DisplayOverrideStore.swift
    DisplayRecommendation.swift
  LeeHiDPIApp/
    main.swift
Tests/
  LeeHiDPICoreTests/
    HiDPITests.swift
Scripts/
  package_app.sh
```

## Development

Run tests:

```sh
swift test
```

Build release binary:

```sh
swift build -c release --product lee-hidpi
```

Package app:

```sh
./Scripts/package_app.sh
```

The packaged app is generated at:

```text
dist/Lee-HiDPI.app
```

## GitHub Publishing Checklist

Before publishing:

```sh
swift test
./Scripts/package_app.sh
```

Recommended first commit:

```sh
git init
git add .
git commit -m "Initial Lee-HiDPI release"
```

## Current Limitations

- Display names are currently based on CoreGraphics/vendor/product information.
- Virtual display, DDC brightness, mirroring, and BetterDisplay-style advanced controls are not implemented.
- HiDPI override behavior can vary across macOS versions and display firmware.
- Some changes require reconnecting the display or restarting macOS.

## License

No license has been selected yet. Add a `LICENSE` file before public release if you want others to reuse or contribute to the code.

---

# 中文说明

Lee-HiDPI 是一个轻量级 macOS 菜单栏 App，用来帮助外接显示器启用更清晰的 HiDPI 缩放模式。

它的设计目标是尽量简单：选择外接显示器，点击一次按钮，App 自动处理推荐配置。适合不想研究复杂显示参数、只想让文字更清晰的用户。

## 功能特性

- 外接显示器一键优化清晰度。
- 针对 24 寸 QHD/2K 显示器提供推荐 HiDPI 配置。
- 首次启动自动检测系统语言：中文系统显示中文，其它系统显示英文。
- App 内可手动切换中文 / English。
- 提供恢复默认功能，移除 Lee-HiDPI 写入的显示器配置。
- 菜单栏右键只保留 `打开` 和 `退出`。
- 提供命令行工具，方便调试和高级用户使用。
- 使用 Swift Package Manager 和原生 AppKit 开发。

## 它解决什么问题

很多普通外接显示器在 macOS 上默认运行在标准 1x 模式。此时界面分辨率和渲染分辨率一致，文字可能看起来发虚、不够锐利。

Lee-HiDPI 会为选中的外接显示器生成 macOS display override 配置，让系统暴露 HiDPI 模式，例如：

```text
1920x1080 HiDPI -> 3840x2160 渲染
2048x1152 HiDPI -> 4096x2304 渲染
```

对于 24 寸 QHD/2K 外接显示器，默认推荐：

```text
最佳：1920x1080 HiDPI
备用：2048x1152 HiDPI
```

## 系统要求

- macOS 14 或更高版本
- Xcode Command Line Tools
- Swift 6.3 或更高版本
- 一台外接显示器

## 快速开始

从源码运行：

```sh
swift run lee-hidpi
```

打包成 macOS App：

```sh
./Scripts/package_app.sh
open dist/Lee-HiDPI.app
```

## App 使用方式

Lee-HiDPI 的界面刻意保持简单：

1. 选择外接显示器。
2. 点击 `一键优化清晰度`。
3. 如果 macOS 弹出管理员授权窗口，请确认。
4. 如果 App 提示需要重新连接显示器或重启 macOS，请按提示操作。
5. 重新连接或重启后，再点击一次 `一键优化清晰度`。

恢复默认：

1. 选择外接显示器。
2. 点击 `恢复默认`。
3. 重新连接显示器或重启 macOS。

## 语言

首次启动时：

- 系统语言是中文：默认显示中文界面。
- 系统语言不是中文：默认显示英文界面。

你也可以在 App 内使用 `中文 / EN` 切换语言。选择会保存到 `UserDefaults`，下次打开会自动沿用。

## 命令行用法

列出当前检测到的显示器：

```sh
swift run lee-hidpi --list
```

为第一台外接显示器应用或准备推荐配置：

```sh
swift run lee-hidpi --best
```

重置第一台外接显示器配置：

```sh
swift run lee-hidpi --reset
```

导出推荐配置到用户目录：

```sh
swift run lee-hidpi --export
```

直接导出到系统 override 目录：

```sh
sudo .build/release/lee-hidpi --export --system
```

## 文件位置

用户导出目录：

```text
~/Documents/LeeHiDPIOverrides
```

macOS 显示器 override 目录：

```text
/Library/Displays/Contents/Resources/Overrides
```

Lee-HiDPI 只会针对选中的外接显示器 vendor/product 配置文件进行操作。

## 安全说明

显示器 override 会影响 macOS 暴露哪些显示模式。Lee-HiDPI 的界面虽然简单，但底层仍然涉及系统显示配置。

Lee-HiDPI 的安全策略：

- 不自动配置内建显示器。
- 只写入选中的外接显示器配置。
- `恢复默认` 只移除 Lee-HiDPI 针对选中显示器写入的配置。
- 需要写入系统目录时，通过 macOS 管理员授权弹窗完成。

安装或重置配置后，macOS 通常需要：

- 重新连接外接显示器，或
- 重启 macOS

## 项目结构

```text
Package.swift
Sources/
  LeeHiDPICore/
    DisplayInventory.swift
    DisplayModeControl.swift
    DisplayModel.swift
    DisplayOverridePayload.swift
    DisplayOverrideStore.swift
    DisplayRecommendation.swift
  LeeHiDPIApp/
    main.swift
Tests/
  LeeHiDPICoreTests/
    HiDPITests.swift
Scripts/
  package_app.sh
```

## 开发

运行测试：

```sh
swift test
```

构建 release 命令行工具：

```sh
swift build -c release --product lee-hidpi
```

打包 App：

```sh
./Scripts/package_app.sh
```

打包结果：

```text
dist/Lee-HiDPI.app
```

## 发布到 GitHub 前

建议先运行：

```sh
swift test
./Scripts/package_app.sh
```

首次提交示例：

```sh
git init
git add .
git commit -m "Initial Lee-HiDPI release"
```

## 当前限制

- 显示器名称目前基于 CoreGraphics / vendor / product 信息生成。
- 尚未实现虚拟显示器、DDC 亮度控制、镜像、BetterDisplay 风格的高级控制等功能。
- 不同 macOS 版本、不同显示器固件对 display override 的支持可能不同。
- 某些配置变更需要重新连接显示器或重启 macOS。

## 许可证

目前尚未选择开源许可证。如果要公开发布并允许他人复用或贡献代码，建议添加 `LICENSE` 文件。
