import ServiceManagement
import os
import Combine

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    private static let logger = Logger(subsystem: "com.cai.breathe", category: "LaunchAtLogin")

    /// 是否支持自启动功能（macOS 13+）
    let isSupported: Bool

    /// 系统交互注入点（测试时替换）
    private let systemStatus: () -> Bool
    private let systemSetter: (Bool) throws -> Void

    private let systemRequiresApproval: () -> Bool
    @Published private(set) var isEnabled = false
    @Published private(set) var requiresApproval = false
    @Published private(set) var errorMessage: String?

    func refresh() {
        isEnabled = systemStatus()
        requiresApproval = systemRequiresApproval()
    }

    func openLoginItemsSettings() {
        guard #available(macOS 13.0, *) else { return }
        SMAppService.openSystemSettingsLoginItems()
    }

    /// 切换自启动，返回系统最终状态。
    /// 注册失败时返回系统实际状态，调用方应以返回值同步配置，保证配置始终反映系统真实状态。
    func setEnabled(_ enabled: Bool) -> Bool {
        errorMessage = nil
        refresh()
        if enabled && requiresApproval { return isEnabled }
        do {
            try systemSetter(enabled)
        } catch {
            errorMessage = error.localizedDescription
            Self.logger.error("开机自启\(enabled ? "启用" : "禁用")失败: \(error.localizedDescription)")
        }
        refresh()
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
        },
        systemRequiresApproval: @escaping () -> Bool = {
            guard #available(macOS 13.0, *) else { return false }
            return SMAppService.mainApp.status == .requiresApproval
        }
    ) {
        self.systemStatus = systemStatus
        self.systemSetter = systemSetter
        self.systemRequiresApproval = systemRequiresApproval
        if #available(macOS 13.0, *) {
            isSupported = true
        } else {
            isSupported = false
        }
        refresh()
    }

    /// 同步配置与系统实际状态
    /// 当配置与系统状态不一致时，以系统状态为准
    func sync(withSettings enabled: Bool) {
        refresh()
        let systemState = isEnabled
        if enabled != systemState {
            AppSettingsManager.shared.settings.launchAtLogin = systemState
            AppSettingsManager.shared.save()
        }
    }
}
