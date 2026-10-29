import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private let navigation = SettingsNavigation()

    private init() {
        let contentView = SettingsView(navigation: navigation)
        let window = BreatheWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 640),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "设置"
        window.contentMinSize = NSSize(width: 540, height: 560)
        window.contentView = BreatheHostingView(rootView: contentView)
        window.setContentSize(NSSize(width: 540, height: 640))
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.appearance = NSAppearance(named: .aqua)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWindow(tab: SettingsTab? = nil) {
        if let tab = tab {
            navigation.tab = tab
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
