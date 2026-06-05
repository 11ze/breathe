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
}
