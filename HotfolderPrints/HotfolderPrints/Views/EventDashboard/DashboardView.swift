import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Event Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(appState.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Event controls
                eventControls
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)

            Divider()

            if appState.eventState == .idle {
                idleState
            } else {
                activeEventView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Event Controls

    private var eventControls: some View {
        HStack(spacing: 12) {
            if appState.eventState == .running {
                Button(action: { appState.pauseEvent() }) {
                    Label("Pause", systemImage: "pause.fill")
                }
                .buttonStyle(.bordered)

                Button(action: { appState.stopEvent() }) {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            } else if appState.eventState == .paused {
                Button(action: { appState.resumeEvent() }) {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(action: { appState.stopEvent() }) {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            } else {
                Button(action: { appState.startEvent(); }) {
                    Label("Start Event", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!appState.isReadyToStart)
            }
        }
    }

    // MARK: - Idle State

    private var idleState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "printer.dotmatrix")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            VStack(spacing: 8) {
                Text("No Active Event")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Set up your watch folder, template, and printer in Setup, then start an event.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            Button("Go to Setup") {
                appState.selectedSection = .setup
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()
        }
    }

    // MARK: - Active Event

    private var activeEventView: some View {
        VStack(spacing: 0) {
            // Stats bar
            statsBar
                .padding(.horizontal, 30)
                .padding(.vertical, 16)

            Divider()

            // Split view: incoming photos + print queue
            HSplitView {
                // Incoming photos
                IncomingPhotosView()
                    .frame(minWidth: 300)

                // Print queue
                PrintQueueView()
                    .frame(minWidth: 400)
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 0) {
            statCard(
                title: "Photos Received",
                value: "\(appState.photosReceived)",
                icon: "photo.stack",
                color: .blue
            )

            Divider()
                .frame(height: 40)
                .padding(.horizontal, 20)

            statCard(
                title: "Waiting",
                value: "\(appState.incomingPhotos.count)",
                icon: "clock",
                color: .orange
            )

            Divider()
                .frame(height: 40)
                .padding(.horizontal, 20)

            statCard(
                title: "Prints Made",
                value: "\(appState.printQueueManager.totalPrintsMade)",
                icon: "printer",
                color: .green
            )

            Divider()
                .frame(height: 40)
                .padding(.horizontal, 20)

            statCard(
                title: "Total Copies",
                value: "\(appState.printQueueManager.totalCopiesPrinted)",
                icon: "doc.on.doc",
                color: .purple
            )

            Spacer()

            // Template info
            if let template = appState.templateManager.selectedTemplate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(template.name)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text("\(template.imageCount) photos per print · \(template.printSize.displayName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.title2.monospacedDigit())
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
