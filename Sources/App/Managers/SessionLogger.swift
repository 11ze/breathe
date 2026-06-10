import Foundation

/// 会话日志管理器 — CSV 格式与 breathe-cli 完全兼容
/// 日志存储在 ~/.config/breathe/sessions.csv
@MainActor
final class SessionLogger {
    static let shared = SessionLogger()

    private init() {}

    /// 追加一条会话记录
    func log(_ record: SessionRecord) {
        do {
            try AppPaths.ensureDirectoryExists()
            let fileURL = AppPaths.sessionLogFile
            let fileManager = FileManager.default

            // 文件不存在时先写列头
            if !fileManager.fileExists(atPath: fileURL.path) {
                let header = SessionRecord.csvHeader + "\n"
                try header.write(to: fileURL, atomically: true, encoding: .utf8)
            }

            // 追加数据行
            let row = record.csvRow + "\n"
            guard let handle = FileHandle(forUpdatingAtPath: fileURL.path) else { return }
            handle.seekToEndOfFile()
            if let data = row.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } catch {
            // 日志写入失败不影响用户体验（与 breathe-cli 一致）
        }
    }

    /// 读取所有会话记录
    func loadAll() -> [SessionRecord] {
        let fileURL = AppPaths.sessionLogFile
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return []
        }
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        // 跳过列头行
        return lines.dropFirst().compactMap { line in
            SessionRecord(csvRow: String(line))
        }
    }

    /// 从旧版 breathe-cli 日志 (~/.breathe_log.csv) 导入
    func importLegacyLog() -> Int {
        let legacyPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".breathe_log.csv")

        guard let content = try? String(contentsOf: legacyPath, encoding: .utf8) else {
            return 0
        }

        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        var imported = 0

        for line in lines {
            // 跳过列头行
            if line.hasPrefix("date,") { continue }

            if let record = SessionRecord(csvRow: String(line)) {
                log(record)
                imported += 1
            }
        }

        return imported
    }
}
