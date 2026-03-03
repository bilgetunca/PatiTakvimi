//
//  PatiTakvimApp.swift
//  PatiTakvim
//
//  Created by bilge tunca on 18.12.2025.
//

import SwiftUI
import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    // App açıkken de banner göster
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
}

@main
struct PatiTakvimApp: App {
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
