import SwiftUI

struct StreakView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var selectedDate: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your journey")
                        .monoLabel()

                    HStack(spacing: 0) {
                        Text("Your ")
                            .font(.instrumentSerif(size: 34))
                        Text("progress")
                            .font(.instrumentSerifItalic(size: 34))
                    }
                    .foregroundColor(.ink)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 14)

                StreakHeroCard(sessionManager: sessionManager)

                HeatmapCalendarCard(sessionManager: sessionManager, selectedDate: $selectedDate)

                if let date = selectedDate {
                    DayDetailCard(sessionManager: sessionManager, date: date)
                }

                MilestonesCard(sessionManager: sessionManager)
            }
            .padding(.bottom, 100)
            .animation(.spring(response: 0.3), value: selectedDate)
        }
        .background(Color.bg)
    }
}

// MARK: - Streak Hero (Compact)
struct StreakHeroCard: View {
    var sessionManager: SessionManager

    private var streak: Int { sessionManager.currentStreak() }
    private var best: Int { sessionManager.bestStreak() }
    private var isPersonalBest: Bool { streak >= best && streak > 0 }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.amber)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(streak)")
                            .font(.instrumentSerif(size: 34))
                        Text("d")
                            .font(.instrumentSerifItalic(size: 16))
                            .foregroundColor(.ink2)
                    }
                    .foregroundColor(.ink)

                    HStack(spacing: 6) {
                        Text("Current streak")
                            .monoLabel()
                        if isPersonalBest {
                            Text("BEST")
                                .font(.geistMono(size: 8, weight: .bold))
                                .kerning(1)
                                .foregroundColor(.amber)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.amber.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().frame(height: 44)

            VStack(spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(best)")
                        .font(.instrumentSerif(size: 34))
                    Text("d")
                        .font(.instrumentSerifItalic(size: 16))
                        .foregroundColor(.ink2)
                }
                .foregroundColor(.ink)

                Text("Best streak")
                    .monoLabel()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

// MARK: - Heatmap Calendar
struct HeatmapCalendarCard: View {
    var sessionManager: SessionManager
    @Binding var selectedDate: Date?

    private let cellSpacing: CGFloat = 3
    private let cal = Calendar.current

    private var installDate: Date {
        UserDefaults.standard.object(forKey: "appInstallDate") as? Date ?? Date()
    }

    private var weeksCount: Int {
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: installDate), to: cal.startOfDay(for: Date())).day ?? 0
        return max(min((days / 7) + 2, 16), 2)
    }

    private var cellSize: CGFloat {
        let available = UIScreen.main.bounds.width - 93
        let size = (available - CGFloat(max(weeksCount - 1, 0)) * cellSpacing) / CGFloat(max(weeksCount, 1))
        return min(max(size, 12), 22)
    }

    private var heatmapData: [Date: Int] {
        sessionManager.minutesByDay(weeks: weeksCount)
    }

    private var maxMinutes: Int {
        max(heatmapData.values.max() ?? 1, 1)
    }

    private var gridDays: [Date] {
        let today = cal.startOfDay(for: Date())
        let todayWeekday = cal.component(.weekday, from: today)
        let endOfWeek = cal.date(byAdding: .day, value: 7 - todayWeekday, to: today)!
        guard let startDate = cal.date(byAdding: .day, value: -(weeksCount * 7 - 1), to: endOfWeek) else { return [] }

        var days: [Date] = []
        var current = startDate
        while current <= endOfWeek {
            days.append(current)
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }
        return days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(.ink2)
                    Text("Activity")
                        .monoLabel()
                }

                Spacer()

                Text("Last \(weeksCount) weeks")
                    .font(.geistMono(size: 10))
                    .foregroundColor(.ink3)
            }

            HStack(alignment: .top, spacing: cellSpacing) {
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    ForEach(0..<7, id: \.self) { day in
                        if day == 1 || day == 3 || day == 5 {
                            Text(dayLabel(day))
                                .font(.geistMono(size: 9))
                                .foregroundColor(.ink3)
                                .frame(height: cellSize)
                        } else {
                            Color.clear.frame(height: cellSize)
                        }
                    }
                }
                .frame(width: 18)

                HStack(spacing: cellSpacing) {
                    ForEach(0..<weeksCount, id: \.self) { week in
                        VStack(spacing: cellSpacing) {
                            ForEach(0..<7, id: \.self) { day in
                                let index = week * 7 + day
                                if index < gridDays.count {
                                    let date = gridDays[index]
                                    let minutes = heatmapData[date] ?? 0
                                    let today = cal.startOfDay(for: Date())
                                    let isFuture = date > today
                                    let isSelected = selectedDate.map { cal.isDate($0, inSameDayAs: date) } ?? false

                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(isFuture ? Color.clear : cellColor(minutes: minutes))
                                        .frame(width: cellSize, height: cellSize)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(
                                                    isSelected ? Color.ink : (isFuture ? Color.line.opacity(0.3) : Color.clear),
                                                    lineWidth: isSelected ? 2 : 0.5
                                                )
                                        )
                                        .onTapGesture {
                                            guard !isFuture else { return }
                                            withAnimation(.spring(response: 0.25)) {
                                                if isSelected {
                                                    selectedDate = nil
                                                } else {
                                                    selectedDate = date
                                                }
                                            }
                                        }
                                } else {
                                    Color.clear.frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                if selectedDate == nil {
                    Text("Tap a day for details")
                        .font(.geistMono(size: 9))
                        .foregroundColor(.ink3)
                }

                Spacer()

                Text("Less")
                    .font(.geistMono(size: 9))
                    .foregroundColor(.ink3)

                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.bg2)
                        .frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.sage.opacity(0.25))
                        .frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.sage.opacity(0.45))
                        .frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.sage.opacity(0.7))
                        .frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.sage)
                        .frame(width: 12, height: 12)
                }

                Text("More")
                    .font(.geistMono(size: 9))
                    .foregroundColor(.ink3)
            }
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private func cellColor(minutes: Int) -> Color {
        guard minutes > 0 else { return Color.bg2 }
        let ratio = Double(minutes) / Double(maxMinutes)
        if ratio < 0.25 { return Color.sage.opacity(0.25) }
        if ratio < 0.5 { return Color.sage.opacity(0.45) }
        if ratio < 0.75 { return Color.sage.opacity(0.7) }
        return Color.sage
    }

    private func dayLabel(_ day: Int) -> String {
        switch day {
        case 1: return "M"
        case 3: return "W"
        case 5: return "F"
        default: return ""
        }
    }
}

