import AppKit
import LeeHiDPICore
import Foundation

enum AppLanguage: String {
    case chinese = "zh-Hans"
    case english = "en"

    private static let defaultsKey = "LeeHiDPI.language"

    static func bootstrapDefaultIfNeeded() {
        guard UserDefaults.standard.string(forKey: defaultsKey) == nil else {
            return
        }

        let preferred = Locale.preferredLanguages.first ?? ""
        current = preferred.hasPrefix("zh") ? .chinese : .english
    }

    static var current: AppLanguage {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
               let language = AppLanguage(rawValue: rawValue) {
                return language
            }

            let preferred = Locale.preferredLanguages.first ?? ""
            return preferred.hasPrefix("zh") ? .chinese : .english
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }
}

struct AppStrings {
    var language: AppLanguage

    static var current: AppStrings {
        AppStrings(language: .current)
    }

    func text(_ chinese: String, _ english: String) -> String {
        language == .chinese ? chinese : english
    }

    var windowTitle: String { text("屏幕清晰度", "Display Clarity") }
    var menuOpen: String { text("打开", "Open") }
    var menuQuit: String { text("退出", "Quit") }
    var subtitle: String {
        text("为 24 寸 2K 外接屏自动选择舒服的 HiDPI。", "Automatically chooses a comfortable HiDPI mode for 24-inch QHD displays.")
    }
    var displayLabel: String { text("当前显示器", "Current Display") }
    var optimizeButton: String { text("一键优化清晰度", "Optimize Clarity") }
    var resetButton: String { text("恢复默认", "Reset") }
    var noDisplay: String { text("未选择显示器", "No display selected") }
    var clearMode: String { text("已处于最佳清晰模式", "Recommended clarity mode is active") }
    var otherHiDPIMode: String { text("当前是 HiDPI，但不是最佳配置", "HiDPI is active, but not the recommended mode") }
    var blurryMode: String { text("当前文字可能发虚", "Text may look blurry") }
    var builtinDisplayNeedsExternal: String { text("内建显示器不需要配置；请先选择外接显示器。", "Built-in displays do not need setup. Select an external display first.") }
    var builtinDisplayNoReset: String { text("内建显示器不需要重置。", "Built-in displays do not need reset.") }
    var chooseDisplay: String { text("请先选择显示器。", "Select a display first.") }
    var noRecommendation: String { text("没有找到适合这台显示器的推荐配置。", "No recommended setup was found for this display.") }
    var installedConfig: String {
        text("已安装。重插显示器或重启后，再点一次优化。", "Installed. Reconnect or restart, then optimize again.")
    }
    func generatedButInstallFailed(_ error: String, _ path: String) -> String {
        text("已生成配置，但自动安装失败：\(error)。配置位置：\(path)", "Setup file was generated, but automatic installation failed: \(error). Location: \(path)")
    }
    func generateFailed(_ error: String) -> String {
        text("生成清晰度配置失败：\(error)", "Failed to generate clarity setup: \(error)")
    }
    func appliedMode(_ mode: String) -> String {
        text("已应用最佳模式：\(mode)", "Applied recommended mode: \(mode)")
    }
    func applyFailed(_ error: String) -> String {
        text("应用最佳模式失败：\(error)", "Failed to apply recommended mode: \(error)")
    }
    var resetDone: String {
        text("已恢复默认。请重插显示器或重启 macOS。", "Reset complete. Reconnect the display or restart macOS.")
    }
    func resetFailed(_ error: String) -> String {
        text("恢复默认失败：\(error)", "Reset failed: \(error)")
    }
    func readDisplayFailed(_ error: String) -> String {
        text("读取显示器失败：\(error)", "Failed to read displays: \(error)")
    }
    var notHiDPIPrompt: String {
        text("点击上方按钮自动处理；需要权限时系统会弹窗。", "Click the button above; macOS will ask for permission if needed.")
    }
    var otherHiDPIPrompt: String {
        text("显示器已启用 HiDPI，但分辨率不是推荐值。点击优化可恢复最佳配置。", "HiDPI is active at a different resolution. Click Optimize to restore the recommended mode.")
    }
    var alreadyClearPrompt: String { text("已经处于清晰模式。", "Already in clarity mode.") }
    func detail(current: String, target: String) -> String {
        text("当前：\(current)  ·  推荐：\(target)", "Current: \(current)  ·  Recommended: \(target)")
    }
    func displayKind(isBuiltin: Bool) -> String {
        isBuiltin ? text("内建", "Built-in") : text("外接", "External")
    }
    func displayState(isOptimal: Bool, isHiDPI: Bool) -> String {
        if isOptimal {
            return text("最佳", "Optimal")
        }
        return isHiDPI ? "HiDPI" : text("标准", "Standard")
    }
    func modeDescription(_ mode: HiDPIMode) -> String {
        text("\(mode.logicalPoints) HiDPI（\(mode.backingPixels) 渲染）", "\(mode.logicalPoints) HiDPI (\(mode.backingPixels) rendered)")
    }
}

