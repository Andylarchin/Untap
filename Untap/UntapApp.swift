import SwiftUI
import FamilyControls

@main
struct UntapApp: App {
    @StateObject private var appBlocker = AppBlockingManager.shared
    @StateObject private var nfcManager = NFCManager.shared
    @StateObject private var sessionManager = SessionManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appBlocker)
                .environmentObject(nfcManager)
                .environmentObject(sessionManager)
                .task {
                    await appBlocker.requestAuthorization()
                    appBlocker.ensureShieldConfigSynced()
                    sessionManager.syncAttemptsFromExtension()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        sessionManager.syncAttemptsFromExtension()
                    }
                }
        }
    }
}
