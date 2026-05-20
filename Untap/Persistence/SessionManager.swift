import Foundation
import CoreData

class SessionManager: ObservableObject {
    static let shared = SessionManager()

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.viewContext }

    @Published var activeSession: CDBlockSession?
    @Published var lastCompletedSession: CDBlockSession?

    private init() {
        cleanupOrphanedSessions()
        loadActiveSession()
    }

    // MARK: - Refresh

    func refresh() {
        context.refreshAllObjects()
        loadActiveSession()
        objectWillChange.send()
    }

    // MARK: - Session Lifecycle

    func startSession() -> CDBlockSession {
        if let existing = activeSession {
            existing.endDate = Date()
            existing.isActive = false
            persistence.save()
        }

        let session = CDBlockSession(context: context)
        session.id = UUID()
        session.startDate = Date()
        session.isActive = true
        persistence.save()
        activeSession = session
        return session
    }

    func endSession() -> CDBlockSession? {
        guard let session = activeSession else { return nil }
        session.endDate = Date()
        session.isActive = false
        persistence.save()
        lastCompletedSession = session
        activeSession = nil
        return session
    }

    // MARK: - Block Attempts

    func recordAttempt(appIdentifier: String, appDisplayName: String) {
        guard let session = activeSession else { return }
        let attempt = CDBlockAttempt(context: context)
        attempt.id = UUID()
        attempt.appIdentifier = appIdentifier
        attempt.appDisplayName = appDisplayName
        attempt.timestamp = Date()
        attempt.session = session
        persistence.save()
        objectWillChange.send()
    }

    // MARK: - Queries

    func attemptsForSession(_ session: CDBlockSession) -> [CDBlockAttempt] {
        let request: NSFetchRequest<CDBlockAttempt> = CDBlockAttempt.fetchRequest()
        request.predicate = NSPredicate(format: "session == %@", session)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBlockAttempt.timestamp, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func attemptCountsByApp(for session: CDBlockSession) -> [(appName: String, count: Int)] {
        let attempts = attemptsForSession(session)
        var counts: [String: Int] = [:]
        for attempt in attempts {
            let name = attempt.appDisplayName ?? "Unknown"
            counts[name, default: 0] += 1
        }
        return counts.map { (appName: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func todaySessions() -> [CDBlockSession] {
        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        let startOfDay = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "startDate >= %@", startOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBlockSession.startDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func todayAttempts() -> [CDBlockAttempt] {
        let request: NSFetchRequest<CDBlockAttempt> = CDBlockAttempt.fetchRequest()
        let startOfDay = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "timestamp >= %@", startOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBlockAttempt.timestamp, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Date-Specific Queries

    func sessionsForDate(_ date: Date) -> [CDBlockSession] {
        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        request.predicate = NSPredicate(format: "startDate >= %@ AND startDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBlockSession.startDate, ascending: false)]
        return (try? context.fetch(request)) ?? []
    }

    func minutesSavedForDate(_ date: Date) -> Int {
        let sessions = sessionsForDate(date)
        var total: TimeInterval = 0
        for session in sessions {
            let end = session.endDate ?? Date()
            let start = session.startDate ?? Date()
            total += end.timeIntervalSince(start)
        }
        return Int(total / 60)
    }

    func attemptCountsByAppForDate(_ date: Date) -> [(appName: String, count: Int)] {
        let request: NSFetchRequest<CDBlockAttempt> = CDBlockAttempt.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        let attempts = (try? context.fetch(request)) ?? []
        var counts: [String: Int] = [:]
        for attempt in attempts {
            let name = attempt.appDisplayName ?? "Unknown"
            counts[name, default: 0] += 1
        }
        return counts.map { (appName: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func totalAttemptsForDate(_ date: Date) -> Int {
        let request: NSFetchRequest<CDBlockAttempt> = CDBlockAttempt.fetchRequest()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        return (try? context.count(for: request)) ?? 0
    }

    func todayAttemptCountsByApp() -> [(appName: String, count: Int)] {
        let attempts = todayAttempts()
        var counts: [String: Int] = [:]
        for attempt in attempts {
            let name = attempt.appDisplayName ?? "Unknown"
            counts[name, default: 0] += 1
        }
        return counts.map { (appName: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    func todayTotalAttempts() -> Int {
        todayAttempts().count
    }

    func todayTotalMinutesSaved() -> Int {
        let sessions = todaySessions()
        var total: TimeInterval = 0
        for session in sessions {
            let end = session.endDate ?? Date()
            let start = session.startDate ?? Date()
            total += end.timeIntervalSince(start)
        }
        return Int(total / 60)
    }

    func todaySessionCount() -> Int {
        todaySessions().count
    }

    func weekTotalMinutesSaved() -> Int {
        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        request.predicate = NSPredicate(format: "startDate >= %@", startOfWeek as NSDate)
        let sessions = (try? context.fetch(request)) ?? []
        var total: TimeInterval = 0
        for session in sessions {
            let end = session.endDate ?? Date()
            let start = session.startDate ?? Date()
            total += end.timeIntervalSince(start)
        }
        return Int(total / 60)
    }

    func allTimeTotalMinutesSaved() -> Int {
        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        let sessions = (try? context.fetch(request)) ?? []
        var total: TimeInterval = 0
        for session in sessions {
            let end = session.endDate ?? Date()
            let start = session.startDate ?? Date()
            total += end.timeIntervalSince(start)
        }
        return Int(total / 60)
    }

    func allTimeTotalAttempts() -> Int {
        let request: NSFetchRequest<CDBlockAttempt> = CDBlockAttempt.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }

    func allTimeSessionCount() -> Int {
        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }

    func currentStreak() -> Int {
        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBlockSession.startDate, ascending: false)]
        let sessions = (try? context.fetch(request)) ?? []

        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let hasSession = sessions.contains { session in
                guard let start = session.startDate else { return false }
                return start >= checkDate && start < dayEnd
            }

            if hasSession {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else if streak == 0 {
                break
            } else {
                break
            }
        }

        return max(streak, todaySessionCount() > 0 ? 1 : 0)
    }

    func bestStreak() -> Int {
        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBlockSession.startDate, ascending: true)]
        let sessions = (try? context.fetch(request)) ?? []

        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        var uniqueDays: Set<Date> = []
        for session in sessions {
            if let start = session.startDate {
                uniqueDays.insert(calendar.startOfDay(for: start))
            }
        }

        let sortedDays = uniqueDays.sorted()
        var best = 1
        var current = 1

        for i in 1..<sortedDays.count {
            if calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1]) == sortedDays[i] {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }

        return best
    }

    func activeSessionDuration() -> TimeInterval {
        guard let session = activeSession, let start = session.startDate else { return 0 }
        return Date().timeIntervalSince(start)
    }

    // MARK: - Heatmap Data

    func minutesByDay(weeks: Int = 12) -> [Date: Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(weeks * 7), to: today) else { return [:] }

        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        request.predicate = NSPredicate(format: "startDate >= %@", startDate as NSDate)
        let sessions = (try? context.fetch(request)) ?? []

        var result: [Date: Int] = [:]
        for session in sessions {
            guard let start = session.startDate else { continue }
            let day = calendar.startOfDay(for: start)
            let end = session.endDate ?? Date()
            let minutes = Int(end.timeIntervalSince(start) / 60)
            result[day, default: 0] += minutes
        }
        return result
    }

    func sessionCountByDay(weeks: Int = 12) -> [Date: Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(weeks * 7), to: today) else { return [:] }

        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        request.predicate = NSPredicate(format: "startDate >= %@", startDate as NSDate)
        let sessions = (try? context.fetch(request)) ?? []

        var result: [Date: Int] = [:]
        for session in sessions {
            guard let start = session.startDate else { continue }
            let day = calendar.startOfDay(for: start)
            result[day, default: 0] += 1
        }
        return result
    }

    // MARK: - Extension Sync

    func syncAttemptsFromExtension() {
        guard let defaults = UserDefaults(suiteName: "group.com.andy.Untap") else { return }
        defaults.synchronize()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateKey = "attempts_\(formatter.string(from: Date()))"

        guard let extensionCounts = defaults.dictionary(forKey: dateKey) as? [String: Int] else { return }

        let existingAttempts = todayAttempts()
        var existingCounts: [String: Int] = [:]
        for attempt in existingAttempts {
            let name = attempt.appDisplayName ?? "Unknown"
            existingCounts[name, default: 0] += 1
        }

        let targetSession = activeSession ?? todaySessions().first

        var didCreate = false
        for (appName, extensionCount) in extensionCounts {
            let alreadySynced = existingCounts[appName] ?? 0
            let newCount = extensionCount - alreadySynced
            guard newCount > 0 else { continue }

            for _ in 0..<newCount {
                let attempt = CDBlockAttempt(context: context)
                attempt.id = UUID()
                attempt.appIdentifier = appName.lowercased().replacingOccurrences(of: " ", with: ".")
                attempt.appDisplayName = appName
                attempt.timestamp = Date()
                attempt.session = targetSession
                didCreate = true
            }
        }

        if didCreate {
            persistence.save()
            objectWillChange.send()
        }
    }

    // MARK: - Private

    private func cleanupOrphanedSessions() {
        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        let activeSessions = (try? context.fetch(request)) ?? []

        for session in activeSessions {
            session.endDate = session.endDate ?? Date()
            session.isActive = false
        }

        if !activeSessions.isEmpty {
            persistence.save()
        }
    }

    private func loadActiveSession() {
        let request: NSFetchRequest<CDBlockSession> = CDBlockSession.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBlockSession.startDate, ascending: false)]
        request.fetchLimit = 1
        activeSession = (try? context.fetch(request))?.first
    }
}
