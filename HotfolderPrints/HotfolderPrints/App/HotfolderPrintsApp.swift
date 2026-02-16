import SwiftUI

@main
struct HotfolderPrintsApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1300, height: 850)
    }
}
