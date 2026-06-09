import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?
    var statusItem: NSStatusItem?

    // 菜单项引用（需要动态更新标题）
    private var statusLineItem: NSMenuItem?      // "吸气 · 4s"
    private var infoLineItem: NSMenuItem?        // "已完成 3 次 · 剩余 2:35"
    private var startMenuItem: NSMenuItem?
    private var pauseMenuItem: NSMenuItem?
    private var muteMenuItem: NSMenuItem?
    private var presetSubmenu: NSMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = true
                button.image = image
            } else if let sfImage = NSImage(systemSymbolName: "wind", accessibilityDescription: "Breathe") {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
                sfImage.isTemplate = true
                button.image = sfImage.withSymbolConfiguration(config)
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

        // 状态行：阶段 + 秒数（会话中显示）
        let statusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        statusLineItem = statusItem
        menu.addItem(statusItem)

        // 状态行：呼吸次数 + 剩余时间（会话中显示）
        let infoItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        infoItem.isEnabled = false
        infoLineItem = infoItem
        menu.addItem(infoItem)

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
            presetMenu.addItem(NSMenuItem(
                title: "\(preset.displayName) (\(preset.ratioString), \(preset.durationMinutes)分钟)",
                action: #selector(selectPreset(_:)),
                keyEquivalent: ""
            ))
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

        engine.onSessionStart = { [weak self] in
            self?.updateStatusBarIcon(isActive: true)
        }

        engine.onInhaleStart = {
            AudioManager.shared.playInhale()
        }

        engine.onExhaleStart = {
            AudioManager.shared.playExhale()
        }

        engine.onSessionComplete = { [weak self] record in
            // 恢复图标
            self?.updateStatusBarIcon(isActive: false)

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
        let presets: [Preset] = [.balanced, .calm, .extended]
        let index = presetSubmenu?.items.firstIndex(of: sender)
        // 跳过第一项（自动）和分隔符
        if let idx = index, idx >= 2 && idx <= 4 {
            let preset = presets[idx - 2]
            AppSettingsManager.shared.settings.defaultPreset = preset.rawValue
            AppSettingsManager.shared.save()
        }
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

    private func updateStatusBarIcon(isActive: Bool) {
        guard let button = statusItem?.button else { return }

        if isActive {
            // 手动着色 SF Symbol — contentTintColor 对菜单栏图标无效
            if let sfImage = NSImage(systemSymbolName: "wind", accessibilityDescription: "Breathe Active") {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .bold)
                if let configured = sfImage.withSymbolConfiguration(config) {
                    button.image = tint(image: configured, with: .systemCyan)
                }
            }
        } else {
            // 恢复原始 template 图标
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = true
                button.image = image
            } else if let sfImage = NSImage(systemSymbolName: "wind", accessibilityDescription: "Breathe") {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
                sfImage.isTemplate = true
                button.image = sfImage.withSymbolConfiguration(config)
            }
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

    private func refreshPanel() {
        // 面板视图通过 @ObservedObject 自动刷新
    }
}

// MARK: - NSMenuDelegate（动态更新菜单项标题）

extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        let engine = BreathingEngine.shared
        let isSessionActive = engine.isSessionActive

        // 状态行：会话中显示，空闲时隐藏
        statusLineItem?.isHidden = !isSessionActive
        infoLineItem?.isHidden = !isSessionActive
        pauseMenuItem?.isHidden = !isSessionActive

        if isSessionActive {
            statusLineItem?.title = statusText(for: engine.phase, seconds: engine.currentPhaseSecondsRemaining)
            infoLineItem?.title = "已完成 \(engine.breathsCompleted) 次呼吸 · 剩余 \(formatTime(engine.remainingSeconds))"
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

// MARK: - 菜单辅助方法

extension AppDelegate {
    private func statusText(for phase: BreathingPhase, seconds: Int) -> String {
        switch phase {
        case .countdown: return "准备 · \(seconds)"
        case .inhale:    return "吸气 · \(seconds)s"
        case .exhale:    return "呼气 · \(seconds)s"
        case .paused:    return "‖ 已暂停"
        default:         return ""
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
