import SwiftUI

struct AddEventSheet: View {
    let petID: UUID
    let category: CareCategory
    var onAdd: (CareEvent) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var date: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var note: String = ""
    @State private var notify: Bool = true

    @State private var remind1: Bool = false
    @State private var remind3: Bool = true
    @State private var remind7: Bool = true

    // ✅ yeni: kullanıcı isterse tek bir tarih+saat seçsin (lead days devre dışı)
    @State private var useExactReminder: Bool = false
    @State private var exactReminderAt: Date = Date().addingTimeInterval(3600)

    // ✅ yeni: kullanıcı lead-days'i özelleştirmek isterse
    @State private var useCustomReminders: Bool = false

    // ✅ yeni: seçimi varsayılan yap
    @State private var makeDefault: Bool = false

    // ✅ yeni: bildirim saati (global)
    @State private var time: Date = Date()

    var body: some View {
        ZStack {
            NeonBackground().opacity(0.9)

            VStack(spacing: 14) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yeni \(category.rawValue)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Tarihi seç, kaydet. İstersen bu seçimi varsayılan yap.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(category.rawValue, systemImage: category.systemIcon)
                                .foregroundStyle(.white)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                            Spacer()
                        }

                        DatePicker("Tarih", selection: $date, displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .tint(.white)

                        Toggle("Bildirim", isOn: $notify)
                            .tint(.cyan)

                        if notify {
                            Toggle("Özel tarih/saat seç", isOn: $useExactReminder)
                                .tint(.pink)

                            if useExactReminder {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bildirim tam olarak ne zaman gelsin?")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.85))

                                    DatePicker("", selection: $exactReminderAt, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .tint(.white)
                                }

                                Text("Not: Özel tarih/saat seçince 7 ve 3 gün kala otomatik hatırlatmalar devre dışı kalır.")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.65))
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bildirim saati")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.85))

                                    DatePicker("", selection: $time, displayedComponents: [.hourAndMinute])
                                        .labelsHidden()
                                        .tint(.white)
                                }

                                Divider().background(Color.white.opacity(0.15))

                                Toggle("Hatırlatmayı özelleştir", isOn: $useCustomReminders)
                                    .tint(.cyan)

                                if useCustomReminders {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Hatırlatma günleri")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.85))

                                        HStack(spacing: 10) {
                                            ReminderChip(title: "1 gün", isOn: $remind1)
                                            ReminderChip(title: "3 gün", isOn: $remind3)
                                            ReminderChip(title: "7 gün", isOn: $remind7)
                                            Spacer(minLength: 0)
                                        }

                                        Toggle("Bu seçimi varsayılan yap", isOn: $makeDefault)
                                            .tint(.orange)
                                    }
                                } else {
                                    Text("Otomatik: 7 gün ve 3 gün kala saat 10:00")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                            }
                        }

                        TextField("Not (opsiyonel)", text: $note)
                            .textInputAutocapitalization(.sentences)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Vazgeç")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button {
                        save()
                        dismiss()
                    } label: {
                        Text("Kaydet")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(colors: [Color.cyan, Color.pink],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(notify && !useExactReminder && useCustomReminders && selectedReminderDays().isEmpty)
                    .opacity(notify && !useExactReminder && useCustomReminders && selectedReminderDays().isEmpty ? 0.6 : 1.0)
                }
            }
            .padding(16)
        }
        .onAppear {
            hydrateFromDefaults()
        }
    }

    private func hydrateFromDefaults() {
        // Başlangıçta otomatik (7 ve 3 gün) çalışsın: event'e reminderDays yazmayacağız.
        useCustomReminders = false

        let days = settings.defaultReminderDays
        remind1 = days.contains(1)
        remind3 = days.contains(3)
        remind7 = days.contains(7)

        var comps = DateComponents()
        comps.hour = settings.notificationHour
        comps.minute = settings.notificationMinute
        time = Calendar.current.date(from: comps) ?? Date()
    }

    private func selectedReminderDays() -> [Int] {
        var arr: [Int] = []
        if remind1 { arr.append(1) }
        if remind3 { arr.append(3) }
        if remind7 { arr.append(7) }
        return Array(Set(arr)).sorted()
    }

    private func save() {
        // 1) Kullanıcı özel tarih+saat seçtiyse: sadece onu kaydet
        let customAt: Date? = (notify && useExactReminder) ? exactReminderAt : nil

        // 2) Özel tarih yoksa:
        // - useCustomReminders açıksa seçilen günleri yaz
        // - değilse nil bırak (otomatik 7 & 3 gün + 10:00)
        let daysForEvent: [Int]? = (notify && !useExactReminder && useCustomReminders) ? selectedReminderDays() : nil

        let new = CareEvent(
            petID: petID,
            category: category,
            date: date,
            note: note,
            isNotificationEnabled: notify,
            reminderDays: daysForEvent,
            customReminderAt: customAt
        )
        onAdd(new)

        // Varsayılanlara kaydetme:
        // - Bildirim kapalıysa zaten yok
        // - Özel tarih+saat seçildiyse varsayılan mantığına yazma
        // - Özelleştirme kapalıysa da varsayılanlara yazma
        guard notify, !useExactReminder, useCustomReminders, makeDefault else { return }

        settings.saveReminderDays(selectedReminderDays())

        let cal = Calendar.current
        settings.saveTime(
            hour: cal.component(.hour, from: time),
            minute: cal.component(.minute, from: time)
        )
    }
}

private struct ReminderChip: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isOn.toggle()
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isOn ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(isOn ? 0.22 : 0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
