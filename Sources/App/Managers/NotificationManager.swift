import Foundation
import UserNotifications

/// 通知管理器 — 会话完成通知 + 每日提醒
@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private static let dailyReminderId = "com.cai.breathe.daily-reminder"

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - 会话完成通知

    func showSessionComplete(breaths: Int, duration: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Breathe"
        content.body = "呼吸练习完成！完成了 \(breaths) 个呼吸周期，时长 \(duration / 60) 分钟"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - 每日提醒

    func scheduleDailyReminder(at time: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderId])

        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Breathe"
        content.body = "是时候做一次呼吸练习了 🌬️"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.dailyReminderId,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.dailyReminderId]
        )
    }
}
