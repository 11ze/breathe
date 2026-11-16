import AppKit
import XCTest
@testable import Breathe

final class AppDelegateMenuTests: XCTestCase {
    @MainActor
    func testMainMenuHasCommandWCloseItem() throws {
        let previousMenu = NSApp.mainMenu
        defer { NSApp.mainMenu = previousMenu }

        let delegate = AppDelegate()
        delegate.installMainMenu()

        let appMenu = try XCTUnwrap(NSApp.mainMenu?.items.first?.submenu)
        let closeItem = try XCTUnwrap(
            appMenu.items.first { $0.keyEquivalent.lowercased() == "w" },
            "主菜单缺少 ⌘W 关闭项"
        )

        XCTAssertEqual(closeItem.action, #selector(NSWindow.performClose(_:)))
        XCTAssertNil(closeItem.target, "关闭动作应交给当前 key window")
        XCTAssertEqual(closeItem.keyEquivalentModifierMask, .command)
    }

    @MainActor
    func testCommandWClosesSettingsWindow() throws {
        let previousMenu = NSApp.mainMenu
        defer { NSApp.mainMenu = previousMenu }

        let delegate = AppDelegate()
        delegate.installMainMenu()

        SettingsWindowController.shared.showWindow()
        let window = try XCTUnwrap(SettingsWindowController.shared.window)
        defer { window.orderOut(nil) }

        XCTAssertTrue(window.isVisible)

        let appMenu = try XCTUnwrap(NSApp.mainMenu?.items.first?.submenu)
        let closeItem = try XCTUnwrap(appMenu.items.first { $0.keyEquivalent == "w" })
        closeItem.target = window
        defer { closeItem.target = nil }

        let event = try XCTUnwrap(NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: .command,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber,
            context: nil,
            characters: "w",
            charactersIgnoringModifiers: "w",
            isARepeat: false,
            keyCode: 13
        ))
        XCTAssertTrue(try XCTUnwrap(NSApp.mainMenu).performKeyEquivalent(with: event))

        XCTAssertFalse(window.isVisible, "⌘W 应关闭设置窗口")
    }
}
