import XCTest
@testable import Breathe

/// AppSettings 配置模型测试
/// 验证序列化/反序列化的正确性和默认值的安全性
final class AppSettingsTests: XCTestCase {

    // MARK: - 默认值

    /// 默认值决定了首次安装时的用户体验
    /// auto 预设按时段自动选择，soundEnabled=true 保证新用户能听到引导音
    func testDefaultValues() {
        let settings = AppSettings()
        XCTAssertEqual(settings.defaultPreset, "auto")
        XCTAssertEqual(settings.customInhaleSeconds, 5)
        XCTAssertEqual(settings.customExhaleSeconds, 5)
        XCTAssertEqual(settings.customDurationMinutes, 10)
        XCTAssertTrue(settings.soundEnabled)
        XCTAssertTrue(settings.logSessions)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.dailyReminderEnabled)
        XCTAssertEqual(settings.dailyReminderTime, "08:00")
    }

    // MARK: - JSON 序列化 round-trip

    func testJsonRoundTrip() {
        var settings = AppSettings()
        settings.defaultPreset = "evening"
        settings.soundEnabled = false
        settings.customInhaleSeconds = 4
        settings.customExhaleSeconds = 6
        settings.dailyReminderEnabled = true
        settings.dailyReminderTime = "09:30"

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try! encoder.encode(settings)

        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(AppSettings.self, from: data)

        XCTAssertEqual(settings, decoded)
    }

    // MARK: - 旧版预设名迁移

    /// 上游 v1.11 把预设改为 morning/midday/evening/night，
    /// 旧配置里的 balanced/calm/extended 按参数对应迁移，不丢失用户选择
    func testLegacyPresetNamesMigrateOnDecoding() {
        let expectations = [
            "balanced": "morning",   // 5-5, 10min
            "calm": "evening",       // 4-6, 15min
            "extended": "midday",    // 4-6, 20min
        ]
        for (legacy, migrated) in expectations {
            let json = "{\"defaultPreset\": \"\(legacy)\"}"
            let settings = try! JSONDecoder().decode(AppSettings.self, from: json.data(using: .utf8)!)
            XCTAssertEqual(settings.defaultPreset, migrated, "\(legacy) 应迁移为 \(migrated)")
        }
    }

    /// 新预设名和 auto/custom 不受迁移影响
    func testCurrentPresetNamesPassThrough() {
        for name in ["auto", "custom", "morning", "midday", "evening", "night"] {
            let json = "{\"defaultPreset\": \"\(name)\"}"
            let settings = try! JSONDecoder().decode(AppSettings.self, from: json.data(using: .utf8)!)
            XCTAssertEqual(settings.defaultPreset, name)
        }
    }

    // MARK: - 部分字段反序列化

    /// 配置文件可能只有部分字段（比如用户手动编辑删除了某些行）
    /// 缺失字段应使用默认值而非崩溃
    func testPartialJsonDecoding() {
        let json = """
        {
            "defaultPreset": "midday",
            "soundEnabled": false
        }
        """
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let settings = try! decoder.decode(AppSettings.self, from: data)

        XCTAssertEqual(settings.defaultPreset, "midday")
        XCTAssertFalse(settings.soundEnabled)
        // 其余字段应为默认值
        XCTAssertEqual(settings.customInhaleSeconds, 5)
        XCTAssertTrue(settings.logSessions)
    }

    // MARK: - 空对象反序列化

    func testEmptyJsonDecoding() {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let settings = try! decoder.decode(AppSettings.self, from: data)

        XCTAssertEqual(settings, AppSettings())
    }

    // MARK: - Equatable

    func testEquatable() {
        let a = AppSettings()
        var b = AppSettings()
        XCTAssertEqual(a, b)
        b.soundEnabled = false
        XCTAssertNotEqual(a, b)
    }
}