@main
enum LeeHiDPIAppMain {
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())

        if arguments.contains("--help") || arguments.contains("-h") {
            CommandLineInterface.printHelp()
            return
        }

        if arguments.contains("--list") {
            CommandLineInterface.listDisplays()
            return
        }

        if arguments.contains("--export") {
            CommandLineInterface.exportDisplays(useSystemStore: arguments.contains("--system"))
            return
        }

        if arguments.contains("--best") {
            CommandLineInterface.applyBestConfiguration()
            return
        }

        if arguments.contains("--reset") {
            CommandLineInterface.resetConfiguration()
            return
        }

        NSApplication.shared.setActivationPolicy(.accessory)
        AppLanguage.bootstrapDefaultIfNeeded()
        let delegate = AppDelegate()
        NSApplication.shared.delegate = delegate
        AppDelegate.shared = delegate
        NSApplication.shared.run()
    }
}

enum CommandLineInterface {
    static func printHelp() {
        print(
            """
            Lee-HiDPI

            用法：
              lee-hidpi              启动菜单栏 App
              lee-hidpi --list       列出已检测显示器和可生成的 HiDPI 模式
              lee-hidpi --best       为第一台外接显示器应用或导出最佳 HiDPI 配置
              lee-hidpi --reset      删除第一台外接显示器的 HiDPI 配置
              lee-hidpi --export     导出显示器 override plist 到 ~/Documents/LeeHiDPIOverrides
              lee-hidpi --export --system
                                        写入显示器 override plist 到 /Library/Displays/Contents/Resources/Overrides

            写入系统目录通常需要管理员权限。
            """
        )
    }

    static func listDisplays() {
        do {
            let displays = try CoreGraphicsDisplayInventory().activeDisplays()
            guard !displays.isEmpty else {
                print("未检测到活动显示器。")
                return
            }

            for display in displays {
                let modes = HiDPIModeGenerator.generateModes(for: display)
                print(summary(for: display))
                if modes.isEmpty {
                    print("  没有生成兼容的 HiDPI 模式。")
                } else {
                    for mode in modes {
                        print("  - \(mode)")
                    }
                }
            }
        } catch {
            print("读取显示器失败：\(error.localizedDescription)")
        }
    }

    static func exportDisplays(useSystemStore: Bool) {
        do {
            let displays = try CoreGraphicsDisplayInventory().activeDisplays()
            let store = useSystemStore ? DisplayOverrideStore.systemOverrideStore : .defaultUserExportStore
            var exported = 0

            for display in displays where display.canBuildDisplayOverride {
                do {
                    let recommended = DisplayRecommendationEngine.recommendedConfiguration(for: display)
                    let result = try store.export(display: display, modes: recommended?.modesForOverride)
                    exported += 1
                    print("已为 \(display.name) 导出 \(result.modeCount) 个模式：\(result.fileURL.path)")
                    if let backupURL = result.backupURL {
                        print("  备份：\(backupURL.path)")
                    }
                } catch {
                    print("已跳过 \(display.name)：\(error.localizedDescription)")
                }
            }

            if exported == 0 {
                print("没有可导出的外接显示器。")
            }
        } catch {
            print("导出显示器配置失败：\(error.localizedDescription)")
        }
    }

