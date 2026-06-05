import XCTest
@testable import Breathe

/// BreathingConfig 配置测试
/// 重点验证时长取整算术——这是从 breathe-cli 移植的核心逻辑
final class BreathingConfigTests: XCTestCase {

    // MARK: - 从预设创建

    func testFromPresetBalanced() {
        let config = BreathingConfig(preset: .balanced)
        XCTAssertEqual(config.inhaleSeconds, 5)
        XCTAssertEqual(config.exhaleSeconds, 5)
        XCTAssertEqual(config.durationSeconds, 600) // 10 分钟 = 600 秒
        XCTAssertEqual(config.cycleSeconds, 10)
        XCTAssertEqual(config.totalBreaths, 60)
        XCTAssertEqual(config.presetName, "balanced")
    }

    func testFromPresetCalm() {
        let config = BreathingConfig(preset: .calm)
        XCTAssertEqual(config.durationSeconds, 900) // 15 分钟 = 900 秒
        XCTAssertEqual(config.totalBreaths, 90)
    }

    // MARK: - 时长向上取整（核心算术）

    /// 这是 breathe-cli 的关键算法：
    /// duration = -(-totalSeconds // cycle) * cycle
    /// 当 totalSeconds 恰好是 cycle 的整数倍时，不需要调整
    func testExactMultipleNoRounding() {
        // 600 / 10 = 60，恰好整除
        XCTAssertEqual(BreathingConfig.roundUpToCycleMultiple(600, cycleSeconds: 10), 600)
    }

    /// 当 totalSeconds 不是 cycle 的整数倍时，向上取整
    /// 这确保最后一个呼吸周期总是完整的，不会出现半个呼吸
    func testRoundsUpToNextMultiple() {
        // 300 / 11 = 27.27... → 向上到 308 (28 × 11)
        XCTAssertEqual(BreathingConfig.roundUpToCycleMultiple(300, cycleSeconds: 11), 308)
    }

    func testRoundsUpOneSecondShort() {
        // 599 / 10 → 600
        XCTAssertEqual(BreathingConfig.roundUpToCycleMultiple(599, cycleSeconds: 10), 600)
    }

    func testZeroDuration() {
        XCTAssertEqual(BreathingConfig.roundUpToCycleMultiple(0, cycleSeconds: 10), 0)
    }

    func testAlreadyMultiple() {
        // 330 / 11 = 30，恰好整除
        XCTAssertEqual(BreathingConfig.roundUpToCycleMultiple(330, cycleSeconds: 11), 330)
    }

    // MARK: - 自定义配置

    func testCustomValidConfig() {
        let config = BreathingConfig(inhale: 5, exhale: 5, durationMinutes: 10)
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.presetName, "custom")
        XCTAssertEqual(config?.durationSeconds, 600)
    }

    func testCustomInvalidRatioReturns() {
        // 吸气过短
        let config1 = BreathingConfig(inhale: 2, exhale: 5, durationMinutes: 10)
        XCTAssertNil(config1, "吸气 2 秒应被拒绝")
    }

    func testCustomDurationOutOfRange() {
        let config1 = BreathingConfig(inhale: 5, exhale: 5, durationMinutes: 0)
        XCTAssertNil(config1, "时长 0 分钟应被拒绝")

        let config2 = BreathingConfig(inhale: 5, exhale: 5, durationMinutes: 61)
        XCTAssertNil(config2, "时长 61 分钟应被拒绝")
    }

    func testCustomDurationRoundsUp() {
        // 5 分钟 = 300 秒，11 秒周期 → 308 秒 (28 × 11)
        let config = BreathingConfig(inhale: 5, exhale: 6, durationMinutes: 5)
        XCTAssertEqual(config?.durationSeconds, 308)
        XCTAssertEqual(config?.totalBreaths, 28) // 308 / 11
    }

    // MARK: - ratioString

    func testRatioString() {
        let config = BreathingConfig(preset: .calm)
        XCTAssertEqual(config.ratioString, "4-6")
    }
}
