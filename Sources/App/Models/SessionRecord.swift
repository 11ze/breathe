import Foundation

/// 一次呼吸会话的记录（CSV 可序列化）
struct SessionRecord: Equatable {
    let date: String          // YYYY-MM-DD
    let time: String          // HH:MM:SS
    let preset: String        // balanced / calm / extended / custom
    let ratio: String         // "5-5"
    let durationTargetSeconds: Int
    let durationActualSeconds: Int
    let breaths: Int
    let completionPercent: Int  // 0-100
    let status: String          // "completed" / "ended early (user)"

    /// CSV 列头（与 breathe-cli 完全兼容）
    static let csvHeader = "date,time,preset,ratio,duration_target_s,duration_actual_s,breaths,completion_pct,status"

    /// 从会话数据创建记录
    init(
        date: String, time: String,
        preset: String, ratio: String,
        durationTargetSeconds: Int, durationActualSeconds: Int,
        breaths: Int, completionPercent: Int, status: String
    ) {
        self.date = date
        self.time = time
        self.preset = preset
        self.ratio = ratio
        self.durationTargetSeconds = durationTargetSeconds
        self.durationActualSeconds = durationActualSeconds
        self.breaths = breaths
        self.completionPercent = min(100, max(0, completionPercent))
        self.status = status
    }

    /// 转为 CSV 行
    var csvRow: String {
        "\(date),\(time),\(preset),\(ratio),\(durationTargetSeconds),\(durationActualSeconds),\(breaths),\(completionPercent),\(status)"
    }

    /// 从 CSV 行解析（与 breathe-cli 格式兼容）
    init?(csvRow: String) {
        let columns = csvRow.split(separator: ",", omittingEmptySubsequences: false)
        guard columns.count == 9 else { return nil }
        self.date = String(columns[0])
        self.time = String(columns[1])
        self.preset = String(columns[2])
        self.ratio = String(columns[3])
        guard let target = Int(columns[4]),
              let actual = Int(columns[5]),
              let breaths = Int(columns[6]),
              let pct = Int(columns[7]) else { return nil }
        self.durationTargetSeconds = target
        self.durationActualSeconds = actual
        self.breaths = breaths
        self.completionPercent = pct
        self.status = String(columns[8])
    }
}
