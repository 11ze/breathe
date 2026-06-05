import Foundation
import Combine

// MARK: - 配置模型

/// 应用配置（JSON 持久化到 ~/.config/breathe/settings.json）
struct AppSettings: Codable, Equatable {
    /// 默认预设：auto（按时段）/ balanced / calm / extended / custom
    var defaultPreset: String = "auto"
    /// 自定义吸气秒数
    var customInhaleSeconds: Int = 5
    /// 自定义呼气秒数
    var customExhaleSeconds: Int = 5
    /// 自定义时长（分钟）
    var customDurationMinutes: Int = 10
    /// 音频提示
    var soundEnabled: Bool = true
    /// 记录会话日志
    var logSessions: Bool = true
    /// 开机自启
    var launchAtLogin: Bool = false
    /// 每日提醒
    var dailyReminderEnabled: Bool = false
    /// 每日提醒时间 "HH:mm"
    var dailyReminderTime: String = "08:00"

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultPreset = try container.decodeIfPresent(String.self, forKey: .defaultPreset) ?? "auto"
        customInhaleSeconds = try container.decodeIfPresent(Int.self, forKey: .customInhaleSeconds) ?? 5
        customExhaleSeconds = try container.decodeIfPresent(Int.self, forKey: .customExhaleSeconds) ?? 5
        customDurationMinutes = try container.decodeIfPresent(Int.self, forKey: .customDurationMinutes) ?? 10
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        logSessions = try container.decodeIfPresent(Bool.self, forKey: .logSessions) ?? true
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        dailyReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .dailyReminderEnabled) ?? false
        dailyReminderTime = try container.decodeIfPresent(String.self, forKey: .dailyReminderTime) ?? "08:00"
    }
}

// MARK: - 配置重载通知

extension Notification.Name {
    static let settingsDidReload = Notification.Name("breathe.settingsDidReload")
}

// MARK: - 配置管理器

/// 配置管理器 — 原子写入 + 文件监听 + isLoaded 保护
/// 复用 menu-bar-executor 的 AppSettingsManager 模式
@MainActor
final class AppSettingsManager: ObservableObject {
    static let shared = AppSettingsManager()

    @Published var settings: AppSettings = AppSettings()

    /// 配置是否已成功从磁盘加载（防止加载失败时空默认值覆盖真实配置）
    private var isLoaded = false

    private let filePath: URL
    private let resolvedFilePath: URL

    // MARK: - 文件监听

    private var fileMonitorSource: DispatchSourceFileSystemObject?
    private var monitorFileDescriptor: Int32 = -1
    private var debounceTask: Task<Void, Never>?
    /// 自身 save() 触发文件变化时跳过自动重载
    private var skipNextFileChange = false

    private init() {
        filePath = AppPaths.settingsFile
        // 初始化时一次性解析软链接
        if let resolved = try? FileManager.default.destinationOfSymbolicLink(atPath: filePath.path) {
            resolvedFilePath = URL(fileURLWithPath: resolved)
        } else {
            resolvedFilePath = filePath
        }
        load()
        startFileMonitoring()
    }

    deinit {
        fileMonitorSource?.cancel()
        fileMonitorSource = nil
        if monitorFileDescriptor >= 0 {
            close(monitorFileDescriptor)
        }
        debounceTask?.cancel()
    }

    // MARK: - 文件监听

    private func startFileMonitoring() {
        let fd = open(resolvedFilePath.path, O_EVTONLY)
        guard fd >= 0 else { return }
        monitorFileDescriptor = fd

        fileMonitorSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: DispatchQueue(label: "com.cai.breathe.settings-monitor")
        )

        fileMonitorSource?.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.handleFileChange()
            }
        }

        fileMonitorSource?.resume()
    }

    private func stopFileMonitoring() {
        fileMonitorSource?.cancel()
        fileMonitorSource = nil
        if monitorFileDescriptor >= 0 {
            close(monitorFileDescriptor)
            monitorFileDescriptor = -1
        }
    }

    private func restartFileMonitoring() {
        stopFileMonitoring()
        startFileMonitoring()
    }

    private func handleFileChange() {
        if skipNextFileChange {
            skipNextFileChange = false
            return
        }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            self?.reloadSilent()
        }
    }

    // MARK: - 加载

    func load() {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            isLoaded = true
            return
        }
        do {
            let data = try Data(contentsOf: filePath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            settings = try decoder.decode(AppSettings.self, from: data)
            isLoaded = true
        } catch {
            // 加载失败时保持默认值，允许 save()
            isLoaded = true
        }
    }

    func reloadSilent() {
        load()
        NotificationCenter.default.post(name: .settingsDidReload, object: nil)
        restartFileMonitoring()
    }

    // MARK: - 保存

    func save() {
        guard isLoaded else { return }
        skipNextFileChange = true
        do {
            try AppPaths.ensureDirectoryExists()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(settings)

            let fileManager = FileManager.default
            let tempPath = resolvedFilePath.appendingPathExtension("tmp")
            try data.write(to: tempPath, options: .atomic)

            if fileManager.fileExists(atPath: resolvedFilePath.path) {
                try fileManager.replaceItem(at: resolvedFilePath, withItemAt: tempPath, backupItemName: nil, resultingItemURL: nil)
            } else {
                try fileManager.moveItem(at: tempPath, to: resolvedFilePath)
            }

            restartFileMonitoring()
        } catch {
            // 保存失败静默忽略
        }
    }

    func reload() {
        load()
        NotificationCenter.default.post(name: .settingsDidReload, object: nil)
    }
}
