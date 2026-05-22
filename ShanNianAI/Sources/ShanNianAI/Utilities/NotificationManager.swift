import UserNotifications
import UIKit

@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var dailyReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyReminderEnabled, forKey: "notification_daily_reminder")
            if dailyReminderEnabled { scheduleDailyReminder() }
            else { cancelDailyReminder() }
        }
    }
    @Published var reminderTime: Date {
        didSet {
            UserDefaults.standard.set(reminderTime.timeIntervalSince1970, forKey: "notification_reminder_time")
            if dailyReminderEnabled { scheduleDailyReminder() }
        }
    }
    @Published var reviewReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(reviewReminderEnabled, forKey: "notification_review_reminder")
            if reviewReminderEnabled { scheduleReviewReminders() }
            else { cancelReviewReminders() }
        }
    }

    private override init() {
        let savedTime = UserDefaults.standard.double(forKey: "notification_reminder_time")
        self.reminderTime = savedTime > 0
            ? Date(timeIntervalSince1970: savedTime)
            : Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()

        self.dailyReminderEnabled = UserDefaults.standard.bool(forKey: "notification_daily_reminder")
        self.reviewReminderEnabled = UserDefaults.standard.bool(forKey: "notification_review_reminder")

        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted

            if granted {
                await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
                if dailyReminderEnabled { scheduleDailyReminder() }
                if reviewReminderEnabled { scheduleReviewReminders() }
            }
        } catch {
            isAuthorized = false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Daily Reminder

    func scheduleDailyReminder() {
        cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "🌟 一闪"
        content.body = "今天有什么一闪而过的念头？来记录吧"
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily_reminder"]
        )
    }

    // MARK: - Review Reminders

    func scheduleReviewReminders() {
        cancelReviewReminders()

        // 1 day review
        scheduleReview(at: 1)

        // 7 day review
        scheduleReview(at: 7)

        // 30 day review
        scheduleReview(at: 30)
    }

    private func scheduleReview(at daysAgo: Int) {
        let content = UNMutableNotificationContent()
        content.title = "📝 回顾提醒"
        content.body = "来看看\(daysAgo)天前的笔记，温故知新"
        content.sound = .default

        // Trigger every morning at 9 AM
        var components = DateComponents()
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "review_\(daysAgo)d",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelReviewReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["review_1d", "review_7d", "review_30d"]
        )
    }

    // MARK: - Delegates

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Handle notification taps
    }
}
