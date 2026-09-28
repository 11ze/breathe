import XCTest
@testable import Breathe

/// 通知时长格式化测试
/// 上游会话总结的 Completed 行是秒级精度，整除到分钟会把 7分30秒显示成"7 分钟"、
/// 提前停止的短会话显示成"0 分钟"
final class NotificationManagerTests: XCTestCase {

    @MainActor func testWholeMinutes() {
        XCTAssertEqual(NotificationManager.formatDuration(420), "7 分钟")
        XCTAssertEqual(NotificationManager.formatDuration(60), "1 分钟")
    }

    @MainActor func testMinutesAndSeconds() {
        XCTAssertEqual(NotificationManager.formatDuration(450), "7 分 30 秒")
        XCTAssertEqual(NotificationManager.formatDuration(61), "1 分 1 秒")
    }

    @MainActor func testUnderOneMinute() {
        XCTAssertEqual(NotificationManager.formatDuration(40), "40 秒")
        XCTAssertEqual(NotificationManager.formatDuration(0), "0 秒")
    }
}
