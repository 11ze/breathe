import AppKit
import SwiftUI

/// 自定义 Panel（无标题栏，可成为 key window）
final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// 呼吸球窗口控制器
/// 桌面浮动呼吸球，会话期间始终可见，空闲时隐藏
@MainActor
final class BreathingPanelWindowController: NSWindowController {
    static let shared = BreathingPanelWindowController()

    private var hostingController: NSHostingController<BreathingPanelView>?

    private init() {
        let contentView = BreathingPanelView()
        let hostingCtrl = NSHostingController(rootView: contentView)
        hostingController = hostingCtrl

        let panel = KeyPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 260),
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 显示/隐藏

    func show() {
        if let window = window, !window.isVisible {
            positionDefault()
        }
        window?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    // MARK: - 定位

    /// 首次显示时放到屏幕中央
    private func positionDefault() {
        guard let window = window,
              let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - window.frame.width / 2
        let y = screenFrame.midY - window.frame.height / 2
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
