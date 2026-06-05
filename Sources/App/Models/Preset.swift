import Foundation

/// 呼吸预设（全部 6.0 bpm）
enum Preset: String, CaseIterable, Codable {
    /// 5-5 比例，10 分钟（早晨推荐）
    case balanced
    /// 4-6 比例，15 分钟（傍晚推荐）
    case calm
    /// 4-6 比例，20 分钟（下午推荐）
    case extended

    /// 吸气秒数
    var inhaleSeconds: Int {
        switch self {
        case .balanced: return 5
        case .calm: return 4
        case .extended: return 4
        }
    }

    /// 呼气秒数
    var exhaleSeconds: Int {
        switch self {
        case .balanced: return 5
        case .calm: return 6
        case .extended: return 6
        }
    }

    /// 默认时长（分钟）
    var durationMinutes: Int {
        switch self {
        case .balanced: return 10
        case .calm: return 15
        case .extended: return 20
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

    /// 人类可读的显示名
    var displayName: String {
        switch self {
        case .balanced: return "balanced"
        case .calm: return "calm"
        case .extended: return "extended"
        }
    }

    /// 比例字符串，如 "5-5"
    var ratioString: String {
        "\(inhaleSeconds)-\(exhaleSeconds)"
    }
}
