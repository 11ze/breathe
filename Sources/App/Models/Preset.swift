import Foundation

/// 呼吸预设（全部 6.0 bpm）
/// 与上游 breathe-cli v1.11+ 的预设体系对齐
enum Preset: String, CaseIterable, Codable {
    /// 5-5 比例，10 分钟（06-12 点）
    case morning
    /// 4-6 比例，20 分钟（12-17 点）
    case midday
    /// 4-6 比例，15 分钟（17-22 点）
    case evening
    /// 3-7 比例，20 分钟（22-06 点）
    case night

    /// 吸气秒数
    var inhaleSeconds: Int {
        switch self {
        case .morning: return 5
        case .midday: return 4
        case .evening: return 4
        case .night: return 3
        }
    }

    /// 呼气秒数
    var exhaleSeconds: Int {
        switch self {
        case .morning: return 5
        case .midday: return 6
        case .evening: return 6
        case .night: return 7
        }
    }

    /// 默认时长（分钟）
    var durationMinutes: Int {
        switch self {
        case .morning: return 10
        case .midday: return 20
        case .evening: return 15
        case .night: return 20
        }
    }

    /// 一个完整呼吸周期的秒数
    var cycleSeconds: Int {
        inhaleSeconds + exhaleSeconds
    }

    /// 每分钟呼吸次数
    var breathsPerMinute: Double {
        60.0 / Double(cycleSeconds)
    }

    /// 界面显示名。CSV 与配置文件仍使用英文 rawValue。
    var displayName: String {
        switch self {
        case .morning: return "晨间"
        case .midday: return "午间"
        case .evening: return "晚间"
        case .night: return "深夜"
        }
    }

    /// 把历史记录与配置中的英文预设名转成中文显示名。
    /// 兼容旧版 CSV 的 balanced / calm / extended。
    static func displayName(for rawValue: String) -> String {
        switch rawValue {
        case "balanced": return Preset.morning.displayName
        case "extended": return Preset.midday.displayName
        case "calm": return Preset.evening.displayName
        case "custom": return "自定义"
        case "unknown": return "未知"
        default: return Preset(rawValue: rawValue)?.displayName ?? rawValue
        }
    }

    /// 比例字符串，如 "5-5"
    var ratioString: String {
        "\(inhaleSeconds)-\(exhaleSeconds)"
    }
}
