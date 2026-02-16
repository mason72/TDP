import SwiftUI

struct EventSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        SetupCard(
            title: "Print Settings",
            icon: "doc.badge.gearshape",
            isConfigured: true
        ) {
            VStack(spacing: 16) {
                // Copies per print
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Copies per print")
                            .font(.body)
                        Text("Number of copies to automatically print for each composite")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: { if appState.defaultCopies > 1 { appState.defaultCopies -= 1 } }) {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(appState.defaultCopies <= 1)

                        Text("\(appState.defaultCopies)")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.semibold)
                            .frame(minWidth: 30)

                        Button(action: { if appState.defaultCopies < 99 { appState.defaultCopies += 1 } }) {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(appState.defaultCopies >= 99)
                    }
                }

                Divider()

                // Color profile
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Color Profile")
                            .font(.body)
                        Text("Color space used for compositing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("", selection: .constant(ColorProfileManager.ColorProfile.sRGB)) {
                        ForEach(ColorProfileManager.ColorProfile.allCases) { profile in
                            Text(profile.rawValue).tag(profile)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
            }
        }
    }
}
