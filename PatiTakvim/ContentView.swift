import UserNotifications
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @State private var pets: [PetDraft] = []
    @State private var selectedPetID: UUID? = nil
    @State private var events: [CareEvent] = []

    @State private var showWizard = false
    @State private var showSplash = false

    @StateObject private var settings = AppSettings()

    @AppStorage("ptk_pets_json") private var petsJSON: Data = Data()
    @AppStorage("ptk_selected_pet_id") private var selectedPetIDString: String = ""
    @AppStorage("ptk_events_json") private var eventsJSON: Data = Data()

    var body: some View {
        ZStack {
            NeonBackground()
            mainContent
        }
        .environmentObject(settings)
        .onAppear(perform: handleAppear)
        .onChange(of: pets) { _, _ in
            saveState()
            resyncNotifications()
        }
        .onChange(of: events) { _, _ in
            saveState()
            resyncNotifications()
        }
        // ✅ Varsayılanlar değişince de yeniden schedule
        .onChange(of: settings.notificationHour) { _, _ in resyncNotifications() }
        .onChange(of: settings.notificationMinute) { _, _ in resyncNotifications() }
        .onChange(of: settings.defaultReminderDays) { _, _ in resyncNotifications() }
        .sheet(isPresented: $showWizard) {
            AddPetWizardView { newPet in
                pets.append(newPet)
                if selectedPetID == nil { selectedPetID = newPet.id }
            }
            .presentationDetents([.large])
            .environmentObject(settings)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if pets.isEmpty {
            WelcomeView { showWizard = true }
        } else if showSplash {
            SplashWelcomeView()
                .transition(.opacity)
        } else {
            HomeDashboardView(
                pets: $pets,
                selectedPetID: $selectedPetID,
                events: $events,
                onAddPet: { showWizard = true }
            )
            .transition(.opacity)
        }
    }

    private func handleAppear() {
        loadState()
        resyncNotifications()

        #if canImport(UIKit)
        UNUserNotificationCenter.current().setBadgeCount(0)
        #endif

        if !pets.isEmpty {
            showSplash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }

    private func resyncNotifications() {
        let manager = LocalNotificationManager.shared
        manager.requestAuthorizationIfNeeded()

        // Basit ve güvenilir: her değişimde yeniden kur.
        for ev in events {
            manager.cancel(event: ev)
            guard ev.isNotificationEnabled else { continue }

            let petName = pets.first(where: { $0.id == ev.petID })?.displayName ?? "Evcil"

            // 1) Kullanıcı özel tarih+saat seçtiyse: sadece onu planla
            if ev.customReminderAt != nil {
                manager.schedule(event: ev, petName: petName)
                continue
            }

            // 2) Kullanıcı hatırlatma günlerini özelleştirdiyse: settings saatini kullan
            if let days = ev.reminderDays, !days.isEmpty {
                manager.schedule(
                    event: ev,
                    petName: petName,
                    hour: settings.notificationHour,
                    minute: settings.notificationMinute
                )
                continue
            }

            // 3) Hiçbir şey ayarlanmadıysa: otomatik 7 & 3 gün kala 10:00 (manager default)
            manager.schedule(event: ev, petName: petName)
        }
    }

    private func loadState() {
        if !petsJSON.isEmpty {
            do { pets = try JSONDecoder().decode([PetDraft].self, from: petsJSON) }
            catch { pets = []; petsJSON = Data() }
        }

        if let id = UUID(uuidString: selectedPetIDString) {
            selectedPetID = id
        } else {
            selectedPetID = pets.first?.id
        }

        if !eventsJSON.isEmpty {
            do { events = try JSONDecoder().decode([CareEvent].self, from: eventsJSON) }
            catch { events = []; eventsJSON = Data() }
        }
    }

    private func saveState() {
        do { petsJSON = try JSONEncoder().encode(pets) } catch {}
        selectedPetIDString = selectedPetID?.uuidString ?? ""
        do { eventsJSON = try JSONEncoder().encode(events) } catch {}
    }
}

private struct SplashWelcomeView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            VStack(spacing: 10) {
                Text("🐾")
                    .font(.system(size: 64))
                    .scaleEffect(pulse ? 1.05 : 0.95)
                    .shadow(color: .purple.opacity(0.4), radius: 18)

                Text("PatiTakvim")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Günlük bakım ve hatırlatmalar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
