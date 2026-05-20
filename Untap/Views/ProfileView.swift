import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appBlocker: AppBlockingManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showShieldSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ProfileHeaderView()

                ProfileStatsCard(sessionManager: sessionManager)

                SettingsSectionCard(
                    title: "Preferences",
                    items: [
                        SettingsItem(icon: "bell.fill", title: "Notifications", subtitle: "Reminders & alerts"),
                        SettingsItem(icon: "moon.fill", title: "Appearance", subtitle: "Light mode"),
                        SettingsItem(icon: "hand.raised.fill", title: "Privacy", subtitle: "Manage your data"),
                    ]
                )

                // Shield message settings button
                Button {
                    showShieldSettings = true
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Block Screen")
                            .monoLabel()
                            .padding(.bottom, 12)

                        HStack(spacing: 12) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 16))
                                .foregroundColor(.ink2)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Custom Block Message")
                                    .font(.system(size: 15))
                                    .foregroundColor(.ink)

                                Text("Customize what you see when blocked")
                                    .font(.system(size: 12))
                                    .foregroundColor(.ink3)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.ink3)
                        }
                        .padding(.vertical, 12)
                    }
                    .padding(18)
                    .cardStyle()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }

                SettingsSectionCard(
                    title: "NFC & Devices",
                    items: [
                        SettingsItem(icon: "wave.3.right", title: "NFC Tags", subtitle: "\(NFCManager.shared.pairedTags.count) paired"),
                        SettingsItem(icon: "applewatch", title: "Apple Watch", subtitle: "Not connected"),
                    ]
                )

                SettingsSectionCard(
                    title: "Support",
                    items: [
                        SettingsItem(icon: "questionmark.circle.fill", title: "Help Center", subtitle: nil),
                        SettingsItem(icon: "envelope.fill", title: "Contact Us", subtitle: nil),
                        SettingsItem(icon: "star.fill", title: "Rate Untap", subtitle: nil),
                    ]
                )

                Text("Untap v1.0.0")
                    .font(.geistMono(size: 10))
                    .foregroundColor(.ink3)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Text("Made with focus")
                    .font(.geistMono(size: 10))
                    .foregroundColor(.ink3)
                    .padding(.bottom, 100)
            }
        }
        .background(Color.bg)
        .sheet(isPresented: $showShieldSettings) {
            ShieldSettingsView()
                .environmentObject(appBlocker)
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.amber, .rose],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Text("AN")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(spacing: 4) {
                Text("Andy")
                    .font(.instrumentSerif(size: 28))
                    .foregroundColor(.ink)

                Text("@andy")
                    .font(.geistMono(size: 12))
                    .foregroundColor(.ink3)
            }

            Button {
            } label: {
                Text("Edit profile")
                    .font(.geist(size: 13, weight: .medium))
                    .foregroundColor(.ink2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.bg2)
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 36)
        .padding(.bottom, 24)
    }
}

// MARK: - Profile Stats
struct ProfileStatsCard: View {
    var sessionManager: SessionManager

    var body: some View {
        HStack(spacing: 0) {
            ProfileStat(
                value: "\(sessionManager.allTimeTotalMinutesSaved() / 60)",
                unit: "h",
                label: "Total saved"
            )
            Divider().frame(height: 40)
            ProfileStat(
                value: "\(sessionManager.bestStreak())",
                unit: "d",
                label: "Best streak"
            )
            Divider().frame(height: 40)
            ProfileStat(
                value: "\(sessionManager.allTimeTotalAttempts())",
                unit: nil,
                label: "Blocks"
            )
        }
        .padding(.vertical, 20)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

struct ProfileStat: View {
    let value: String
    let unit: String?
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.instrumentSerif(size: 28))
                    .foregroundColor(.ink)
                if let unit = unit {
                    Text(unit)
                        .font(.instrumentSerifItalic(size: 16))
                        .foregroundColor(.ink2)
                }
            }

