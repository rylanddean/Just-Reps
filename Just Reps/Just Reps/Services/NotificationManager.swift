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
        "Your streak is at risk. Still time.",
        "5 reps still counts.",
        "One set is enough.",
        "Today's a good day to show up.",
        "Show up. Even 5 reps counts.",
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

    /// Schedules the at-risk notification at preferredLogHour + 3h, floored at 9AM,
    /// capped at 9PM. Falls back to 8PM when fewer than 7 days are logged in the window.
    func scheduleSmartReminder(entries: [WorkoutEntry]) {
        let preferredHour = StreakEngine.preferredLogHour(from: entries)
        let atRiskHour = max(9, min(21, preferredHour + 3))
        scheduleDailyReminder(hour: atRiskHour, minute: 0)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationId])
    }
}
