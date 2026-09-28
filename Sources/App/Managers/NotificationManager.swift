import Foundation
import UserNotifications
import os

/// 通知管理器 — 会话完成通知
@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private static let logger = Logger(subsystem: "com.cai.breathe", category: "Notification")

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                Self.logger.error("通知授权请求失败: \(error.localizedDescription)")
            } else if !granted {
                Self.logger.info("用户未授予通知权限")
            }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - 会话完成通知

    /// 秒 → 秒级精度时长文案（对齐上游会话总结的 Completed 行）
    static func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes == 0 { return "\(secs) 秒" }
        if secs == 0 { return "\(minutes) 分钟" }
        return "\(minutes) 分 \(secs) 秒"
    }

    func showSessionComplete(record: SessionRecord) {
        let content = UNMutableNotificationContent()
        content.title = "Breathe"
        content.body = "\(record.preset) \(record.ratio) · \(record.breaths) 个呼吸周期 · \(Self.formatDuration(record.durationActualSeconds)) · 完成 \(record.completionPercent)%"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 遗留清理

    /// 每日提醒功能已删除；移除旧版本注册的重复通知，
    /// 否则它会每天触发且无法再通过应用关闭
    func removeLegacyDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["com.cai.breathe.daily-reminder"])
        center.removeDeliveredNotifications(withIdentifiers: ["com.cai.breathe.daily-reminder"])
    }
}