            Text(label)
                .monoLabel()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shield Settings View
struct ShieldSettingsView: View {
    @EnvironmentObject var appBlocker: AppBlockingManager
    @Environment(\.dismiss) var dismiss
    @State private var config: ShieldMessageConfig = .default

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Preview
                    VStack(spacing: 16) {
                        Text("Preview")
                            .monoLabel()
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 12) {
                            Text(config.iconEmoji)
                                .font(.system(size: 44))

                            Text(config.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.ink)
                                .multilineTextAlignment(.center)

                            Text(config.body)
                                .font(.system(size: 14))
                                .foregroundColor(.ink2)
                                .multilineTextAlignment(.center)

                            Text(config.primaryButtonLabel)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.ink)
                                .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .padding(.horizontal, 20)
                        .background(Color.bg2)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.line, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)

                    // Edit fields
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Customize")
                            .monoLabel()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Emoji")
                                .font(.system(size: 12))
                                .foregroundColor(.ink3)
                            TextField("Emoji", text: $config.iconEmoji)
                                .font(.system(size: 28))
                                .frame(width: 60)
                                .padding(8)
                                .background(Color.bg2)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(.system(size: 12))
                                .foregroundColor(.ink3)
                            TextField("Title", text: $config.title)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color.bg2)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Message")
                                .font(.system(size: 12))
                                .foregroundColor(.ink3)
                            TextField("Body text", text: $config.body, axis: .vertical)
                                .font(.system(size: 15))
                                .lineLimit(3...5)
                                .padding(12)
                                .background(Color.bg2)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Button label")
                                .font(.system(size: 12))
                                .foregroundColor(.ink3)
                            TextField("Button text", text: $config.primaryButtonLabel)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color.bg2)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 16)

                    // Preset messages
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Presets")
                            .monoLabel()
                            .padding(.horizontal, 16)

                        ForEach(presets, id: \.title) { preset in
                            Button {
                                config = preset
                            } label: {
                                HStack(spacing: 12) {
                                    Text(preset.iconEmoji)
                                        .font(.system(size: 22))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.ink)
                                        Text(preset.body)
                                            .font(.system(size: 12))
                                            .foregroundColor(.ink3)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.ink3)
                                }
                                .padding(14)
                                .cardStyle()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.bg)
            .navigationTitle("Block Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        appBlocker.saveShieldConfig(config)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                config = appBlocker.loadShieldConfig()
            }
        }
    }

    private var presets: [ShieldMessageConfig] {
        [
            ShieldMessageConfig(
                title: "You've got work to do",
                body: "Lock in! You chose to block this app for a reason.",
                primaryButtonLabel: "Got it",
                iconEmoji: "🔒"
            ),
            ShieldMessageConfig(
                title: "Stay focused",
                body: "Your future self will thank you. Keep going.",
                primaryButtonLabel: "Back to work",
                iconEmoji: "🎯"
            ),
            ShieldMessageConfig(
                title: "Not right now",
                body: "This app is blocked during your focus session. You're doing great.",
                primaryButtonLabel: "OK",
                iconEmoji: "🧘"
            ),
            ShieldMessageConfig(
                title: "Nope!",
                body: "You said no distractions. We're holding you to it.",
                primaryButtonLabel: "Fine",
                iconEmoji: "💪"
            ),
        ]
    }
}

// MARK: - Settings Section
struct SettingsSectionCard: View {
    let title: String
    let items: [SettingsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .monoLabel()
                .padding(.bottom, 12)

            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                SettingsRow(item: item)

                if index < items.count - 1 {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

struct SettingsItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
}

struct SettingsRow: View {
    let item: SettingsItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 16))
                .foregroundColor(.ink2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15))
                    .foregroundColor(.ink)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.ink3)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.ink3)
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppBlockingManager.shared)
        .environmentObject(SessionManager.shared)
}
