import AppKit
import SwiftUI

/// 自定义 Panel（无标题栏，可成为 key window）
final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// 呼吸面板窗口控制器
/// 复用 menu-bar-executor 的 CommandPaletteWindowController 模式
/// 关键区别：会话期间不自动关闭（用户需要一边做其他事一边看呼吸引导）
@MainActor
final class BreathingPanelWindowController: NSWindowController {
    static let shared = BreathingPanelWindowController()

    private var eventMonitor: Any?
    private var hostingController: NSHostingController<BreathingPanelView>?

    private init() {
        let contentView = BreathingPanelView()
        let hostingCtrl = NSHostingController(rootView: contentView)
        hostingController = hostingCtrl

        let panel = KeyPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 460),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = hostingCtrl

        super.init(window: panel)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: panel
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 显示/隐藏

    func toggle() {
        if let window = window, window.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let appDelegate = AppDelegate.shared,
              let button = appDelegate.statusItem?.button else {
            return
        }
        positionNearStatusBarButton(button)
        window?.makeKeyAndOrderFront(nil)
        setupEventMonitor()
    }

    func hide() {
        removeEventMonitor()
        window?.orderOut(nil)
    }

    // MARK: - 定位

    private func positionNearStatusBarButton(_ button: NSStatusBarButton) {
        guard let window = window else { return }
        let buttonFrame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
        let panelWidth = window.frame.width
        let x = buttonFrame.origin.x + (buttonFrame.width - panelWidth) / 2
        let y = buttonFrame.origin.y - window.frame.height - 5
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    // MARK: - 事件监听

    private func setupEventMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let window = self.window, window.isKeyWindow else { return event }

            // Escape 关闭面板（仅空闲状态）
            if event.keyCode == 53 {
                self.hide()
                return nil
            }

            return event
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    @objc private func windowDidResignKey(_ notification: Notification) {
        // 空闲状态下点击面板外部可关闭
        // 会话期间不自动关闭（与 menu-bar-executor 的关键区别）
        guard let engine = BreathingEngine.shared as BreathingEngine?,
              !engine.isSessionActive else { return }
        hide()
    }
}
