import Foundation
import Combine

final class AppSettings: ObservableObject {

    // MARK: Defaults
    static let defaultReminderDaysFallback: [Int] = [7, 3]
    static let defaultNotificationHourFallback: Int = 10
    static let defaultNotificationMinuteFallback: Int = 0

    private enum Keys {
        static let defaultRemindersRaw = "settings_default_reminders_raw"
        static let notificationHour = "settings_notification_hour"
        static let notificationMinute = "settings_notification_minute"
    }

    @Published var defaultReminderDays: [Int]
    @Published var notificationHour: Int
    @Published var notificationMinute: Int

    init() {
        let raw = UserDefaults.standard.string(forKey: Keys.defaultRemindersRaw) ?? "7,3"
        let parsed = raw
            .split(separator: ",")
            .compactMap { Int($0) }
            .filter { $0 >= 0 && $0 <= 365 }

        let normalized = Array(Set(parsed)).sorted()
        self.defaultReminderDays = normalized.isEmpty ? Self.defaultReminderDaysFallback : normalized

        let h = UserDefaults.standard.object(forKey: Keys.notificationHour) as? Int ?? Self.defaultNotificationHourFallback
        let m = UserDefaults.standard.object(forKey: Keys.notificationMinute) as? Int ?? Self.defaultNotificationMinuteFallback
        self.notificationHour = min(max(h, 0), 23)
        self.notificationMinute = min(max(m, 0), 59)

        // Self-heal persisted values if they were invalid/out of range
        if h != notificationHour {
            UserDefaults.standard.set(notificationHour, forKey: Keys.notificationHour)
        }
        if m != notificationMinute {
            UserDefaults.standard.set(notificationMinute, forKey: Keys.notificationMinute)
        }
    }

    func saveReminderDays(_ days: [Int]) {
        let cleaned = Array(Set(days))
            .map { max(0, min(365, $0)) }
            .sorted()

        defaultReminderDays = cleaned
        let raw = cleaned.map(String.init).joined(separator: ",")
        UserDefaults.standard.set(raw, forKey: Keys.defaultRemindersRaw)
    }

    func saveTime(hour: Int, minute: Int) {
        notificationHour = min(max(hour, 0), 23)
        notificationMinute = min(max(minute, 0), 59)

        UserDefaults.standard.set(notificationHour, forKey: Keys.notificationHour)
        UserDefaults.standard.set(notificationMinute, forKey: Keys.notificationMinute)
    }
    func resetToDefaults() {
        saveReminderDays(Self.defaultReminderDaysFallback)
        saveTime(hour: Self.defaultNotificationHourFallback, minute: Self.defaultNotificationMinuteFallback)
    }
}
