import Foundation

/// 按时段自动选择预设（与上游 breathe-cli 的 preset_for_hour 一致）
enum TimeOfDay {
    case morning    // 06:00-11:59
    case midday     // 12:00-16:59
    case evening    // 17:00-21:59
    case night      // 22:00-05:59

    static func current() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        return forHour(hour)
    }

    static func forHour(_ hour: Int) -> TimeOfDay {
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .midday
        case 17..<22: return .evening
        default: return .night
        }
    }

    var recommendedPreset: Preset {
        switch self {
        case .morning: return .morning
        case .midday: return .midday
        case .evening: return .evening
        case .night: return .night
        }
    }

    var displayName: String {
        switch self {
        case .morning: return "早晨"
        case .midday: return "下午"
        case .evening: return "傍晚"
        case .night: return "夜间"
        }
    }
}
