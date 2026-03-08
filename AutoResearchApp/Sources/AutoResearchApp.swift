import SwiftUI

@main
struct AutoResearchApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .defaultSize(width: 1200, height: 800)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
