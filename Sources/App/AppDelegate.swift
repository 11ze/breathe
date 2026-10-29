import AppKit
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    var statusItem: NSStatusItem?

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = BreatheStatusIcon.make()
            button.imagePosition = .imageLeading
            button.title = ""
            button.toolTip = "Breathe"
            button.setAccessibilityLabel("Breathe")
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        installMainMenu()
        BreatheTrafficLightMonitor.install()

        // 同步自启动状态
        LaunchAtLoginManager.shared.sync(withSettings: AppSettingsManager.shared.settings.launchAtLogin)

        // 配置引擎回调
        setupEngineCallbacks()

        // 初始化音频订阅（声音状态跟随配置）
        _ = AudioManager.shared

        // 清理已删除的每日提醒功能遗留的系统通知
        NotificationManager.shared.removeLegacyDailyReminder()
    }

    // MARK: - 快捷键

    /// LSUIElement 应用不显示主菜单，仅保留快捷键分发。
    private func installMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem(title: "Breathe", action: nil, keyEquivalent: "")
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu(title: "Breathe")
        appMenuItem.submenu = appMenu

        let startItem = NSMenuItem(
            title: "开始呼吸",
            action: #selector(toggleBreathing),
            keyEquivalent: "b"
        )
        startItem.target = self
        appMenu.addItem(startItem)

        appMenu.addItem(.separator())

        let historyItem = NSMenuItem(
            title: "历史记录",
            action: #selector(openHistory),
            keyEquivalent: "h"
        )
        historyItem.target = self
        appMenu.addItem(historyItem)

        let settingsItem = NSMenuItem(
            title: "设置…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        appMenu.addItem(settingsItem)

        appMenu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 Breathe",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        appMenu.addItem(quitItem)

        NSApp.mainMenu = mainMenu
    }

    // MARK: - 引擎回调

    private func setupEngineCallbacks() {
        let engine = BreathingEngine.shared

        // 监听会话状态 + 剩余时间，更新状态栏图标和标题
        Publishers.CombineLatest(engine.$isSessionActive, engine.$remainingSeconds)
            .sink { [weak self] isActive, remaining in
                self?.updateStatusBarContent(isActive: isActive, remaining: remaining)
            }
            .store(in: &cancellables)

        engine.onInhaleStart = {
            AudioManager.shared.playInhale()
        }

        engine.onExhaleStart = {
            AudioManager.shared.playExhale()
        }

        engine.onSessionComplete = { record in
            // 隐藏呼吸球
            BreathingPanelWindowController.shared.hide()

            // 发送通知
            NotificationManager.shared.showSessionComplete(record: record)

            // 记录日志
            if AppSettingsManager.shared.settings.logSessions {
                SessionLogger.shared.log(record)
            }
        }
    }

    // MARK: - 菜单动作

    @objc func toggleBreathing() {
        BreatheMenuController.shared.hide()
        let engine = BreathingEngine.shared
        if engine.isSessionActive {
            engine.stop()
        } else {
            let settings = AppSettingsManager.shared.settings
            if settings.defaultPreset == "custom",
               BreathingConfig(
                   inhale: settings.customInhaleSeconds,
                   exhale: settings.customExhaleSeconds,
                   durationMinutes: settings.customDurationMinutes
               ) == nil {
                NSSound.beep()
                return
            }
            engine.start(config: BreathingConfig.fromCurrentSettings())
            BreathingPanelWindowController.shared.show()
        }
    }

    @objc func togglePause() {
        BreathingEngine.shared.togglePause()
    }

    @objc func toggleMute() {
        AudioManager.shared.toggleMute()
    }

    @objc func selectPreset(_ value: String) {
        AppSettingsManager.shared.settings.defaultPreset = value
        AppSettingsManager.shared.save()
        if value == "custom" {
            SettingsWindowController.shared.showWindow(tab: .preset)
        }
    }

    @objc func openSettings() {
        SettingsWindowController.shared.showWindow()
    }

    @objc func openHistory() {
        HistoryWindowController.shared.showWindow()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - 状态栏

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        BreatheMenuController.shared.toggle(from: sender)
    }

    /// 更新状态栏图标和剩余时长标题
    private func updateStatusBarContent(isActive: Bool, remaining: Int) {
        guard let button = statusItem?.button else { return }
        guard isActive else {
            button.attributedTitle = NSAttributedString(string: "")
            return
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor(srgbRed: 0.149, green: 0.451, blue: 0.310, alpha: 1)
        ]
        button.attributedTitle = NSAttributedString(
            string: " " + formatTime(remaining),
            attributes: attributes
        )
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
