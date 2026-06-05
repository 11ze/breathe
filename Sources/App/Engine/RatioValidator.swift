import Foundation

/// 呼吸比例安全验证错误
enum RatioValidationError: Error, LocalizedError {
    /// 三段比例暗示屏息（如 4-7-8）
    case breathHoldNotSupported
    /// 格式不正确
    case invalidFormat
    /// 总周期不足 8 秒
    case cycleTooShort(total: Int, minimum: Int)
    /// 吸气超出范围
    case inhaleOutOfRange(value: Int, range: ClosedRange<Int>)
    /// 呼气超出范围
    case exhaleOutOfRange(value: Int, range: ClosedRange<Int>)
    /// 呼气超过吸气两倍
    case exhaleTooLong(exhale: Int, maxRelativeToInhale: Int)

    var errorDescription: String? {
        switch self {
        case .breathHoldNotSupported:
            return "三段比例（如 4-7-8）暗示屏息，本应用不支持屏息练习"
        case .invalidFormat:
            return "比例格式应为 吸气-呼气（如 5-5）"
        case .cycleTooShort(let total, let minimum):
            return "总呼吸周期须 ≥ \(minimum) 秒，当前 \(total) 秒"
        case .inhaleOutOfRange(let value, let range):
            return "吸气时长须在 \(range.lowerBound)-\(range.upperBound) 秒，当前 \(value) 秒"
        case .exhaleOutOfRange(let value, let range):
            return "呼气时长须在 \(range.lowerBound)-\(range.upperBound) 秒，当前 \(value) 秒"
        case .exhaleTooLong(let exhale, let max):
            return "呼气时长不应超过吸气的 2 倍，当前呼气 \(exhale) 秒，上限 \(max) 秒"
        }
    }
}

/// 呼吸比例安全验证
/// 移植自 breathe-cli 的 parse_ratio() 安全规则，验证顺序保持一致
enum RatioValidator {
    /// 吸气允许范围（秒）
    static let inhaleRange = 3...10
    /// 呼气允许范围（秒）
    static let exhaleRange = 3...10
    /// 最小总周期（秒）
    static let minCycleSeconds = 8

    /// 验证呼吸比例字符串，返回 (吸气秒数, 呼气秒数) 或错误
    /// - Parameter ratioString: 格式如 "5-5" 或 "4-6"
    static func validate(_ ratioString: String) -> Result<(inhale: Int, exhale: Int), RatioValidationError> {
        let parts = ratioString.split(separator: "-").compactMap { Int($0) }

        // 规则 1：三段比例 → 屏息警告（优先于格式错误，与 breathe-cli 一致）
        let rawParts = ratioString.split(separator: "-")
        if rawParts.count > 2 {
            return .failure(.breathHoldNotSupported)
        }

        // 规则 2：必须恰好两段
        if rawParts.count != 2 || parts.count != 2 {
            return .failure(.invalidFormat)
        }

        let inhale = parts[0]
        let exhale = parts[1]
        let total = inhale + exhale

        // 规则 3：总周期 ≥ 8 秒
        if total < minCycleSeconds {
            return .failure(.cycleTooShort(total: total, minimum: minCycleSeconds))
        }

        // 规则 4：吸气范围
        if !inhaleRange.contains(inhale) {
            return .failure(.inhaleOutOfRange(value: inhale, range: inhaleRange))
        }

        // 规则 5：呼气范围
        if !exhaleRange.contains(exhale) {
            return .failure(.exhaleOutOfRange(value: exhale, range: exhaleRange))
        }

        // 规则 6：呼气 ≤ 2×吸气
        if exhale > 2 * inhale {
            return .failure(.exhaleTooLong(exhale: exhale, maxRelativeToInhale: 2 * inhale))
        }

        return .success((inhale: inhale, exhale: exhale))
    }

    /// 直接验证数值对
    static func validate(inhale: Int, exhale: Int) -> Result<(inhale: Int, exhale: Int), RatioValidationError> {
        let total = inhale + exhale

        if total < minCycleSeconds {
            return .failure(.cycleTooShort(total: total, minimum: minCycleSeconds))
        }
        if !inhaleRange.contains(inhale) {
            return .failure(.inhaleOutOfRange(value: inhale, range: inhaleRange))
        }
        if !exhaleRange.contains(exhale) {
            return .failure(.exhaleOutOfRange(value: exhale, range: exhaleRange))
        }
        if exhale > 2 * inhale {
            return .failure(.exhaleTooLong(exhale: exhale, maxRelativeToInhale: 2 * inhale))
        }

        return .success((inhale: inhale, exhale: exhale))
    }
}
