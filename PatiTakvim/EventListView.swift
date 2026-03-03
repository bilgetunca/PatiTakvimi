import SwiftUI

struct EventListView: View {
    let pet: PetDraft
    let category: CareCategory
    @Binding var events: [CareEvent]
    @EnvironmentObject private var settings: AppSettings

    @State private var showAdd = false
    @State private var editTarget: EditTarget? = nil

    struct EditTarget: Identifiable {
        let id: UUID
    }

    private var filtered: [CareEvent] {
        events
            .filter { $0.petID == pet.id && $0.category == category }
            .sorted { $0.date < $1.date }
    }

    private func scheduleNotifications(for ev: CareEvent) {
        let manager = LocalNotificationManager.shared
        manager.requestAuthorizationIfNeeded()
        manager.cancel(event: ev)
        guard ev.isNotificationEnabled else { return }

        // 1) Tam tarih/saat seçildiyse (exact)
        if ev.customReminderAt != nil {
            manager.schedule(event: ev, petName: pet.displayName)
            return
        }

        // 2) Kullanıcı günleri özelleştirdiyse: settings saatini kullan
        if let days = ev.reminderDays, !days.isEmpty {
            manager.schedule(
                event: ev,
                petName: pet.displayName,
                hour: settings.notificationHour,
                minute: settings.notificationMinute
            )
            return
        }

        // 3) Otomatik: 7 & 3 gün kala 10:00 (manager default)
        manager.schedule(event: ev, petName: pet.displayName)
    }

    private func cancelNotifications(for ev: CareEvent) {
        LocalNotificationManager.shared.cancel(event: ev)
    }

    var body: some View {
        ZStack {
            NeonBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(pet.displayName) • \(category.rawValue)")
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Tarihe dokun → düzenle. Düzenle ekranında alttan Sil/Kaydet kullan.")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    if filtered.isEmpty {
                        GlassCard {
                            VStack(spacing: 10) {
                                Image(systemName: category.systemIcon)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.9))

                                Text("Henüz kayıt yok")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Sağ üstten + ile ilk tarihi ekle.")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filtered) { ev in
                                Button {
                                    editTarget = EditTarget(id: ev.id)
                                } label: {
                                    EventRow(event: ev)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        cancelNotifications(for: ev)
                                        events.removeAll { $0.id == ev.id }
                                    } label: {
                                        Label("Sil", systemImage: "trash")
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
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddEventSheet(petID: pet.id, category: category) { newEvent in
                events.append(newEvent)
                scheduleNotifications(for: newEvent)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $editTarget) { target in
            if let idx = events.firstIndex(where: { $0.id == target.id }) {
                EditEventSheet(
                    event: $events[idx],
                    onSave: { _ in
                        // Binding zaten güncellendi; en güncel event'i tekrar schedule et.
                        scheduleNotifications(for: events[idx])
                    },
                    onDelete: { ev in
                        cancelNotifications(for: ev)
                        events.removeAll { $0.id == ev.id }
                    }
                )
                .presentationDetents([.medium, .large])
            } else {
                ZStack {
                    NeonBackground()
                    Text("Kayıt bulunamadı")
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

private struct EventRow: View {
    let event: CareEvent

    private var reminderText: String {
        guard event.isNotificationEnabled else { return "Bildirim kapalı" }

        // Kullanıcı tam tarih/saat seçtiyse
        if let exact = event.customReminderAt {
            let f = DateFormatter()
            f.locale = Locale(identifier: "tr_TR")
            f.dateFormat = "d MMM HH:mm"
            return "Özel: \(f.string(from: exact))"
        }

        // Kullanıcı hiçbir şey ayarlamadıysa: otomatik 7/3 @ 10:00
        guard let days = event.reminderDays, !days.isEmpty else {
            let list = LocalNotificationManager.defaultReminderDays
                .sorted()
                .map { "\($0)g" }
                .joined(separator: " • ")
            return "Otomatik: \(list) • 10:00"
        }

        // Kullanıcı günleri özelleştirdiyse
        let list = days.sorted().map { "\($0)g" }.joined(separator: " • ")
        return "Hatırlatma: \(list)"
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: event.category.systemIcon)
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
                    Text(RelativeDateText.subtitle(for: event.date))
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("\(RelativeDateText.smallDate(event.date)) • \(reminderText)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "pencil")
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }
}
