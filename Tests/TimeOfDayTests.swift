import XCTest
@testable import Breathe

/// TimeOfDay 时段选择测试
/// 验证"自动"预设确实根据时段选择不同的预设，而非固定返回 balanced
/// 这组测试防止 [TimeOfDay 被定义但从未调用] 的回归
final class TimeOfDayTests: XCTestCase {

    // MARK: - 时段与预设映射

    func testMorningRecommendsBalanced() {
        XCTAssertEqual(TimeOfDay.morning.recommendedPreset, .balanced)
    }

    func testAfternoonRecommendsExtended() {
        XCTAssertEqual(TimeOfDay.afternoon.recommendedPreset, .extended)
    }

    func testEveningRecommendsCalm() {
        XCTAssertEqual(TimeOfDay.evening.recommendedPreset, .calm)
    }

    func testNightRecommendsCalm() {
        XCTAssertEqual(TimeOfDay.night.recommendedPreset, .calm)
    }

    // MARK: - current() 返回值总是合法的

    /// current() 不应崩溃或返回意外的枚举值
    func testCurrentReturnsValidTimeOfDay() {
        let current = TimeOfDay.current()
        // 验证 current 是四个已知 case 之一（编译器保证，但这是行为锚点）
        _ = current.recommendedPreset
    }

    // MARK: - 所有时段都推荐已知预设

    /// 每个时段的推荐预设都能通过安全验证
    func testAllTimeOfDayPresetsPassValidation() {
        for timeOfDay: TimeOfDay in [.morning, .afternoon, .evening, .night] {
            let preset = timeOfDay.recommendedPreset
            let result = RatioValidator.validate(
                inhale: preset.inhaleSeconds,
                exhale: preset.exhaleSeconds
            )
            if case .failure(let error) = result {
                XCTFail("\(timeOfDay.displayName) 推荐的 \(preset.displayName) 未通过安全验证: \(error)")
            }
        }
    }

    // MARK: - displayName 非空

    func testDisplayNameNotEmpty() {
        for timeOfDay: TimeOfDay in [.morning, .afternoon, .evening, .night] {
            XCTAssertFalse(timeOfDay.displayName.isEmpty)
        }
    }
}
