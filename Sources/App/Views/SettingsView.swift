import SwiftUI

/// 设置与历史窗口共用的原生界面颜色。
enum BreatheStyle {
    static let accent = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
            return NSColor(srgbRed: 0.45, green: 0.78, blue: 0.59, alpha: 1)
        }
        return NSColor(srgbRed: 0.17, green: 0.50, blue: 0.35, alpha: 1)
    })
    static let background = Color(nsColor: NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
            return NSColor.windowBackgroundColor
        }
        return NSColor(srgbRed: 0.96, green: 0.965, blue: 0.955, alpha: 1)
    })
    static let surface = Color(nsColor: .controlBackgroundColor)
}

struct SettingsView: View {
    @ObservedObject private var settingsManager = AppSettingsManager.shared
    @State private var selectedTab = "预设"

    var body: some View {
        VStack(spacing: 0) {
            Picker("设置分类", selection: $selectedTab) {
                Label("预设", systemImage: "wind").tag("预设")
                Label("通用", systemImage: "gearshape").tag("通用")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 200)
            .padding(12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if selectedTab == "预设" {
                        presetTab
                    } else {
                        generalTab
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minWidth: 540, minHeight: 560)
        .background(BreatheStyle.background)
        .tint(BreatheStyle.accent)
    }

    // MARK: - 预设

    private var presetTab: some View {
        Group {
            heading("呼吸节奏", description: "选择适合当前时段的呼吸预设。")

            settingsGroup {
                HStack {
                    Text("默认预设")
                    Spacer()
                    Picker("默认预设", selection: bindingFor(\.defaultPreset)) {
                        Text("自动（按时段）").tag("auto")
                        ForEach(Preset.allCases, id: \.self) { preset in
                            Text(preset.displayName).tag(preset.rawValue)
                        }
                        Text("自定义…").tag("custom")
                    }
                    .labelsHidden()
                    .frame(width: 190)
                }
                .padding(14)

                if settingsManager.settings.defaultPreset != "custom" || customRatioError == nil {
                    Divider().padding(.horizontal, 14)
                    TimelineView(.periodic(from: .now, by: 60)) { _ in
                        presetSummary
                    }
                }
            }

            if settingsManager.settings.defaultPreset == "custom" {
                customRatioSection
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    sectionTitle("时段映射")
                    settingsGroup {
                        periodRow("早晨", time: "06:00 – 12:00", symbol: "sunrise", preset: .morning)
                        Divider().padding(.horizontal, 14)
                        periodRow("下午", time: "12:00 – 17:00", symbol: "sun.max", preset: .midday)
                        Divider().padding(.horizontal, 14)
                        periodRow("傍晚", time: "17:00 – 22:00", symbol: "sunset", preset: .evening)
                        Divider().padding(.horizontal, 14)
                        periodRow("夜间", time: "22:00 – 06:00", symbol: "moon", preset: .night)
                    }
                    Text("全部预设均为每分钟 6 次呼吸。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var presetSummary: some View {
        let config = BreathingConfig.fromCurrentSettings()
        return HStack(spacing: 18) {
            summaryValue(
                settingsManager.settings.defaultPreset == "auto" ? "当前预设" : "所选预设",
                value: config.presetName == "custom" ? "自定义" : config.presetName
            )
            Divider()
            summaryValue("吸气 / 呼气", value: "\(config.inhaleSeconds) / \(config.exhaleSeconds)", unit: "秒")
            Divider()
            summaryValue("练习时长", value: "\(config.durationSeconds / 60)", unit: "分钟")
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(14)
    }

    private var customRatioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("自定义比例")
            settingsGroup {
                HStack {
                    Text("吸气")
                    Spacer()
                    Stepper("\(settingsManager.settings.customInhaleSeconds) 秒",
                            value: bindingFor(\.customInhaleSeconds), in: RatioValidator.inhaleRange)
                        .fixedSize()
                        .accessibilityLabel("吸气秒数")
                }
                .padding(14)
                Divider().padding(.horizontal, 14)
                HStack {
                    Text("呼气")
                    Spacer()
                    Stepper("\(settingsManager.settings.customExhaleSeconds) 秒",
                            value: bindingFor(\.customExhaleSeconds), in: RatioValidator.exhaleRange)
                        .fixedSize()
                        .accessibilityLabel("呼气秒数")
                }
                .padding(14)
                Divider().padding(.horizontal, 14)
                HStack {
                    Text("练习时长")
                    Spacer()
                    Stepper("\(settingsManager.settings.customDurationMinutes) 分钟",
                            value: bindingFor(\.customDurationMinutes), in: 1...60)
                        .fixedSize()
                        .accessibilityLabel("练习时长（分钟）")
                }
                .padding(14)
            }
            if let error = customRatioError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                    .font(.caption)
            } else if let config = BreathingConfig(
                inhale: settingsManager.settings.customInhaleSeconds,
                exhale: settingsManager.settings.customExhaleSeconds,
                durationMinutes: settingsManager.settings.customDurationMinutes
            ) {
                Label("周期 \(config.cycleSeconds) 秒，实际时长 \(config.durationSeconds / 60) 分 \(config.durationSeconds % 60) 秒",
                      systemImage: "checkmark.circle")
                    .foregroundColor(BreatheStyle.accent)
                    .font(.caption)
            }
        }
    }

    private var customRatioError: String? {
        let result = RatioValidator.validate(
            inhale: settingsManager.settings.customInhaleSeconds,
            exhale: settingsManager.settings.customExhaleSeconds
        )
        if case .failure(let error) = result {
            return error.errorDescription
        }
        return nil
    }

    // MARK: - 通用

    private var generalTab: some View {
        Group {
            heading("通用", description: "声音、会话记录与启动选项。")

            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("音频")
                settingsGroup {
                    HStack {
                        settingLabel("声音提示", detail: "在吸气和呼气开始时播放提示音")
                        Spacer()
                        Toggle("声音提示", isOn: bindingFor(\.soundEnabled))
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    .padding(14)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("数据")
                settingsGroup {
                    HStack {
                        Text("记录会话日志")
                        Spacer()
                        Toggle("记录会话日志", isOn: bindingFor(\.logSessions))
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    .padding(14)
                    if settingsManager.settings.logSessions {
                        Divider().padding(.horizontal, 14)
                        HStack {
                            Text("日志路径")
                            Spacer()
                            Text("~/.config/breathe/sessions.csv")
                                .textSelection(.enabled)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(14)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("启动")
                settingsGroup {
                    if LaunchAtLoginManager.shared.isSupported {
                        HStack {
                            settingLabel("开机自动启动", detail: "登录 macOS 时启动 Breathe")
                            Spacer()
                            Toggle("开机自动启动", isOn: launchAtLoginBinding)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                        .padding(14)
                    } else {
                        Text("需要 macOS 13 或更高版本")
                            .foregroundColor(.secondary)
                            .padding(14)
                    }
                }
            }
        }
    }

    // MARK: - 布局

    private func heading(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.system(size: 20, weight: .semibold))
            Text(description).font(.subheadline).foregroundColor(.secondary)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.caption).foregroundColor(.secondary).padding(.leading, 3)
    }

    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BreatheStyle.surface)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.primary.opacity(0.08)))
    }

    private func settingLabel(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
            Text(detail).font(.caption).foregroundColor(.secondary)
        }
    }

    private func summaryValue(_ title: String, value: String, unit: String = "") -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption).foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(size: 17, weight: .medium)).monospacedDigit()
                    .foregroundColor(BreatheStyle.accent)
                if !unit.isEmpty {
                    Text(unit).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func periodRow(_ title: String, time: String, symbol: String, preset: Preset) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 19))
                .foregroundColor(BreatheStyle.accent).frame(width: 24)
            settingLabel(title, detail: time)
            Spacer()
            Text(preset.displayName).font(.caption).foregroundColor(.secondary)
                .frame(width: 65, alignment: .leading)
            VStack(alignment: .trailing, spacing: 5) {
                Text(preset.ratioString).monospacedDigit()
                Text("\(preset.durationMinutes) 分钟").font(.caption).foregroundColor(.secondary)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - 配置

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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
