import AppKit
import SwiftUI

// MARK: - 设计令牌

/// 设计稿 `designs/breathe/style.css` 的颜色与尺寸。
enum BreatheStyle {
    static let ink = Color(hex: 0x242B28)
    static let muted = Color(hex: 0x66716B)
    static let green = Color(hex: 0x26734F)
    static let accent = Color(hex: 0x2C8058)
    static let line = Color(hex: 0xDCE0DD)

    static let surface = Color(hex: 0xF5F6F4)
    static let titlebar = Color(hex: 0xEFF1ED)
    static let titlebarLine = Color(hex: 0xD6DDD5)
    static let tabbar = Color(hex: 0xF0F2EE)
    static let separator = Color(hex: 0xE5E9E3)
    static let sectionTitle = Color(hex: 0x606B63)
    static let summaryValue = Color(hex: 0x345C43)

    static let controlBorder = Color(hex: 0xCBD2CB)
    static let switchOff = Color(hex: 0xD2D8D0)
    static let switchBorder = Color(hex: 0xC2CAC2)
    static let buttonBorder = Color(hex: 0xCFD5CE)
    static let buttonHover = Color(hex: 0xEEF2EB)
    static let buttonPressed = Color(hex: 0xDCE5D9)

    static let tableHeader = Color(hex: 0xECEfe8)
    static let tableHeaderText = Color(hex: 0x677164)
    static let tableHeaderLine = Color(hex: 0xD7DDD1)
    static let tableRowHover = Color(hex: 0xE1ECDC)
    static let tablePreset = Color(hex: 0x4F6650)

    static let statusGreen = Color(hex: 0x2F7046)
    static let statusGreenBackground = Color(hex: 0xE3EFE2)
    static let statusOrange = Color(hex: 0x8D5C25)
    static let statusOrangeBackground = Color(hex: 0xF4EADA)

    static let menuSurface = Color(hex: 0xF4F7F3)
    static let menuRule = Color(hex: 0xC9D1C9)
    static let shortcut = Color(hex: 0x6C776E)
    static let menuEnd = Color(hex: 0x66716B)
    static let menuPresetMenuBorder = Color(hex: 0xCBD5CC)

    static let error = Color(hex: 0xA34224)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - 分组与标题

struct BreatheSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(BreatheStyle.sectionTitle)
            .padding(.leading, 3)
    }
}

struct BreatheGroup<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0, content: { content })
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(BreatheStyle.line, lineWidth: 1)
            )
    }
}

struct BreatheDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(BreatheStyle.separator)
            .frame(height: 1)
            .padding(.horizontal, inset)
    }
}

// MARK: - 标题栏

/// 从 SwiftUI 视图访问所在窗口，标题栏按钮和拖动区域使用。
@MainActor
final class BreatheWindowBox: ObservableObject {
    weak var window: NSWindow?
}

struct BreatheWindowAccessor: NSViewRepresentable {
    let box: BreatheWindowBox

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            box.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            box.window = nsView.window
        }
    }
}

struct BreatheWindowTitlebar: View {
    let title: String
    let onAction: (BreatheWindowAction) -> Void

    @State private var hoveringLights = false

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                HStack(spacing: BreatheTitlebarMetrics.dotSpacing) {
                    trafficLight(
                        color: Color(hex: 0xEF6A60),
                        symbol: "xmark",
                        label: "关闭"
                    ) {
                        onAction(.close)
                    }
                    trafficLight(
                        color: Color(hex: 0xEDC052),
                        symbol: "minus",
                        label: "最小化"
                    ) {
                        onAction(.minimize)
                    }
                    trafficLight(
                        color: Color(hex: 0x62BE67),
                        symbol: "plus",
                        label: "缩放"
                    ) {
                        onAction(.zoom)
                    }
                }
                .onHover { hoveringLights = $0 }

                Spacer(minLength: 0)

                Text("Breathe")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: 0x7A847B))
                    .allowsHitTesting(false)
            }

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(BreatheStyle.ink)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, BreatheTitlebarMetrics.horizontalPadding)
        .frame(height: BreatheTitlebarMetrics.height)
        .background(BreatheStyle.titlebar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BreatheStyle.titlebarLine)
                .frame(height: 1)
        }
    }

    private func trafficLight(
        color: Color,
        symbol: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .overlay(Circle().strokeBorder(Color.black.opacity(0.08), lineWidth: 1))
                if hoveringLights {
                    Image(systemName: symbol)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.55))
                }
            }
            .frame(width: BreatheTitlebarMetrics.dotSize, height: BreatheTitlebarMetrics.dotSize)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - 控件

struct BreatheSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(configuration.isOn ? BreatheStyle.accent : BreatheStyle.switchOff)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                configuration.isOn ? BreatheStyle.accent : BreatheStyle.switchBorder,
                                lineWidth: 1
                            )
                    )
                Circle()
                    .fill(Color.white)
                    .frame(width: 15, height: 15)
                    .shadow(color: Color.black.opacity(0.13), radius: 1.5, y: 1)
                    .padding(1)
            }
            .frame(width: 32, height: 19)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) {
                configuration.label
            }
            .toggleStyle(.switch)
        }
    }
}

struct BreathePushButton: View {
    let title: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(BreatheStyle.ink)
                .padding(.horizontal, 11)
                .frame(height: 25)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(hovering ? BreatheStyle.buttonHover : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(BreatheStyle.buttonBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressedFadeStyle())
        .onHover { hovering = $0 }
    }
}

