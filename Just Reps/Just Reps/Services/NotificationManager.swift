import Foundation
import UserNotifications

extension Notification.Name {
    static let streakAtRiskTapped = Notification.Name("streakAtRiskTapped")
}

@Observable
@MainActor
final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    var isAuthorized = false

    private let dailyReminderId   = "just_reps_daily_reminder"
    private let atRiskReminderId  = "just_reps_streak_at_risk"

    private let dailyMessages = [
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

    // MARK: - Daily Reminder

    func scheduleDailyReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderId])

        let content = UNMutableNotificationContent()
        content.title = "Just Reps"
        content.body = dailyMessages.randomElement() ?? "Time for your daily reps."
        content.sound = .default

        var trigger = DateComponents()
        trigger.hour = hour
        trigger.minute = minute

        let request = UNNotificationRequest(
            identifier: dailyReminderId,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )
        center.add(request)
    }

    func scheduleSmartReminder(entries: [WorkoutEntry]) {
        let preferredHour = StreakEngine.preferredLogHour(from: entries)
        let atRiskHour = max(9, min(21, preferredHour + 3))
        scheduleDailyReminder(hour: atRiskHour, minute: 0)
    }

    func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReminderId])
    }

    // MARK: - Streak At-Risk Notification

    /// Schedules a one-time notification at 8 PM tonight. Safe to call repeatedly.
    func scheduleAtRiskNotification(streak: Int) {
        let hour = Calendar.current.component(.hour, from: .now)
        guard hour < 20 else { return }  // already past 8 PM

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [atRiskReminderId])

        let content = UNMutableNotificationContent()
        content.title = "Streak at Risk"
        content.body = "Your \(streak)-day streak ends tonight. Log a few reps to keep it alive."
        content.sound = .default

        var fireDate = DateComponents()
        fireDate.hour = 20
        fireDate.minute = 0

        let request = UNNotificationRequest(
            identifier: atRiskReminderId,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: fireDate, repeats: false)
        )
        center.add(request)
    }

    func cancelAtRiskNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [atRiskReminderId])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == atRiskReminderId {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .streakAtRiskTapped, object: nil)
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Suppress at-risk notification in-foreground; the app's own UI handles it
        if notification.request.identifier == atRiskReminderId {
            completionHandler([])
        } else {
            completionHandler([.banner, .sound])
        }
    }
}