// MARK: - Day Detail
struct DayDetailCard: View {
    var sessionManager: SessionManager
    let date: Date

    private var minutesSaved: Int { sessionManager.minutesSavedForDate(date) }
    private var sessionCount: Int { sessionManager.sessionsForDate(date).count }
    private var topApps: [(appName: String, count: Int)] { sessionManager.attemptCountsByAppForDate(date) }
    private var totalAttempts: Int { sessionManager.totalAttemptsForDate(date) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .font(.instrumentSerif(size: 22))
                .foregroundColor(.ink)

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(minutesSaved / 60)")
                            .font(.instrumentSerif(size: 28))
                            .foregroundColor(.ink)
                        Text("h \(minutesSaved % 60)m")
                            .font(.instrumentSerifItalic(size: 14))
                            .foregroundColor(.ink2)
                    }
                    Text("Blocked")
                        .monoLabel()
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 36)

                VStack(spacing: 4) {
                    Text("\(sessionCount)")
                        .font(.instrumentSerif(size: 28))
                        .foregroundColor(.ink)
                    Text("Sessions")
                        .monoLabel()
                }
                .frame(maxWidth: .infinity)

                Divider().frame(height: 36)

                VStack(spacing: 4) {
                    Text("\(totalAttempts)")
                        .font(.instrumentSerif(size: 28))
                        .foregroundColor(.ink)
                    Text("Attempts")
                        .monoLabel()
                }
                .frame(maxWidth: .infinity)
            }

            if !topApps.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Most blocked")
                        .monoLabel()

                    ForEach(topApps.prefix(5), id: \.appName) { app in
                        HStack(spacing: 10) {
                            AppIconView(name: app.appName, size: 26)

                            Text(app.appName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.ink)

                            Spacer()

                            Text("\(app.count)")
                                .font(.geistMono(size: 13))
                                .foregroundColor(.ink3)
                        }
                    }
                }
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

// MARK: - Milestones
struct MilestonesCard: View {
    var sessionManager: SessionManager

    private var milestones: [(icon: String, title: String, subtitle: String, achieved: Bool)] {
        let streak = sessionManager.currentStreak()
        let totalSessions = sessionManager.allTimeSessionCount()
        let totalHours = sessionManager.allTimeTotalMinutesSaved() / 60

        return [
            ("flame.fill", "First Spark", "Complete your first session", totalSessions >= 1),
            ("flame.fill", "On Fire", "3-day streak", streak >= 3),
            ("flame.fill", "Unstoppable", "7-day streak", streak >= 7),
            ("flame.fill", "Legendary", "30-day streak", streak >= 30),
            ("clock.fill", "Time Saver", "Save 1 hour total", totalHours >= 1),
            ("clock.fill", "Deep Focus", "Save 10 hours total", totalHours >= 10),
            ("shield.fill", "Committed", "10 sessions complete", totalSessions >= 10),
            ("shield.fill", "Devoted", "50 sessions complete", totalSessions >= 50),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.amber)
                Text("Milestones")
                    .monoLabel()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(0..<milestones.count, id: \.self) { i in
                    let m = milestones[i]
                    HStack(spacing: 10) {
                        Image(systemName: m.icon)
                            .font(.system(size: 16))
                            .foregroundColor(m.achieved ? .amber : .ink3.opacity(0.4))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(m.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(m.achieved ? .ink : .ink3)

                            Text(m.subtitle)
                                .font(.system(size: 10))
                                .foregroundColor(.ink3)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(10)
                    .background(m.achieved ? Color.amber.opacity(0.08) : Color.bg2.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(m.achieved ? Color.amber.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

#Preview {
    StreakView()
        .environmentObject(SessionManager.shared)
}
