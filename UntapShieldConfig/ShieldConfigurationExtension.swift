//
//  ShieldConfigurationExtension.swift
//  UntapShieldConfig
//
//  Created by Andy Larchin on 5/19/26.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private var config: ShieldMessageConfig {
        let defaults = UserDefaults(suiteName: "group.com.andy.Untap")
        if let data = defaults?.data(forKey: "shieldConfig"),
           let config = try? JSONDecoder().decode(ShieldMessageConfig.self, from: data) {
            return config
        }
        return ShieldMessageConfig.default
    }

    private func makeShieldConfiguration() -> ShieldConfiguration {
        let cfg = config
        return ShieldConfiguration(
            backgroundBlurStyle: .systemThickMaterial,
            backgroundColor: UIColor(red: 250/255, green: 248/255, blue: 245/255, alpha: 1),
            icon: nil,
            title: ShieldConfiguration.Label(
                text: "\(cfg.iconEmoji) \(cfg.title)",
                color: UIColor(red: 31/255, green: 27/255, blue: 22/255, alpha: 1)
            ),
            subtitle: ShieldConfiguration.Label(
                text: cfg.body,
                color: UIColor(red: 107/255, green: 101/255, blue: 96/255, alpha: 1)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: cfg.primaryButtonLabel,
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 31/255, green: 27/255, blue: 22/255, alpha: 1),
            secondaryButtonLabel: nil
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeShieldConfiguration()
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
