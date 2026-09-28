import XCTest
@testable import Breathe

/// TimeOfDay 时段选择测试
/// 验证"自动"预设确实根据时段选择不同的预设
/// 时段边界与上游 breathe-cli 的 preset_for_hour 一致
final class TimeOfDayTests: XCTestCase {

    // MARK: - 时段与预设映射

    func testMorningRecommendsMorning() {
        XCTAssertEqual(TimeOfDay.morning.recommendedPreset, .morning)
    }

    func testMiddayRecommendsMidday() {
        XCTAssertEqual(TimeOfDay.midday.recommendedPreset, .midday)
    }

    func testEveningRecommendsEvening() {
        XCTAssertEqual(TimeOfDay.evening.recommendedPreset, .evening)
    }

    func testNightRecommendsNight() {
        XCTAssertEqual(TimeOfDay.night.recommendedPreset, .night)
    }

    // MARK: - 小时 → 时段边界（与上游 preset_for_hour 对齐）

    func testForHourBoundaries() {
        XCTAssertEqual(TimeOfDay.forHour(5), .night)
        XCTAssertEqual(TimeOfDay.forHour(6), .morning)
        XCTAssertEqual(TimeOfDay.forHour(11), .morning)
        XCTAssertEqual(TimeOfDay.forHour(12), .midday)
        XCTAssertEqual(TimeOfDay.forHour(16), .midday)
        XCTAssertEqual(TimeOfDay.forHour(17), .evening)
        XCTAssertEqual(TimeOfDay.forHour(21), .evening)
        XCTAssertEqual(TimeOfDay.forHour(22), .night)
        XCTAssertEqual(TimeOfDay.forHour(0), .night)
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
        for timeOfDay: TimeOfDay in [.morning, .midday, .evening, .night] {
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
        for timeOfDay: TimeOfDay in [.morning, .midday, .evening, .night] {
            XCTAssertFalse(timeOfDay.displayName.isEmpty)
        }
    }
}
