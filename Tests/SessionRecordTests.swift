import XCTest
@testable import Breathe

/// SessionRecord 序列化测试
/// CSV 格式必须与 breathe-cli 完全兼容，否则历史数据无法互通
final class SessionRecordTests: XCTestCase {

    // MARK: - CSV 行生成

    func testCsvRow() {
        let record = SessionRecord(
            date: "2026-06-05", time: "14:32:00",
            preset: "calm", ratio: "4-6",
            durationTargetSeconds: 900, durationActualSeconds: 900,
            breaths: 90, completionPercent: 100, status: "completed"
        )
        XCTAssertEqual(
            record.csvRow,
            "2026-06-05,14:32:00,calm,4-6,900,900,90,100,completed"
        )
    }

    // MARK: - CSV 行解析

    func testParseValidCsvRow() {
        let row = "2026-06-05,14:32:00,calm,4-6,900,900,90,100,completed"
        let record = SessionRecord(csvRow: row)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.date, "2026-06-05")
        XCTAssertEqual(record?.time, "14:32:00")
        XCTAssertEqual(record?.preset, "calm")
        XCTAssertEqual(record?.ratio, "4-6")
        XCTAssertEqual(record?.durationTargetSeconds, 900)
        XCTAssertEqual(record?.durationActualSeconds, 900)
        XCTAssertEqual(record?.breaths, 90)
        XCTAssertEqual(record?.completionPercent, 100)
        XCTAssertEqual(record?.status, "completed")
    }

    func testParseEndedEarly() {
        let row = "2026-06-05,14:32:00,balanced,5-5,600,300,30,50,ended early (user)"
        let record = SessionRecord(csvRow: row)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.status, "ended early (user)")
        XCTAssertEqual(record?.completionPercent, 50)
    }

    // MARK: - 无效输入

    func testParseInvalidCsvRowTooFewColumns() {
        let record = SessionRecord(csvRow: "2026-06-05,14:32:00,calm")
        XCTAssertNil(record, "列数不足应返回 nil")
    }

    func testParseInvalidCsvRowNonNumeric() {
        let record = SessionRecord(csvRow: "2026-06-05,14:32:00,calm,4-6,abc,900,90,100,completed")
        XCTAssertNil(record, "数值列非数字应返回 nil")
    }

    // MARK: - CSV 列头兼容性

    func testCsvHeaderMatchesBreatheCLI() {
        XCTAssertEqual(
            SessionRecord.csvHeader,
            "date,time,preset,ratio,duration_target_s,duration_actual_s,breaths,completion_pct,status"
        )
    }

    // MARK: - round-trip

    func testRoundTrip() {
        let original = SessionRecord(
            date: "2026-06-05", time: "08:00:00",
            preset: "custom", ratio: "5-5",
            durationTargetSeconds: 600, durationActualSeconds: 580,
            breaths: 58, completionPercent: 96, status: "ended early (user)"
        )
        let parsed = SessionRecord(csvRow: original.csvRow)
        XCTAssertEqual(original, parsed)
    }

    // MARK: - completionPercent 钳制

    func testCompletionPercentClamped() {
        let record = SessionRecord(
            date: "2026-06-05", time: "14:32:00",
            preset: "calm", ratio: "4-6",
            durationTargetSeconds: 900, durationActualSeconds: 950,
            breaths: 95, completionPercent: 105, status: "completed"
        )
        XCTAssertEqual(record.completionPercent, 100, "超过 100 应钳制到 100")
    }
}
