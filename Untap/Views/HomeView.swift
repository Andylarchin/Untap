import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appBlocker: AppBlockingManager
    @EnvironmentObject var nfcManager: NFCManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var isSessionActive = false
    @State private var showSessionSummary = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HeaderView()

                TapHeroView(
                    isActive: $isSessionActive,
                    sessionManager: sessionManager,
                    onTap: handleTap
                )

                StatsRowView(sessionManager: sessionManager)

                BlockedAppsCardView(sessionManager: sessionManager)

                GoalCardView(sessionManager: sessionManager)

                FriendsCardView()

                Text("— keep going —")
                    .monoLabel()
                    .padding(.vertical, 20)
            }
            .padding(.bottom, 100)
        }
        .background(Color.bg)
        .onAppear {
            isSessionActive = sessionManager.activeSession != nil
        }
        .onChange(of: nfcManager.lastScannedTag) { _, newValue in
            if newValue != nil {
                toggleSession()
            }
        }
        .sheet(isPresented: $showSessionSummary) {
            if let session = sessionManager.lastCompletedSession {
                SessionSummaryView(session: session, sessionManager: sessionManager)
            }
        }
    }

    private func handleTap() {
        guard nfcManager.hasPairedTags else {
            nfcManager.errorMessage = "Pair a tag first in the Blocks tab"
            return
        }
        nfcManager.startScanning()
    }

    private func toggleSession() {
        withAnimation(.spring(response: 0.4)) {
            isSessionActive.toggle()
        }

        if isSessionActive {
            appBlocker.enableBlocking()
        } else {
            appBlocker.disableBlocking()
            showSessionSummary = true
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE · MMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString)
                    .monoLabel()

                HStack(spacing: 0) {
                    Text("\(greeting), ")
                        .font(.instrumentSerif(size: 26))
                    Text("Andy")
                        .font(.instrumentSerifItalic(size: 26))
                    Text(".")
                        .font(.instrumentSerif(size: 26))
                }
                .foregroundColor(.ink)
            }

            Spacer()

            Circle()
                .fill(
                    LinearGradient(
                        colors: [.amber, .rose],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 38, height: 38)
                .overlay(
                    Text("AN")
                        .font(.geist(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}

// MARK: - Tap Hero View
struct TapHeroView: View {
    @Binding var isActive: Bool
    var sessionManager: SessionManager
    var onTap: () -> Void

    @State private var animateRipple = false
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var todayMinutes: Int {
        sessionManager.todayTotalMinutesSaved()
    }

    private var hours: Int { todayMinutes / 60 }
    private var minutes: Int { todayMinutes % 60 }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.sageSoft, Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)

                if isActive {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Color.sage, lineWidth: 1.5)
                            .frame(width: 140, height: 140)
                            .scaleEffect(animateRipple ? 2.5 : 1)
                            .opacity(animateRipple ? 0 : 0.8)
                            .animation(
                                .easeOut(duration: 1.6)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                                value: animateRipple
                            )
                    }
                }

                Circle()
                    .stroke(Color.line, style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
                    .frame(width: 270, height: 270)

                Circle()
                    .stroke(Color.line, lineWidth: 8)
                    .frame(width: 230, height: 230)

                Circle()
                    .trim(from: 0, to: todayMinutes > 0 ? min(Double(todayMinutes) / 180.0, 1.0) : 0)
                    .stroke(
                        LinearGradient(
                            colors: [Color.sageDeep.opacity(0.3), Color.sage, Color.sageDeep.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 230, height: 230)
                    .rotationEffect(.degrees(-90))

                HStack(spacing: 6) {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 12))
                    Text(isActive ? "Tap active" : "Ready")
                        .font(.geistMono(size: 10))
                        .kerning(1)
                        .textCase(.uppercase)
                }
                .foregroundColor(.sageDeep)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.line, lineWidth: 1))
                .offset(y: -118)

                VStack(spacing: 8) {
                    Text("Time saved today")
                        .monoLabel()

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(hours)")
                            .font(.instrumentSerif(size: 88))
                        Text("h")
                            .font(.instrumentSerifItalic(size: 32))
                            .foregroundColor(.ink2)
                        Text("\(minutes)")
                            .font(.instrumentSerif(size: 88))
                        Text("m")
                            .font(.instrumentSerifItalic(size: 32))
                            .foregroundColor(.ink2)
                    }
                    .foregroundColor(.ink)

                    if todayMinutes > 0 {
                        Text("\(sessionManager.todaySessionCount()) session\(sessionManager.todaySessionCount() == 1 ? "" : "s") today")
                            .font(.system(size: 13))
                            .foregroundColor(.ink3)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.sageSoft)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(height: 300)

            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 18))
                    Text(isActive ? "Session active — tap to end" : "Tap to start a session")
                        .font(.geist(size: 15, weight: .medium))
                }
                .foregroundColor(.bg)
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
                .background(Color.ink)
                .clipShape(Capsule())
                .shadow(color: Color.ink.opacity(0.25), radius: 12, y: 8)
            }
            .padding(.top, -6)
        }
        .padding(.vertical, 18)
        .onAppear {
            if isActive { animateRipple = true }
        }
        .onChange(of: isActive) { _, newValue in
            animateRipple = newValue
        }
        .onReceive(timer) { _ in
            now = Date()
        }
    }
}

