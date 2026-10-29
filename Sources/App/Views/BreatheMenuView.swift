import AppKit
import SwiftUI

/// 菜单面板中的命令。
enum BreatheMenuAction {
    case toggleBreathing
    case togglePause
    case selectPreset(String)
    case toggleMute
    case openHistory
    case openSettings
    case quit
}

@MainActor
final class BreatheMenuModel: ObservableObject {
    @Published var presetExpanded = false
}

/// 状态栏下拉菜单，按设计稿一比一实现。
struct BreatheMenuView: View {
    @ObservedObject private var engine = BreathingEngine.shared
    @ObservedObject private var settings = AppSettingsManager.shared
    @ObservedObject private var audio = AudioManager.shared
    @ObservedObject var model: BreatheMenuModel

    let onAction: (BreatheMenuAction) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            menuRow(
                title: engine.isSessionActive ? "停止呼吸" : "开始呼吸",
                tint: BreatheStyle.green,
                emphasized: true,
                disabled: startDisabled
            ) { color in
                Text("⌘ B").font(.system(size: 11)).foregroundColor(color)
            } action: {
                onAction(.toggleBreathing)
            }

            if engine.isSessionActive {
                menuRow(
                    title: engine.isPaused ? "继续" : "暂停",
                    disabled: isCountdown
                ) { color in
                    Text("Space").font(.system(size: 11)).foregroundColor(color)
                } action: {
                    onAction(.togglePause)
                }
            }

            menuRule

            menuRow(title: "预设") { color in
                HStack(spacing: 12) {
                    Text(currentPresetName)
                        .font(.system(size: 11))
                        .foregroundColor(color)
                    Text("›")
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
            } action: {
                model.presetExpanded.toggle()
            }

            if model.presetExpanded {
                presetList
            }

            menuRow(title: audio.isMuted ? "取消静音" : "静音") { color in
                Text("S").font(.system(size: 11)).foregroundColor(color)
            } action: {
                onAction(.toggleMute)
            }

            menuRule

            menuRow(title: "历史记录") { color in
                Text("⌘ H").font(.system(size: 11)).foregroundColor(color)
            } action: {
                onAction(.openHistory)
            }

            menuRow(title: "设置…") { color in
                Text("⌘ ,").font(.system(size: 11)).foregroundColor(color)
            } action: {
                onAction(.openSettings)
            }

            menuRule

            menuRow(title: "退出 Breathe") { color in
                Text("⌘ Q").font(.system(size: 11)).foregroundColor(color)
            } action: {
                onAction(.quit)
            }
        }
        .padding(6)
        .frame(width: 260)
        .background(menuBackground)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - 头部与分隔线

    private var header: some View {
        HStack(spacing: 8) {
            BreatheWavesMark(color: BreatheStyle.green, width: 24, height: 15, horizontalInset: 2)
            Text("Breathe")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(BreatheStyle.ink)
            Spacer()
            Text(statusText)
                .font(.system(size: 10))
                .foregroundColor(BreatheStyle.muted)
        }
        .padding(.top, 10)
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
    }

    private var menuRule: some View {
        Rectangle()
            .fill(BreatheStyle.menuRule)
            .frame(height: 1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
    }

    // MARK: - 菜单行

    private func menuRow<Trailing: View>(
        title: String,
        tint: Color = BreatheStyle.ink,
        emphasized: Bool = false,
        disabled: Bool = false,
        @ViewBuilder trailing: @escaping (Color) -> Trailing,
        action: @escaping () -> Void
    ) -> some View {
        BreatheMenuRow(
            title: title,
            tint: tint,
            emphasized: emphasized,
            disabled: disabled,
            trailing: trailing,
            action: action
        )
    }

    // MARK: - 预设子菜单

    private var presetList: some View {
        VStack(spacing: 0) {
            presetOption("自动（按时段）", value: "auto", detail: nil)
            ForEach(Preset.allCases, id: \.self) { preset in
                presetOption(
                    preset.displayName,
                    value: preset.rawValue,
                    detail: "\(preset.displayRatio) · \(preset.durationMinutes) 分钟"
                )
            }
            presetOption("自定义…", value: "custom", detail: nil)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(BreatheStyle.menuPresetMenuBorder, lineWidth: 1)
        )
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    private func presetOption(_ title: String, value: String, detail: String?) -> some View {
        BreathePresetOption(
            title: title,
            detail: detail,
            selected: settings.settings.defaultPreset == value
        ) {
            model.presetExpanded = false
            onAction(.selectPreset(value))
        }
    }

    // MARK: - 状态

    private var currentPresetName: String {
        switch settings.settings.defaultPreset {
        case "auto": return "自动"
        case "custom": return "自定义"
        default: return Preset.displayName(for: settings.settings.defaultPreset)
        }
    }

    private var statusText: String {
        switch engine.phase {
        case .idle: return "准备就绪"
        case .countdown: return "准备开始"
        case .inhale: return "吸气"
        case .exhale: return "呼气"
        case .paused: return "已暂停"
        }
    }

    private var isCountdown: Bool {
        if case .countdown = engine.phase { return true }
        return false
    }

    private var startDisabled: Bool {
        guard !engine.isSessionActive, settings.settings.defaultPreset == "custom" else { return false }
        return BreathingConfig(
            inhale: settings.settings.customInhaleSeconds,
            exhale: settings.settings.customExhaleSeconds,
            durationMinutes: settings.settings.customDurationMinutes
        ) == nil
    }

    private var menuBackground: some View {
        ZStack {
            MenuVisualEffect()
            BreatheStyle.menuSurface.opacity(0.94)
        }
    }
}

// MARK: - 行组件

private struct BreatheMenuRow<Trailing: View>: View {
    let title: String
    let tint: Color
    let emphasized: Bool
    let disabled: Bool
    let trailing: (Color) -> Trailing
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        let foreground: Color = disabled
            ? tint.opacity(0.45)
            : (hovering ? Color.white : tint)

        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: emphasized ? .semibold : .regular))
                Spacer(minLength: 8)
                trailing(disabled ? BreatheStyle.shortcut.opacity(0.45) : (hovering ? Color.white : BreatheStyle.shortcut))
            }
            .foregroundColor(foreground)
            .padding(.horizontal, 10)
            .frame(minHeight: 30)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(hovering && !disabled ? BreatheStyle.accent : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { hovering = $0 }
    }
}

private struct BreathePresetOption: View {
    let title: String
    let detail: String?
    let selected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 11, weight: selected ? .semibold : .regular))
                Spacer(minLength: 8)
                if let detail = detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .opacity(0.7)
                }
            }
            .foregroundColor(hovering ? .white : (selected ? BreatheStyle.green : BreatheStyle.ink))
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(hovering ? BreatheStyle.accent : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

// MARK: - 毛玻璃背景

private struct MenuVisualEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - 预览

struct BreatheMenuView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BreatheMenuView(model: BreatheMenuModel(), onAction: { _ in })
            BreatheMenuView(model: {
                let model = BreatheMenuModel()
                model.presetExpanded = true
                return model
            }(), onAction: { _ in })
        }
        .padding(20)
        .background(Color(hex: 0xDDE5DF))
    }
}
