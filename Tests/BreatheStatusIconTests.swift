import AppKit
import XCTest
@testable import Breathe

final class BreatheStatusIconTests: XCTestCase {
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
