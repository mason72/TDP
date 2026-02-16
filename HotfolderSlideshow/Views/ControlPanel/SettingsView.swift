import SwiftUI

/// Slideshow settings: durations, transitions, and behavior toggles.
struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.headline)

            // Slide duration
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Image Duration")
                        .font(.subheadline)
                    Spacer()
                    Text("\(String(format: "%.0f", appState.slideDuration))s")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .trailing)
                }

                Slider(value: $appState.slideDuration, in: 3...60, step: 1)
            }

            // Transition duration
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Crossfade Duration")
                        .font(.subheadline)
                    Spacer()
                    Text("\(String(format: "%.1f", appState.transitionDuration))s")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                        .frame(width: 32, alignment: .trailing)
                }

                Slider(value: $appState.transitionDuration, in: 0...3, step: 0.1)
            }

            Divider()

            // Toggles
            Toggle("Watch subfolders", isOn: $appState.watchRecursively)
                .font(.subheadline)

            Toggle("Video audio enabled", isOn: $appState.videoAudioEnabled)
                .font(.subheadline)

            Toggle("Auto-start slideshow on launch", isOn: $appState.autoStartSlideshow)
                .font(.subheadline)
        }
    }
}