    static func applyBestConfiguration() {
        do {
            let displays = try CoreGraphicsDisplayInventory().activeDisplays()
            guard let display = displays.first(where: { !$0.isBuiltin }) else {
                print("没有找到外接显示器。")
                return
            }

            guard let recommendation = DisplayRecommendationEngine.recommendedConfiguration(for: display) else {
                print("没有找到适合 \(display.name) 的推荐配置。")
                return
            }

            let controller = CoreGraphicsDisplayModeController()
            let runtimeModes = controller.availableModes(for: display)
            if let exposedMode = runtimeModes.first(where: {
                $0.logicalPoints == recommendation.primary.logicalPoints
                    && $0.backingPixels == recommendation.primary.backingPixels
            }) {
                try controller.apply(exposedMode, to: display)
                print("已应用最佳模式：\(exposedMode)")
                return
            }

            let result = try DisplayOverrideStore.defaultUserExportStore.export(
                display: display,
                modes: recommendation.modesForOverride
            )
            print("系统尚未暴露最佳模式，已导出推荐配置：\(result.fileURL.path)")
            print("请确认系统目录已安装该配置，然后重插显示器或重启 macOS。")
        } catch {
            print("应用最佳配置失败：\(error.localizedDescription)")
        }
    }

    static func resetConfiguration() {
        do {
            let displays = try CoreGraphicsDisplayInventory().activeDisplays()
            guard let display = displays.first(where: { !$0.isBuiltin }) else {
                print("没有找到外接显示器。")
                return
            }

            guard let vendorID = display.vendorID, let productID = display.productID else {
                print("这台显示器缺少必要标识，无法重置。")
                return
            }

            let systemURL = URL(fileURLWithPath: "/Library/Displays/Contents/Resources/Overrides")
                .appendingPathComponent("DisplayVendorID-\(String(vendorID, radix: 16))", isDirectory: true)
                .appendingPathComponent("DisplayProductID-\(String(productID, radix: 16))")

            let userURL = DisplayOverrideStore.defaultUserExportStore.rootDirectory
                .appendingPathComponent("DisplayVendorID-\(String(vendorID, radix: 16))", isDirectory: true)
                .appendingPathComponent("DisplayProductID-\(String(productID, radix: 16))")

            try? FileManager.default.removeItem(at: userURL)
            print("用户配置已清理：\(userURL.path)")
            print("系统配置请在 App 中点击“恢复默认”，或手动删除：\(systemURL.path)")
        } catch {
            print("重置失败：\(error.localizedDescription)")
        }
    }

    static func summary(for display: DisplayDescriptor) -> String {
        let vendor = display.vendorID.map { String($0, radix: 16) } ?? "未知"
        let product = display.productID.map { String($0, radix: 16) } ?? "未知"
        let kind = display.isBuiltin ? "内建屏" : "外接屏"
        let logical = display.logicalPoints.map { " 界面=\($0)" } ?? ""
        let hidpi = display.isCurrentlyHiDPI ? " 当前=HiDPI" : " 当前=标准"
        return "\(display.name) [\(kind)] id=\(display.displayID) 渲染=\(display.nativePixels)\(logical)\(hidpi) vendor=\(vendor) product=\(product)"
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    private var statusMenu = NSMenu()
    private var windowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "HiDPI"
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
        rebuildMenu()

        showWindow()
    }

    func rebuildMenu() {
        let strings = AppStrings.current
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: strings.menuOpen, action: #selector(showWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: strings.menuQuit, action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        statusMenu = menu
    }

