import SwiftUI

/// 设置视图
struct SettingsView: View {
    @ObservedObject private var settingsManager = AppSettingsManager.shared

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
                    Text("morning (5-5, 10分钟)").tag("morning")
                    Text("midday (4-6, 20分钟)").tag("midday")
                    Text("evening (4-6, 15分钟)").tag("evening")
                    Text("night (3-7, 20分钟)").tag("night")
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
                    Text("morning").foregroundColor(.secondary)
                }
                HStack {
                    Label("下午 (12-17)", systemImage: "sun.max")
                    Spacer()
                    Text("midday").foregroundColor(.secondary)
                }
                HStack {
                    Label("傍晚 (17-22)", systemImage: "sunset")
                    Spacer()
                    Text("evening").foregroundColor(.secondary)
                }
                HStack {
                    Label("夜间 (22-6)", systemImage: "moon")
                    Spacer()
                    Text("night").foregroundColor(.secondary)
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
                    Toggle("开机自动启动", isOn: launchAtLoginBinding)
                } else {
                    Text("需要 macOS 13 或更高版本")
                        .foregroundColor(.secondary)
                        .font(.caption)
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

    /// 开机自启动：先注册系统服务，配置同步为系统最终状态（注册失败时开关回弹）
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

// MARK: - 预览

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
