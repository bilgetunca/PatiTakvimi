//
//  MiniCalendarView.swift
//  PatiTakvim
//
//  Created by bilge tunca on 21.12.2025.
//

import SwiftUI

struct MiniCalendarView: View {
    let petID: UUID
    let events: [CareEvent]
    var onEditEvent: (UUID) -> Void = { _ in }

    @State private var currentMonth: Date = Date()
    @State private var selectedDay: Date = Date()

    private let calendar = Calendar.current

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Button {
                        changeMonth(-1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(monthTitle)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        changeMonth(1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                }

                // Weekdays
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Days grid
                let days = daysInMonth
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    ForEach(days, id: \.self) { day in
                        VStack(spacing: 6) {
                            Text("\(calendar.component(.day, from: day))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(
                                    calendar.isDate(day, equalTo: currentMonth, toGranularity: .month)
                                    ? .white
                                    : .white.opacity(0.25)
                                )
                                .frame(width: 28, height: 28)
                                .background(
                                    calendar.isDate(day, inSameDayAs: selectedDay)
                                    ? Color.white
                                    : Color.clear
                                )
                                .foregroundStyle(
                                    calendar.isDate(day, inSameDayAs: selectedDay)
                                    ? .black
                                    : .white
                                )
                                .clipShape(Circle())
                                .onTapGesture {
                                    selectedDay = day
                                }

                            if !events(on: day).isEmpty {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.2))

                // Selected day events
                if events(on: selectedDay).isEmpty {
                    Text("Bu gün için hatırlatma yok")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    VStack(spacing: 6) {
                        ForEach(events(on: selectedDay)) { ev in
                            Button {
                                onEditEvent(ev.id)
                            } label: {
                                HStack {
                                    Image(systemName: ev.category.systemIcon)
                                    Text(ev.category.rawValue)
                                    Spacer()
                                    Image(systemName: "pencil")
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func events(on day: Date) -> [CareEvent] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        return events
            .filter { $0.petID == petID }
            .filter { $0.date >= start && $0.date < end }
            .sorted { $0.date < $1.date }
    }

    private var weekdays: [String] {
        ["P", "S", "Ç", "P", "C", "C", "P"]
    }

    private var daysInMonth: [Date] {
        guard
            let interval = calendar.dateInterval(of: .month, for: currentMonth),
            let firstWeekday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: interval.start))
        else { return [] }

        let daysCount = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 30
        let firstDayOffset = calendar.dateComponents([.day], from: firstWeekday, to: interval.start).day ?? 0

        let totalCells = ((daysCount + firstDayOffset + 6) / 7) * 7

        return (0..<totalCells).compactMap { idx in
            calendar.date(byAdding: .day, value: idx - firstDayOffset, to: interval.start)
        }
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: currentMonth).capitalized
    }

    private func changeMonth(_ offset: Int) {
        if let new = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = new
        }
    }
}
