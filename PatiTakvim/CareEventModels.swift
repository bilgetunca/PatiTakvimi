import Foundation

enum CareCategory: String, CaseIterable, Identifiable, Codable {
    case vaccine = "Aşı"
    case internalParasite = "İç Parazit"
    case externalParasite = "Dış Parazit"
    case vetCheck = "Veteriner Kontrol"

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .vaccine: return "syringe"
        case .internalParasite: return "pills"
        case .externalParasite: return "shield.lefthalf.filled"
        case .vetCheck: return "stethoscope"
        }
    }
}

struct CareEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var petID: UUID
    var category: CareCategory
    var date: Date

    var note: String
    var isNotificationEnabled: Bool

    /// Kullanıcı ayarlamazsa `nil` kalır → sistem default (7 ve 3 gün) kullanır.
    /// Ayarlarsa örn: [1] veya [3,7]
    var reminderDays: [Int]?

    /// Kullanıcı isterse bildirimi tam olarak istediği tarih+saatte alabilir.
    /// Doluysa: 7/3 gün kala mantığı devre dışı kalır ve sadece bu tarih planlanır.
    var customReminderAt: Date?

    init(
        id: UUID = UUID(),
        petID: UUID,
        category: CareCategory,
        date: Date,
        note: String = "",
        isNotificationEnabled: Bool = true,
        reminderDays: [Int]? = nil,
        customReminderAt: Date? = nil
    ) {
        self.id = id
        self.petID = petID
        self.category = category
        self.date = date
        self.note = note
        self.isNotificationEnabled = isNotificationEnabled
        self.reminderDays = reminderDays
        self.customReminderAt = customReminderAt
    }
}

// MARK: - Helpers

extension Array where Element == CareEvent {
    func nextEvent(petID: UUID, category: CareCategory, now: Date = Date()) -> CareEvent? {
        self
            .filter { $0.petID == petID && $0.category == category }
            .sorted { $0.date < $1.date }
            .first(where: { $0.date >= Calendar.current.startOfDay(for: now) })
        ?? self
            .filter { $0.petID == petID && $0.category == category }
            .sorted { $0.date < $1.date }
            .last
    }
}

struct RelativeDateText {
    static func subtitle(for date: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        let startNow = cal.startOfDay(for: now)
        let startDate = cal.startOfDay(for: date)

        let dayDiff = cal.dateComponents([.day], from: startNow, to: startDate).day ?? 0

        if dayDiff == 0 { return "Bugün" }
        if dayDiff == 1 { return "Yarın" }
        if dayDiff > 1 { return "\(dayDiff) gün sonra" }

        let past = abs(dayDiff)
        if past == 1 { return "Dün (geçti)" }
        return "\(past) gün geçti"
    }

    static func smallDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}
