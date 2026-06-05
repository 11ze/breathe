import Foundation
import Combine

/// 呼吸阶段状态
enum BreathingPhase: Equatable {
    case idle
    case countdown(Int)        // 3-2-1 倒计时
    case inhale
    case exhale
    indirect case paused(BreathingPhase) // 暂停时记住当前阶段
}

/// 呼吸引擎 — 核心状态机
/// 移植自 breathe-cli 的 run_session() 循环，用 Timer (20Hz) 替代 Python 的 while+sleep
@MainActor
final class BreathingEngine: ObservableObject {
    static let shared = BreathingEngine()

    // MARK: - Published 状态

    /// 当前呼吸阶段
    @Published private(set) var phase: BreathingPhase = .idle
    /// 当前阶段进度 0.0~1.0（用于驱动圆环动画）
    @Published private(set) var phaseProgress: Double = 0.0
    /// 已完成的呼吸次数
    @Published private(set) var breathsCompleted: Int = 0
    /// 剩余秒数（整数，单调递减）
    @Published private(set) var remainingSeconds: Int = 0
    /// 总时长（秒）
    @Published private(set) var totalDurationSeconds: Int = 0
    /// 是否正在会话中
    @Published private(set) var isSessionActive: Bool = false

    // MARK: - 内部状态

    private var config: BreathingConfig?
    private var timer: Timer?
    private var phaseStartTime: Date = .distantPast
    private var breathingBase: Int = 0 // 已完成的呼吸周期总秒数
    private var sessionStartTime: Date = .distantPast

    /// 帧率 20Hz，与 breathe-cli 一致
    private let frameInterval: TimeInterval = 0.05

    // MARK: - 回调

    /// 吸气开始时触发（用于播放音频）
    var onInhaleStart: (() -> Void)?
    /// 呼气开始时触发（用于播放音频）
    var onExhaleStart: (() -> Void)?
    /// 会话完成时触发（用于通知和日志）
    var onSessionComplete: ((_ record: SessionRecord) -> Void)?

    // internal init 允许测试创建独立实例，不影响单例
    init() {}

    // MARK: - 公共接口

    /// 开始呼吸会话
    func start(config: BreathingConfig) {
        guard !isSessionActive else { return }
        self.config = config
        self.totalDurationSeconds = config.durationSeconds
        self.remainingSeconds = config.durationSeconds
        self.breathsCompleted = 0
        self.breathingBase = 0
        self.phaseProgress = 0.0
        self.isSessionActive = true
        self.sessionStartTime = Date()

        // 开始 3-2-1 倒计时
        phase = .countdown(3)
        startTimer()
    }

    /// 停止会话（用户主动）
    func stop() {
        guard isSessionActive else { return }
        let record = buildRecord(completed: false)
        cleanup()
        onSessionComplete?(record)
    }

    /// 暂停/继续
    func togglePause() {
        switch phase {
        case .inhale, .exhale:
            phase = .paused(phase)
            // 不停止 timer，暂停状态下继续 tick 但不推进状态
        case .paused:
            resume()
        default:
            break
        }
    }

    var isPaused: Bool {
        if case .paused = phase { return true }
        return false
    }

    // MARK: - 暂停/恢复

