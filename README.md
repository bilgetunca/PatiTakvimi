# PatiTakvimi 🐾

PatiTakvimi is a SwiftUI-based pet care reminder application designed to help pet owners manage care routines efficiently.

The app enables structured event planning, real-time notification handling, and calendar-based tracking in a clean and modular architecture.

---

## 🚀 Core Features

- Add, edit, and delete care reminders
- Mini calendar with day-based event filtering
- Local notification scheduling
- Pet profile management
- Persistent storage with Core Data
- Smooth SwiftUI sheet-based navigation

---

## 🏗 Architecture & Technical Approach

- Built with **SwiftUI**
- Persistence layer implemented using **Core Data**
- Notification handling managed through a dedicated `LocalNotificationManager`
- Modular view structure (Dashboard, Calendar, Detail, Settings)
- Clean separation between UI and model logic

---

## 📱 Key Components

- `HomeDashboardView`
- `MiniCalendarView`
- `LocalNotificationManager`
- `AddEventSheet` / `EditEventSheet`
- `Persistence.swift`

---

## 🛠 Technologies

- Swift
- SwiftUI
- Core Data
- UserNotifications Framework
- MVVM-inspired structure

---

## ▶️ How to Run

1. Clone the repository
2. Open `PatiTakvim.xcodeproj`
3. Run on simulator or physical device

---

## 📌 Future Improvements

- Cloud sync support
- Multi-pet analytics dashboard
- Widget integration
- iCloud backup support

