import SwiftUI

struct SessionSummaryView: View {
    let session: CDBlockSession
    let sessionManager: SessionManager
    @Environment(\.dismiss) var dismiss

    private var duration: TimeInterval {
        guard let start = session.startDate else { return 0 }
        let end = session.endDate ?? Date()
        return end.timeIntervalSince(start)
    }

    private var durationMinutes: Int { Int(duration / 60) }
    private var durationHours: Int { durationMinutes / 60 }
    private var durationRemainingMinutes: Int { durationMinutes % 60 }

    private var attemptCounts: [(appName: String, count: Int)] {
        sessionManager.attemptCountsByApp(for: session)
    }

    private var totalAttempts: Int {
        attemptCounts.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.sageSoft)
                                .frame(width: 80, height: 80)

                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.sageDeep)
                        }

                        Text("Session complete")
                            .font(.instrumentSerif(size: 32))
                            .foregroundColor(.ink)

                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            if durationHours > 0 {
                                Text("\(durationHours)")
                                    .font(.instrumentSerif(size: 44))
                                Text("h")
                                    .font(.instrumentSerifItalic(size: 20))
                                    .foregroundColor(.ink2)
                            }
                            Text("\(durationRemainingMinutes)")
                                .font(.instrumentSerif(size: 44))
                            Text("m")
                                .font(.instrumentSerifItalic(size: 20))
                                .foregroundColor(.ink2)
                        }
                        .foregroundColor(.ink)

                        Text("of focused time")
                            .font(.system(size: 14))
                            .foregroundColor(.ink3)
                    }
                    .padding(.top, 20)

                    if !attemptCounts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Blocked attempts")
                                    .monoLabel()

                                Spacer()

                                Text("\(totalAttempts) total")
                                    .font(.geistMono(size: 11))
                                    .foregroundColor(.ink3)
                            }

                            ForEach(attemptCounts, id: \.appName) { entry in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colorForApp(entry.appName))
                                        .frame(width: 34, height: 34)
                                        .overlay(
                                            Image(systemName: iconForApp(entry.appName))
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        )

                                    Text(entry.appName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.ink)

                                    Spacer()

                                    Text("You tried \(entry.count) time\(entry.count == 1 ? "" : "s")")
                                        .font(.geistMono(size: 11))
                                        .foregroundColor(.ink2)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(18)
                        .cardStyle()
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 28))
                                .foregroundColor(.sage)

                            Text("No blocked attempts!")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.ink)

                            Text("You stayed focused the entire session")
                                .font(.system(size: 13))
                                .foregroundColor(.ink3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .cardStyle()
                        .padding(.horizontal, 16)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.geist(size: 16, weight: .medium))
                            .foregroundColor(.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
            .background(Color.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.ink3)
                    }
                }
            }
        }
    }

    private func iconForApp(_ name: String) -> String {
        switch name.lowercased() {
        case "instagram": return "camera.fill"
        case "tiktok": return "play.rectangle.fill"
        case "x", "twitter": return "bubble.left.fill"
        case "reddit": return "list.bullet"
        case "youtube": return "play.fill"
        default: return "app.fill"
        }
    }

    private func colorForApp(_ name: String) -> Color {
        switch name.lowercased() {
        case "instagram": return Color(hex: "E4405F")
        case "tiktok": return Color(hex: "000000")
        case "x", "twitter": return Color(hex: "1DA1F2")
        case "reddit": return Color(hex: "FF4500")
        case "youtube": return Color(hex: "FF0000")
        default: return Color.gray
        }
    }
}
