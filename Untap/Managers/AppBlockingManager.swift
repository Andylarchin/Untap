import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

class AppBlockingManager: ObservableObject {
    static let shared = AppBlockingManager()

    static let appGroupID = "group.com.andy.Untap"
    static let sharedDefaults = UserDefaults(suiteName: appGroupID)

    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var isBlockingEnabled = false
    @Published var selectedApps = FamilyActivitySelection()
    @Published var blockingRules: [BlockingRule] = []

    // MARK: - Private Properties
    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let sessionManager = SessionManager.shared
    private let defaults = UserDefaults.standard

    private init() {
        loadRules()
        loadSelectedApps()
        loadBlockingState()
    }

    // MARK: - Authorization

    @MainActor
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            print("Authorization failed: \(error)")
            isAuthorized = false
        }
    }

    // MARK: - Blocking Control

    func enableBlocking() {
        guard isAuthorized else { return }

        store.shield.applications = selectedApps.applicationTokens
        store.shield.applicationCategories = .specific(selectedApps.categoryTokens)
        store.shield.webDomains = selectedApps.webDomainTokens

        isBlockingEnabled = true
        defaults.set(true, forKey: "isBlockingEnabled")

        let _ = sessionManager.startSession()
    }

    func disableBlocking() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        isBlockingEnabled = false
        defaults.set(false, forKey: "isBlockingEnabled")

        let _ = sessionManager.endSession()
    }

    func toggleBlocking() {
        if isBlockingEnabled {
            disableBlocking()
        } else {
            enableBlocking()
        }
    }

    // MARK: - Selected Apps Persistence

    func saveSelectedApps() {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: selectedApps, requiringSecureCoding: false) {
            defaults.set(data, forKey: "selectedApps")
        }
    }

    private func loadSelectedApps() {
        // FamilyActivitySelection tokens don't persist across launches in a simple way.
        // The user re-selects via FamilyActivityPicker each launch if needed.
    }

    private func loadBlockingState() {
        isBlockingEnabled = defaults.bool(forKey: "isBlockingEnabled")
        if isBlockingEnabled && sessionManager.activeSession == nil {
            isBlockingEnabled = false
            defaults.set(false, forKey: "isBlockingEnabled")
        }
    }

    // MARK: - Shield Message Configuration

    func ensureShieldConfigSynced() {
        if Self.sharedDefaults?.data(forKey: "shieldConfig") == nil {
            saveShieldConfig(.default)
        }
    }

    func saveShieldConfig(_ config: ShieldMessageConfig) {
        if let data = try? JSONEncoder().encode(config) {
            Self.sharedDefaults?.set(data, forKey: "shieldConfig")
            defaults.set(data, forKey: "shieldConfig")
        }
    }

    func loadShieldConfig() -> ShieldMessageConfig {
        let source = Self.sharedDefaults ?? defaults
        if let data = source.data(forKey: "shieldConfig"),
           let config = try? JSONDecoder().decode(ShieldMessageConfig.self, from: data) {
            return config
        }
        return ShieldMessageConfig.default
    }

    // MARK: - Rules Management

    func addRule(_ rule: BlockingRule) {
        blockingRules.append(rule)
        saveRules()
    }

    func removeRule(_ rule: BlockingRule) {
        blockingRules.removeAll { $0.id == rule.id }
        saveRules()
    }

    func toggleRule(_ rule: BlockingRule) {
        if let index = blockingRules.firstIndex(where: { $0.id == rule.id }) {
            blockingRules[index].isActive.toggle()
            saveRules()
        }
    }

    func updateRuleApps(_ rule: BlockingRule, apps: FamilyActivitySelection) {
        if let index = blockingRules.firstIndex(where: { $0.id == rule.id }) {
            blockingRules[index].appSelection = apps
            saveRules()
        }
    }

    // MARK: - Persistence

    private func loadRules() {
        if let data = defaults.data(forKey: "blockingRules"),
           let rules = try? JSONDecoder().decode([BlockingRule].self, from: data) {
            blockingRules = rules
        } else {
            blockingRules = BlockingRule.defaultRules
        }
    }

    private func saveRules() {
        if let data = try? JSONEncoder().encode(blockingRules) {
            defaults.set(data, forKey: "blockingRules")
        }
    }

}

