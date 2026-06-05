import Foundation

/// 按时段自动选择预设
enum TimeOfDay {
    case morning    // 06:00-11:59 → balanced
    case afternoon  // 12:00-17:59 → extended
    case evening    // 18:00-21:59 → calm
    case night      // 22:00-05:59 → calm

    static func current() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<22: return .evening
        default: return .night
        }
    }

    var recommendedPreset: Preset {
        switch self {
        case .morning: return .balanced
        case .afternoon: return .extended
        case .evening: return .calm
        case .night: return .calm
        }
    }

    var displayName: String {
        switch self {
        case .morning: return "早晨"
        case .afternoon: return "下午"
        case .evening: return "傍晚"
        case .night: return "夜间"
        }
    }
}
