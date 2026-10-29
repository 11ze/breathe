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

/// 标题栏三个圆点的动作，SwiftUI 按钮和事件监听共用。
enum BreatheWindowAction {
    case close
    case minimize
    case zoom
}

/// 窗口动作的唯一实现。
enum BreatheWindowActionHandler {
    static func perform(_ action: BreatheWindowAction, on window: NSWindow?) {
        guard let window = window else { return }
        switch action {
        case .close:
            window.performClose(nil)
        case .minimize:
            window.miniaturize(nil)
        case .zoom:
            window.zoom(nil)
        }
    }
}

/// 标题栏尺寸与圆点命中区域的单一来源。
/// 坐标以标题栏左上角为原点，y 向下。
enum BreatheTitlebarMetrics {
    static let height: CGFloat = 47
    static let horizontalPadding: CGFloat = 16
    static let dotSize: CGFloat = 12
    static let dotSpacing: CGFloat = 8

    static let actions: [BreatheWindowAction] = [.close, .minimize, .zoom]

    static func dotRect(_ index: Int) -> CGRect {
        CGRect(
            x: horizontalPadding + CGFloat(index) * (dotSize + dotSpacing),
            y: (height - dotSize) / 2,
            width: dotSize,
            height: dotSize
        )
    }

    static func hitRect(_ index: Int) -> CGRect {
        dotRect(index).insetBy(dx: -1, dy: -2.5)
    }

    static func action(at point: CGPoint) -> BreatheWindowAction? {
        for (index, action) in actions.enumerated() where hitRect(index).contains(point) {
            return action
        }
        return nil
    }
}

/// 自定义交通灯绘制在内容层，系统标题栏覆盖顶部约 28pt。
/// 在事件派发前接管标题栏：三个圆点执行窗口动作，其余区域拖动或双击缩放。
@MainActor
enum BreatheTrafficLightMonitor {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { event in
            guard let window = event.window as? BreatheWindow else { return event }
            let point = event.locationInWindow
            let distanceFromTop = window.frame.height - point.y
            guard (0..<BreatheTitlebarMetrics.height).contains(distanceFromTop) else { return event }

            if let action = BreatheTitlebarMetrics.action(at: CGPoint(x: point.x, y: distanceFromTop)) {
                BreatheWindowActionHandler.perform(action, on: window)
                return nil
            }

            if event.clickCount == 2 {
                BreatheWindowActionHandler.perform(.zoom, on: window)
            } else {
                window.performDrag(with: event)
            }
            return nil
        }
    }
}
