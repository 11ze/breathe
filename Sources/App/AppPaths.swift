import Foundation

/// 应用程序路径管理
enum AppPaths {
    /// 配置目录路径 (~/.config/breathe/)
    static let configDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config")
        .appendingPathComponent("breathe")

    /// 配置文件路径
    static var settingsFile: URL { configDirectory.appendingPathComponent("settings.json") }

    /// 会话日志文件路径
    static var sessionLogFile: URL { configDirectory.appendingPathComponent("sessions.csv") }

    /// 确保配置目录存在
    static func ensureDirectoryExists() throws {
        if !FileManager.default.fileExists(atPath: configDirectory.path) {
            try FileManager.default.createDirectory(at: configDirectory, withIntermediateDirectories: true)
        }
    }
}
