import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum PetType: String, CaseIterable, Identifiable, Codable {
    case cat = "Kedi"
    case dog = "Köpek"
    case bird = "Kuş"
    case fish = "Balık"
    case rabbit = "Tavşan"
    case hamster = "Hamster"
    case turtle = "Kaplumbağa"
    case reptile = "Sürüngen"
    case other = "Diğer"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .cat: return "🐱"
        case .dog: return "🐶"
        case .bird: return "🦜"
        case .fish: return "🐠"
        case .rabbit: return "🐰"
        case .hamster: return "🐹"
        case .turtle: return "🐢"
        case .reptile: return "🦎"
        case .other: return "🐾"
        }
    }
}

enum PetDocumentType: String, Codable, CaseIterable, Identifiable {
    case passport = "Pasaport"
    case vaccineCard = "Aşı Karnesi"
    case chip = "Mikroçip Belgesi"
    case report = "Veteriner Raporu"
    case other = "Diğer"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .passport: return "person.text.rectangle"
        case .vaccineCard: return "cross.case.fill"
        case .chip: return "qrcode"
        case .report: return "doc.text.fill"
        case .other: return "paperclip"
        }
    }
}

struct PetDocument: Identifiable, Equatable, Codable {
    let id: UUID
    var type: PetDocumentType
    var title: String
    var fileName: String
    var data: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        type: PetDocumentType = .other,
        title: String,
        fileName: String,
        data: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.fileName = fileName
        self.data = data
        self.createdAt = createdAt
    }
}

struct PetDraft: Identifiable, Equatable, Codable {
    let id: UUID
    var type: PetType
    var name: String
    var breed: String

    // Fotoğraf
    var photoData: Data?

    // Doğum tarihi (biliyorsa)
    var birthDate: Date?

    // Doğum tarihi bilinmiyorsa yaklaşık yaş
    var approxAgeYears: Int?
    var approxAgeMonths: Int?

    // Kilo
    var weightKg: Double?
    var weightUpdatedAt: Date?

    // Belgeler
    var documents: [PetDocument]

    init(
        id: UUID = UUID(),
        type: PetType = .cat,
        name: String = "",
        breed: String = "",
        photoData: Data? = nil,
        birthDate: Date? = nil,
        approxAgeYears: Int? = nil,
        approxAgeMonths: Int? = nil,
        weightKg: Double? = nil,
        weightUpdatedAt: Date? = nil,
        documents: [PetDocument] = []
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.breed = breed
        self.photoData = photoData
        self.birthDate = birthDate
        self.approxAgeYears = approxAgeYears
        self.approxAgeMonths = approxAgeMonths
        self.weightKg = weightKg
        self.weightUpdatedAt = weightUpdatedAt
        self.documents = documents
    }

    var displayName: String {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Yeni Evcil" : t
    }

    #if canImport(UIKit)
    var uiImage: UIImage? {
        guard let photoData else { return nil }
        return UIImage(data: photoData)
    }
    #endif

    var ageText: String {
        if let birthDate {
            let c = Calendar.current
            let comps = c.dateComponents([.year, .month], from: birthDate, to: Date())
            let y = max(0, comps.year ?? 0)
            let m = max(0, comps.month ?? 0)
            if y == 0 && m == 0 { return "0 ay" }
            if y == 0 { return "\(m) ay" }
            if m == 0 { return "\(y) yıl" }
            return "\(y) yıl \(m) ay"
        }

        let y = approxAgeYears
        let m = approxAgeMonths
        if y == nil && m == nil { return "—" }

        let yy = max(0, y ?? 0)
        let mm = max(0, m ?? 0)

        if yy == 0 && mm == 0 { return "0 ay" }
        if yy == 0 { return "\(mm) ay" }
        if mm == 0 { return "\(yy) yıl" }
        return "\(yy) yıl \(mm) ay"
    }
}
