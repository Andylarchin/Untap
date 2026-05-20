import SwiftUI
import FamilyControls

@main
struct UntapApp: App {
    @StateObject private var appBlocker = AppBlockingManager.shared
    @StateObject private var nfcManager = NFCManager.shared
    @StateObject private var sessionManager = SessionManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("darkMode") private var darkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(darkMode ? .dark : .light)
                .environmentObject(appBlocker)
                .environmentObject(nfcManager)
                .environmentObject(sessionManager)
                .task {
                    if UserDefaults.standard.object(forKey: "appInstallDate") == nil {
                        UserDefaults.standard.set(Date(), forKey: "appInstallDate")
                    }
                    await appBlocker.requestAuthorization()
                    appBlocker.ensureShieldConfigSynced()
                    sessionManager.syncAttemptsFromExtension()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        sessionManager.syncAttemptsFromExtension()
                        sessionManager.refresh()
                        appBlocker.objectWillChange.send()
                    }
                }
        }
    }
}
