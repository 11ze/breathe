import SwiftUI

/// 设置窗口的两个分类。
enum SettingsTab: String {
    case preset
    case general
}

/// 设置窗口的分类选择，菜单打开“自定义”时切回预设页。
final class SettingsNavigation: ObservableObject {
    @Published var tab: SettingsTab = .preset
}

/// 设置窗口，布局和视觉按 `designs/breathe/` 原型一比一实现。
struct SettingsView: View {
    @ObservedObject private var settingsManager = AppSettingsManager.shared
    @StateObject private var windowBox = BreatheWindowBox()
    @ObservedObject private var navigation: SettingsNavigation
    @State private var inhaleText: String
    @State private var exhaleText: String
    @State private var durationText: String

    init(navigation: SettingsNavigation = SettingsNavigation(), initialTab: SettingsTab? = nil) {
        if let initialTab = initialTab {
            navigation.tab = initialTab
        }
        _navigation = ObservedObject(wrappedValue: navigation)
        let settings = AppSettingsManager.shared.settings
        _inhaleText = State(initialValue: "\(settings.customInhaleSeconds)")
        _exhaleText = State(initialValue: "\(settings.customExhaleSeconds)")
        _durationText = State(initialValue: "\(settings.customDurationMinutes)")
    }

    var body: some View {
        VStack(spacing: 0) {
            BreatheWindowTitlebar(title: "设置") { action in
                BreatheWindowActionHandler.perform(action, on: windowBox.window)
            }

            tabBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if selectedTab == .preset {
                        presetTab
                    } else {
                        generalTab
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 30)
                .padding(.bottom, 22)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BreatheStyle.surface)
        .frame(minWidth: 540, minHeight: 560)
        .background(BreatheWindowAccessor(box: windowBox))
        .onChange(of: settingsManager.settings.customInhaleSeconds) { value in
            if Int(inhaleText) != value { inhaleText = "\(value)" }
        }
        .onChange(of: settingsManager.settings.customExhaleSeconds) { value in
            if Int(exhaleText) != value { exhaleText = "\(value)" }
        }
        .onChange(of: settingsManager.settings.customDurationMinutes) { value in
            if Int(durationText) != value { durationText = "\(value)" }
        }
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1)
        )
        .ignoresSafeArea()
        .onAppear(perform: syncDraftsFromSettings)
    }

    private var selectedTab: SettingsTab {
        navigation.tab
    }

    // MARK: - 分类切换

    private var tabBar: some View {
        HStack(spacing: 6) {
            tabButton(.preset) {
                BreatheWavesMark(
                    color: selectedTab == .preset ? BreatheStyle.green : BreatheStyle.ink,
                    fontSize: 18
                )
                .frame(height: 18)
                Text("预设")
                    .font(.system(size: 12))
            }
            tabButton(.general) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .frame(height: 18)
                Text("通用")
                    .font(.system(size: 12))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(BreatheStyle.tabbar)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BreatheStyle.line)
                .frame(height: 1)
        }
    }

    private func tabButton<Label: View>(
        _ tab: SettingsTab,
        @ViewBuilder label: () -> Label
    ) -> some View {
        let selected = selectedTab == tab
        return Button {
            navigation.tab = tab
        } label: {
            HStack(spacing: 7, content: label)
                .foregroundColor(selected ? BreatheStyle.green : BreatheStyle.ink)
                .padding(.horizontal, 16)
                .frame(minWidth: 86, minHeight: 30)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(selected ? Color.white : Color.clear)
                )
                .shadow(
                    color: selected ? Color(hex: 0x243A23, opacity: 0.13) : Color.clear,
                    radius: 2,
                    y: 1
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - 预设

    private var presetTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading("呼吸节奏", description: "选择适合当前时段的呼吸预设。")

            BreatheGroup {
                HStack {
                    Text("默认预设")
                        .font(.system(size: 13))
                        .foregroundColor(BreatheStyle.ink)
                    Spacer()
                    BreatheSelect(
                        selection: settingsManager.settings.defaultPreset,
                        options: presetOptions,
                        onChange: selectPreset
                    )
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 48)

                if !(isCustom && customValidation != nil) {
                    BreatheDivider(inset: 14)
                    if settingsManager.settings.defaultPreset == "auto" {
                        TimelineView(.periodic(from: .now, by: 60)) { _ in
                            presetSummary
                        }
                    } else {
                        presetSummary
                    }
                }
            }

            if isCustom {
                BreatheSectionTitle(title: "自定义比例")
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                BreatheGroup {
                    customRow(title: "吸气", text: $inhaleText, unit: "秒", onChange: updateInhale)
                    BreatheDivider()
                    customRow(title: "呼气", text: $exhaleText, unit: "秒", onChange: updateExhale)
                    BreatheDivider()
                    customRow(title: "练习时长", text: $durationText, unit: "分钟", onChange: updateDuration)
                }

                validationLine
            } else if settingsManager.settings.defaultPreset == "auto" {
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    VStack(alignment: .leading, spacing: 0) {
                        BreatheSectionTitle(title: "时段映射")
                            .padding(.top, 20)
                            .padding(.bottom, 8)

                        BreatheGroup {
                            periodRow("早晨", time: "06:00 – 12:00", symbol: "☼", preset: .morning, current: currentPreset)
                            BreatheDivider(inset: 14)
                            periodRow("下午", time: "12:00 – 17:00", symbol: "☀", preset: .midday, current: currentPreset)
                            BreatheDivider(inset: 14)
                            periodRow("傍晚", time: "17:00 – 22:00", symbol: "◒", preset: .evening, current: currentPreset)
                            BreatheDivider(inset: 14)
                            periodRow("夜间", time: "22:00 – 06:00", symbol: "☾", preset: .night, current: currentPreset)
                        }

                        Text("全部预设均为每分钟 6 次呼吸。")
                            .font(.system(size: 10))
                            .foregroundColor(BreatheStyle.muted)
                            .padding(.top, 12)
                            .padding(.leading, 3)
                    }
                }
            }
        }
    }

    private var presetOptions: [BreatheSelectOption<String>] {
        var options = [BreatheSelectOption(value: "auto", title: "自动（按时段）")]
        options += Preset.allCases.map {
            BreatheSelectOption(value: $0.rawValue, title: $0.displayName)
        }
        options.append(BreatheSelectOption(value: "custom", title: "自定义…"))
        return options
    }

    private var presetSummary: some View {
        let config = BreathingConfig.fromCurrentSettings()
        let presetName = settingsManager.settings.defaultPreset == "custom"
            ? "自定义"
            : Preset.displayName(for: config.presetName)
        let label = settingsManager.settings.defaultPreset == "auto" ? "当前预设" : "所选预设"

        return HStack(spacing: 0) {
            summaryColumn(label, value: presetName, unit: "", valueSize: 15)
            summaryDivider
            summaryColumn("吸气 / 呼气", value: "\(config.inhaleSeconds) / \(config.exhaleSeconds)", unit: "秒")
                .padding(.leading, 18)
            summaryDivider
            summaryColumn("练习时长", value: "\(config.durationSeconds / 60)", unit: "分钟")
                .padding(.leading, 18)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(BreatheStyle.separator)
            .frame(width: 1, height: 38)
    }

    private func summaryColumn(
        _ title: String,
        value: String,
        unit: String,
        valueSize: CGFloat = 19
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(BreatheStyle.muted)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: valueSize, weight: .medium).monospacedDigit())
                    .foregroundColor(BreatheStyle.summaryValue)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11))
                        .foregroundColor(BreatheStyle.muted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var currentPreset: Preset {
        TimeOfDay.current().recommendedPreset
    }

    private func periodRow(
        _ title: String,
        time: String,
        symbol: String,
        preset: Preset,
        current: Preset
    ) -> some View {
        HStack(spacing: 10) {
            Text(symbol)
                .font(.system(size: 21))
                .foregroundColor(preset == current ? BreatheStyle.accent : Color(hex: 0x708370))
                .frame(width: 23, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundColor(BreatheStyle.ink)
                    if preset == current {
                        Text("当前")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(BreatheStyle.statusGreen)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(BreatheStyle.statusGreenBackground)
                            )
                    }
                }
                Text(time)
                    .font(.system(size: 10))
                    .foregroundColor(BreatheStyle.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 3) {
                Text(preset.displayRatio)
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundColor(BreatheStyle.ink)
                Text("\(preset.durationMinutes) 分钟")
                    .font(.system(size: 10))
                    .foregroundColor(BreatheStyle.muted)
            }
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private func customRow(
        title: String,
        text: Binding<String>,
        unit: String,
        onChange: @escaping (String) -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(BreatheStyle.ink)
            Spacer()
            BreatheNumberField(text: text, unit: unit)
                .onChange(of: text.wrappedValue, perform: onChange)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 48)
    }

    private var validationLine: some View {
        Group {
            if let message = customValidation {
                Text(message)
                    .foregroundColor(BreatheStyle.error)
            } else if let config = customConfig {
                Text("周期 \(config.cycleSeconds) 秒，实际时长 \(config.durationSeconds / 60) 分 \(config.durationSeconds % 60) 秒")
                    .foregroundColor(BreatheStyle.green)
            }
        }
        .font(.system(size: 11))
        .lineSpacing(2)
        .padding(.top, 10)
        .padding(.leading, 3)
    }

    // MARK: - 通用

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading("通用", description: "声音、会话记录与启动选项。")

            BreatheSectionTitle(title: "音频")
                .padding(.top, 20)
                .padding(.bottom, 8)

            BreatheGroup {
                HStack {
                    settingLabel("声音提示", detail: "在吸气和呼气开始时播放提示音")
                    Spacer()
                    Toggle("声音提示", isOn: bindingFor(\.soundEnabled))
                        .labelsHidden()
                        .toggleStyle(BreatheSwitchToggleStyle())
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
            }

            BreatheSectionTitle(title: "数据")
                .padding(.top, 20)
                .padding(.bottom, 8)

            BreatheGroup {
                HStack {
                    Text("记录会话日志")
                        .font(.system(size: 13))
                        .foregroundColor(BreatheStyle.ink)
                    Spacer()
                    Toggle("记录会话日志", isOn: bindingFor(\.logSessions))
                        .labelsHidden()
                        .toggleStyle(BreatheSwitchToggleStyle())
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 48)

                if settingsManager.settings.logSessions {
                    BreatheDivider()
                    HStack {
                        Text("日志路径")
                        Spacer()
                        Text("~/.config/breathe/sessions.csv")
                            .textSelection(.enabled)
                    }
                    .font(.system(size: 10))
                    .foregroundColor(BreatheStyle.muted)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                }
            }

            BreatheSectionTitle(title: "启动")
                .padding(.top, 20)
                .padding(.bottom, 8)

            BreatheGroup {
                if LaunchAtLoginManager.shared.isSupported {
                    HStack {
                        settingLabel("开机自动启动", detail: "登录 macOS 时启动 Breathe")
                        Spacer()
                        Toggle("开机自动启动", isOn: launchAtLoginBinding)
                            .labelsHidden()
                            .toggleStyle(BreatheSwitchToggleStyle())
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                } else {
                    Text("需要 macOS 13 或更高版本")
                        .font(.system(size: 13))
                        .foregroundColor(BreatheStyle.muted)
                        .padding(14)
                }
            }
        }
    }

    // MARK: - 布局辅助

    private func heading(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .tracking(-0.5)
                .foregroundColor(BreatheStyle.ink)
            Text(description)
                .font(.system(size: 12))
                .foregroundColor(BreatheStyle.muted)
                .lineSpacing(3)
                .frame(height: 20, alignment: .topLeading)
        }
        .padding(.bottom, 19)
    }

    private func settingLabel(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(BreatheStyle.ink)
            Text(detail)
                .font(.system(size: 11))
                .foregroundColor(BreatheStyle.muted)
                .lineSpacing(2)
        }
    }

    // MARK: - 自定义比例校验

    private var isCustom: Bool {
        settingsManager.settings.defaultPreset == "custom"
    }

    private var customConfig: BreathingConfig? {
        guard let inhale = Int(inhaleText),
              let exhale = Int(exhaleText),
              let minutes = Int(durationText) else { return nil }
        return BreathingConfig(inhale: inhale, exhale: exhale, durationMinutes: minutes)
    }

    private var customValidation: String? {
        guard let inhale = Int(inhaleText),
              let exhale = Int(exhaleText),
              let minutes = Int(durationText) else {
            return "请输入完整的整数时长。"
        }
        if case .failure(let error) = RatioValidator.validate(inhale: inhale, exhale: exhale) {
            switch error {
            case .inhaleOutOfRange:
                return "吸气时长须在 3–10 秒"
            case .exhaleOutOfRange:
                return "呼气时长须在 3–10 秒"
            default:
                return error.errorDescription
            }
        }
        if !(1...60).contains(minutes) {
            return "练习时长须在 1–60 分钟"
        }
        return nil
    }

    private func selectPreset(_ value: String) {
        settingsManager.settings.defaultPreset = value
        settingsManager.save()
        if value == "custom" {
            navigation.tab = .preset
        }
    }

    private func syncDraftsFromSettings() {
        inhaleText = "\(settingsManager.settings.customInhaleSeconds)"
        exhaleText = "\(settingsManager.settings.customExhaleSeconds)"
        durationText = "\(settingsManager.settings.customDurationMinutes)"
    }

    private func updateInhale(_ text: String) {
        guard let value = Int(text),
              value != settingsManager.settings.customInhaleSeconds else { return }
        settingsManager.settings.customInhaleSeconds = value
        settingsManager.save()
    }

    private func updateExhale(_ text: String) {
        guard let value = Int(text),
              value != settingsManager.settings.customExhaleSeconds else { return }
        settingsManager.settings.customExhaleSeconds = value
        settingsManager.save()
    }

    private func updateDuration(_ text: String) {
        guard let value = Int(text),
              value != settingsManager.settings.customDurationMinutes else { return }
        settingsManager.settings.customDurationMinutes = value
        settingsManager.save()
    }

    // MARK: - 配置绑定

    private func bindingFor<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { settingsManager.settings[keyPath: keyPath] },
            set: { newValue in
                settingsManager.settings[keyPath: keyPath] = newValue
                settingsManager.save()
            }
        )
    }

    /// 先注册系统服务，配置同步为系统最终状态，注册失败时开关回弹。
    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settingsManager.settings.launchAtLogin },
            set: { newValue in
                let finalState = LaunchAtLoginManager.shared.setEnabled(newValue)
                settingsManager.settings.launchAtLogin = finalState
                settingsManager.save()
            }
        )
    }
}

extension Preset {
    /// 设计稿使用短连接号展示比例。
    var displayRatio: String {
        "\(inhaleSeconds)–\(exhaleSeconds)"
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView(initialTab: .preset)
                .frame(width: 540, height: 640)
            SettingsView(initialTab: .general)
                .frame(width: 540, height: 640)
        }
    }
}
