import SwiftUI

/// 设置视图
struct SettingsView: View {
    @ObservedObject private var settingsManager = AppSettingsManager.shared
    @ObservedObject private var audioManager = AudioManager.shared

    var body: some View {
        TabView {
            presetTab
                .tabItem { Label("预设", systemImage: "wind") }
            generalTab
                .tabItem { Label("通用", systemImage: "gearshape") }
        }
        .frame(width: 450, height: 350)
    }

    // MARK: - 预设标签页

    private var presetTab: some View {
        Form {
            Section("默认预设") {
                Picker("模式", selection: bindingFor(\.defaultPreset)) {
                    Text("自动（按时段）").tag("auto")
                    Text("balanced (5-5, 10分钟)").tag("balanced")
                    Text("calm (4-6, 15分钟)").tag("calm")
                    Text("extended (4-6, 20分钟)").tag("extended")
                    Text("自定义...").tag("custom")
                }
            }

            if settingsManager.settings.defaultPreset == "custom" {
                Section("自定义比例") {
                    customRatioSection
                }
            }

            Section("时段映射") {
                HStack {
                    Label("早晨 (6-12)", systemImage: "sunrise")
                    Spacer()
                    Text("balanced").foregroundColor(.secondary)
                }
                HStack {
                    Label("下午 (12-18)", systemImage: "sun.max")
                    Spacer()
                    Text("extended").foregroundColor(.secondary)
                }
                HStack {
                    Label("傍晚 (18-22)", systemImage: "sunset")
                    Spacer()
                    Text("calm").foregroundColor(.secondary)
                }
                HStack {
                    Label("夜间 (22-6)", systemImage: "moon")
                    Spacer()
                    Text("calm").foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }

    private var customRatioSection: some View {
        Group {
            HStack {
                Stepper(
                    "吸气 \(settingsManager.settings.customInhaleSeconds) 秒",
                    value: bindingFor(\.customInhaleSeconds),
                    in: RatioValidator.inhaleRange
                )
            }
            HStack {
                Stepper(
                    "呼气 \(settingsManager.settings.customExhaleSeconds) 秒",
                    value: bindingFor(\.customExhaleSeconds),
                    in: RatioValidator.exhaleRange
                )
            }
            HStack {
                Stepper(
                    "时长 \(settingsManager.settings.customDurationMinutes) 分钟",
                    value: bindingFor(\.customDurationMinutes),
                    in: 1...60
                )
            }

            // 安全校验反馈
            if let error = customRatioError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                    .font(.caption)
            } else {
                let config = BreathingConfig(
                    inhale: settingsManager.settings.customInhaleSeconds,
                    exhale: settingsManager.settings.customExhaleSeconds,
                    durationMinutes: settingsManager.settings.customDurationMinutes
                )
                if let config = config {
                    Label(
                        "周期 \(config.cycleSeconds)s，实际时长 \(config.durationSeconds / 60) 分 \(config.durationSeconds % 60) 秒",
                        systemImage: "checkmark.circle"
                    )
                    .foregroundColor(.green)
                    .font(.caption)
                }
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

    // MARK: - 通用标签页

    private var generalTab: some View {
        Form {
            Section("音频") {
                Toggle("声音提示", isOn: bindingFor(\.soundEnabled))
            }

            Section("数据") {
                Toggle("记录会话日志", isOn: bindingFor(\.logSessions))

                if settingsManager.settings.logSessions {
                    HStack {
                        Text("日志路径")
                        Spacer()
                        Text("~/.config/breathe/sessions.csv")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }

            Section("启动") {
                if LaunchAtLoginManager.shared.isSupported {
                    Toggle("开机自动启动", isOn: bindingFor(\.launchAtLogin))
                } else {
                    Text("需要 macOS 13 或更高版本")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }

            Section("提醒") {
                Toggle("每日提醒", isOn: bindingFor(\.dailyReminderEnabled))
                if settingsManager.settings.dailyReminderEnabled {
                    TextField("提醒时间", text: bindingFor(\.dailyReminderTime))
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
    }

    // MARK: - Binding 辅助

    private func bindingFor<T>(_ keyPath: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { settingsManager.settings[keyPath: keyPath] },
            set: { newValue in
                settingsManager.settings[keyPath: keyPath] = newValue
                settingsManager.save()
            }
        )
    }
}

// MARK: - 预览

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