    private func resume() {
        guard case .paused = phase else { return }

        // 边界条件：如果 breathingBase >= duration，直接完成（移植自 breathe-cli）
        if let config = config, breathingBase >= config.durationSeconds {
            completeSession()
            return
        }

        // 恢复总是从吸气重新开始（与 breathe-cli 行为一致）
        phase = .inhale
        phaseStartTime = Date()
        onInhaleStart?()
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - 核心帧循环 (20Hz)

    private func tick() {
        switch phase {
        case .idle:
            return

        case .countdown(let remaining):
            tickCountdown(remaining: remaining)

        case .inhale:
            tickInhale()

        case .exhale:
            tickExhale()

        case .paused:
            // 暂停状态不推进，但保持 timer 运行以响应恢复
            break
        }
    }

    private func tickCountdown(remaining: Int) {
        let elapsed = Date().timeIntervalSince(phaseStartTime)
        let progress = elapsed / 1.0 // 每个倒计时数字 1 秒
        phaseProgress = progress

        if progress >= 1.0 {
            if remaining > 1 {
                phase = .countdown(remaining - 1)
                phaseStartTime = Date()
                phaseProgress = 0.0
            } else {
                // 倒计时结束，开始吸气
                beginInhale()
            }
        }
    }

    private func tickInhale() {
        guard let config = config else { return }
        let phaseElapsed = Date().timeIntervalSince(phaseStartTime)
        let phaseDuration = Double(config.inhaleSeconds)
        let progress = phaseElapsed / phaseDuration
        phaseProgress = min(progress, 1.0)

        updateRemainingSeconds()

        if progress >= 1.0 {
            // 吸气 → 呼气
            beginExhale(previousPhaseStart: phaseStartTime, phaseDuration: phaseDuration)
        }
    }

    private func tickExhale() {
        guard let config = config else { return }
        let phaseElapsed = Date().timeIntervalSince(phaseStartTime)
        let phaseDuration = Double(config.exhaleSeconds)
        let progress = phaseElapsed / phaseDuration
        phaseProgress = min(progress, 1.0)

        updateRemainingSeconds()

        if progress >= 1.0 {
            // 呼气完成 → 增加呼吸计数
            breathsCompleted += 1
            breathingBase = breathsCompleted * config.cycleSeconds

            // 检查会话是否完成
            if breathingBase >= config.durationSeconds {
                completeSession()
                return
            }

            // 呼气 → 吸气
            beginInhale(previousPhaseStart: phaseStartTime, phaseDuration: phaseDuration)
        }
    }

    // MARK: - 阶段转换

    private func beginInhale() {
        guard let config = config else { return }
        phase = .inhale
        phaseStartTime = Date()
        phaseProgress = 0.0
        onInhaleStart?()
    }

    /// 从上一阶段连续过渡到吸气
    private func beginInhale(previousPhaseStart: Date, phaseDuration: TimeInterval) {
        guard let config = config else { return }
        phase = .inhale
        // 保持时间连续性：phaseStartTime = 上一个阶段的理论起始 + 该阶段时长
        phaseStartTime = previousPhaseStart.addingTimeInterval(phaseDuration)
        phaseProgress = 0.0
        onInhaleStart?()
    }

    private func beginExhale(previousPhaseStart: Date, phaseDuration: TimeInterval) {
        guard let config = config else { return }
        phase = .exhale
        phaseStartTime = previousPhaseStart.addingTimeInterval(phaseDuration)
        phaseProgress = 0.0
        onExhaleStart?()
    }

    // MARK: - 剩余时间计算

    /// 移植自 breathe-cli 的剩余时间算术
    /// remaining = duration - breathingBase - int(phaseElapsed)
    /// INHALE: 不加 inhaleSeconds 偏移
    /// EXHALE: 加 inhaleSeconds 偏移
    private func updateRemainingSeconds() {
        guard let config = config else { return }
        let phaseElapsed = Date().timeIntervalSince(phaseStartTime)
        let cleanPhaseSeconds = Int(phaseElapsed)

        switch phase {
        case .inhale:
            remainingSeconds = max(0, config.durationSeconds - breathingBase - cleanPhaseSeconds)
        case .exhale:
            remainingSeconds = max(0, config.durationSeconds - breathingBase - config.inhaleSeconds - cleanPhaseSeconds)
        default:
            break
        }
    }

    // MARK: - 会话完成

    private func completeSession() {
        guard let config = config else { return }

        // 0.4 秒定格（移植自 breathe-cli 的视觉停顿）
        phaseProgress = 1.0
        remainingSeconds = 0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            guard let self = self else { return }
            let record = self.buildRecord(completed: true)
            self.cleanup()
            self.onSessionComplete?(record)
        }
    }

    // MARK: - 清理

    private func cleanup() {
        stopTimer()
        phase = .idle
        phaseProgress = 0.0
        isSessionActive = false
        config = nil
    }

    // MARK: - 记录构建

    private func buildRecord(completed: Bool) -> SessionRecord {
        let now = sessionStartTime
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: now)

        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: now)

        let actualSeconds: Int
        let completionPct: Int
        let status: String

        if completed {
            actualSeconds = totalDurationSeconds
            completionPct = 100
            status = "completed"
        } else {
            let elapsed = Int(Date().timeIntervalSince(sessionStartTime))
            actualSeconds = elapsed
            completionPct = totalDurationSeconds > 0 ? min(100, elapsed * 100 / totalDurationSeconds) : 0
            status = "ended early (user)"
        }

        return SessionRecord(
            date: date, time: time,
            preset: config?.presetName ?? "unknown",
            ratio: config?.ratioString ?? "?-?",
            durationTargetSeconds: totalDurationSeconds,
            durationActualSeconds: actualSeconds,
            breaths: breathsCompleted,
            completionPercent: completionPct,
            status: status
        )
    }
}
