import XCTest
@testable import Breathe

/// LaunchAtLoginManager 行为测试
/// 验证切换自启动时注册动作被调用，且返回值始终反映系统最终状态
/// （注册失败时调用方据此回弹开关，保证配置不与系统脱节）
@MainActor
final class LaunchAtLoginManagerTests: XCTestCase {

    /// 启用成功：注册动作收到 true，返回系统状态 true
    func testEnableCallsSystemRegisterAndReturnsState() {
        var calls: [Bool] = []
        let manager = LaunchAtLoginManager(
            systemStatus: { true },
            systemSetter: { calls.append($0) }
        )

        let result = manager.setEnabled(true)

        XCTAssertEqual(calls, [true])
        XCTAssertTrue(result)
    }

    /// 注册失败（如系统拒绝）：返回系统实际状态 false，而非透传目标值
    func testEnableFailureReturnsActualSystemState() {
        struct RegisterError: Error {}
        let manager = LaunchAtLoginManager(
            systemStatus: { false },
            systemSetter: { _ in throw RegisterError() }
        )

        let result = manager.setEnabled(true)

        XCTAssertFalse(result)
    }

    /// 禁用：注销动作被调用，返回 false
    func testDisableCallsSystemUnregister() {
        var calls: [Bool] = []
        let manager = LaunchAtLoginManager(
            systemStatus: { false },
            systemSetter: { calls.append($0) }
        )

        let result = manager.setEnabled(false)

        XCTAssertEqual(calls, [false])
        XCTAssertFalse(result)
    }
}
