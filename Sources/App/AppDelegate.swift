import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
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
    }

    private func buildMenu() {
        guard let button = statusItem?.button else { return }

        let menu = NSMenu()

        let startItem = NSMenuItem(
            title: "开始呼吸",
            action: #selector(toggleBreathing),
            keyEquivalent: "b"
        )
        startItem.target = self
        menu.addItem(startItem)

        menu.addItem(NSMenuItem.separator())

        let muteItem = NSMenuItem(
            title: "静音",
            action: #selector(toggleMute),
            keyEquivalent: "s"
        )
        muteItem.target = self
        menu.addItem(muteItem)

        let historyItem = NSMenuItem(
            title: "历史记录",
            action: #selector(openHistory),
            keyEquivalent: "h"
        )
        historyItem.target = self
        historyItem.keyEquivalentModifierMask = [.command]
        menu.addItem(historyItem)

        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

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

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .leftMouseUp {
            // TODO: Phase 6 - toggle breathing panel
        } else if event.type == .rightMouseUp {
            guard let menu = sender.menu else { return }
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 5), in: sender)
        }
    }

    @objc private func toggleBreathing() {
        // TODO: Phase 6 - start/stop breathing session
    }

    @objc private func toggleMute() {
        // TODO: Phase 3 - toggle mute via AudioManager
    }

    @objc private func openSettings() {
        // TODO: Phase 6 - SettingsWindowController.shared.showWindow()
    }

    @objc private func openHistory() {
        // TODO: Phase 6 - HistoryWindowController.shared.showWindow()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
