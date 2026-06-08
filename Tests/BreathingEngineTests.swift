import XCTest
@testable import Breathe

/// BreathingEngine 核心状态机测试
/// 引擎是 @MainActor 隔离的，测试类也需 @MainActor
/// 这些测试验证引擎的算术正确性（剩余时间、周期对齐）和行为正确性（暂停恢复、会话完成）
@MainActor
final class BreathingEngineTests: XCTestCase {

    var engine: BreathingEngine!

    override func setUp() {
        super.setUp()
        engine = BreathingEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - 初始状态

    func testInitialState() {
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.phaseProgress, 0.0)
        XCTAssertEqual(engine.breathsCompleted, 0)
        XCTAssertEqual(engine.remainingSeconds, 0)
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isPaused)
    }

    // MARK: - 开始会话

    func testStartSetsInitialState() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)

        XCTAssertTrue(engine.isSessionActive)
        XCTAssertEqual(engine.phase, .countdown(3))
        XCTAssertEqual(engine.totalDurationSeconds, 600)
        XCTAssertEqual(engine.remainingSeconds, 600)
        XCTAssertEqual(engine.breathsCompleted, 0)
    }

    func testStartWhileActiveIsIgnored() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)

        let config2 = BreathingConfig(preset: .calm)
        engine.start(config: config2)
        XCTAssertEqual(engine.totalDurationSeconds, 600, "不应被第二次 start 覆盖")
    }

    // MARK: - 停止会话

    func testStopCleansUp() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)
        engine.stop()

        XCTAssertEqual(engine.phase, .idle)
        XCTAssertFalse(engine.isSessionActive)
    }

    func testStopWhileIdleIsIgnored() {
        engine.stop()
        XCTAssertEqual(engine.phase, .idle)
    }

    // MARK: - 停止触发回调

    func testStopTriggersCallbackWithEndedEarly() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)

        var receivedRecord: SessionRecord?
        engine.onSessionComplete = { record in
            receivedRecord = record
        }

        engine.stop()

        XCTAssertNotNil(receivedRecord)
        XCTAssertEqual(receivedRecord?.status, "ended early (user)")
        XCTAssertEqual(receivedRecord?.preset, "balanced")
        XCTAssertEqual(receivedRecord?.ratio, "5-5")
        XCTAssertEqual(receivedRecord?.durationTargetSeconds, 600)
    }

    // MARK: - 暂停/恢复

    func testPauseFromCountdownDoesNothing() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)

        // 倒计时阶段不能暂停
        engine.togglePause()
        XCTAssertEqual(engine.phase, .countdown(3))
    }

    func testIsPausedReturnsFalseWhenNotPaused() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)
        XCTAssertFalse(engine.isPaused)
    }

    // MARK: - AudioManager 集成

    func testAudioManagerToggleMute() {
        let audioManager = AudioManager.shared
        let wasMuted = audioManager.isMuted
        audioManager.toggleMute()
        XCTAssertEqual(audioManager.isMuted, !wasMuted)
        audioManager.toggleMute() // 恢复
    }

    func testAudioManagerSetMuted() {
        let audioManager = AudioManager.shared
        audioManager.setMuted(true)
        XCTAssertTrue(audioManager.isMuted)
        audioManager.setMuted(false)
        XCTAssertFalse(audioManager.isMuted)
    }

    // MARK: - BreathingConfig 集成

    /// 所有预设的 durationSeconds 都是 cycleSeconds 的整数倍
    /// 这保证引擎能精确完成所有呼吸周期，不会出现半个呼吸
    func testAllPresetDurationsAreCycleMultiples() {
        for preset in Preset.allCases {
            let config = BreathingConfig(preset: preset)
            XCTAssertEqual(
                config.durationSeconds % config.cycleSeconds, 0,
                "\(preset.displayName): \(config.durationSeconds) 不能被 \(config.cycleSeconds) 整除"
            )
        }
    }

    func testConfigTotalBreathsCalculation() {
        for preset in Preset.allCases {
            let config = BreathingConfig(preset: preset)
            XCTAssertEqual(
                config.totalBreaths,
                config.durationSeconds / config.cycleSeconds
            )
        }
    }

    // MARK: - 会话记录包含正确信息

    func testStoppedSessionRecordFormat() {
        let config = BreathingConfig(preset: .calm)
        engine.start(config: config)

        var receivedRecord: SessionRecord?
        engine.onSessionComplete = { record in
            receivedRecord = record
        }
        engine.stop()

        XCTAssertNotNil(receivedRecord)
        XCTAssertEqual(receivedRecord?.preset, "calm")
        XCTAssertEqual(receivedRecord?.ratio, "4-6")
        XCTAssertEqual(receivedRecord?.durationTargetSeconds, 900)
    }

    // MARK: - 单例

    func testSharedSingleton() {
        XCTAssertTrue(BreathingEngine.shared === BreathingEngine.shared)
    }

    // MARK: - onSessionStart 回调

    /// 验证 start() 触发 onSessionStart 回调
    /// 这个回调驱动菜单栏图标的更新，如果没触发，图标不会变
    func testOnSessionStartCallbackFiredOnStart() {
        let config = BreathingConfig(preset: .balanced)

        var startFired = false
        engine.onSessionStart = {
            startFired = true
        }

        engine.start(config: config)

        XCTAssertTrue(startFired, "start() 应该触发 onSessionStart 回调")
    }

    /// 验证 stop() 不触发 onSessionStart（只有 start 才触发）
    func testOnSessionStartNotFiredOnStop() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)

        var startCount = 0
        engine.onSessionStart = {
            startCount += 1
        }

        engine.stop()

        XCTAssertEqual(startCount, 0, "stop() 不应触发 onSessionStart")
    }

    // MARK: - 异步状态转换

    /// 验证 3 秒倒计时后引擎自动进入吸气阶段
    /// 如果引擎 timer 不工作或 phaseStartTime 未正确初始化，此测试会失败
    func testCountdownTransitionsToInhale() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)
        XCTAssertEqual(engine.phase, .countdown(3))

        let expectation = expectation(description: "倒计时结束进入吸气阶段")

        // 用 Timer 轮询，避免 DispatchQueue.main.asyncAfter 的时序问题
        var elapsed = 0.0
        let pollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            elapsed += 0.1
            if case .inhale = self.engine.phase {
                t.invalidate()
                expectation.fulfill()
            } else if elapsed > 5.0 {
                t.invalidate()
                XCTFail("5 秒后仍未进入吸气阶段，当前: \(self.engine.phase)")
            }
        }
        RunLoop.main.add(pollTimer, forMode: .common)

        waitForExpectations(timeout: 6) { _ in
            pollTimer.invalidate()
        }
    }

    /// 验证吸气阶段 phaseProgress 持续增长
    /// 这是呼吸动画的核心驱动——如果 progress 不变，SwiftUI 圆环就不会动
    func testPhaseProgressChangesDuringInhale() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)

        let expectation = expectation(description: "吸气阶段 progress 发生变化")

        // 先等倒计时结束
        var countdownDone = false
        var initialProgress: Double?

        let pollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }

            if !countdownDone {
                if case .inhale = self.engine.phase {
                    countdownDone = true
                    initialProgress = self.engine.phaseProgress
                }
                return
            }

            // 吸气阶段中，progress 应该 > 初始值
            let currentProgress = self.engine.phaseProgress
            if currentProgress > (initialProgress ?? 0) + 0.05 {
                t.invalidate()
                expectation.fulfill()
            }
        }
        RunLoop.main.add(pollTimer, forMode: .common)

        waitForExpectations(timeout: 8) { _ in
            pollTimer.invalidate()
        }
    }

    /// 验证吸气→呼气的自动转换
    /// 完整的呼吸循环才能让用户看到"膨胀-收缩"动画
    func testInhaleTransitionsToExhale() {
        let config = BreathingConfig(preset: .balanced)
        engine.start(config: config)

        let expectation = expectation(description: "吸气结束后进入呼气阶段")

        var phaseLog: [String] = []

        let pollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }

            switch self.engine.phase {
            case .exhale:
                // 确保经过了吸气阶段
                if phaseLog.contains("inhale") {
                    t.invalidate()
                    expectation.fulfill()
                }
            case .inhale:
                if !phaseLog.contains("inhale") {
                    phaseLog.append("inhale")
                }
            default:
                break
            }
        }
        RunLoop.main.add(pollTimer, forMode: .common)

        waitForExpectations(timeout: 15) { _ in
            pollTimer.invalidate()
        }
    }
}
