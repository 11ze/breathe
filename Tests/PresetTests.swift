import XCTest
@testable import Breathe

/// 预设不变量测试
/// 这些不变量确保所有预设都是安全的（呼吸频率、周期、时长都在合理范围内）
final class PresetTests: XCTestCase {

    // MARK: - 全部 6.0 bpm 不变量

    /// 共振呼吸的科学依据是 ~6 次/分钟，所有预设必须满足这个频率
    /// 偏离此频率的训练效果会大打折扣
    func testAllPresetsAre6BPM() {
        for preset in Preset.allCases {
            XCTAssertEqual(
                preset.breathsPerMinute, 6.0,
                "\(preset.displayName) 的 bpm 不是 6.0"
            )
        }
    }

    // MARK: - 周期 ≥ 8 秒

    func testAllPresetsCycleAtLeast8Seconds() {
        for preset in Preset.allCases {
            XCTAssertGreaterThanOrEqual(
                preset.cycleSeconds, 8,
                "\(preset.displayName) 周期不足 8 秒"
            )
        }
    }

    // MARK: - 时长可被周期整除

    /// 如果时长不能被周期整除，最后一个呼吸会被截断，用户体验差
    func testAllPresetsDurationDivisibleByCycle() {
        for preset in Preset.allCases {
            let totalSeconds = preset.durationMinutes * 60
            XCTAssertEqual(
                totalSeconds % preset.cycleSeconds, 0,
                "\(preset.displayName): \(totalSeconds) 秒不能被 \(preset.cycleSeconds) 秒整除"
            )
        }
    }

    // MARK: - 吸气/呼气在安全范围内

    func testAllPresetsPassRatioValidation() {
        for preset in Preset.allCases {
            let result = RatioValidator.validate(inhale: preset.inhaleSeconds, exhale: preset.exhaleSeconds)
            if case .failure(let error) = result {
                XCTFail("\(preset.displayName) 预设未通过安全验证: \(error)")
            }
        }
    }

    // MARK: - 各预设具体值

    func testMorningValues() {
        let p = Preset.morning
        XCTAssertEqual(p.inhaleSeconds, 5)
        XCTAssertEqual(p.exhaleSeconds, 5)
        XCTAssertEqual(p.durationMinutes, 10)
        XCTAssertEqual(p.cycleSeconds, 10)
        XCTAssertEqual(p.ratioString, "5-5")
    }

    func testMiddayValues() {
        let p = Preset.midday
        XCTAssertEqual(p.inhaleSeconds, 4)
        XCTAssertEqual(p.exhaleSeconds, 6)
        XCTAssertEqual(p.durationMinutes, 20)
        XCTAssertEqual(p.cycleSeconds, 10)
        XCTAssertEqual(p.ratioString, "4-6")
    }

    func testEveningValues() {
        let p = Preset.evening
        XCTAssertEqual(p.inhaleSeconds, 4)
        XCTAssertEqual(p.exhaleSeconds, 6)
        XCTAssertEqual(p.durationMinutes, 15)
        XCTAssertEqual(p.cycleSeconds, 10)
        XCTAssertEqual(p.ratioString, "4-6")
    }

    func testNightValues() {
        let p = Preset.night
        XCTAssertEqual(p.inhaleSeconds, 3)
        XCTAssertEqual(p.exhaleSeconds, 7)
        XCTAssertEqual(p.durationMinutes, 20)
        XCTAssertEqual(p.cycleSeconds, 10)
        XCTAssertEqual(p.ratioString, "3-7")
    }

    // MARK: - CaseIterable 完整性

    func testAllCases() {
        XCTAssertEqual(Preset.allCases.count, 4)
        XCTAssertEqual(Preset.allCases, [.morning, .midday, .evening, .night])
    }

    // MARK: - 中文显示名

    /// 界面统一显示中文；CSV 与 settings.json 继续使用英文 rawValue。
    func testDisplayNameMapsCurrentAndLegacyIDs() {
        XCTAssertEqual(Preset.morning.displayName, "晨间")
        XCTAssertEqual(Preset.midday.displayName, "午间")
        XCTAssertEqual(Preset.evening.displayName, "晚间")
        XCTAssertEqual(Preset.night.displayName, "深夜")

        XCTAssertEqual(Preset.displayName(for: "morning"), "晨间")
        XCTAssertEqual(Preset.displayName(for: "midday"), "午间")
        XCTAssertEqual(Preset.displayName(for: "evening"), "晚间")
        XCTAssertEqual(Preset.displayName(for: "night"), "深夜")
        XCTAssertEqual(Preset.displayName(for: "balanced"), "晨间")
        XCTAssertEqual(Preset.displayName(for: "extended"), "午间")
        XCTAssertEqual(Preset.displayName(for: "calm"), "晚间")
        XCTAssertEqual(Preset.displayName(for: "custom"), "自定义")
        XCTAssertEqual(Preset.displayName(for: "unknown"), "未知")
        XCTAssertEqual(Preset.displayName(for: "weird"), "weird")
    }

}
