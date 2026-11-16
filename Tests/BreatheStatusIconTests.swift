import AppKit
import XCTest
@testable import Breathe

final class BreatheStatusIconTests: XCTestCase {
    @MainActor
    func testActiveSessionDisplaysRemainingTime() throws {
        let delegate = AppDelegate()
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        delegate.statusItem = item

        delegate.updateStatusBarContent(isActive: true, remaining: 1129)

        XCTAssertEqual(try XCTUnwrap(item.button).title, " 18:49")
    }

    @MainActor
    func testEndingSessionClearsRemainingTime() throws {
        let delegate = AppDelegate()
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        delegate.statusItem = item
        delegate.updateStatusBarContent(isActive: true, remaining: 1129)

        delegate.updateStatusBarContent(isActive: false, remaining: 0)

        XCTAssertEqual(try XCTUnwrap(item.button).title, "")
    }

    @MainActor
    func testCountdownUsesSystemTextColourForBothAppearances() throws {
        let delegate = AppDelegate()
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer { NSStatusBar.system.removeStatusItem(item) }
        delegate.statusItem = item
        let button = try XCTUnwrap(item.button)

        for appearance in [NSAppearance.Name.aqua, .darkAqua] {
            button.appearance = NSAppearance(named: appearance)
            delegate.updateStatusBarContent(isActive: true, remaining: 1129)

            XCTAssertEqual(button.title, " 18:49")
            button.attributedTitle.enumerateAttribute(
                .foregroundColor,
                in: NSRange(location: 0, length: button.attributedTitle.length)
            ) { colour, _, _ in
                XCTAssertEqual(
                    colour as? NSColor,
                    NSColor.controlTextColor,
                    "倒计时应使用系统文字颜色：\(appearance.rawValue)"
                )
            }
            XCTAssertNil(button.contentTintColor)
        }
    }

    func testVisibleGlyphIsVerticallyCentered() {
        let image = BreatheStatusIcon.make()
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 40, pixelsHigh: 40, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = image.size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: NSRect(origin: .zero, size: image.size))
        NSGraphicsContext.restoreGraphicsState()
        var rows: [Int] = []
        for y in 0..<bitmap.pixelsHigh {
            if (0..<bitmap.pixelsWide).contains(where: { bitmap.colorAt(x: $0, y: y)!.alphaComponent > 0.1 }) { rows.append(y) }
        }
        guard let first = rows.first, let last = rows.last else {
            XCTFail("图标为空")
            return
        }
        XCTAssertEqual(first, bitmap.pixelsHigh - 1 - last, accuracy: 1)
        XCTAssertTrue(image.isTemplate)
    }
}