private struct PressedFadeStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct BreatheSelectOption<Value: Hashable>: Identifiable {
    let value: Value
    let title: String

    var id: Value { value }
}

/// 用原生 NSMenu 呈现选项，关闭状态的外观完全由设计稿控制。
@MainActor
final class BreatheSelectPresenter: NSObject, ObservableObject {
    struct Item {
        let title: String
        let value: AnyHashable
        let selected: Bool
    }

    var items: [Item] = []
    var onSelect: ((AnyHashable) -> Void)?

    func present() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.appearance = NSAppearance(named: .aqua)
        for item in items {
            let menuItem = NSMenuItem(
                title: item.title,
                action: #selector(selectItem(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = item.value
            menuItem.state = item.selected ? .on : .off
            menu.addItem(menuItem)
        }

        let mouse = NSEvent.mouseLocation
        let window = NSApp.keyWindow ?? NSApp.windows.first {
            $0.isVisible && $0.frame.contains(mouse)
        }
        guard let view = window?.contentView else { return }
        let point = view.convert(mouse, from: nil)
        menu.popUp(positioning: nil, at: NSPoint(x: point.x - 8, y: point.y - 22), in: view)
    }

    @objc private func selectItem(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? AnyHashable else { return }
        onSelect?(value)
    }
}

struct BreatheSelect<Value: Hashable>: View {
    let selection: Value
    let options: [BreatheSelectOption<Value>]
    let onChange: (Value) -> Void

    @StateObject private var presenter = BreatheSelectPresenter()

    private var selectedTitle: String {
        options.first(where: { $0.value == selection })?.title ?? ""
    }

    var body: some View {
        Button {
            configurePresenter()
            presenter.present()
        } label: {
            HStack(spacing: 8) {
                Text(selectedTitle)
                    .font(.system(size: 12))
                    .foregroundColor(BreatheStyle.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(BreatheStyle.muted)
            }
            .padding(.horizontal, 9)
            .frame(width: 245, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(BreatheStyle.controlBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 1, y: 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear(perform: configurePresenter)
    }

    private func configurePresenter() {
        presenter.items = options.map {
            BreatheSelectPresenter.Item(
                title: $0.title,
                value: AnyHashable($0.value),
                selected: $0.value == selection
            )
        }
        presenter.onSelect = { value in
            if let selected = value as? Value {
                onChange(selected)
            }
        }
    }
}

/// 状态栏使用的 ≋ 模板图标。
enum BreatheStatusIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 20, height: 15)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setStroke()
            for index in 0..<3 {
                let y = 2.0 + CGFloat(index) * 5.5
                let path = NSBezierPath()
                path.lineWidth = 1.5
                path.lineCapStyle = .round
                path.move(to: NSPoint(x: 1, y: y))
                path.curve(
                    to: NSPoint(x: 10, y: y),
                    controlPoint1: NSPoint(x: 3.8, y: y + 2.4),
                    controlPoint2: NSPoint(x: 7.2, y: y + 2.4)
                )
                path.curve(
                    to: NSPoint(x: 19, y: y),
                    controlPoint1: NSPoint(x: 12.8, y: y - 2.4),
                    controlPoint2: NSPoint(x: 16.2, y: y - 2.4)
                )
                path.stroke()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}

/// 设计稿品牌符号 ≋ 的矢量版本，用于分类标签、菜单与状态栏。
struct BreatheWavesMark: View {
    var color: Color = BreatheStyle.green
    var width: CGFloat = 18
    var height: CGFloat = 13
    /// 字体字形左右留白，用于让墨迹尺寸与设计稿的 ≋ 一致。
    var horizontalInset: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            let inset = min(horizontalInset, size.width / 2)
            let drawWidth = size.width - inset * 2
            let amplitude = size.height * 0.16
            let lineWidth = max(1, size.height * 0.10)
            for index in 0..<3 {
                let y = size.height * (0.2 + Double(index) * 0.3)
                var path = Path()
                path.move(to: CGPoint(x: inset, y: y))
                path.addCurve(
                    to: CGPoint(x: inset + drawWidth * 0.5, y: y),
                    control1: CGPoint(x: inset + drawWidth * 0.18, y: y - amplitude),
                    control2: CGPoint(x: inset + drawWidth * 0.32, y: y - amplitude)
                )
                path.addCurve(
                    to: CGPoint(x: inset + drawWidth, y: y),
                    control1: CGPoint(x: inset + drawWidth * 0.68, y: y + amplitude),
                    control2: CGPoint(x: inset + drawWidth * 0.82, y: y + amplitude)
                )
                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

struct BreatheNumberField: View {
    @Binding var text: String
    let unit: String

    var body: some View {
        HStack(spacing: 8) {
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 12).monospacedDigit())
                .foregroundColor(BreatheStyle.ink)
                .frame(width: 70, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(BreatheStyle.controlBorder, lineWidth: 1)
                )
            Text(unit)
                .font(.system(size: 11))
                .foregroundColor(BreatheStyle.muted)
        }
    }
}

struct BreatheStatusBadge: View {
    let completed: Bool

    var body: some View {
        Text(completed ? "已完成" : "提前结束")
            .font(.system(size: 10))
            .foregroundColor(completed ? BreatheStyle.statusGreen : BreatheStyle.statusOrange)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(completed ? BreatheStyle.statusGreenBackground : BreatheStyle.statusOrangeBackground)
            )
            .fixedSize()
    }
}
