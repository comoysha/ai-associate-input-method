import SwiftUI

@main
struct AIAssociateInputMethodApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("AI Associate", systemImage: "text.bubble.fill") {
            MenuBarView(appState: appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(settings: appState.settings)
        }
    }
}
