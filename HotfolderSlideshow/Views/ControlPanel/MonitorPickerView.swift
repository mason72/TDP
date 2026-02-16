import SwiftUI

/// Monitor selection UI — shows connected displays and allows picking one for the slideshow.
struct MonitorPickerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Display")
                    .font(.headline)

                Spacer()

                Button(action: { appState.monitorManager.refreshDisplays() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Refresh display list")
            }

            if appState.monitorManager.displays.isEmpty {
                Text("No displays detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(appState.monitorManager.displays) { display in
                    MonitorRow(
                        display: display,
                        isSelected: appState.monitorManager.selectedDisplayID == display.id,
                        onSelect: { appState.selectMonitor(display.id) }
                    )
                }
            }
        }
    }
}

// MARK: - Monitor Row

private struct MonitorRow: View {
    let display: DisplayInfo
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 1) {
                    Text(display.name)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .regular)

                    Text("\(Int(display.resolution.width)) x \(Int(display.resolution.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