// MARK: - Stats Row
struct StatsRowView: View {
    var sessionManager: SessionManager

    var body: some View {
        HStack(spacing: 10) {
            StatCard(
                icon: "shield.fill",
                iconColor: .sageDeep,
                label: "Blocks",
                value: "\(sessionManager.todayTotalAttempts())",
                subtitle: "today"
            )

            StatCard(
                icon: "flame.fill",
                iconColor: .amber,
                label: "Streak",
                value: "\(sessionManager.currentStreak())",
                unit: "d",
                subtitle: sessionManager.currentStreak() >= sessionManager.bestStreak() ? "personal best" : "keep going"
            )

            StatCard(
                icon: "clock.fill",
                iconColor: .rose,
                label: "This week",
                value: "\(sessionManager.weekTotalMinutesSaved() / 60)",
                unit: "h",
                subtitle: "\(sessionManager.weekTotalMinutesSaved() % 60)m more"
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

struct StatCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var unit: String? = nil
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
                Text(label)
                    .monoLabel()
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.instrumentSerif(size: 30))
                    .foregroundColor(.ink)
                if let unit = unit {
                    Text(unit)
                        .font(.instrumentSerifItalic(size: 14))
                        .foregroundColor(.ink2)
                }
            }

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.ink3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .cardStyle()
    }
}

// MARK: - Blocked Apps Card
struct BlockedAppsCardView: View {
    var sessionManager: SessionManager

    private var appCounts: [(appName: String, count: Int)] {
        sessionManager.todayAttemptCountsByApp()
    }

    private var totalAttempts: Int {
        sessionManager.todayTotalAttempts()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Most blocked today")
                        .monoLabel()

                    if totalAttempts > 0 {
                        HStack(spacing: 0) {
                            Text("\(totalAttempts) interruption\(totalAttempts == 1 ? "" : "s"), ")
                                .font(.instrumentSerif(size: 22))
                            Text("averted")
                                .font(.instrumentSerifItalic(size: 22))
                                .foregroundColor(.sageDeep)
                        }
                        .foregroundColor(.ink)
                    } else {
                        Text("No blocked attempts yet")
                            .font(.instrumentSerif(size: 22))
                            .foregroundColor(.ink3)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 10)

            if appCounts.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 28))
                            .foregroundColor(.ink3)
                        Text("Start a session to track blocked apps")
                            .font(.system(size: 13))
                            .foregroundColor(.ink3)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
            } else {
                let maxCount = appCounts.first?.count ?? 1
                ForEach(appCounts.prefix(5), id: \.appName) { entry in
                    BlockedAppRow(
                        app: BlockedApp(name: entry.appName, icon: iconForApp(entry.appName), count: entry.count, time: ""),
                        maxCount: maxCount
                    )
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
            }
        }
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private func iconForApp(_ name: String) -> String {
        switch name.lowercased() {
        case "instagram": return "camera.fill"
        case "tiktok": return "play.rectangle.fill"
        case "x", "twitter": return "bubble.left.fill"
        case "reddit": return "list.bullet"
        case "youtube": return "play.fill"
        case "facebook": return "person.2.fill"
        case "linkedin": return "briefcase.fill"
        default: return "app.fill"
        }
    }
}

struct BlockedApp: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let count: Int
    let time: String
}