// MARK: - Shield Message Config

struct ShieldMessageConfig: Codable {
    var title: String
    var body: String
    var primaryButtonLabel: String
    var iconEmoji: String

    static let `default` = ShieldMessageConfig(
        title: "You've got work to do",
        body: "Lock in! You chose to block this app for a reason.",
        primaryButtonLabel: "Got it",
        iconEmoji: "🔒"
    )
}

// MARK: - Models

struct BlockingRule: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var apps: [String]
    var appSelection: FamilyActivitySelection?
    var schedule: String
    var isActive: Bool
    var accentColorHex: String
    var startHour: Int?
    var startMinute: Int?
    var endHour: Int?
    var endMinute: Int?
    var activeDays: [Int]?

    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    var scheduleDisplay: String {
        guard let sh = startHour, let eh = endHour else { return schedule }
        let sm = startMinute ?? 0
        let em = endMinute ?? 0
        let days = activeDays ?? Array(0...6)
        return "\(formatDays(days)) · \(formatTime(sh, sm)) – \(formatTime(eh, em))"
    }

    private func formatDays(_ days: [Int]) -> String {
        let daySet = Set(days)
        if daySet == Set(0...6) { return "Daily" }
        if daySet == Set(1...5) { return "Mon–Fri" }
        if daySet == Set([0, 6]) { return "Weekends" }
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days.sorted().map { names[$0] }.joined(separator: ", ")
    }

    private func formatTime(_ hour: Int, _ minute: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        if minute == 0 { return "\(h) \(period)" }
        return "\(h):\(String(format: "%02d", minute)) \(period)"
    }

    static var defaultRules: [BlockingRule] {
        [
            BlockingRule(
                id: UUID(),
                name: "Morning focus",
                description: "Deep work before noon",
                apps: ["instagram", "tiktok", "x", "reddit"],
                appSelection: nil,
                schedule: "Mon–Fri · 6 AM – 12 PM",
                isActive: true,
                accentColorHex: "7A8F6A",
                startHour: 6,
                startMinute: 0,
                endHour: 12,
                endMinute: 0,
                activeDays: [1, 2, 3, 4, 5]
            ),
            BlockingRule(
                id: UUID(),
                name: "Wind-down",
                description: "Protect your sleep",
                apps: ["youtube", "tiktok", "instagram", "reddit"],
                appSelection: nil,
                schedule: "Daily · 10 PM – 7 AM",
                isActive: true,
                accentColorHex: "C97B6E",
                startHour: 22,
                startMinute: 0,
                endHour: 7,
                endMinute: 0,
                activeDays: [0, 1, 2, 3, 4, 5, 6]
            ),
            BlockingRule(
                id: UUID(),
                name: "Weekend reset",
                description: "Saturday mornings off-grid",
                apps: ["instagram", "x", "facebook", "linkedin"],
                appSelection: nil,
                schedule: "Sat · 7 AM – 11 AM",
                isActive: false,
                accentColorHex: "D68A3C",
                startHour: 7,
                startMinute: 0,
                endHour: 11,
                endMinute: 0,
                activeDays: [6]
            )
        ]
    }
}

// MARK: - FamilyActivitySelection Codable Extension
extension FamilyActivitySelection: @retroactive Codable {
    enum CodingKeys: String, CodingKey {
        case applicationTokens
        case categoryTokens
        case webDomainTokens
    }

    public init(from decoder: Decoder) throws {
        self.init()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(true, forKey: .applicationTokens)
    }
}
