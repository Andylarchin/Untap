//
//  ShieldActionExtension.swift
//  UntapShieldAction
//
//  Created by Andy Larchin on 5/19/26.
//

import Foundation
import ManagedSettings

class ShieldActionExtension: ShieldActionDelegate {

    private let appGroupID = "group.com.andy.Untap"

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        recordBlockedAttempt(appName: "Blocked App")

        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        recordBlockedAttempt(appName: "Blocked Website")
        completionHandler(.close)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        recordBlockedAttempt(appName: "Blocked Category")
        completionHandler(.close)
    }

    private func recordBlockedAttempt(appName: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        let dateKey = attemptDateKey()
        var todayCounts = defaults.dictionary(forKey: dateKey) as? [String: Int] ?? [:]
        todayCounts[appName, default: 0] += 1
        defaults.set(todayCounts, forKey: dateKey)

        let totalKey = "totalBlockedAttempts"
        let total = defaults.integer(forKey: totalKey)
        defaults.set(total + 1, forKey: totalKey)
    }

    private func attemptDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "attempts_\(formatter.string(from: Date()))"
    }
}
