import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private let appGroupID = "group.com.andy.Untap"

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        recordAttempt(name: application.localizedDisplayName ?? "App")
        return makeConfig(for: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        recordAttempt(name: application.localizedDisplayName ?? category.localizedDisplayName ?? "App")
        return makeConfig(for: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        recordAttempt(name: webDomain.domain ?? "Website")
        return makeConfig(for: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        recordAttempt(name: webDomain.domain ?? "Website")
        return makeConfig(for: webDomain.domain)
    }

    private func makeConfig(for appName: String?) -> ShieldConfiguration {
        let cfg = loadConfig()
        let title = appName != nil ? "\(appName!) is blocked" : cfg.title

        let icon = UIImage(systemName: "hand.raised.fill")?
            .withTintColor(.systemRed, renderingMode: .alwaysOriginal)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterialDark,
            backgroundColor: UIColor(white: 0.08, alpha: 0.95),
            icon: icon,
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(text: cfg.body, color: UIColor(white: 0.75, alpha: 1)),
            primaryButtonLabel: ShieldConfiguration.Label(text: cfg.primaryButtonLabel, color: .black),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: nil
        )
    }

    private func loadConfig() -> ShieldMessageConfig {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "shieldConfig"),
              let config = try? JSONDecoder().decode(ShieldMessageConfig.self, from: data) else {
            return .default
        }
        return config
    }

    private func recordAttempt(name: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateKey = "attempts_\(formatter.string(from: Date()))"

        var counts = defaults.dictionary(forKey: dateKey) as? [String: Int] ?? [:]
        counts[name, default: 0] += 1
        defaults.set(counts, forKey: dateKey)

        let total = defaults.integer(forKey: "totalBlockedAttempts")
        defaults.set(total + 1, forKey: "totalBlockedAttempts")
        defaults.synchronize()
    }
}

struct ShieldMessageConfig: Codable {
    var title: String
    var body: String
    var primaryButtonLabel: String
    var iconEmoji: String

    static let `default` = ShieldMessageConfig(
        title: "You've got work to do",
        body: "Lock in! You chose to block this app for a reason.",
        primaryButtonLabel: "Got it",
        iconEmoji: "\u{1F512}"
    )
}
