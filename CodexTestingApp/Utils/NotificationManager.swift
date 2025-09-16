import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private override init() { super.init() }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    func scheduleReminder(for task: TaskItem) {
        guard let when = task.reminderAt, when > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = task.title
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: when)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func cancelReminder(for taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [taskId.uuidString])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [taskId.uuidString])
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
}
