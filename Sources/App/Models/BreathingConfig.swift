import Foundation

/// 呼吸会话配置
struct BreathingConfig: Equatable {
    /// 吸气秒数
    let inhaleSeconds: Int
    /// 呼气秒数
    let exhaleSeconds: Int
    /// 目标时长（秒，已向上取整到完整呼吸周期）
    let durationSeconds: Int
    /// 预设名称（用于日志记录）
    let presetName: String

    /// 从预设创建配置，时长向上取整到完整呼吸周期
    init(preset: Preset) {
        self.inhaleSeconds = preset.inhaleSeconds
        self.exhaleSeconds = preset.exhaleSeconds
        self.presetName = preset.rawValue
        let targetSeconds = preset.durationMinutes * 60
        self.durationSeconds = Self.roundUpToCycleMultiple(targetSeconds, cycleSeconds: preset.cycleSeconds)
    }

    /// 从自定义参数创建配置，需通过安全验证
    init?(inhale: Int, exhale: Int, durationMinutes: Int) {
        guard case .success = RatioValidator.validate(inhale: inhale, exhale: exhale) else {
            return nil
        }
        guard (1...60).contains(durationMinutes) else {
            return nil
        }
        self.inhaleSeconds = inhale
        self.exhaleSeconds = exhale
        self.presetName = "custom"
        let targetSeconds = durationMinutes * 60
        let cycle = inhale + exhale
        self.durationSeconds = Self.roundUpToCycleMultiple(targetSeconds, cycleSeconds: cycle)
    }

    /// 一个完整呼吸周期的秒数
    var cycleSeconds: Int {
        inhaleSeconds + exhaleSeconds
    }

    /// 总呼吸次数
    var totalBreaths: Int {
        durationSeconds / cycleSeconds
    }

    /// 比例字符串
    var ratioString: String {
        "\(inhaleSeconds)-\(exhaleSeconds)"
    }

    /// 根据当前设置创建配置（供菜单项和面板按钮共用）
    @MainActor static func fromCurrentSettings() -> BreathingConfig {
        let settings = AppSettingsManager.shared.settings
        if settings.defaultPreset == "auto" {
            return BreathingConfig(preset: TimeOfDay.current().recommendedPreset)
        } else if settings.defaultPreset == "custom" {
            return BreathingConfig(
                inhale: settings.customInhaleSeconds,
                exhale: settings.customExhaleSeconds,
                durationMinutes: settings.customDurationMinutes
            ) ?? BreathingConfig(preset: .balanced)
        } else if let preset = Preset(rawValue: settings.defaultPreset) {
            return BreathingConfig(preset: preset)
        } else {
            return BreathingConfig(preset: .balanced)
        }
    }

    /// 向上取整到呼吸周期的整数倍
    /// Python 的 `-(-a // b) * b` 用 floor division，Swift 的 `/` 是 truncating division
    /// 等价的 Swift 写法：`(a + b - 1) / b * b`
    static func roundUpToCycleMultiple(_ totalSeconds: Int, cycleSeconds: Int) -> Int {
        guard cycleSeconds > 0 else { return totalSeconds }
        return (totalSeconds + cycleSeconds - 1) / cycleSeconds * cycleSeconds
    }
}