struct BlockedAppRow: View {
    let app: BlockedApp
    let maxCount: Int

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(appColor)
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: app.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    Text("\(app.count)×")
                        .font(.geistMono(size: 11))
                        .foregroundColor(.ink2)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.bg2)
                            .frame(height: 4)

                        Capsule()
                            .fill(app.count == maxCount ? Color.amber : Color.sage)
                            .frame(width: geo.size.width * CGFloat(app.count) / CGFloat(max(maxCount, 1)), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.vertical, 8)
    }

    private var appColor: Color {
        switch app.name.lowercased() {
        case "instagram": return Color(hex: "E4405F")
        case "tiktok": return Color(hex: "000000")
        case "x", "twitter": return Color(hex: "1DA1F2")
        case "reddit": return Color(hex: "FF4500")
        case "youtube": return Color(hex: "FF0000")
        default: return Color.gray
        }
    }
}

// MARK: - Goal Card
struct GoalCardView: View {
    var sessionManager: SessionManager

    private var todayMinutes: Int {
        sessionManager.todayTotalMinutesSaved()
    }

    private var goalMinutes: Int { 60 }
    private var progress: Double { min(Double(todayMinutes) / Double(goalMinutes), 1.0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily goal")
                        .monoLabel()

                    HStack(spacing: 0) {
                        Text("Block ")
                            .font(.instrumentSerif(size: 22))
                        Text("1h")
                            .font(.instrumentSerifItalic(size: 22))
                        Text(" of distractions")
                            .font(.instrumentSerif(size: 22))
                    }
                    .foregroundColor(.ink)
                }

                Spacer()

                Image(systemName: progress >= 1.0 ? "checkmark.circle.fill" : "target")
                    .font(.system(size: 22))
                    .foregroundColor(progress >= 1.0 ? .sage : .sageDeep)
            }

            HStack(spacing: 3) {
                ForEach(0..<24, id: \.self) { index in
                    let filled = Double(index) / 24.0 < progress
                    let isWarning = Double(index) / 24.0 > 0.75

                    RoundedRectangle(cornerRadius: 3)
                        .fill(filled ? (isWarning ? Color.amber : Color.sage) : Color.bg2)
                        .frame(height: 28)
                }
            }

            HStack {
                Text("\(todayMinutes)m / \(goalMinutes)m")
                    .font(.geistMono(size: 11))
                    .foregroundColor(.ink3)

                Spacer()

                let remaining = max(goalMinutes - todayMinutes, 0)
                Text(remaining > 0 ? "\(remaining)m left" : "Goal reached!")
                    .font(.geistMono(size: 11))
                    .foregroundColor(.sageDeep)
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

// MARK: - Friends Card
struct FriendsCardView: View {
    let friends = [
        Friend(name: "Maya", initials: "MR", streak: 23, color: Color(hex: "D68A3C")),
        Friend(name: "You", initials: "AN", streak: 12, color: Color(hex: "7A8F6A"), isYou: true),
        Friend(name: "Theo", initials: "TS", streak: 9, color: Color(hex: "C97B6E")),
        Friend(name: "Priya", initials: "PK", streak: 7, color: Color(hex: "6E8FB0")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.ink2)

                    Text("Friends this week")
                        .monoLabel()
                }

                Spacer()

                Button {
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Invite")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.ink2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.bg2)
                    .clipShape(Capsule())
                }
            }
            .padding(.bottom, 12)

            ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                FriendRow(friend: friend, rank: index + 1)
                    .padding(.vertical, 8)

                if index < friends.count - 1 {
                    Divider()
                }
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

struct Friend: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let streak: Int
    let color: Color
    var isYou: Bool = false
}

struct FriendRow: View {
    let friend: Friend
    let rank: Int

    var rankSymbol: String {
        switch rank {
        case 1: return "①"
        case 2: return "②"
        case 3: return "③"
        case 4: return "④"
        default: return "\(rank)"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(rankSymbol)
                .font(.geistMono(size: 12))
                .foregroundColor(rank == 1 ? .amber : .ink3)
                .fontWeight(rank == 1 ? .semibold : .regular)
                .frame(width: 28)

            Circle()
                .fill(friend.color)
                .frame(width: 34, height: 34)
                .overlay(
                    Text(friend.initials)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(Color.ink, lineWidth: friend.isYou ? 2 : 0)
                        .padding(-2)
                )

            HStack(spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 14, weight: friend.isYou ? .semibold : .regular))
                    .foregroundColor(.ink)

                if friend.isYou {
                    Text("· you")
                        .font(.system(size: 12))
                        .foregroundColor(.ink3)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.amber)

                Text("\(friend.streak)")
                    .font(.geistMono(size: 13))
                    .foregroundColor(.ink)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppBlockingManager.shared)
        .environmentObject(NFCManager.shared)
        .environmentObject(SessionManager.shared)
}
