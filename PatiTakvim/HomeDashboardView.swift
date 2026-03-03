import SwiftUI

struct HomeDashboardView: View {
    @Binding var pets: [PetDraft]
    @Binding var selectedPetID: UUID?
    @Binding var events: [CareEvent]
    var onAddPet: () -> Void

    @State private var selectedDay: Date = Date()

    private var selectedPet: PetDraft? {
        guard !pets.isEmpty else { return nil }
        if let id = selectedPetID, let found = pets.first(where: { $0.id == id }) { return found }
        return pets.first
    }

    private var calendar: Calendar { .current }

    private var selectedDayEventsForSelectedPet: [CareEvent] {
        guard let pet = selectedPet else { return [] }
        return events
            .filter { $0.petID == pet.id && calendar.isDate($0.date, inSameDayAs: selectedDay) }
            .sorted { $0.date < $1.date }
    }

    enum Route: Hashable {
        case events(petID: UUID, category: CareCategory)
        case petDetail(UUID)
    }

    var body: some View {
        
        NavigationStack {
            ZStack {
                NeonBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        petStrip

                        if let pet = selectedPet {
                            HStack {
                                Text("\(pet.displayName) için")
                                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)

                                Spacer()

                                NavigationLink(value: Route.petDetail(pet.id)) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle.fill")
                                        Text("\(pet.displayName)'nin profili")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                                }
                            }

                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                                alignment: .leading,
                                spacing: 14
                            ) {
                                trackerLinkCompact(for: pet, category: .vaccine)
                                trackerLinkCompact(for: pet, category: .internalParasite)
                                trackerLinkCompact(for: pet, category: .externalParasite)
                                trackerLinkCompact(for: pet, category: .vetCheck)
                            }

                            GlassCard {
                                MiniCalendarView(
                                    petID: pet.id,
                                    events: events,
                                    selectedDay: $selectedDay
                                )
                            }

                            // ✅ Seçilen güne göre hızlı özet (B seçiminin "filtre" kısmı)
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Seçili gün")
                                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                                            .foregroundStyle(.white)

                                        Spacer()

                                        Text(RelativeDateText.smallDate(selectedDay))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }

                                    if selectedDayEventsForSelectedPet.isEmpty {
                                        Text("Bu gün için hatırlatma yok.")
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.65))
                                    } else {
                                        VStack(spacing: 6) {
                                            ForEach(selectedDayEventsForSelectedPet.prefix(4)) { ev in
                                                HStack {
                                                    Image(systemName: ev.category.systemIcon)
                                                        .foregroundStyle(.white.opacity(0.9))
                                                    Text(ev.category.rawValue)
                                                        .foregroundStyle(.white.opacity(0.9))
                                                    Spacer()
                                                    Text(RelativeDateText.subtitle(for: ev.date))
                                                        .foregroundStyle(.white.opacity(0.7))
                                                }
                                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                            }

                                            if selectedDayEventsForSelectedPet.count > 4 {
                                                Text("+ \(selectedDayEventsForSelectedPet.count - 4) daha")
                                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                                    .foregroundStyle(.white.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
            
            .onChange(of: selectedPetID) { _, _ in
                // Pet değişince seçimi bugüne çek, yoksa kullanıcı kafayı yer.
                selectedDay = Date()
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .events(let petID, let category):
                    if let pet = pets.first(where: { $0.id == petID }) {
                        EventListView(pet: pet, category: category, events: $events)
                    } else {
                        ZStack {
                            NeonBackground()
                            Text("Evcil bulunamadı")
                                .foregroundStyle(.white)
                        }
                    }

                case .petDetail(let id):
                    if let idx = pets.firstIndex(where: { $0.id == id }) {
                        PetDetailView(pet: $pets[idx]) {
                            // 1) Bu pet'e ait event'lerin bildirimlerini iptal et
                            let toRemove = events.filter { $0.petID == id }
                            for ev in toRemove {
                                LocalNotificationManager.shared.cancel(event: ev)
                            }

                            // 2) Pet'i sil ve seçimi güncelle
                            pets.remove(at: idx)
                            if selectedPetID == id {
                                selectedPetID = pets.first?.id
                            }

                            // 3) Event'leri listeden kaldır
                            events.removeAll { $0.petID == id }
                        }
                    } else {
                        ZStack {
                            NeonBackground()
                            Text("Evcil bulunamadı")
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Pati Takvim")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Günlük bakım ve hatırlatmalar")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            Button(action: onAddPet) {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pati ekle")
        }
        .padding(.vertical, 10)
    }

    private var petStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(pets) { pet in
                    PetChip(
                        pet: pet,
                        isSelected: pet.id == (selectedPetID ?? pets.first?.id)
                    ) {
                        selectedPetID = pet.id
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func trackerLink(for pet: PetDraft, category: CareCategory) -> some View {
        let next = events.nextEvent(petID: pet.id, category: category)
        let subtitle: String
        if let next {
            subtitle = "\(RelativeDateText.subtitle(for: next.date)) • \(RelativeDateText.smallDate(next.date))"
        } else {
            subtitle = "Takvim ayarla"
        }

        return NavigationLink(value: Route.events(petID: pet.id, category: category)) {
            TrackerCard(
                title: category.rawValue,
                subtitle: subtitle,
                icon: category.systemIcon
            )
        }
        .buttonStyle(.plain)
    }

    private func trackerLinkCompact(for pet: PetDraft, category: CareCategory) -> some View {
        let next = events.nextEvent(petID: pet.id, category: category)
        let subtitle: String
        if let next {
            subtitle = RelativeDateText.smallDate(next.date)
        } else {
            subtitle = "Takvim ayarla"
        }

        return NavigationLink(value: Route.events(petID: pet.id, category: category)) {
            TrackerCardCompact(
                title: dashboardTitle(for: category),
                subtitle: subtitle,
                icon: category.systemIcon
            )
        }
        .buttonStyle(.plain)
    }

    private func dashboardTitle(for category: CareCategory) -> String {
        switch category {
        case .vetCheck:
            return "Veteriner"
        default:
            return category.rawValue
        }
    }
}

// MARK: - UI pieces

private struct PetChip: View {
    let pet: PetDraft
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    if let ui = pet.uiImage {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text(pet.type.emoji)
                            .font(.system(size: 34))
                    }
                }
                .frame(width: 66, height: 66)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(
                        Color.white.opacity(isSelected ? 0.30 : 0.14),
                        lineWidth: isSelected ? 2.2 : 1.2
                    )
                )
                .shadow(color: .white.opacity(isSelected ? 0.14 : 0.08), radius: 10, x: 0, y: 6)

                Text(pet.displayName)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(width: 78)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(isSelected ? 0.14 : 0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(isSelected ? 0.22 : 0.12), lineWidth: 1))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
    }
}

private struct TrackerCard: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }
}

private struct TrackerCardCompact: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        GlassCard {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.70))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
        .frame(height: 60)
    }
}
