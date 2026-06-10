import AppKit
import Combine
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    var statusItem: NSStatusItem?

    // 菜单项引用（需要动态更新标题）
    private var startMenuItem: NSMenuItem?
    private var pauseMenuItem: NSMenuItem?
    private var muteMenuItem: NSMenuItem?
    private var presetSubmenu: NSMenu?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let icon = makeStatusBarIcon(isActive: false) {
                button.image = icon
            } else {
                button.title = "◎"
            }
            button.toolTip = "Breathe"
        }

        buildMenu()

        // 同步自启动状态
        LaunchAtLoginManager.shared.sync(withSettings: AppSettingsManager.shared.settings.launchAtLogin)

        // 配置引擎回调
        setupEngineCallbacks()

        // 配置音频和通知
        setupAudioAndNotifications()

        // 配置每日提醒
        scheduleDailyReminderIfNeeded()
    }

    // MARK: - 菜单构建

    private func buildMenu() {
        guard let button = statusItem?.button else { return }

        let menu = NSMenu()
        menu.delegate = self

        // 开始/停止呼吸
        let startItem = NSMenuItem(
            title: "开始呼吸",
            action: #selector(toggleBreathing),
            keyEquivalent: "b"
        )
        startItem.target = self
        startMenuItem = startItem
        menu.addItem(startItem)

        // 暂停/继续（会话中显示）
        let pauseItem = NSMenuItem(title: "暂停", action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        pauseMenuItem = pauseItem
        menu.addItem(pauseItem)

        menu.addItem(NSMenuItem.separator())

        // 预设子菜单
        let presetItem = NSMenuItem(title: "预设", action: nil, keyEquivalent: "")
        let presetMenu = NSMenu()

        presetMenu.addItem(NSMenuItem(title: "自动 (按时段)", action: #selector(selectPresetAuto), keyEquivalent: ""))
        presetMenu.addItem(NSMenuItem.separator())
        for preset in Preset.allCases {
            let item = NSMenuItem(
                title: "\(preset.displayName) (\(preset.ratioString), \(preset.durationMinutes)分钟)",
                action: #selector(selectPreset(_:)),
                keyEquivalent: ""
            )
            item.representedObject = preset.rawValue
            presetMenu.addItem(item)
        }
        presetMenu.addItem(NSMenuItem.separator())
        presetMenu.addItem(NSMenuItem(title: "自定义...", action: #selector(selectPresetCustom), keyEquivalent: ""))

        presetSubmenu = presetMenu
        presetItem.submenu = presetMenu
        menu.addItem(presetItem)

        menu.addItem(NSMenuItem.separator())

        // 静音
        let muteItem = NSMenuItem(
            title: "静音",
            action: #selector(toggleMute),
            keyEquivalent: "s"
        )
        muteItem.target = self
        muteMenuItem = muteItem
        menu.addItem(muteItem)

        menu.addItem(NSMenuItem.separator())

        // 历史记录
        let historyItem = NSMenuItem(
            title: "历史记录",
            action: #selector(openHistory),
            keyEquivalent: "h"
        )
        historyItem.target = self
        historyItem.keyEquivalentModifierMask = [.command]
        menu.addItem(historyItem)

        // 设置
        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 退出
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        button.menu = menu
        button.action = #selector(statusBarButtonClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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

        engine.onSessionComplete = { [weak self] record in
            // 隐藏呼吸球
            BreathingPanelWindowController.shared.hide()

            // 发送通知
            NotificationManager.shared.showSessionComplete(
                breaths: record.breaths,
                duration: record.durationActualSeconds
            )

            // 记录日志
            if AppSettingsManager.shared.settings.logSessions {
                SessionLogger.shared.log(record)
            }
        }
    }

    private func setupAudioAndNotifications() {
        let settings = AppSettingsManager.shared.settings
        AudioManager.shared.setMuted(!settings.soundEnabled)
    }

    private func scheduleDailyReminderIfNeeded() {
        let settings = AppSettingsManager.shared.settings
        if settings.dailyReminderEnabled {
            NotificationManager.shared.scheduleDailyReminder(at: settings.dailyReminderTime)
        }
    }

    // MARK: - 菜单动作

    @objc private func toggleBreathing() {
        let engine = BreathingEngine.shared
        if engine.isSessionActive {
            engine.stop()
        } else {
            engine.start(config: BreathingConfig.fromCurrentSettings())
            BreathingPanelWindowController.shared.show()
        }
    }

    // MARK: - 状态栏点击

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let menu = sender.menu else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 5), in: sender)
    }

    @objc private func toggleMute() {
        AudioManager.shared.toggleMute()
    }

    @objc private func togglePause() {
        BreathingEngine.shared.togglePause()
    }

    @objc private func selectPresetAuto() {
        AppSettingsManager.shared.settings.defaultPreset = "auto"
        AppSettingsManager.shared.save()
    }

    @objc private func selectPreset(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String else { return }
        AppSettingsManager.shared.settings.defaultPreset = rawValue
        AppSettingsManager.shared.save()
    }

    @objc private func selectPresetCustom() {
        AppSettingsManager.shared.settings.defaultPreset = "custom"
        AppSettingsManager.shared.save()
        SettingsWindowController.shared.showWindow()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showWindow()
    }

    @objc private func openHistory() {
        HistoryWindowController.shared.showWindow()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - 辅助

    /// 更新状态栏图标和剩余时长标题
    private func updateStatusBarContent(isActive: Bool, remaining: Int) {
        guard let button = statusItem?.button else { return }
        button.image = makeStatusBarIcon(isActive: isActive)
        button.title = isActive ? " \(formatTime(remaining))" : ""
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    /// 创建菜单栏图标（回退链：自定义资源 → SF Symbol）
    private func makeStatusBarIcon(isActive: Bool) -> NSImage? {
        if isActive {
            guard let sfImage = NSImage(systemSymbolName: "wind", accessibilityDescription: "Breathe Active") else { return nil }
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
            guard let configured = sfImage.withSymbolConfiguration(config) else { return nil }
            return tint(image: configured, with: .systemCyan)
        } else {
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = true
                return image
            }
            guard let sfImage = NSImage(systemSymbolName: "wind", accessibilityDescription: "Breathe") else { return nil }
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            sfImage.isTemplate = true
            return sfImage.withSymbolConfiguration(config)
        }
    }

    /// 用 sourceAtop 合成模式将 template 图像着色
    private func tint(image: NSImage, with color: NSColor) -> NSImage {
        let tinted = NSImage(size: image.size)
        tinted.lockFocus()
        let rect = NSRect(origin: .zero, size: image.size)
        image.draw(in: rect)
        color.withAlphaComponent(0.9).setFill()
        rect.fill(using: .sourceAtop)
        tinted.unlockFocus()
        return tinted
    }
}

// MARK: - NSMenuDelegate（动态更新菜单项标题）

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let engine = BreathingEngine.shared
        let isSessionActive = engine.isSessionActive

        // 暂停项：会话中显示，空闲时隐藏
        pauseMenuItem?.isHidden = !isSessionActive

        if isSessionActive {
            pauseMenuItem?.title = engine.isPaused ? "继续" : "暂停"
            startMenuItem?.title = "停止呼吸"
        } else {
            startMenuItem?.title = "开始呼吸"
        }

        let isMuted = AudioManager.shared.isMuted
        muteMenuItem?.title = isMuted ? "取消静音" : "静音"
        muteMenuItem?.state = isMuted ? .on : .off
    }
}
