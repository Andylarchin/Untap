import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @EnvironmentObject var appBlocker: AppBlockingManager
    @EnvironmentObject var nfcManager: NFCManager
    @EnvironmentObject var sessionManager: SessionManager

    enum Tab: String, CaseIterable {
        case home = "Home"
        case blocks = "Blocks"
        case progress = "Progress"
        case me = "Me"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .blocks: return "shield.fill"
            case .progress: return "flame.fill"
            case .me: return "person.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)

                BlocksView()
                    .tag(Tab.blocks)

                StreakView()
                    .tag(Tab.progress)

                ProfileView()
                    .tag(Tab.me)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                        Text(tab.rawValue)
                            .font(.custom("GeistMono-Regular", size: 10))
                            .kerning(1)
                            .textCase(.uppercase)
                    }
                    .foregroundColor(selectedTab == tab ? Color.ink : Color.ink3)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 34)
        .background(
            LinearGradient(
                colors: [Color.bg.opacity(0), Color.bg],
                startPoint: .top,
                endPoint: .center
            )
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(AppBlockingManager.shared)
        .environmentObject(NFCManager.shared)
        .environmentObject(SessionManager.shared)
}
