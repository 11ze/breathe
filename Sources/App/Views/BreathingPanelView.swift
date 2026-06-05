import SwiftUI

/// 呼吸面板主视图
/// 布局：头部信息 → 呼吸圆环 → 阶段标签 → 进度条 → 控制按钮
struct BreathingPanelView: View {
    @ObservedObject private var engine = BreathingEngine.shared
    @ObservedObject private var audioManager = AudioManager.shared

    var body: some View {
        VStack(spacing: 16) {
            if engine.isSessionActive {
                activeSessionView
            } else {
                idleView
            }
        }
        .frame(width: 280, height: 420)
        .padding(20)
    }

    // MARK: - 空闲视图

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Breathe")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            BreathingCircle(phase: .idle, progress: 0)

            Text(presetDescription)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: startBreathing) {
                Label("开始呼吸", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("b", modifiers: .command)

            Spacer()
        }
    }

    // MARK: - 活跃会话视图

    private var activeSessionView: some View {
        VStack(spacing: 12) {
            // 头部信息：预设 · 比例 · 剩余时间
            headerView

            // 呼吸圆环
            BreathingCircle(phase: engine.phase, progress: engine.phaseProgress)

            // 阶段标签 + 倒计时
            phaseLabelView

            // 进度条
            progressView

            // 控制按钮
            controlsView
        }
    }

    // MARK: - 头部

    private var headerView: some View {
        HStack {
            Text(headerText)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(formatTime(engine.remainingSeconds))
                .font(.caption.monospacedDigit())
                .foregroundColor(.secondary)
        }
    }

    private var headerText: String {
        switch engine.phase {
        case .countdown(let n):
            return "准备..."
        default:
            return "◎ \(engine.breathsCompleted) 次呼吸"
        }
    }

    // MARK: - 阶段标签

    private var phaseLabelView: some View {
        VStack(spacing: 4) {
            Text(phaseText)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(phaseColor)

            if case .countdown(let n) = engine.phase {
                Text("\(n)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            } else if engine.isSessionActive {
                Text(phaseCountdownText)
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .frame(height: 60)
    }

    private var phaseText: String {
        switch engine.phase {
        case .idle: return ""
        case .countdown: return "准备"
        case .inhale: return "吸气"
        case .exhale: return "呼气"
        case .paused: return "已暂停"
        }
    }

    private var phaseColor: Color {
        switch engine.phase {
        case .inhale: return .cyan
        case .exhale: return .green
        case .paused: return .orange
        default: return .primary
        }
    }

    private var phaseCountdownText: String {
        switch engine.phase {
        case .inhale, .exhale:
            let remaining = Int(ceil(1.0 - engine.phaseProgress))
            return "\(max(0, remaining))s"
        case .paused:
            return "‖"
        default:
            return ""
        }
    }

    // MARK: - 进度条

    private var progressView: some View {
        ProgressView(
            value: Double(engine.totalDurationSeconds - engine.remainingSeconds),
            total: Double(max(1, engine.totalDurationSeconds))
        )
        .progressViewStyle(.linear)
        .tint(.cyan)
    }

    // MARK: - 控制按钮

    private var controlsView: some View {
        HStack(spacing: 16) {
            // 暂停/继续
            Button(action: { engine.togglePause() }) {
                Image(systemName: engine.isPaused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(!canPause)
            .keyboardShortcut(.space, modifiers: [])

            // 静音
            Button(action: { audioManager.toggleMute() }) {
                Image(systemName: audioManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            // 停止
            Button(action: { engine.stop() }) {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .foregroundColor(.red)
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    private var canPause: Bool {
        switch engine.phase {
        case .inhale, .exhale, .paused:
            return true
        default:
            return false
        }
    }

    // MARK: - 辅助

    private var presetDescription: String {
        let settings = AppSettingsManager.shared.settings
        if settings.defaultPreset == "auto" {
            return "自动 · 按时段选择预设"
        }
        return "\(settings.defaultPreset) · 点击开始"
    }

    private func startBreathing() {
        let settings = AppSettingsManager.shared.settings
        let config: BreathingConfig

        if settings.defaultPreset == "custom" {
            guard let custom = BreathingConfig(
                inhale: settings.customInhaleSeconds,
                exhale: settings.customExhaleSeconds,
                durationMinutes: settings.customDurationMinutes
            ) else {
                // 自定义参数无效时 fallback 到 balanced
                config = BreathingConfig(preset: .balanced)
                engine.start(config: config)
                return
            }
            config = custom
        } else if let preset = Preset(rawValue: settings.defaultPreset) {
            config = BreathingConfig(preset: preset)
        } else {
            // auto 或未知值 → balanced
            config = BreathingConfig(preset: .balanced)
        }

        engine.start(config: config)
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - 预览

struct BreathingPanelView_Previews: PreviewProvider {
    static var previews: some View {
        BreathingPanelView()
            .background(Color(nsColor: .windowBackgroundColor))
    }
}
