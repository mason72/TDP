import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // App header
            VStack(spacing: 6) {
                Image(systemName: "printer.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
                Text("Hotfolder Prints")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)

            Divider()

            // Navigation items
            List(selection: $appState.selectedSection) {
                ForEach(AppSection.allCases) { section in
                    Label(section.rawValue, systemImage: section.iconName)
                        .tag(section)
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Event status indicator
            eventStatusBar
                .padding(16)
        }
        .frame(minWidth: 200)
    }

    private var eventStatusBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(appState.eventState.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if appState.eventState.isActive {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(appState.photosReceived)")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.bold)
                        Text("Photos")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(appState.printQueueManager.totalCopiesPrinted)")
                            .font(.title3.monospacedDigit())
                            .fontWeight(.bold)
                        Text("Printed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        switch appState.eventState {
        case .idle: return .secondary
        case .running: return .green
        case .paused: return .orange
        }
    }
}
