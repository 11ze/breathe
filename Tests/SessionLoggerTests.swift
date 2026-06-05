import XCTest
@testable import Breathe

/// SessionLogger 测试
/// 使用临时目录避免污染真实配置目录
@MainActor
final class SessionLoggerTests: XCTestCase {

    // MARK: - CSV 兼容性

    /// CSV 列头必须与 breathe-cli 完全一致，否则历史数据无法互通
    func testCsvHeaderCompatibility() {
        XCTAssertEqual(
            SessionRecord.csvHeader,
            "date,time,preset,ratio,duration_target_s,duration_actual_s,breaths,completion_pct,status"
        )
    }

    // MARK: - 生成与解析 round-trip

    func testRecordRoundTrip() {
        let record = SessionRecord(
            date: "2026-06-05", time: "14:32:00",
            preset: "calm", ratio: "4-6",
            durationTargetSeconds: 900, durationActualSeconds: 900,
            breaths: 90, completionPercent: 100, status: "completed"
        )
        let parsed = SessionRecord(csvRow: record.csvRow)
        XCTAssertEqual(record, parsed)
    }

    // MARK: - 各种状态记录

    func testCompletedStatus() {
        let record = SessionRecord(
            date: "2026-06-05", time: "08:00:00",
            preset: "balanced", ratio: "5-5",
            durationTargetSeconds: 600, durationActualSeconds: 600,
            breaths: 60, completionPercent: 100, status: "completed"
        )
        XCTAssertTrue(record.csvRow.hasSuffix("completed"))
    }

    func testEndedEarlyStatus() {
        let record = SessionRecord(
            date: "2026-06-05", time: "08:00:00",
            preset: "custom", ratio: "5-5",
            durationTargetSeconds: 600, durationActualSeconds: 300,
            breaths: 30, completionPercent: 50, status: "ended early (user)"
        )
        XCTAssertTrue(record.csvRow.hasSuffix("ended early (user)"))
    }

    // MARK: - 无效输入

    func testInvalidCsvReturnsNil() {
        XCTAssertNil(SessionRecord(csvRow: ""))
        XCTAssertNil(SessionRecord(csvRow: "a,b,c"))
        XCTAssertNil(SessionRecord(csvRow: "2026-06-05,14:32:00,calm,4-6,abc,900,90,100,completed"))
    }

    // MARK: - completionPercent 钳制

    /// 超过 100% 的完成度应被钳制，防止 CSV 数据异常
    func testCompletionPercentClampedTo100() {
        let record = SessionRecord(
            date: "2026-06-05", time: "14:32:00",
            preset: "calm", ratio: "4-6",
            durationTargetSeconds: 900, durationActualSeconds: 950,
            breaths: 95, completionPercent: 150, status: "completed"
        )
        XCTAssertEqual(record.completionPercent, 100)
    }

    func testCompletionPercentClampedTo0() {
        let record = SessionRecord(
            date: "2026-06-05", time: "14:32:00",
            preset: "calm", ratio: "4-6",
            durationTargetSeconds: 900, durationActualSeconds: 0,
            breaths: 0, completionPercent: -10, status: "ended early (user)"
        )
        XCTAssertEqual(record.completionPercent, 0)
    }
}
