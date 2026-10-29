import AppKit
import SwiftUI

/// 无系统交通灯、但保留原生窗口缩放与阴影的窗口。
final class BreatheWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// 让 SwiftUI 内容铺满整窗，忽略系统标题栏带来的顶部安全区。
final class BreatheHostingView<Content: View>: NSHostingView<Content> {
    override var safeAreaInsets: NSEdgeInsets { NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) }
}

/// 自定义交通灯绘制在内容层，系统标题栏覆盖顶部约 28pt。
/// 在事件派发前接管标题栏：三个圆点执行窗口动作，其余区域拖动或双击缩放。
@MainActor
enum BreatheTrafficLightMonitor {
    private static var installed = false
    private static let titlebarHeight: CGFloat = 47

    static func install() {
        guard !installed else { return }
        installed = true
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { event in
            guard let window = event.window as? BreatheWindow else { return event }
            let point = event.locationInWindow
            let distanceFromTop = window.frame.height - point.y
            guard (0..<titlebarHeight).contains(distanceFromTop) else { return event }

            if (15...32).contains(distanceFromTop) {
                switch point.x {
                case 15...29:
                    window.performClose(nil)
                    return nil
                case 35...49:
                    window.miniaturize(nil)
                    return nil
                case 55...69:
                    window.zoom(nil)
                    return nil
                default:
                    break
                }
            }

            if event.clickCount == 2 {
                window.zoom(nil)
            } else {
                window.performDrag(with: event)
            }
            return nil
        }
    }
}
