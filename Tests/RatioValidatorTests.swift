import XCTest
@testable import Breathe

/// RatioValidator 安全约束测试
/// 验证为什么这些边界重要：呼吸练习涉及生理节奏，错误参数可能导致过度换气或不适
final class RatioValidatorTests: XCTestCase {

    // MARK: - 有效比例

    func testValidBalancedRatio() {
        let result = RatioValidator.validate("5-5")
        switch result {
        case .success(let (inhale, exhale)):
            XCTAssertEqual(inhale, 5)
            XCTAssertEqual(exhale, 5)
        case .failure:
            XCTFail("5-5 应该是有效比例")
        }
    }

    func testValidCalmRatio() {
        let result = RatioValidator.validate("4-6")
        switch result {
        case .success(let (inhale, exhale)):
            XCTAssertEqual(inhale, 4)
            XCTAssertEqual(exhale, 6)
        case .failure:
            XCTFail("4-6 应该是有效比例")
        }
    }

    // MARK: - 屏息拒绝（优先于格式错误）

    /// 三段比例（如 4-7-8）暗示屏息，这是最重要的安全规则
    /// 屏息对初学者可能造成不适，且本应用专注共振呼吸而非屏息练习
    func testThreePartRatioRejectedAsBreathHold() {
        let result = RatioValidator.validate("4-7-8")
        if case .failure(.breathHoldNotSupported) = result {
            // 正确：应返回屏息警告而非通用格式错误
        } else {
            XCTFail("三段比例应被拒绝为 breathHoldNotSupported，而不是其他错误")
        }
    }

    // MARK: - 格式错误

    func testInvalidFormat() {
        let cases = ["", "5", "abc-def", "5-5-5-5"]
        for ratio in cases {
            let result = RatioValidator.validate(ratio)
            if case .success = result {
                XCTFail("'\(ratio)' 应该无效")
            }
        }
    }

    // MARK: - 总周期下限（≥ 8 秒）

    /// 过快的呼吸节奏会导致过度换气，8 秒周期 = 7.5 bpm 是安全下限
    func testCycleTooShort() {
        let result = RatioValidator.validate("3-3")
        if case .failure(.cycleTooShort(let total, let minimum)) = result {
            XCTAssertEqual(total, 6)
            XCTAssertEqual(minimum, 8)
        } else {
            XCTFail("3+3=6 秒应被拒绝为周期过短")
        }
    }

    func testCycleExactly8SecondsIsValid() {
        let result = RatioValidator.validate("4-4")
        if case .failure = result {
            XCTFail("4+4=8 秒应刚好通过最小周期检查")
        }
    }

    // MARK: - 吸气范围 (3~10)

    /// 吸气过短会导致浅呼吸，过长对初学者困难
    func testInhaleTooShort() {
        let result = RatioValidator.validate("2-6")
        if case .failure(.inhaleOutOfRange(let value, _)) = result {
            XCTAssertEqual(value, 2)
        } else {
            XCTFail("吸气 2 秒应被拒绝")
        }
    }

    func testInhaleTooLong() {
        let result = RatioValidator.validate("11-11")
        if case .failure(.inhaleOutOfRange(let value, _)) = result {
            XCTAssertEqual(value, 11)
        } else {
            XCTFail("吸气 11 秒应被拒绝")
        }
    }

    func testInhaleBoundary3() {
        let result = RatioValidator.validate("3-5")
        if case .failure = result {
            XCTFail("吸气 3 秒应通过（下界）")
        }
    }

    func testInhaleBoundary10() {
        let result = RatioValidator.validate("10-10")
        if case .failure = result {
            XCTFail("吸气 10 秒应通过（上界）")
        }
    }

    // MARK: - 呼气范围 (3~10)

    /// 用 "6-2" 而非 "5-2"：确保总周期 >= 8 以命中呼气范围检查而非周期过短检查
    func testExhaleTooShort() {
        let result = RatioValidator.validate("6-2")
        if case .failure(.exhaleOutOfRange(let value, _)) = result {
            XCTAssertEqual(value, 2)
        } else {
            XCTFail("呼气 2 秒应被拒绝")
        }
    }

    // MARK: - 呼气 ≤ 2× 吸气

    /// 呼气过长会导致空气饥饿感，造成焦虑而非放松
    func testExhaleExceedsDoubleInhale() {
        let result = RatioValidator.validate("3-7")
        if case .failure(.exhaleTooLong(let exhale, let max)) = result {
            XCTAssertEqual(exhale, 7)
            XCTAssertEqual(max, 6) // 2 * 3
        } else {
            XCTFail("呼气 7 > 2×吸气 3 应被拒绝")
        }
    }

    func testExhaleExactlyDoubleInhaleIsValid() {
        let result = RatioValidator.validate("3-6")
        if case .failure = result {
            XCTFail("呼气 6 = 2×吸气 3 应刚好通过")
        }
    }

    // MARK: - 数值验证接口

    func testNumericValidation() {
        let result = RatioValidator.validate(inhale: 5, exhale: 5)
        if case .success(let (i, e)) = result {
            XCTAssertEqual(i, 5)
            XCTAssertEqual(e, 5)
        } else {
            XCTFail("数值验证 5-5 应通过")
        }
    }

    func testNumericValidationFails() {
        let result = RatioValidator.validate(inhale: 2, exhale: 5)
        if case .success = result {
            XCTFail("吸气 2 秒应被数值验证拒绝")
        }
    }
}
