import SwiftUI

@main
struct HotfolderSlideshowApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ControlPanelView()
                .environmentObject(appState)
                .frame(minWidth: 500, minHeight: 600)
        }
        .windowResizability(.contentSize)
        .commands {
            // Slideshow menu commands
            CommandMenu("Slideshow") {
                Button("Play/Pause") {
                    appState.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Next Slide") {
                    appState.nextSlide()
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Button("Previous Slide") {
                    appState.previousSlide()
                }
                .keyboardShortcut(.leftArrow, modifiers: [])

                Divider()

                Button("Stop Slideshow") {
                    appState.stop()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Divider()

                Toggle("Mute Video Audio", isOn: Binding(
                    get: { !appState.videoAudioEnabled },
                    set: { appState.videoAudioEnabled = !$0 }
                ))
                .keyboardShortcut("m", modifiers: [])
            }
        }
    }
}
