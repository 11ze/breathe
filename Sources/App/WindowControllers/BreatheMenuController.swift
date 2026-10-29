import AppKit
import Combine
import SwiftUI

/// 菜单面板窗口：无边框、无标题栏，成为 key window 以接收快捷键。
final class BreatheMenuPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// 菜单面板的 hosting view，保证应用未激活时第一次点击也能命中行按钮。
private final class MenuHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// 状态栏菜单控制器。用自定义面板替代 NSMenu，视觉与设计稿一致。
@MainActor
final class BreatheMenuController: NSObject, NSWindowDelegate {
    static let shared = BreatheMenuController()

    private let model = BreatheMenuModel()
    private var panel: BreatheMenuPanel?
    private var anchorTop: CGFloat = 0
    private var lastHide = Date.distantPast
    private var cancellables = Set<AnyCancellable>()
    private var keyMonitor: Any?

    private override init() {
        super.init()
        buildPanel()
        observeSizeChanges()
        installKeyMonitor()
    }

    // MARK: - 显示与关闭

    func toggle(from button: NSStatusBarButton) {
        if panel?.isVisible == true {
            hide()
            return
        }
        guard Date().timeIntervalSince(lastHide) > 0.15 else { return }
        show(from: button)
    }

    func show(from button: NSStatusBarButton) {
        guard let panel = panel else { return }
        model.presetExpanded = false
        position(under: button)
        resizeToFit()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        AppDelegate.shared?.statusItem?.button?.highlight(true)
    }

    func hide() {
        guard panel?.isVisible == true else { return }
        lastHide = Date()
        model.presetExpanded = false
        panel?.orderOut(nil)
        AppDelegate.shared?.statusItem?.button?.highlight(false)
    }

    // MARK: - 面板

    private func buildPanel() {
        let panel = BreatheMenuPanel(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 263),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.appearance = NSAppearance(named: .aqua)
        panel.isMovable = false
        panel.animationBehavior = .none
        panel.delegate = self
        panel.contentView = MenuHostingView(
            rootView: BreatheMenuView(model: model) { [weak self] action in
                self?.perform(action)
            }
        )
        self.panel = panel
    }

    private func position(under button: NSStatusBarButton) {
        guard let panel = panel, let buttonWindow = button.window else { return }
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let screen = buttonWindow.screen ?? NSScreen.main
        let visible = screen?.visibleFrame ?? .zero
        let width: CGFloat = 260
        let x = min(
            max(visible.minX + 6, buttonRect.maxX - width),
            visible.maxX - width - 6
        )
        if buttonRect.width <= 0 || buttonRect.height <= 0 {
            anchorTop = visible.maxY - 6
            panel.setFrame(
                NSRect(x: visible.maxX - width - 6, y: anchorTop - panel.frame.height, width: width, height: panel.frame.height),
                display: false
            )
            return
        }
        anchorTop = buttonRect.minY - 5
        panel.setFrame(
            NSRect(x: x, y: anchorTop - panel.frame.height, width: width, height: panel.frame.height),
            display: false
        )
    }

    private func observeSizeChanges() {
        model.$presetExpanded
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self, self.panel?.isVisible == true else { return }
                    self.resizeToFit()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .sink { [weak self] _ in
                self?.hide()
            }
            .store(in: &cancellables)

        BreathingEngine.shared.$isSessionActive
            .dropFirst()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self, self.panel?.isVisible == true else { return }
                    self.resizeToFit()
                }
            }
            .store(in: &cancellables)
    }

    private func resizeToFit() {
        guard let panel = panel, let hosting = panel.contentView else { return }
        hosting.layoutSubtreeIfNeeded()
        let height = max(1, ceil(hosting.fittingSize.height))
        let frame = NSRect(
            x: panel.frame.minX,
            y: anchorTop - height,
            width: 260,
            height: height
        )
        panel.setFrame(frame, display: true)
    }

    // MARK: - 事件

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    private func installKeyMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return event }
            if !panel.frame.contains(NSEvent.mouseLocation) {
                self.hide()
            }
            return event
        }
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let panel = self.panel, panel.isVisible else { return }
                if !panel.frame.contains(NSEvent.mouseLocation) {
                    self.hide()
                }
            }
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.panel?.isVisible == true else { return event }
            switch event.keyCode {
            case 53: // esc
                self.hide()
                return nil
            case 49: // space
                if BreathingEngine.shared.isSessionActive,
                   event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
                    AppDelegate.shared?.togglePause()
                    return nil
                }
            default:
                break
            }
            if event.charactersIgnoringModifiers?.lowercased() == "s",
               event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
                AppDelegate.shared?.toggleMute()
                return nil
            }
            return event
        }
    }

    // MARK: - 命令

    private func perform(_ action: BreatheMenuAction) {
        switch action {
        case .toggleBreathing:
            hide()
            AppDelegate.shared?.toggleBreathing()
        case .togglePause:
            AppDelegate.shared?.togglePause()
        case .selectPreset(let value):
            if value == "custom" {
                hide()
            }
            AppDelegate.shared?.selectPreset(value)
            if value != "custom", panel?.isVisible == true {
                DispatchQueue.main.async { [weak self] in
                    self?.resizeToFit()
                }
            }
        case .toggleMute:
            AppDelegate.shared?.toggleMute()
        case .openHistory:
            hide()
            AppDelegate.shared?.openHistory()
        case .openSettings:
            hide()
            AppDelegate.shared?.openSettings()
        case .quit:
            hide()
            AppDelegate.shared?.quitApp()
        }
    }
}
