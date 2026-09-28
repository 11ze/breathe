import ServiceManagement
import os

@MainActor
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    private static let logger = Logger(subsystem: "com.cai.breathe", category: "LaunchAtLogin")

    /// 是否支持自启动功能（macOS 13+）
    let isSupported: Bool

    /// 系统交互注入点（测试时替换）
    private let systemStatus: () -> Bool
    private let systemSetter: (Bool) throws -> Void

    /// 系统当前是否启用自启动
    var isEnabled: Bool { systemStatus() }

    /// 切换自启动，返回系统最终状态。
    /// 注册失败时返回系统实际状态，调用方应以返回值同步配置，保证配置始终反映系统真实状态。
    func setEnabled(_ enabled: Bool) -> Bool {
        do {
            try systemSetter(enabled)
        } catch {
            Self.logger.error("开机自启\(enabled ? "启用" : "禁用")失败: \(error.localizedDescription)")
        }
        return isEnabled
    }

    init(
        systemStatus: @escaping () -> Bool = {
            guard #available(macOS 13.0, *) else { return false }
            return SMAppService.mainApp.status == .enabled
        },
        systemSetter: @escaping (Bool) throws -> Void = { enabled in
            guard #available(macOS 13.0, *) else { return }
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        }
    ) {
        self.systemStatus = systemStatus
        self.systemSetter = systemSetter
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
