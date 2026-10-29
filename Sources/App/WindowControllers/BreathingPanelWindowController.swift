import AppKit
import SwiftUI

/// 自定义 Panel（无标题栏，可成为 key window）
final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// 允许按住拖动窗口的 HostingView
/// 新版 macOS 上 NSHostingView 面板的背景拖动判定失效，
/// mouseDown 直接转为窗口拖动，绕开系统判定
final class DraggableHostingView: NSHostingView<BreathingPanelView> {
    /// 窗口非 key 时首次按下默认只用于激活窗口、不派发事件；
    /// 返回 true 让焦点在别的窗口时第一次按下就直接开始拖拽
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

/// 呼吸球窗口控制器
/// 桌面浮动呼吸球，会话期间始终可见，空闲时隐藏
@MainActor
final class BreathingPanelWindowController: NSWindowController {
    static let shared = BreathingPanelWindowController()

    private init() {
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
        panel.hasShadow = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = DraggableHostingView(rootView: BreathingPanelView())

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
