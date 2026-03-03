import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var r1 = false
    @State private var r3 = true
    @State private var r7 = true

    @State private var time: Date = Date()

    var body: some View {
        ZStack {
            NeonBackground().opacity(0.9)

            VStack(spacing: 14) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ayarlar")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Özelleştirilmiş hatırlatmalar için varsayılanlar. Otomatik hatırlatma: 7 ve 3 gün kala 10:00.")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Bildirimler")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Varsayılan hatırlatma günleri")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))

                            HStack(spacing: 10) {
                                ReminderChip(title: "1 gün", isOn: $r1)
                                ReminderChip(title: "3 gün", isOn: $r3)
                                ReminderChip(title: "7 gün", isOn: $r7)
                                Spacer(minLength: 0)
                            }

                            Text("Etkinlik içinde " + "Hatırlatmayı özelleştir" + " açarsan bunlar kullanılır. Hiçbir şey seçmezsen otomatik 7 & 3 gün kala 10:00 çalışır.")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.65))
                        }

                        Divider().background(Color.white.opacity(0.15))

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Özelleştirilmiş hatırlatma saati")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))

                            DatePicker("", selection: $time, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .tint(.white)
                        }
                    }
                }

                Button {
                    settings.resetToDefaults()
                    hydrate()
                } label: {
                    Text("Varsayılanlara Sıfırla (7/3 • 10:00)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                HStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Kapat")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    Button {
                        apply()
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
                    .disabled(!r1 && !r3 && !r7)
                    .opacity((!r1 && !r3 && !r7) ? 0.6 : 1.0)
                }
            }
            .padding(16)
        }
        .onAppear { hydrate() }
    }

    private func hydrate() {
        let days = settings.defaultReminderDays
        r1 = days.contains(1)
        r3 = days.contains(3)
        r7 = days.contains(7)

        var comps = DateComponents()
        comps.hour = settings.notificationHour
        comps.minute = settings.notificationMinute
        time = Calendar.current.date(from: comps) ?? Date()
    }

    private func apply() {
        var days: [Int] = []
        if r1 { days.append(1) }
        if r3 { days.append(3) }
        if r7 { days.append(7) }

        // normalize
        days = Array(Set(days)).sorted()
        settings.saveReminderDays(days)

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
