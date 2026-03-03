import Foundation
import UserNotifications

final class LocalNotificationManager {
    static let shared = LocalNotificationManager()
    private init() {}

    // Default hatırlatmalar (custom yoksa)
    static let defaultReminderDays: [Int] = [7, 3]

    // Kullanıcı hiçbir ayar yapmazsa default saat: 10:00
    static let defaultReminderHour: Int = 10
    static let defaultReminderMinute: Int = 0

    func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    // MARK: - Public API (ekle/edit/sil)

    func schedule(event: CareEvent, petName: String, hour: Int = -1, minute: Int = -1) {
        guard event.isNotificationEnabled else { return }

        if let exact = event.customReminderAt {
            scheduleExact(event: event, petName: petName, fireAt: exact)
            return
        }

        let leads = leadDays(for: event)
        for lead in leads {
            scheduleOne(event: event, petName: petName, leadDays: lead, hour: hour, minute: minute)
        }
    }

    func cancel(event: CareEvent) {
        let center = UNUserNotificationCenter.current()
        var ids = leadDays(for: event).map { notificationID(for: event, leadDays: $0) }
        ids.append(exactNotificationID(for: event))
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func reschedule(event: CareEvent, petName: String) {
        cancel(event: event)
        schedule(event: event, petName: petName)
    }

    // MARK: - Internals

    private func notificationID(for event: CareEvent, leadDays: Int) -> String {
        "careevent-\(event.id.uuidString)-d\(leadDays)"
    }

    private func exactNotificationID(for event: CareEvent) -> String {
        "careevent-\(event.id.uuidString)-exact"
    }

    private func leadDays(for event: CareEvent) -> [Int] {
        let list = (event.reminderDays?.isEmpty == false) ? (event.reminderDays ?? []) : Self.defaultReminderDays
        let cleaned = list.map { max(0, $0) }.filter { $0 <= 365 }
        return Array(Set(cleaned)).sorted()
    }

    private func scheduleExact(event: CareEvent, petName: String, fireAt: Date) {
        let cal = Calendar.current
        let now = Date()

        // Geçmişte kalan tarihleri planlama
        guard fireAt > now else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(petName) • \(event.category.rawValue)"
        content.body = "Hatırlatma: \(RelativeDateText.smallDate(event.date))"
        content.sound = .default
        content.badge = 1

        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let id = exactNotificationID(for: event)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.add(req)
    }

    private func scheduleOne(event: CareEvent, petName: String, leadDays: Int, hour: Int, minute: Int) {
        let cal = Calendar.current
        let now = Date()

        if cal.startOfDay(for: event.date) < cal.startOfDay(for: now) { return }

        let useHour: Int
        let useMinute: Int
        if (0...23).contains(hour) && (0...59).contains(minute) {
            useHour = hour
            useMinute = minute
        } else {
            useHour = Self.defaultReminderHour
            useMinute = Self.defaultReminderMinute
        }

        let eventDay = cal.startOfDay(for: event.date)
        guard let baseFire = cal.date(byAdding: .day, value: -leadDays, to: eventDay) else { return }
        let fireAt = cal.date(bySettingHour: useHour, minute: useMinute, second: 0, of: baseFire) ?? baseFire

        // Geçmişte kalan lead'leri planlama
        guard fireAt > now else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(petName) • \(event.category.rawValue)"
        content.body  = "\(leadDays) gün kaldı • \(RelativeDateText.smallDate(event.date))"
        content.sound = .default

        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let id = notificationID(for: event, leadDays: leadDays)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id]) // idempotent
        center.add(req)
    }
}
