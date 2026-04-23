import SwiftUI

@main
struct MiddleClickScrollApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("Middle Click Scroll") {
            SettingsView(settingsStore: appState.settingsStore)
                .environmentObject(appState)
                .onAppear {
                    appDelegate.configure(appState: appState)
                }
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView(settingsStore: appState.settingsStore)
                .environmentObject(appState)
        }
    }
}
