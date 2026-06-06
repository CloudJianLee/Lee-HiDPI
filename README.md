# Lee-HiDPI

[English](README_EN.md) | 简体中文

一款简单、原生的 macOS 菜单栏工具，为外接显示器启用更清晰的 HiDPI 缩放。

Lee-HiDPI 目前主要针对 **24 英寸 2K/QHD（2560×1440）显示器**设计。选择显示器并点击一次按钮，应用会安装推荐配置，尽量减少需要理解和调整的参数。

## 下载与安装

1. 从 [Releases](https://github.com/CloudJianLee/Lee-HiDPI/releases) 下载最新的 `macos-universal.zip`。
2. 解压后，将 `Lee-HiDPI.app` 移入“应用程序”文件夹。
3. 首次启动时右键点击 App，选择“打开”。

当前公开构建使用临时签名，尚未经过 Apple Developer ID 签名和公证，因此 macOS 可能显示安全提示。请只从本仓库的 Releases 页面下载。

系统要求：

- macOS 14 Sonoma 或更高版本
- Apple Silicon 或 Intel Mac
- 一台外接显示器

## 使用方法

1. 打开 Lee-HiDPI，选择需要优化的外接显示器。
2. 点击“**一键优化清晰度**”。
3. 按 macOS 提示输入管理员密码。
4. 如果配置刚刚安装，请重新连接显示器或重启 Mac。
5. 再次点击“一键优化清晰度”，应用推荐的显示模式。

菜单栏图标支持双击打开主窗口；右键菜单只保留“打开”和“退出”。

需要撤销时，选择对应显示器并点击“**恢复默认**”，然后重新连接显示器或重启 Mac。

## 它做了什么

普通外接显示器在 macOS 上可能只提供 1× 模式，导致文字边缘不够清晰。Lee-HiDPI 会为选中的外接显示器创建系统 display override，使 macOS 可以识别对应的 HiDPI 模式。

对 24 英寸 2K/QHD 显示器，当前推荐：

```text
首选：1920×1080 HiDPI（3840×2160 渲染）
备用：2048×1152 HiDPI（4096×2304 渲染）
```

应用不会修改 Mac 内建显示器，也不会安装常驻后台服务。写入系统配置时，授权由 macOS 管理员确认窗口完成。

## 语言

首次启动会根据系统首选语言自动选择界面：

- 中文系统：简体中文
- 其他语言：English

也可以在应用内随时切换，选择会保存在本机。

## 重要说明

- HiDPI 效果取决于 macOS 版本、显示器固件、连接方式和显卡能力。
- 安装或移除 display override 后，通常需要重新连接显示器或重启系统。
- “恢复默认”只删除 Lee-HiDPI 为当前所选显示器管理的配置文件。
- 当前产品定位是 24 英寸 2K 显示器的一键优化工具，并非 BetterDisplay 的完整替代品。
- 尚未提供虚拟显示器、DDC 亮度、镜像和高级分辨率编辑功能。

遇到问题时，请在 [Issues](https://github.com/CloudJianLee/Lee-HiDPI/issues) 中附上 macOS 版本、Mac 型号、显示器型号和连接方式。

## 从源码构建

需要 Xcode Command Line Tools 和 Swift 6.3 或更高版本。

```sh
git clone https://github.com/CloudJianLee/Lee-HiDPI.git
cd Lee-HiDPI
swift test
./Scripts/package_app.sh
open dist/Lee-HiDPI.app
```

打包脚本默认：

- 运行完整测试
- 构建 Universal 2（`arm64` + `x86_64`）
- 生成标准 App Bundle
- 使用临时签名并验证签名
- 校验 `Info.plist` 和二进制架构

生成 GitHub Release 附件：

```sh
./Scripts/package_app.sh --archive
```

版本号统一维护在 [`Config/Version.env`](Config/Version.env)。如有 Developer ID 证书，可指定正式签名身份：

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  ./Scripts/package_app.sh --archive
```

## 命令行

```sh
swift run lee-hidpi --list
swift run lee-hidpi --best
swift run lee-hidpi --reset
swift run lee-hidpi --export
```

命令行功能主要用于开发和诊断。普通用户直接使用 App 即可。

## 项目结构

```text
Config/                 版本与 Bundle 配置
Resources/              App Bundle 元数据
Scripts/                构建与打包脚本
Sources/LeeHiDPICore/   显示器检测、推荐和 override 逻辑
Sources/LeeHiDPIApp/    AppKit 菜单栏应用与 CLI
Tests/                  Swift Testing 测试
```

## 许可证

本项目采用 [MIT License](LICENSE) 开源。
