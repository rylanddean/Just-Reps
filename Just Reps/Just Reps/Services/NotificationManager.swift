import Foundation
import UserNotifications

@Observable
@MainActor
final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    var isAuthorized = false

    private let notificationId = "just_reps_daily_reminder"

    private let messages = [
        "Quick set?",
        "Keep the streak alive.",
        "5 reps still counts.",
        "Today's a good day to show up.",
        "Don't break the chain.",
        "One set is enough.",
        "Show up daily.",
    ]

    // MARK: - Permission

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            isAuthorized = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            isAuthorized = false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling

    /// Schedules a daily local notification at the given hour + minute.
    func scheduleDailyReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])

        let content = UNMutableNotificationContent()
        content.title = "Just Reps"
        content.body = messages.randomElement() ?? "Time for your daily reps."
        content.sound = .default

        var trigger = DateComponents()
        trigger.hour = hour
        trigger.minute = minute

        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )

        center.add(request)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}
