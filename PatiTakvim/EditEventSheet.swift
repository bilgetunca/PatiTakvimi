import SwiftUI

struct EditEventSheet: View {
    @Binding var event: CareEvent
    var onSave: (CareEvent) -> Void
    var onDelete: (CareEvent) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var notify: Bool = true

    @State private var useCustomReminders: Bool = false
    @State private var useExactReminder: Bool = false
    @State private var exactReminderAt: Date = Date().addingTimeInterval(3600)

    @State private var remind1: Bool = false
    @State private var remind3: Bool = false
    @State private var remind7: Bool = false
    @State private var pop: Bool = false

    var body: some View {
        ZStack {
            NeonBackground().opacity(0.9)
            VStack(spacing: 14) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Düzenle • \(event.category.rawValue)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Tarih, not ve bildirim ayarlarını güncelleyebilirsin.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
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
                                        .foregroundStyle(.white.opacity(0.8))

                                    DatePicker("", selection: $exactReminderAt, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .tint(.white)
                                }

                                Text("Not: Özel tarih/saat seçince 7 ve 3 gün kala otomatik hatırlatmalar devre dışı kalır.")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.65))
                            } else {
                                Toggle("Hatırlatmayı özelleştir", isOn: $useCustomReminders)
                                    .tint(.cyan)

                                if useCustomReminders {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Kaç gün önce hatırlatsın?")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.8))

                                        HStack(spacing: 10) {
                                            ReminderChip(title: "1 gün", isOn: $remind1)
                                            ReminderChip(title: "3 gün", isOn: $remind3)
                                            ReminderChip(title: "7 gün", isOn: $remind7)
                                        }
                                    }
                                } else {
                                    Text("Otomatik: 7 ve 3 gün kala saat 10:00")
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
                    Button("Sil", role: .destructive) {
                        onDelete(event)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)

                    Button("Kaydet") {
                        applyToBinding()
                        onSave(event)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.cyan, .pink], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
                    .disabled(notify && !useExactReminder && useCustomReminders && selectedReminderDays().isEmpty)
                    .opacity(notify && !useExactReminder && useCustomReminders && selectedReminderDays().isEmpty ? 0.6 : 1)
                }
            }
            .padding()
        }
        .onAppear { hydrateFromBinding() }
    }

    private func hydrateFromBinding() {
        date = event.date
        note = event.note
        notify = event.isNotificationEnabled

        if let exact = event.customReminderAt {
            useExactReminder = true
            exactReminderAt = exact
            useCustomReminders = false
            remind1 = false
            remind3 = false
            remind7 = false
            return
        }

        useExactReminder = false

        if let days = event.reminderDays, !days.isEmpty {
            useCustomReminders = true
            remind1 = days.contains(1)
            remind3 = days.contains(3)
            remind7 = days.contains(7)
        } else {
            useCustomReminders = false
            remind1 = false
            remind3 = false
            remind7 = false
        }
    }

    private func selectedReminderDays() -> [Int] {
        var arr: [Int] = []
        if remind1 { arr.append(1) }
        if remind3 { arr.append(3) }
        if remind7 { arr.append(7) }
        return arr
    }

    private func applyToBinding() {
        event.date = date
        event.note = note
        event.isNotificationEnabled = notify

        if !notify {
            event.reminderDays = nil
            event.customReminderAt = nil
            return
        }

        if useExactReminder {
            event.customReminderAt = exactReminderAt
            event.reminderDays = nil
            return
        }

        event.customReminderAt = nil

        if useCustomReminders {
            let arr = selectedReminderDays()
            event.reminderDays = arr.isEmpty ? nil : arr
        } else {
            event.reminderDays = nil
        }
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
        }
        .buttonStyle(.plain)
    }
}
