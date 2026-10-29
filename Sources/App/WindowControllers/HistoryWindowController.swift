import AppKit
import SwiftUI

@MainActor
final class HistoryWindowController: NSObject {
    static let shared = HistoryWindowController()

    private var window: NSWindow?

    private override init() {
        super.init()
    }

    func showWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = HistoryView()
        let hostingView = BreatheHostingView(rootView: contentView)

        let newWindow = BreatheWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 560),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "历史记录"
        newWindow.contentMinSize = NSSize(width: 860, height: 540)
        newWindow.contentView = hostingView
        newWindow.setContentSize(NSSize(width: 860, height: 560))
        newWindow.isReleasedWhenClosed = false
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = true
        newWindow.appearance = NSAppearance(named: .aqua)
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.titlebarSeparatorStyle = .none
        newWindow.standardWindowButton(.closeButton)?.isHidden = true
        newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newWindow.standardWindowButton(.zoomButton)?.isHidden = true
        newWindow.center()
        window = newWindow

        newWindow.makeKeyAndOrderFront(nil)
        newWindow.setContentSize(NSSize(width: 860, height: 560))
        NSApp.activate(ignoringOtherApps: true)
    }
}
