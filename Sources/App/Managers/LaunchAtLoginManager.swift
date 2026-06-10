import ServiceManagement
import os

@MainActor
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    private static let logger = Logger(subsystem: "com.cai.breathe", category: "LaunchAtLogin")

    /// 是否支持自启动功能（macOS 13+）
    let isSupported: Bool

    /// 当前是否启用自启动
    var isEnabled: Bool {
        get {
            guard #available(macOS 13.0, *) else { return false }
            return SMAppService.mainApp.status == .enabled
        }
        set {
            guard #available(macOS 13.0, *) else { return }
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Self.logger.error("开机自启\(newValue ? "启用" : "禁用")失败: \(error.localizedDescription)")
            }
        }
    }

    private init() {
        if #available(macOS 13.0, *) {
            isSupported = true
        } else {
            isSupported = false
        }
    }

    /// 同步配置与系统实际状态
    /// 当配置与系统状态不一致时，以系统状态为准
    func sync(withSettings enabled: Bool) {
        let systemState = isEnabled
        if enabled != systemState {
            AppSettingsManager.shared.settings.launchAtLogin = systemState
            AppSettingsManager.shared.save()
        }
    }
}
