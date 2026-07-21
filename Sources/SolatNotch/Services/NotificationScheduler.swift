import Foundation
import UserNotifications

struct NotificationScheduler {
    func requestAuthorization() async throws -> Bool { try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
    func schedule(_ schedules: [DailyPrayerTimes], preferences: [Prayer: NotificationPreference]) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: schedules.flatMap { day in Prayer.allCases.map { "\(day.id)-\($0.rawValue)" } })
        for day in schedules { for prayer in Prayer.allCases {
            guard let preference = preferences[prayer], preference.enabled, let time = day[prayer] else { continue }
            let fire = time.addingTimeInterval(TimeInterval(-60 * preference.leadMinutes)); guard fire > Date() else { continue }
            let content = UNMutableNotificationContent(); content.title = prayer.malayName
            content.body = preference.leadMinutes == 0 ? "Telah masuk waktu \(prayer.malayName)." : "\(preference.leadMinutes) minit lagi sebelum \(prayer.malayName)."
            switch UserDefaults.standard.string(forKey: "notificationSound") ?? NotificationSoundChoice.device.rawValue {
            case NotificationSoundChoice.silent.rawValue: content.sound = nil
            case NotificationSoundChoice.azan.rawValue: content.sound = UNNotificationSound(named: UNNotificationSoundName("adhan.caf"))
            default: content.sound = .default
            }
            let parts = MalaysiaTime.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let request = UNNotificationRequest(identifier: "\(day.id)-\(prayer.rawValue)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
            try? await center.add(request)
        }}
    }
    func sendTestNotification() async throws {
        let content = UNMutableNotificationContent(); content.title = "Solat Notch"; content.body = "Peringatan macOS berfungsi dengan baik."; content.sound = .default
        try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "solat-notch-test", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)))
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions { [.banner, .sound, .list] }
}
