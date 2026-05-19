import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Custom shield configuration that displays when a user tries to open a blocked app
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 0.98, green: 0.973, blue: 0.961, alpha: 1), // bg color
            icon: UIImage(systemName: "hand.raised.fill"),
            title: ShieldConfiguration.Label(
                text: "Stay Focused",
                color: UIColor(red: 0.122, green: 0.106, blue: 0.086, alpha: 1) // ink color
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked during your focus session.\nTap your NFC card to unblock.",
                color: UIColor(red: 0.612, green: 0.584, blue: 0.565, alpha: 1) // ink3 color
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.478, green: 0.561, blue: 0.416, alpha: 1), // sage color
            secondaryButtonLabel: nil
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 0.98, green: 0.973, blue: 0.961, alpha: 1),
            icon: UIImage(systemName: "globe"),
            title: ShieldConfiguration.Label(
                text: "Website Blocked",
                color: UIColor(red: 0.122, green: 0.106, blue: 0.086, alpha: 1)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This website is blocked during your focus session.\nTap your NFC card to unblock.",
                color: UIColor(red: 0.612, green: 0.584, blue: 0.565, alpha: 1)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 0.478, green: 0.561, blue: 0.416, alpha: 1),
            secondaryButtonLabel: nil
        )
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return configuration(shielding: webDomain)
    }
}