    @objc private func statusItemClicked() {
        guard let event = NSApplication.shared.currentEvent else {
            return
        }

        if event.type == .rightMouseUp {
            statusItem?.menu = statusMenu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else if event.type == .leftMouseUp, event.clickCount == 2 {
            showWindow()
        }
    }

    @objc private func showWindow() {
        if windowController == nil {
            windowController = MainWindowController()
        }
        windowController?.showWindow(nil)
        windowController?.centerOnSelectedDisplay()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc func applyBestConfiguration() {
        windowController?.applyBestConfiguration()
    }

    @objc func resetConfiguration() {
        windowController?.resetConfiguration()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

@MainActor
final class MainWindowController: NSWindowController {
    private let titleField = NSTextField(labelWithString: "")
    private let subtitleField = NSTextField(labelWithString: "")
    private let displayLabel = NSTextField(labelWithString: "")
    private let displayPopup = NSPopUpButton()
    private let statusView = PaddedStatusView()
    private let detailField = NSTextField(labelWithString: "")
    private let operationField = NSTextField(labelWithString: "")
    private let languageControl = NSSegmentedControl(labels: ["中文", "EN"], trackingMode: .selectOne, target: nil, action: nil)
    private var bestButton: NSButton?
    private var resetButton: NSButton?
    private let inventory = CoreGraphicsDisplayInventory()
    private let modeController = CoreGraphicsDisplayModeController()
    private let store = DisplayOverrideStore.defaultUserExportStore
    private var displays: [DisplayDescriptor] = []
    private var runtimeModesByDisplayID: [UInt32: [RuntimeDisplayMode]] = [:]

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 390),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppStrings.current.windowTitle
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        super.init(window: window)
        buildContent()
        startObservingDisplayChanges()
        refresh()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func startObservingDisplayChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemDisplayStateChanged(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemDisplayStateChanged(_:)),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDisplayStateChanged(_:)),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func systemDisplayStateChanged(_ notification: Notification) {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(refreshAndRecenter),
            object: nil
        )
        perform(#selector(refreshAndRecenter), with: nil, afterDelay: 1)
    }

    @objc private func refreshAndRecenter() {
        refresh()
        centerOnSelectedDisplay()
    }

    func centerOnSelectedDisplay() {
        guard let window else {
            return
        }

        let targetScreen = selectedDisplay.flatMap { display in
            NSScreen.screens.first { screen in
                guard let number = screen.deviceDescription[
                    NSDeviceDescriptionKey("NSScreenNumber")
                ] as? NSNumber else {
                    return false
                }
                return number.uint32Value == display.displayID
            }
        } ?? window.screen ?? NSScreen.main

        guard let visibleFrame = targetScreen?.visibleFrame else {
            window.center()
            return
        }

        let frame = window.frame
        let origin = NSPoint(
            x: visibleFrame.midX - frame.width / 2,
            y: visibleFrame.midY - frame.height / 2
        )
        window.setFrameOrigin(origin)
    }

    private func scheduleRecenterAfterModeChange() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(refreshAndRecenter),
            object: nil
        )
        perform(#selector(refreshAndRecenter), with: nil, afterDelay: 0.5)
        perform(#selector(refreshAndRecenter), with: nil, afterDelay: 1.5)
    }

    private func buildContent() {
        guard let contentView = window?.contentView else {
            return
        }

        let backgroundView = NSVisualEffectView()
        backgroundView.material = .underWindowBackground
        backgroundView.blendingMode = .behindWindow
        backgroundView.state = .active
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundView)

        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "display", accessibilityDescription: nil)
        iconView.contentTintColor = .controlAccentColor
        iconView.symbolConfiguration = .init(pointSize: 24, weight: .medium)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let iconBackground = NSView()
        iconBackground.wantsLayer = true
        iconBackground.layer?.cornerRadius = 8
        iconBackground.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(iconView)

        titleField.font = .systemFont(ofSize: 24, weight: .semibold)
        titleField.textColor = .labelColor
        titleField.alignment = .center

        subtitleField.font = .systemFont(ofSize: 13)
        subtitleField.textColor = .secondaryLabelColor
        subtitleField.alignment = .center

        let titleStack = NSStackView(views: [titleField, subtitleField])
        titleStack.orientation = .vertical
        titleStack.alignment = .centerX
        titleStack.spacing = 3

        let headerStack = NSStackView(views: [iconBackground, titleStack])
        headerStack.orientation = .vertical
        headerStack.alignment = .centerX
        headerStack.spacing = 10

        displayLabel.font = .systemFont(ofSize: 12, weight: .medium)
        displayLabel.textColor = .secondaryLabelColor
        displayLabel.alignment = .center
        displayPopup.target = self
        displayPopup.action = #selector(displaySelectionChanged)
        displayPopup.controlSize = .large

        let bestButton = NSButton(title: "", target: self, action: #selector(applyBestConfiguration))
        bestButton.bezelStyle = .rounded
        bestButton.keyEquivalent = "\r"
        bestButton.font = .systemFont(ofSize: 16, weight: .semibold)
        bestButton.controlSize = .large
        self.bestButton = bestButton

        let resetButton = NSButton(title: "", target: self, action: #selector(resetConfiguration))
        resetButton.bezelStyle = .rounded
        resetButton.controlSize = .large
        self.resetButton = resetButton

        languageControl.target = self
        languageControl.action = #selector(languageChanged)
        languageControl.controlSize = .small
        languageControl.selectedSegment = AppLanguage.current == .chinese ? 0 : 1

        let displayStack = NSStackView(views: [displayLabel, displayPopup])
        displayStack.orientation = .vertical
        displayStack.alignment = .centerX
        displayStack.spacing = 6

        let buttonStack = NSStackView(views: [bestButton, resetButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 10
        buttonStack.distribution = .fillEqually

        detailField.font = .systemFont(ofSize: 13, weight: .regular)
        detailField.textColor = .secondaryLabelColor
        detailField.alignment = .center
        detailField.lineBreakMode = .byWordWrapping
        detailField.maximumNumberOfLines = 2

        operationField.textColor = .secondaryLabelColor
        operationField.font = .systemFont(ofSize: 12)
        operationField.alignment = .center
        operationField.lineBreakMode = .byWordWrapping
        operationField.maximumNumberOfLines = 2

        let stack = NSStackView(views: [
            headerStack,
            languageControl,
            displayStack,
            statusView,
            detailField,
            buttonStack,
            operationField
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(stack)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleField.translatesAutoresizingMaskIntoConstraints = false
        subtitleField.translatesAutoresizingMaskIntoConstraints = false
        languageControl.translatesAutoresizingMaskIntoConstraints = false
        displayPopup.translatesAutoresizingMaskIntoConstraints = false
        bestButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        statusView.translatesAutoresizingMaskIntoConstraints = false
        detailField.translatesAutoresizingMaskIntoConstraints = false
        operationField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 48),
            iconBackground.heightAnchor.constraint(equalToConstant: 48),
            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            stack.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor, constant: 6),
            stack.widthAnchor.constraint(equalToConstant: 440),
            stack.topAnchor.constraint(greaterThanOrEqualTo: backgroundView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: backgroundView.bottomAnchor, constant: -22),
            titleStack.widthAnchor.constraint(equalTo: stack.widthAnchor),
            languageControl.widthAnchor.constraint(equalToConstant: 112),
            displayPopup.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttonStack.widthAnchor.constraint(equalTo: stack.widthAnchor),
            bestButton.heightAnchor.constraint(equalToConstant: 44),
            resetButton.heightAnchor.constraint(equalToConstant: 44),
            statusView.widthAnchor.constraint(equalTo: stack.widthAnchor),
            statusView.heightAnchor.constraint(equalToConstant: 44),
            detailField.widthAnchor.constraint(equalTo: stack.widthAnchor),
            operationField.widthAnchor.constraint(equalTo: stack.widthAnchor),
            operationField.heightAnchor.constraint(greaterThanOrEqualToConstant: 34)
        ])

        applyLanguage()
    }

    @objc func refresh() {
        do {
            displays = try inventory.activeDisplays()
            runtimeModesByDisplayID = Dictionary(uniqueKeysWithValues: displays.map { display in
                (display.displayID, modeController.availableModes(for: display))
            })
            populateDisplayPopup()
            updatePanel(message: nil)
        } catch {
            operationField.stringValue = AppStrings.current.readDisplayFailed(error.localizedDescription)
        }
    }

    @objc func exportOverrides() {
        var messages: [String] = []
        let targets = selectedDisplay.map { [$0] } ?? displays

        for display in targets where display.canBuildDisplayOverride {
            do {
                    let recommended = DisplayRecommendationEngine.recommendedConfiguration(for: display)
                    let result = try store.export(display: display, modes: recommended?.modesForOverride)
                    messages.append("已为 \(display.name) 导出 \(result.modeCount) 个模式")
                messages.append("  \(result.fileURL.path)")
            } catch {
                messages.append("已跳过 \(display.name)：\(error.localizedDescription)")
            }
        }

        if messages.isEmpty {
            messages.append("没有可导出的外接显示器。")
        }

        updatePanel(message: messages.joined(separator: "  "))
    }

    @objc private func displaySelectionChanged() {
        updatePanel(message: nil)
        centerOnSelectedDisplay()
    }

    @objc private func languageChanged() {
        AppLanguage.current = languageControl.selectedSegment == 0 ? .chinese : .english
        applyLanguage()
        AppDelegate.shared?.rebuildMenu()
        updatePanel(message: nil)
    }

    private func applyLanguage() {
        let strings = AppStrings.current
        window?.title = strings.windowTitle
        titleField.stringValue = strings.windowTitle
        subtitleField.stringValue = strings.subtitle
        displayLabel.stringValue = strings.displayLabel
        bestButton?.title = strings.optimizeButton
        resetButton?.title = strings.resetButton
        languageControl.selectedSegment = AppLanguage.current == .chinese ? 0 : 1
        populateDisplayPopup(selecting: selectedDisplay?.displayID)
    }

    @objc func applyBestConfiguration() {
        let strings = AppStrings.current
        guard let display = selectedDisplay else {
            updatePanel(message: strings.chooseDisplay)
            return
        }

        guard !display.isBuiltin else {
            updatePanel(message: strings.builtinDisplayNeedsExternal)
            return
        }

        guard let recommendation = DisplayRecommendationEngine.recommendedConfiguration(for: display) else {
            updatePanel(message: strings.noRecommendation)
            return
        }

        let runtimeModes = runtimeModesByDisplayID[display.displayID] ?? []
        if let exposedMode = runtimeModes.first(where: {
            $0.logicalPoints == recommendation.primary.logicalPoints
                && $0.backingPixels == recommendation.primary.backingPixels
        }) {
            do {
                try modeController.apply(exposedMode, to: display)
                refresh()
                updatePanel(message: strings.appliedMode(exposedMode.description))
                scheduleRecenterAfterModeChange()
            } catch {
                updatePanel(message: strings.applyFailed(error.localizedDescription))
            }
            return
        }

        do {
            let result = try store.export(display: display, modes: recommendation.modesForOverride)
            do {
                try installOverrideWithAdministratorPrivileges(from: result.fileURL, payload: display)
                updatePanel(message: strings.installedConfig)
            } catch {
                updatePanel(message: strings.generatedButInstallFailed(error.localizedDescription, result.fileURL.path))
            }
        } catch {
            updatePanel(message: strings.generateFailed(error.localizedDescription))
        }
    }

    @objc func resetConfiguration() {
        let strings = AppStrings.current
        guard let display = selectedDisplay else {
            updatePanel(message: strings.chooseDisplay)
            return
        }

        guard !display.isBuiltin else {
            updatePanel(message: strings.builtinDisplayNoReset)
            return
        }

        do {
            try removeUserOverride(for: display)
            try removeSystemOverrideWithAdministratorPrivileges(for: display)
            updatePanel(message: strings.resetDone)
        } catch {
            updatePanel(message: strings.resetFailed(error.localizedDescription))
        }
    }

    @objc private func revealExportFolder() {
        try? FileManager.default.createDirectory(at: store.rootDirectory, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([store.rootDirectory])
    }

    private var selectedDisplay: DisplayDescriptor? {
        let index = displayPopup.indexOfSelectedItem
        guard displays.indices.contains(index) else {
            return nil
        }
        return displays[index]
    }

    private func populateDisplayPopup(selecting displayID: UInt32? = nil) {
        let selectedID = displayID ?? selectedDisplay?.displayID
        displayPopup.removeAllItems()

        for display in displays {
            displayPopup.addItem(withTitle: displayMenuTitle(for: display))
        }

        if let selectedID, let index = displays.firstIndex(where: { $0.displayID == selectedID }) {
            displayPopup.selectItem(at: index)
        } else if !displays.isEmpty {
            displayPopup.selectItem(at: 0)
        }
    }

    private func updateStatus() {
        guard let display = selectedDisplay else {
            statusView.configure(text: AppStrings.current.noDisplay, style: .warning)
            detailField.stringValue = ""
            return
        }

        let strings = AppStrings.current
        let isOptimal = DisplayRecommendationEngine.isRecommendedModeActive(for: display)
        if isOptimal {
            statusView.configure(text: strings.clearMode, style: .success)
        } else if display.isCurrentlyHiDPI {
            statusView.configure(text: strings.otherHiDPIMode, style: .warning)
        } else {
            statusView.configure(text: strings.blurryMode, style: .warning)
        }

        let current = display.logicalPoints.map { "\($0)" } ?? "\(display.nativePixels)"
        let target: String
        if let recommendation = DisplayRecommendationEngine.recommendedConfiguration(for: display) {
            target = strings.modeDescription(recommendation.primary)
        } else {
            target = "1920x1080 HiDPI"
        }
        detailField.stringValue = strings.detail(current: current, target: target)
    }

    private func updatePanel(message: String?) {
        let strings = AppStrings.current
        updateStatus()
        if let message {
            operationField.stringValue = message
        } else if let display = selectedDisplay,
                  DisplayRecommendationEngine.isRecommendedModeActive(for: display) {
            operationField.stringValue = strings.alreadyClearPrompt
        } else if selectedDisplay?.isCurrentlyHiDPI == true {
            operationField.stringValue = strings.otherHiDPIPrompt
        } else {
            operationField.stringValue = strings.notHiDPIPrompt
        }
    }

    private func displayMenuTitle(for display: DisplayDescriptor) -> String {
        let strings = AppStrings.current
        let kind = strings.displayKind(isBuiltin: display.isBuiltin)
        let state = strings.displayState(
            isOptimal: DisplayRecommendationEngine.isRecommendedModeActive(for: display),
            isHiDPI: display.isCurrentlyHiDPI
        )
        return "\(display.name) · \(kind) · \(state)"
    }

    private func installOverrideWithAdministratorPrivileges(from sourceURL: URL, payload display: DisplayDescriptor) throws {
        guard let vendorID = display.vendorID, let productID = display.productID else {
            throw DisplayOverrideStoreError.missingVendorOrProductID
        }

        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("LeeHiDPI-DisplayProductID-\(String(productID, radix: 16))")
        if FileManager.default.fileExists(atPath: temporaryURL.path) {
            try FileManager.default.removeItem(at: temporaryURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: temporaryURL)

        let vendorDirectory = "/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-\(String(vendorID, radix: 16))"
        let productFile = "\(vendorDirectory)/DisplayProductID-\(String(productID, radix: 16))"
        let command = "mkdir -p \(shellQuote(vendorDirectory)) && cp \(shellQuote(temporaryURL.path)) \(shellQuote(productFile)) && chmod 644 \(shellQuote(productFile))"
        let script = "do shell script \(appleScriptQuote(command)) with administrator privileges"

        var error: NSDictionary?
        if NSAppleScript(source: script)?.executeAndReturnError(&error) == nil {
            let message = error?[NSAppleScript.errorMessage] as? String ?? "管理员安装失败"
            throw NSError(domain: "LeeHiDPI", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private func removeUserOverride(for display: DisplayDescriptor) throws {
        guard let vendorID = display.vendorID, let productID = display.productID else {
            throw DisplayOverrideStoreError.missingVendorOrProductID
        }

        let fileURL = store.rootDirectory
            .appendingPathComponent("DisplayVendorID-\(String(vendorID, radix: 16))", isDirectory: true)
            .appendingPathComponent("DisplayProductID-\(String(productID, radix: 16))")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func removeSystemOverrideWithAdministratorPrivileges(for display: DisplayDescriptor) throws {
        guard let vendorID = display.vendorID, let productID = display.productID else {
            throw DisplayOverrideStoreError.missingVendorOrProductID
        }

        let vendorDirectory = "/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-\(String(vendorID, radix: 16))"
        let productFile = "\(vendorDirectory)/DisplayProductID-\(String(productID, radix: 16))"
        let command = "rm -f \(shellQuote(productFile)) && rmdir \(shellQuote(vendorDirectory)) 2>/dev/null || true"
        let script = "do shell script \(appleScriptQuote(command)) with administrator privileges"

        var error: NSDictionary?
        if NSAppleScript(source: script)?.executeAndReturnError(&error) == nil {
            let message = error?[NSAppleScript.errorMessage] as? String ?? "管理员重置失败"
            throw NSError(domain: "LeeHiDPI", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func appleScriptQuote(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

}

@MainActor
private final class PaddedStatusView: NSView {
    enum Style {
        case success
        case warning

        var tint: NSColor {
            switch self {
            case .success:
                .systemGreen
            case .warning:
                .systemOrange
            }
        }

        var symbolName: String {
            switch self {
            case .success:
                "checkmark.circle.fill"
            case .warning:
                "exclamationmark.triangle.fill"
            }
        }
    }

    private let imageView = NSImageView()
    private let textField = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        build()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        build()
    }

    func configure(text: String, style: Style) {
        imageView.image = NSImage(systemSymbolName: style.symbolName, accessibilityDescription: nil)
        imageView.contentTintColor = style.tint
        textField.stringValue = text
        textField.textColor = style.tint
        layer?.backgroundColor = style.tint.withAlphaComponent(0.12).cgColor
    }

    private func build() {
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = true

        imageView.symbolConfiguration = .init(pointSize: 15, weight: .semibold)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        textField.font = .systemFont(ofSize: 15, weight: .semibold)
        textField.lineBreakMode = .byTruncatingTail
        textField.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        addSubview(textField)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 18),
            imageView.heightAnchor.constraint(equalToConstant: 18),
            textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
