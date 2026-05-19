import SwiftUI

struct SocialView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("4 friends · 2 groups")
                        .monoLabel()

                    HStack(spacing: 0) {
                        Text("Your ")
                            .font(.instrumentSerif(size: 34))
                        Text("circle")
                            .font(.instrumentSerifItalic(size: 34))
                    }
                    .foregroundColor(.ink)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 14)

                // Weekly Leaderboard
                WeeklyLeaderboardCard()

                // Activity Feed
                ActivityFeedCard()

                // Groups
                GroupsCard()

                // Invite Friends
                InviteFriendsCard()
            }
            .padding(.bottom, 100)
        }
        .background(Color.bg)
    }
}

// MARK: - Weekly Leaderboard
struct WeeklyLeaderboardCard: View {
    let leaderboard = [
        LeaderboardEntry(name: "Maya", initials: "MR", hours: 18.5, color: Color(hex: "D68A3C")),
        LeaderboardEntry(name: "You", initials: "AN", hours: 14.2, color: Color(hex: "7A8F6A"), isYou: true),
        LeaderboardEntry(name: "Theo", initials: "TS", hours: 12.8, color: Color(hex: "C97B6E")),
        LeaderboardEntry(name: "Priya", initials: "PK", hours: 10.3, color: Color(hex: "6E8FB0")),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.amber)

                    Text("Weekly leaderboard")
                        .monoLabel()
                }

                Spacer()

                Text("5 days left")
                    .font(.geistMono(size: 10))
                    .foregroundColor(.ink3)
            }

            ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(entry: entry, rank: index + 1)
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let hours: Double
    let color: Color
    var isYou: Bool = false
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int

    var medal: String? {
        switch rank {
        case 1: return "gold"
        case 2: return "silver"
        case 3: return "bronze"
        default: return nil
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(medalColor)
                        .frame(width: 28, height: 28)

                    Text("\(rank)")
                        .font(.geistMono(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text("\(rank)")
                        .font(.geistMono(size: 14))
                        .foregroundColor(.ink3)
                        .frame(width: 28)
                }
            }

            // Avatar
            Circle()
                .fill(entry.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(entry.initials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(Color.ink, lineWidth: entry.isYou ? 2 : 0)
                        .padding(-2)
                )

            // Name
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.name)
                        .font(.system(size: 15, weight: entry.isYou ? .semibold : .medium))
                        .foregroundColor(.ink)

                    if entry.isYou {
                        Text("(you)")
                            .font(.system(size: 12))
                            .foregroundColor(.ink3)
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    let maxHours = 20.0
                    let width = min(geo.size.width * entry.hours / maxHours, geo.size.width)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.bg2)
                            .frame(height: 6)

                        Capsule()
                            .fill(entry.isYou ? Color.sage : Color.ink.opacity(0.2))
                            .frame(width: width, height: 6)
                    }
                }
                .frame(height: 6)
            }

            Spacer()

            // Hours
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", entry.hours))
                    .font(.instrumentSerif(size: 22))
                    .foregroundColor(.ink)
                Text("h")
                    .font(.instrumentSerifItalic(size: 14))
                    .foregroundColor(.ink2)
            }
        }
        .padding(.vertical, 6)
    }

    private var medalColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return Color.clear
        }
    }
}

// MARK: - Activity Feed
struct ActivityFeedCard: View {
    let activities = [
        Activity(name: "Maya", action: "completed a 2h focus session", time: "12m ago", icon: "checkmark.circle.fill"),
        Activity(name: "Theo", action: "started Wind-down mode", time: "34m ago", icon: "moon.fill"),
        Activity(name: "Priya", action: "hit a 7-day streak!", time: "1h ago", icon: "flame.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.ink2)

                Text("Activity")
                    .monoLabel()
            }

            ForEach(activities) { activity in
                ActivityRow(activity: activity)
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

struct Activity: Identifiable {
    let id = UUID()
    let name: String
    let action: String
    let time: String
    let icon: String
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.system(size: 16))
                .foregroundColor(.sage)
                .frame(width: 32, height: 32)
                .background(Color.sageSoft)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text(activity.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.ink)
                    Text(" \(activity.action)")
                        .font(.system(size: 14))
                        .foregroundColor(.ink2)
                }

                Text(activity.time)
                    .font(.geistMono(size: 10))
                    .foregroundColor(.ink3)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Groups Card
struct GroupsCard: View {
    let groups = [
        FocusGroup(name: "Morning Warriors", members: 8, emoji: "sunrise.fill"),
        FocusGroup(name: "Study Buddies", members: 5, emoji: "book.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.ink2)

                    Text("Groups")
                        .monoLabel()
                }

                Spacer()

                Button {
                    // Create group
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10))
                        Text("Create")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.ink2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.bg2)
                    .clipShape(Capsule())
                }
            }

            ForEach(groups) { group in
                GroupRow(group: group)
            }
        }
        .padding(18)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

struct FocusGroup: Identifiable {
    let id = UUID()
    let name: String
    let members: Int
    let emoji: String
}

struct GroupRow: View {
    let group: FocusGroup

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.sageSoft)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: group.emoji)
                        .font(.system(size: 20))
                        .foregroundColor(.sageDeep)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.ink)

                Text("\(group.members) members")
                    .font(.geistMono(size: 11))
                    .foregroundColor(.ink3)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.ink3)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Invite Friends Card
struct InviteFriendsCard: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(.sage)

            VStack(spacing: 4) {
                Text("Invite friends")
                    .font(.instrumentSerif(size: 22))
                    .foregroundColor(.ink)

                Text("Focus together, achieve more")
                    .font(.system(size: 13))
                    .foregroundColor(.ink3)
            }

            Button {
                // Share invite
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                    Text("Share invite link")
                        .font(.geist(size: 14, weight: .medium))
                }
                .foregroundColor(.bg)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.ink)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }
}

#Preview {
    SocialView()
}
