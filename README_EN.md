# Lee-HiDPI

English | [简体中文](README.md)

A small native macOS menu bar app that enables clearer HiDPI scaling for external displays.

Lee-HiDPI is currently designed primarily for **24-inch 2K/QHD (2560×1440) displays**. Select a display and click one button; the app installs and applies its recommended configuration without exposing unnecessary tuning controls.

## Download and Install

1. Download the latest `macos-universal.zip` from [Releases](https://github.com/CloudJianLee/Lee-HiDPI/releases).
2. Extract it and move `Lee-HiDPI.app` to Applications.
3. On first launch, Control-click the app and choose **Open**.

Public builds currently use ad-hoc signing and are not yet notarized with Apple. macOS may therefore show a security warning. Only download builds from this repository's Releases page.

Requirements:

- macOS 14 Sonoma or later
- Apple Silicon or Intel Mac
- An external display

## Usage

1. Open Lee-HiDPI and select the external display.
2. Click **Optimize Clarity**.
3. Approve the macOS administrator prompt.
4. If the configuration was just installed, reconnect the display or restart the Mac.
5. Click **Optimize Clarity** again to apply the recommended display mode.

Double-click the menu bar icon to open the main window. Its context menu contains only **Open** and **Quit**.

To undo the change, select the display, click **Reset**, then reconnect the display or restart the Mac.

## How It Works

Some external displays only expose 1× modes to macOS, which can make text edges look soft. Lee-HiDPI creates a display override for the selected external display so macOS can expose matching HiDPI modes.

Current recommendations for a 24-inch 2K/QHD display:

```text
Primary:  1920×1080 HiDPI (rendered at 3840×2160)
Fallback: 2048×1152 HiDPI (rendered at 4096×2304)
```

The app does not modify the Mac's built-in display or install a persistent background service. macOS presents its own administrator authorization dialog before system configuration is changed.

## Language

The first launch follows the system's preferred language:

- Chinese system language: Simplified Chinese
- Any other language: English

The language can also be switched inside the app, and the preference is saved locally.

## Important Notes

- Results depend on the macOS version, display firmware, connection type, and graphics hardware.
- Installing or removing a display override normally requires reconnecting the display or restarting macOS.
- Reset only removes the file managed by Lee-HiDPI for the selected display.
- The current product is a focused one-click tool for 24-inch 2K displays, not a complete BetterDisplay replacement.
- Virtual displays, DDC brightness, mirroring, and advanced resolution editing are not implemented.

When reporting a problem in [Issues](https://github.com/CloudJianLee/Lee-HiDPI/issues), include the macOS version, Mac model, display model, and connection type.

## Build from Source

Xcode Command Line Tools and Swift 6.3 or later are required.

```sh
git clone https://github.com/CloudJianLee/Lee-HiDPI.git
cd Lee-HiDPI
swift test
./Scripts/package_app.sh
open dist/Lee-HiDPI.app
```

The packaging script runs the test suite, builds a Universal 2 binary (`arm64` + `x86_64`), creates and validates the app bundle, and applies an ad-hoc signature.

Create versioned GitHub Release assets with:

```sh
./Scripts/package_app.sh --archive
```

The version is maintained in [`Config/Version.env`](Config/Version.env). A Developer ID identity can be supplied for distribution signing:

```sh
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
  ./Scripts/package_app.sh --archive
```

## Command Line

```sh
swift run lee-hidpi --list
swift run lee-hidpi --best
swift run lee-hidpi --reset
swift run lee-hidpi --export
```

The CLI is intended for development and diagnostics. Most users only need the app.

## Project Layout

```text
Config/                 Version and bundle configuration
Resources/              App bundle metadata
Scripts/                Build and packaging scripts
Sources/LeeHiDPICore/   Display detection, recommendations, and overrides
Sources/LeeHiDPIApp/    AppKit menu bar app and CLI
Tests/                  Swift Testing tests
```

## License

This project is open source under the [MIT License](LICENSE).
